# Tantara SaaS — Architecture Technique

> Plateforme de numérisation, génération et préservation des récits (*tantara*) et chants traditionnels (*hira gasy*) malgaches.

Ce document est le **plan directeur** du projet. Il décrit l'architecture cible, l'arborescence du monorepo, le modèle de données, les contrats d'API et la feuille de route d'implémentation. Le code de chaque module sera produit **étape par étape**, sur ta validation.

---

## 1. Vision & objectifs

| Objectif | Description |
|---|---|
| **Numériser** | Collecter des *tantara* (récits) et *hira gasy* (chants) depuis des sources publiques (web, YouTube, PDF). |
| **Structurer** | Nettoyer, normaliser et stocker ces corpus dans MySQL (bruts + validés). |
| **Valider** | Offrir aux relecteurs un back-office (RBAC) pour corriger et valider les textes. |
| **Générer** | Fine-tuner un LLM causal multilingue pour produire de nouveaux récits en malgache. |
| **Préserver** | Versionner le corpus validé et exposer une API de génération/inférence. |

---

## 2. Stack technique

| Couche | Technologie | Justification |
|---|---|---|
| Backend / API | **FastAPI** (Python 3.11) | Async, typage Pydantic, OpenAPI auto-généré, idéal pour l'orchestration IA. *(Flask conservé en compat. legacy `app.py`)* |
| Frontend SaaS | **Next.js 14** (App Router, TypeScript) | SSR/RSC, routing i18n, écosystème React. |
| Base de données | **MySQL 8** + **SQLAlchemy 2.0** (async) + Alembic | Relationnel structuré, migrations versionnées. |
| IA / NLP | **HuggingFace Transformers** + **PyTorch** + **PEFT/LoRA** | Fine-tuning causal LM, efficient en VRAM. |
| Scraping | **BeautifulSoup4**, **httpx**, **yt-dlp**, **pandas** | HTML + vidéos + dédoublonnage. |
| DevOps | **Docker**, **docker-compose**, **GitHub Actions**, **GHCR** | Conteneurisation, CI/CD, déploiement. |
| Auth | **JWT** (access/refresh) + **RBAC** | Gestion des rôles relecteur/éditeur/admin. |
| Observabilité | **structlog**, **Prometheus** (optionnel) | Logs JSON, métriques. |

---

## 3. Architecture logique (C4 — niveau conteneur)

```
                          ┌──────────────────────────────┐
                          │        Utilisateurs           │
                          │  Relecteur / Éditeur / Admin  │
                          └───────────────┬──────────────┘
                                          │ HTTPS
                          ┌───────────────▼──────────────┐
                          │   Frontend Next.js (SSR)      │
                          │   - Dashboard validation      │
                          │   - i18n fr/mg                │
                          │   - RBAC UI                   │
                          └───────────────┬──────────────┘
                                          │ REST /api/v1
                          ┌───────────────▼──────────────┐
                          │      API FastAPI              │
                          │  ┌─────────┬─────────┬──────┐ │
                          │  │ Auth    │ Corpus  │ Gen  │ │
                          │  │ RBAC    │ Review  │ AI   │ │
                          │  └─────────┴─────────┴──────┘ │
                          └───┬──────────┬──────────┬─────┘
                              │          │          │
              ┌───────────────▼──┐  ┌────▼─────┐  ┌─▼──────────────┐
              │   MySQL 8        │  │ Scrapers │  │ Inference Svc  │
              │  raw + validated │  │ workers  │  │ (HF model)     │
              │  + users/roles   │  │ (cron)   │  │ GPU/CPU        │
              └──────────────────┘  └──────────┘  └────────────────┘
```

**Flux principaux**
1. **Ingestion** : `scrapers` → `raw_texts` (statut `pending`).
2. **Prétraitement** : pipeline NLP → `cleaned_texts` (statut `ready_for_review`).
3. **Validation** : relecteur (Next.js) → API → `corpus` (statut `validated`).
4. **Entraînement** : dataset exporté depuis `corpus` → fine-tuning → artefacts `models/`.
5. **Génération** : API `/generate` → service d'inférence → texte généré + score qualité.

---

## 4. Arborescence du monorepo (cible)

