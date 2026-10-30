-- SYNTHETIC DEMO DATA ONLY. Not any university's actual policy.
-- Import once after V001 into an empty database. Never overwrite existing users.
SET NAMES utf8mb4;
START TRANSACTION;
INSERT INTO users (id, username, password_hash, display_name, role) VALUES
(1, 'demo_admin', '$2a$10$pzstyOO8bt8djNotaoJU/ef1YSRu8pK3CpuNcDIR8e5Hegz5dyABW', '演示管理员', 'ADMIN'),
(2, 'demo_student', '$2a$10$pzstyOO8bt8djNotaoJU/ef1YSRu8pK3CpuNcDIR8e5Hegz5dyABW', '演示学生', 'USER');
INSERT INTO documents
(id, document_key, title, version, status, effective_from, effective_to, source_type, source_note, created_by) VALUES
(101, 'scholarship', '【虚构演示】本科生奖学金办法', '2025', 'ACTIVE', '2025-01-01', '2026-09-01', 'SYNTHETIC', '虚构演示数据；不得作为真实申报依据。', 1),
(102, 'scholarship', '【虚构演示】本科生奖学金办法', '2026', 'ACTIVE', '2026-09-01', '2026-11-01', 'SYNTHETIC', '虚构演示数据；不得作为真实申报依据。', 1),
(103, 'scholarship', '【虚构演示】本科生奖学金办法', '2027', 'ACTIVE', '2026-11-01', NULL, 'SYNTHETIC', '虚构演示数据；未来生效版本。', 1),
(104, 'grant', '【虚构演示】助学金申请办法', '2026', 'ACTIVE', '2026-01-01', NULL, 'SYNTHETIC', '虚构演示数据；不得作为真实申报依据。', 1),
(105, 'hardship', '【虚构演示】临时困难补助办法', '2024', 'REPEALED', '2024-01-01', NULL, 'SYNTHETIC', '虚构演示数据；已废止，默认检索排除。', 1),
(106, 'work-study', '【虚构演示】勤工助学岗位办法', '2025', 'ACTIVE', '2025-01-01', '2026-10-30', 'SYNTHETIC', '虚构演示数据；失效日当天排除。', 1),
(107, 'appeal', '【虚构演示】奖助学金申诉办法', '2026', 'ACTIVE', '2026-01-01', NULL, 'SYNTHETIC', '虚构演示数据；不得作为真实申报依据。', 1),
(108, 'merit', '【虚构演示】优秀学生奖励细则', 'draft', 'DRAFT', '2026-01-01', NULL, 'SYNTHETIC', '虚构演示数据；草稿尚未发布。', 1);
UPDATE documents SET replaced_by = 102 WHERE id = 101;
UPDATE documents SET replaced_by = 103 WHERE id = 102;

INSERT INTO chunks (id, document_id, chunk_no, section_path, content)
SELECT d.id * 10 + n.n, d.id, n.n, CONCAT('第', n.n, '条'),
    CASE n.n
      WHEN 1 THEN CASE d.document_key
        WHEN 'scholarship' THEN CONCAT('【虚构演示】', d.version, '版奖学金申请面向全日制在籍本科生。')
        WHEN 'grant' THEN '【虚构演示】助学金申请面向已完成家庭经济困难认定的在籍学生。'
        WHEN 'hardship' THEN '【虚构演示】临时困难补助适用于遭遇突发困难的学生，本办法已废止。'
        WHEN 'work-study' THEN '【虚构演示】勤工助学岗位面向学有余力的在籍学生，本办法已失效。'
        WHEN 'appeal' THEN '【虚构演示】学生可就奖助学金评审结果提出申诉。'
        ELSE '【虚构演示】优秀学生奖励规则为草稿，不作为正式依据。' END
      WHEN 2 THEN CASE d.id
        WHEN 101 THEN '【虚构演示】奖学金申请需平均成绩不低于80分，仅适用于2025版。'
        WHEN 102 THEN '【虚构演示】奖学金申请需平均成绩不低于85分，仅适用于2026版。'
        WHEN 103 THEN '【虚构演示】奖学金申请需平均成绩不低于90分，自2026年11月1日起适用。'
        WHEN 104 THEN '【虚构演示】助学金评审以家庭经济困难认定结果为基础。'
        WHEN 107 THEN '【虚构演示】申诉材料须包含学号、事实说明和证明资料。'
        ELSE '【虚构演示】本条仅用于测试无效制度能否被排除。' END
      WHEN 3 THEN CASE d.document_key
        WHEN 'scholarship' THEN '【虚构演示】申请材料包括申请表、成绩单和个人事迹说明。'
        WHEN 'grant' THEN '【虚构演示】申请材料包括申请表和家庭经济困难认定证明。'
        WHEN 'appeal' THEN '【虚构演示】申诉应在公示结束前提交至学院学生工作办公室。'
        ELSE '【虚构演示】申请材料包括申请表及相关证明。' END
      WHEN 4 THEN CASE d.document_key
        WHEN 'appeal' THEN '【虚构演示】受理单位在收到完整材料后五个工作日内反馈处理进度。'
        ELSE '【虚构演示】申请由学院初审并公示，公示期为五个工作日。' END
      ELSE CASE d.document_key
        WHEN 'appeal' THEN '【虚构演示】申诉资料由受理单位留档，未经授权不得向他人披露。'
        ELSE '【虚构演示】提交虚假材料者取消本次参评资格；有异议可按申诉办法处理。' END
    END
FROM documents d CROSS JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n
WHERE d.id BETWEEN 101 AND 108;
COMMIT;
