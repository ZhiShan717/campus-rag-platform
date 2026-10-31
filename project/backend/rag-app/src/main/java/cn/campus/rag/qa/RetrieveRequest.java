package cn.campus.rag.qa;

import java.util.List;

/**
 * 发给 Python 的检索请求。
 *
 * <p>注意 candidateChunkIds：Java 先把"有效制度的条款编号"筛好，
 * 再把这份名单交给 Python。Python 只能在这批编号里排序，不能自己扩大范围。
 * 这样即使 Python 那边写错，也不会把废止制度的条文捞出来。</p>
 */
public record RetrieveRequest(String query, List<String> candidateChunkIds, int topK) {
}
