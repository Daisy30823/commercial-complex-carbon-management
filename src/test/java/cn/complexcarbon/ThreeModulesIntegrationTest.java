package cn.complexcarbon;

import cn.complexcarbon.util.Db;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

class ThreeModulesIntegrationTest {
    @BeforeAll static void requireDatabaseConfiguration() {
        assumeTrue(databaseConfigured(), "database integration tests require DB_HOST/MYSQLHOST or db.properties");
    }

    private static boolean databaseConfigured() {
        return System.getenv("DB_HOST") != null || System.getenv("MYSQLHOST") != null
                || ThreeModulesIntegrationTest.class.getClassLoader().getResource("db.properties") != null;
    }

    @Test void databaseConnectionUsesCurrentMysql() throws Exception { try (Connection connection=Db.getConnection()) { assertTrue(connection.isValid(3)); } }
    @Test void originalEnergyRecordsRemain() throws Exception { assertTrue(scalar("select count(*) from energy_consumption_record")>=5500); }
    @Test void originalCarbonRecordsRemain() throws Exception { assertTrue(scalar("select count(*) from carbon_accounting_record")>=5500); }
    @Test void merchantBillTablesExist() throws Exception { assertEquals(3,scalar("select count(*) from information_schema.tables where table_schema=database() and table_name in ('energy_allocation_rule','merchant_energy_bill','merchant_energy_bill_detail')")); }
    @Test void dataQualityTablesExist() throws Exception { assertEquals(2,scalar("select count(*) from information_schema.tables where table_schema=database() and table_name in ('data_quality_issue','data_quality_review')")); }
    @Test void allModuleProceduresExist() throws Exception { assertEquals(10,scalar("select count(*) from information_schema.routines where routine_schema=database() and routine_type='PROCEDURE' and routine_name in ('sp_preview_merchant_bill_allocation','sp_generate_merchant_energy_bills','sp_query_merchant_energy_bills','sp_confirm_merchant_energy_bill','sp_void_merchant_energy_bill','sp_generate_monthly_carbon_report_dataset','sp_scan_data_quality_issues','sp_query_data_quality_issues','sp_review_data_quality_issue','sp_resolve_data_quality_issue')")); }
    @Test void allocationPreviewReturnsRealRows() throws Exception { assertTrue(callCount("{call sp_preview_merchant_bill_allocation(?,?,?,?)}",1,2026,7,"lease_area")>0); }
    @Test void generatedBillsExistForRealMonth() throws Exception { assertTrue(scalar("select count(*) from merchant_energy_bill where complex_id=1 and bill_year=2026 and bill_month=7 and current_version_flag=1 and bill_status<>2")>=10); }
    @Test void generatedBillTotalsMatchMonthlyDataset() throws Exception { BigDecimal bills=decimal("select sum(total_energy_tce) from merchant_energy_bill where complex_id=1 and bill_year=2026 and bill_month=7 and current_version_flag=1 and bill_status<>2");BigDecimal records=decimal("select sum(e.consumption_amount*et.standard_coal_coefficient) from energy_consumption_record e join energy_type et on et.energy_type_id=e.energy_type_id join meter_device md on md.meter_device_id=e.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=1 and e.record_date between '2026-07-01' and '2026-07-31'");assertTrue(bills.subtract(records).abs().compareTo(new BigDecimal("0.001"))<0); }
    @Test void allocationWeightsSumToOneIncludingTail() throws Exception { assertTrue(decimal("select abs(sum(allocation_weight)-1) from merchant_energy_bill where complex_id=1 and bill_year=2026 and bill_month=7 and current_version_flag=1").compareTo(new BigDecimal("0.00000001"))<0); }
    @Test void billRegenerationKeepsHistoricalVersions() throws Exception { assertTrue(scalar("select count(distinct version_no) from merchant_energy_bill where complex_id=1 and bill_year=2026 and bill_month=7")>=2);assertEquals(scalar("select count(*) from merchant_occupancy o join merchant m on m.merchant_id=o.merchant_id where m.complex_id=1 and m.merchant_status=1 and o.current_valid_flag=1"),scalar("select count(*) from merchant_energy_bill where complex_id=1 and bill_year=2026 and bill_month=7 and current_version_flag=1")); }
    @Test void publicAllocationDoesNotLeakAcrossComplexes() throws Exception { assertEquals(0,scalar("select count(*) from merchant_energy_bill where complex_id=2 and bill_year=2026 and bill_month=7 and current_version_flag=1")); }
    @Test void completeMonthBillsRemainDraftUntilConfirmation() throws Exception { assertTrue(scalar("select count(*) from merchant_energy_bill where complex_id=1 and bill_year=2026 and bill_month=7 and current_version_flag=1 and data_completeness_rate=100 and bill_status=0")>=18); }
    @Test void monthlyReportExposesCompleteCoverage() throws Exception { try(Connection c=Db.getConnection();CallableStatement s=c.prepareCall("{call sp_generate_monthly_carbon_report_dataset(?,?,?)}")){s.setLong(1,1);s.setInt(2,2026);s.setInt(3,7);assertTrue(s.execute());try(ResultSet r=s.getResultSet()){assertTrue(r.next());assertEquals(31,r.getInt("covered_days"));assertEquals(0,r.getBigDecimal("date_completeness_rate").compareTo(new BigDecimal("100")));}} }
    @Test void qualityScanIsIdempotent() throws Exception { callCount("{call sp_scan_data_quality_issues(?,?,?)}",1,Date.valueOf("2026-07-01"),Date.valueOf("2026-07-31"));long first=scalar("select count(*) from data_quality_issue where complex_id=1");callCount("{call sp_scan_data_quality_issues(?,?,?)}",1,Date.valueOf("2026-07-01"),Date.valueOf("2026-07-31"));assertEquals(first,scalar("select count(*) from data_quality_issue where complex_id=1")); }
    @Test void qualityFingerprintsAreUnique() throws Exception { assertEquals(scalar("select count(*) from data_quality_issue"),scalar("select count(distinct issue_fingerprint) from data_quality_issue")); }
    @Test void qualityScanProducesAtLeastThreeRuleTypes() throws Exception { assertTrue(scalar("select count(distinct issue_rule) from data_quality_issue where complex_id=1")>=3); }
    @Test void energyCorrectionTriggerUpdatesCarbonAndCanRollback() throws Exception { try(Connection c=Db.getConnection()){c.setAutoCommit(false);try(PreparedStatement find=c.prepareStatement("select e.energy_record_id,e.end_reading,car.carbon_emission_kg from energy_consumption_record e join carbon_accounting_record car on car.energy_record_id=e.energy_record_id where e.abnormal_flag=1 limit 1");ResultSet r=find.executeQuery()){assertTrue(r.next());long id=r.getLong(1);BigDecimal end=r.getBigDecimal(2),carbon=r.getBigDecimal(3);try(PreparedStatement update=c.prepareStatement("update energy_consumption_record set end_reading=?,correction_reason='集成测试回滚' where energy_record_id=?")){update.setBigDecimal(1,end.add(BigDecimal.ONE));update.setLong(2,id);update.executeUpdate();}try(PreparedStatement verify=c.prepareStatement("select carbon_emission_kg from carbon_accounting_record where energy_record_id=?")){verify.setLong(1,id);try(ResultSet changed=verify.executeQuery()){assertTrue(changed.next());assertNotEquals(0,changed.getBigDecimal(1).compareTo(carbon));}}finally{c.rollback();}}} }
    @Test void enabledComplexesHaveAtLeastFourActiveBuildings() throws Exception { assertEquals(0,scalar("select count(*) from commercial_complex c where c.record_status=1 and (select count(*) from building b where b.complex_id=c.complex_id and b.record_status=1)<4")); }
    @Test void acceptanceTestComplexRemainsInactive() throws Exception { assertEquals(0,scalar("select count(*) from commercial_complex where complex_code like 'ACC-%' and record_status=1")); }
    @Test void meterNodeLabelsContainNoQuestionMarks() throws Exception { assertEquals(0,scalar("select count(*) from meter_node where node_name like '%?%' or node_type like '%?%' or remark like '%?%'")); }
    @Test void functionalAreaLabelsContainNoQuestionMarks() throws Exception { assertEquals(0,scalar("select count(*) from functional_area where area_name like '%?%' or area_type like '%?%' or remark like '%?%'")); }
    @Test void administratorHasModuleWriteRole() throws Exception { assertTrue(scalar("select count(*) from app_user u join user_role ur on ur.user_id=u.user_id and ur.valid_flag=1 join sys_role r on r.role_id=ur.role_id where u.username='admin' and r.role_code='admin'")>0); }

    private static long scalar(String sql)throws Exception{try(Connection c=Db.getConnection();PreparedStatement s=c.prepareStatement(sql);ResultSet r=s.executeQuery()){assertTrue(r.next());return r.getLong(1);}}
    private static BigDecimal decimal(String sql)throws Exception{try(Connection c=Db.getConnection();PreparedStatement s=c.prepareStatement(sql);ResultSet r=s.executeQuery()){assertTrue(r.next());return r.getBigDecimal(1);}}
    private static int callCount(String sql,Object...values)throws Exception{try(Connection c=Db.getConnection();CallableStatement s=c.prepareCall(sql)){for(int i=0;i<values.length;i++)s.setObject(i+1,values[i]);if(!s.execute())return 0;try(ResultSet r=s.getResultSet()){int count=0;while(r.next())count++;return count;}}}
}
