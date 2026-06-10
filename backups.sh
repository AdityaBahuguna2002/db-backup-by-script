#!/bin/bash

set -euo pipefail

# Load env
source /home/azureuser/dir-path-db-backup/.env

# Validate variables
required_vars=(
  DB_CONTAINER
  DATABASE_NAME
  DB_USER_NAME
  DB_PASSWORD
  BACKUP_DIR
  BACKUP_RETENTION_COUNT
  AZURE_STORAGE_ACCOUNT
  AZURE_STORAGE_KEY
  AZURE_CONTAINER_NAME
  AZURE_RETENTION_COUNT
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: $var is not set"
    exit 1
  fi
done

mkdir -p "$BACKUP_DIR"

DATE=$(date +%F-%H-%M-%S)

FILE_NAME="${DATABASE_NAME}-${DATE}.sql.gz"

FULL_PATH="$BACKUP_DIR/$FILE_NAME"

echo "[$(date)] Starting backup..."

# Create backup
docker exec "$DB_CONTAINER" \
  mysqldump \
  -u"$DB_USER_NAME" \
  -p"$DB_PASSWORD" \
  --single-transaction \
  --quick \
  --no-tablespaces \
  "$DATABASE_NAME" \
| gzip > "$FULL_PATH"

# Verify backup
gzip -t "$FULL_PATH"

echo "[$(date)] Backup created: $FILE_NAME"

# Upload to Azure
echo "[$(date)] Uploading backup to Azure Blob Storage..."

az storage blob upload \
  --account-name "$AZURE_STORAGE_ACCOUNT" \
  --account-key "$AZURE_STORAGE_KEY" \
  --container-name "$AZURE_CONTAINER_NAME" \
  --name "$FILE_NAME" \
  --file "$FULL_PATH" \
  --overwrite true

echo "[$(date)] Azure upload completed"

##################################################
# LOCAL RETENTION
##################################################

echo "[$(date)] Cleaning local backups..."

ls -tp "$BACKUP_DIR"/*.sql.gz 2>/dev/null \
| tail -n +$((BACKUP_RETENTION_COUNT + 1)) \
| xargs -r rm --

echo "[$(date)] Local cleanup completed"

##################################################
# AZURE RETENTION
##################################################

echo "[$(date)] Cleaning Azure backups..."

BLOBS=$(az storage blob list \
  --account-name "$AZURE_STORAGE_ACCOUNT" \
  --account-key "$AZURE_STORAGE_KEY" \
  --container-name "$AZURE_CONTAINER_NAME" \
  --query "sort_by([], &properties.lastModified)[].name" \
  -o tsv)

TOTAL_BLOBS=$(echo "$BLOBS" | grep -c . || true)

if [ "$TOTAL_BLOBS" -gt "$AZURE_RETENTION_COUNT" ]; then

  DELETE_COUNT=$((TOTAL_BLOBS - AZURE_RETENTION_COUNT))

  echo "$BLOBS" \
  | head -n "$DELETE_COUNT" \
  | while read -r blob; do

      echo "Deleting Azure blob: $blob"

      az storage blob delete \
        --account-name "$AZURE_STORAGE_ACCOUNT" \
        --account-key "$AZURE_STORAGE_KEY" \
        --container-name "$AZURE_CONTAINER_NAME" \
        --name "$blob" \
        --only-show-errors

    done
fi

echo "[$(date)] Azure cleanup completed"

echo "[$(date)] Backup completed successfully"
