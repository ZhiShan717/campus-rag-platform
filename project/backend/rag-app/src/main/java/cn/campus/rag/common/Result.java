package cn.campus.rag.common;

/**
 * 统一返回结构。所有接口都返回这个壳子，前端只需要判断 code。
 *
 * <p>为什么不直接返回对象？因为出错的时候也得有统一的形状：
 * 成功是 {code:0, message:"ok", data:{...}}，失败是 {code:400, message:"用户名已存在", data:null}。
 * 前端拿到响应先看 code，不用猜这次返回的是不是错误。</p>
 */
public class Result<T> {

    /** 0 表示成功，非 0 表示失败 */
    private int code;
    private String message;
    private T data;

    public Result() {
    }

    public Result(int code, String message, T data) {
        this.code = code;
        this.message = message;
        this.data = data;
    }

    /** 成功并且有数据 */
    public static <T> Result<T> ok(T data) {
        return new Result<>(0, "ok", data);
    }

    /** 成功但没有数据要返回（比如删除） */
    public static <T> Result<T> ok() {
        return new Result<>(0, "ok", null);
    }

    /** 失败 */
    public static <T> Result<T> fail(int code, String message) {
        return new Result<>(code, message, null);
    }

    public int getCode() {
        return code;
    }

    public void setCode(int code) {
        this.code = code;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public T getData() {
        return data;
    }

    public void setData(T data) {
        this.data = data;
    }
}
