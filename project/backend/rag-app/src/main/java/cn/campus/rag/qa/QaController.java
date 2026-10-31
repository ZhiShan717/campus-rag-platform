package cn.campus.rag.qa;

import cn.campus.rag.common.Result;
import cn.campus.rag.qa.dto.AskRequest;
import cn.campus.rag.qa.dto.AskResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 问答接口。
 *
 * <p>登录后才有资格问——因为每次提问都要记是谁问的，
 * 第二周做"历史记录"和"反馈"都依赖这个身份。</p>
 */
@RestController
@RequestMapping("/api/qa")
public class QaController {

    private final QaService qaService;

    public QaController(QaService qaService) {
        this.qaService = qaService;
    }

    /** POST /api/qa/ask  {"question":"国家奖学金多少钱"} */
    @PostMapping("/ask")
    public Result<AskResponse> ask(@Valid @RequestBody AskRequest req) {
        return Result.ok(qaService.ask(req.getQuestion()));
    }
}
