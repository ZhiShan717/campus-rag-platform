package cn.campus.rag.qa;

import cn.campus.rag.common.BizException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.List;

/**
 * 调 Python 检索服务的客户端。
 *
 * <p>RestClient 是 Spring 6.1 引入的同步 HTTP 客户端，
 * 比老的 RestTemplate 写法更顺：post().uri().body().retrieve().body(类)。</p>
 *
 * <p>超时必须设。不设的话 Python 那边卡住，Java 线程就跟着卡死，
 * 一个卡死两个卡死，整个服务就假死了——这是线上最典型的雪崩。</p>
 */
@Component
public class PythonClient {

    private final RestClient restClient;

    public PythonClient(@Value("${app.python.base-url}") String baseUrl,
                        @Value("${app.python.timeout-millis}") int timeoutMillis) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(timeoutMillis);
        factory.setReadTimeout(timeoutMillis);

        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .requestFactory(factory)
                .build();
    }

    /**
     * 请求 Python 对候选条款排序。
     *
     * @param question        学生的问题
     * @param candidateChunkIds Java 筛好的有效条款编号
     * @return 排好序的命中列表
     */
    public List<RetrieveHit> retrieve(String question, List<String> candidateChunkIds) {
        try {
            RetrieveResponse response = restClient.post()
                    .uri("/retrieve")
                    .body(new RetrieveRequest(question, candidateChunkIds, 5))
                    .retrieve()
                    .body(RetrieveResponse.class);

            return response == null || response.hits() == null ? List.of() : response.hits();
        } catch (Exception e) {
            // 检索服务挂了，不能当成"没有答案"糊弄过去，
            // 要明确告诉调用方"服务异常"，这是两种完全不同的情况
            throw new BizException(503, "检索服务暂时不可用：" + e.getMessage());
        }
    }
}
