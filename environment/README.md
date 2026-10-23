# 项目开发环境

本目录维护团队共享的开发中间件、Python 依赖、模型准备和环境检查工具。项目业务代码分别位于 `backend/`、`rag-runtime/` 和 `frontend/`；当前仍处于目录骨架阶段，启动基础服务不代表业务平台已经可用。队员先阅读[团队协作与接入](../docs/team/团队协作与接入.md)，完整目录见[项目目录与开发约定](../docs/development/项目目录与开发约定.md)。

完整的 Windows 软件安装、实际仓库路径、脚本适配及分层验收步骤见[详细安装与配置指南 PDF](../output/pdf/校园RAG平台_详细安装与配置指南.pdf)，对应[可编辑正文](../docs/team/详细安装与配置指南.md)以当前仓库修订。新队员复用本人已有 Docker Desktop 时，优先阅读指南第 09-11 节，避免直接切换负责人独立数据目录启动器。

软件官网、阿里云安装包镜像、pip/npm/Maven 依赖源及其区别集中在指南第 24-26 节；下载地址仅作为备选来源，不会自动改变现有脚本使用的官方源或项目锁定版本。

## 使用前确认

- 当前脚本面向 Windows PowerShell，Docker Desktop 使用 WSL2 后端和 Linux 容器。凭据初始化使用 Windows 文件权限，CPU 模型安装固定 Python 3.11、Windows x64 的 PyTorch 包；其他系统需另行适配。
- 先安装 Java 17、Maven 3.9、Python 3.11、Git、Docker Desktop；Node.js 按后续前端依赖要求配置，需要本地生成模型时安装 Ollama。工具本身不随仓库分发。
- [Enter-DevEnvironment.ps1](Enter-DevEnvironment.ps1) 含已有机器的 Java、Maven 等工具路径；[Start-ContainerEngine.ps1](Start-ContainerEngine.ps1)、[Initialize-ContainerClient.ps1](Initialize-ContainerClient.ps1) 与 [Common.ps1](Common.ps1) 使用工作区独立 Docker 配置和 `desktop-linux` 上下文。队员需按自己的安装位置、Docker 上下文及数据目录核对和适配后再执行；这些入口目前不保证跨机器直接运行。
- `Start-ContainerEngine.ps1` 会使用 `.local/docker-profile/` 的独立配置，并设置该配置的数据目录。已有 Docker 环境应先核对数据盘和配置，避免切换到其他数据目录后误以为原容器丢失。
- 下列命令从仓库根目录执行。个人登录辅助、负责人启动入口和编辑器工作区配置只在本机保留，不随 Git 分发。

## 首次准备与日常操作

完成上述路径适配后，在 Python 3.11 终端创建项目虚拟环境并安装 SDK：

```powershell
python -m venv .venv
.\environment\Install-PythonDependencies.ps1
```

初始化本机凭据，再启动五项基础服务：

```powershell
.\environment\Initialize-Environment.ps1
.\environment\Start-Services.ps1
```

需要 RocketMQ 时，以带参数的启动入口启用消息组件：

```powershell
.\environment\Start-Services.ps1 -Messaging
```

检查工具、依赖与服务认证；未启用消息组件时，省略检查命令的 `-Messaging`：

```powershell
.\environment\Check-Environment.ps1
.\environment\Test-Services.ps1 -Messaging
```

按需生成供业务代码接入的本机连接参数，并准备或启动模型：

```powershell
.\environment\Initialize-ApplicationEnvironment.ps1
.\environment\Prepare-Models.ps1
```

模型已准备好时，使用 `Start-ModelService.ps1` 启动 Ollama，使用 `Test-Models.ps1` 重新验收。首次模型准备会下载大型依赖和权重，应预留磁盘、网络与内存资源。

结束工作时：

```powershell
.\environment\Stop-Services.ps1
.\environment\Stop-ModelService.ps1
```

停止基础服务会移除这套环境的容器，保留命名数据卷和凭据；不会退出整个 Docker Desktop。模型停止脚本仅停止本环境记录且身份核验一致的 Ollama 进程。不要使用删除数据卷的选项代替日常停止操作。

## 文件索引

