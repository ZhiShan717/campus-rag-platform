-- Bind an explicit date in Java; CURRENT_DATE depends on the server timezone.
SET @as_of = '2026-10-30';
SELECT c.id AS chunkId, c.document_id AS documentId, d.title AS documentTitle,
       d.version, c.chunk_no AS chunkNo, c.section_path AS sectionPath, c.content,
       d.source_type AS sourceType, d.source_note AS sourceNote
FROM documents d JOIN chunks c ON c.document_id = d.id
WHERE d.status = 'ACTIVE'
  AND d.effective_from <= @as_of
  AND (d.effective_to IS NULL OR @as_of < d.effective_to)
ORDER BY d.id, c.chunk_no, c.id;
-- Do NOT add replaced_by IS NULL: a successor can be scheduled for the future.
