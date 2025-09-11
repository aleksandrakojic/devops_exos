Setting up automated backups to Cloudflare R2 involves scheduling a task (via cron or GitHub Actions), dumping your database, and uploading the dump to R2 using the AWS CLI compatible interface. Here's a step-by-step guide with code snippets and configurations to help you implement this.

---

# **Overview of the Solution**

- **Backup Script:** Use `mongodump` to dump the database into a tarball.
- **Upload:** Use `aws s3` CLI (configured for Cloudflare R2) to upload the backup.
- **Schedule:** Automate the process with a cron job on your server or a GitHub Actions scheduled workflow.
- **Optional (Stretch):** Download the latest backup and restore to the database.

---

# **Part 1: Prerequisites**

### **1.1. Cloudflare R2 Setup**

- Create an R2 bucket via the Cloudflare dashboard.
- Generate Access Key and Secret Key.
- Note your R2 endpoint URL (e.g., `https://<account_id>.r2.cloudflarestorage.com`).

### **1.2. Install AWS CLI**

On your server or CI runner:

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### **1.3. Configure AWS CLI for R2**

Create a profile or configure directly:

```bash
aws configure --profile r2
# Use your R2 keys and set the default region (e.g., 'auto' or leave blank)
# When configuring, you'll set:
# AWS Access Key ID: your R2 access key
# AWS Secret Access Key: your R2 secret key
# Default region: (leave blank or set to 'auto')
# Output format: json
```

Set the R2 endpoint:

```bash
aws --profile r2 configure set r2.endpoint_url https://<account_id>.r2.cloudflarestorage.com
```

Alternatively, include `--endpoint-url` in commands.

---

# **Part 2: Backup Script**

Create a script (`backup.sh`) to dump the MongoDB database and upload to R2.

```bash
#!/bin/bash

# Configurable variables
DB_HOST="localhost"  # or your server address
DB_PORT="27017"
DB_NAME="your_db_name"
BACKUP_DIR="/path/to/backups"
DATE_STR=$(date +"%Y-%m-%d-%H-%M")
BACKUP_FILE="mongodump-$DATE_STR.tar.gz"
R2_BUCKET="your-bucket-name"
AWS_PROFILE="r2"
R2_ENDPOINT="https://<account_id>.r2.cloudflarestorage.com"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Dump the database
mongodump --host "$DB_HOST" --port "$DB_PORT" --db "$DB_NAME" --archive="$BACKUP_DIR/$BACKUP_FILE" --gzip

# Upload to Cloudflare R2
aws --profile "$AWS_PROFILE" --endpoint-url "$R2_ENDPOINT" s3 cp "$BACKUP_DIR/$BACKUP_FILE" s3://"$R2_BUCKET"/ --storage-class STANDARD

# Optional: delete backups older than 7 days
find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +7 -delete
```

Make the script executable:

```bash
chmod +x backup.sh
```

---

# **Part 3: Scheduling the Backup**

### **Option A: Cron Job (Server-based)**

Edit crontab:

```bash
crontab -e
```

Add an entry to run every 12 hours:

```bash
0 */12 * * * /path/to/backup.sh
```

### **Option B: GitHub Actions Workflow**

Create a scheduled workflow `.github/workflows/backup.yml`:

```yaml
name: MongoDB Backup to R2

on:
  schedule:
    - cron: '0 */12 * * *'  # every 12 hours

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Install AWS CLI
        run: |
          curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
          unzip awscliv2.zip
          sudo ./aws/install

      - name: Download mongodump
        run: |
          sudo apt-get install -y mongodb-clients
          # Add commands to dump your database or connect to remote MongoDB
          # For example, use mongodump with credentials if needed

      - name: Configure AWS CLI for R2
        run: |
          aws configure set aws_access_key_id ${{ secrets.R2_ACCESS_KEY }}
          aws configure set aws_secret_access_key ${{ secrets.R2_SECRET_KEY }}
          aws configure set region auto
          aws configure set r2.endpoint_url https://<account_id>.r2.cloudflarestorage.com

      - name: Run backup script
        run: |
          # Save your backup script inline or as a file
          # Example:
          mongodump --host your_mongo_host --port 27017 --db your_db --archive=backup.gz --gzip
          aws --endpoint-url https://<account_id>.r2.cloudflarestorage.com s3 cp backup.gz s3://your-bucket/
```

*Note:* For GitHub Actions, you'll need to set secrets `R2_ACCESS_KEY` and `R2_SECRET_KEY`.

---

# **Part 4: Optional - Restoring the Database**

Download the latest backup from R2 and restore:

```bash
aws --profile r2 --endpoint-url "$R2_ENDPOINT" s3 cp s3://your-bucket/backup-file.tar.gz ./latest_backup.tar.gz

mongorestore --archive=latest_backup.tar.gz --gzip
```

---

# **Summary**

- Use `mongodump` to create backups
- Upload backups to Cloudflare R2 via `aws s3 cp`
- Automate with cron or GitHub Actions scheduled workflows
- (Stretch) Download and restore backups

---

Would you like me to prepare a **full example repository** including scripts, workflows, and instructions?