| 分类 | 文件与用途 |
| --- | --- |
| 双击入口 | [启动基础服务.cmd](启动基础服务.cmd)、[停止基础服务.cmd](停止基础服务.cmd)、[检查开发环境.cmd](检查开发环境.cmd) 分别调用对应服务和检查脚本；消息组件需用带 `-Messaging` 的 PowerShell 入口 |
| 开发终端 | [启动开发终端.cmd](启动开发终端.cmd)、[Start-DevTerminal.cmd](Start-DevTerminal.cmd) 调用 [Enter-DevEnvironment.ps1](Enter-DevEnvironment.ps1)，设置当前终端的工具与模型路径 |
| 凭据初始化 | [Initialize-Environment.ps1](Initialize-Environment.ps1) 生成基础服务凭据；[Initialize-ApplicationEnvironment.ps1](Initialize-ApplicationEnvironment.ps1) 汇总应用连接参数并生成 APP/JWT 密钥 |
| 容器与服务 | [Start-ContainerEngine.ps1](Start-ContainerEngine.ps1)、[Initialize-ContainerClient.ps1](Initialize-ContainerClient.ps1) 准备本机 Docker；[Start-Services.ps1](Start-Services.ps1)、[Stop-Services.ps1](Stop-Services.ps1) 管理服务；[Common.ps1](Common.ps1) 提供公共函数 |
| 环境与服务验收 | [Check-Environment.ps1](Check-Environment.ps1) 检查工具、SDK、模型 API 和端口；[Test-Services.ps1](Test-Services.ps1) 检查容器健康、认证及 IK 中文分词，`-Messaging` 另检查消息组件 |
| SDK 依赖 | [Install-PythonDependencies.ps1](Install-PythonDependencies.ps1) 使用 [requirements-rag.lock.txt](requirements-rag.lock.txt) 安装；[requirements-rag.in](requirements-rag.in) 为依赖声明；[Test-PythonDependencies.py](Test-PythonDependencies.py) 检查兼容性及离线 SDK 调用 |
| 模型依赖 | [Install-ModelDependencies.ps1](Install-ModelDependencies.ps1) 按 [requirements-models.lock.txt](requirements-models.lock.txt) 安装 CPU 推理依赖，同时遵守 SDK 锁约束；[requirements-models.in](requirements-models.in) 为依赖声明 |
| 模型准备与服务 | [Prepare-Models.ps1](Prepare-Models.ps1) 安装依赖、下载和验收；[Test-Models.ps1](Test-Models.ps1) 验收已有模型；[Start-ModelService.ps1](Start-ModelService.ps1)、[Stop-ModelService.ps1](Stop-ModelService.ps1) 管理 Ollama |
| 模型内部助手 | [model-download.py](model-download.py) 固定 BAAI 模型提交并核验权重；[model-download-wheels.py](model-download-wheels.py) 下载并核验依赖包；[model-pull-ollama.py](model-pull-ollama.py) 拉取并校验 Qwen digest；[model-verify.py](model-verify.py) 执行模型推理验收 |
| 中间件配置 | [docker-compose.yml](docker-compose.yml)、[elasticsearch/Dockerfile](elasticsearch/Dockerfile)、[rocketmq/broker.conf](rocketmq/broker.conf) 定义开发服务、匹配的 IK 插件和本机消息配置 |
| 参数与资料 | [model-env.example](model-env.example) 为无密钥模型参数；[SOURCES.md](SOURCES.md) 记录镜像和版本来源；[原始项目手册](docs/校园级RAG知识库平台环境安装与首次运行手册.pdf) 为最初安装参考，现行操作以仓库说明为准 |
| Git 排除规则 | [.gitignore](.gitignore) 与根目录规则共同排除凭据、安装包、缓存、模型、虚拟环境和本机运行数据 |

日常安装使用锁文件；重新解析依赖时才使用依赖声明，并审查和更新对应锁文件。模型 Python 助手属于环境准备工具，业务接口应在 `rag-runtime/` 实现。

## 基础服务与连接信息

Compose 项目名为 `campus-rag-dev`，服务端口均绑定 `127.0.0.1`，使用独立持久化卷。以下地址属于每位队员自己的电脑，不是团队共享服务器。

