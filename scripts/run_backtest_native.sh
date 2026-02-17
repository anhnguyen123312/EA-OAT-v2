#!/bin/bash
# Run backtest via native MT5 macOS app (preserves login session)
# Usage: ./run_backtest_native.sh

set -e

# Config paths
WINEPREFIX="/Users/duynguyen/Library/Application Support/net.metaquotes.wine.metatrader5"
MT5_BASE="$WINEPREFIX/drive_c/Program Files/MetaTrader 5"
PROJECT_ROOT="/Volumes/Data/Git/EA-OAT-v2"
CONFIG_SRC="$PROJECT_ROOT/config/active/autobacktest.ini"
CONFIG_DEST="$MT5_BASE/autobacktest.ini"
CSV_PATH="$WINEPREFIX/drive_c/users/crossover/AppData/Roaming/MetaQuotes/Terminal/Common/Files/backtest_results.csv"

echo "=== MT5 Native Backtest Launcher ==="
echo ""

# Step 1: Copy config to MT5 folder
echo "[1/3] Copying backtest config..."
cp "$CONFIG_SRC" "$CONFIG_DEST"
echo "      Config: $(cat "$CONFIG_SRC" | grep -E '^(Expert|Symbol|Period|FromDate|ToDate|Deposit)=' | tr '\n' ' ')"
echo ""

# Step 2: Launch MT5 native app (preserves login session)
echo "[2/3] Launching MT5 native app..."
echo "      NOTE: MT5 will open but backtest may need manual start via Strategy Tester (Ctrl+R)"
echo ""

# Check if MT5 is already running
if pgrep -q -f "MetaTrader 5"; then
    echo "      MT5 is already running. Please run backtest manually from Strategy Tester."
else
    # Launch with config (ShutdownTerminal=0 keeps app open)
    open -a "MetaTrader 5" --args "/config:C:\Program Files\MetaTrader 5\autobacktest.ini"
    echo "      MT5 launched. Wait for connection, then start backtest from Strategy Tester."
fi

echo ""
echo "[3/3] After backtest completes, run this to get results:"
echo "      cat \"$CSV_PATH\" | iconv -f UTF-16LE -t UTF-8 | tr -d '\r'"
echo ""
echo "=== Waiting for backtest to complete ==="
echo "Press Ctrl+C to exit (MT5 will remain open)"
