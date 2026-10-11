-Port: 127.0.0.1:3306
-Secrets dans .env
-Backup: backup_2026-10-11.sql 1,3k

-healthcheck mysqladmin ping
-restart: unless-stopped
-docker ps = (healthy)


