package cn.complexcarbon.util;

import java.util.Map;

public record ApiResponse(boolean success, int code, String message, Object data) {
    public static ApiResponse ok(Object data) { return new ApiResponse(true, 200, "操作成功", data); }
    public static ApiResponse bad(String message) { return new ApiResponse(false, 400, message, Map.of()); }
    public static ApiResponse error(String message) { return new ApiResponse(false, 500, message, Map.of()); }
    public static ApiResponse unauthorized() { return new ApiResponse(false, 401, "登录状态已失效", Map.of()); }
    public static ApiResponse tooMany(String message) { return new ApiResponse(false, 429, message, Map.of()); }
}
