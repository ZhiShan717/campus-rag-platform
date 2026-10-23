# 校园 RAG 知识库平台

团队公开仓库：[ZhiShan717/campus-rag-platform](https://github.com/ZhiShan717/campus-rag-platform)，默认分支 `main`。任何人都可浏览和通过 HTTPS 克隆；向原仓库推送仍需写入权限。

本仓库集中管理 Java 平台、Python RAG 运行时和 Vue 前端。六个 Java 模块已接入 Java 17 聚合 POM，Python、前端、数据库、部署和测试目录已建立；当前为工程目录骨架，业务功能和可运行的业务应用仍待实现。

## 项目入口

| 位置 | 内容 |
| --- | --- |
| `pom.xml`、六个 `*-service/` | Java 服务与聚合构建配置 |
| [rag-runtime/](rag-runtime/README.md) | Python 检索、编排、MCP 与评测 |
| [frontend/](frontend/README.md) | Vue 前端 |
| [database/](database/README.md) | 数据库迁移、开发样例与检索索引定义 |
| [deploy/](deploy/README.md)、[tests/](tests/README.md) | 业务部署与跨模块验证 |
| [docs/](docs/项目目录与开发约定.md) | 项目目录约定、团队接入、接口与架构文档 |

新队员先阅读[团队协作与接入](docs/团队协作与接入.md)，克隆项目并准备各自的开发环境。有写入权限的队员通过任务分支提交 Pull Request；没有写入权限时，通过个人 Fork 提交 Pull Request。详细模块职责见[项目目录与开发约定](docs/项目目录与开发约定.md)。

## 环境配置入口

环境脚本、开发中间件 Compose、依赖锁文件、本机启动入口、VS Code 工作区和原始安装手册统一放在 **[environment/](environment/README.md)**。负责人日常启动使用其中的 `启动负责人环境.cmd`，开发使用 `启动开发终端.cmd` 或 `校园RAG开发环境.code-workspace`；完整说明见[本机开发环境说明](environment/README.md)。

根目录 `.local/`、`.venv/`、`.setup/` 是独立的本机运行区，保存已有工具、模型、服务数据、虚拟环境与检查记录，继续使用原路径并由 Git 排除。环境凭据位于 `environment/.env`、`environment/.env.application`，也不提交仓库。文件分类见[文件夹说明](docs/文件夹说明.md)。

手册中的仓库占位符和环境版本差异，以本仓库文档为准。各模块完成工程初始化和业务实现后，再执行业务构建、启动、问答、引用、权限和评测验收。
