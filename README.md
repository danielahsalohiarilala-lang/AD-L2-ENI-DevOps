# AD-L2-ENI-DevOps - Tantara - Partie 2
## 1. Tantara-DB - 100% Valide
- Securite: 127.0.0.1:3306 + secrets dans .env
- Supervision: healthcheck mysqladmin ping + restart: unless-stopped (healthy)
- Backup: backup_2026-10-11.sql 1,3k valide
- Commandes:
  Backup: docker exec mysql sh  -c 'exec mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' > backup_$(date +%F).sql
  Restore: docker exec -i mysql sh -c 'exec mysql -u root -p"$MYSQL_ROOT_PASSWORD""$MYSQL_DATABASE"' < backup_*.sql

## 2. App Python
- Dockerfile: python:3.11-slim + gunicorn 0.0.0.0:5000
- docker ps: mysql Up (healthy)
## 3. CI/CD Github Actions
- ci.yml: Lint flake8 + Python 3.11
- docker.yml; Build & Push vers ghcr.io/danielahsalohiarilala-lang/ad-l2-eni-devops:latest
- Packages: 
1 package publié sur GitHub

## Lancement 
cd tantara-db && docker compose up -d
docker ps

## Test de restauration (12/10/2026)
- Table test créée, sauvegardée, supprimée, puis restaurée depuis le dump : OK
- Sauvegarde auto : cron 2h, rotation 7 jours, journal dans backup.log

