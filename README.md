# 校园 RAG 知识库平台

团队公开仓库：[ZhiShan717/campus-rag-platform](https://github.com/ZhiShan717/campus-rag-platform)，默认分支 `main`。任何人都可浏览和通过 HTTPS 克隆；向原仓库推送仍需写入权限。

本仓库统一管理 Java 后端、Python RAG 运行时、Vue 前端和开发环境。**当前为工程目录骨架，业务应用尚未实现。** 六个 Java 模块已接入 Java 17 聚合 POM，基础环境与模型脚本可复用。

## 从这里开始

- **新队员**：先看[队员信息速查](docs/team/队员信息速查.md)，再按[完整接入手册](docs/team/团队协作与接入.md)准备本机环境。
- **负责人日常使用**：在 `environment/` 双击 `启动负责人环境.cmd`；开发使用 `启动开发终端.cmd` 或 `校园RAG开发环境.code-workspace`。
- **查资料或确认文件放哪里**：使用[文档导航](docs/README.md)与[目录及开发约定](docs/development/项目目录与开发约定.md)。

## 目录总览

```text
campus-rag-platform/
├── backend/          Java 后端，集中六个服务模块
├── frontend/         Vue 前端
├── rag-runtime/      Python 检索、编排与模型调用
├── database/         数据结构、迁移、样例与索引定义
├── deploy/           业务部署
├── tests/            跨模块验证
├── docs/             团队、开发、接口与架构文档
├── environment/      开发环境配置、脚本与启动入口
├── pom.xml           Java 聚合构建入口
├── .local/           本机工具、模型与服务数据
├── .venv/            本机 Python 虚拟环境
└── .setup/           本机状态、日志与检查记录
```

## 开发入口

| 位置 | 内容 |
| --- | --- |
| [backend/](backend/README.md)、`pom.xml` | Java 服务与聚合构建配置 |
| [rag-runtime/](rag-runtime/README.md) | Python 检索、编排、MCP 与评测 |
| [frontend/](frontend/README.md) | Vue 前端 |
| [database/](database/README.md) | 数据库迁移、开发样例与检索索引定义 |
| [deploy/](deploy/README.md)、[tests/](tests/README.md) | 业务部署与跨模块验证 |
| [docs/](docs/README.md) | 文档导航 |

Java 的全部模块仍在仓库根目录构建，指定模块时使用新路径：

```powershell
mvn -o -B validate
mvn -o -B -pl backend/doc-service -am validate
```

上述命令验证模块结构。Java 启动类、Python 业务 API 和前端工程入口仍待实现，目前没有业务启动命令或可访问的业务网站。

## 环境配置入口

环境脚本、开发中间件 Compose、依赖锁文件、本机启动入口、VS Code 工作区和原始安装手册统一放在 **[environment/](environment/README.md)**。负责人日常启动使用其中的 `启动负责人环境.cmd`，开发使用 `启动开发终端.cmd` 或 `校园RAG开发环境.code-workspace`；完整说明见[本机开发环境说明](environment/README.md)。

根目录 `.local/`、`.venv/`、`.setup/` 是独立的本机运行区，继续使用原路径，由 Git 排除，并在本项目 VS Code 工作区的文件列表中隐藏。环境凭据位于 `environment/.env`、`environment/.env.application`，也不提交仓库；成员自行准备环境和生成凭据。分享边界和文件归属统一见[目录及开发约定](docs/development/项目目录与开发约定.md)。

手册中的仓库占位符和环境版本差异，以本仓库文档为准。各模块完成工程初始化和业务实现后，再执行业务构建、启动、问答、引用、权限和评测验收。
