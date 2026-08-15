package cn.complexcarbon;

import cn.complexcarbon.util.ApiResponse;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class ApiResponseTest {
    @Test void successResponseHasContractFields() {
        ApiResponse response = ApiResponse.ok("demo");
        assertTrue(response.success());
        assertEquals(200, response.code());
        assertEquals("demo", response.data());
    }

    @Test void badResponseIsClientError() {
        ApiResponse response = ApiResponse.bad("参数错误");
        assertFalse(response.success());
        assertEquals(400, response.code());
    }
}
