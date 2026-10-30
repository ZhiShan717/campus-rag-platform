# 第一周数据库交付

根据《校园级 RAG 知识库平台 Demo 前两周学习开发计划（七人课程对位版）》中 2026/10/24—10/30 的数据库任务完成。范围为数据库、SQL、Mapper 和恢复验证。适合交给沈明昊接入统一 Java 工程。独立验收入口为 `project/database-week1.pom.xml`，保留原有 `project/pom.xml` 六模块聚合构建。

## 交付入口

| 内容 | 文件 |
| --- | --- |
| 建表、约束、索引 | [V001__initial.sql](project/database/mysql/migrations/V001__initial.sql) |
| 2 个账号、8 份制度版本、40 条条款 | [V001__demo.sql](project/database/mysql/seeds/V001__demo.sql) |
| 候选联查、CRUD、修订事务、完整性检查 | [queries](project/database/mysql/queries/) |
| 字段字典、版本边界与样例预期 | [字段字典](project/docs/database/字段字典.md) |
| Entity / BaseMapper / 有效版本 Mapper | [Java 源码](project/backend/database-support/src/main/java/cn/campus/rag/db/) |
| 与沈明昊的集成约定 | [Java 接入说明](project/docs/database/Java接入说明.md) |
| 按天对照和需要本人掌握的内容 | [每日任务与学习笔记](project/docs/database/每日任务与学习笔记.md) |
| 验证结果和交付限制 | [第一周验收报告](project/docs/database/第一周验收报告.md) |
| 真实 mysqldump 快照 | [week1-demo.sql](project/database/mysql/snapshots/week1-demo.sql) |

演示制度全部为本次构造的**虚构演示数据**，不能作为真实奖助学金申请依据。未接收到戴月整理的原始样例，也未取得统一团队工程中的接口实现。

## 本机已检查的环境

Windows 上存在 MySQL Server **8.0.46**，`MySQL80` 服务运行中，Workbench 已安装；Java **17.0.20.1**、Maven **3.9.9** 可用。无需重复安装。MySQL 命令行工具默认位置：`C:\Program Files\MySQL\MySQL Server 8.0\bin`。

脚本使用 PowerShell 7；在项目根目录执行。MySQL 服务账号密码由本人输入，不写入源码。本次自动验证使用独立临时实例和随机端口，未取得或修改现有 MySQL80 的凭据、业务库。

## 在自己的 MySQL80 中建立开发库

```powershell
.\scripts\Manage-Week1Database.ps1 -Action Initialize
```

输入本机 MySQL root 密码，创建 `campus_rag_week1` 并导入建表和种子脚本。如果该数据库已经存在，命令会停止，避免覆盖；需要另一个空库时指定 `-Database campus_rag_week1_v2`。

Workbench 新建连接：主机 `127.0.0.1`，端口 `3306`，账号使用自己的 MySQL 账号。打开 `campus_rag_week1`，运行 `project/database/mysql/queries/01__effective_candidates.sql`，固定 2026-10-30 应返回 **15 条**候选。

演示应用账号：`demo_admin` / `demo_student`，两者密码均为 `DemoOnly-2026!`。这两个是 users 表中的**应用账号**，不是 MySQL 连接账号。数据库仅保存 BCrypt 哈希；固定演示口令只用于本地虚构数据。

## 备份与恢复

```powershell
.\scripts\Manage-Week1Database.ps1 -Action Backup -File .\my-week1-backup.sql
.\scripts\Manage-Week1Database.ps1 -Action Restore -Database campus_rag_week1_restored -File .\my-week1-backup.sql
```

恢复到新库，不覆盖旧库。也可以将 `-File` 指向交付中的 `project/database/mysql/snapshots/week1-demo.sql`。备份命令不覆盖已存在的目标文件。

快照由实际 mysqldump 生成，包含三张表的结构、索引和数据；恢复命令使用 MySQL 客户端执行。建表是一次性迁移：MySQL DDL 有隐式提交，导入出错可能留下部分结构，不能假定整个迁移会自动回滚。先检查错误，再选择新空库重试；本交付不自动删库。

## 复现自动验收

```powershell
.\scripts\Test-Week1.ps1
```

此命令初始化独立 MySQL 8 实例，以随机凭据在回环地址监听，运行真实的初始化、备份、恢复脚本和 Java/Mapper 集成测试。需约数十秒；首次 Maven 下载依赖需要网络且可能更久。测试完成或失败后都会停止临时实例，并删除临时凭据文件；数据和日志位于 `%TEMP%\campus-rag-week1-*`，便于查错。

测试数据目录采用英文临时路径，避免本机 mysqld 在中文目录下启动失败；项目源码和交付文件仍在当前目录。自动测试不连接现有 MySQL80 服务。`mvn -f project/database-week1.pom.xml test` 单独运行会提示缺少测试环境变量，应使用上面的脚本。

通过后快照更新到 `project/database/mysql/snapshots/week1-demo.sql`；测试报告位于 `project/target/surefire-reports/`。源码模块不是完整 Spring Boot 应用，没有浏览器入口。登录鉴权、团队 HTTP 联调、真实 RAG 问答与第二周历史引用快照应由对应负责人继续集成，不能从数据库测试通过推定已完成。
