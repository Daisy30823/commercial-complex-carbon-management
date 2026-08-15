package cn.complexcarbon;

import cn.complexcarbon.util.SqlSortHelper;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class SqlSortHelperTest {
    @Test void resolvesOnlyWhitelistedColumns() {
        assertEquals("record_date desc", SqlSortHelper.resolve("energy_consumption_record", "record_date", "desc").sql());
        assertThrows(IllegalArgumentException.class, () -> SqlSortHelper.resolve("energy_consumption_record", "record_date desc; drop table app_user", "asc"));
        assertThrows(IllegalArgumentException.class, () -> SqlSortHelper.resolve("energy_consumption_record", "record_date", "sideways"));
    }

    @Test void sortsCompleteServiceResults() {
        List<Map<String,Object>> rows=List.of(Map.of("bill_code","b1","total_energy_cost",10),Map.of("bill_code","b2","total_energy_cost",30));
        assertEquals("b2",SqlSortHelper.sortRows("merchant_energy_bill",rows,"total_energy_cost","desc").get(0).get("bill_code"));
    }
}
