-- MySQL >= 8.0.16. Execute once in an EMPTY database selected by the caller.
-- MySQL DDL implicitly commits; this migration is not a rollbackable transaction.
SET NAMES utf8mb4;
CREATE TABLE users (
    id BIGINT NOT NULL AUTO_INCREMENT,
    username VARCHAR(64) NOT NULL,
    password_hash VARCHAR(100) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    display_name VARCHAR(64) NOT NULL,
    role VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'USER',
    enabled TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT ck_users_username CHECK (CHAR_LENGTH(TRIM(username)) > 0 AND username = TRIM(username)),
    CONSTRAINT ck_users_hash CHECK (password_hash REGEXP '^[$]2[aby][$][0-9]{2}[$][./A-Za-z0-9]{53}$'),
    CONSTRAINT ck_users_display CHECK (CHAR_LENGTH(TRIM(display_name)) > 0),
    CONSTRAINT ck_users_role CHECK (role IN ('USER', 'ADMIN')),
    CONSTRAINT ck_users_enabled CHECK (enabled IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE documents (
    id BIGINT NOT NULL AUTO_INCREMENT,
    document_key VARCHAR(80) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    title VARCHAR(200) NOT NULL,
    version VARCHAR(32) NOT NULL,
    status VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'DRAFT',
    effective_from DATE NOT NULL,
    effective_to DATE NULL,
    replaced_by BIGINT NULL,
    source_type VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    source_url VARCHAR(1024) NULL,
    source_note VARCHAR(500) NOT NULL,
    created_by BIGINT NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_documents_version UNIQUE (document_key, version),
    CONSTRAINT uq_documents_id_key UNIQUE (id, document_key),
    CONSTRAINT uq_documents_predecessor UNIQUE (replaced_by),
    KEY idx_documents_effective (status, effective_from, effective_to),
    CONSTRAINT fk_documents_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_documents_successor FOREIGN KEY (replaced_by, document_key)
        REFERENCES documents(id, document_key) ON DELETE RESTRICT,
    CONSTRAINT ck_documents_key CHECK (document_key REGEXP '^[A-Za-z0-9_-]+$'),
    CONSTRAINT ck_documents_title CHECK (CHAR_LENGTH(TRIM(title)) > 0),
    CONSTRAINT ck_documents_version CHECK (CHAR_LENGTH(TRIM(version)) > 0),
    CONSTRAINT ck_documents_status CHECK (status IN ('DRAFT', 'ACTIVE', 'REPEALED')),
    CONSTRAINT ck_documents_dates CHECK (effective_to IS NULL OR effective_to > effective_from),
    CONSTRAINT ck_documents_successor CHECK (replaced_by IS NULL OR effective_to IS NOT NULL),
    CONSTRAINT ck_documents_source CHECK (source_type IN ('SYNTHETIC', 'PUBLIC')),
    CONSTRAINT ck_documents_provenance CHECK (CHAR_LENGTH(TRIM(source_note)) > 0 AND
        (source_type <> 'PUBLIC' OR (source_url IS NOT NULL AND CHAR_LENGTH(TRIM(source_url)) > 0)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;

CREATE TABLE chunks (
    id BIGINT NOT NULL AUTO_INCREMENT,
    document_id BIGINT NOT NULL,
    chunk_no INT NOT NULL,
    section_path VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    PRIMARY KEY (id),
    CONSTRAINT uq_chunks_document_no UNIQUE (document_id, chunk_no),
    CONSTRAINT fk_chunks_document FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE RESTRICT,
    CONSTRAINT ck_chunks_no CHECK (chunk_no > 0),
    CONSTRAINT ck_chunks_section CHECK (CHAR_LENGTH(TRIM(section_path)) > 0),
    CONSTRAINT ck_chunks_content CHECK (CHAR_LENGTH(TRIM(content)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;
