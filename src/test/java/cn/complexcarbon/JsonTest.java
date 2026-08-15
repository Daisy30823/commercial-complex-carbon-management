package cn.complexcarbon;

import cn.complexcarbon.util.Json;
import org.junit.jupiter.api.Test;
import java.util.Map;
import static org.junit.jupiter.api.Assertions.assertTrue;

class JsonTest {
    @Test void serializesApiDataAsJson() throws Exception {
        String json = Json.write(Map.of("success", true, "count", 3));
        assertTrue(json.contains("\"success\":true"));
        assertTrue(json.contains("\"count\":3"));
    }
}
