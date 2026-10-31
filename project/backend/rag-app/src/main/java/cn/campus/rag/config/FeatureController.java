package cn.campus.rag.config;

import cn.campus.rag.common.Result;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 功能开关。
 *
 * <p>前端启动时先请求这个，根据返回值决定显示哪些按钮。
 * 比如 mock=true 时页面上会亮一个"当前使用模拟检索"的小标签，
 * 避免演示时把假的当成真的。</p>
 */
@RestController
@RequestMapping("/api/features")
public class FeatureController {

    @Value("${app.python.mock:true}")
    private boolean pythonMock;

    @GetMapping
    public Result<Map<String, Object>> features() {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("pythonMock", pythonMock);
        map.put("project", "校园级 RAG 知识库平台");
        map.put("version", "week1");
        return Result.ok(map);
    }
}