```
tantara-saas/
├── apps/
│   ├── api/                        # Backend FastAPI
│   │   ├── app/
│   │   │   ├── main.py             # Point d'entrée FastAPI
│   │   │   ├── core/               # Config, sécurité, logging
│   │   │   │   ├── config.py
│   │   │   │   ├── security.py     # JWT, hash, RBAC deps
│   │   │   │   └── logging.py
│   │   │   ├── db/                 # Session, base, init
│   │   │   │   ├── base.py
│   │   │   │   └── session.py
│   │   │   ├── models/             # ORM SQLAlchemy
│   │   │   │   ├── user.py
│   │   │   │   ├── raw_text.py
│   │   │   │   ├── corpus.py
│   │   │   │   └── audit.py
│   │   │   ├── schemas/            # Pydantic (I/O)
│   │   │   ├── api/
│   │   │   │   └── v1/
│   │   │   │       ├── auth.py
│   │   │   │       ├── corpus.py
│   │   │   │       ├── review.py
│   │   │   │       ├── generate.py
│   │   │   │       └── admin.py
│   │   │   ├── services/           # Logique métier
│   │   │   └── workers/            # Tâches scraping/NLP (Celery/RQ)
│   │   ├── alembic/                # Migrations
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   │
│   ├── web/                        # Frontend Next.js
│   │   ├── src/
│   │   │   ├── app/
│   │   │   │   ├── [locale]/       # i18n fr/mg
│   │   │   │   │   ├── dashboard/
│   │   │   │   │   ├── review/
│   │   │   │   │   └── generate/
│   │   │   ├── components/
│   │   │   ├── lib/                # API client, auth
│   │   │   ├── i18n/
│   │   │   └── styles/
│   │   ├── public/
│   │   ├── Dockerfile
│   │   └── package.json
│   │
│   └── ai/                         # Pipelines IA (hors ligne / batch)
│       ├── data/                   # Scripts collecte
│       │   ├── scrape_web.py
│       │   └── scrape_youtube.py
│       ├── preprocessing/
│       │   ├── clean.py
│       │   ├── dedupe.py
│       │   └── tokenize_mg.py
│       ├── training/
│       │   ├── build_dataset.py
│       │   ├── finetune.py
│       │   ├── lora_config.yaml
│       │   └── evaluate.py
│       ├── inference/
│       │   └── generate.py
│       └── requirements.txt
│
├── infra/
│   ├── mysql/
│   │   └── init/01_schema.sql      # DDL + seed rôles
│   ├── nginx/
│   │   └── nginx.conf              # Reverse proxy
│   └── monitoring/                 # (optionnel) prometheus
│
├── .github/workflows/
│   ├── ci.yml                      # Lint + tests
│   ├── docker.yml                  # Build & push images
│   └── deploy.yml                  # Déploiement continu
│
├── docker-compose.yml
├── docker-compose.prod.yml
├── .env.example
├── Makefile
└── README.md
```

> **Note de migration** : l'actuel `app.py` Flask devient un *health endpoint* legacy ou sera remplacé par `apps/api`. Aucun code existant n'est cassé pendant la transition.

---

## 5. Modèle de données (MySQL)

### 5.1 Diagramme entité-relation

```
users 1───N reviews N───1 corpus
users 1───N audit_logs
sources 1───N raw_texts
raw_texts 1───1 cleaned_texts 1───1 corpus
corpus 1───N dataset_versions
dataset_versions 1───N training_runs
training_runs 1───N model_artifacts
```

### 5.2 Tables principales

| Table | Rôle | Champs clés |
|---|---|---|
| `users` | Comptes & rôles | `id`, `email`, `password_hash`, `role` (`reader`\|`reviewer`\|`admin`), `locale`, `is_active` |
| `sources` | Provenance | `id`, `name`, `url`, `type` (`web`\|`youtube`\|`pdf`), `license` |
| `raw_texts` | Corpus brut | `id`, `source_id`, `title`, `content` (LONGTEXT), `language`, `collected_at`, `status` |
| `cleaned_texts` | Après NLP | `id`, `raw_text_id`, `content`, `word_count`, `quality_score`, `dedupe_hash` |
| `corpus` | Validé | `id`, `cleaned_text_id`, `genre` (`tantara`\|`hira_gasy`), `validated_by`, `validated_at`, `version` |
| `reviews` | Historique validation | `id`, `corpus_id`, `reviewer_id`, `action`, `comment`, `created_at` |
| `dataset_versions` | Snapshots dataset | `id`, `name`, `num_samples`, `created_at`, `path` |
| `training_runs` | Runs d'entraînement | `id`, `dataset_version_id`, `base_model`, `hyperparams` (JSON), `metrics` (JSON) |
| `model_artifacts` | Modèles produits | `id`, `training_run_id`, `path`, `eval_score`, `is_production` |
| `audit_logs` | Traçabilité | `id`, `user_id`, `action`, `entity`, `entity_id`, `meta` (JSON), `created_at` |

### 5.3 Cycle de vie d'un texte

```
raw (pending) → cleaned (ready_for_review) → validated (in_corpus)
      │                    │                         │
      └──── rejected ◄─────┴──── rejected ◄──────────┘
```

---

## 6. Contrats d'API (REST `/api/v1`)

| Méthode | Endpoint | Rôle requis | Description |
|---|---|---|---|
| `POST` | `/auth/login` | public | JWT access + refresh |
| `POST` | `/auth/refresh` | public | Renouvelle l'access token |
| `GET` | `/corpus` | reader+ | Liste paginée + filtres (`genre`, `status`, `q`) |
| `GET` | `/corpus/{id}` | reader+ | Détail d'un texte |
| `POST` | `/corpus/{id}/review` | reviewer+ | Valider / rejeter / commenter |
| `PATCH` | `/corpus/{id}` | reviewer+ | Éditer le contenu (crée une révision) |
| `POST` | `/scraping/jobs` | admin | Lancer une collecte |
| `GET` | `/scraping/jobs/{id}` | admin | Statut d'un job |
| `POST` | `/generate` | reader+ | Génère un récit (`prompt`, `genre`, `max_tokens`) |
| `GET` | `/generate/history` | reader+ | Historique des générations |
| `GET` | `/admin/stats` | admin | Métriques (corpus, modèles, relecteurs) |
| `GET` | `/health` | public | Liveness/readiness |

