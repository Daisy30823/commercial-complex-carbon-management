package cn.complexcarbon.controller;

import cn.complexcarbon.util.ApiResponse;
import cn.complexcarbon.util.Db;
import cn.complexcarbon.util.Json;
import cn.complexcarbon.util.ResultSets;
import cn.complexcarbon.util.SqlSortHelper;
import com.fasterxml.jackson.core.type.TypeReference;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.mindrot.jbcrypt.BCrypt;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

public class ApiServlet extends HttpServlet {
    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {};
    private static final Set<String> PROCEDURE_RESOURCES = Set.of("complexes", "buildings", "areas", "merchants", "meter-nodes", "meter-devices");
    private static final Map<String, String> TABLES = Map.ofEntries(
            Map.entry("complexes", "commercial_complex"), Map.entry("buildings", "building"),
            Map.entry("areas", "functional_area"), Map.entry("merchants", "merchant"),
            Map.entry("meter-nodes", "meter_node"), Map.entry("meter-devices", "meter_device"),
            Map.entry("energy-records", "energy_consumption_record"), Map.entry("carbon-records", "carbon_accounting_record"),
            Map.entry("budgets", "carbon_budget"), Map.entry("alerts", "alert_event"),
            Map.entry("corrective-tasks", "corrective_task"), Map.entry("projects", "energy_saving_project"),
            Map.entry("evaluations", "project_evaluation"), Map.entry("users", "app_user"),
            Map.entry("roles", "sys_role"), Map.entry("logs", "operation_log"));
    private static final Map<String, String> PRIMARY_KEYS = Map.ofEntries(
            Map.entry("commercial_complex", "complex_id"), Map.entry("building", "building_id"),
            Map.entry("functional_area", "area_id"), Map.entry("merchant", "merchant_id"),
            Map.entry("meter_node", "meter_node_id"), Map.entry("meter_device", "meter_device_id"),
            Map.entry("energy_consumption_record", "energy_record_id"), Map.entry("carbon_accounting_record", "carbon_accounting_id"),
            Map.entry("carbon_budget", "carbon_budget_id"), Map.entry("alert_event", "alert_event_id"),
            Map.entry("corrective_task", "corrective_task_id"), Map.entry("energy_saving_project", "energy_saving_project_id"),
            Map.entry("project_evaluation", "project_evaluation_id"), Map.entry("app_user", "user_id"),
            Map.entry("sys_role", "role_id"), Map.entry("operation_log", "operation_log_id"));
    private static final long REGISTRATION_WINDOW_MILLIS = 15 * 60 * 1000L;
    private static final int REGISTRATION_LIMIT = 5;
    private static final ConcurrentHashMap<String, RegistrationWindow> REGISTRATION_WINDOWS = new ConcurrentHashMap<>();

    @Override protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException { dispatch(req, resp, "GET"); }
    @Override protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException { dispatch(req, resp, "POST"); }
    @Override protected void doPut(HttpServletRequest req, HttpServletResponse resp) throws IOException { dispatch(req, resp, "PUT"); }
    @Override protected void doDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException { dispatch(req, resp, "DELETE"); }

