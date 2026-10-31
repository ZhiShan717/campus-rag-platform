package cn.campus.rag.clause.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 新增/修改条款的请求体。
 */
@Data
public class ClauseRequest {

    @NotNull(message = "必须指定属于哪份制度")
    private Long documentId;

    @NotBlank(message = "条款号不能为空")
    private String clauseNo;

    @NotBlank(message = "条款内容不能为空")
    @Size(max = 2000, message = "条款内容不能超过 2000 字")
    private String content;
}
