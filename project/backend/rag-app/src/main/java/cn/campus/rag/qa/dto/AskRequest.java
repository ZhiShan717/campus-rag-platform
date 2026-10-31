package cn.campus.rag.qa.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 提问请求体。
 */
@Data
public class AskRequest {

    @NotBlank(message = "问题不能为空")
    @Size(max = 500, message = "问题不能超过 500 字")
    private String question;
}