    private void dispatch(HttpServletRequest req, HttpServletResponse resp, String method) throws IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        try {
            String path = req.getPathInfo() == null ? "/" : req.getPathInfo();
            if (path.equals("/health") && method.equals("GET")) {
                resp.setStatus(200);
                resp.getWriter().write(Json.write(Map.of("success", true, "data", health())));
                return;
            }
            ApiResponse result = route(req, method, path);
            resp.setStatus(result.code());
            resp.getWriter().write(Json.write(result));
        } catch (IllegalArgumentException e) {
            resp.setStatus(400); resp.getWriter().write(Json.write(ApiResponse.bad(e.getMessage())));
        } catch (SQLException e) {
            getServletContext().log("database operation failed", e);
            int code = e.getErrorCode() == 1062 || e.getErrorCode() == 1452 || e.getErrorCode() == 1451 || e.getErrorCode() == 3819 || e.getErrorCode() == 1644 ? 400 : 500;
            String message = code == 400 ? sqlMessage(e) : "数据库操作失败，请检查配置或参数";
            resp.setStatus(code); resp.getWriter().write(Json.write(new ApiResponse(false, code, message, Map.of())));
        } catch (Exception e) {
            getServletContext().log("api operation failed", e);
            resp.setStatus(500); resp.getWriter().write(Json.write(ApiResponse.error("服务暂时不可用")));
        }
    }

    private ApiResponse route(HttpServletRequest req, String method, String path) throws Exception {
        if (path.equals("/auth/login") && method.equals("POST")) return login(req);
        if (path.equals("/auth/register") && method.equals("POST")) return register(req);
        if (path.equals("/auth/logout") && method.equals("POST")) { if (req.getSession(false) != null) req.getSession(false).invalidate(); return ApiResponse.ok(Map.of()); }
        if (path.equals("/auth/me") && method.equals("GET")) { var s=req.getSession(false); return s == null || s.getAttribute("user") == null ? ApiResponse.unauthorized() : ApiResponse.ok(s.getAttribute("user")); }
        if (path.equals("/dashboard/summary") && method.equals("GET")) return summary(req);
        if (path.equals("/complexes/enabled") && method.equals("GET")) return enabledComplexes();
        if (path.equals("/profile") && method.equals("GET")) return profile(req);
        if (path.equals("/profile") && method.equals("PUT")) return updateProfile(req, body(req));
        if (path.equals("/profile/password") && method.equals("PUT")) return changePassword(req, body(req));
        if (path.equals("/profile/logs") && method.equals("GET")) return profileLogs(req);
        enforceBusinessWritePermission(req, method);
        if (path.equals("/charts/energy-carbon-trend") && method.equals("GET")) return chartTrend(req);
        if (path.equals("/charts/area-carbon-ranking") && method.equals("GET")) return chartRanking(req);
        if (path.equals("/charts/energy-mix") && method.equals("GET")) return callQuery("sp_query_energy_mix", params(longParam(req,"complexId",1), statYear(req), statMonth(req)));
        if (path.equals("/charts/area-date-heatmap") && method.equals("GET")) return heatmap(req);
        if (path.equals("/charts/area-performance-radar") && method.equals("GET")) return radar(req);
        if (path.equals("/charts/budget-gauge") && method.equals("GET")) return gauge(req);
        if (path.equals("/meter-nodes/tree") && method.equals("GET")) return callQuery("sp_query_meter_node_tree", params(longParam(req,"complexId",1)));
        if (path.equals("/budgets/refresh") && method.equals("POST")) return callQuery("sp_refresh_budget_actuals", params(longParam(req,"budgetId",1)));
        if (path.matches("/budgets/\\d+/over-budget-areas") && method.equals("GET")) return callQuery("sp_query_over_budget_areas", params(Long.parseLong(path.split("/")[2])));
        if (path.equals("/alerts/open") && method.equals("GET")) return callQuery("sp_query_open_alerts", params(longParam(req,"complexId",1), nullable(req.getParameter("severity"))));
        if (path.matches("/alerts/\\d+/(acknowledge|close)") && method.equals("PUT")) return updateAlert(Long.parseLong(path.split("/")[2]), path.endsWith("close"), body(req));
        if (path.equals("/projects/effects") && method.equals("GET")) return callQuery("sp_query_project_effect", params(longParam(req,"complexId",1)));
        if (path.equals("/analytics/monthly-area") && method.equals("GET")) return callQuery("sp_query_monthly_area_energy_carbon", params(longParam(req,"complexId",1), intParam(req,"year",statYear(req)), intParam(req,"month",statMonth(req))));
        if (path.equals("/analytics/top-merchants") && method.equals("GET")) return callQuery("sp_query_top_merchants_carbon", params(longParam(req,"complexId",1), statYear(req), statMonth(req), boundedInt(req,"limit",10,1,100)));
        if (path.equals("/analytics/over-budget") && method.equals("GET")) return callQuery("sp_query_over_budget_areas", params(longParam(req,"budgetId",1)));
        if (path.equals("/analytics/open-alerts") && method.equals("GET")) return callQuery("sp_query_open_alerts", params(longParam(req,"complexId",1), nullable(req.getParameter("severity"))));
        if (path.equals("/analytics/project-effect") && method.equals("GET")) return callQuery("sp_query_project_effect", params(longParam(req,"complexId",1)));
        if (path.equals("/analytics/energy-mix") && method.equals("GET")) return callQuery("sp_query_energy_mix", params(longParam(req,"complexId",1), statYear(req), statMonth(req)));
        if (path.equals("/allocation-rules") && method.equals("GET")) return allocationRules(req);
        if (path.equals("/allocation-rules") && method.equals("POST")) return saveAllocationRule(req,null,body(req));
        if (path.matches("/allocation-rules/\\d+") && method.equals("PUT")) return saveAllocationRule(req,Long.parseLong(path.split("/")[2]),body(req));
        if (path.matches("/allocation-rules/\\d+") && method.equals("DELETE")) return disableAllocationRule(req,Long.parseLong(path.split("/")[2]));
        if (path.equals("/merchant-bills/preview") && method.equals("GET")) return merchantBillPreview(req);
        if (path.equals("/merchant-bills/generate") && method.equals("POST")) return generateMerchantBills(req, body(req));
        if (path.matches("/merchant-bills/\\d+/confirm") && method.equals("PUT")) return confirmMerchantBill(req,Long.parseLong(path.split("/")[2]));
        if (path.matches("/merchant-bills/\\d+/void") && method.equals("PUT")) return voidMerchantBill(req, path, body(req));
        if (path.matches("/merchant-bills/\\d+") && method.equals("GET")) return merchantBillDetail(Long.parseLong(path.split("/")[2]));
        if (path.equals("/merchant-bills") && method.equals("GET")) return merchantBills(req);
        if (path.equals("/monthly-reports/preview") && method.equals("GET")) return monthlyReport(req);
        if (path.equals("/data-quality/rules") && method.equals("GET")) return qualityRules();
        if (path.equals("/data-quality/summary") && method.equals("GET")) return qualitySummary(req);
        if (path.equals("/data-quality/scan") && method.equals("POST")) return scanQuality(req, body(req));
        if (path.matches("/data-quality/issues/\\d+/review") && method.equals("PUT")) return qualityAction(req,path,body(req),"sp_review_data_quality_issue");
        if (path.matches("/data-quality/issues/\\d+/resolve") && method.equals("PUT")) return qualityAction(req,path,body(req),"sp_resolve_data_quality_issue");
        if (path.matches("/data-quality/issues/\\d+/false-positive") && method.equals("PUT")) return qualityAction(req,path,body(req),"sp_mark_data_quality_false_positive");
        if (path.matches("/data-quality/issues/\\d+/create-alert") && method.equals("POST")) return qualityCreateAlert(req,Long.parseLong(path.split("/")[3]));
        if (path.matches("/data-quality/issues/\\d+/correct") && method.equals("PUT")) return correctQualityRecord(req,Long.parseLong(path.split("/")[3]),body(req));
        if (path.matches("/data-quality/issues/\\d+") && method.equals("GET")) return qualityDetail(Long.parseLong(path.split("/")[3]));
        if (path.equals("/data-quality/issues") && method.equals("GET")) return qualityIssues(req);
        return resource(req, method, path);
    }

    private ApiResponse login(HttpServletRequest req) throws Exception {
        Map<String,Object> b=body(req); String username=str(b,"username"), password=str(b,"password");
        requireText(username,"用户名"); requireText(password,"密码");
        try(Connection c=Db.getConnection(); PreparedStatement ps=c.prepareStatement("select u.user_id,u.username,u.password_hash,u.real_name,u.job_title,coalesce(group_concat(distinct r.role_code order by r.role_code),'') role_codes from app_user u left join user_role ur on ur.user_id=u.user_id and ur.valid_flag=1 and (ur.effective_date is null or ur.effective_date<=curdate()) and (ur.expiry_date is null or ur.expiry_date>=curdate()) left join sys_role r on r.role_id=ur.role_id and r.role_status=1 where u.username=? and u.user_status=1 group by u.user_id,u.username,u.password_hash,u.real_name,u.job_title")) {
            ps.setString(1, username); try(ResultSet rs=ps.executeQuery()) {
                if(!rs.next() || !BCrypt.checkpw(password, rs.getString("password_hash"))) throw new IllegalArgumentException("用户名或密码错误");
                Map<String,Object> u=new LinkedHashMap<>(); u.put("userId",rs.getLong("user_id")); u.put("username",rs.getString("username")); u.put("realName",rs.getString("real_name")); u.put("jobTitle",rs.getString("job_title")); u.put("roleCodes",roleCodes(rs.getString("role_codes"))); req.getSession(true).setAttribute("user",u);
                try(PreparedStatement update=c.prepareStatement("update app_user set last_login_time=now(),last_login_ip=?,failed_login_count=0,locked_until=null where user_id=?")){update.setString(1,req.getRemoteAddr());update.setLong(2,rs.getLong("user_id"));update.executeUpdate();}
                return ApiResponse.ok(u);
            }
        }
    }

    private ApiResponse register(HttpServletRequest req) throws Exception {
        if (!allowRegistration(clientAddress(req), System.currentTimeMillis())) {
            return ApiResponse.tooMany("注册请求过于频繁，请稍后再试");
        }
        Map<String,Object> b=body(req);
        String username=str(b,"username"), password=str(b,"password"), confirmPassword=str(b,"confirmPassword");
        String realName=str(b,"realName"), email=str(b,"email"), phone=str(b,"phone");
        requireText(username,"用户名"); requireText(realName,"姓名"); requireText(password,"密码");
        if(!username.matches("[A-Za-z0-9_]{4,30}")) throw new IllegalArgumentException("用户名须为 4-30 位字母、数字或下划线");
        if(password.length()<8) throw new IllegalArgumentException("密码不得少于 8 位");
        if(!password.equals(confirmPassword)) throw new IllegalArgumentException("两次输入的密码不一致");
        if(email!=null&&!email.isBlank()&&!email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) throw new IllegalArgumentException("邮箱格式不正确");
        try(Connection c=Db.getConnection()){
            c.setAutoCommit(false);
            try{
                try(PreparedStatement check=c.prepareStatement("select username,email from app_user where lower(username)=lower(?) or (? is not null and lower(email)=lower(?)) for update")){
                    check.setString(1,username); setNullableString(check,2,email); setNullableString(check,3,email);
                    try(ResultSet rs=check.executeQuery()){while(rs.next()){if(rs.getString("username").equalsIgnoreCase(username))throw new IllegalArgumentException("用户名已存在");if(email!=null&&!email.isBlank()&&email.equalsIgnoreCase(rs.getString("email")))throw new IllegalArgumentException("邮箱已被使用");}}
                }
                long roleId;
                try(PreparedStatement role=c.prepareStatement("select role_id from sys_role where role_code='registered_user' and role_status=1")){try(ResultSet rs=role.executeQuery()){if(!rs.next())throw new IllegalArgumentException("注册角色尚未初始化，请先执行 050_registration_default_role.sql");roleId=rs.getLong(1);}}
                long userId;
                try(PreparedStatement insert=c.prepareStatement("insert into app_user(username,password_hash,real_name,phone,email,user_status,remark) values(?,?,?,?,?,1,'用户自助注册')",Statement.RETURN_GENERATED_KEYS)){
                    insert.setString(1,username);insert.setString(2,BCrypt.hashpw(password,BCrypt.gensalt(12)));insert.setString(3,realName);setNullableString(insert,4,phone);setNullableString(insert,5,email);insert.executeUpdate();try(ResultSet keys=insert.getGeneratedKeys()){if(!keys.next())throw new SQLException("注册用户主键生成失败");userId=keys.getLong(1);}
                }
                try(PreparedStatement assign=c.prepareStatement("insert into user_role(user_id,role_id,effective_date,valid_flag,remark) values(?,?,curdate(),1,'自助注册默认角色')")){assign.setLong(1,userId);assign.setLong(2,roleId);assign.executeUpdate();}
                try(PreparedStatement log=c.prepareStatement("insert into operation_log(user_id,username_snapshot,module_name,business_type,object_type,object_id,operation_description,request_method,request_url,response_code,operation_result,ip_address,user_agent) values(?,?,'用户注册','register','app_user',?,'用户自助注册','POST','/api/auth/register','200',1,?,?)")){log.setLong(1,userId);log.setString(2,username);log.setString(3,Long.toString(userId));log.setString(4,req.getRemoteAddr());log.setString(5,req.getHeader("User-Agent"));log.executeUpdate();}
                c.commit(); return ApiResponse.ok(Map.of("userId",userId,"username",username,"roleCode","registered_user"));
            }catch(Exception e){c.rollback();throw e;}finally{c.setAutoCommit(true);}
        }
    }

    private Map<String, String> health() throws SQLException {
        try (Connection connection = Db.getConnection(); PreparedStatement statement = connection.prepareStatement("select 1")) {
            statement.setQueryTimeout(5);
            try (ResultSet result = statement.executeQuery()) {
                if (!result.next() || result.getInt(1) != 1) throw new SQLException("Database health check failed");
            }
        }
        return Map.of("application", "commercial-complex-carbon", "database", "up");
    }

    private static boolean allowRegistration(String address, long now) {
        RegistrationWindow window = REGISTRATION_WINDOWS.compute(address, (key, current) -> {
            if (current == null || now - current.startedAt() >= REGISTRATION_WINDOW_MILLIS) {
                return new RegistrationWindow(now, 1);
            }
            return new RegistrationWindow(current.startedAt(), current.count() + 1);
        });
        if (REGISTRATION_WINDOWS.size() > 10000) {
            REGISTRATION_WINDOWS.entrySet().removeIf(entry -> now - entry.getValue().startedAt() >= REGISTRATION_WINDOW_MILLIS);
        }
        return window.count() <= REGISTRATION_LIMIT;
    }

    private static String clientAddress(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            String[] addresses = forwarded.split(",");
            return addresses[addresses.length - 1].trim();
        }
        return request.getRemoteAddr();
    }

    private record RegistrationWindow(long startedAt, int count) {}

    private void enforceBusinessWritePermission(HttpServletRequest req,String method){
        if("GET".equals(method))return;
        var session=req.getSession(false); if(session==null)return;
        Object value=session.getAttribute("user"); if(!(value instanceof Map<?,?> user))return;
        Object roleValue=user.get("roleCodes"); if(!(roleValue instanceof Collection<?> roles))return;
        boolean registered=roles.stream().anyMatch("registered_user"::equals);
        boolean admin=roles.stream().anyMatch("admin"::equals);
        if(registered&&!admin)throw new IllegalArgumentException("注册用户为只读角色，无权执行新增、修改或停用操作");
    }

    private static List<String> roleCodes(String value){return value==null||value.isBlank()?List.of():Arrays.stream(value.split(",")).map(String::trim).filter(s->!s.isBlank()).toList();}
    private static void setNullableString(PreparedStatement statement,int index,String value)throws SQLException{if(value==null||value.isBlank())statement.setNull(index,Types.VARCHAR);else statement.setString(index,value);}

    private ApiResponse enabledComplexes() throws SQLException { return query("select complex_id,complex_code,complex_name from commercial_complex where record_status=1 order by complex_id", List.of()); }

    private ApiResponse summary(HttpServletRequest req) throws SQLException {
        Map<String,Object> d=new LinkedHashMap<>();
        long complexId=longParam(req,"complexId",1); String end=req.getParameter("statDate"); if(end==null||end.isBlank())end=LocalDate.now().toString();
        String[] keys={"buildingCount","deviceCount","recentEnergyTce","recentCarbonKg","budgetExecutionRate","openAlerts","activeProjects","simulatedReductionKg"};
        String[] sql={"select count(*) from building where complex_id=? and record_status=1","select count(*) from meter_device md join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=? and md.device_status=1","select coalesce(sum(er.consumption_amount*et.standard_coal_coefficient),0) from energy_consumption_record er join energy_type et on et.energy_type_id=er.energy_type_id join meter_device md on md.meter_device_id=er.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=? and er.record_date between date_sub(?,interval 29 day) and ?","select coalesce(sum(car.carbon_emission_kg),0) from carbon_accounting_record car join energy_consumption_record er on er.energy_record_id=car.energy_record_id join meter_device md on md.meter_device_id=er.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=? and car.accounting_status in(1,2) and er.record_date between date_sub(?,interval 29 day) and ?","select coalesce(max(execution_rate),0) from carbon_budget where complex_id=? and budget_year=year(?)","select count(*) from alert_event where complex_id=? and event_status in(1,2)","select count(*) from energy_saving_project where complex_id=? and project_status=1","select coalesce(sum(pe.carbon_reduction_kg),0) from project_evaluation pe join energy_saving_project esp on esp.energy_saving_project_id=pe.energy_saving_project_id where esp.complex_id=? and pe.evaluation_status in(1,2)"};
        try(Connection c=Db.getConnection()){for(int i=0;i<sql.length;i++)try(PreparedStatement ps=c.prepareStatement(sql[i])){int n=1; if(i==0||i==1||i==5||i==6||i==7){ps.setLong(n++,complexId);} else if(i==2||i==3){ps.setLong(n++,complexId);ps.setDate(n++,java.sql.Date.valueOf(end));ps.setDate(n++,java.sql.Date.valueOf(end));} else {ps.setLong(n++,complexId);ps.setDate(n++,java.sql.Date.valueOf(end));} try(ResultSet rs=ps.executeQuery()){if(rs.next())d.put(keys[i],rs.getObject(1));}}}
        List<Map<String,Object>> breakdown=new ArrayList<>();
        try(Connection c=Db.getConnection();PreparedStatement ps=c.prepareStatement("select et.energy_name,et.standard_unit,round(sum(er.consumption_amount),3) raw_amount,round(sum(er.consumption_amount*et.standard_coal_coefficient),6) tce from energy_consumption_record er join energy_type et on et.energy_type_id=er.energy_type_id join meter_device md on md.meter_device_id=er.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=? and er.record_date between date_sub(?,interval 29 day) and ? group by et.energy_type_id,et.energy_name,et.standard_unit order by et.sort_no")){ps.setLong(1,complexId);ps.setDate(2,java.sql.Date.valueOf(end));ps.setDate(3,java.sql.Date.valueOf(end));try(ResultSet rs=ps.executeQuery()){breakdown=ResultSets.list(rs);}}
        d.put("energyBreakdown",breakdown); return ApiResponse.ok(d);
    }

    private ApiResponse chartTrend(HttpServletRequest req)throws SQLException { String sql="select er.record_date stat_date,round(sum(er.consumption_amount*et.standard_coal_coefficient),6) energy_tce,round(sum(coalesce(ca.carbon_emission_kg,0))/1000,6) carbon_t from energy_consumption_record er join energy_type et on et.energy_type_id=er.energy_type_id left join carbon_accounting_record ca on ca.energy_record_id=er.energy_record_id join meter_device md on md.meter_device_id=er.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=? and er.record_date between coalesce(?,date_sub(?,interval 29 day)) and coalesce(?,?) group by er.record_date order by er.record_date"; String end=req.getParameter("statDate");if(end==null||end.isBlank())end=LocalDate.now().toString();return query(sql,params(longParam(req,"complexId",1),nullable(req.getParameter("from")),java.sql.Date.valueOf(end),nullable(req.getParameter("to")),java.sql.Date.valueOf(end))); }
    private ApiResponse chartRanking(HttpServletRequest req)throws SQLException { String sql="select fa.area_name,round(sum(coalesce(ca.carbon_emission_kg,0))/1000,6) carbon_t from energy_consumption_record er join carbon_accounting_record ca on ca.energy_record_id=er.energy_record_id join meter_device md on md.meter_device_id=er.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id join functional_area fa on fa.area_id=mn.area_id where mn.complex_id=? and er.record_date between coalesce(?,date_sub(?,interval 29 day)) and coalesce(?,?) group by fa.area_id,fa.area_name order by carbon_t desc limit ?";String end=req.getParameter("statDate");if(end==null||end.isBlank())end=LocalDate.now().toString();return query(sql,params(longParam(req,"complexId",1),nullable(req.getParameter("from")),java.sql.Date.valueOf(end),nullable(req.getParameter("to")),java.sql.Date.valueOf(end),boundedInt(req,"limit",12,1,50))); }
    private ApiResponse heatmap(HttpServletRequest req)throws SQLException { String sql="select er.record_date stat_date,fa.area_name,round(sum(er.consumption_amount*et.standard_coal_coefficient),6) value_tce from energy_consumption_record er join energy_type et on et.energy_type_id=er.energy_type_id join meter_device md on md.meter_device_id=er.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id join functional_area fa on fa.area_id=mn.area_id where mn.complex_id=? and er.record_date between coalesce(?,date_sub(?,interval 29 day)) and coalesce(?,?) group by er.record_date,fa.area_id,fa.area_name order by er.record_date,fa.area_name";String end=req.getParameter("statDate");if(end==null||end.isBlank())end=LocalDate.now().toString();return query(sql,params(longParam(req,"complexId",1),nullable(req.getParameter("from")),java.sql.Date.valueOf(end),nullable(req.getParameter("to")),java.sql.Date.valueOf(end))); }
    private ApiResponse radar(HttpServletRequest req)throws SQLException { String sql="select fa.area_name,round(coalesce(metric.energy_tce,0)/nullif(fa.gross_area,0),6) unit_energy_tce,round(coalesce(metric.carbon_kg,0)/nullif(fa.gross_area,0),6) unit_carbon_kg,coalesce(budget.execution_rate,0) budget_rate,coalesce(alerts.alert_count,0) alerts from functional_area fa join building b on b.building_id=fa.building_id and b.complex_id=? and b.record_status=1 left join (select mn.area_id,sum(er.consumption_amount*et.standard_coal_coefficient) energy_tce,sum(ca.carbon_emission_kg) carbon_kg from meter_node mn join meter_device md on md.meter_node_id=mn.meter_node_id and md.device_status=1 join energy_consumption_record er on er.meter_device_id=md.meter_device_id join energy_type et on et.energy_type_id=er.energy_type_id left join carbon_accounting_record ca on ca.energy_record_id=er.energy_record_id where mn.node_status=1 group by mn.area_id) metric on metric.area_id=fa.area_id left join (select area_id,max(execution_rate) execution_rate from v_budget_execution group by area_id) budget on budget.area_id=fa.area_id left join (select area_id,count(*) alert_count from alert_event group by area_id) alerts on alerts.area_id=fa.area_id where fa.record_status=1 order by fa.sort_no"; return query(sql,params(longParam(req,"complexId",1))); }
    private ApiResponse gauge(HttpServletRequest req)throws SQLException { return query("select budget_code,budget_year,total_budget_emission_kg,actual_emission_kg,execution_rate,remaining_budget_kg from carbon_budget where complex_id=? and budget_year=year(?) order by budget_year desc limit 1",params(longParam(req,"complexId",1),java.sql.Date.valueOf(req.getParameter("statDate")==null||req.getParameter("statDate").isBlank()?LocalDate.now().toString():req.getParameter("statDate")))); }

    private ApiResponse profile(HttpServletRequest req)throws SQLException { long uid=sessionUserId(req); String sql="select u.user_id,u.username,u.real_name,u.employee_no,u.job_title,u.phone,u.email,u.avatar_url,u.last_login_time,u.last_login_ip,u.user_status,coalesce(r.role_name,'未分配') role_name from app_user u left join user_role ur on ur.user_id=u.user_id and ur.valid_flag=1 left join sys_role r on r.role_id=ur.role_id where u.user_id=?"; return query(sql,params(uid)); }
    private ApiResponse updateProfile(HttpServletRequest req,Map<String,Object>b)throws SQLException { long uid=sessionUserId(req); requireText(str(b,"realName"),"姓名"); return query("update app_user set real_name=?,phone=?,email=?,avatar_url=? where user_id=?",params(str(b,"realName"),str(b,"phone"),str(b,"email"),str(b,"avatarUrl"),uid)); }
    private ApiResponse changePassword(HttpServletRequest req,Map<String,Object>b)throws SQLException { long uid=sessionUserId(req); requireText(str(b,"currentPassword"),"当前密码"); String np=str(b,"newPassword"); requireText(np,"新密码"); if(np.length()<8)throw new IllegalArgumentException("新密码至少 8 位"); if(!np.equals(str(b,"confirmPassword")))throw new IllegalArgumentException("两次新密码不一致"); try(Connection c=Db.getConnection();PreparedStatement ps=c.prepareStatement("select password_hash from app_user where user_id=?")){ps.setLong(1,uid);try(ResultSet rs=ps.executeQuery()){if(!rs.next()||!BCrypt.checkpw(str(b,"currentPassword"),rs.getString(1)))throw new IllegalArgumentException("当前密码错误");}} return query("update app_user set password_hash=?,password_changed_at=now() where user_id=?",params(BCrypt.hashpw(np,BCrypt.gensalt(10)),uid)); }
    private ApiResponse profileLogs(HttpServletRequest req)throws SQLException { return query("select operation_time,module_name,business_type,operation_description,operation_result from operation_log where user_id=? order by operation_time desc limit 20",params(sessionUserId(req))); }
    private long sessionUserId(HttpServletRequest req){Object u=req.getSession(false)==null?null:req.getSession(false).getAttribute("user");if(u instanceof Map<?,?> m&&m.get("userId")!=null)return Long.parseLong(m.get("userId").toString());throw new IllegalArgumentException("登录状态已失效");}

    private ApiResponse allocationRules(HttpServletRequest req)throws SQLException {
        return query("select allocation_rule_id,rule_code,rule_name,allocation_method,effective_date,expiry_date,active_flag,remark from energy_allocation_rule where complex_id=? order by active_flag desc,effective_date desc",params(longParam(req,"complexId",1)));
    }

    private ApiResponse saveAllocationRule(HttpServletRequest req,Long id,Map<String,Object>b)throws SQLException {requireAnyRole(req,Set.of("admin","carbon_accountant"));String code=str(b,"ruleCode"),name=str(b,"ruleName"),method=allocationMethod(str(b,"allocationMethod"));requireText(code,"规则编码");requireText(name,"规则名称");String parameters=str(b,"parametersJson");if(parameters!=null&&!parameters.isBlank())try{Json.MAPPER.readTree(parameters);}catch(IOException e){throw new IllegalArgumentException("规则参数必须是合法 JSON");}if(id==null)return query("insert into energy_allocation_rule(complex_id,rule_code,rule_name,allocation_method,parameters_json,effective_date,active_flag,created_by_user_id,remark) values(?,?,?,?,cast(? as json),?,1,?,?)",params(num(b,"complexId",1),code,name,method,parameters,str(b,"effectiveDate",LocalDate.now().toString()),sessionUserId(req),str(b,"remark")));return query("update energy_allocation_rule set rule_code=?,rule_name=?,allocation_method=?,parameters_json=cast(? as json),effective_date=?,expiry_date=?,active_flag=?,remark=? where allocation_rule_id=? and complex_id=?",params(code,name,method,parameters,str(b,"effectiveDate",LocalDate.now().toString()),str(b,"expiryDate"),num(b,"activeFlag",1),str(b,"remark"),id,num(b,"complexId",1)));}
    private ApiResponse disableAllocationRule(HttpServletRequest req,long id)throws SQLException {requireAnyRole(req,Set.of("admin","carbon_accountant"));return query("update energy_allocation_rule set active_flag=0 where allocation_rule_id=?",params(id));}

    private ApiResponse merchantBillPreview(HttpServletRequest req)throws SQLException {
        int year=intParam(req,"year",statYear(req)),month=boundedInt(req,"month",statMonth(req),1,12);
        String method=allocationMethod(req.getParameter("method"));
        return callQuery("sp_preview_merchant_bill_allocation",params(longParam(req,"complexId",1),year,month,method));
    }

    private ApiResponse generateMerchantBills(HttpServletRequest req,Map<String,Object>b)throws SQLException {
        requireAnyRole(req,Set.of("admin","carbon_accountant","auditor"));
        long complexId=num(b,"complexId",1);int year=Math.toIntExact(num(b,"year",LocalDate.now().getYear()));int month=Math.toIntExact(num(b,"month",LocalDate.now().getMonthValue()));
        if(month<1||month>12)throw new IllegalArgumentException("月份范围为 1-12");
        return callQuery("sp_generate_merchant_energy_bills",params(complexId,year,month,allocationMethod(str(b,"method")),sessionUserId(req)));
    }

    private ApiResponse merchantBills(HttpServletRequest req)throws SQLException {
        Integer year=optionalInt(req.getParameter("year"),"year"),month=optionalInt(req.getParameter("month"),"month"),status=optionalInt(req.getParameter("status"),"status");
        Long merchantId=optionalLong(req.getParameter("merchantId"),"merchantId");
        List<Map<String,Object>> rows=callData("sp_query_merchant_energy_bills",params(longParam(req,"complexId",1),year,month,merchantId,status));
        return ApiResponse.ok(SqlSortHelper.sortRows("merchant_energy_bill",rows,req.getParameter("sortBy"),req.getParameter("sortOrder")));
    }

    private ApiResponse merchantBillDetail(long id)throws SQLException {
        Map<String,Object> data=new LinkedHashMap<>();
        data.put("bill",queryData("select b.*,m.merchant_code,m.merchant_name,m.contact_name,m.contact_phone,cc.complex_name,r.rule_name,r.allocation_method from merchant_energy_bill b join merchant m on m.merchant_id=b.merchant_id join commercial_complex cc on cc.complex_id=b.complex_id left join energy_allocation_rule r on r.allocation_rule_id=b.allocation_rule_id where b.merchant_energy_bill_id=?",params(id)));
        data.put("details",queryData("select d.*,et.energy_code,et.energy_name from merchant_energy_bill_detail d join energy_type et on et.energy_type_id=d.energy_type_id where d.merchant_energy_bill_id=? order by et.sort_no,d.source_type",params(id)));
        return ApiResponse.ok(data);
    }

    private ApiResponse voidMerchantBill(HttpServletRequest req,String path,Map<String,Object>b)throws SQLException {
        requireAnyRole(req,Set.of("admin","carbon_accountant","auditor"));
        String reason=str(b,"reason");requireText(reason,"作废原因");
        return callQuery("sp_void_merchant_energy_bill",params(Long.parseLong(path.split("/")[2]),sessionUserId(req),reason));
    }

    private ApiResponse confirmMerchantBill(HttpServletRequest req,long id)throws SQLException {requireAnyRole(req,Set.of("admin","carbon_accountant","auditor"));return callQuery("sp_confirm_merchant_energy_bill",params(id,sessionUserId(req)));}

    private ApiResponse monthlyReport(HttpServletRequest req)throws SQLException {
        long complexId=longParam(req,"complexId",1);int year=intParam(req,"year",statYear(req)),month=boundedInt(req,"month",statMonth(req),1,12);
        LocalDate start=LocalDate.of(year,month,1),end=start.withDayOfMonth(start.lengthOfMonth());
        Map<String,Object> data=new LinkedHashMap<>();
        List<Map<String,Object>> overview=callData("sp_generate_monthly_carbon_report_dataset",params(complexId,year,month));
        data.put("overview",overview);data.put("energyMix",callData("sp_query_energy_mix",params(complexId,year,month)));
        data.put("areaRanking",callData("sp_query_monthly_area_energy_carbon",params(complexId,year,month)));
        data.put("dailyTrend",queryData("select e.record_date,round(sum(e.consumption_amount*coalesce(et.standard_coal_coefficient,0)),6) energy_tce,round(sum(coalesce(car.carbon_emission_kg,0))/1000,6) carbon_tco2e from energy_consumption_record e join energy_type et on et.energy_type_id=e.energy_type_id join meter_device md on md.meter_device_id=e.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id left join carbon_accounting_record car on car.energy_record_id=e.energy_record_id where mn.complex_id=? and e.record_date between ? and ? group by e.record_date order by e.record_date",params(complexId,java.sql.Date.valueOf(start),java.sql.Date.valueOf(end))));
        data.put("topMerchants",callData("sp_query_top_merchants_carbon",params(complexId,year,month,10)));
        data.put("bills",callData("sp_query_merchant_energy_bills",params(complexId,year,month,null,null)));
        data.put("budget",queryData("select budget_code,budget_name,total_budget_emission_kg,actual_emission_kg,execution_rate,remaining_budget_kg from carbon_budget where complex_id=? and budget_year=?",params(complexId,year)));
        data.put("overBudget",queryData("select fa.area_name,d.budget_month,d.budget_emission_kg,d.actual_emission_kg,d.execution_rate,d.warning_level from carbon_budget_detail d join carbon_budget b on b.carbon_budget_id=d.carbon_budget_id join functional_area fa on fa.area_id=d.area_id where b.complex_id=? and b.budget_year=? and d.budget_month=? and d.over_budget_flag=1",params(complexId,year,month)));
        data.put("alerts",queryData("select severity_level,event_status,count(*) issue_count from alert_event where complex_id=? and occurred_at>=? and occurred_at<? group by severity_level,event_status",params(complexId,java.sql.Date.valueOf(start),java.sql.Date.valueOf(end.plusDays(1)))));
        data.put("tasks",queryData("select t.task_status,count(*) task_count from corrective_task t join alert_event a on a.alert_event_id=t.alert_event_id where a.complex_id=? and t.created_at>=? and t.created_at<? group by t.task_status",params(complexId,java.sql.Date.valueOf(start),java.sql.Date.valueOf(end.plusDays(1)))));
        data.put("projects",callData("sp_query_project_effect",params(complexId)));
        data.put("quality",queryData("select issue_rule,severity_level,issue_status,count(*) issue_count from data_quality_issue where complex_id=? and detected_at<? group by issue_rule,severity_level,issue_status",params(complexId,java.sql.Date.valueOf(end.plusDays(1)))));
        double completeness=overview.isEmpty()?0:Double.parseDouble(String.valueOf(overview.get(0).getOrDefault("date_completeness_rate",0)));
        List<String> advice=new ArrayList<>();if(completeness<100)advice.add("本月数据覆盖不足，建议补采缺失日期并完成审核后再用于正式管理决策。");
        if(!queryData("select 1 from data_quality_issue where complex_id=? and issue_status in(0,1) limit 1",params(complexId)).isEmpty())advice.add("存在待处理数据质量问题，建议先完成复核闭环再确认月度报告。");
        double totalCarbon=callData("sp_query_energy_mix",params(complexId,year,month)).stream().mapToDouble(row->Double.parseDouble(String.valueOf(row.getOrDefault("total_carbon_emission_kg",0)))).sum();
        double electricityCarbon=callData("sp_query_energy_mix",params(complexId,year,month)).stream().filter(row->"电力".equals(String.valueOf(row.get("energy_name")))).mapToDouble(row->Double.parseDouble(String.valueOf(row.getOrDefault("total_carbon_emission_kg",0)))).sum();
        if(totalCarbon>0&&electricityCarbon/totalCarbon>0.7)advice.add("电力碳排放占比超过 70%，建议重点优化空调、照明和重点用电设备。");
        if(!((List<?>)data.get("overBudget")).isEmpty())advice.add("存在超预算功能区域，建议优先开展区域能耗排查并落实整改责任。");
        if(advice.isEmpty())advice.add("本月数据覆盖完整，可结合高排放区域和商户排名制定下月节能计划。");
        data.put("managementAdvice",advice);data.put("disclaimer","本报告用于内部能源与碳排放管理分析，不作为正式碳核证或可交易碳资产依据。");
        return ApiResponse.ok(data);
    }

    private ApiResponse qualityRules()throws SQLException{return query("select rule_code ruleCode,rule_name ruleName,rule_description ruleDescription,severity_level severityLevel,threshold_json thresholdJson from data_quality_rule_config where active_flag=1 order by rule_code",List.of());}

    private ApiResponse scanQuality(HttpServletRequest req,Map<String,Object>b)throws SQLException {
        requireAnyRole(req,Set.of("admin","energy_manager"));
        long complexId=num(b,"complexId",1);java.sql.Date start=date(b,"startDate"),end=date(b,"endDate");if(start==null||end==null)throw new IllegalArgumentException("扫描起止日期不能为空");if(end.before(start))throw new IllegalArgumentException("结束日期不能早于开始日期");
        return callQuery("sp_scan_data_quality",params(complexId,start,end,sessionUserId(req)));
    }

    private ApiResponse qualityIssues(HttpServletRequest req)throws SQLException {
        int page=boundedInt(req,"page",1,1,100000),pageSize=boundedInt(req,"pageSize",20,1,200);long complexId=longParam(req,"complexId",1);String start=req.getParameter("startDate"),end=req.getParameter("endDate"),rule=req.getParameter("rule"),severity=req.getParameter("severity"),keyword=req.getParameter("keyword");Integer status=optionalInt(req.getParameter("status"),"status");Long device=optionalLong(req.getParameter("deviceId"),"deviceId");
        StringBuilder where=new StringBuilder(" from data_quality_issue q left join energy_consumption_record e on e.energy_record_id=q.energy_record_id left join meter_device md on md.meter_device_id=q.meter_device_id where q.complex_id=?");List<Object> values=new ArrayList<>();values.add(complexId);if(start!=null&&!start.isBlank()){where.append(" and coalesce(e.record_date,date(q.detected_at))>=?");values.add(start);}if(end!=null&&!end.isBlank()){where.append(" and coalesce(e.record_date,date(q.detected_at))<=?");values.add(end);}if(rule!=null&&!rule.isBlank()){where.append(" and q.issue_rule=?");values.add(rule);}if(severity!=null&&!severity.isBlank()){where.append(" and q.severity_level=?");values.add(severity);}if(status!=null){where.append(" and q.issue_status=?");values.add(status);}if(device!=null){where.append(" and q.meter_device_id=?");values.add(device);}if(keyword!=null&&!keyword.isBlank()){where.append(" and (q.issue_title like ? or md.device_name like ? or e.record_code like ?)");values.add("%"+keyword+"%");values.add("%"+keyword+"%");values.add("%"+keyword+"%");}
        long total;try(Connection c=Db.getConnection();PreparedStatement ps=c.prepareStatement("select count(*)"+where)){for(int i=0;i<values.size();i++)set(ps,i+1,values.get(i));try(ResultSet rs=ps.executeQuery()){rs.next();total=rs.getLong(1);}}
        SqlSortHelper.Order order=SqlSortHelper.resolve("data_quality_issue_query",req.getParameter("sortBy"),req.getParameter("sortOrder"));List<Object> pageValues=new ArrayList<>(values);pageValues.add(pageSize);pageValues.add((page-1L)*pageSize);List<Map<String,Object>> items=queryData("select q.*,md.device_code,md.device_name,e.record_code,e.record_date"+where+" order by "+order.sql()+" limit ? offset ?",pageValues);return ApiResponse.ok(Map.of("items",items,"total",total,"page",page,"pageSize",pageSize));
    }

    private ApiResponse qualitySummary(HttpServletRequest req)throws SQLException {
        String date=req.getParameter("statDate");if(date==null||date.isBlank())date=LocalDate.now().toString();
        return query("select count(*) total_count,sum(issue_status=0) pending_count,sum(issue_status=1) reviewing_count,sum(issue_status=2) resolved_count,sum(issue_status=3) false_positive_count,sum(severity_level='高' and issue_status in(0,1)) high_open_count,sum(issue_rule='missing_record' and issue_status in(0,1)) missing_count,sum(issue_rule='sudden_increase' and issue_status in(0,1)) sudden_count,sum(issue_rule='device_offline' and issue_status in(0,1)) offline_count,sum(issue_rule='pending_audit' and issue_status in(0,1)) pending_audit_count,sum(issue_rule='expired_emission_factor' and issue_status in(0,1)) expired_factor_count,(select round(count(distinct e.record_date)/30*100,2) from energy_consumption_record e join meter_device md on md.meter_device_id=e.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=? and e.record_date between date_sub(?,interval 29 day) and ?) data_completeness_rate from data_quality_issue where complex_id=?",params(longParam(req,"complexId",1),java.sql.Date.valueOf(date),java.sql.Date.valueOf(date),longParam(req,"complexId",1)));
    }

    private ApiResponse qualityDetail(long id)throws SQLException {
        Map<String,Object> data=new LinkedHashMap<>();data.put("issue",queryData("select q.*,md.device_code,md.device_name,e.record_code,e.record_date,e.start_reading,e.end_reading,e.consumption_amount,e.raw_payload,e.correction_reason,car.carbon_emission_kg from data_quality_issue q left join meter_device md on md.meter_device_id=q.meter_device_id left join energy_consumption_record e on e.energy_record_id=q.energy_record_id left join carbon_accounting_record car on car.energy_record_id=e.energy_record_id where q.data_quality_issue_id=?",params(id)));
        data.put("reviews",queryData("select r.*,u.username,u.real_name from data_quality_review r join app_user u on u.user_id=r.reviewer_user_id where r.data_quality_issue_id=? order by r.reviewed_at desc",params(id)));return ApiResponse.ok(data);
    }

    private ApiResponse qualityAction(HttpServletRequest req,String path,Map<String,Object>b,String procedure)throws SQLException {
        requireAnyRole(req,Set.of("admin","energy_manager","carbon_accountant","auditor"));
        String comment=str(b,"comment");requireText(comment,"处理说明");return callQuery(procedure,params(Long.parseLong(path.split("/")[3]),sessionUserId(req),comment));
    }

    private ApiResponse qualityCreateAlert(HttpServletRequest req,long issueId)throws SQLException {
        requireAnyRole(req,Set.of("admin","energy_manager"));long uid=sessionUserId(req);List<Map<String,Object>> issues=queryData("select * from data_quality_issue where data_quality_issue_id=?",params(issueId));if(issues.isEmpty())throw new IllegalArgumentException("数据质量问题不存在");Map<String,Object> issue=issues.get(0);
        try(Connection c=Db.getConnection()){c.setAutoCommit(false);try{
            long ruleId;try(PreparedStatement ps=c.prepareStatement("select alert_rule_id from alert_rule where complex_id=? and rule_status=1 order by alert_rule_id limit 1")){set(ps,1,issue.get("complex_id"));try(ResultSet rs=ps.executeQuery()){if(!rs.next())throw new IllegalArgumentException("当前综合体没有可用预警规则");ruleId=rs.getLong(1);}}
            try(PreparedStatement check=c.prepareStatement("select event_code from alert_event where complex_id=? and event_status in(1,2) and json_unquote(json_extract(source_snapshot,'$.dataQualityIssueId'))=? limit 1")){set(check,1,issue.get("complex_id"));check.setString(2,Long.toString(issueId));try(ResultSet rs=check.executeQuery()){if(rs.next()){c.rollback();return ApiResponse.ok(Map.of("eventCode",rs.getString(1),"reused",true));}}}
            String code="dq-"+issueId+"-"+System.currentTimeMillis();try(PreparedStatement ps=c.prepareStatement("insert into alert_event(alert_rule_id,complex_id,meter_device_id,energy_record_id,event_code,event_type,severity_level,event_title,event_content,occurred_at,first_seen_at,last_seen_at,event_status,source_snapshot,remark) values(?,?,?,?,?,?,?,?,?,now(),now(),now(),1,?,?)",Statement.RETURN_GENERATED_KEYS)){set(ps,1,ruleId);set(ps,2,issue.get("complex_id"));set(ps,3,issue.get("meter_device_id"));set(ps,4,issue.get("energy_record_id"));ps.setString(5,code);ps.setString(6,"数据质量");set(ps,7,issue.get("severity_level"));set(ps,8,issue.get("issue_title"));set(ps,9,issue.get("issue_description"));ps.setString(10,Json.write(Map.of("dataQualityIssueId",issueId)));ps.setString(11,"由数据质量问题 #"+issueId+" 创建");ps.executeUpdate();}
            c.commit();insertLog(uid,"data-quality.create-alert",issueId);return ApiResponse.ok(Map.of("eventCode",code));
        }catch(Exception e){c.rollback();if(e instanceof SQLException se)throw se;if(e instanceof IllegalArgumentException ia)throw ia;throw new SQLException(e);}}
    }

    private ApiResponse correctQualityRecord(HttpServletRequest req,long issueId,Map<String,Object>b)throws SQLException {
        requireAnyRole(req,Set.of("admin","energy_manager"));String reason=str(b,"reason");requireText(reason,"修正原因");BigDecimal start=decimal(b,"startReading"),end=decimal(b,"endReading");if(start==null||end==null||start.signum()<0||end.compareTo(start)<0)throw new IllegalArgumentException("修正读数无效，期末读数必须大于等于非负期初读数");long uid=sessionUserId(req);
        try(Connection c=Db.getConnection()){c.setAutoCommit(false);try{
            Map<String,Object> issue;try(PreparedStatement ps=c.prepareStatement("select * from data_quality_issue where data_quality_issue_id=? for update")){ps.setLong(1,issueId);try(ResultSet rs=ps.executeQuery()){if(!rs.next())throw new IllegalArgumentException("数据质量问题不存在");issue=row(rs);}}
            if(issue.get("energy_record_id")==null)throw new IllegalArgumentException("该问题没有可修正的能耗记录");long recordId=Long.parseLong(issue.get("energy_record_id").toString());Map<String,Object> before;
            try(PreparedStatement ps=c.prepareStatement("select e.*,car.carbon_emission_kg from energy_consumption_record e left join carbon_accounting_record car on car.energy_record_id=e.energy_record_id where e.energy_record_id=? for update")){ps.setLong(1,recordId);try(ResultSet rs=ps.executeQuery()){if(!rs.next())throw new IllegalArgumentException("关联能耗记录不存在");before=row(rs);}}
            try(PreparedStatement ps=c.prepareStatement("update energy_consumption_record set start_reading=?,end_reading=?,correction_reason=?,data_quality_status=3,abnormal_flag=0,audit_status=0 where energy_record_id=?")){ps.setBigDecimal(1,start);ps.setBigDecimal(2,end);ps.setString(3,reason);ps.setLong(4,recordId);ps.executeUpdate();}
            Map<String,Object> after;try(PreparedStatement ps=c.prepareStatement("select e.*,car.carbon_emission_kg from energy_consumption_record e left join carbon_accounting_record car on car.energy_record_id=e.energy_record_id where e.energy_record_id=?")){ps.setLong(1,recordId);try(ResultSet rs=ps.executeQuery()){rs.next();after=row(rs);}}
            try(PreparedStatement ps=c.prepareStatement("insert into data_quality_review(data_quality_issue_id,reviewer_user_id,review_action,before_snapshot,after_snapshot,review_comment) values(?,?,?,?,?,?)")){ps.setLong(1,issueId);ps.setLong(2,uid);ps.setString(3,"correct");ps.setString(4,Json.write(before));ps.setString(5,Json.write(after));ps.setString(6,reason);ps.executeUpdate();}
            try(PreparedStatement ps=c.prepareStatement("update data_quality_issue set issue_status=2,resolved_by_user_id=?,resolved_at=now(),resolution_type='corrected',resolution_note=? where data_quality_issue_id=?")){ps.setLong(1,uid);ps.setString(2,reason);ps.setLong(3,issueId);ps.executeUpdate();}
            c.commit();insertLog(uid,"data-quality.correct",recordId);return ApiResponse.ok(Map.of("energyRecordId",recordId,"before",before,"after",after));
        }catch(Exception e){c.rollback();if(e instanceof SQLException se)throw se;if(e instanceof IllegalArgumentException ia)throw ia;throw new SQLException(e);}}
    }

    private void requireAnyRole(HttpServletRequest req,Set<String> allowed)throws SQLException {long uid=sessionUserId(req);try(Connection c=Db.getConnection();PreparedStatement ps=c.prepareStatement("select count(*) from user_role ur join sys_role r on r.role_id=ur.role_id where ur.user_id=? and ur.valid_flag=1 and r.role_status=1 and r.role_code in ("+String.join(",",Collections.nCopies(allowed.size(),"?"))+")")){ps.setLong(1,uid);int index=2;for(String role:allowed)ps.setString(index++,role);try(ResultSet rs=ps.executeQuery()){rs.next();if(rs.getInt(1)==0)throw new IllegalArgumentException("当前角色没有执行该操作的权限");}}}
    private static Map<String,Object> row(ResultSet rs)throws SQLException {Map<String,Object> value=new LinkedHashMap<>();ResultSetMetaData meta=rs.getMetaData();for(int i=1;i<=meta.getColumnCount();i++)value.put(meta.getColumnLabel(i),rs.getObject(i));return value;}

    private static String allocationMethod(String value){String method=value==null||value.isBlank()?"lease_area":value;if(!Set.of("lease_area","contract_ratio","operating_days","manual").contains(method))throw new IllegalArgumentException("不支持的分摊方式");return method;}
    private static Integer optionalInt(String value,String name){if(value==null||value.isBlank())return null;try{return Integer.valueOf(value);}catch(NumberFormatException e){throw new IllegalArgumentException(name+"必须是整数");}}
    private static Long optionalLong(String value,String name){if(value==null||value.isBlank())return null;return parseLong(value,name);}

    private ApiResponse resource(HttpServletRequest req,String method,String path)throws Exception {
        String[] parts=path.split("/"); if(parts.length<2)throw new IllegalArgumentException("未知接口"); String resource=parts[1], table=TABLES.get(resource); if(table==null)throw new IllegalArgumentException("未知资源");
        if(method.equals("GET")){if(parts.length>=3&&parts[2].matches("\\d+"))return detail(table,Long.parseLong(parts[2]));return list(req,table);}
        if(PROCEDURE_RESOURCES.contains(resource)){if(method.equals("DELETE")&&parts.length>=3)return delete(resource,Long.parseLong(parts[2]));if(method.equals("POST")||method.equals("PUT"))return save(resource,body(req));}
        if(resource.equals("energy-records")&&(method.equals("POST")||method.equals("PUT")))return saveEnergyRecord(req,method,parts,body(req));
        if(resource.equals("corrective-tasks")&&method.equals("PUT")&&parts.length>=3)return updateTask(Long.parseLong(parts[2]),body(req));
        throw new IllegalArgumentException("不支持的请求方法");
    }

    private ApiResponse list(HttpServletRequest req,String table)throws SQLException {
        StringBuilder sql=new StringBuilder("select * from ").append(table).append(" where 1=1"); List<Object> p=new ArrayList<>(); String keyword=req.getParameter("keyword");
        if(keyword!=null&&!keyword.isBlank()){if(table.equals("commercial_complex")){sql.append(" and (complex_code like ? or complex_name like ? or address like ?)");p.add("%"+keyword+"%");p.add("%"+keyword+"%");p.add("%"+keyword+"%");}else{String col=switch(table){case "building"->"building_name";case "functional_area"->"area_name";case "merchant"->"merchant_name";case "meter_node"->"node_name";case "meter_device"->"device_name";case "energy_consumption_record"->"record_code";case "carbon_accounting_record"->"accounting_code";case "carbon_budget"->"budget_name";case "alert_event"->"event_title";case "corrective_task"->"task_title";case "energy_saving_project"->"project_name";case "project_evaluation"->"evaluation_conclusion";case "operation_log"->"module_name";default->"username";};sql.append(" and ").append(col).append(" like ?");p.add("%"+keyword+"%");}}
        if(table.equals("operation_log")){
            addTextFilter(req,sql,p,"module","module_name");
            addTextFilter(req,sql,p,"businessType","business_type");
            addTextFilter(req,sql,p,"username","username_snapshot");
            String start=req.getParameter("startDate"),end=req.getParameter("endDate");
            if(start!=null&&!start.isBlank()){sql.append(" and operation_time>=?");p.add(java.sql.Date.valueOf(start));}
            if(end!=null&&!end.isBlank()){sql.append(" and operation_time<date_add(?,interval 1 day)");p.add(java.sql.Date.valueOf(end));}
        }
        String complex=req.getParameter("complexId");if(complex!=null&&!complex.isBlank()&&!table.equals("commercial_complex")){long cid=parseLong(complex,"complexId");switch(table){case "building","merchant","carbon_budget","energy_saving_project"->{sql.append(" and complex_id=?");p.add(cid);}case "functional_area"->{sql.append(" and building_id in(select building_id from building where complex_id=?)");p.add(cid);}case "meter_node"->{sql.append(" and complex_id=?");p.add(cid);}case "meter_device"->{sql.append(" and meter_node_id in(select meter_node_id from meter_node where complex_id=?)");p.add(cid);}case "energy_consumption_record"->{sql.append(" and meter_device_id in(select md.meter_device_id from meter_device md join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=?)");p.add(cid);}case "carbon_accounting_record"->{sql.append(" and energy_record_id in(select er.energy_record_id from energy_consumption_record er join meter_device md on md.meter_device_id=er.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=?)");p.add(cid);}case "alert_event"->{sql.append(" and complex_id=?");p.add(cid);}case "corrective_task"->{sql.append(" and alert_event_id in(select alert_event_id from alert_event where complex_id=?)");p.add(cid);}case "project_evaluation"->{sql.append(" and energy_saving_project_id in(select energy_saving_project_id from energy_saving_project where complex_id=?)");p.add(cid);}}}
        String status=Set.of("building","functional_area").contains(table)?"record_status":table.equals("merchant")?"merchant_status":table.equals("meter_node")?"node_status":table.equals("meter_device")?"device_status":null;String statusFilter=req.getParameter("status");if(table.equals("commercial_complex")&&statusFilter!=null&&!statusFilter.isBlank()){sql.append(" and record_status=?");p.add(Integer.parseInt(statusFilter));}else if(status!=null){sql.append(" and ").append(status).append("=?");p.add(statusFilter!=null&&!statusFilter.isBlank()?Integer.parseInt(statusFilter):1);}
        int page=boundedInt(req,"page",1,1,100000), size=boundedInt(req,"pageSize",20,1,200); long total=count(table,sql.toString(),p);SqlSortHelper.Order order=SqlSortHelper.resolve(table,req.getParameter("sortBy"),req.getParameter("sortOrder"));sql.append(" order by ").append(order.sql()).append(" limit ? offset ?");p.add(size);p.add((page-1L)*size);ApiResponse rows=query(sql.toString(),p);return new ApiResponse(true,200,"操作成功",Map.of("items",rows.data(),"total",total,"page",page,"pageSize",size,"sortBy",order.key(),"sortOrder",order.direction()));
    }
    private static void addTextFilter(HttpServletRequest req,StringBuilder sql,List<Object> params,String parameter,String column){String value=req.getParameter(parameter);if(value!=null&&!value.isBlank()){sql.append(" and ").append(column).append("=?");params.add(value);}}
    private long count(String table,String where,List<Object> p)throws SQLException{String sql=where.replaceFirst("select \\*","select count(*)").replaceFirst(" order by.*$","");try(Connection c=Db.getConnection();PreparedStatement ps=c.prepareStatement(sql)){for(int i=0;i<p.size();i++)set(ps,i+1,p.get(i));try(ResultSet rs=ps.executeQuery()){rs.next();return rs.getLong(1);}}}
    private ApiResponse detail(String table,long id)throws SQLException{return query("select * from "+table+" where "+PRIMARY_KEYS.get(table)+"=?",params(id));}

    private ApiResponse save(String resource,Map<String,Object>b)throws SQLException{
        requireCore(resource,b);String call;List<Object>p;switch(resource){case "complexes"->{call="{call sp_save_commercial_complex(?,?,?,?,?,?,?,?,?,?,?,?)}";p=params(num(b,"complexId"),str(b,"complexCode"),str(b,"complexName"),str(b,"address"),decimal(b,"grossFloorArea"),str(b,"operatorName"),str(b,"propertyCompany"),str(b,"contactName"),str(b,"contactPhone"),num(b,"recordStatus",1),str(b,"remark"));}case "buildings"->{call="{call sp_save_building(?,?,?,?,?,?,?,?,?,?,?,?)}";p=params(num(b,"buildingId"),num(b,"complexId"),num(b,"departmentId"),str(b,"buildingCode"),str(b,"buildingName"),str(b,"buildingType"),decimal(b,"grossFloorArea"),num(b,"aboveGroundFloors",0),num(b,"undergroundFloors",0),num(b,"recordStatus",1),str(b,"remark"));}case "areas"->{call="{call sp_save_functional_area(?,?,?,?,?,?,?,?,?,?,?,?,?)}";p=params(num(b,"areaId"),num(b,"buildingId"),num(b,"departmentId"),str(b,"areaCode"),str(b,"areaName"),str(b,"areaType"),str(b,"floorNo"),decimal(b,"grossArea"),decimal(b,"rentableArea"),num(b,"publicAreaFlag",0),num(b,"recordStatus",1),str(b,"remark"));}case "merchants"->{call="{call sp_save_merchant(?,?,?,?,?,?,?,?,?,?,?,?)}";p=params(num(b,"merchantId"),num(b,"complexId"),str(b,"merchantCode"),str(b,"merchantName"),str(b,"category"),str(b,"brandName"),str(b,"contactName"),str(b,"contactPhone"),decimal(b,"operatingArea"),num(b,"merchantStatus",1),str(b,"remark"));}case "meter-nodes"->{validateNode(b);call="{call sp_save_meter_node(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)}";p=params(num(b,"meterNodeId"),num(b,"complexId"),num(b,"buildingId"),num(b,"areaId"),num(b,"merchantId"),num(b,"energyTypeId"),num(b,"parentNodeId"),str(b,"nodeCode"),str(b,"nodeName"),str(b,"nodeType"),num(b,"nodeLevel",1),str(b,"nodePath"),num(b,"virtualNodeFlag",0),num(b,"nodeStatus",1),str(b,"remark"));}case "meter-devices"->{requireText(str(b,"deviceCode"),"设备编码");requireText(str(b,"deviceName"),"设备名称");requireNumber(b,"meterNodeId","计量节点");requireNumber(b,"energyTypeId","能源类型");call="{call sp_save_meter_device(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)}";p=params(num(b,"meterDeviceId"),num(b,"meterNodeId"),num(b,"energyTypeId"),str(b,"deviceCode"),str(b,"deviceName"),str(b,"deviceType","meter"),str(b,"manufacturer"),str(b,"modelNumber"),str(b,"protocol"),decimal(b,"multiplier"),num(b,"collectionFrequencyMinutes",60),date(b,"installationDate"),num(b,"deviceStatus",1),str(b,"remark"));}default->throw new IllegalArgumentException("不支持的资源");}return callQuery(call,p,true);
    }
    private ApiResponse delete(String resource,long id)throws SQLException{if(resource.equals("meter-nodes")&&hasChildren(id))throw new IllegalArgumentException("当前节点存在子节点，请先停用或迁移子节点");String proc=Map.of("complexes","sp_delete_commercial_complex","buildings","sp_delete_building","areas","sp_delete_functional_area","merchants","sp_delete_merchant","meter-nodes","sp_delete_meter_node","meter-devices","sp_delete_meter_device").get(resource);return callQuery(proc,List.of(id));}

    private ApiResponse saveEnergyRecord(HttpServletRequest req,String method,String[] parts,Map<String,Object>b)throws Exception{
        requireText(str(b,"recordCode"),"记录编码");requireNumber(b,"meterDeviceId","计量设备");requireNumber(b,"energyTypeId","能源类型");requireText(str(b,"recordDate"),"记录日期");requireText(str(b,"periodStart"),"期初时间");requireText(str(b,"periodEnd"),"期末时间");BigDecimal start=decimal(b,"startReading"),end=decimal(b,"endReading");if(start==null||end==null)throw new IllegalArgumentException("期初和期末读数不能为空");if(start.signum()<0||end.signum()<0)throw new IllegalArgumentException("读数不能为负数");if(end.compareTo(start)<0)throw new IllegalArgumentException("期末读数不能小于期初读数");long audit=num(b,"auditStatus",0);if(audit<0||audit>2)throw new IllegalArgumentException("审核状态必须为 0、1 或 2");validateEnergyContext(num(b,"meterDeviceId"),num(b,"energyTypeId"),date(b,"recordDate"));String raw=str(b,"rawPayload");if(raw!=null&&!raw.isBlank())try{if(!Json.MAPPER.readTree(raw).isObject())throw new IllegalArgumentException("原始 JSON 必须为对象");}catch(IOException e){throw new IllegalArgumentException("原始 JSON 格式不合法");}
        Long id=parts.length>=3&&parts[2].matches("\\d+")?Long.valueOf(parts[2]):num(b,"energyRecordId");String sql=id==null?"insert into energy_consumption_record (meter_device_id,energy_type_id,record_code,record_date,period_start,period_end,start_reading,end_reading,multiplier,consumption_unit,unit_price,data_source,data_quality_status,abnormal_flag,audit_status,raw_payload,correction_reason,created_by_user_id) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)":"update energy_consumption_record set meter_device_id=?,energy_type_id=?,record_code=?,record_date=?,period_start=?,period_end=?,start_reading=?,end_reading=?,multiplier=?,consumption_unit=?,unit_price=?,data_source=?,data_quality_status=?,abnormal_flag=?,audit_status=?,raw_payload=?,correction_reason=? where energy_record_id=?";
        List<Object>p=id==null?params(num(b,"meterDeviceId"),num(b,"energyTypeId"),str(b,"recordCode"),date(b,"recordDate"),timestamp(b,"periodStart"),timestamp(b,"periodEnd"),start,end,decimal(b,"multiplier"),str(b,"consumptionUnit"),decimal(b,"unitPrice"),str(b,"dataSource","manual"),num(b,"dataQualityStatus",1),num(b,"abnormalFlag",0),num(b,"auditStatus",0),raw,str(b,"correctionReason"),userId(req)):params(num(b,"meterDeviceId"),num(b,"energyTypeId"),str(b,"recordCode"),date(b,"recordDate"),timestamp(b,"periodStart"),timestamp(b,"periodEnd"),start,end,decimal(b,"multiplier"),str(b,"consumptionUnit"),decimal(b,"unitPrice"),str(b,"dataSource","manual"),num(b,"dataQualityStatus",1),num(b,"abnormalFlag",0),num(b,"auditStatus",0),raw,str(b,"correctionReason"),id);return query(sql,p);
    }
    private ApiResponse updateTask(long id,Map<String,Object>b)throws SQLException{requireNumber(b,"taskStatus","任务状态");return query("update corrective_task set task_status=?,corrective_measure=?,handling_result=?,verification_result=?,verified_at=case when ?=1 then now() else verified_at end where corrective_task_id=?",params(num(b,"taskStatus"),str(b,"correctiveMeasure"),str(b,"handlingResult"),str(b,"verificationResult"),num(b,"taskStatus"),id));}
    private ApiResponse updateAlert(long id,boolean close,Map<String,Object>b)throws SQLException{long uid=userIdFromBodyOrSession(b);String sql=close?"update alert_event set event_status=3,closed_by_user_id=?,closed_at=now(),close_reason=? where alert_event_id=? and event_status in(1,2)":"update alert_event set event_status=2,acknowledged_by_user_id=?,acknowledged_at=now() where alert_event_id=? and event_status=1";List<Object>p=close?params(uid,str(b,"closeReason","验收关闭"),id):params(uid,id);ApiResponse r=query(sql,p);insertLog(uid,close?"alert.close":"alert.acknowledge",id);return r;}
    private void insertLog(long uid,String module,long id)throws SQLException{try(Connection c=Db.getConnection();PreparedStatement ps=c.prepareStatement("insert into operation_log(user_id,username_snapshot,module_name,business_type,object_type,object_id,operation_description,request_method,request_url,operation_result) values(?,?,?,?,?,?,?,?,?,1)")){ps.setLong(1,uid);ps.setString(2,"admin");ps.setString(3,module);ps.setString(4,"状态流转");ps.setString(5,"alert_event");ps.setString(6,Long.toString(id));ps.setString(7,module);ps.setString(8,"PUT");ps.setString(9,"/api/alerts/"+id);ps.executeUpdate();}}
    private boolean hasChildren(long id)throws SQLException{try(Connection c=Db.getConnection();PreparedStatement ps=c.prepareStatement("select count(*) from meter_node where parent_node_id=? and node_status=1")){ps.setLong(1,id);try(ResultSet rs=ps.executeQuery()){rs.next();return rs.getLong(1)>0;}}}
    private void validateEnergyContext(long deviceId,long energyTypeId,java.sql.Date recordDate)throws SQLException{try(Connection c=Db.getConnection();PreparedStatement ps=c.prepareStatement("select md.energy_type_id,(select count(*) from emission_factor ef where ef.energy_type_id=? and ef.active_flag=1 and ef.factor_status=1 and ? between ef.effective_date and coalesce(ef.expiry_date,'9999-12-31')) factor_count from meter_device md where md.meter_device_id=? and md.device_status=1")){ps.setLong(1,energyTypeId);ps.setDate(2,recordDate);ps.setLong(3,deviceId);try(ResultSet rs=ps.executeQuery()){if(!rs.next())throw new IllegalArgumentException("计量设备不存在或已停用");if(rs.getLong(1)!=energyTypeId)throw new IllegalArgumentException("能源类型与计量设备不一致");if(rs.getLong(2)==0)throw new IllegalArgumentException("该日期没有有效排放因子");}}}
    private void validateNode(Map<String,Object>b)throws SQLException{requireText(str(b,"nodeCode"),"节点编码");requireText(str(b,"nodeName"),"节点名称");requireText(str(b,"nodeType"),"节点类型");Long id=num(b,"meterNodeId"),parent=num(b,"parentNodeId");if(id!=null&&parent!=null&&id.equals(parent))throw new IllegalArgumentException("节点不能将自己设置为父节点");if(id!=null&&parent!=null){long current=parent;Set<Long>seen=new HashSet<>();try(Connection c=Db.getConnection();PreparedStatement ps=c.prepareStatement("select parent_node_id from meter_node where meter_node_id=?")){while(current>0&&seen.add(current)){if(current==id)throw new IllegalArgumentException("不能形成循环父子关系");ps.setLong(1,current);try(ResultSet rs=ps.executeQuery()){if(!rs.next()||rs.getObject(1)==null)break;current=rs.getLong(1);}}}}}
    private ApiResponse callQuery(String proc,List<Object>p)throws SQLException{return callQuery(proc,p,false);}
    private List<Map<String,Object>> callData(String proc,List<Object>p)throws SQLException {String call="{call "+proc+"("+String.join(",",Collections.nCopies(p.size(),"?"))+")}";try(Connection c=Db.getConnection();CallableStatement cs=c.prepareCall(call)){for(int i=0;i<p.size();i++)set(cs,i+1,p.get(i));if(cs.execute())try(ResultSet rs=cs.getResultSet()){return ResultSets.list(rs);}return List.of();}}
    private List<Map<String,Object>> queryData(String sql,List<Object>p)throws SQLException {try(Connection c=Db.getConnection();PreparedStatement ps=c.prepareStatement(sql)){for(int i=0;i<p.size();i++)set(ps,i+1,p.get(i));try(ResultSet rs=ps.executeQuery()){return ResultSets.list(rs);}}}
    private ApiResponse callQuery(String proc,List<Object>p,boolean out)throws SQLException{String call=proc.startsWith("{")?proc:"{call "+proc+"("+String.join(",",Collections.nCopies(p.size()+(out?1:0),"?"))+")}";try(Connection c=Db.getConnection();CallableStatement cs=c.prepareCall(call)){c.setAutoCommit(false);try{for(int i=0;i<p.size();i++)set(cs,i+1,p.get(i));if(out)cs.registerOutParameter(p.size()+1,Types.BIGINT);boolean result=cs.execute();c.commit();if(out)return ApiResponse.ok(Map.of("savedId",cs.getLong(p.size()+1)));if(result)try(ResultSet rs=cs.getResultSet()){return ApiResponse.ok(ResultSets.list(rs));}return ApiResponse.ok(Map.of());}catch(SQLException e){c.rollback();throw e;}}}
    private ApiResponse query(String sql,List<Object>p)throws SQLException{String op=sql.trim().toLowerCase(Locale.ROOT);try(Connection c=Db.getConnection();PreparedStatement ps=c.prepareStatement(sql,Statement.RETURN_GENERATED_KEYS)){for(int i=0;i<p.size();i++)set(ps,i+1,p.get(i));if(op.startsWith("insert")||op.startsWith("update")||op.startsWith("delete")){c.setAutoCommit(false);try{int n=ps.executeUpdate();long id=0;try(ResultSet keys=ps.getGeneratedKeys()){if(keys.next())id=keys.getLong(1);}c.commit();return ApiResponse.ok(Map.of("updated",n,"savedId",id));}catch(SQLException e){c.rollback();throw e;}}try(ResultSet rs=ps.executeQuery()){return ApiResponse.ok(ResultSets.list(rs));}}}

    private Map<String,Object> body(HttpServletRequest req)throws IOException{if(req.getContentType()==null||!req.getContentType().toLowerCase().contains("application/json"))throw new IllegalArgumentException("请求必须使用 application/json");return Json.MAPPER.readValue(req.getInputStream(),MAP_TYPE);}
    private static String sqlMessage(SQLException e){if(e.getErrorCode()==1062)return "编码或唯一字段已存在";if(e.getErrorCode()==1452)return "关联的父级或外键不存在";if(e.getErrorCode()==1451)return "存在关联数据，不能停用或删除";if(e.getErrorCode()==3819||e.getErrorCode()==1644)return e.getMessage().replaceAll("\\s+"," ");return "参数不符合数据库约束";}
    private static void requireText(String v,String name){if(v==null||v.isBlank())throw new IllegalArgumentException(name+"不能为空");}
    private static void requireNumber(Map<String,Object>m,String k,String name){if(num(m,k)==null)throw new IllegalArgumentException(name+"不能为空");}
    private static void requireCore(String r,Map<String,Object>b){switch(r){case "complexes"-> {requireText(str(b,"complexCode"),"综合体编码");requireText(str(b,"complexName"),"综合体名称");}case "buildings"->{requireNumber(b,"complexId","综合体");requireText(str(b,"buildingCode"),"建筑编码");requireText(str(b,"buildingName"),"建筑名称");}case "areas"->{requireNumber(b,"buildingId","建筑");requireText(str(b,"areaCode"),"区域编码");requireText(str(b,"areaName"),"区域名称");}case "merchants"->{requireNumber(b,"complexId","综合体");requireText(str(b,"merchantCode"),"商户编码");requireText(str(b,"merchantName"),"商户名称");}}
    }
    private static Long num(Map<String,Object>m,String k){Object v=m.get(k);return v==null||v.toString().isBlank()?null:Long.valueOf(v.toString());}
    private static long num(Map<String,Object>m,String k,long d){Long v=num(m,k);return v==null?d:v;}
    private static BigDecimal decimal(Map<String,Object>m,String k){Object v=m.get(k);return v==null||v.toString().isBlank()?null:new BigDecimal(v.toString());}
    private static String str(Map<String,Object>m,String k){Object v=m.get(k);return v==null?null:v.toString();}
    private static String str(Map<String,Object>m,String k,String d){String v=str(m,k);return v==null||v.isBlank()?d:v;}
    private static java.sql.Date date(Map<String,Object>m,String k){String v=str(m,k);return v==null||v.isBlank()?null:java.sql.Date.valueOf(v);}
    private static Timestamp timestamp(Map<String,Object>m,String k){String v=str(m,k);if(v==null||v.isBlank())return null;try{return Timestamp.valueOf(v.replace('T',' '));}catch(IllegalArgumentException e){throw new IllegalArgumentException(k+"格式应为 yyyy-MM-dd HH:mm:ss");}}
    private static Object nullable(String s){return s==null||s.isBlank()?null:s;}
    private static List<Object> params(Object...v){return Arrays.asList(v);}
    private static Long parseLong(String v,String name){try{return Long.valueOf(v);}catch(NumberFormatException e){throw new IllegalArgumentException(name+"必须是数字");}}
    private static long longParam(HttpServletRequest r,String n,long d){String v=r.getParameter(n);return v==null||v.isBlank()?d:parseLong(v,n);}
    private static int intParam(HttpServletRequest r,String n,int d){String v=r.getParameter(n);if(v==null||v.isBlank())return d;try{return Integer.parseInt(v);}catch(NumberFormatException e){throw new IllegalArgumentException(n+"必须是整数");}}
    private static int boundedInt(HttpServletRequest r,String n,int d,int min,int max){int v=intParam(r,n,d);if(v<min||v>max)throw new IllegalArgumentException(n+"范围为"+min+"-"+max);return v;}
    private static int statYear(HttpServletRequest r){String v=r.getParameter("statDate");return LocalDate.parse(v==null||v.isBlank()?LocalDate.now().toString():v).getYear();}
    private static int statMonth(HttpServletRequest r){String v=r.getParameter("statDate");return LocalDate.parse(v==null||v.isBlank()?LocalDate.now().toString():v).getMonthValue();}
    private static long userId(HttpServletRequest req){return userIdFromBodyOrSession(Map.of(),req);}
    private static long userIdFromBodyOrSession(Map<String,Object>b){return num(b,"userId",1);}
    private static long userIdFromBodyOrSession(Map<String,Object>b,HttpServletRequest req){Object u=req.getSession(false)==null?null:req.getSession(false).getAttribute("user");if(u instanceof Map<?,?> m&&m.get("userId")!=null)return Long.parseLong(m.get("userId").toString());return userIdFromBodyOrSession(b);}
    private static void set(PreparedStatement ps,int i,Object v)throws SQLException{if(v==null)ps.setNull(i,Types.VARCHAR);else if(v instanceof java.sql.Date d)ps.setDate(i,d);else if(v instanceof Timestamp t)ps.setTimestamp(i,t);else if(v instanceof Number n)ps.setBigDecimal(i,new BigDecimal(n.toString()));else ps.setString(i,v.toString());}
}
