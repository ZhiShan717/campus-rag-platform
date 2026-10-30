-- Expected: zero rows for each integrity query after importing the seed.
SELECT c.id FROM chunks c LEFT JOIN documents d ON c.document_id = d.id WHERE d.id IS NULL;
SELECT a.id AS predecessor, b.id AS successor FROM documents a JOIN documents b ON a.replaced_by = b.id
WHERE a.document_key <> b.document_key OR a.effective_to <> b.effective_from OR a.effective_from >= b.effective_from;
SELECT a.id, b.id FROM documents a JOIN documents b ON a.document_key = b.document_key AND a.id < b.id
WHERE a.status = 'ACTIVE' AND b.status = 'ACTIVE'
  AND a.effective_from < COALESCE(b.effective_to, '9999-12-31')
  AND b.effective_from < COALESCE(a.effective_to, '9999-12-31');
EXPLAIN SELECT c.id FROM documents d JOIN chunks c ON c.document_id = d.id
WHERE d.status = 'ACTIVE' AND d.effective_from <= '2026-10-30'
AND (d.effective_to IS NULL OR d.effective_to > '2026-10-30');
SHOW INDEX FROM documents;
SHOW INDEX FROM chunks;
