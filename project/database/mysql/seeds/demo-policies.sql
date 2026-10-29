-- 奖助学金演示制度数据（自动生成，勿手工编辑）
-- 生成器：project/database/mysql/seeds/tools/export_seed_sql.py
-- 规模：8 份制度 / 10 个版本 / 43 条条款
-- 数据性质：全部为虚构演示数据，不得对外宣称是真实政策
-- 前置条件：documents / document_versions / chunks 三表已按字段表建好

SET NAMES utf8mb4;

-- 可重复执行：先清空演示数据
DELETE FROM `chunks` WHERE `id` LIKE 'c%';
DELETE FROM `document_versions` WHERE `id` LIKE 'v%';
DELETE FROM `documents` WHERE `id` LIKE 'd%';

-- documents
INSERT INTO `documents` (`id`, `title`, `doc_no`, `issuer`, `category`, `source_type`, `source_note`, `created_at`) VALUES ('d001', '国家奖学金评审办法', '〔演示〕学字2024-12号', '学生工作处', 'NATIONAL_SCHOLARSHIP', 'FAKE_DEMO', '虚构演示数据，依据公开政策精神改写，不对应任何真实校发文件', '2026-10-24T10:00:00+08:00');
INSERT INTO `documents` (`id`, `title`, `doc_no`, `issuer`, `category`, `source_type`, `source_note`, `created_at`) VALUES ('d002', '国家励志奖学金实施办法', '〔演示〕学字2023-08号', '学生工作处', 'NATIONAL_INSPIRATION', 'FAKE_DEMO', '虚构演示数据，依据公开政策精神改写，不对应任何真实校发文件', '2026-10-24T10:05:00+08:00');
INSERT INTO `documents` (`id`, `title`, `doc_no`, `issuer`, `category`, `source_type`, `source_note`, `created_at`) VALUES ('d003', '校级优秀学生奖学金评定办法', '〔演示〕校字2022-03号', '学校奖学金评审委员会', 'SCHOOL_SCHOLARSHIP', 'FAKE_DEMO', '虚构演示数据，不对应任何真实校发文件', '2026-10-24T10:10:00+08:00');
INSERT INTO `documents` (`id`, `title`, `doc_no`, `issuer`, `category`, `source_type`, `source_note`, `created_at`) VALUES ('d004', '家庭经济困难学生认定办法', '〔演示〕学字2023-15号', '学生工作处', 'NEED_ASSESSMENT', 'FAKE_DEMO', '虚构演示数据，不对应任何真实校发文件', '2026-10-24T10:15:00+08:00');
INSERT INTO `documents` (`id`, `title`, `doc_no`, `issuer`, `category`, `source_type`, `source_note`, `created_at`) VALUES ('d005', '国家助学金管理办法', '〔演示〕学字2019-05号', '学生工作处', 'NATIONAL_GRANT', 'FAKE_DEMO', '虚构演示数据，用于演示「已废止制度不得作为依据」的检索行为', '2026-10-24T10:20:00+08:00');
INSERT INTO `documents` (`id`, `title`, `doc_no`, `issuer`, `category`, `source_type`, `source_note`, `created_at`) VALUES ('d006', '勤工助学管理办法', '〔演示〕学字2026-02号', '学生资助管理中心', 'WORK_STUDY', 'FAKE_DEMO', '虚构演示数据，用于演示「已发布未生效」的检索行为', '2026-10-24T10:25:00+08:00');
INSERT INTO `documents` (`id`, `title`, `doc_no`, `issuer`, `category`, `source_type`, `source_note`, `created_at`) VALUES ('d007', '生源地信用助学贷款实施细则', '〔演示〕学字2025-06号', '学生资助管理中心', 'STUDENT_LOAN', 'FAKE_DEMO', '虚构演示数据，用于演示「新版替代旧版」的额度变化', '2026-10-24T10:30:00+08:00');
INSERT INTO `documents` (`id`, `title`, `doc_no`, `issuer`, `category`, `source_type`, `source_note`, `created_at`) VALUES ('d008', '校级临时困难补助办法', '〔演示〕学字2024-20号', '学生工作处', 'NEED_ASSESSMENT', 'FAKE_DEMO', '虚构演示数据，不对应任何真实校发文件', '2026-10-24T10:35:00+08:00');

