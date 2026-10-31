package cn.campus.rag.qa.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

/**
 * 一条引用。前端拿它渲染"答案下面的出处"。
 *
 * <p>这是整个项目最值钱的地方：答案可以简单，但**必须能点回到原文**。
 * 学校场景里，学生要的是"哪份文件第几条这么写的"，不是一个看起来很聪明的回答。</p>
 */
@Data
@AllArgsConstructor
public class Citation {

    private String chunkId;

    private Long documentId;

    private String documentTitle;

    private String version;

    private String clauseNo;

    private String content;

    /** Python 返回的相关度，0 到 1 */
    private Double score;
}
