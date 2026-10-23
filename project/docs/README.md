# 项目文档导航

本目录保存业务开发与团队协作资料。安装步骤、依赖源、环境结构与自检说明集中在仓库根目录的 `environment/`，避免重复维护。

## 阅读顺序

新队员从[队员信息速查](team/队员信息速查.md)了解仓库与现状，再按[团队协作与接入](team/团队协作与接入.md)准备本机环境。开始业务开发前，阅读[目录与开发约定](development/项目目录与开发约定.md)，再与相关成员对齐接口和架构。

需要逐步的软件安装、仓库克隆、路径适配、服务和模型检查说明时，使用[详细安装与配置指南 PDF](../../environment/output/pdf/校园RAG平台_详细安装与配置指南.pdf)，对应的[可编辑正文](../../environment/docs/详细安装与配置指南.md)在环境区维护。指南第 27–31 节提供队员配置验收方法、通过标准和记录表。

## 文件分类

```text
project/docs/
├── README.md                    本文：阅读顺序与资料索引
├── team/
│   ├── 队员信息速查.md           首次发给队员的摘要
│   └── 团队协作与接入.md         完整准备与 Git 协作步骤
├── development/
│   └── 项目目录与开发约定.md     文件归属、私有区与开发规则
├── api/README.md                 接口契约的维护入口
└── architecture/README.md        跨模块设计决策的维护入口
```

## 按任务查找

| 要做的事 | 资料 |
| --- | --- |
| 首次给队员发项目信息 | [team/队员信息速查](team/队员信息速查.md)：仓库、加入事项、服务连接与协作摘要 |
| 按步骤安装配置、检查是否完成，或下载离线指南 | [环境区详细指南 PDF](../../environment/output/pdf/校园RAG平台_详细安装与配置指南.pdf) / [可编辑正文](../../environment/docs/详细安装与配置指南.md) |
| 准备队员电脑、克隆和提交代码 | [team/团队协作与接入](team/团队协作与接入.md)：完整准备流程、权限与 Fork/PR 操作 |
| 查目录位置、文件归属和开发规范 | [development/项目目录与开发约定](development/项目目录与开发约定.md)：统一目录说明与维护规则 |
| 编写或对齐跨模块接口 | [api/](api/README.md) |
| 记录跨模块设计决定 | [architecture/](architecture/README.md) |
| 启动、停止、检查或维护开发环境 | [environment/README.md](../../environment/README.md) |
| 查看原始安装参考 | [原始手册 PDF](../../environment/docs/校园级RAG知识库平台环境安装与首次运行手册.pdf)；操作和版本差异以仓库现行文档为准 |

项目开发入口为 [project/README.md](../README.md)，仓库总入口为[根 README.md](../../README.md)。源码职责以各模块 README 为准；密码、模型、个人授权和本机检查日志不放入本目录。

新增文档后在此补充导航；新建或移动源码目录时同步根 README 和对应模块 README。接口与架构目录目前仅有说明，业务契约和设计仍需团队落实。

2026-10-23 目录整理：业务资料位于 `project/docs/`，安装与自检指南正文及 PDF 分别位于 `environment/docs/`、`environment/output/pdf/`。旧目录下不再保留重复指南。
