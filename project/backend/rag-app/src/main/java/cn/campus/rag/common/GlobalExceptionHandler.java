package cn.campus.rag.common;

import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 全局异常处理器。
 *
 * <p>@RestControllerAdvice 的意思是：整个项目里任何 Controller 抛出来的异常，
 * 都会先到这里过一遍，由它决定返回什么 JSON。</p>
 *
 * <p>好处是 Controller 里不用写 try-catch，
 * 业务代码只管 throw new BizException("用户名已存在")，剩下的交给这里。</p>
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    /** 业务异常：用户名重复、密码错误、制度不存在…… */
    @ExceptionHandler(BizException.class)
    public Result<Void> handleBiz(BizException e) {
        return Result.fail(e.getCode(), e.getMessage());
    }

    /** 参数校验失败：@NotBlank 之类的注解没通过时会走这里 */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public Result<Void> handleValidation(MethodArgumentNotValidException e) {
        String msg = e.getBindingResult().getFieldErrors().isEmpty()
                ? "参数不合法"
                : e.getBindingResult().getFieldErrors().get(0).getDefaultMessage();
        return Result.fail(400, msg);
    }

    /** 兜底：任何没被上面接住的异常 */
    @ExceptionHandler(Exception.class)
    public Result<Void> handleOther(Exception e) {
        // 堆栈打到服务端日志，给前端只留一句人话。
        // 为什么不能把 e.getMessage() 返回去——它可能带着 SQL、表名、列名，
        // 等于把数据库结构白送给外面的人。
        e.printStackTrace();
        return Result.fail(500, "服务器内部错误，请查看服务端日志");
    }
}
