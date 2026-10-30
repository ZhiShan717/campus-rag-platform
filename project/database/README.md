# 数据库与检索索引

集中维护全队共享的结构变更与开发样例。各成员开发时使用自己的本地实例，联调环境另行约定。

| 目录 | 用途 |
| --- | --- |
| `mysql/migrations/` | MySQL 版本化建表及表结构变更脚本 |
| `mysql/seeds/` | 面向空开发库的一次性演示初始化数据 |
| `mysql/queries/` | 有效候选、CRUD、版本事务和完整性检查示例 |
| `mysql/snapshots/` | 已验证可恢复的虚构演示数据库快照 |
| `elasticsearch/index-templates/` | Elasticsearch mapping、索引模板与分析器配置 |

第一周数据库模块已提供 `users / documents / chunks` 三表迁移、约束、索引、演示数据、Mapper 和恢复脚本。使用说明及验证入口见仓库根目录 [README.database-week1.md](../../README.database-week1.md)，字段与规则见 [字段字典](../docs/database/字段字典.md)。数据均为虚构演示，不可作为真实校规依据；新增 SQL 文件不会自动运行。业务服务和团队接口仍需接入验证。

在仓库根目录运行 `scripts/Test-Week1.ps1`，通过独立临时 MySQL 实例验证建表、CRUD、版本过滤和恢复；日常初始化与恢复使用 `scripts/Manage-Week1Database.ps1`。脚本拒绝复用已有数据库，避免覆盖数据。开发凭据由各成员本机管理，不能写入迁移脚本。原有环境初始化入口为 [环境初始化脚本](../../environment/Initialize-Environment.ps1)。
