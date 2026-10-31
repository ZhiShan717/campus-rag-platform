package cn.campus.rag.common;

/**
 * 业务异常。
 *
 * <p>什么时候用它？当你发现"这个请求本身没错，但业务上不允许"的时候。
 * 比如用户名重复、制度不存在、密码错误。
 * 抛出去之后，GlobalExceptionHandler 会把它接住，转成 {code, message} 返回给前端。</p>
 *
 * <p>extends RuntimeException = 继承"运行时异常"。好处是不用每层都写 try-catch，
 * 随便哪一层 throw 出去，都会被最外层的统一异常处理器接住。</p>
 */
public class BizException extends RuntimeException {

    private final int code;

    public BizException(String message) {
        this(400, message);
    }

    public BizException(int code, String message) {
        super(message);
        this.code = code;
    }

    public int getCode() {
        return code;
    }
}
