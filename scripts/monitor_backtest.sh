#!/bin/bash
# Monitor backtest progress and notify when complete
# Usage: ./monitor_backtest.sh

CSV_FILE="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/users/crossover/AppData/Roaming/MetaQuotes/Terminal/Common/Files/backtest_results.csv"
LAST_MOD_TIME=0

echo "=== Monitoring MT5 Backtest ==="
echo "Checking every 30 seconds..."
echo "Press Ctrl+C to stop monitoring"
echo ""

while true; do
    # Check if MT5 is still running
    if ! pgrep -q "MetaTrader"; then
        echo "✅ MT5 closed - backtest likely complete!"

        if [ -f "$CSV_FILE" ]; then
            CURRENT_TIME=$(stat -f %m "$CSV_FILE")
            if [ "$CURRENT_TIME" -gt "$LAST_MOD_TIME" ]; then
                echo "✅ New results detected!"
                echo ""
                echo "File: $CSV_FILE"
                ls -lh "$CSV_FILE"
                echo ""
                echo "To collect results, run:"
                echo "./scripts/collect_backtest_results.sh AdvancedEA XAUUSD M5"
                exit 0
            fi
        fi

        echo "⚠️ MT5 closed but no new results - check manually"
        exit 1
    fi

    # Check if CSV was updated
    if [ -f "$CSV_FILE" ]; then
        CURRENT_TIME=$(stat -f %m "$CSV_FILE")
        if [ "$CURRENT_TIME" -gt "$LAST_MOD_TIME" ]; then
            LAST_MOD_TIME=$CURRENT_TIME
            echo "[$(date +%H:%M:%S)] CSV updated - backtest progressing..."
        fi
    fi

    # Show timestamp
    echo -n "."
    sleep 30
done
