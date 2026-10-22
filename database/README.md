# 数据库与检索索引

集中维护全队共享的结构变更与开发样例。各成员开发时使用自己的本地实例，联调环境另行约定。

| 目录 | 用途 |
| --- | --- |
| `mysql/migrations/` | MySQL 版本化建表及表结构变更脚本 |
| `mysql/seeds/` | 可重复导入的开发样例数据 |
| `elasticsearch/index-templates/` | Elasticsearch mapping、索引模板与分析器配置 |

当前只建立目录，尚无业务表或索引定义；没有执行数据库导入或变更。模型使用 `BAAI/bge-large-zh-v1.5`，后续向量字段维度统一为 **1024**。

MySQL 业务结构与 Java 实体、Python 检索字段确定后，再提交首份迁移。迁移工具和执行方式待团队统一；新增 SQL 文件不会自动运行。开发凭据由 [环境初始化脚本](../environment/Initialize-Environment.ps1)在各成员本机生成，不能写入迁移脚本。
