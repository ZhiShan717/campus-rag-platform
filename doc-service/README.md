# 文档服务

管理知识库文档及其处理流程；后续衔接文件存储、解析与索引任务。

当前仅有 Java 17 Maven 模块和目录占位，尚无启动类、接口或业务实现，不能作为服务启动。Spring 等框架及依赖版本将在团队统一选型后加入。

## 目录约定

- `src/main/java/cn/campus/rag/document/controller/`：请求入口。
- `src/main/java/cn/campus/rag/document/service/`：业务逻辑。
- `src/main/resources/`：应用资源与非敏感配置。
- `src/test/java/cn/campus/rag/document/`：模块测试。

后续按实际代码需要增加数据访问、实体和配置等目录。不要在资源文件中提交真实账号、密码或密钥。

## 后续实现

文档元数据、上传与处理状态、解析任务和存储接入。

## 验证模块结构

在仓库根目录使用项目开发终端执行：

```powershell
mvn -pl doc-service -am validate
```

执行 `mvn validate` 可一次验证父 POM 和全部 Java 模块。此命令验证 Maven 结构，不表示服务已实现或可运行。
