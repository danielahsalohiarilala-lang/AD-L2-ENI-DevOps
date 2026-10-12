-- ============================================================
-- Tantara SaaS : schéma MySQL 8 (MPD), modèle de données v2
-- Exécuté automatiquement au premier démarrage du conteneur MySQL.
-- ============================================================
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS organisation (
  id_org      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name        VARCHAR(150) NOT NULL,
  slug        VARCHAR(80)  NOT NULL,
  is_active   TINYINT(1)   NOT NULL DEFAULT 1,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_org),
  UNIQUE KEY uq_organisation_slug (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS role (
  id_role  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  code     VARCHAR(20) NOT NULL,
  libelle  VARCHAR(50) NOT NULL,
  PRIMARY KEY (id_role),
  UNIQUE KEY uq_role_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS utilisateur (
  id_user        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  email          VARCHAR(255) NOT NULL,
  password_hash  VARCHAR(255) NOT NULL,
  locale         CHAR(2)      NOT NULL DEFAULT 'fr',
  is_active      TINYINT(1)   NOT NULL DEFAULT 1,
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_role        INT UNSIGNED NOT NULL,
  id_org         INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_user),
  UNIQUE KEY uq_utilisateur_email (email),
  KEY ix_utilisateur_org (id_org),
  CONSTRAINT fk_utilisateur_role FOREIGN KEY (id_role) REFERENCES role (id_role) ON DELETE RESTRICT,
  CONSTRAINT fk_utilisateur_org  FOREIGN KEY (id_org)  REFERENCES organisation (id_org) ON DELETE RESTRICT,
  CONSTRAINT ck_utilisateur_locale CHECK (locale IN ('fr','mg'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS source (
  id_source  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name       VARCHAR(150) NOT NULL,
  url        VARCHAR(500) NOT NULL,
  type       ENUM('web','youtube','pdf','manual') NOT NULL,
  license    VARCHAR(100) NOT NULL,
  id_org     INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_source),
  UNIQUE KEY uq_source_org_url (id_org, url(255)),
  CONSTRAINT fk_source_org FOREIGN KEY (id_org) REFERENCES organisation (id_org) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS scraping_job (
  id_job         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  status         ENUM('queued','running','done','failed') NOT NULL DEFAULT 'queued',
  params         JSON NULL,
  error_message  TEXT NULL,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  started_at     DATETIME NULL,
  finished_at    DATETIME NULL,
  id_user        INT UNSIGNED NULL,
  id_source      INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_job),
  KEY ix_job_source (id_source),
  CONSTRAINT fk_job_user   FOREIGN KEY (id_user)   REFERENCES utilisateur (id_user) ON DELETE SET NULL,
  CONSTRAINT fk_job_source FOREIGN KEY (id_source) REFERENCES source (id_source) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS texte_brut (
  id_raw         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  title          VARCHAR(255) NULL,
  content        LONGTEXT NOT NULL,
  language       CHAR(2) NOT NULL,
  creator        VARCHAR(200) NULL,
  region         VARCHAR(100) NULL,
  date_origin    VARCHAR(50) NULL,
  origin_url     VARCHAR(500) NULL,
  media_type     ENUM('text','audio','video','pdf') NOT NULL DEFAULT 'text',
  collected_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status         ENUM('pending','cleaned','rejected') NOT NULL DEFAULT 'pending',
  reject_reason  VARCHAR(255) NULL,
  id_source      INT UNSIGNED NOT NULL,
  id_job         INT UNSIGNED NULL,
  PRIMARY KEY (id_raw),
  KEY ix_brut_status_source (status, id_source),
  KEY ix_brut_job (id_job),
  UNIQUE KEY uq_brut_source_url (id_source, origin_url(255)),
  CONSTRAINT fk_brut_source FOREIGN KEY (id_source) REFERENCES source (id_source) ON DELETE RESTRICT,
  CONSTRAINT fk_brut_job    FOREIGN KEY (id_job)    REFERENCES scraping_job (id_job) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS fichier_media (
  id_media    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  media_type  ENUM('audio','video','pdf') NOT NULL,
  path        VARCHAR(500) NOT NULL,
  mime_type   VARCHAR(100) NULL,
  size_bytes  BIGINT UNSIGNED NULL,
  duration_s  INT UNSIGNED NULL,
  checksum    CHAR(64) NOT NULL,
  id_raw      INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_media),
  KEY ix_media_raw (id_raw),
  CONSTRAINT fk_media_raw FOREIGN KEY (id_raw) REFERENCES texte_brut (id_raw) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS texte_nettoye (
  id_cleaned     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  content        LONGTEXT NOT NULL,
  word_count     INT UNSIGNED NOT NULL,
  quality_score  DECIMAL(3,2) NULL,
  dedupe_hash    CHAR(64) NOT NULL,
  status         ENUM('ready_for_review','validated','rejected') NOT NULL DEFAULT 'ready_for_review',
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_raw         INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_cleaned),
  UNIQUE KEY uq_nettoye_raw (id_raw),
  KEY ix_nettoye_hash (dedupe_hash),
  KEY ix_nettoye_status_date (status, created_at),
  FULLTEXT KEY ft_nettoye_content (content),
  CONSTRAINT fk_nettoye_raw FOREIGN KEY (id_raw) REFERENCES texte_brut (id_raw) ON DELETE RESTRICT,
  CONSTRAINT ck_nettoye_quality CHECK (quality_score IS NULL OR (quality_score >= 0 AND quality_score <= 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS revue (
  id_review   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  action      ENUM('validate','reject','comment') NOT NULL,
  comment     TEXT NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_user     INT UNSIGNED NOT NULL,
  id_cleaned  INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_review),
  KEY ix_revue_cleaned (id_cleaned),
  KEY ix_revue_user (id_user),
  CONSTRAINT fk_revue_user    FOREIGN KEY (id_user)    REFERENCES utilisateur (id_user) ON DELETE RESTRICT,
  CONSTRAINT fk_revue_cleaned FOREIGN KEY (id_cleaned) REFERENCES texte_nettoye (id_cleaned) ON DELETE RESTRICT,
  CONSTRAINT ck_revue_reject_comment CHECK (action <> 'reject' OR (comment IS NOT NULL AND comment <> ''))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS corpus (
  id_corpus     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  genre         ENUM('tantara','hira_gasy') NOT NULL,
  access_level  ENUM('public','restricted','private') NOT NULL DEFAULT 'restricted',
  validated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  version       INT UNSIGNED NOT NULL DEFAULT 1,
  id_cleaned    INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_corpus),
  UNIQUE KEY uq_corpus_cleaned (id_cleaned),
  KEY ix_corpus_genre_access (genre, access_level),
  CONSTRAINT fk_corpus_cleaned FOREIGN KEY (id_cleaned) REFERENCES texte_nettoye (id_cleaned) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS corpus_revision (
  id_revision  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  content      LONGTEXT NOT NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_corpus    INT UNSIGNED NOT NULL,
  id_user      INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_revision),
  KEY ix_revision_corpus (id_corpus),
  FULLTEXT KEY ft_revision_content (content),
  CONSTRAINT fk_revision_corpus FOREIGN KEY (id_corpus) REFERENCES corpus (id_corpus) ON DELETE RESTRICT,
  CONSTRAINT fk_revision_user   FOREIGN KEY (id_user)   REFERENCES utilisateur (id_user) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dataset_version (
  id_dataset   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name         VARCHAR(100) NOT NULL,
  num_samples  INT UNSIGNED NOT NULL DEFAULT 0,
  path         VARCHAR(500) NOT NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_org       INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_dataset),
  UNIQUE KEY uq_dataset_org_name (id_org, name),
  CONSTRAINT fk_dataset_org FOREIGN KEY (id_org) REFERENCES organisation (id_org) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS dataset_item (
  id_dataset  INT UNSIGNED NOT NULL,
  id_corpus   INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_dataset, id_corpus),
  KEY ix_item_corpus (id_corpus),
  CONSTRAINT fk_item_dataset FOREIGN KEY (id_dataset) REFERENCES dataset_version (id_dataset) ON DELETE CASCADE,
  CONSTRAINT fk_item_corpus  FOREIGN KEY (id_corpus)  REFERENCES corpus (id_corpus) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS training_run (
  id_run       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  base_model   VARCHAR(150) NOT NULL,
  hyperparams  JSON NULL,
  metrics      JSON NULL,
  status       ENUM('queued','running','done','failed') NOT NULL DEFAULT 'queued',
  started_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  finished_at  DATETIME NULL,
  id_dataset   INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_run),
  KEY ix_run_dataset (id_dataset),
  CONSTRAINT fk_run_dataset FOREIGN KEY (id_dataset) REFERENCES dataset_version (id_dataset) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS model_artifact (
  id_model       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  path           VARCHAR(500) NOT NULL,
  eval_score     DECIMAL(5,3) NULL,
  is_production  TINYINT(1) NOT NULL DEFAULT 0,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_run         INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_model),
  KEY ix_model_run (id_run),
  CONSTRAINT fk_model_run FOREIGN KEY (id_run) REFERENCES training_run (id_run) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS generation (
  id_gen         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  prompt         TEXT NOT NULL,
  genre          ENUM('tantara','hira_gasy') NOT NULL,
  max_tokens     INT UNSIGNED NOT NULL,
  output         LONGTEXT NOT NULL,
  quality_score  DECIMAL(3,2) NULL,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_user        INT UNSIGNED NOT NULL,
  id_model       INT UNSIGNED NOT NULL,
  PRIMARY KEY (id_gen),
  KEY ix_gen_user (id_user),
  KEY ix_gen_model (id_model),
  CONSTRAINT fk_gen_user  FOREIGN KEY (id_user)  REFERENCES utilisateur (id_user) ON DELETE RESTRICT,
  CONSTRAINT fk_gen_model FOREIGN KEY (id_model) REFERENCES model_artifact (id_model) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_log (
  id_log      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  action      VARCHAR(50) NOT NULL,
  entity      VARCHAR(50) NOT NULL,
  entity_id   INT UNSIGNED NOT NULL,
  meta        JSON NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_user     INT UNSIGNED NULL,
  PRIMARY KEY (id_log),
  KEY ix_audit_entity (entity, entity_id),
  KEY ix_audit_user (id_user),
  CONSTRAINT fk_audit_user FOREIGN KEY (id_user) REFERENCES utilisateur (id_user) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vue : contenu courant d'une archive (dernière révision, sinon texte nettoyé)
CREATE OR REPLACE VIEW v_corpus_courant AS
SELECT c.id_corpus, c.genre, c.access_level, c.validated_at, c.version,
       tn.id_cleaned, tb.id_raw, tb.title, tb.creator, tb.region, tb.language, tb.media_type,
       s.id_source, s.id_org, s.license,
       COALESCE(
         (SELECT cr.content FROM corpus_revision cr
           WHERE cr.id_corpus = c.id_corpus
           ORDER BY cr.created_at DESC, cr.id_revision DESC LIMIT 1),
         tn.content) AS content
FROM corpus c
JOIN texte_nettoye tn ON tn.id_cleaned = c.id_cleaned
JOIN texte_brut tb    ON tb.id_raw = tn.id_raw
JOIN source s         ON s.id_source = tb.id_source;

SET FOREIGN_KEY_CHECKS = 1;

-- Données de référence
INSERT INTO role (code, libelle) VALUES
  ('reader','Lecteur'), ('reviewer','Relecteur'), ('admin','Administrateur')
ON DUPLICATE KEY UPDATE libelle = VALUES(libelle);
