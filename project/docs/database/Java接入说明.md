# 给沈明昊的数据库接入说明

本模块提供实体和 Mapper，不提供登录、JWT、REST Controller 或 Java→Python HTTP 调用。拷贝 `backend/database-support/src/main/java/cn/campus/rag/db/` 到统一 Java 工程的源码目录，沿用 `cn.campus.rag` 包名前缀。独立 POM `project/database-week1.pom.xml` 只用于本模块编译和 MySQL 集成验证，不替换原有聚合 POM。

1. 在统一 Spring Boot 工程引入与版本匹配的 MyBatis-Plus starter。本模块测试使用 MyBatis-Plus 3.5.7；Spring Boot 3 工程应选 `mybatis-plus-spring-boot3-starter`，避免同时重复引入其他 MyBatis starter。MySQL JDBC 驱动由主工程管理。
2. 配置数据源为自己的开发库；凭据走环境变量，不提交真实密码。配置 `mybatis-plus.configuration.map-underscore-to-camel-case: true`。在启动类加入 `@MapperScan("cn.campus.rag.db.mapper")`。
3. 实体字段采用可直接访问的 public 属性，避免额外 Lombok 依赖；它们是持久化对象。接口应使用独立 DTO，尤其禁止序列化 `User.passwordHash`，注册 DTO 不接收 role。
4. 普通新增编辑使用 BaseMapper 的 insert / updateById / selectById。MyBatis-Plus 默认跳过 null 字段；清空失效日期等可空列时，需显式 UpdateWrapper.set("effective_to", null)。用户输入只能传参数值，不能拼接成 SQL/列名。
5. `selectEffectiveCandidates(asOf)` 使用 Java 端明确计算的日期，例如 `LocalDate.now(ZoneId.of("Asia/Shanghai"))`。固定验收使用 2026-10-30，不依赖服务器当前日期。
6. 将结果转换为统一候选 DTO 后发给 Python。ID 若统一接口使用字符串，应在 DTO 边界统一转字符串；数据库内仍为 BIGINT，不能用前端数组序号代替。

候选映射返回字段示例：

```json
{
  "chunkId": 1022,
  "documentId": 102,
  "documentTitle": "【虚构演示】本科生奖学金办法",
  "version": "2026",
  "chunkNo": 2,
  "sectionPath": "第2条",
  "content": "【虚构演示】奖学金申请需平均成绩不低于85分，仅适用于2026版。",
  "sourceType": "SYNTHETIC",
  "sourceNote": "虚构演示数据；不得作为真实申报依据。"
}
```

`question`、`candidateChunks`、`topK` 的外层结构由团队 HTTP 契约确认。Java 应保留本次候选 ID 集合，校验 Python 返回的所有 chunkId 属于该集合，再使用数据库候选中的原文构建引用。不要信任 Python 或浏览器自行给出的标题与原文。

## 修订事务约定

Service 的 `@Transactional` 方法调用 `lockVersionFamily(documentKey)`，检查锁定版本、日期区间和后继关系；新增后继及其条款；将前驱 effective_to 设为新版本 effective_from、replaced_by 设为新 ID；确认更新行数后提交。任何校验失败或 SQL 失败必须回滚。不要在事务外先查一次再无条件更新。

此规则保证将来发布的新版不会提前替代现行版。不能在“登记未来新版”时把前驱改成 REPEALED。已存在后继时，第一周模块建议拒绝继续挂接并交由专门版本调整业务处理，避免覆盖版本链。

数据库能拦住外键和必填错误，但不能代表管理员权限已经实现；created_by 指向普通用户在外键上合法，是否允许此操作必须由后端认证授权层判断。密码 CHECK 只检查 BCrypt 字符串形式，不代替安全哈希函数。

历史问答及引用内容快照属于第二周；第一周的 `snapshots/week1-demo.sql` 是数据库备份，两者概念不同。后续历史引用应复制当时的标题、版本、sectionPath、content 和来源，不能只存 chunkId 后每次回查可修改的原文。
