# AdvancedEA v1.01 Backtest - Live Status

**Started:** 2026-02-17 18:27 (automated via Wine) - FAILED ❌
**Retry:** 2026-02-17 18:28 (fixed credentials)
**Method:** run_backtest_automated.sh (headless terminal64.exe)
**Status:** RUNNING ⏳

---

## Configuration

```ini
Expert: AdvancedEA
Symbol: XAUUSD
Period: M5
Model: 4 (Real Ticks - highest accuracy)
Dates: 2023.01.01 - 2025.12.31 (3 years)
Deposit: $1,000
Leverage: 1:100
ShutdownTerminal: 1 (auto-close when done)
```

---

## Expected Completion

- **Model:** Real Ticks (slowest but most accurate)
- **Period:** 3 years of M5 data
- **Expected Duration:** 15-30 minutes
- **ETA:** ~18:42 - 18:57

---

## What Happened - First Attempt FAILED

**18:27 - First Run:**
- ❌ FAILED - Wrong credentials in config
- Config had: Login=515167729, Server=Exness-MT5Trial7
- Backtest couldn't authenticate

**18:28 - Second Run (CURRENT):**
- ✅ Fixed credentials: Login=128364028, Server=Exness-MT5Real7
- Wine is running MT5 terminal64.exe in headless mode
- Loading historical tick data for XAUUSD
- Simulating each M5 candle with real bid/ask spreads
- Running AdvancedEA.ex5 on each tick
- Will export results to backtest_results.csv when complete
- Will auto-close MT5 when done

The toolbar warnings in output are normal Wine compatibility messages and can be ignored.

---

## How to Check Progress

```bash
# Check if MT5 is still running
pgrep -q "wine" && echo "RUNNING" || echo "DONE"

# Check if results CSV exists and is new
ls -lh "$HOME/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/users/crossover/AppData/Roaming/MetaQuotes/Terminal/Common/Files/backtest_results.csv"

# Monitor background task output
tail -f /private/tmp/claude-501/-Volumes-Data-Git-EA-OAT-v2/tasks/b03b710.output
```

---

## Next Steps After Completion

1. **Collect Results**
   ```bash
   ./scripts/collect_backtest_results.sh AdvancedEA XAUUSD M5
   ```

2. **Backtester Analysis**
   - Read CSV files
   - Classify all trades (5 categories)
   - Identify root causes
   - Write comprehensive journal

3. **Em Decision**
   - Compare v1.01 vs v1.00
   - Execute decision tree
   - Create next iteration task (v1.02) or mark COMPLETE

4. **Implementation** (if needed)
   - v1.02: PA Confluence Framework (specs ready)
   - v1.03: DCA + Risk Management (planned)
   - Or: Mark project COMPLETE if targets met

---

## Success Criteria for v1.01

**Expected (if entry timing fix worked):**
- Win Rate: 60-70% (up from 19.8%)
- Max DD: < 40% (down from 100%)
- Profit: Positive (from -$1,000)
- Trade Count: ~80-120 trades

**Failure Indicators:**
- WR < 60%: Entry timing fix didn't work
- DD > 50%: Risk management issues
- Profit < $0: Still losing money

---

## Preparation Status

✅ v1.02 CODER_TASK ready (PA Confluence specs)
✅ BACKTESTER_TASK ready (analysis framework)
✅ Scripts tested and working
✅ Git up-to-date (all commits pushed)
✅ Documentation complete

**Ready to proceed immediately when backtest completes!**

---

**Last Updated:** 2026-02-17 18:30
**Background Task ID:** b03b710