**Exemple de réponse `/corpus`**
```json
{
  "items": [
    {
      "id": 42,
      "title": "Ny tantaran'Andrianampoinimerina",
      "genre": "tantara",
      "language": "mg",
      "status": "ready_for_review",
      "source": {"name": "Wikipedia MG", "url": "https://mg.wikipedia.org/..."},
      "word_count": 812,
      "quality_score": 0.87
    }
  ],
  "total": 134,
  "page": 1,
  "size": 20
}
```

---

## 7. Sécurité & RBAC

| Rôle | Droits |
|---|---|
| `reader` | Lire corpus validé, générer des récits |
| `reviewer` | + Éditer / valider / rejeter les textes |
| `admin` | + Gérer utilisateurs, lancer scraping, déployer modèles |

- Mots de passe : **bcrypt** / **argon2**.
- JWT : access 15 min, refresh 7 j, rotation.
- Rate limiting sur `/generate` et `/auth`.
- Validation Pydantic stricte + protection injection SQL via ORM paramétré.
- CORS restreint au domaine frontend.
- Secrets via variables d'environnement (jamais commités).

---

## 8. Pipeline IA (vue d'ensemble)

```
MySQL (corpus validé)
      │  build_dataset.py
      ▼
JSONL {prompt, completion}  ──►  finetune.py (HF Trainer + LoRA/PEFT)
      │                                   │
      │                                   ▼
      │                          model_artifacts/ (adapters + tokenizer)
      │                                   │
      ▼                                   ▼
evaluate.py (perplexité, BLEU/ROUGE, score heuristique mg)
                                          │
                                          ▼
                              inference/generate.py  ──►  API /generate
```

**Modèle de base candidat** : un modèle multilingue (ex. `bigscience/mt0` pour seq2seq, ou `TinyLlama`/`Llama-3-8B` en causal) — le choix final sera arrêté en Phase 4 selon les ressources GPU.

**Spécificités malgache** : tokenizer à auditer (couverture du vocabulaire mg), normalisation des diacritiques (`ô`, `à`, `é`), segmentation par phrases (`.`/`?`/`!`), gestion des variantes dialectales.

---

## 9. DevOps & CI/CD

| Workflow | Déclencheur | Étapes |
|---|---|---|
| `ci.yml` | PR / push | Lint (ruff, black, eslint), tests (pytest, vitest), couverture |
| `docker.yml` | push main | Build images `api` + `web`, push GHCR (tags `sha` + `latest`) |
| `deploy.yml` | tag `v*` / main | Pull image, migrations Alembic, rolling deploy, health check |

- `docker-compose.yml` : `mysql`, `api`, `web`, `nginx`, `redis` (jobs), volume modèle.
- `.env.example` documente toutes les variables.
- Images multi-stage, utilisateur non-root, `.dockerignore`.

---

## 10. Feuille de route d'implémentation

| Phase | Livrable | Statut |
|---|---|---|
| **0** | Ce document + arborescence + squelettes | ✅ en cours |
| **1** | Scrapers (BeautifulSoup/yt-dlp), `01_schema.sql`, modèles SQLAlchemy | ⏳ à valider |
| **2** | Nettoyage, dédoublonnage, tokenisation/segmentation mg | ⏳ |
| **3** | API FastAPI (corpus/review/auth) + dashboard Next.js RBAC + i18n | ⏳ |
| **4** | `build_dataset.py`, `finetune.py` (LoRA), `generate.py` | ⏳ |
| **5** | `lora_config.yaml`, `evaluate.py`, tuning hyperparamètres | ⏳ |
| **6** | Dockerfiles, `docker-compose.yml`, workflows GitHub Actions | ⏳ |

---

## 11. Décisions d'architecture (ADR courtes)

1. **FastAPI plutôt que Flask** : async natif (appels modèle IA longs), validation Pydantic, docs OpenAPI automatiques. Le `app.py` Flask existant reste en compatibilité.
2. **MySQL plutôt que PostgreSQL** : imposé par les specs du projet ENI.
3. **Monorepo** : cohérence des versions, CI/CD unifié, partage de schémas/types.
4. **LoRA/PEFT** : permet de fine-tuner un LLM volumineux sur GPU modeste.
5. **Séparation `apps/ai`** : les pipelines lourds (entraînement) ne tournent pas dans le conteneur API.

---

## 12. Prochaine étape

Dis-moi **« go phase 1 »** (ou précise l'ordre que tu préfères) et je génère :
- les scripts `scrape_web.py` et `scrape_youtube.py`,
- le DDL `infra/mysql/init/01_schema.sql`,
- les modèles SQLAlchemy (`apps/api/app/models/*`) + le module de connexion.

Tu peux aussi ajuster l'architecture (ex. préférer Flask, PostgreSQL, ou un modèle de base précis) avant qu'on code.
