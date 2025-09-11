#!/bin/bash

# Download latest backup
R2_BUCKET="${R2_BUCKET:-your-bucket-name}"
R2_ENDPOINT="${R2_ENDPOINT:-https://<account_id>.r2.cloudflarestorage.com}"
AWS_PROFILE="${AWS_PROFILE:-r2}"

# Get latest backup filename
LATEST_FILE=$(aws --profile "$AWS_PROFILE" --endpoint-url "$R2_ENDPOINT" s3 ls s3://"$R2_BUCKET"/ --recursive | sort | tail -n 1 | awk '{print $4}')

if [ -z "$LATEST_FILE" ]; then
  echo "No backups found!"
  exit 1
fi

echo "Downloading latest backup: $LATEST_FILE"

aws --profile "$AWS_PROFILE" --endpoint-url "$R2_ENDPOINT" s3 cp s3://"$R2_BUCKET/$LATEST_FILE" ./latest_backup.tar.gz

# Restore the database
mongorestore --archive=./latest_backup.tar.gz --gzip

echo "Restore complete."