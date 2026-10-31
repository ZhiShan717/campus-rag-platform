package cn.campus.rag.qa;

import java.util.List;

/** Python /retrieve 接口的响应体：一个 hits 数组 */
public record RetrieveResponse(List<RetrieveHit> hits) {
}