| 服务 | 本机地址 | 用户与凭据变量 |
| --- | --- | --- |
| MySQL 8.0 | `127.0.0.1:13306` | 库 `campus_rag`，用户 `campus_dev`，密码 `MYSQL_PASSWORD` |
| Redis 7.4.2 | `127.0.0.1:6379` | `REDIS_PASSWORD` |
| Elasticsearch 8.11.4 + IK 8.11.4 | `http://127.0.0.1:9200` | 用户 `elastic`，密码 `ELASTIC_PASSWORD` |
| MinIO 2024 | API `http://127.0.0.1:9000`，控制台 `http://127.0.0.1:9001` | `MINIO_ROOT_USER`、`MINIO_ROOT_PASSWORD` |
| Nacos 2.3.2 | `http://127.0.0.1:8848/nacos`，另映射 9848/9849 | 用户 `nacos`，密码 `NACOS_ADMIN_PASSWORD` |
| RocketMQ 5.3.1 | NameServer `127.0.0.1:9876`；Broker `127.0.0.1:10911`，另映射 10909/10912 | 使用 `-Messaging` 启用 |
| Ollama | `http://127.0.0.1:11434` | 本地模型 API |

MySQL 默认宿主机端口为 13306，可在本机 `.env` 中配置 `MYSQL_PORT`；同一 Compose 网络内使用服务名和容器端口 3306。RocketMQ 当前公告地址为 `127.0.0.1`，适用于 Windows 宿主机客户端，其他容器或其他电脑的客户端需调整网络配置。消息服务首次启动会初始化数据卷目录权限。

基础服务内存上限合计约 3.5 GiB，消息组件额外约 1.4 GiB；这些上限不代表实际占用，也不包括 Docker、模型及业务应用开销。

## 本机凭据与运行数据

- `environment/.env` 由初始化脚本为各服务随机生成凭据，并设置 Windows 文件权限，仅授予当前用户、SYSTEM 和管理员访问。重复运行保留已有值；Nacos 管理员密码由服务启动流程初始化。
- `environment/.env.application` 由应用参数初始化脚本生成，包含服务连接信息、模型路径和独立随机 APP/JWT 密钥。已有文件不会被覆盖；业务代码需将变量名接入实际配置，尚未实现的业务地址需按代码填写。
- 每位队员自行生成本机凭据。不要把负责人的密码、令牌或应用密钥发给队员，也不要提交到仓库；团队通过仓库共享表结构和样例数据。
- `.env` 应与对应数据卷共同妥善保管。修改或重新生成文件不会自动轮换数据库内已有密码，丢失原文件可能导致无法连接已有数据。
- 脚本将虚拟环境放在 `.venv/`，模型、工具和缓存放在 `.local/`，检查输出和进程状态放在 `.setup/`。这些工作区相对目录均不随 Git 分发。
- Compose 验证使用 `config --quiet`，避免将展开后的凭据打印到终端或共享记录中。

## 模型约定与接入限制

| 用途 | 模型与配置 |
| --- | --- |
| 中文嵌入 | `BAAI/bge-large-zh-v1.5`，目录 `.local/models/bge-large-zh-v1.5`，输出 **1024 维** |
| 重排 | `BAAI/bge-reranker-base`，目录 `.local/models/bge-reranker-base` |
| 本地生成 | Ollama `qwen3:1.7b`，目录 `.local/ollama-models`，固定 digest 校验 |
| 请求参数 | Ollama 请求显式设置 `keep_alive=0`、`options.num_ctx=2048`，小批量调用控制内存 |

模型下载固定版本并校验权重；同名 Ollama 标签变化时需复核。重新验收使用 `Test-Models.ps1`，检查嵌入维度、相关性、重排和生成结果；这不替代真实业务的完整 RAG 与权限验收。

- 原始手册中 large 嵌入模型的 768 维描述有误，业务 Elasticsearch `dense_vector.dims` 应与实际 1024 维输出一致。
- Spring Boot、Spring Cloud 和 Spring Cloud Alibaba 的组合需按实际 POM 与官方兼容关系确认，不能直接照搬原始手册的版本组合。
- MinIO 使用固定摘要的 OpenEBS 同版本镜像，来源说明见 [SOURCES.md](SOURCES.md)。
- 当前 Compose 只提供基础中间件，尚未提供业务表、索引、JWT 接口或业务服务。Nginx、Kubernetes、Sentinel、Seata、SkyWalking 等增强组件未在本目录启用。
