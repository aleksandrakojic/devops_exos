#!/bin/bash

# Configuration
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-27017}"
DB_NAME="${DB_NAME:-your_db_name}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
DATE_STR=$(date +"%Y-%m-%d-%H-%M")
BACKUP_FILE="mongodump-$DATE_STR.tar.gz"
R2_BUCKET="${R2_BUCKET:-your-bucket-name}"
R2_ENDPOINT="${R2_ENDPOINT:-https://<account_id>.r2.cloudflarestorage.com}"
AWS_PROFILE="${AWS_PROFILE:-r2}"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

echo "Starting backup for database: $DB_NAME"

# Dump the database
mongodump --host "$DB_HOST" --port "$DB_PORT" --db "$DB_NAME" --archive="$BACKUP_DIR/$BACKUP_FILE" --gzip

if [ $? -ne 0 ]; then
  echo "mongodump failed!"
  exit 1
fi

# Upload to Cloudflare R2
echo "Uploading backup to R2 bucket: $R2_BUCKET"

aws --profile "$AWS_PROFILE" --endpoint-url "$R2_ENDPOINT" s3 cp "$BACKUP_DIR/$BACKUP_FILE" s3://"$R2_BUCKET"/

if [ $? -eq 0 ]; then
  echo "Upload successful!"
else
  echo "Upload failed!"
  exit 1
fi

# Optional: delete backups older than 7 days
find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +7 -delete