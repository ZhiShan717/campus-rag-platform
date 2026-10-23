# 检索与问答服务

承接检索与问答业务；后续调用 Python RAG 能力并组织检索结果、答案和引用。

当前仅有 Java 17 Maven 模块和目录占位，尚无启动类、接口或业务实现，不能作为服务启动。Spring 等框架及依赖版本将在团队统一选型后加入。

## 目录约定

- `src/main/java/cn/campus/rag/search/controller/`：请求入口。
- `src/main/java/cn/campus/rag/search/service/`：业务逻辑。
- `src/main/resources/`：应用资源与非敏感配置。
- `src/test/java/cn/campus/rag/search/`：模块测试。

后续按实际代码需要增加数据访问、实体和配置等目录。不要在资源文件中提交真实账号、密码或密钥。

## 后续实现

检索与问答流程、权限过滤、Python 服务调用和引用结果组织。

## 验证模块结构

在仓库根目录使用项目开发终端执行：

```powershell
mvn.cmd -f .\project\pom.xml -o -B -pl backend/search-service -am validate
```

在仓库根目录执行 `mvn.cmd -f .\project\pom.xml -o -B validate` 可一次验证父 POM 和全部 Java 模块。此命令验证 Maven 结构，不表示服务已实现或可运行。
