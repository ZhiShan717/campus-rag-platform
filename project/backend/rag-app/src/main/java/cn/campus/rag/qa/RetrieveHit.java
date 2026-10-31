package cn.campus.rag.qa;

/**
 * Python 返回的一条检索结果：哪个编号、多少分。
 * 只有编号和分数，不返回正文——正文以 Java 数据库里的为准，防止两边不一致。
 */
public record RetrieveHit(String chunkId, double score) {
}
