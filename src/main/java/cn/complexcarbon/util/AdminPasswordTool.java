package cn.complexcarbon.util;

import org.mindrot.jbcrypt.BCrypt;

public final class AdminPasswordTool {
    private AdminPasswordTool() {}

    public static void main(String[] args) {
        String username = System.getenv("ADMIN_USERNAME");
        String password = System.getenv("ADMIN_INITIAL_PASSWORD");
        if (username == null || !username.matches("[A-Za-z0-9_.-]{4,64}")) {
            throw new IllegalArgumentException("ADMIN_USERNAME must contain 4-64 letters, digits, dots, underscores or hyphens");
        }
        if (password == null || password.length() < 12 || password.equalsIgnoreCase("password")
                || password.equalsIgnoreCase(username)) {
            throw new IllegalArgumentException("ADMIN_INITIAL_PASSWORD must be at least 12 characters and not be a default password");
        }
        System.out.print(BCrypt.hashpw(password, BCrypt.gensalt(12)));
    }
}
