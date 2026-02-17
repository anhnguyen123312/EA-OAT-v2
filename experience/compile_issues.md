# Compile Issues

Technical compilation problems encountered and their fixes.

<!-- Coder updates this file after every compile attempt -->

## AdvancedEA v1.00 - 2026-02-17

### Issue: STAT_WIN_TRADES constant doesn't exist
**Error:** `error 256: undeclared identifier` at line 1371
**Cause:** Used `STAT_WIN_TRADES` in OnTester() R:R calculation
**Fix:** MQL5 uses `STAT_PROFIT_TRADES` (not STAT_WIN_TRADES)
- Also use `STAT_GROSS_PROFIT` and `STAT_GROSS_LOSS` for totals
- Formula: `avgWin = GROSS_PROFIT / PROFIT_TRADES`, `avgLoss = GROSS_LOSS / LOSS_TRADES`

### Success: Zero errors, zero warnings
**File:** AdvancedEA.mq5 (1,411 lines)
**Output:** AdvancedEA.ex5 (45KB)
**Critical fixes applied:**
1. GetATR()/GetMA() helper functions (handle-based API)
2. HasTriggerCandle() function (Design Decision 14)
3. OB strength base 8 (allows Strong OBs >=7)
4. Correct R:R calculation in OnTester()
5. Trigger candle check before entry
6. MTF bias in trade comment

## 2026-02-17: AdvancedEA v1.00 Compilation

### Issue 1: Incorrect TesterStatistics constant
**Error:** `error 256: undeclared identifier` at line 1371
```
double winTrades = TesterStatistics(STAT_WIN_TRADES);  // WRONG
```

**Cause:** `STAT_WIN_TRADES` constant doesn't exist in MQL5

**Fix:** Use correct constant `STAT_PROFIT_TRADES`
```mql5
double profitTrades = TesterStatistics(STAT_PROFIT_TRADES);  // CORRECT
```

**Lesson:** Always verify constant names against MQL5 documentation. The correct statistics constants are:
- `STAT_TRADES` - total trades
- `STAT_PROFIT_TRADES` - number of winning trades
- `STAT_LOSS_TRADES` - number of losing trades
- `STAT_GROSS_PROFIT` - total profit from wins
- `STAT_GROSS_LOSS` - total loss from losses

### Issue 2: Duplicate variable declaration
**Error:** Duplicate `winRate` calculation after fixing Issue 1

**Cause:** Modified code had leftover duplicate line from user edit

**Fix:** Removed duplicate calculation

### Success: AdvancedEA v1.00
- **Result:** 0 errors, 0 warnings
- **Build time:** 1227 msec
- **Output:** AdvancedEA.ex5 (45KB)
- **Lines of code:** ~1400 lines (single-file architecture)
- **Components:** 5 detector classes + scorer + risk manager + full EA logic

## 2026-02-17 (Continued): AdvancedEA v1.00 Backtest Results

### Backtest Configuration
- **Symbol:** XAUUSD
- **Timeframe:** M5
- **Period:** 2023.01.01 - 2025.12.31 (3 years)
- **Model:** Every tick (Model=4)
- **Deposit:** $10,000 (config shows 10000, but CSV shows 1000 - discrepancy needs investigation)
- **Leverage:** 1:100

### CATASTROPHIC FAILURE - Account Blown
**Result:** Strategy completely failed all targets

**Critical Metrics:**
- ❌ **Win Rate:** 19.80% (Target: ≥80%, Gap: -60.2%)
- ❌ **Total Trades:** 197 (0.18 trades/day vs target ≥10/day)
- ❌ **Net Profit:** -$1,001.90 (ACCOUNT BLOWN)
- ❌ **Max DD:** 100.18% (Target: <10%, exceeded by 90.18%)
- ❌ **Profit Factor:** 0.46 (massive losses)
- ❌ **Risk:Reward:** ~0.46 (Target: ≥2.0)

**Trade Distribution:**
- Win Trades: 39
- Loss Trades: 158
- Long Trades: 98
- Short Trades: 99 (balanced)

**Root Cause Analysis (Preliminary):**
1. **Signal Quality Issue:** 80% loss rate suggests detectors are generating false signals
2. **Risk Management Failure:** Account blown indicates position sizing or stop loss logic is broken
3. **Low Trade Frequency:** 0.18 trades/day vs 10+ target suggests filters are TOO strict OR detectors aren't working
4. **Possible Bugs:**
   - Deposit discrepancy (config=10000, CSV=1000)
   - Stop loss not being respected (100% DD)
   - Entry logic inverting signals (20% WR could mean signals are backwards)

**Lesson:** AdvancedEA v1.00 baseline is NOT viable. Requires complete strategy review and likely detector debugging before next iteration.
