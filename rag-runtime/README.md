# Python RAG 运行时

本目录用于后续实现 Python 侧的检索增强生成、流程编排和 MCP 工具。当前已建立目录骨架，尚无业务代码、API 入口或可运行服务；暂不能使用 `uvicorn` 启动。

## 目录职责

```text
rag-runtime/
├── src/                 # 未来的 API 入口、请求与响应定义、应用组装
├── graph/               # LangGraph 状态、节点、流程与路由
├── mcp_server/          # MCP 工具服务与工具注册
├── rag/
│   ├── indexer/         # 文档解析、切分、嵌入与索引写入
│   ├── retriever/       # 召回策略、过滤条件与检索结果合并
│   ├── reranker/        # 候选内容重排
│   └── generator/       # 提示词、模型调用、答案与引用生成
├── guardrails/          # 输入输出检查与运行时约束
├── eval/                # 评测流程、指标与脱敏评测材料
├── tests/               # 本模块的单元测试与集成测试
├── config/              # 配置约定与无密钥模板说明
└── requirements.txt     # 引用项目统一的 Python SDK 依赖锁
```

目录中的 `.gitkeep` 仅用于在 Git 中保留空目录。未来新增实际文件后可删除相应占位文件；`api.py` 等入口文件在实现对应功能时再创建。

## 使用现有开发环境

使用 **Python 3.11**。负责人本机已有仓库根目录的 `.venv`，无需再在本目录创建虚拟环境。双击根目录的 `启动开发终端.cmd`，或在仓库根目录的 PowerShell 中运行：

```powershell
. .\dev-environment\Enter-DevEnvironment.ps1
python --version
```

本机的 Python SDK 依赖已安装。需要按统一锁文件重新安装时，在仓库根目录运行：

```powershell
python -m pip install -r .\rag-runtime\requirements.txt
```

`requirements.txt` 直接引用 [SDK 依赖锁](../dev-environment/requirements-rag.lock.txt)，不另维护一份版本清单。新队员先按[团队协作与接入说明](../docs/团队协作与接入.md)完成基础环境准备，再使用上述入口。

## 模型与配置

模型推理依赖、模型下载和验收继续使用现有环境脚本。在仓库根目录运行：

```powershell
.\dev-environment\Prepare-Models.ps1
```

已经准备好模型、只需验证时，使用 `dev-environment\Test-Models.ps1`。本机使用 `BAAI/bge-large-zh-v1.5` 嵌入模型，向量维度为 **1024**；后续 Elasticsearch 向量索引必须与此维度一致。重排模型为 `BAAI/bge-reranker-base`，本地生成模型为 Ollama 的 `qwen3:1.7b`。

配置来源和保密要求见 [config/README.md](config/README.md)。模型权重、虚拟环境、实际凭据和运行数据均保存在已有本机目录中，不纳入本模块源码。

业务实现前需明确 API 契约、索引结构、权限传递及引用格式。当前未声明服务端口，未生成接口或数据库连接程序；未来启动方式以实际入口实现为准。
