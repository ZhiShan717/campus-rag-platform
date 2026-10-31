package cn.campus.rag;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 启动类。整个项目就这一个 main 方法，跑起来它，整个后端就活了。
 *
 * <p>@SpringBootApplication 看起来只有一个注解，其实它一次干了三件事：</p>
 * <ol>
 *   <li>说明这个类是配置类</li>
 *   <li>开启自动配置——看到 web 依赖就自动配好 Tomcat，看到 h2 驱动就自动配好数据源</li>
 *   <li>扫描 cn.campus.rag 包下面的所有 @RestController / @Service / @Component，把它们装进容器</li>
 * </ol>
 *
 * <p>所以别的类都不需要写 main，也不需要手动 new，
 * 只要加上注解、放在这个包或子包里，Spring 就会自己找到它。</p>
 */
@SpringBootApplication
public class RagDemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(RagDemoApplication.class, args);
    }
}
