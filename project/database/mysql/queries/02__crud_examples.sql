-- Practice only: all writes are rolled back. Use bound parameters in application code.
SET NAMES utf8mb4;
START TRANSACTION;
INSERT INTO documents (document_key, title, version, status, effective_from, source_type, source_note, created_by)
VALUES ('practice', '【虚构演示】SQL练习制度', '1', 'DRAFT', '2026-10-30', 'SYNTHETIC', '仅用于回滚练习。', 1);
SET @document_id = LAST_INSERT_ID();
INSERT INTO chunks (document_id, chunk_no, section_path, content)
VALUES (@document_id, 1, '第一章/第一条', '【虚构演示】新增条款原文。');
SELECT d.id, d.title, c.id AS chunk_id, c.section_path, c.content
FROM documents d JOIN chunks c ON c.document_id = d.id WHERE d.id = @document_id;
UPDATE chunks SET content = '【虚构演示】编辑后的原文。' WHERE document_id = @document_id AND chunk_no = 1;
UPDATE documents SET title = '【虚构演示】编辑后的制度' WHERE id = @document_id;
DELETE FROM chunks WHERE document_id = @document_id;
DELETE FROM documents WHERE id = @document_id;
ROLLBACK;
