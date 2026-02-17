#!/bin/bash
# Collect backtest results (CSV + logs) after backtest completes
# Usage: ./collect_backtest_results.sh EAName Symbol Period
# Example: ./collect_backtest_results.sh SimpleEA XAUUSD M5

set -e

# Validate inputs
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "ERROR: Missing arguments"
    echo "Usage: ./collect_backtest_results.sh EAName Symbol Period"
    echo "Example: ./collect_backtest_results.sh SimpleEA XAUUSD M5"
    exit 1
fi

EA_NAME="$1"
SYMBOL="$2"
PERIOD="$3"

PROJECT_ROOT="/Volumes/Data/Git/EA-OAT-v2"
WINEPREFIX="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5"
MT5_BASE="$WINEPREFIX/drive_c/Program Files/MetaTrader 5"

# Source paths
CSV_PATH="$WINEPREFIX/drive_c/users/crossover/AppData/Roaming/MetaQuotes/Terminal/Common/Files/backtest_results.csv"
LOG_DATE=$(date +%Y%m%d)
LOG_PATH="$MT5_BASE/Tester/logs/${LOG_DATE}.log"

# Destination paths
DATE=$(date +%Y-%m-%d)
CSV_DEST="$PROJECT_ROOT/results/${DATE}_${EA_NAME}_${SYMBOL}_${PERIOD}.csv"
LOG_DEST="$PROJECT_ROOT/results/logs/${DATE}_${EA_NAME}.log"

echo "=== MT5 Backtest Results Collector ==="
echo "EA: $EA_NAME"
echo "Symbol: $SYMBOL"
echo "Period: $PERIOD"
echo "Date: $DATE"
echo ""

# Step 1: Check CSV exists
if [ ! -f "$CSV_PATH" ]; then
    echo "ERROR: CSV not found at: $CSV_PATH"
    echo ""
    echo "Possible causes:"
    echo "1. Backtest didn't complete"
    echo "2. OnTester() didn't export CSV"
    echo "3. Wrong Wine username (check actual path)"
    echo ""
    echo "Try: ls -la \"$WINEPREFIX/drive_c/users/*/AppData/Roaming/MetaQuotes/Terminal/Common/Files/\""
    exit 1
fi
echo "[1/4] ✓ CSV found"

# Step 2: Copy CSV to results/
cp "$CSV_PATH" "$CSV_DEST"
echo "[2/4] ✓ CSV copied to: $CSV_DEST"

# Step 3: Copy log (optional, may not exist)
if [ -f "$LOG_PATH" ]; then
    mkdir -p "$PROJECT_ROOT/results/logs"
    cp "$LOG_PATH" "$LOG_DEST"
    echo "[3/4] ✓ Log copied to: $LOG_DEST"
else
    echo "[3/4] - No log file found (optional)"
fi

# Step 4: Display summary from CSV
echo "[4/4] Results Summary:"
echo ""

# Convert UTF-16LE to UTF-8 and parse key metrics
if command -v iconv >/dev/null 2>&1; then
    # Parse CSV for key metrics
    WIN_RATE=$(cat "$CSV_DEST" | iconv -f UTF-16LE -t UTF-8 2>/dev/null | grep "Win Rate" | cut -d',' -f2 | tr -d '\r' || echo "N/A")
    TOTAL_TRADES=$(cat "$CSV_DEST" | iconv -f UTF-16LE -t UTF-8 2>/dev/null | grep "Total Trades" | cut -d',' -f2 | tr -d '\r' || echo "N/A")
    NET_PROFIT=$(cat "$CSV_DEST" | iconv -f UTF-16LE -t UTF-8 2>/dev/null | grep "Net Profit" | cut -d',' -f2 | tr -d '\r' || echo "N/A")
    MAX_DD=$(cat "$CSV_DEST" | iconv -f UTF-16LE -t UTF-8 2>/dev/null | grep "Balance DD %" | cut -d',' -f2 | tr -d '\r' || echo "N/A")

    echo "  Win Rate:      $WIN_RATE"
    echo "  Total Trades:  $TOTAL_TRADES"
    echo "  Net Profit:    $NET_PROFIT"
    echo "  Max DD %:      $MAX_DD"
else
    echo "  (Install iconv for CSV parsing)"
fi

echo ""
echo "Done. Results saved to results/"
echo ""
echo "Next steps:"
echo "1. Backtester reads: $CSV_DEST"
echo "2. Backtester writes: results/${DATE}_${EA_NAME}_journal.md"
echo "3. git add + commit + push"
