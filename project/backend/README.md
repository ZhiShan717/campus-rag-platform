# Java 后端

六个 Java 服务集中在此目录，聚合构建入口为 [project/pom.xml](../pom.xml)。各模块继续使用 Java 17、原 artifactId 与 `cn.campus.rag` 包前缀，父 POM 通过 `../../pom.xml` 引用。

| 模块 | 职责 |
| --- | --- |
| [gateway-service](gateway-service/README.md) | 网关、认证衔接与路由 |
| [auth-service](auth-service/README.md) | 用户、角色与权限 |
| [doc-service](doc-service/README.md) | 文档、版本与处理任务 |
| [search-service](search-service/README.md) | 检索与 Java/Python 协作 |
| [admin-service](admin-service/README.md) | 管理功能 |
| [eval-service](eval-service/README.md) | 评测任务与结果 |

在**仓库根目录**的开发终端验证全部模块或指定模块：

```powershell
mvn.cmd -f .\project\pom.xml -o -B validate
mvn.cmd -f .\project\pom.xml -o -B -pl backend/doc-service -am validate
```

当前仅有工程骨架，尚无 Spring 启动类或业务依赖，以上命令验证 Maven 结构。框架选型、接口、数据表和个人分工仍需团队统一，详见[开发约定](../docs/development/项目目录与开发约定.md)与[队员手册](../docs/team/团队协作与接入.md)。
