-- Illustrates the service transaction contract, NOT a generic production procedure.
-- Entire transaction must use one connection. The service validates dates/statuses,
-- locks ALL existing rows of this document_key, and checks affected row counts.
-- New families require a separate serialized creation path (unique key + retry).
SET NAMES utf8mb4;
START TRANSACTION;
SELECT id, effective_from, effective_to, status, replaced_by FROM documents
WHERE document_key = 'appeal' ORDER BY id FOR UPDATE;
INSERT INTO documents (document_key, title, version, status, effective_from, source_type, source_note, created_by)
VALUES ('appeal', '【虚构演示】奖助学金申诉办法', '2027', 'ACTIVE', '2027-01-01', 'SYNTHETIC', '未来修订练习。', 1);
SET @new_id = LAST_INSERT_ID();
INSERT INTO chunks (document_id, chunk_no, section_path, content)
VALUES (@new_id, 1, '第一条', '【虚构演示】2027版申诉条款。');
UPDATE documents SET effective_to = '2027-01-01', replaced_by = @new_id
WHERE id = 107 AND status = 'ACTIVE' AND replaced_by IS NULL AND effective_from < '2027-01-01';
-- In the real service, require exactly one updated row, then COMMIT; otherwise ROLLBACK.
ROLLBACK;
