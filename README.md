# 校园 RAG 知识库平台

公开仓库：[ZhiShan717/campus-rag-platform](https://github.com/ZhiShan717/campus-rag-platform)，默认分支 `main`。读取和克隆无需邀请，向原仓库推送需要写入权限。

本仓库分为两个区域：**[project/](project/README.md) 保存业务项目，[environment/](environment/README.md) 保存开发环境配置与安装资料**。当前仍为工程骨架：六个 Java 模块已有聚合 POM，Python 与前端已有目录规划，业务网站、API 和完整问答链路尚未实现。

## 阅读入口

| 要做的事 | 入口 |
| --- | --- |
| 新队员了解仓库、权限与加入步骤 | [队员信息速查](project/docs/team/队员信息速查.md)、[团队协作与接入](project/docs/team/团队协作与接入.md) |
| 安装软件、配置服务和模型 | [环境操作说明](environment/README.md)、[详细安装指南正文](environment/docs/详细安装与配置指南.md) |
| 下载或离线阅读手册 | [详细安装与配置指南 PDF](environment/output/pdf/校园RAG平台_详细安装与配置指南.pdf) |
| 验证本人配置是否完成 | [指南第 27-31 节](environment/docs/详细安装与配置指南.md#27-队员自检准备与完成判定)：命令、通过标准、模型报告时间和验收记录 |
| 查官网、阿里云镜像及依赖源 | 指南第 24-26 节，保留版本、架构和校验要求 |
| 开始业务开发与查文件归属 | [项目入口](project/README.md)、[业务文档导航](project/docs/README.md)、[目录与开发约定](project/docs/development/项目目录与开发约定.md) |

## 目录结构

```text
campus-rag-platform/                Git 仓库根
├── project/                       业务项目区
│   ├── README.md                  业务入口与结构检查
│   ├── pom.xml                    Java 17 聚合 POM
│   ├── backend/                   gateway/auth/doc/search/admin/eval 六个服务
│   ├── frontend/                  Vue 页面、组件、API 与模块测试
│   ├── rag-runtime/               Python RAG、编排、MCP、护栏与评测
│   ├── database/                  迁移、人工样例与 ES 索引定义
│   ├── deploy/                    业务镜像、Nginx 与 Kubernetes 部署
│   ├── tests/                     跨模块集成、端到端验证与构造材料
│   └── docs/                      团队、开发、接口与架构文档
├── environment/                   环境配置区
│   ├── README.md                  安装、启动、验证与脚本索引
│   ├── *.ps1、*.py、*.cmd         环境和模型管理入口
│   ├── docker-compose.yml         开发中间件配置
│   ├── elasticsearch/、rocketmq/  中间件附属配置
│   ├── requirements-*             SDK 与模型依赖声明/锁
│   ├── model-env.example          无密钥模型参数
│   ├── docs/                      原始手册、指南正文与资料索引
│   └── output/pdf/                可分发的安装指南 PDF
├── README.md                      本导航
├── .editorconfig、.gitattributes   编码、缩进和换行约定
├── .gitignore                     本机文件排除规则
├── .local/                        本机工具、模型、Docker 配置与数据
├── .venv/                         本机 Python 虚拟环境
└── .setup/                        本机日志、进程记录与检查工具
```

`project/deploy/` 管业务部署，`environment/docker-compose.yml` 管开发中间件。`.gitkeep` 用于保留尚无实现的业务目录，加入真实文件后可移除对应占位。

根 `.local/`、`.venv/`、`.setup/` 属于被 Git 忽略的本机环境运行区，保持既有绝对路径。工具、模型、凭据和 Docker 数据继续使用原位置；个人登录辅助、负责人启动包装和编辑器配置仅留本机。

## 获取仓库与命令位置

```powershell
git clone https://github.com/ZhiShan717/campus-rag-platform.git
cd campus-rag-platform
```

克隆获得业务骨架、共用环境配置与资料；每位队员按手册准备自己的工具和依赖。负责人仓库根为 `D:\campus_RAG_work`，业务根为 `D:\campus_RAG_work\project`；队员可使用 `D:\Projects\campus-rag-platform`。

**环境命令从仓库根执行。** 先按手册第 07、09-11 节适配本人工具路径、Docker context 和数据目录，再启动或验证服务。

```powershell
. .\environment\Enter-DevEnvironment.ps1
.\environment\Check-Environment.ps1
```

工具表、端口、服务认证和模型推理是不同检查层次，按指南逐项判断。已有环境无需重复安装或重建数据卷。

**业务 Maven 从仓库根指定项目 POM：**

```powershell
mvn.cmd -f .\project\pom.xml -o -B validate
mvn.cmd -f .\project\pom.xml -o -B -pl backend/doc-service -am validate
```

也可进入 `project/` 后执行 `mvn.cmd -o -B validate`。`-pl backend/doc-service` 相对于 `project/pom.xml`，不用再加 `project/`。当前仅校验根项目与六个模块共七项结构，不证明业务服务已可启动。

Python 使用仓库根 `.venv/`；[业务依赖入口](project/rag-runtime/requirements.txt)引用 [SDK 锁](environment/requirements-rag.lock.txt)，不复制版本清单。前端尚无 `package.json`，须先完成工程初始化再按实际脚本安装和启动。

## 分享边界与协作

通过 Git 分享 `project/` 业务源码、部署、测试与文档，以及 `environment/` 的共用脚本、Compose、依赖锁和安装资料。`environment/.env`、`.env.application`、根 `.local/`、`.venv/`、`.setup/`、个人授权、模型、数据盘与日志不提交。

当前没有团队共享服务器，`127.0.0.1` 指各自电脑。共享数据库迁移和可公开样例，不共用负责人的数据盘或管理员账号。

Git 操作仍在仓库根执行。有写入权限时使用任务分支，无写入权限时通过个人 Fork 提交 Pull Request，步骤见[代码协作](project/docs/team/团队协作与接入.md#代码协作)。目录、接口、依赖或配置变化时同步说明，检查通过后提交并正常推送，不强制覆盖其他成员的提交。
