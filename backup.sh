#!/bin/bash
# Database backup script for Upskillo

# Configuration
DB_HOST="upskillo-mysql.cukwnuzu8fg8.ap-south-1.rds.amazonaws.com"
DB_USER="upskilloadmin"
DB_PASS="Upskillo123"
DB_NAME="upskillo"
S3_BUCKET="s3://upskillo-data/upskillo-backup"
BACKUP_FILE="mysql_backup_$(date +%Y-%m-%d_%H-%M).sql.gz"

# Create backup
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME 2>/dev/null | gzip > /tmp/$BACKUP_FILE

# Upload to S3
aws s3 cp /tmp/$BACKUP_FILE $S3_BUCKET/$BACKUP_FILE --region ap-south-1

# Cleanup local file
rm /tmp/$BACKUP_FILE

echo "$(date): Backup completed: $BACKUP_FILE"