-- document_versions
INSERT INTO `document_versions` (`id`, `document_id`, `version_no`, `status`, `effective_date`, `expiry_date`, `replaced_by`, `published_date`, `summary`) VALUES ('v001', 'd001', '2021版', 'SUPERSEDED', '2021-09-01', '2024-08-31', 'v002', '2021-07-15', '旧版：奖励标准 8000 元，学业成绩排名前 10%');
INSERT INTO `document_versions` (`id`, `document_id`, `version_no`, `status`, `effective_date`, `expiry_date`, `replaced_by`, `published_date`, `summary`) VALUES ('v002', 'd001', '2024版', 'ACTIVE', '2024-09-01', NULL, NULL, '2024-07-20', '2024 修订：奖励标准提高到 10000 元，成绩门槛收紧至前 5%');
INSERT INTO `document_versions` (`id`, `document_id`, `version_no`, `status`, `effective_date`, `expiry_date`, `replaced_by`, `published_date`, `summary`) VALUES ('v003', 'd002', '2023版', 'ACTIVE', '2023-09-01', NULL, NULL, '2023-07-10', '现行版本');
INSERT INTO `document_versions` (`id`, `document_id`, `version_no`, `status`, `effective_date`, `expiry_date`, `replaced_by`, `published_date`, `summary`) VALUES ('v004', 'd003', '2022版', 'ACTIVE', '2022-03-01', NULL, NULL, '2021-12-20', '现行版本');
INSERT INTO `document_versions` (`id`, `document_id`, `version_no`, `status`, `effective_date`, `expiry_date`, `replaced_by`, `published_date`, `summary`) VALUES ('v005', 'd004', '2023版', 'ACTIVE', '2023-09-01', NULL, NULL, '2023-06-30', '现行版本');
INSERT INTO `document_versions` (`id`, `document_id`, `version_no`, `status`, `effective_date`, `expiry_date`, `replaced_by`, `published_date`, `summary`) VALUES ('v006', 'd005', '2019版', 'ABOLISHED', '2019-09-01', '2025-08-31', NULL, '2019-07-01', '2025 年 8 月 31 日废止，后续办法尚未发布');
INSERT INTO `document_versions` (`id`, `document_id`, `version_no`, `status`, `effective_date`, `expiry_date`, `replaced_by`, `published_date`, `summary`) VALUES ('v007', 'd006', '2026版', 'PENDING', '2027-03-01', NULL, NULL, '2026-12-20', '2026 年 12 月发布，2027 年 3 月 1 日起施行，整理数据时尚未生效');
INSERT INTO `document_versions` (`id`, `document_id`, `version_no`, `status`, `effective_date`, `expiry_date`, `replaced_by`, `published_date`, `summary`) VALUES ('v008', 'd007', '2020版', 'SUPERSEDED', '2020-09-01', '2025-08-31', 'v009', '2020-07-01', '旧版：每年最高贷款 12000 元');
INSERT INTO `document_versions` (`id`, `document_id`, `version_no`, `status`, `effective_date`, `expiry_date`, `replaced_by`, `published_date`, `summary`) VALUES ('v009', 'd007', '2025版', 'ACTIVE', '2025-09-01', NULL, NULL, '2025-07-05', '2025 修订：贷款额度提高到 16000 元，毕业后增设只还息宽限期');
INSERT INTO `document_versions` (`id`, `document_id`, `version_no`, `status`, `effective_date`, `expiry_date`, `replaced_by`, `published_date`, `summary`) VALUES ('v010', 'd008', '2024版', 'ACTIVE', '2024-09-01', NULL, NULL, '2024-08-01', '现行版本');

