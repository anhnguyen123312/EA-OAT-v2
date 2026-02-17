#!/bin/bash
# Validate MT5 backtest .ini config file
# Usage: ./validate_config.sh path/to/config.ini
# Example: ./validate_config.sh config/active/autobacktest.ini

set -e

if [ -z "$1" ]; then
    echo "ERROR: Config file path required"
    echo "Usage: ./validate_config.sh path/to/config.ini"
    exit 1
fi

CONFIG_FILE="$1"

echo "=== MT5 Config Validator ==="
echo "File: $CONFIG_FILE"
echo ""

# Check file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: File not found: $CONFIG_FILE"
    exit 1
fi

echo "[Validation Results]"
echo ""

# Critical checks
ERRORS=0
WARNINGS=0

# 1. Expert= must be name only (no path prefix)
EXPERT_LINE=$(grep "^Expert=" "$CONFIG_FILE" || true)
if [ -z "$EXPERT_LINE" ]; then
    echo "❌ ERROR: Missing 'Expert=' line"
    ERRORS=$((ERRORS + 1))
else
    EXPERT_VALUE=$(echo "$EXPERT_LINE" | cut -d'=' -f2)

    # Check for path separators (backslash or forward slash)
    if echo "$EXPERT_VALUE" | grep -q '[/\\]'; then
        echo "❌ ERROR: Expert= contains path separator: $EXPERT_VALUE"
        echo "   Fix: Use EA name only (e.g., Expert=SimpleEA, NOT Expert=Experts\\SimpleEA)"
        ERRORS=$((ERRORS + 1))
    else
        echo "✓ Expert=$EXPERT_VALUE (name only, correct)"
    fi
fi

# 2. Symbol must be set
SYMBOL_LINE=$(grep "^Symbol=" "$CONFIG_FILE" || true)
if [ -z "$SYMBOL_LINE" ]; then
    echo "❌ ERROR: Missing 'Symbol=' line"
    ERRORS=$((ERRORS + 1))
else
    SYMBOL_VALUE=$(echo "$SYMBOL_LINE" | cut -d'=' -f2)
    echo "✓ Symbol=$SYMBOL_VALUE"
fi

# 3. Period must be valid
PERIOD_LINE=$(grep "^Period=" "$CONFIG_FILE" || true)
if [ -z "$PERIOD_LINE" ]; then
    echo "❌ ERROR: Missing 'Period=' line"
    ERRORS=$((ERRORS + 1))
else
    PERIOD_VALUE=$(echo "$PERIOD_LINE" | cut -d'=' -f2)
    # Valid periods: M1=1, M5=5, M15=15, M30=30, H1=60, H4=240, D1=1440
    VALID_PERIODS="1 5 15 30 60 240 1440 10080 43200"
    if echo "$VALID_PERIODS" | grep -wq "$PERIOD_VALUE"; then
        echo "✓ Period=$PERIOD_VALUE"
    else
        echo "⚠️  WARNING: Unusual period value: $PERIOD_VALUE"
        echo "   Valid: M1=1, M5=5, M15=15, M30=30, H1=60, H4=240, D1=1440"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# 4. Model must be set (0-4)
MODEL_LINE=$(grep "^Model=" "$CONFIG_FILE" || true)
if [ -z "$MODEL_LINE" ]; then
    echo "⚠️  WARNING: Missing 'Model=' line (default: 1)"
    WARNINGS=$((WARNINGS + 1))
else
    MODEL_VALUE=$(echo "$MODEL_LINE" | cut -d'=' -f2)
    if [ "$MODEL_VALUE" -ge 0 ] && [ "$MODEL_VALUE" -le 4 ] 2>/dev/null; then
        echo "✓ Model=$MODEL_VALUE (0=Every tick, 1=1min OHLC, 2=Open only, 3=Math, 4=Every tick real)"
    else
        echo "❌ ERROR: Invalid Model value: $MODEL_VALUE (must be 0-4)"
        ERRORS=$((ERRORS + 1))
    fi
fi

# 5. Date range must be valid
FROM_DATE=$(grep "^FromDate=" "$CONFIG_FILE" | cut -d'=' -f2 || true)
TO_DATE=$(grep "^ToDate=" "$CONFIG_FILE" | cut -d'=' -f2 || true)

if [ -z "$FROM_DATE" ]; then
    echo "❌ ERROR: Missing 'FromDate=' line"
    ERRORS=$((ERRORS + 1))
elif ! echo "$FROM_DATE" | grep -qE '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'; then
    echo "❌ ERROR: Invalid FromDate format: $FROM_DATE (expected: YYYY.MM.DD)"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ FromDate=$FROM_DATE"
fi

if [ -z "$TO_DATE" ]; then
    echo "❌ ERROR: Missing 'ToDate=' line"
    ERRORS=$((ERRORS + 1))
elif ! echo "$TO_DATE" | grep -qE '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$'; then
    echo "❌ ERROR: Invalid ToDate format: $TO_DATE (expected: YYYY.MM.DD)"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ ToDate=$TO_DATE"
fi

# 6. Deposit must be set
DEPOSIT=$(grep "^Deposit=" "$CONFIG_FILE" | cut -d'=' -f2 || true)
if [ -z "$DEPOSIT" ]; then
    echo "⚠️  WARNING: Missing 'Deposit=' line"
    WARNINGS=$((WARNINGS + 1))
elif [ "$DEPOSIT" -le 0 ] 2>/dev/null; then
    echo "❌ ERROR: Invalid Deposit: $DEPOSIT (must be > 0)"
    ERRORS=$((ERRORS + 1))
else
    echo "✓ Deposit=$DEPOSIT"
fi

# 7. Leverage must be set
LEVERAGE=$(grep "^Leverage=" "$CONFIG_FILE" | cut -d'=' -f2 || true)
if [ -z "$LEVERAGE" ]; then
    echo "⚠️  WARNING: Missing 'Leverage=' line (default: 100)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "✓ Leverage=$LEVERAGE"
fi

# 8. ShutdownTerminal for automation
SHUTDOWN=$(grep "^ShutdownTerminal=" "$CONFIG_FILE" | cut -d'=' -f2 || true)
if [ "$SHUTDOWN" != "1" ]; then
    echo "⚠️  WARNING: ShutdownTerminal=$SHUTDOWN (recommend: 1 for automation)"
    WARNINGS=$((WARNINGS + 1))
else
    echo "✓ ShutdownTerminal=1 (auto-close after backtest)"
fi

# 9. Login/Server for real-ticks model
if [ "$MODEL_VALUE" == "4" ]; then
    LOGIN=$(grep "^Login=" "$CONFIG_FILE" | cut -d'=' -f2 || true)
    SERVER=$(grep "^Server=" "$CONFIG_FILE" | cut -d'=' -f2 || true)

    if [ -z "$LOGIN" ]; then
        echo "⚠️  WARNING: Model=4 (real ticks) but Login= missing"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "✓ Login=$LOGIN (for real-ticks download)"
    fi

    if [ -z "$SERVER" ]; then
        echo "⚠️  WARNING: Model=4 (real ticks) but Server= missing"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "✓ Server=$SERVER"
    fi
fi

# Summary
echo ""
echo "=== Summary ==="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ VALID: 0 errors, 0 warnings"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  VALID WITH WARNINGS: 0 errors, $WARNINGS warning(s)"
    exit 0
else
    echo "❌ INVALID: $ERRORS error(s), $WARNINGS warning(s)"
    echo ""
    echo "Fix errors before running backtest."
    exit 1
fi
