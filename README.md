# db-backup-by-script
This is a DB backup by script. If DB is deployed as a Docker container.

# MySQL Automated Backup System

## Overview

This project provides an automated MySQL backup solution for applications running inside Docker containers.

Features:

* Automated MySQL database backups using mysqldump
* Gzip compression for reduced storage usage
* Azure Blob Storage upload
* Local backup retention management
* Azure Blob retention management
* Cron-based scheduling
* Backup verification
* Automated cleanup of old backups
* Docker container support

---

## Architecture

```text
MySQL Container
      │
      ▼
mysqldump
      │
      ▼
gzip compression
      │
      ▼
Local Backup Directory
      │
      ▼
Azure Blob Storage
      │
      ▼
Retention Cleanup
```

---

---

## Prerequisites

Ensure the following tools are installed on the server:

* Docker
* MySQL container running
* Azure CLI
* Cron service
* gzip

Verify installations:

```bash
docker --version
az --version
gzip --version
crontab -l
```

---

## Azure CLI Installation

If Azure CLI is not installed, install it using the following commands:

### Ubuntu/Debian

Path of Azure Cli:

```bash
https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest&pivots=apt
```

Direct Install Azure Cli
```bash
curl -fsSL 'https://azurecliprod.blob.core.windows.net/$root/deb_install.sh' | sudo bash
```

Verify installation:

```bash
az --version
```

Expected output:

```text
azure-cli                         x.x.x
```
---

## Folder Structure

```text
dir-db-backup-path/
├── .env
├── backups.sh
├── backup.log
└── *.sql.gz
```

---

## Environment Configuration

Create a `.env` file:

```env
# Database Configuration
DATABASE_HOST_STRING="mysql-db:3306"
DATABASE_NAME="test_db"
DB_USER_NAME="root"
DB_PASSWORD="your-password"

# Docker Container
DB_CONTAINER="mysql-db-container"

# Local Backup
BACKUP_DIR="/home/azureuser/dir-path-db-backup"
BACKUP_RETENTION_COUNT="7"

# Azure Storage
AZURE_STORAGE_ACCOUNT="storage-account-name"
AZURE_STORAGE_KEY="storage-account-key"
AZURE_CONTAINER_NAME="test-db-backup-container"

# Azure Retention
AZURE_RETENTION_COUNT="7"
```

---

## Environment File Security

Restrict access to the `.env` file:

```bash
chmod 600 .env
```

Verify permissions:

```bash
ls -la .env
```

Expected:

```text
-rw------- 1 user user ...
```

---

## Script Permissions

Make the backup script executable:

```bash
chmod +x backups.sh
```

Verify:

```bash
ls -la backups.sh
```

Expected:

```text
-rwxr-xr-x
```

---

## Manual Backup

Run backup manually:

```bash
./backups.sh
```

Expected output:

```text
Starting backup...
Backup created...
Azure upload completed...
Backup completed successfully
```

Verify backup creation:

```bash
ls -lah *.sql.gz
```

---

## Cron Configuration

### Open Crontab

```bash
crontab -e
```

---

### Test Every Minute

Use the following cron entry for testing:

```cron
* * * * * /home/azureuser/resourcing-db-backup/backups.sh >> /home/azureuser/resourcing-db-backup/backup.log 2>&1
```

Verify cron entries:

```bash
crontab -l
```

Monitor logs:

```bash
tail -f /home/azureuser/resourcing-db-backup/backup.log
```

**Important:** Remove this cron entry after testing to avoid generating excessive backups.

---

### Production Schedule

Server timezone:

```text
UTC
```

Required execution time:

```text
10:30 PM IST
```

Equivalent UTC:

```text
05:00 PM UTC
```

Cron:

```cron
0 17 * * * /home/azureuser/dir-path-db-backup/backups.sh >> /home/azureuser/dir-path-db-backup/backup.log 2>&1
```

Verify:

```bash
crontab -l
```

---

## Local Retention

Configured using:

```env
BACKUP_RETENTION_COUNT="7"
```

### Behavior:

* Keep latest 7 backups
* Delete older backups automatically

Example:

```text
backup-1.sql.gz
backup-2.sql.gz
backup-3.sql.gz
backup-4.sql.gz
backup-5.sql.gz
backup-6.sql.gz
backup-7.sql.gz
```

When backup-8 is created:

```text
backup-1.sql.gz
```

is automatically removed.

---

## Azure Blob Retention

Configured using:

```env
AZURE_RETENTION_COUNT="7"
```

### Behavior:

* Upload every backup
* Keep the latest 7 backups
* Delete older blobs automatically

---

## Azure Blob Storage Configuration

Recommended settings:

### Public Access

```text
Disabled
```

### Container Access Level

```text
Private (No Anonymous Access)
```

### Geo Redundancy

```text
LRS (Locally Redundant Storage)
```

For production-critical systems:

```text
GRS (Geo Redundant Storage)
```

---

## Backup Verification

Verify gzip file:

```bash
gzip -t backup.sql.gz
```

If no output is returned:

```text
Backup is valid
```

Check file size:

```bash
ls -lh backup.sql.gz
```

---

## Restore Backup

### Decompress Backup

```bash
gunzip backup.sql.gz
```

Output:

```text
backup.sql
```

---

### Restore Database

```bash
docker exec -i mysql-db-container \
mysql -u root -p test_db < backup.sql
```

---

### Restore Without Decompressing

```bash
gunzip -c backup.sql.gz | docker exec -i mysql-db-container mysql -u root -p test_db
```

---

## Log Monitoring

View logs:

```bash
tail -f backup.log
```

View last 100 lines:

```bash
tail -100 backup.log
```

Clear logs:

```bash
> backup.log
```

---

## Troubleshooting

### Backup Script Not Found

Error:

```text
backup.sh: not found
```

Verify:

```bash
ls -la
```

Check cron path matches the actual file name.

Ensure cron references the correct script path and filename.

Example:

```cron
* * * * * /home/azureuser/dir-path-db-backup/backups.sh
```

---

### Azure Upload Failure

Verify:

```bash
az --version
```

Check:

* Storage account name
* Storage account key
* Container name
* Network connectivity

---

### Docker Container Not Found

Verify:

```bash
docker ps
```

Update:

```env
DB_CONTAINER="correct-container-name"
```

---

### Cron Job Not Running

Check cron service:

```bash
systemctl status cron
```

Restart cron:

```bash
sudo systemctl restart cron
```

Verify cron entries:

```bash
crontab -l
```

Check logs:

```bash
tail -f backup.log
```

---

## Security Recommendations

* Never commit `.env` files
* Never commit Azure Storage Keys
* Restrict `.env` permissions

```bash
chmod 600 .env
```

* Use Private Blob Containers
* Rotate Storage Keys periodically

--- 

### Permission Denied

Verify script permissions:

```bash
chmod +x backups.sh
```

Verify ownership:

```bash
ls -la backups.sh
```

---

## Recommended .gitignore

Create a `.gitignore` file:

```gitignore
.env
backup.log
*.sql
*.sql.gz
```

This prevents accidental exposure of credentials and backup files.

---

## Maintenance Checklist

### Daily

* Verify backup completion

### Weekly

* Verify Azure uploads
* Test restore process

### Monthly

* Restore a backup to a test database
* Validate backup integrity

---

## Author
Aditya Bahuguna | Personal Infrastructure Automation Project

MySQL + Docker + Azure Blob Storage Backup Solution
"""
---
