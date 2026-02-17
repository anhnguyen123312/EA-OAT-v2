#!/bin/bash
# Restore MT5 login credentials from backup
# Usage: ./restore_mt5_login.sh

set -e

WINEPREFIX="/Users/duynguyen/Library/Application Support/net.metaquotes.wine.metatrader5"
MT5_CONFIG="$WINEPREFIX/drive_c/Program Files/MetaTrader 5/config"
PROJECT="/Volumes/Data/Git/EA-OAT-v2"
BACKUP="$PROJECT/config/mt5-backup"

echo "=== Restoring MT5 Login Credentials ==="

if [ ! -d "$BACKUP" ]; then
    echo "ERROR: Backup folder not found at $BACKUP"
    exit 1
fi

# Restore files
cp "$BACKUP/common.ini" "$MT5_CONFIG/"
cp "$BACKUP/accounts.dat" "$MT5_CONFIG/"
cp "$BACKUP/servers.dat" "$MT5_CONFIG/"

echo "Restored:"
echo "  - common.ini (login: 128364028, server: Exness-MT5Real7)"
echo "  - accounts.dat (saved account credentials)"
echo "  - servers.dat (server configurations)"
echo ""
echo "Login credentials restored. Open MT5 to verify."
