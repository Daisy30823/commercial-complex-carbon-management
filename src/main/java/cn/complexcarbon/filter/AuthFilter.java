package cn.complexcarbon.filter;

import cn.complexcarbon.util.ApiResponse;
import cn.complexcarbon.util.Json;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

public class AuthFilter implements Filter {
    @Override public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        String path = req.getRequestURI().substring(req.getContextPath().length());
        if (path.startsWith("/api/auth/") || path.equals("/api/health")) { chain.doFilter(request, response); return; }
        if (req.getSession(false) != null && req.getSession(false).getAttribute("user") != null) { chain.doFilter(request, response); return; }
        if (path.startsWith("/api/")) {
            HttpServletResponse resp = (HttpServletResponse) response;
            resp.setStatus(401); resp.setContentType("application/json;charset=UTF-8");
            resp.getWriter().write(Json.write(ApiResponse.unauthorized())); return;
        }
        ((HttpServletResponse) response).sendRedirect(req.getContextPath() + "/login.jsp");
    }
}
