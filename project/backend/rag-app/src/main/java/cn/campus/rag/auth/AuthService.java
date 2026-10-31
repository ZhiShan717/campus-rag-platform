package cn.campus.rag.auth;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import cn.campus.rag.auth.dto.LoginRequest;
import cn.campus.rag.auth.dto.LoginResponse;
import cn.campus.rag.auth.dto.RegisterRequest;
import cn.campus.rag.common.BizException;
import cn.campus.rag.user.User;
import cn.campus.rag.user.UserMapper;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * 登录注册的业务逻辑。
 *
 * <p>Controller 只负责收请求、返结果，真正的规则都在这里：
 * 用户名不能重复、密码要加密、密码错了不能说"这个用户不存在"（会被撞库）。</p>
 */
@Service
public class AuthService {

    private final UserMapper userMapper;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;

    public AuthService(UserMapper userMapper, JwtUtil jwtUtil, PasswordEncoder passwordEncoder) {
        this.userMapper = userMapper;
        this.jwtUtil = jwtUtil;
        this.passwordEncoder = passwordEncoder;
    }

    /**
     * 注册。默认角色是 USER（普通用户），管理员只能由管理员手工开通。
     */
    public void register(RegisterRequest req) {
        // 先查重。数据库上虽然有 UNIQUE 约束，但提前查能给出更友好的提示
        User exist = userMapper.selectOne(
                Wrappers.<User>lambdaQuery().eq(User::getUsername, req.getUsername())
        );
        if (exist != null) {
            throw new BizException("用户名已存在");
        }

        User user = new User();
        user.setUsername(req.getUsername());
        // 关键：绝不能存明文。BCrypt 每次加密结果都不一样，但 matches 能验出对不对
        user.setPasswordHash(passwordEncoder.encode(req.getPassword()));
        user.setRole("USER");
        userMapper.insert(user);
    }

    /**
     * 登录。校验通过就签发 token。
     */
    public LoginResponse login(LoginRequest req) {
        User user = userMapper.selectOne(
                Wrappers.<User>lambdaQuery().eq(User::getUsername, req.getUsername())
        );

        // 用户名不存在和密码错误，返回同一句话。
        // 如果分开提示，攻击者就能试探出"哪些用户名是存在的"
        if (user == null || !passwordEncoder.matches(req.getPassword(), user.getPasswordHash())) {
            throw new BizException(401, "用户名或密码错误");
        }

        String token = jwtUtil.createToken(user.getId(), user.getUsername(), user.getRole());
        return new LoginResponse(token, user.getId(), user.getUsername(), user.getRole());
    }

    /**
     * 查当前登录用户。信息直接从 UserContext 拿，不用查库——
     * token 里已经带了这些字段，拦截器早就解析好了。
     */
    public UserContext.LoginUser current() {
        UserContext.LoginUser user = UserContext.get();
        if (user == null) {
            throw new BizException(401, "未登录");
        }
        return user;
    }
}
