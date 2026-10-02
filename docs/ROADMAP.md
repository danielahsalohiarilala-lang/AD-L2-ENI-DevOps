# Tantara SaaS — Feuille de route

> Plan d'exécution du projet **Tantara SaaS** : numérisation, génération et préservation des récits (*tantara*) et chants traditionnels (*hira gasy*) malgaches.

Voir [`ARCHITECTURE.md`](./ARCHITECTURE.md) pour la conception technique détaillée.

---

## Vue d'ensemble

| # | Phase | Objectif | Livrables principaux | Durée estimée |
|---|-------|----------|----------------------|---------------|
| 0 | Architecture | Cadrer la conception | `ARCHITECTURE.md`, monorepo, conventions | ✅ fait |
| 1 | Collecte & scraping | Alimenter le corpus brut | Scrapers, DDL MySQL, modèles SQLAlchemy | 1 semaine |
| 2 | Prétraitement & NLP | Nettoyer et normaliser | Nettoyage, dédoublonnage, tokenisation mg | 1 semaine |
| 3 | Validation humaine | Corriger/valider les textes | API FastAPI, dashboard Next.js, RBAC, i18n | 2 semaines |
| 4 | Fine-tuning IA | Entraîner le modèle génératif | Dataset, `finetune.py` (LoRA), inférence | 2 semaines |
| 5 | Réaffinage & optimisation | Améliorer la qualité | Hyperparamètres, `evaluate.py` | 1 semaine |
| 6 | CI/CD & déploiement | Industrialiser | Dockerfiles, compose, GitHub Actions | 1 semaine |

---

## Phase 1 — Collecte et scraping

**Objectif** : constituer un corpus brut de *tantara* et *hira gasy* depuis des sources publiques.

**Livrables**
- [ ] `apps/ai/data/scrape_web.py` — extraction HTML via `BeautifulSoup` + `httpx`
- [ ] `apps/ai/data/scrape_youtube.py` — sous-titres/métadonnées via `yt-dlp`
- [ ] `infra/mysql/init/01_schema.sql` — DDL complet + seed rôles
- [ ] `apps/api/app/db/` + `apps/api/app/models/*` — connexion SQLAlchemy 2.0 async
- [ ] `apps/ai/data/sources.yaml` — registre des sources (URL, type, licence)

**Critères d'acceptation**
- Un job de scraping insère des lignes dans `raw_texts` avec statut `pending`.
- Les métadonnées (`title`, `source`, `url`, `collected_at`) sont renseignées.
- Aucune donnée insérée sans licence traçable dans `sources`.

**Dépendances** : Phase 0.

---

## Phase 2 — Prétraitement et NLP

**Objectif** : transformer le corpus brut en textes propres et exploitables.

**Livrables**
- [ ] `apps/ai/preprocessing/clean.py` — suppression caractères spéciaux, espaces, HTML résiduel
- [ ] `apps/ai/preprocessing/dedupe.py` — dédoublonnage (hash + similarité)
- [ ] `apps/ai/preprocessing/tokenize_mg.py` — tokenisation/segmentation adaptée au malgache
- [ ] Correction orthographique de base (dictionnaire + règles)
- [ ] Écriture dans `cleaned_texts` avec `word_count` et `quality_score`

**Critères d'acceptation**
- Pipeline idempotent : relancer ne crée pas de doublons.
- Normalisation des diacritiques (`ô`, `à`, `é`) documentée et testée.
- Segmentation par phrases (`.`, `?`, `!`) fonctionnelle sur un échantillon annoté.

**Dépendances** : Phase 1.

---

## Phase 3 — Interface de validation humaine

**Objectif** : permettre à des relecteurs de corriger et valider le corpus.

**Livrables**
- [ ] API FastAPI : `/auth/*`, `/corpus`, `/corpus/{id}/review`, `/admin/stats`
- [ ] RBAC : rôles `reader` / `reviewer` / `admin`
- [ ] Dashboard Next.js : liste, détail, édition, validation/rejet
- [ ] i18n `fr` / `mg` (App Router `[locale]`)
- [ ] Journal d'audit (`audit_logs`, `reviews`)

**Critères d'acceptation**
- Un `reviewer` peut valider un texte → passage dans `corpus` avec `validated_by`.
- Un `reader` ne peut pas éditer (403).
- L'interface bascule fr/mg sans rechargement complet.

