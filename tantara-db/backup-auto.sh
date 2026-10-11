#!/bin/bash
DIR="$(cd "$(dirname "$O")" && pwd)"
docker exec mysql sh -c 'exec mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' > "$DIR/backup_$(date +%F_%H-%M).sql"
echo "[$(date)] backup ok" >> "$DIR/backup.log"


