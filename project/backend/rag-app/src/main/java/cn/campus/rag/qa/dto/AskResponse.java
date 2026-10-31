package cn.campus.rag.qa.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.List;

/**
 * 问答响应。
 *
 * <p>found=false 的时候 answer 是一句"没有找到依据"，
 * citations 是空列表。前端据此显示"暂未收录相关政策"，
 * 而不是让模型硬编一个答案出来。</p>
 */
@Data
@AllArgsConstructor
public class AskResponse {

    /** 是否在有效制度里找到了依据 */
    private boolean found;

    private String answer;

    private List<Citation> citations;
}
