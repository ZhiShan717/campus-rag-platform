# 业务项目入口

业务源码、部署定义、业务测试与团队开发资料集中在本目录；软件安装、依赖锁、开发中间件、模型准备和配置自检集中在仓库根目录的 [environment/](../environment/README.md)。

## 目录导航

| 位置 | 内容 |
| --- | --- |
| [backend/](backend/README.md) | 网关、认证、文档、检索、管理、评测六个 Java 服务 |
| [pom.xml](pom.xml) | Java 17 聚合构建入口，统一管理上述六个模块 |
| [rag-runtime/](rag-runtime/README.md) | Python 检索、重排、生成、编排、MCP 与评测 |
| [frontend/](frontend/README.md) | Vue 前端页面与接口调用的目录骨架 |
| [database/](database/README.md) | 业务迁移、可公开样例及 Elasticsearch 索引定义 |
| [deploy/](deploy/README.md) | 后续业务镜像、Nginx 与 Kubernetes 配置 |
| [tests/](tests/README.md) | 跨模块集成、端到端验证与构造材料 |
| [docs/](docs/README.md) | 队员接入、目录与开发约定、接口和架构资料 |

当前是工程骨架：Java 尚无业务启动类，Python 尚无 API 入口，前端尚无 `package.json`；没有可运行的业务网站或完整问答服务。

## 从哪里开始

1. 新队员阅读[队员信息速查](docs/team/队员信息速查.md)和[团队协作与接入](docs/team/团队协作与接入.md)。
2. 按[详细安装与配置指南](../environment/docs/详细安装与配置指南.md)或[PDF 版](../environment/output/pdf/校园RAG平台_详细安装与配置指南.pdf)准备环境，并执行其中第 27–31 节的配置验收。
3. 开发前阅读[目录与开发约定](docs/development/项目目录与开发约定.md)，与相关成员确认接口、依赖、表结构及分工。

## 命令的执行位置

文档未另行说明时，命令从**仓库根目录**执行，即本目录与 `environment/` 的共同上一级。负责人本机为 `D:\campus_RAG_work`，队员使用各自的实际克隆路径。

```powershell
# 在仓库根目录载入开发环境
. .\environment\Enter-DevEnvironment.ps1
# 验证 Java 聚合结构及指定模块
mvn.cmd -f .\project\pom.xml -o -B validate
mvn.cmd -f .\project\pom.xml -o -B -pl backend/doc-service -am validate
# 使用仓库根目录的 Python 虚拟环境校验依赖
.\.venv\Scripts\python.exe -m pip check
```

Maven 命令仅验证 POM 结构，不表示业务服务已经实现。Python 虚拟环境仍为仓库根目录 `.venv/`；工具、模型、Docker 数据及本机状态仍保存在仓库根目录 `.local/`、`.setup/`，均不提交 Git。

回到[仓库首页](../README.md)；环境启停、自检与安装说明见 [environment/README.md](../environment/README.md)。
