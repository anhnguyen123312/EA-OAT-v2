#!/bin/bash
# Fully automated MT5 backtest via Wine terminal64.exe
# Usage: ./run_backtest_automated.sh
# This runs headless and auto-closes when done

set -e

# Paths
WINEPREFIX="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5"
MT5_BASE="$WINEPREFIX/drive_c/Program Files/MetaTrader 5"
WINE="/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"
PROJECT_ROOT="/Volumes/Data/Git/EA-OAT-v2"
CONFIG_SRC="$PROJECT_ROOT/config/active/autobacktest.ini"
CONFIG_DEST="$MT5_BASE/config/autobacktest.ini"
CSV_PATH="$WINEPREFIX/drive_c/users/crossover/AppData/Roaming/MetaQuotes/Terminal/Common/Files/backtest_results.csv"

echo "=== Automated MT5 Backtest ==="
echo ""

# Step 1: Copy config
echo "[1/4] Copying config..."
mkdir -p "$MT5_BASE/config"
cp "$CONFIG_SRC" "$CONFIG_DEST"
echo "      Expert: $(grep '^Expert=' "$CONFIG_SRC" | cut -d'=' -f2)"
echo "      Symbol: $(grep '^Symbol=' "$CONFIG_SRC" | cut -d'=' -f2)"
echo "      Period: M$(grep '^Period=' "$CONFIG_SRC" | cut -d'=' -f2)"
echo "      Dates: $(grep '^FromDate=' "$CONFIG_SRC" | cut -d'=' -f2) to $(grep '^ToDate=' "$CONFIG_SRC" | cut -d'=' -f2)"
echo ""

# Step 2: Remove old CSV
echo "[2/4] Cleaning old results..."
if [ -f "$CSV_PATH" ]; then
    OLD_TIMESTAMP=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$CSV_PATH")
    rm -f "$CSV_PATH"
    echo "      Removed old CSV (from $OLD_TIMESTAMP)"
else
    echo "      No old CSV to remove"
fi
echo ""

# Step 3: Run backtest via Wine
echo "[3/4] Running backtest (this takes 15-30 minutes)..."
echo "      Model: Real Ticks (highest accuracy)"
echo "      Auto-shutdown: Enabled"
echo ""

cd "$MT5_BASE"

# Run terminal64.exe with config
# /portable flag uses local config
# ShutdownTerminal=1 in config will auto-close when done
WINEPREFIX="$WINEPREFIX" "$WINE" terminal64.exe /config:"C:\Program Files\MetaTrader 5\config\autobacktest.ini" /portable

echo ""
echo "[4/4] Backtest completed!"
echo ""

# Step 4: Check results
if [ -f "$CSV_PATH" ]; then
    NEW_TIMESTAMP=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$CSV_PATH")
    echo "✅ Results available!"
    echo "   File: $CSV_PATH"
    echo "   Created: $NEW_TIMESTAMP"
    echo "   Size: $(stat -f "%z" "$CSV_PATH") bytes"
    echo ""
    echo "Next step: Collect results"
    echo "   ./scripts/collect_backtest_results.sh AdvancedEA XAUUSD M5"
else
    echo "⚠️  No results CSV found - backtest may have failed"
    echo "   Check MT5 logs: $MT5_BASE/MQL5/Logs/"
    exit 1
fi

echo ""
echo "=== Done ==="
