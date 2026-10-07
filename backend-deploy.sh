#!/bin/bash

set -e
set -o pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

WORKING_DIR="/var/www/grihashakti-backend"
APP_NAME="grihashakti-backend"
APP_DIR="$WORKING_DIR/$APP_NAME"

echo "==========================================================="
echo -e "${YELLOW}Starting Grihashakti Backend Deployment${NC}"
echo "==========================================================="

if [ $# -eq 0 ]; then
    echo -e "${RED}Usage: $0 <zip-file-name>${NC}"
    exit 1
fi

ZIP_FILE="$1"
ZIP_PATH="$WORKING_DIR/$ZIP_FILE"
TIMESTAMP=$(TZ=Asia/Kolkata date +"%d%m%y_%H%M")
BACKUP_DIR="$WORKING_DIR/${APP_NAME}-bkp-$TIMESTAMP"

if [ ! -f "$ZIP_PATH" ]; then
    echo -e "${RED}ERROR: ZIP file not found: $ZIP_PATH${NC}"
    exit 1
fi

RUNTIME_DIR=$(unzip -Z1 "$ZIP_PATH" | awk -F/ 'NF>1 {print $1; exit}')

if [ -z "$RUNTIME_DIR" ]; then
    echo -e "${RED}ERROR: Unable to detect extracted folder from ZIP${NC}"
    exit 1
fi

echo -e "${YELLOW}ZIP File        :${NC} $ZIP_FILE"
echo -e "${YELLOW}Runtime Folder  :${NC} $RUNTIME_DIR"
echo -e "${YELLOW}Backup Folder   :${NC} $BACKUP_DIR"

cd "$WORKING_DIR"

if [ ! -d "$APP_DIR" ]; then
    echo -e "${RED}ERROR: Existing application directory not found: $APP_DIR${NC}"
    exit 1
fi

echo -e "${YELLOW}Taking backup of existing backend...${NC}"
mv "$APP_DIR" "$BACKUP_DIR"

echo -e "${YELLOW}Extracting new backend code...${NC}"
unzip "$ZIP_PATH" -d "$WORKING_DIR"

if [ ! -d "$WORKING_DIR/$RUNTIME_DIR" ]; then
    echo -e "${RED}ERROR: Extracted folder not found: $WORKING_DIR/$RUNTIME_DIR${NC}"
    exit 1
fi

echo -e "${YELLOW}Renaming extracted folder to $APP_NAME...${NC}"
mv "$WORKING_DIR/$RUNTIME_DIR" "$APP_DIR"

if [ ! -f "$BACKUP_DIR/web/sites/default/settings.php" ]; then
    echo -e "${RED}ERROR: settings.php not found in backup${NC}"
    exit 1
fi

echo -e "${YELLOW}Restoring settings.php from backup...${NC}"
cp "$BACKUP_DIR/web/sites/default/settings.php" \
   "$APP_DIR/web/sites/default/settings.php"

echo -e "${YELLOW}Installing composer dependencies...${NC}"
cd "$APP_DIR"
composer install --no-dev --optimize-autoloader

echo -e "${GREEN}Restarting php-fpm...${NC}"
systemctl restart php-fpm

echo -e "${GREEN}Restarting nginx...${NC}"
systemctl restart nginx

echo -e "${GREEN}Removing deployment ZIP...${NC}"
rm -f "$ZIP_PATH"

echo "==========================================================="
echo -e "${GREEN}Backend Deployment Completed Successfully${NC}"
echo "==========================================================="