**Dépendances** : Phases 1–2.

---

## Phase 4 — Apprentissage et fine-tuning du modèle IA

**Objectif** : entraîner un modèle causal multilingue sur le corpus validé.

**Livrables**
- [ ] `apps/ai/training/build_dataset.py` — export MySQL → JSONL `{prompt, completion}`
- [ ] `apps/ai/training/finetune.py` — HF `Trainer` + LoRA/PEFT
- [ ] `apps/ai/training/lora_config.yaml` — configuration LoRA
- [ ] `apps/ai/inference/generate.py` — génération de récits malgaches
- [ ] Enregistrement des runs dans `training_runs` / `model_artifacts`

**Critères d'acceptation**
- Le dataset est versionné (`dataset_versions`) et reproductible.
- Un run de fine-tuning produit un artefact chargeable en inférence.
- L'inférence génère un récit en malgache à partir d'un prompt.

**Dépendances** : Phases 2–3 (corpus validé).

---

## Phase 5 — Réaffinage et optimisation

**Objectif** : améliorer la qualité et l'efficacité du modèle.

**Livrables**
- [ ] `apps/ai/training/evaluate.py` — perplexité, ROUGE/BLEU, score heuristique mg
- [ ] Grille d'hyperparamètres (learning rate, batch size, epochs, LoRA rank/alpha)
- [ ] Rapport comparatif des runs (`metrics` JSON)
- [ ] Sélection du modèle de production (`is_production`)

**Critères d'acceptation**
- Chaque run est comparé sur les mêmes métriques.
- Le meilleur modèle est promu en production via un flag.

**Dépendances** : Phase 4.

---

## Phase 6 — CI/CD et déploiement

**Objectif** : automatiser tests, build et déploiement.

**Livrables**
- [ ] `apps/api/Dockerfile` + `apps/web/Dockerfile` (multi-stage, non-root)
- [ ] `docker-compose.yml` (mysql, api, web, nginx, redis) + `docker-compose.prod.yml`
- [ ] `.github/workflows/ci.yml` — lint (ruff/black/eslint) + tests (pytest/vitest)
- [ ] `.github/workflows/docker.yml` — build & push GHCR
- [ ] `.github/workflows/deploy.yml` — migrations Alembic + rolling deploy + health check
- [ ] `.env.example` documenté

**Critères d'acceptation**
- Une PR déclenche lint + tests et bloque si échec.
- Un push sur `main` publie les images taguées (`sha` + `latest`).
- Un tag `v*` déploie avec health check.

**Dépendances** : Phases 1–5.

---

## Jalons (milestones)

| Jalon | Description | Phases couvertes |
|-------|-------------|------------------|
| **M1 — Corpus brut** | Scraping opérationnel, données en base | 1 |
| **M2 — Corpus propre** | Pipeline NLP validé sur échantillon | 2 |
| **M3 — Back-office** | Relecteurs actifs, corpus validé | 3 |
| **M4 — Modèle v1** | Fine-tuning + inférence fonctionnels | 4 |
| **M5 — Qualité** | Modèle optimisé et évalué | 5 |
| **M6 — Production** | Déploiement automatisé | 6 |

---

## Risques et mitigations

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Faible couverture du malgache par le tokenizer | Qualité IA | Audit du tokenizer, vocabulaire additionnel, normalisation |
| Sources publiques sans licence claire | Juridique | Registre `sources.license`, exclusion par défaut |
| Ressources GPU limitées | Entraînement | LoRA/PEFT, petits modèles, quantization |
| Qualité de validation humaine variable | Fiabilité corpus | Double relecture, score de consensus, journal d'audit |
| Données dialectales hétérogènes | Cohérence | Champs de variante dialectale, segmentation par source |

---

## Conventions de développement

- **Branches** : `main` (stable), `dev` (intégration), `feature/*`, `docs/*`, `fix/*`.
- **Commits** : conventionnels (`feat:`, `fix:`, `docs:`, `chore:`, `test:`).
- **Qualité** : lint + tests obligatoires avant merge (CI).
- **Secrets** : jamais commités — variables d'environnement / secrets CI.
- **PR** : une PR par sujet, description liée à la phase concernée.

---

## Prochaine étape

Démarrer la **Phase 1** : scrapers (`scrape_web.py`, `scrape_youtube.py`), DDL MySQL (`01_schema.sql`) et modèles SQLAlchemy + module de connexion.