-- chunks
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c001', 'v001', '第一条', '第一章 总则', 1, '为激励学生勤奋学习、全面发展，学校设立国家奖学金，用于奖励特别优秀的全日制在校本科生。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c002', 'v001', '第二条', '第二章 奖励标准', 2, '国家奖学金每人每年 8000 元，一次性发放至学生本人银行卡。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c003', 'v001', '第三条', '第三章 申请条件', 3, '申请国家奖学金的学生，上一学年学业成绩排名须在本专业前 10%。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c004', 'v001', '第四条', '第三章 申请条件', 4, '申请学生须无不及格课程，且在校期间未受过纪律处分。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c005', 'v001', '第五条', '第四章 评审程序', 5, '学院初评后报学校评审委员会审定，评审结果在全校范围内公示 5 个工作日。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c006', 'v002', '第一条', '第一章 总则', 1, '为激励学生勤奋学习、全面发展，学校设立国家奖学金，用于奖励特别优秀的全日制在校本科生，评审工作坚持公开、公平、公正原则。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c007', 'v002', '第二条', '第二章 奖励标准', 2, '国家奖学金每人每年 10000 元，一次性发放至学生本人银行卡。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c008', 'v002', '第三条', '第三章 申请条件', 3, '申请国家奖学金的学生，上一学年学业成绩排名须在本专业前 5%，综合素质考评排名须在本专业前 10%。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c009', 'v002', '第四条', '第三章 申请条件', 4, '申请学生须无不及格课程、未受过纪律处分，且同一学年未获得其他同级奖学金。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c010', 'v002', '第五条', '第四章 评审程序', 5, '学院初评后报学校评审委员会审定，评审结果在全校范围内公示 5 个工作日，公示无异议后报上级主管部门备案。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c011', 'v003', '第一条', '第一章 总则', 1, '为资助家庭经济困难且品学兼优的全日制本科生，学校设立国家励志奖学金。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c012', 'v003', '第二条', '第二章 奖励标准', 2, '国家励志奖学金的奖励金额为每人每年 5000 元，按学年一次性发放。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c013', 'v003', '第三条', '第三章 申请条件', 3, '申请学生须已通过家庭经济困难认定，且上一学年学业成绩排名在本专业前 30%。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c014', 'v003', '第四条', '第三章 申请条件', 4, '同一学年内，国家励志奖学金与国家奖学金不可同时获得，学生只能选择其中一项申报。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c015', 'v003', '第五条', '第四章 评审程序', 5, '学生本人申请，学院审核并公示 3 个工作日后报学生工作处，全校公示 5 个工作日。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c016', 'v004', '第一条', '一、奖项设置', 1, '学校设立校级优秀学生奖学金，分为一等奖、二等奖、三等奖三个等级，每学年评定一次。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c017', 'v004', '第二条', '二、奖励标准', 2, '一等奖 3000 元，二等奖 2000 元，三等奖 1000 元，同一学年不重复发放。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c018', 'v004', '第三条', '三、申请条件', 3, '申请学生上一学年综合测评排名须在本班级前 20%，且无不及格课程。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c019', 'v004', '第四条', '四、评定程序', 4, '班级评议小组初评，学院审核后报学生工作处备案，评定结果在学院范围内公示 3 个工作日。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c020', 'v005', '第一条', '第一章 总则', 1, '家庭经济困难学生认定结果是申请国家助学金、国家励志奖学金和勤工助学岗位的前提条件。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c021', 'v005', '第二条', '第二章 认定等级', 2, '认定结果分为特别困难、困难、一般困难三档，分别对应不同的资助力度。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c022', 'v005', '第三条', '第三章 申请材料', 3, '申请学生须提交家庭经济情况说明及相应证明材料，并对材料真实性负责，提供虚假材料者取消当年认定资格。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c023', 'v005', '第四条', '第四章 认定程序', 4, '每年 9 月集中受理认定申请，班级评议、学院审核后公示 5 个工作日。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c024', 'v005', '第五条', '第五章 结果管理', 5, '认定结果有效期为一个学年，家庭经济状况发生重大变化的，可随时申请复核。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c025', 'v006', '第一条', '第一章 总则', 1, '为资助家庭经济困难学生的生活费用开支，学校设立国家助学金。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c026', 'v006', '第二条', '第二章 资助标准', 2, '国家助学金平均每人每年 3300 元，按困难等级分档发放。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c027', 'v006', '第三条', '第三章 申请条件', 3, '申请学生须已通过家庭经济困难认定，且在校期间无纪律处分记录。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c028', 'v006', '第四条', '第四章 发放方式', 4, '国家助学金按学期分两次发放至学生本人银行卡，不得由他人代领。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c029', 'v007', '第一条', '第一章 总则', 1, '学校设置勤工助学岗位，帮助家庭经济困难学生通过劳动获得报酬，培养自立自强意识。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c030', 'v007', '第二条', '第二章 岗位设置', 2, '勤工助学岗位包括校内助管、助教和实验室助理三类，由学生资助管理中心统一发布。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c031', 'v007', '第三条', '第三章 报酬标准', 3, '勤工助学报酬每小时不低于 20 元，每名学生每月工作时间不超过 40 小时。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c032', 'v007', '第四条', '第四章 岗位申请', 4, '已通过家庭经济困难认定的学生在岗位申请中优先录用。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c033', 'v008', '第一条', '第一章 总则', 1, '生源地信用助学贷款由国家开发银行等金融机构向符合条件的家庭经济困难学生发放。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c034', 'v008', '第二条', '第二章 贷款额度', 2, '全日制普通本专科学生每人每年贷款额度最高 12000 元，用于支付学费和住宿费。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c035', 'v008', '第三条', '第三章 贷款期限', 3, '贷款期限为学制年限加 15 年，最长不超过 22 年。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c036', 'v008', '第四条', '第四章 贴息政策', 4, '学生在校期间的贷款利息由财政全额补贴，毕业后开始承担利息。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c037', 'v009', '第一条', '第一章 总则', 1, '生源地信用助学贷款由国家开发银行等金融机构向符合条件的家庭经济困难学生发放，用于支付学费和住宿费。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c038', 'v009', '第二条', '第二章 贷款额度', 2, '全日制普通本专科学生每人每年贷款额度最高 16000 元。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c039', 'v009', '第三条', '第三章 贷款期限', 3, '贷款期限为学制年限加 15 年，最长不超过 22 年。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c040', 'v009', '第四条', '第四章 贴息政策', 4, '学生在校期间利息由财政全额补贴，毕业后 5 年内只需偿还利息，第 6 年起偿还本金。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c041', 'v010', '第一条', '一、适用情形', 1, '学生本人或家庭遭遇突发变故、重大疾病等导致经济困难的，可申请校级临时困难补助。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c042', 'v010', '第二条', '二、补助标准', 2, '临时困难补助为一次性发放，金额在 1000 元至 5000 元之间，由评审小组按实际情况确定。');
INSERT INTO `chunks` (`id`, `version_id`, `clause_no`, `section_path`, `order_no`, `content`) VALUES ('c043', 'v010', '第三条', '三、申请程序', 3, '学生本人提出申请，学院核实情况后报学生工作处审批，审批通过后 10 个工作日内发放。');

-- 结束：8 / 10 / 43
