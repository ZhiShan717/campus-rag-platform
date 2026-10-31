package cn.campus.rag.config;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import cn.campus.rag.user.User;
import cn.campus.rag.user.UserMapper;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * 启动时补一个管理员账号。
 *
 * <p>为什么不写在 data.sql 里？因为 BCrypt 哈希是一串随机盐算出来的，
 * 手写进 SQL 容易出错，而且不同人电脑上算出来的还不一样。
 * 让程序自己在启动时加密、插入，最稳。</p>
 *
 * <p>CommandLineRunner 是 Spring Boot 提供的钩子：
 * 容器启动完成后会自动执行一次 run 方法。</p>
 */
@Component
public class DataInitializer implements CommandLineRunner {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    public DataInitializer(UserMapper userMapper, PasswordEncoder passwordEncoder) {
        this.userMapper = userMapper;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        User exist = userMapper.selectOne(
                Wrappers.<User>lambdaQuery().eq(User::getUsername, "admin")
        );
        if (exist != null) {
            return;
        }

        User admin = new User();
        admin.setUsername("admin");
        admin.setPasswordHash(passwordEncoder.encode("admin123"));
        admin.setRole("ADMIN");
        userMapper.insert(admin);

        System.out.println("[init] 已创建管理员账号 admin / admin123");
    }
}
