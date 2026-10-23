# 运行时配置约定

当前仅搭建目录，尚未实现配置加载程序。以下文件是后续接入的配置来源；应用代码需明确读取方式、变量映射和缺失值校验，不能假定它们会被自动加载。

| 配置来源 | 用途 |
| --- | --- |
| `environment/.env.application`（本机文件，Git 已忽略） | 本机服务地址、连接凭据、模型路径和应用密钥；由现有初始化脚本生成 |
| [model-env.example](../../../environment/model-env.example) | 可共享的无密钥模型参数示例，包含模型路径、1024 维嵌入及 Ollama 调用参数 |
| [Enter-DevEnvironment.ps1](../../../environment/Enter-DevEnvironment.ps1) | 开发终端导出的 Python 环境、绝对模型路径和 Ollama 运行参数 |
| [本机开发环境说明](../../../environment/README.md) | 基础服务、本地模型、初始化和验证步骤 |

相对模型路径以仓库根目录为基准。负责人本机使用仓库根目录下 `.local/models` 和 `.local/ollama-models` 的既有模型，不在 `project/rag-runtime` 中复制权重。`project/` 不是环境脚本的运行根目录。

队员使用自己的本地服务和凭据，不复制负责人的 `.env.application`。后续确需新增可共享配置时，只提交无密钥模板，并将真实取值保存在 Git 忽略的本机文件或环境变量中。密码、访问令牌、JWT 密钥、原始用户材料和个人数据不得写入本目录的版本控制文件。
