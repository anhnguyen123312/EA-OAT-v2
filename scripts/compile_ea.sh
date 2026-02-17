#!/bin/bash
# Compile EA from code/experts/ to MT5
# Usage: ./compile_ea.sh EAName
# Example: ./compile_ea.sh SimpleEA

set -e

# Validate input
if [ -z "$1" ]; then
    echo "ERROR: EA name required"
    echo "Usage: ./compile_ea.sh EAName"
    exit 1
fi

EA_NAME="$1"
PROJECT_ROOT="/Volumes/Data/Git/EA-OAT-v2"
EA_SOURCE="$PROJECT_ROOT/code/experts/${EA_NAME}.mq5"

# Wine/MT5 paths
WINEPREFIX="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5"
MT5_BASE="$WINEPREFIX/drive_c/Program Files/MetaTrader 5"
WINE="/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"

echo "=== MT5 EA Compiler ==="
echo "EA: $EA_NAME"
echo ""

# Step 1: Validate source exists
if [ ! -f "$EA_SOURCE" ]; then
    echo "ERROR: Source file not found: $EA_SOURCE"
    exit 1
fi
echo "[1/5] ✓ Source file found"

# Step 2: Copy source to MT5 Experts folder
cp "$EA_SOURCE" "$MT5_BASE/MQL5/Experts/"
echo "[2/5] ✓ Copied to MT5/Experts/"

# Step 3: Copy includes if any (optional)
if [ -d "$PROJECT_ROOT/code/include" ]; then
    cp -r "$PROJECT_ROOT/code/include"/* "$MT5_BASE/MQL5/Include/" 2>/dev/null || true
    echo "[3/5] ✓ Includes copied (if any)"
else
    echo "[3/5] - No includes to copy"
fi

# Step 4: Compile
echo "[4/5] Compiling..."
cd "$MT5_BASE"

# Run compiler
"$WINE" metaeditor64.exe /compile:"MQL5\\Experts\\${EA_NAME}.mq5" /log 2>&1

# Step 5: Check results
LOG_FILE="$MT5_BASE/MQL5/Experts/${EA_NAME}.log"
if [ -f "$LOG_FILE" ]; then
    echo ""
    echo "=== Compile Log ==="
    cat "$LOG_FILE"
    echo ""

    # Check for errors
    ERROR_COUNT=$(grep -c "error" "$LOG_FILE" || true)
    WARNING_COUNT=$(grep -c "warning" "$LOG_FILE" || true)

    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "[5/5] ❌ FAILED: $ERROR_COUNT error(s), $WARNING_COUNT warning(s)"
        echo ""
        echo "Compile log saved to: $LOG_FILE"
        echo "Update experience/compile_issues.md with this error"
        exit 1
    else
        echo "[5/5] ✅ SUCCESS: 0 errors, $WARNING_COUNT warning(s)"

        # Check .ex5 created
        if [ -f "$MT5_BASE/MQL5/Experts/${EA_NAME}.ex5" ]; then
            EX5_SIZE=$(stat -f%z "$MT5_BASE/MQL5/Experts/${EA_NAME}.ex5")
            echo ""
            echo "Compiled binary: ${EA_NAME}.ex5 (${EX5_SIZE} bytes)"
        fi
    fi
else
    echo "[5/5] ⚠️  No log file found - compile may have failed"
    exit 1
fi

echo ""
echo "Done. Ready for backtest."
