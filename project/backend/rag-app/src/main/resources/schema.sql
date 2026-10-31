-- ============================================================
-- 校园 RAG 知识库平台 · 建表脚本（第一周）
-- 顺序有讲究：先建被引用的表，再建引用别人的表
-- ============================================================

-- 用户表。user 是 SQL 保留字，所以表名叫 app_user
CREATE TABLE IF NOT EXISTS app_user (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE COMMENT '登录名',
    password_hash VARCHAR(100) NOT NULL COMMENT '密码哈希，绝不存明文',
    role          VARCHAR(20)  NOT NULL DEFAULT 'USER' COMMENT 'USER 普通用户 / ADMIN 管理员',
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 制度表。一份制度可能有多个版本，靠 status 区分哪个是当前有效版
CREATE TABLE IF NOT EXISTS document (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    doc_no         VARCHAR(50)  NULL COMMENT '制度文号，如 NZ-2024',
    title          VARCHAR(200) NOT NULL COMMENT '制度名称',
    version        VARCHAR(50)  NOT NULL COMMENT '版本号，如 2024-A',
    status         INT          NOT NULL DEFAULT 1 COMMENT '1=有效 0=废止',
    effective_date DATE         NULL COMMENT '生效日',
    expire_date    DATE         NULL COMMENT '失效日，null 表示长期有效',
    replaced_by    BIGINT       NULL COMMENT '被哪条新制度替代（指向 document.id）',
    created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 条款表。一条制度拆成很多条，每条是 RAG 检索的最小单位
CREATE TABLE IF NOT EXISTS clause (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    document_id BIGINT        NOT NULL COMMENT '属于哪份制度',
    clause_no   VARCHAR(30)   NOT NULL COMMENT '条款号，如 3.1',
    content     VARCHAR(2000) NOT NULL COMMENT '条款正文',
    -- 这里允许 NULL，是个刻意的让步：
    -- chunk_id 要用数据库自增的 id 拼出来（doc1-c1001），
    -- 可插入之前 id 还不存在。所以先插入拿到 id，同一个事务里立刻回填。
    chunk_id    VARCHAR(80)   NULL COMMENT '给 Python 检索用的唯一标识，插入后回填',
    created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 显式插入 id 之后，把自增起点往后挪，避免后面新增时主键撞车
ALTER TABLE document ALTER COLUMN id RESTART WITH 100;
ALTER TABLE clause   ALTER COLUMN id RESTART WITH 1000;
