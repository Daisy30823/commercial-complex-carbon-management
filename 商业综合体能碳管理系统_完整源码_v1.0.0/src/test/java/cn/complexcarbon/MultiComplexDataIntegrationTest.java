package cn.complexcarbon;

import cn.complexcarbon.util.Db;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

class MultiComplexDataIntegrationTest {
    @BeforeAll static void requireDatabaseConfiguration() {
        assumeTrue(databaseConfigured(), "database integration tests require DB_HOST/MYSQLHOST or db.properties");
    }

    private static boolean databaseConfigured() {
        return System.getenv("DB_HOST") != null || System.getenv("MYSQLHOST") != null
                || MultiComplexDataIntegrationTest.class.getClassLoader().getResource("db.properties") != null;
    }

    @Test void eightEnabledComplexesExist() throws Exception {
        assertEquals(8, scalar("select count(*) from commercial_complex where record_status=1"));
    }

    @Test void everyComplexHasFiveBuildings() throws Exception {
        assertEquals(0, scalar("select count(*) from commercial_complex c where c.record_status=1 and (select count(*) from building b where b.complex_id=c.complex_id and b.record_status=1)<5"));
    }

    @Test void everyComplexHasFifteenAreas() throws Exception {
        assertEquals(0, scalar("select count(*) from commercial_complex c where c.record_status=1 and (select count(*) from functional_area a join building b on b.building_id=a.building_id where b.complex_id=c.complex_id and a.record_status=1)<15"));
    }

    @Test void everyComplexHasMerchantOccupancies() throws Exception {
        assertEquals(0, scalar("select count(*) from commercial_complex c where c.record_status=1 and (select count(*) from merchant_occupancy o join merchant m on m.merchant_id=o.merchant_id where m.complex_id=c.complex_id and m.merchant_status=1 and o.current_valid_flag=1)<18"));
    }

    @Test void merchantOccupanciesNeverCrossComplexes() throws Exception {
        assertEquals(0, scalar("select count(*) from merchant_occupancy o join merchant m on m.merchant_id=o.merchant_id join functional_area a on a.area_id=o.area_id join building b on b.building_id=a.building_id where m.complex_id<>b.complex_id"));
    }

    @Test void everyComplexHasMeterTree() throws Exception {
        assertEquals(0, scalar("select count(*) from commercial_complex c where c.record_status=1 and (select count(*) from meter_node n where n.complex_id=c.complex_id and n.node_status=1)<25"));
    }

    @Test void meterTreeParentsNeverCrossComplexes() throws Exception {
        assertEquals(0, scalar("select count(*) from meter_node n join meter_node p on p.meter_node_id=n.parent_node_id where n.complex_id<>p.complex_id"));
    }

    @Test void everyComplexHasThirtyDevices() throws Exception {
        assertEquals(0, scalar("select count(*) from commercial_complex c where c.record_status=1 and (select count(*) from meter_device d join meter_node n on n.meter_node_id=d.meter_node_id where n.complex_id=c.complex_id and d.device_status=1)<30"));
    }

    @Test void everyComplexHasHalfYearEnergyData() throws Exception {
        assertEquals(0, scalar("select count(*) from commercial_complex c where c.record_status=1 and (select count(*) from energy_consumption_record e join meter_device d on d.meter_device_id=e.meter_device_id join meter_node n on n.meter_node_id=d.meter_node_id where n.complex_id=c.complex_id)<3600"));
    }

    @Test void energyTriggerHasOneCarbonRecordPerEnergyRecord() throws Exception {
        assertEquals(0, scalar("select count(*) from energy_consumption_record e left join carbon_accounting_record c on c.energy_record_id=e.energy_record_id where c.carbon_accounting_id is null"));
        assertEquals(scalar("select count(*) from energy_consumption_record"), scalar("select count(*) from carbon_accounting_record"));
    }

    @Test void annualBudgetsCoverEveryAreaAndMonth() throws Exception {
        assertEquals(0, scalar("select count(*) from commercial_complex c join carbon_budget cb on cb.complex_id=c.complex_id and cb.budget_year=year(curdate()) where c.record_status=1 and (select count(*) from carbon_budget_detail d where d.carbon_budget_id=cb.carbon_budget_id and d.valid_flag=1)<>(select count(*)*12 from functional_area a join building b on b.building_id=a.building_id where b.complex_id=c.complex_id and a.record_status=1)"));
    }

    @Test void everyComplexHasThreeBillMonths() throws Exception {
        assertEquals(0, scalar("select count(*) from commercial_complex c where c.record_status=1 and (select count(distinct concat(b.bill_year,'-',b.bill_month)) from merchant_energy_bill b where b.complex_id=c.complex_id and b.current_version_flag=1)<3"));
    }

    @Test void everyComplexHasQualityIssuesFromRules() throws Exception {
        assertEquals(0, scalar("select count(*) from commercial_complex c where c.record_status=1 and (select count(*) from data_quality_issue q where q.complex_id=c.complex_id)<20"));
    }

    @Test void operationLogsMeetAuditVolume() throws Exception {
        assertTrue(scalar("select count(*) from operation_log") >= 2000);
    }

    @Test void registeredUsersHaveDedicatedReadOnlyRole() throws Exception {
        assertEquals(1, scalar("select count(*) from sys_role where role_code='registered_user' and role_status=1"));
    }

    @Test void businessDataContainsNoVisibleTestMarkers() throws Exception {
        assertEquals(0, scalar("select count(*) from operation_log where concat_ws(' ',object_type,object_id,operation_description,request_url) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'"));
    }

    @Test void monthlyReportProcedureReturnsForEveryComplex() throws Exception {
        try (Connection connection = Db.getConnection(); PreparedStatement complexes = connection.prepareStatement("select complex_id from commercial_complex where record_status=1"); ResultSet ids = complexes.executeQuery()) {
            while (ids.next()) {
                try (CallableStatement call = connection.prepareCall("{call sp_generate_monthly_carbon_report_dataset(?,?,?)}")) {
                    call.setLong(1, ids.getLong(1));
                    call.setInt(2, 2026);
                    call.setInt(3, 7);
                    assertTrue(call.execute());
                    try (ResultSet rows = call.getResultSet()) { assertTrue(rows.next()); }
                }
            }
        }
    }

    @Test void dashboardAggregateReturnsWithinFiveSeconds() throws Exception {
        long started = System.nanoTime();
        assertTrue(scalar("select count(*),coalesce(sum(e.consumption_amount*et.standard_coal_coefficient),0) from energy_consumption_record e join energy_type et on et.energy_type_id=e.energy_type_id join meter_device d on d.meter_device_id=e.meter_device_id join meter_node n on n.meter_node_id=d.meter_node_id where n.complex_id=1 and e.record_date between date_sub(curdate(),interval 30 day) and curdate()") > 0);
        assertTrue((System.nanoTime()-started)/1_000_000 < 5000);
    }

    private static long scalar(String sql) throws Exception {
        try (Connection connection = Db.getConnection(); PreparedStatement statement = connection.prepareStatement(sql); ResultSet result = statement.executeQuery()) {
            assertTrue(result.next());
            return result.getLong(1);
        }
    }
}
