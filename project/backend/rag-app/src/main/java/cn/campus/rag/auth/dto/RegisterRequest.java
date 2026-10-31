package cn.campus.rag.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 注册请求体。
 *
 * <p>前端发 {"username":"zhangsan","password":"123456"}，
 * Spring 会把 JSON 自动变成这个对象（靠 @RequestBody）。</p>
 *
 * <p>@NotBlank 和 @Size 是校验注解，Controller 参数上加 @Valid 后生效：
 * 用户名空着、密码太短，请求直接被打回，根本进不了业务代码。</p>
 */
@Data
public class RegisterRequest {

    @NotBlank(message = "用户名不能为空")
    @Size(min = 3, max = 30, message = "用户名长度需在 3 到 30 之间")
    private String username;

    @NotBlank(message = "密码不能为空")
    @Size(min = 6, max = 50, message = "密码长度需在 6 到 50 之间")
    private String password;
}
