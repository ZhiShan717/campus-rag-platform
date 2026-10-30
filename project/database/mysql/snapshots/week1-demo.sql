
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `chunks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chunks` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `document_id` bigint NOT NULL,
  `chunk_no` int NOT NULL,
  `section_path` varchar(200) COLLATE utf8mb4_0900_as_ci NOT NULL,
  `content` text COLLATE utf8mb4_0900_as_ci NOT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_chunks_document_no` (`document_id`,`chunk_no`),
  CONSTRAINT `fk_chunks_document` FOREIGN KEY (`document_id`) REFERENCES `documents` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `ck_chunks_content` CHECK ((char_length(trim(`content`)) > 0)),
  CONSTRAINT `ck_chunks_no` CHECK ((`chunk_no` > 0)),
  CONSTRAINT `ck_chunks_section` CHECK ((char_length(trim(`section_path`)) > 0))
) ENGINE=InnoDB AUTO_INCREMENT=1090 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `chunks` WRITE;
/*!40000 ALTER TABLE `chunks` DISABLE KEYS */;
INSERT INTO `chunks` VALUES (1011,101,1,'第1条','【虚构演示】2025版奖学金申请面向全日制在籍本科生。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1012,101,2,'第2条','【虚构演示】奖学金申请需平均成绩不低于80分，仅适用于2025版。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1013,101,3,'第3条','【虚构演示】申请材料包括申请表、成绩单和个人事迹说明。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1014,101,4,'第4条','【虚构演示】申请由学院初审并公示，公示期为五个工作日。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1015,101,5,'第5条','【虚构演示】提交虚假材料者取消本次参评资格；有异议可按申诉办法处理。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1021,102,1,'第1条','【虚构演示】2026版奖学金申请面向全日制在籍本科生。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1022,102,2,'第2条','【虚构演示】奖学金申请需平均成绩不低于85分，仅适用于2026版。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1023,102,3,'第3条','【虚构演示】申请材料包括申请表、成绩单和个人事迹说明。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1024,102,4,'第4条','【虚构演示】申请由学院初审并公示，公示期为五个工作日。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1025,102,5,'第5条','【虚构演示】提交虚假材料者取消本次参评资格；有异议可按申诉办法处理。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1031,103,1,'第1条','【虚构演示】2027版奖学金申请面向全日制在籍本科生。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1032,103,2,'第2条','【虚构演示】奖学金申请需平均成绩不低于90分，自2026年11月1日起适用。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1033,103,3,'第3条','【虚构演示】申请材料包括申请表、成绩单和个人事迹说明。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1034,103,4,'第4条','【虚构演示】申请由学院初审并公示，公示期为五个工作日。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1035,103,5,'第5条','【虚构演示】提交虚假材料者取消本次参评资格；有异议可按申诉办法处理。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1041,104,1,'第1条','【虚构演示】助学金申请面向已完成家庭经济困难认定的在籍学生。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1042,104,2,'第2条','【虚构演示】助学金评审以家庭经济困难认定结果为基础。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1043,104,3,'第3条','【虚构演示】申请材料包括申请表和家庭经济困难认定证明。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1044,104,4,'第4条','【虚构演示】申请由学院初审并公示，公示期为五个工作日。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1045,104,5,'第5条','【虚构演示】提交虚假材料者取消本次参评资格；有异议可按申诉办法处理。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1051,105,1,'第1条','【虚构演示】临时困难补助适用于遭遇突发困难的学生，本办法已废止。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1052,105,2,'第2条','【虚构演示】本条仅用于测试无效制度能否被排除。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1053,105,3,'第3条','【虚构演示】申请材料包括申请表及相关证明。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1054,105,4,'第4条','【虚构演示】申请由学院初审并公示，公示期为五个工作日。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1055,105,5,'第5条','【虚构演示】提交虚假材料者取消本次参评资格；有异议可按申诉办法处理。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1061,106,1,'第1条','【虚构演示】勤工助学岗位面向学有余力的在籍学生，本办法已失效。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1062,106,2,'第2条','【虚构演示】本条仅用于测试无效制度能否被排除。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1063,106,3,'第3条','【虚构演示】申请材料包括申请表及相关证明。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1064,106,4,'第4条','【虚构演示】申请由学院初审并公示，公示期为五个工作日。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1065,106,5,'第5条','【虚构演示】提交虚假材料者取消本次参评资格；有异议可按申诉办法处理。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1071,107,1,'第1条','【虚构演示】学生可就奖助学金评审结果提出申诉。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1072,107,2,'第2条','【虚构演示】申诉材料须包含学号、事实说明和证明资料。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1073,107,3,'第3条','【虚构演示】申诉应在公示结束前提交至学院学生工作办公室。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1074,107,4,'第4条','【虚构演示】受理单位在收到完整材料后五个工作日内反馈处理进度。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1075,107,5,'第5条','【虚构演示】申诉资料由受理单位留档，未经授权不得向他人披露。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1081,108,1,'第1条','【虚构演示】优秀学生奖励规则为草稿，不作为正式依据。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1082,108,2,'第2条','【虚构演示】本条仅用于测试无效制度能否被排除。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1083,108,3,'第3条','【虚构演示】申请材料包括申请表及相关证明。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1084,108,4,'第4条','【虚构演示】申请由学院初审并公示，公示期为五个工作日。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366'),(1085,108,5,'第5条','【虚构演示】提交虚假材料者取消本次参评资格；有异议可按申诉办法处理。','2026-10-30 23:18:47.593366','2026-10-30 23:18:47.593366');
/*!40000 ALTER TABLE `chunks` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `documents` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `document_key` varchar(80) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `title` varchar(200) COLLATE utf8mb4_0900_as_ci NOT NULL,
  `version` varchar(32) COLLATE utf8mb4_0900_as_ci NOT NULL,
  `status` varchar(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'DRAFT',
  `effective_from` date NOT NULL,
  `effective_to` date DEFAULT NULL,
  `replaced_by` bigint DEFAULT NULL,
  `source_type` varchar(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `source_url` varchar(1024) COLLATE utf8mb4_0900_as_ci DEFAULT NULL,
  `source_note` varchar(500) COLLATE utf8mb4_0900_as_ci NOT NULL,
  `created_by` bigint NOT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_documents_version` (`document_key`,`version`),
  UNIQUE KEY `uq_documents_id_key` (`id`,`document_key`),
  UNIQUE KEY `uq_documents_predecessor` (`replaced_by`),
  KEY `idx_documents_effective` (`status`,`effective_from`,`effective_to`),
  KEY `fk_documents_creator` (`created_by`),
  KEY `fk_documents_successor` (`replaced_by`,`document_key`),
  CONSTRAINT `fk_documents_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_documents_successor` FOREIGN KEY (`replaced_by`, `document_key`) REFERENCES `documents` (`id`, `document_key`) ON DELETE RESTRICT,
  CONSTRAINT `ck_documents_dates` CHECK (((`effective_to` is null) or (`effective_to` > `effective_from`))),
  CONSTRAINT `ck_documents_key` CHECK (regexp_like(`document_key`,_utf8mb4'^[A-Za-z0-9_-]+$')),
  CONSTRAINT `ck_documents_provenance` CHECK (((char_length(trim(`source_note`)) > 0) and ((`source_type` <> _utf8mb4'PUBLIC') or ((`source_url` is not null) and (char_length(trim(`source_url`)) > 0))))),
  CONSTRAINT `ck_documents_source` CHECK ((`source_type` in (_utf8mb4'SYNTHETIC',_utf8mb4'PUBLIC'))),
  CONSTRAINT `ck_documents_status` CHECK ((`status` in (_utf8mb4'DRAFT',_utf8mb4'ACTIVE',_utf8mb4'REPEALED'))),
  CONSTRAINT `ck_documents_successor` CHECK (((`replaced_by` is null) or (`effective_to` is not null))),
  CONSTRAINT `ck_documents_title` CHECK ((char_length(trim(`title`)) > 0)),
  CONSTRAINT `ck_documents_version` CHECK ((char_length(trim(`version`)) > 0))
) ENGINE=InnoDB AUTO_INCREMENT=112 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `documents` WRITE;
/*!40000 ALTER TABLE `documents` DISABLE KEYS */;
INSERT INTO `documents` VALUES (101,'scholarship','【虚构演示】本科生奖学金办法','2025','ACTIVE','2025-01-01','2026-09-01',102,'SYNTHETIC',NULL,'虚构演示数据；不得作为真实申报依据。',1,'2026-10-30 23:18:47.590396','2026-10-30 23:18:47.592201'),(102,'scholarship','【虚构演示】本科生奖学金办法','2026','ACTIVE','2026-09-01','2026-11-01',103,'SYNTHETIC',NULL,'虚构演示数据；不得作为真实申报依据。',1,'2026-10-30 23:18:47.590396','2026-10-30 23:18:47.592745'),(103,'scholarship','【虚构演示】本科生奖学金办法','2027','ACTIVE','2026-11-01',NULL,NULL,'SYNTHETIC',NULL,'虚构演示数据；未来生效版本。',1,'2026-10-30 23:18:47.590396','2026-10-30 23:18:47.590396'),(104,'grant','【虚构演示】助学金申请办法','2026','ACTIVE','2026-01-01',NULL,NULL,'SYNTHETIC',NULL,'虚构演示数据；不得作为真实申报依据。',1,'2026-10-30 23:18:47.590396','2026-10-30 23:18:47.590396'),(105,'hardship','【虚构演示】临时困难补助办法','2024','REPEALED','2024-01-01',NULL,NULL,'SYNTHETIC',NULL,'虚构演示数据；已废止，默认检索排除。',1,'2026-10-30 23:18:47.590396','2026-10-30 23:18:47.590396'),(106,'work-study','【虚构演示】勤工助学岗位办法','2025','ACTIVE','2025-01-01','2026-10-30',NULL,'SYNTHETIC',NULL,'虚构演示数据；失效日当天排除。',1,'2026-10-30 23:18:47.590396','2026-10-30 23:18:47.590396'),(107,'appeal','【虚构演示】奖助学金申诉办法','2026','ACTIVE','2026-01-01',NULL,NULL,'SYNTHETIC',NULL,'虚构演示数据；不得作为真实申报依据。',1,'2026-10-30 23:18:47.590396','2026-10-30 23:18:47.590396'),(108,'merit','【虚构演示】优秀学生奖励细则','draft','DRAFT','2026-01-01',NULL,NULL,'SYNTHETIC',NULL,'虚构演示数据；草稿尚未发布。',1,'2026-10-30 23:18:47.590396','2026-10-30 23:18:47.590396');
/*!40000 ALTER TABLE `documents` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(64) COLLATE utf8mb4_0900_as_ci NOT NULL,
  `password_hash` varchar(100) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `display_name` varchar(64) COLLATE utf8mb4_0900_as_ci NOT NULL,
  `role` varchar(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'USER',
  `enabled` tinyint NOT NULL DEFAULT '1',
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_username` (`username`),
  CONSTRAINT `ck_users_display` CHECK ((char_length(trim(`display_name`)) > 0)),
  CONSTRAINT `ck_users_enabled` CHECK ((`enabled` in (0,1))),
  CONSTRAINT `ck_users_hash` CHECK (regexp_like(`password_hash`,_utf8mb4'^[$]2[aby][$][0-9]{2}[$][./A-Za-z0-9]{53}$')),
  CONSTRAINT `ck_users_role` CHECK ((`role` in (_utf8mb4'USER',_utf8mb4'ADMIN'))),
  CONSTRAINT `ck_users_username` CHECK (((char_length(trim(`username`)) > 0) and (`username` = trim(`username`))))
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_as_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'demo_admin','$2a$10$pzstyOO8bt8djNotaoJU/ef1YSRu8pK3CpuNcDIR8e5Hegz5dyABW','演示管理员','ADMIN',1,'2026-10-30 23:18:47.575989','2026-10-30 23:18:47.575989'),(2,'demo_student','$2a$10$pzstyOO8bt8djNotaoJU/ef1YSRu8pK3CpuNcDIR8e5Hegz5dyABW','演示学生','USER',1,'2026-10-30 23:18:47.575989','2026-10-30 23:18:47.575989');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

