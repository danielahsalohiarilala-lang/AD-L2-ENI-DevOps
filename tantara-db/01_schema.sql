-- MySQL dump 10.13  Distrib 8.4.11, for Linux (x86_64)
--
-- Host: localhost    Database: tantara
-- ------------------------------------------------------
-- Server version	8.4.11

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

--
-- Table structure for table `audit_log`
--

DROP TABLE IF EXISTS `audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_log` (
  `id_log` bigint unsigned NOT NULL AUTO_INCREMENT,
  `action` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_id` int unsigned NOT NULL,
  `meta` json DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `id_user` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id_log`),
  KEY `ix_audit_entity` (`entity`,`entity_id`),
  KEY `ix_audit_user` (`id_user`),
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`id_user`) REFERENCES `utilisateur` (`id_user`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_log`
--

LOCK TABLES `audit_log` WRITE;
/*!40000 ALTER TABLE `audit_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `audit_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `corpus`
--

DROP TABLE IF EXISTS `corpus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `corpus` (
  `id_corpus` int unsigned NOT NULL AUTO_INCREMENT,
  `genre` enum('tantara','hira_gasy') COLLATE utf8mb4_unicode_ci NOT NULL,
  `access_level` enum('public','restricted','private') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'restricted',
  `validated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `version` int unsigned NOT NULL DEFAULT '1',
  `id_cleaned` int unsigned NOT NULL,
  PRIMARY KEY (`id_corpus`),
  UNIQUE KEY `uq_corpus_cleaned` (`id_cleaned`),
  KEY `ix_corpus_genre_access` (`genre`,`access_level`),
  CONSTRAINT `fk_corpus_cleaned` FOREIGN KEY (`id_cleaned`) REFERENCES `texte_nettoye` (`id_cleaned`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `corpus`
--

LOCK TABLES `corpus` WRITE;
/*!40000 ALTER TABLE `corpus` DISABLE KEYS */;
/*!40000 ALTER TABLE `corpus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `corpus_revision`
--

DROP TABLE IF EXISTS `corpus_revision`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `corpus_revision` (
  `id_revision` int unsigned NOT NULL AUTO_INCREMENT,
  `content` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `id_corpus` int unsigned NOT NULL,
  `id_user` int unsigned NOT NULL,
  PRIMARY KEY (`id_revision`),
  KEY `ix_revision_corpus` (`id_corpus`),
  KEY `fk_revision_user` (`id_user`),
  FULLTEXT KEY `ft_revision_content` (`content`),
  CONSTRAINT `fk_revision_corpus` FOREIGN KEY (`id_corpus`) REFERENCES `corpus` (`id_corpus`) ON DELETE RESTRICT,
  CONSTRAINT `fk_revision_user` FOREIGN KEY (`id_user`) REFERENCES `utilisateur` (`id_user`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `corpus_revision`
--

LOCK TABLES `corpus_revision` WRITE;
/*!40000 ALTER TABLE `corpus_revision` DISABLE KEYS */;
/*!40000 ALTER TABLE `corpus_revision` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dataset_item`
--

DROP TABLE IF EXISTS `dataset_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dataset_item` (
  `id_dataset` int unsigned NOT NULL,
  `id_corpus` int unsigned NOT NULL,
  PRIMARY KEY (`id_dataset`,`id_corpus`),
  KEY `ix_item_corpus` (`id_corpus`),
  CONSTRAINT `fk_item_corpus` FOREIGN KEY (`id_corpus`) REFERENCES `corpus` (`id_corpus`) ON DELETE CASCADE,
  CONSTRAINT `fk_item_dataset` FOREIGN KEY (`id_dataset`) REFERENCES `dataset_version` (`id_dataset`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dataset_item`
--

LOCK TABLES `dataset_item` WRITE;
/*!40000 ALTER TABLE `dataset_item` DISABLE KEYS */;
/*!40000 ALTER TABLE `dataset_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dataset_version`
--

DROP TABLE IF EXISTS `dataset_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dataset_version` (
  `id_dataset` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `num_samples` int unsigned NOT NULL DEFAULT '0',
  `path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `id_org` int unsigned NOT NULL,
  PRIMARY KEY (`id_dataset`),
  UNIQUE KEY `uq_dataset_org_name` (`id_org`,`name`),
  CONSTRAINT `fk_dataset_org` FOREIGN KEY (`id_org`) REFERENCES `organisation` (`id_org`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dataset_version`
--

LOCK TABLES `dataset_version` WRITE;
/*!40000 ALTER TABLE `dataset_version` DISABLE KEYS */;
/*!40000 ALTER TABLE `dataset_version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fichier_media`
--

DROP TABLE IF EXISTS `fichier_media`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fichier_media` (
  `id_media` int unsigned NOT NULL AUTO_INCREMENT,
  `media_type` enum('audio','video','pdf') COLLATE utf8mb4_unicode_ci NOT NULL,
  `path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mime_type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `size_bytes` bigint unsigned DEFAULT NULL,
  `duration_s` int unsigned DEFAULT NULL,
  `checksum` char(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_raw` int unsigned NOT NULL,
  PRIMARY KEY (`id_media`),
  KEY `ix_media_raw` (`id_raw`),
  CONSTRAINT `fk_media_raw` FOREIGN KEY (`id_raw`) REFERENCES `texte_brut` (`id_raw`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fichier_media`
--

LOCK TABLES `fichier_media` WRITE;
/*!40000 ALTER TABLE `fichier_media` DISABLE KEYS */;
/*!40000 ALTER TABLE `fichier_media` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `generation`
--

DROP TABLE IF EXISTS `generation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `generation` (
  `id_gen` int unsigned NOT NULL AUTO_INCREMENT,
  `prompt` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `genre` enum('tantara','hira_gasy') COLLATE utf8mb4_unicode_ci NOT NULL,
  `max_tokens` int unsigned NOT NULL,
  `output` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `quality_score` decimal(3,2) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `id_user` int unsigned NOT NULL,
  `id_model` int unsigned NOT NULL,
  PRIMARY KEY (`id_gen`),
  KEY `ix_gen_user` (`id_user`),
  KEY `ix_gen_model` (`id_model`),
  CONSTRAINT `fk_gen_model` FOREIGN KEY (`id_model`) REFERENCES `model_artifact` (`id_model`) ON DELETE RESTRICT,
  CONSTRAINT `fk_gen_user` FOREIGN KEY (`id_user`) REFERENCES `utilisateur` (`id_user`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `generation`
--

LOCK TABLES `generation` WRITE;
/*!40000 ALTER TABLE `generation` DISABLE KEYS */;
/*!40000 ALTER TABLE `generation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `model_artifact`
--

DROP TABLE IF EXISTS `model_artifact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `model_artifact` (
  `id_model` int unsigned NOT NULL AUTO_INCREMENT,
  `path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `eval_score` decimal(5,3) DEFAULT NULL,
  `is_production` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `id_run` int unsigned NOT NULL,
  PRIMARY KEY (`id_model`),
  KEY `ix_model_run` (`id_run`),
  CONSTRAINT `fk_model_run` FOREIGN KEY (`id_run`) REFERENCES `training_run` (`id_run`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `model_artifact`
--

LOCK TABLES `model_artifact` WRITE;
/*!40000 ALTER TABLE `model_artifact` DISABLE KEYS */;
/*!40000 ALTER TABLE `model_artifact` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `organisation`
--

DROP TABLE IF EXISTS `organisation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `organisation` (
  `id_org` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_org`),
  UNIQUE KEY `uq_organisation_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `organisation`
--

LOCK TABLES `organisation` WRITE;
/*!40000 ALTER TABLE `organisation` DISABLE KEYS */;
/*!40000 ALTER TABLE `organisation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `revue`
--

DROP TABLE IF EXISTS `revue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revue` (
  `id_review` int unsigned NOT NULL AUTO_INCREMENT,
  `action` enum('validate','reject','comment') COLLATE utf8mb4_unicode_ci NOT NULL,
  `comment` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `id_user` int unsigned NOT NULL,
  `id_cleaned` int unsigned NOT NULL,
  PRIMARY KEY (`id_review`),
  KEY `ix_revue_cleaned` (`id_cleaned`),
  KEY `ix_revue_user` (`id_user`),
  CONSTRAINT `fk_revue_cleaned` FOREIGN KEY (`id_cleaned`) REFERENCES `texte_nettoye` (`id_cleaned`) ON DELETE RESTRICT,
  CONSTRAINT `fk_revue_user` FOREIGN KEY (`id_user`) REFERENCES `utilisateur` (`id_user`) ON DELETE RESTRICT,
  CONSTRAINT `ck_revue_reject_comment` CHECK (((`action` <> _utf8mb4'reject') or ((`comment` is not null) and (`comment` <> _utf8mb4''))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `revue`
--

LOCK TABLES `revue` WRITE;
/*!40000 ALTER TABLE `revue` DISABLE KEYS */;
/*!40000 ALTER TABLE `revue` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `role`
--

DROP TABLE IF EXISTS `role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role` (
  `id_role` int unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `libelle` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_role`),
  UNIQUE KEY `uq_role_code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `role`
--

LOCK TABLES `role` WRITE;
/*!40000 ALTER TABLE `role` DISABLE KEYS */;
INSERT INTO `role` VALUES (1,'reader','Lecteur'),(2,'reviewer','Relecteur'),(3,'admin','Administrateur');
/*!40000 ALTER TABLE `role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `scraping_job`
--

DROP TABLE IF EXISTS `scraping_job`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `scraping_job` (
  `id_job` int unsigned NOT NULL AUTO_INCREMENT,
  `status` enum('queued','running','done','failed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'queued',
  `params` json DEFAULT NULL,
  `error_message` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `started_at` datetime DEFAULT NULL,
  `finished_at` datetime DEFAULT NULL,
  `id_user` int unsigned DEFAULT NULL,
  `id_source` int unsigned NOT NULL,
  PRIMARY KEY (`id_job`),
  KEY `ix_job_source` (`id_source`),
  KEY `fk_job_user` (`id_user`),
  CONSTRAINT `fk_job_source` FOREIGN KEY (`id_source`) REFERENCES `source` (`id_source`) ON DELETE RESTRICT,
  CONSTRAINT `fk_job_user` FOREIGN KEY (`id_user`) REFERENCES `utilisateur` (`id_user`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `scraping_job`
--

LOCK TABLES `scraping_job` WRITE;
/*!40000 ALTER TABLE `scraping_job` DISABLE KEYS */;
/*!40000 ALTER TABLE `scraping_job` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `source`
--

DROP TABLE IF EXISTS `source`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `source` (
  `id_source` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `url` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` enum('web','youtube','pdf','manual') COLLATE utf8mb4_unicode_ci NOT NULL,
  `license` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_org` int unsigned NOT NULL,
  PRIMARY KEY (`id_source`),
  UNIQUE KEY `uq_source_org_url` (`id_org`,`url`(255)),
  CONSTRAINT `fk_source_org` FOREIGN KEY (`id_org`) REFERENCES `organisation` (`id_org`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `source`
--

LOCK TABLES `source` WRITE;
/*!40000 ALTER TABLE `source` DISABLE KEYS */;
/*!40000 ALTER TABLE `source` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `texte_brut`
--

DROP TABLE IF EXISTS `texte_brut`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `texte_brut` (
  `id_raw` int unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `content` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `language` char(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `creator` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `region` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `date_origin` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `origin_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `media_type` enum('text','audio','video','pdf') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'text',
  `collected_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('pending','cleaned','rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `reject_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `id_source` int unsigned NOT NULL,
  `id_job` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id_raw`),
  UNIQUE KEY `uq_brut_source_url` (`id_source`,`origin_url`(255)),
  KEY `ix_brut_status_source` (`status`,`id_source`),
  KEY `ix_brut_job` (`id_job`),
  CONSTRAINT `fk_brut_job` FOREIGN KEY (`id_job`) REFERENCES `scraping_job` (`id_job`) ON DELETE SET NULL,
  CONSTRAINT `fk_brut_source` FOREIGN KEY (`id_source`) REFERENCES `source` (`id_source`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `texte_brut`
--

LOCK TABLES `texte_brut` WRITE;
/*!40000 ALTER TABLE `texte_brut` DISABLE KEYS */;
/*!40000 ALTER TABLE `texte_brut` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `texte_nettoye`
--

DROP TABLE IF EXISTS `texte_nettoye`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `texte_nettoye` (
  `id_cleaned` int unsigned NOT NULL AUTO_INCREMENT,
  `content` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `word_count` int unsigned NOT NULL,
  `quality_score` decimal(3,2) DEFAULT NULL,
  `dedupe_hash` char(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('ready_for_review','validated','rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ready_for_review',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `id_raw` int unsigned NOT NULL,
  PRIMARY KEY (`id_cleaned`),
  UNIQUE KEY `uq_nettoye_raw` (`id_raw`),
  KEY `ix_nettoye_hash` (`dedupe_hash`),
  KEY `ix_nettoye_status_date` (`status`,`created_at`),
  FULLTEXT KEY `ft_nettoye_content` (`content`),
  CONSTRAINT `fk_nettoye_raw` FOREIGN KEY (`id_raw`) REFERENCES `texte_brut` (`id_raw`) ON DELETE RESTRICT,
  CONSTRAINT `ck_nettoye_quality` CHECK (((`quality_score` is null) or ((`quality_score` >= 0) and (`quality_score` <= 1))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `texte_nettoye`
--

LOCK TABLES `texte_nettoye` WRITE;
/*!40000 ALTER TABLE `texte_nettoye` DISABLE KEYS */;
/*!40000 ALTER TABLE `texte_nettoye` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `training_run`
--

DROP TABLE IF EXISTS `training_run`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `training_run` (
  `id_run` int unsigned NOT NULL AUTO_INCREMENT,
  `base_model` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `hyperparams` json DEFAULT NULL,
  `metrics` json DEFAULT NULL,
  `status` enum('queued','running','done','failed') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'queued',
  `started_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `finished_at` datetime DEFAULT NULL,
  `id_dataset` int unsigned NOT NULL,
  PRIMARY KEY (`id_run`),
  KEY `ix_run_dataset` (`id_dataset`),
  CONSTRAINT `fk_run_dataset` FOREIGN KEY (`id_dataset`) REFERENCES `dataset_version` (`id_dataset`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `training_run`
--

LOCK TABLES `training_run` WRITE;
/*!40000 ALTER TABLE `training_run` DISABLE KEYS */;
/*!40000 ALTER TABLE `training_run` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `utilisateur`
--

DROP TABLE IF EXISTS `utilisateur`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `utilisateur` (
  `id_user` int unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `locale` char(2) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'fr',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `id_role` int unsigned NOT NULL,
  `id_org` int unsigned NOT NULL,
  PRIMARY KEY (`id_user`),
  UNIQUE KEY `uq_utilisateur_email` (`email`),
  KEY `ix_utilisateur_org` (`id_org`),
  KEY `fk_utilisateur_role` (`id_role`),
  CONSTRAINT `fk_utilisateur_org` FOREIGN KEY (`id_org`) REFERENCES `organisation` (`id_org`) ON DELETE RESTRICT,
  CONSTRAINT `fk_utilisateur_role` FOREIGN KEY (`id_role`) REFERENCES `role` (`id_role`) ON DELETE RESTRICT,
  CONSTRAINT `ck_utilisateur_locale` CHECK ((`locale` in (_utf8mb4'fr',_utf8mb4'mg')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `utilisateur`
--

LOCK TABLES `utilisateur` WRITE;
/*!40000 ALTER TABLE `utilisateur` DISABLE KEYS */;
/*!40000 ALTER TABLE `utilisateur` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_corpus_courant`
--

DROP TABLE IF EXISTS `v_corpus_courant`;
/*!50001 DROP VIEW IF EXISTS `v_corpus_courant`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_corpus_courant` AS SELECT 
 1 AS `id_corpus`,
 1 AS `genre`,
 1 AS `access_level`,
 1 AS `validated_at`,
 1 AS `version`,
 1 AS `id_cleaned`,
 1 AS `id_raw`,
 1 AS `title`,
 1 AS `creator`,
 1 AS `region`,
 1 AS `language`,
 1 AS `media_type`,
 1 AS `id_source`,
 1 AS `id_org`,
 1 AS `license`,
 1 AS `content`*/;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `v_corpus_courant`
--

/*!50001 DROP VIEW IF EXISTS `v_corpus_courant`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_corpus_courant` AS select `c`.`id_corpus` AS `id_corpus`,`c`.`genre` AS `genre`,`c`.`access_level` AS `access_level`,`c`.`validated_at` AS `validated_at`,`c`.`version` AS `version`,`tn`.`id_cleaned` AS `id_cleaned`,`tb`.`id_raw` AS `id_raw`,`tb`.`title` AS `title`,`tb`.`creator` AS `creator`,`tb`.`region` AS `region`,`tb`.`language` AS `language`,`tb`.`media_type` AS `media_type`,`s`.`id_source` AS `id_source`,`s`.`id_org` AS `id_org`,`s`.`license` AS `license`,coalesce((select `cr`.`content` from `corpus_revision` `cr` where (`cr`.`id_corpus` = `c`.`id_corpus`) order by `cr`.`created_at` desc,`cr`.`id_revision` desc limit 1),`tn`.`content`) AS `content` from (((`corpus` `c` join `texte_nettoye` `tn` on((`tn`.`id_cleaned` = `c`.`id_cleaned`))) join `texte_brut` `tb` on((`tb`.`id_raw` = `tn`.`id_raw`))) join `source` `s` on((`s`.`id_source` = `tb`.`id_source`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-12 18:19:17
