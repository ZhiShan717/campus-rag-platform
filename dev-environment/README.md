# 本机开发环境说明

配置日期：2026-10-22，补充验收：2026-10-23。按[《校园级RAG知识库平台环境安装与首次运行手册》](../docs/参考资料/校园级RAG知识库平台环境安装与首次运行手册.pdf)准备，按项目负责人角色配置开发工具、完整基础服务、Python AI 依赖和本地模型。团队私有仓库已创建：[campus-rag-platform](https://github.com/ZhiShan717/campus-rag-platform)，已建立[项目目录骨架](../docs/项目目录与开发约定.md)，业务功能仍待实现。队员接入请先看[团队协作与接入](../docs/团队协作与接入.md)，目录整理见[文件夹说明](../docs/文件夹说明.md)。

下文 `.local`、`.venv`、`.setup` 均相对于 `D:\campus_RAG_work`；凭据文件的完整位置为 `D:\campus_RAG_work\dev-environment\.env`。

Docker 已于 2026-10-22 23:43（北京时间）完成修复和真实重启验收：原来的七项服务全部健康，九个持久化卷、原容器和凭据均保留；MinIO 登录、IK 中文分词、Nacos 随机密码和 RocketMQ 实际注册全部通过。普通终端和 Docker 图形界面均可使用。

## 日常使用

负责人可直接双击上一级目录的 `启动负责人环境.cmd`，启动七项完整基础服务和 Ollama API。打开图形界面使用桌面或开始菜单的 **Docker Desktop**，也可以双击上一级的 `启动Docker.cmd`。

1. 双击上一级目录的 `启动开发终端.cmd`，进入已配置的开发终端。
2. 双击 `启动基础服务.cmd` 启动 MySQL、Redis、Elasticsearch、MinIO、Nacos。
3. 需要消息队列时，在开发终端运行：

```powershell
.\dev-environment\Start-Services.ps1 -Messaging
```

4. 双击 `检查开发环境.cmd` 查看工具版本和端口；进一步检查服务健康、认证及中文分词：

```powershell
.\dev-environment\Test-Services.ps1 -Messaging
```

5. 用完后双击 `停止基础服务.cmd`，停止并移除这套环境的容器，保留数据卷和凭据。后续再次启动即可使用。

VS Code 可以打开上一级目录的 `校园RAG开发环境.code-workspace`；该工作区已指定 Python 3.11 虚拟环境、Java 17、Maven 和专用开发终端。现有 Java、Python、Pylance、Vue 扩展均已检查存在。

## 开发工具

| 工具 | 本次验证版本 | 位置或说明 |
| --- | --- | --- |
| Java / javac | Temurin 17.0.20.1 | `D:\JDK`，使用现有安装 |
| Maven | 3.9.9 | 使用现有安装 |
| Python | 3.11.9 | `.local\Python311`，官方 Windows 安装包 |
| Python 虚拟环境 | Python 3.11 | `.venv` |
| pip / uv | 26.2.2 / 0.13.5 | 安装于 `.venv` |
| Node.js / npm | 24.22.0 / 11.19.1 | 使用现有安装；npm 官方源连通性通过 |
| Git | 2.55.0.windows.3 | 使用现有安装与已有姓名、邮箱 |
| GitHub Desktop | 3.6.7 | `D:\github\GitHubDesktop`；已登录 ZhiShan717 |
| GitHub CLI | 2.103.0 | `.local\GitHubCLI`；已授权团队私有仓库 |
| VS Code | 1.142.0 | 使用现有安装 |
| Docker Desktop | 4.96.2 | `.local\DockerDesktop`，当前用户安装，WSL2 后端 |
| Docker Engine / Compose | 29.9.2 / 5.6.1 | Linux 容器；使用 `docker compose` 命令 |
| Ollama | 0.40.8 | `.local\Ollama` |

开发终端仅在自身进程设置 PATH、JAVA_HOME、MAVEN_HOME、虚拟环境、模型路径和 Docker 客户端上下文；本机原有 Python 3.14 保留。Python AI 开发依赖已在 `.venv` 安装，版本见 `requirements-rag.lock.txt`；使用 `Install-PythonDependencies.ps1` 可复现安装，`Test-PythonDependencies.py` 验证实际 SDK 调用和依赖一致性。

手册所列 LangChain/LangGraph 版本为下限。新环境采用当前相容的 LangChain 1.4.7、LangGraph 1.2.16、MCP 2.3.0 和 FastAPI 0.159.1，并锁定全部解析后的依赖。当前没有旧业务源码需要迁移；业务代码建立后应使用该代码自己的锁文件。

## GitHub Desktop 登录与使用

GitHub Desktop 已独立登录 `ZhiShan717`，已验证普通入口重新打开后保留登录状态，并成功访问私有仓库。已将本机配置完成的原目录 `D:\campus_RAG_work` 加入应用；另行克隆的目录保留。

桌面、开始菜单和 `D:\github` 的 **GitHub Desktop** 快捷方式统一使用 `Open-GitHubDesktop.ps1`；也可双击上一级的 `启动GitHub.cmd`。该入口每次读取 Windows 当前启用的代理，只传给应用及其 Git 子进程，同时配置 Electron 的代理参数。它保留 HTTPS 证书验证，不修改全局 Git 或系统网络设置。

若 GitHub 官方网页已经显示 **OAuth application authorized**，但未返回应用：保持该授权完成页打开，双击上一级的 `完成GitHub登录.cmd`。辅助入口只将 Microsoft Edge 上 GitHub 官方完成页中的回调交给本机已注册的 D 盘应用，不保存或输出一次性授权参数，不代替账号登录或授权。

原快捷方式备份、登录与同步记录位于 `.setup\state` 和 `.setup\logs\github-desktop-login-check.log`。日常开发使用原项目目录，其中已有虚拟环境、模型和服务数据。

## 基础服务与连接信息

服务统一使用 Compose 项目名 `campus-rag-dev`，全部映射到 `127.0.0.1`，使用独立的持久化数据卷。

| 服务 | 本机地址 | 用户及说明 |
| --- | --- | --- |
| MySQL 8.0 | `127.0.0.1:13306` | 库 `campus_rag`；用户 `campus_dev`；密码见 `MYSQL_PASSWORD` |
| Redis 7.4.2 | `127.0.0.1:6379` | 密码见 `REDIS_PASSWORD` |
| Elasticsearch 8.11.4 + IK 8.11.4 | `http://127.0.0.1:9200` | 用户 `elastic`；密码见 `ELASTIC_PASSWORD` |
| MinIO 2024 | `http://127.0.0.1:9000` | 对象存储 API |
| MinIO 控制台 | `http://127.0.0.1:9001` | 账号、密码见 `MINIO_ROOT_USER`、`MINIO_ROOT_PASSWORD` |
| Nacos 2.3.2 | `http://127.0.0.1:8848/nacos` | 用户 `nacos`；密码见 `NACOS_ADMIN_PASSWORD`；另开放本机 9848/9849 |
| RocketMQ 5.3.1 NameServer | `127.0.0.1:9876` | 通过 `-Messaging` 启动 |
| RocketMQ Broker | `127.0.0.1:10911` | 同时映射本机 10909/10912；为 Windows 本机客户端配置 |
| Ollama | `http://127.0.0.1:11434` | 模型服务 API；本地模型见下文 |

凭据位于本目录的 `.env`，由初始化脚本随机生成，只允许当前用户、SYSTEM 和管理员访问。可以在本机编辑器中查看并填入后续项目；初始化脚本不会反复更换密码。应连同已有数据卷保管该文件，避免丢失后无法连接已初始化的数据库。

本目录 `.env.application` 另行汇总实际连接信息、模型路径，以及独立随机生成的 APP/JWT 密钥，同样限制文件权限且已排除 Git。由 `Initialize-ApplicationEnvironment.ps1` 生成，重复运行保留原值。接入业务代码时需将变量名对应到实际配置；尚未实现的 Java 网关/文档/检索服务地址，需要按真实代码填写。

本机已有 `MySQL80` 服务使用 3306，因此本次独立开发实例使用 13306。原有数据库服务未修改。后续项目在 Windows 上运行时应将这套开发数据库连接端口设为 13306；若业务服务运行在同一 Compose 网络内，则仍使用容器端口 3306。

本机 Navicat Premium Lite 17 已添加并验证连接 **校园RAG开发库**，使用 `127.0.0.1:13306`、`campus_dev` 账号，密码由 Navicat 自身保存。打开该连接下的 `campus_rag` 数据库即可使用；原有 `MySQL8.0` 连接保留。验收记录位于 `.setup\logs\navicat-connection-check.log`。

## Docker 与模型服务

本机加密的漫游用户目录无法完成 Docker 所需的原子文件重命名，已为 Docker 单独设置 D 盘配置目录。应使用 `Start-Services.ps1` 或以下脚本启动引擎：

```powershell
.\dev-environment\Start-ContainerEngine.ps1
```

引擎首次启动可能需要几十秒。基础服务启动脚本会自动等待就绪。

本次故障原因是安装设置中的 `wslDefaultDataRoot` 指向另一块空数据盘，导致原容器不可见。已固定为 `.local\docker-profile\Local\Docker\wsl`，并完成一次正常停止、重新启动和数据一致性验收。桌面与开始菜单入口统一通过本目录 `Open-DockerDesktop.ps1` 打开同一配置。

- Docker 独立配置：`.local\docker-profile\Roaming\Docker`
- Docker 镜像及卷磁盘实际位置：`.local\docker-profile\Local\Docker\wsl\disk\docker_data.vhdx`
- Docker 客户端配置：`.local\docker-cli`；开发终端固定本机 `desktop-linux` 上下文。
- Ollama 模型目录：`.local\ollama-models`，已设置当前用户的 `OLLAMA_MODELS`，并使用本机回环地址 `OLLAMA_HOST`。

Ollama 后台服务可按需启动、停止：

```powershell
.\dev-environment\Start-ModelService.ps1
.\dev-environment\Stop-ModelService.ps1
```

该电脑为约 16GB 内存、Intel 集成显卡，使用 CPU 模型推理。本地中文嵌入模型为 `BAAI/bge-large-zh-v1.5`，重排模型为 `BAAI/bge-reranker-base`，缓存位于 `.local\models`；下载脚本固定官方模型提交并核验权重 SHA256。Ollama 生成模型选择 `qwen3:1.7b`，模型存于 `.local\ollama-models`。实际下载、加载和生成是否通过，以 `Test-Models.ps1` 及 `.setup\logs` 中的现场验收结果为准。

2026-10-23 三类模型实际验收全部通过：嵌入输出 1024 维且已归一化，中文相关材料得分高于无关材料；重排结果符合相关性；Qwen 输出正确的中文测试答案及引用标记，生成后按 `keep_alive=0` 释放内存。该测试使用人工构造材料，业务平台的完整 RAG 与权限验收仍需真实应用代码。

CPU 模型依赖为 PyTorch 2.14.1+cpu、Sentence Transformers 6.2.0、Transformers 5.20.2；锁文件为 `requirements-models.lock.txt`，与 Python SDK 锁同时生效。安装全部模型工具、获取权重并验证使用 `Prepare-Models.ps1`；只重新验证已有模型使用 `Test-Models.ps1`。Qwen 的本次验收 digest 已固定，若官方同名标签改变会要求复核。

`model-env.example` 提供无密钥的模型参数；开发终端导出绝对路径。为控制内存，本机模型调用使用小批量、2048 上下文，生成请求显式设置 `keep_alive=0`，完成后卸载模型。该本地生成模型用于开发联调；团队模型选型可以在后续业务实现中调整。

## 手册中需在接入项目时确认的内容

- `bge-large-zh-v1.5` 的官方输出是 **1024 维**；手册所写的 768 维对应 `bge-base-zh-v1.5`。本机按手册指定的 large 模型配置 1024 维；后续 ES `dense_vector.dims` 应一致。当前没有建立业务索引。来源：[BAAI 官方模型卡](https://huggingface.co/BAAI/bge-large-zh-v1.5)。
- 手册写的 Spring Boot 3.2.x 与 Spring Cloud Alibaba 2022.x 不是官方匹配组合。官方说明中 Alibaba 2023.x 对应 Boot 3.2.x，2022.x 对应 Boot 3.0.x；后续按实际 POM 和锁定依赖确认。来源：[Spring Cloud Alibaba 官方仓库](https://github.com/alibaba/spring-cloud-alibaba)。
- MinIO 原 2024 镜像下载已被上游移除，使用 OpenEBS 重新发布的同版本镜像并固定摘要，详情见 `SOURCES.md`。
- Java 服务、Python RAG 应用、Vue 前端、JWT、业务表与索引、RAG 引用及权限验收需要真实源码；本次未生成这些业务内容。
- 手册列出的 Nginx、Kubernetes、Sentinel、Seata、SkyWalking 属于可选增强项，本次基础开发环境未启用。

## 检查记录与本地文件

- `.setup\logs\environment-check.log`：工具、Docker Engine、模型服务和本机端口检查记录。
- `.setup\logs\docker-recovery-check.log`：原数据恢复、七项服务认证、真实重启、容器/数据卷/凭据一致性验收。
- `.setup\logs\services-final-check.log`：本轮七项服务最终验收结果，文件内记录北京时间。
- `.setup\logs\python-dependencies-check.log`：开发工具、Python SDK 实际调用与依赖一致性验收。
- `.setup\logs\models-verification.json`：三模型实际推理结果、维度、相关性得分、版本及内存释放验收。
- `Test-Services.ps1`：实时验证容器健康、MinIO 认证、Nacos 随机密码、ES IK 中文分词；加 `-Messaging` 验证消息服务。
- RocketMQ 首次启动会运行一次数据卷目录权限初始化，随后以镜像原有的非 root 用户运行 NameServer 和 Broker。
- `.setup\logs\ollama-stdout.log`、`ollama-stderr.log`：由开发脚本管理的模型服务日志。
- 安装包、下载缓存与排障截图在 2026-10-23 整理时清理；保留已安装工具、模型、服务数据和关键检查记录。重新安装模型依赖时，脚本会重新下载并校验所需文件。
- 根目录及本目录的 `.gitignore` 已排除凭据、模型、虚拟环境、安装包和运行数据。

基础服务总内存上限约 3.5GiB；消息组件额外约 1.4GiB，上限不等于实际占用。无需常驻时使用停止入口释放资源；停止不会删除命名数据卷。
