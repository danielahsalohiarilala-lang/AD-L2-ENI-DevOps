#!/bin/bash
DIR="$(cd "$(dirname "$O")" && pwd)"
FILE="$DIR/backup_$(date +%F_%H-%M).sql"

if docker exec mysql sh -c 'exec mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' > "$FILE"; then
  echo "[$(date)] backup ok: $FILE" >> "$DIR/backup.log"
else
  echo "[$(date)] backup ECHEC" >> "$DIR/backup.log"
  rm -f "$FILE"
  exit 1
fi

find "$DIR" -name 'backup_*.sql' -mtime +7 -delete




