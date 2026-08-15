package cn.complexcarbon.util;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public final class Db {
    private static final Properties PROPERTIES = new Properties();
    static {
        String host = environment("DB_HOST", "MYSQLHOST");
        if (!hasCloudDatabaseEnvironment()) {
            try (InputStream in = Db.class.getClassLoader().getResourceAsStream("db.properties")) {
                if (in != null) PROPERTIES.load(in);
            } catch (IOException e) { throw new ExceptionInInitializerError(e); }
        } else {
            if (host == null) host = requiredEnvironment("DB_HOST", "MYSQLHOST");
            String port = requiredEnvironment("DB_PORT", "MYSQLPORT");
            String name = requiredEnvironment("DB_NAME", "MYSQLDATABASE");
            PROPERTIES.setProperty("db.url", "jdbc:mysql://" + host + ":" + port + "/" + name
                    + "?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai"
                    + "&useSSL=false&allowPublicKeyRetrieval=true");
            PROPERTIES.setProperty("db.username", requiredEnvironment("DB_USER", "MYSQLUSER"));
            PROPERTIES.setProperty("db.password", requiredEnvironment("DB_PASSWORD", "MYSQLPASSWORD"));
        }
        try { Class.forName("com.mysql.cj.jdbc.Driver"); } catch (ClassNotFoundException e) { throw new ExceptionInInitializerError(e); }
    }
    private Db() {}
    public static Connection getConnection() throws SQLException {
        String url = PROPERTIES.getProperty("db.url");
        if (url == null || url.isBlank()) throw new SQLException("未配置数据库连接，请复制 db.properties.example 为 db.properties");
        return DriverManager.getConnection(url, PROPERTIES.getProperty("db.username"), PROPERTIES.getProperty("db.password"));
    }

    private static String environment(String primary, String railway) {
        String value = System.getenv(primary);
        if (value == null || value.isBlank()) value = System.getenv(railway);
        return value == null || value.isBlank() ? null : value;
    }

    private static String requiredEnvironment(String primary, String railway) {
        String value = environment(primary, railway);
        if (value == null) throw new ExceptionInInitializerError("Missing database environment variable: " + primary);
        return value;
    }

    private static boolean hasCloudDatabaseEnvironment() {
        String[] names = {"DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD",
                "MYSQLHOST", "MYSQLPORT", "MYSQLDATABASE", "MYSQLUSER", "MYSQLPASSWORD"};
        for (String name : names) {
            String value = System.getenv(name);
            if (value != null && !value.isBlank()) return true;
        }
        return false;
    }
}
