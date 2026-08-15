package cn.complexcarbon.filter;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.SessionCookieConfig;

public class SessionSecurityListener implements ServletContextListener {
    @Override
    public void contextInitialized(ServletContextEvent event) {
        SessionCookieConfig config = event.getServletContext().getSessionCookieConfig();
        config.setHttpOnly(true);
        config.setSecure(!"false".equalsIgnoreCase(System.getenv("SESSION_COOKIE_SECURE")));
    }
}
