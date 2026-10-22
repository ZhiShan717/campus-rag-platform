# 校园 RAG 平台负责人开发环境

本目录用于准备项目负责人的 Windows 开发环境及团队仓库。基础设施配置、模型准备脚本、依赖清单和开发终端可以复用；当前尚无 Java 微服务、Python RAG 业务程序和 Vue 页面。

团队私有仓库：[ZhiShan717/campus-rag-platform](https://github.com/ZhiShan717/campus-rag-platform)。本目录已初始化为 `main` 分支，GitHub 凭据通过官方 GitHub CLI 管理。

## 本机使用

- 双击 `启动Docker.cmd`，或桌面的 **Docker Desktop**，打开使用正确 D 盘配置的 Docker 界面。
- 负责人日常可双击 `启动负责人环境.cmd`，一次启动七项基础服务与 Ollama API。
- 双击 `启动基础服务.cmd` 启动五项基础服务；完整消息环境在开发终端运行 `./dev-environment/Start-Services.ps1 -Messaging`。
- 双击 `启动开发终端.cmd`，使用本项目的 Java 17、Python 3.11 虚拟环境、Maven、Node.js 和模型配置。
- 双击 `检查开发环境.cmd` 检查工具。服务的实际认证和健康检查使用 `./dev-environment/Test-Services.ps1 -Messaging`。
- 用 VS Code 打开 `校园RAG开发环境.code-workspace`。

详细端口、数据位置和日常操作见 [环境说明](dev-environment/README.md)。MySQL 开发实例使用 **13306**，保留本机已有的 3306 实例。

## 负责人配置

基础服务凭据位于 `dev-environment/.env`。运行 `./dev-environment/Initialize-ApplicationEnvironment.ps1`，可生成仅本机用户可访问的 `dev-environment/.env.application`，包含实际连接参数和独立随机 APP/JWT 密钥。再次执行会保留原值。

变量名应在接入真实代码时对应到项目实际配置；尚未编写的网关、检索和文档服务没有可验证的业务地址。团队成员应在各自机器生成开发凭据。

## 模型与依赖

- 手册指定的 `BAAI/bge-large-zh-v1.5` 实际为 **1024 维**，后续 Elasticsearch `dense_vector.dims` 应保持一致。[官方模型卡](https://huggingface.co/BAAI/bge-large-zh-v1.5)
- 中文重排模型使用 `BAAI/bge-reranker-base`，本地生成模型使用 Ollama `qwen3:1.7b`；模型验证入口为 `dev-environment/Test-Models.ps1`。
- Python 开发依赖与安装入口位于 `dev-environment/requirements-rag.in`、`Install-PythonDependencies.ps1`，以实际安装生成的锁文件复现版本。
- 模型、缓存和虚拟环境均存储在本机 D 盘。2026-10-23 已完成嵌入、重排、中文生成的实际推理验证；生成后模型会释放内存。

## 仓库内容

可提交开发脚本、Compose、依赖清单、说明和原始手册。`.env`、`.env.application`、模型权重、Docker 数据、安装包、日志、`node_modules` 和虚拟环境已排除。

手册中的源码仓库地址是占位符。建立 GitHub 仓库后，仍需要真实业务实现才能执行手册中的构建、问答、引用、权限和评测验收。
