package cn.complexcarbon.util;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public final class SqlSortHelper {
    private static final Map<String, SortDefinition> DEFINITIONS = definitions();

    private SqlSortHelper() {}

    public static Order resolve(String domain, String sortBy, String sortOrder) {
        SortDefinition definition = DEFINITIONS.get(domain);
        if (definition == null) throw new IllegalArgumentException("不支持对当前数据排序");
        String key = sortBy == null || sortBy.isBlank() ? definition.defaultKey() : sortBy;
        String column = definition.fields().get(key);
        if (column == null) throw new IllegalArgumentException("不支持的排序字段：" + key);
        String direction = sortOrder == null || sortOrder.isBlank() ? definition.defaultDirection() : sortOrder.toLowerCase(Locale.ROOT);
        if (!direction.equals("asc") && !direction.equals("desc")) throw new IllegalArgumentException("排序方向只能是 asc 或 desc");
        return new Order(key, column, direction);
    }

    public static List<Map<String, Object>> sortRows(String domain, List<Map<String, Object>> rows, String sortBy, String sortOrder) {
        Order order = resolve(domain, sortBy, sortOrder);
        List<Map<String, Object>> result = new ArrayList<>(rows);
        Comparator<Map<String, Object>> comparator = Comparator.comparing(row -> comparable(row.get(order.key())), Comparator.nullsLast(Comparator.naturalOrder()));
        if (order.direction().equals("desc")) comparator = comparator.reversed();
        result.sort(comparator);
        return result;
    }

    private static ComparableValue comparable(Object value) {
        if (value == null) return null;
        if (value instanceof Number number) return new ComparableValue(new BigDecimal(number.toString()), null);
        return new ComparableValue(null, value.toString());
    }

    private static Map<String, SortDefinition> definitions() {
        Map<String, SortDefinition> values = new LinkedHashMap<>();
        add(values,"commercial_complex","complex_id","desc","complex_id","complex_code","complex_name","gross_floor_area","created_at","record_status");
        add(values,"building","building_id","desc","building_id","building_code","building_name","building_type","gross_floor_area","created_at","record_status");
        add(values,"functional_area","area_id","desc","area_id","area_code","area_name","area_type","floor_no","gross_area","created_at","record_status");
        add(values,"merchant","merchant_id","desc","merchant_id","merchant_code","merchant_name","merchant_category","brand_name","operating_area","entry_date","merchant_status");
        add(values,"meter_node","meter_node_id","desc","meter_node_id","node_code","node_name","node_type","node_level","node_status","created_at");
        add(values,"meter_device","meter_device_id","desc","meter_device_id","device_code","device_name","device_type","measuring_unit","online_status","last_collection_time","device_status");
        add(values,"energy_consumption_record","record_date","desc","energy_record_id","record_code","record_date","consumption_amount","energy_cost","audit_status","created_at");
        add(values,"carbon_accounting_record","accounting_date","desc","carbon_accounting_id","accounting_code","accounting_date","activity_data","carbon_emission_kg","accounting_status","created_at");
        add(values,"carbon_budget","budget_year","desc","carbon_budget_id","budget_code","budget_name","budget_year","total_budget_emission_kg","actual_emission_kg","execution_rate","budget_status");
        add(values,"alert_event","occurred_at","desc","alert_event_id","event_code","severity_level","event_title","occurred_at","event_status");
        add(values,"corrective_task","planned_end_at","desc","corrective_task_id","task_code","task_title","priority_level","planned_end_at","task_status","overdue_flag");
        add(values,"energy_saving_project","project_code","desc","energy_saving_project_id","project_code","project_name","project_type","investment_amount","project_status","planned_start_date");
        add(values,"project_evaluation","evaluation_date","desc","project_evaluation_id","evaluation_no","evaluation_date","energy_saving_amount","carbon_reduction_kg","return_on_investment_rate","payback_period_months","evaluation_status");
        add(values,"app_user","user_id","desc","user_id","username","real_name","employee_no","job_title","last_login_time","user_status","created_at");
        add(values,"sys_role","sort_no","asc","role_id","role_code","role_name","sort_no","role_status","created_at");
        add(values,"operation_log","operation_time","desc","operation_log_id","operation_time","username_snapshot","module_name","business_type","operation_result","execution_time_ms");
        add(values,"merchant_energy_bill","bill_code","desc","merchant_energy_bill_id","bill_code","merchant_name","version_no","bill_year","bill_month","data_completeness_rate","total_energy_cost","total_energy_tce","total_carbon_kg","allocation_weight","bill_status");
        Map<String,String> quality=new LinkedHashMap<>();quality.put("data_quality_issue_id","q.data_quality_issue_id");quality.put("issue_rule","q.issue_rule");quality.put("severity_level","q.severity_level");quality.put("issue_title","q.issue_title");quality.put("device_name","md.device_name");quality.put("record_code","e.record_code");quality.put("detected_at","q.detected_at");quality.put("issue_status","q.issue_status");
        values.put("data_quality_issue_query",new SortDefinition(quality,"detected_at","desc"));
        return Map.copyOf(values);
    }

    private static void add(Map<String, SortDefinition> target,String domain,String defaultKey,String defaultDirection,String... fields){Map<String,String> allowed=new LinkedHashMap<>();for(String field:fields)allowed.put(field,field);target.put(domain,new SortDefinition(Map.copyOf(allowed),defaultKey,defaultDirection));}

    public record Order(String key,String column,String direction){public String sql(){return column+" "+direction;}}
    private record SortDefinition(Map<String,String> fields,String defaultKey,String defaultDirection){}
    private record ComparableValue(BigDecimal number,String text) implements Comparable<ComparableValue>{@Override public int compareTo(ComparableValue other){if(number!=null&&other.number!=null)return number.compareTo(other.number);return String.valueOf(text).compareToIgnoreCase(String.valueOf(other.text));}}
}
