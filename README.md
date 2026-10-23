# 校园 RAG 知识库平台

团队公开仓库：[ZhiShan717/campus-rag-platform](https://github.com/ZhiShan717/campus-rag-platform)，默认分支 `main`。任何人都可浏览和通过 HTTPS 克隆；向原仓库推送仍需写入权限。

本仓库统一管理 Java 后端、Python RAG 运行时、Vue 前端和开发环境。**当前为工程目录骨架，业务应用尚未实现。** 六个 Java 模块已接入 Java 17 聚合 POM，基础环境与模型脚本可复用。

本说明与 2026-10-23 的实际文件结构一致。基础服务和模型曾在负责人电脑上验证，成员仍需准备各自环境；不能将目录或环境检查通过视为业务功能已经完成。

## 阅读与使用顺序

| 使用场景 | 先看什么 | 下一步 |
| --- | --- | --- |
| 新队员加入 | [队员信息速查](docs/team/队员信息速查.md) | 按[完整接入手册](docs/team/团队协作与接入.md)准备工具、服务和本人 GitHub 账号 |
| 开发环境操作 | [环境操作说明](environment/README.md) | 打开开发终端或用编辑器打开仓库，按需启动服务 |
| 领取模块任务 | 下方目录说明及各模块 README | 先对齐[接口](docs/api/README.md)、[架构](docs/architecture/README.md)和数据库约定，再实现功能 |
| 确认文件放哪里 | [目录与开发约定](docs/development/项目目录与开发约定.md) | 按源码、环境、文档和本机运行区的归属维护 |

获取项目：

```powershell
git clone https://github.com/ZhiShan717/campus-rag-platform.git
cd campus-rag-platform
```

克隆只获得仓库中的源码骨架、环境配置和说明，不会带上负责人电脑里的工具、模型、虚拟环境或数据库数据。

## 目录总览

```text
campus-rag-platform/
├── backend/                       Java 后端
│   ├── gateway-service/           网关与路由
│   ├── auth-service/              用户、角色与权限
│   ├── doc-service/               文档、版本与处理任务
│   ├── search-service/            检索与 Java/Python 协作
│   ├── admin-service/             管理功能
│   └── eval-service/              评测任务与结果
├── frontend/                      Vue 页面、组件与接口调用
├── rag-runtime/                   Python 检索、重排、生成、编排与 MCP
├── database/                      MySQL 迁移、开发样例与 ES 索引定义
├── deploy/                        业务 Docker、Nginx 与 Kubernetes 部署
├── tests/                         跨模块 integration、e2e 与 fixtures
├── docs/
│   ├── README.md                  文档总导航
│   ├── team/                      队员速查与完整接入手册
│   ├── development/               目录归属与开发规范
│   ├── api/                       接口契约
│   └── architecture/              架构决策
├── environment/                   环境脚本、启动入口、依赖锁与参考手册
├── pom.xml                        Java 17 聚合构建入口
├── README.md                      项目首页与文件索引
├── .editorconfig                  编辑器缩进、编码与换行约定
├── .gitattributes                 Git 文件类型与换行约定
├── .gitignore                     不提交的本机文件规则
├── .local/                        本机工具、模型与服务数据
├── .venv/                         本机 Python 虚拟环境
├── .setup/                        本机状态、日志与检查记录
└── .git/                          本地 Git 历史与远端信息
```

末尾四个以点开头的目录属于本机区域，不是业务源码；其中 `.local/`、`.venv/`、`.setup/` 不进入版本控制。空的开发目录用 `.gitkeep` 保留，加入真实文件后可删除对应占位。

## 项目目录与文件用途

| 目录 | 维护内容与关键位置 | 当前状态 |
| --- | --- | --- |
| [backend/](backend/README.md) | 六个 Java 服务；各模块有 `pom.xml`、`src/main/java/`、`src/main/resources/`、`src/test/java/` | 聚合结构已建立，尚无启动类与业务依赖 |
| [frontend/](frontend/README.md) | `src/views/` 页面、`components/` 组件、`api/` 调用、路由、状态与模块测试 | 已划分目录，尚无 `package.json`、包锁与应用入口 |
| [rag-runtime/](rag-runtime/README.md) | `src/` API 预留位置，`rag/` 检索生成，`graph/` 编排，`mcp_server/` 工具，`guardrails/` 检查，`eval/` 评测，`config/` 配置约定 | 已有目录与依赖入口，尚无业务 API 或完整问答链路 |
| [database/](database/README.md) | `mysql/migrations/` 迁移、`mysql/seeds/` 开发样例、`elasticsearch/index-templates/` 索引定义 | 尚无业务表、迁移 SQL 与索引定义；文件不会自动执行 |
| [deploy/](deploy/README.md) | `docker/` 业务镜像、`nginx/` 代理、`k8s/` 部署清单 | 预留目录，尚无业务部署产物 |
| [tests/](tests/README.md) | `integration/` 跨模块验证、`e2e/` 端到端验证、`fixtures/` 可公开的构造材料 | 预留目录，尚无业务测试框架或用例 |
| [docs/](docs/README.md) | 团队接入、开发规范、接口与架构资料 | 已有团队与目录说明，业务接口和设计待落实 |
| [environment/](environment/README.md) | 开发中间件 Compose、依赖锁、初始化、工具与模型脚本、Windows 启动入口、原始 PDF | 已有负责人本机配置；其他电脑运行前需适配路径和 Docker 配置 |

`environment/` 管开发环境，`deploy/` 管业务部署。模块自身测试跟随模块；跨模块测试集中在根 `tests/`。环境和模型检查使用 `environment/` 的现有脚本。

根目录文件的职责：

| 文件 | 用途 |
| --- | --- |
| [pom.xml](pom.xml) | 统一 Java 17 和六个 `backend/*-service` 模块；构建从仓库根目录执行 |
| [.editorconfig](.editorconfig) | 统一编码、缩进和文件末尾换行 |
| [.gitattributes](.gitattributes) | 统一 Git 换行处理及 PDF 等文件类型 |
| [.gitignore](.gitignore) | 排除真实凭据、运行数据、依赖、构建产物和日志 |

## 环境操作与结构检查

项目共用的 Windows 环境入口如下，均位于 `environment/`：

| 要做的事 | 入口 |
| --- | --- |
| 启动含消息队列的完整基础服务 | [Start-Services.ps1](environment/Start-Services.ps1)，加 `-Messaging` |
| 按需启动 Ollama | [Start-ModelService.ps1](environment/Start-ModelService.ps1) |
| 打开已配置的开发终端 | [启动开发终端.cmd](environment/启动开发终端.cmd) |
| 在 VS Code 中开发 | 用 VS Code 打开仓库根目录，按本人安装位置配置解释器和 Java 工具 |
| 仅启动默认五项基础服务 | [启动基础服务.cmd](environment/启动基础服务.cmd) |
| 检查工具和服务端口 | [检查开发环境.cmd](environment/检查开发环境.cmd)；认证与健康检查见[环境说明](environment/README.md) |
| 结束基础服务 | [停止基础服务.cmd](environment/停止基础服务.cmd)，保留数据卷；Ollama 另用 [Stop-ModelService.ps1](environment/Stop-ModelService.ps1)停止 |

现有开发终端和 Docker 管理脚本仍有安装路径及独立 Docker 配置约定。新队员先按[队员本机准备](docs/team/团队协作与接入.md#队员本机准备)完成适配；环境文件索引、依赖安装和模型准备步骤见 [environment/README.md](environment/README.md)。个人账号登录辅助、负责人启动包装、编辑器配置与自动化助手本机约定不随仓库分发。

Java 的全部模块仍在仓库根目录构建，指定模块时使用新路径：

```powershell
mvn -o -B validate
mvn -o -B -pl backend/doc-service -am validate
```

上述命令验证模块结构。Java 启动类、Python 业务 API 和前端工程入口仍待实现，目前没有业务启动命令或可访问的业务网站。

## 本机文件与团队共享

| 本机位置 | 内容与处理方式 |
| --- | --- |
| `.local/` | 已安装工具、模型、Docker 配置与数据，保留原路径；不分发或提交 |
| `.venv/` | 每人的 Python 环境，按统一锁文件自行创建和安装 |
| `.setup/` | 本机进程状态、检查日志和备份，不上传公开仓库 |
| `environment/.env`、`environment/.env.application` | 本机生成的随机凭据和应用连接参数，与对应数据卷配套保管，不提交 |

上述三个运行目录保留既有本机路径。团队通过 Git 分享源码、共用环境脚本、模板、依赖锁、文档、迁移和可公开样例；模型权重、数据盘、安装包、个人授权、密码和本机专用辅助文件不通过仓库分享。忽略规则只控制提交范围，本机已有工具、数据和辅助入口继续保留。

各成员当前使用自己的本地服务，`127.0.0.1` 指各自电脑；没有团队共享服务器。MySQL 通过仓库统一结构与开发样例，不共用负责人数据盘或管理员账号。地址、版本与模型参数统一查[接入手册](docs/team/团队协作与接入.md)和[环境说明](environment/README.md)，文件归属细则见[目录与开发约定](docs/development/项目目录与开发约定.md)。

## 协作与文档维护

队员用本人 GitHub 账号，有原仓库写入权限时推送任务分支，否则通过个人 Fork 提交 Pull Request；具体步骤见[代码协作](docs/team/团队协作与接入.md#代码协作)。模块分工、框架依赖、接口、业务端口和验收标准仍需团队确定。

新增或移动目录时同步更新本 README 与对应目录的 README；跨模块接口和设计分别在 `docs/api/`、`docs/architecture/` 维护，目录规则在开发约定中维护。维护完成后检查链接与相关功能，再按项目工作约定提交、推送并确认远端同步。

手册中的仓库占位符和环境版本差异，以本仓库文档为准。各模块完成工程初始化和业务实现后，再执行业务构建、启动、问答、引用、权限和评测验收。
