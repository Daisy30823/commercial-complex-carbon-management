package cn.complexcarbon.util;

import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class ResultSets {
    private ResultSets() {}
    public static List<Map<String,Object>> list(ResultSet rs) throws SQLException {
        List<Map<String,Object>> rows = new ArrayList<>();
        ResultSetMetaData meta = rs.getMetaData();
        while (rs.next()) {
            Map<String,Object> row = new LinkedHashMap<>();
            for (int i = 1; i <= meta.getColumnCount(); i++) row.put(meta.getColumnLabel(i), rs.getObject(i));
            rows.add(row);
        }
        return rows;
    }
}
