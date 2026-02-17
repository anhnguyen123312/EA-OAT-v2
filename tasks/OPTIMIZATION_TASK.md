# OPTIMIZATION_TASK - AdvancedEA v1.01

**Created:** 2026-02-17
**Iteration:** 1 → 2
**Previous Version:** AdvancedEA v1.00 (CATASTROPHIC FAILURE)
**Target Version:** AdvancedEA v1.01 (Bug Fix Release)
**Priority:** CRITICAL

---

## Executive Summary

**Root Cause:** Entry timing logic bug - code enters immediately when BOS+OB detected instead of waiting for pullback to complete.

**Evidence:**
- 19.8% WR with 50/50 long/short balance
- Code review proved signal direction is CORRECT
- Entry logic enters at current price, not at OB zone after pullback
- R:R = 1.85 (close to target) shows distance calculations work

**Expected Impact After Fix:**
- WR: 19.8% → 60-70% (not 80% - some pullbacks will fail)
- DD: 100% → <10% (if risk management bug also fixed)

---

## Fixes Required

### 🔴 PRIORITY 1: Fix Entry Timing Logic (CRITICAL)

**File:** `code/experts/AdvancedEA.mq5`
**Location:** Lines 1064-1082 (entry price assignment)

**Current Bug:**
```cpp
// LONG entry logic (Line 1066-1070)
if(candidate.hasOB && ob_bull.valid) {
    candidate.entryPrice = ob_bull.priceBottom;  // ← Entering AT the OB
} else {
    candidate.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);  // ← Or at market
}
```

**Problem:** Code sets entry price to OB level but doesn't check if price has actually REACHED that level.

**Required Fix:**

1. **Add Pullback Detection:**
   ```cpp
   // For LONG setups
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double obZone = ob_bull.priceBottom;
   double tolerance = 0.0005 * currentPrice;  // 0.05% tolerance

   // Check if price is NEAR the OB zone
   if(MathAbs(currentPrice - obZone) > tolerance) {
       // Price not at OB yet - skip this tick
       return;
   }
   ```

2. **Add Confirmation Candle Check:**
   ```cpp
   // When price IS at OB zone, check for confirmation
   if(IsConfirmationCandle(LONG)) {
       candidate.entryPrice = currentPrice;
       // Proceed with entry
   } else {
       return;  // Wait for confirmation
   }
   ```

3. **Implement `IsConfirmationCandle()` Function:**
   ```cpp
   bool IsConfirmationCandle(int direction) {
       double open0 = iOpen(_Symbol, PERIOD_CURRENT, 0);
       double close0 = iClose(_Symbol, PERIOD_CURRENT, 0);
       double high0 = iHigh(_Symbol, PERIOD_CURRENT, 0);
       double low0 = iLow(_Symbol, PERIOD_CURRENT, 0);

       if(direction == 1) {  // LONG
           // Bullish engulfing or pin bar
           return (close0 > open0 && (close0 - open0) >= 0.6 * (high0 - low0));
       } else {  // SHORT
           // Bearish engulfing or pin bar
           return (close0 < open0 && (open0 - close0) >= 0.6 * (high0 - low0));
       }
   }
   ```

4. **Add Input Parameter:**
   ```cpp
   input double ZoneTolerance = 0.0005;  // 0.05% tolerance for POI zones
   ```

**Testing:**
- Verify pullback detection works (price must reach zone before entry)
- Verify confirmation candle requirement
- Check log for "Price not at OB yet - skipping" messages

**Expected Impact:** WR: 19.8% → 60-70%

---

### 🔴 PRIORITY 2: Fix Risk Management (CRITICAL)

**Investigation Required:**

1. **Check Lot Size Calculation:**
   ```cpp
   // In RiskManagement.mqh
   double CalculateLotSize(double slDistance) {
       double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
       double riskAmount = accountBalance * (m_riskPercent / 100.0);  // ← Check this
       double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
       double lots = riskAmount / (slDistance * tickValue);
       // Log all values for verification
       Print("Balance:", accountBalance, " Risk%:", m_riskPercent,
             " RiskAmt:", riskAmount, " SL:", slDistance, " Lots:", lots);
       return lots;
   }
   ```

2. **Verify SL is Actually Set:**
   ```cpp
   // In trade execution
   bool success = trade.Buy(lots, _Symbol, 0, candidate.stopLoss, candidate.takeProfit, comment);
   if(!success) {
       Print("ERROR: Trade failed - ", trade.ResultRetcode());
   }
   // After trade, verify SL was set
   if(PositionSelect(_Symbol)) {
       double actualSL = PositionGetDouble(POSITION_SL);
       Print("Requested SL:", candidate.stopLoss, " Actual SL:", actualSL);
   }
   ```

3. **Check for Decimal Errors:**
   ```cpp
   // Is it 0.5% or 0.005?
   input double RiskPercent = 0.5;  // Should be 0.5, NOT 0.005
   ```

**Testing:**
- Run with $1,000 deposit and verify max loss per trade = $5 (0.5%)
- Check backtest log for risk calculation prints
- Verify DD stays below 10%

**Expected Impact:** DD: 100% → <10%

---

### 🟡 PRIORITY 3: Add Individual Trade Export (HIGH)

**File:** `code/experts/AdvancedEA.mq5`
**Location:** `OnTester()` function

**Add After Existing Metrics Export:**

```cpp
// Export individual trade history
string tradeFile = "trade_history.csv";
int handle = FileOpen(tradeFile, FILE_WRITE|FILE_CSV|FILE_COMMON, ",");
if(handle != INVALID_HANDLE) {
    // Header
    FileWrite(handle, "Ticket", "Type", "OpenTime", "CloseTime",
              "OpenPrice", "ClosePrice", "SL", "TP", "Lots",
              "Profit", "Comment");

    // Loop through history
    HistorySelect(0, TimeCurrent());
    int totalDeals = HistoryDealsTotal();
    for(int i = 0; i < totalDeals; i++) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket > 0) {
            ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
            if(entry == DEAL_ENTRY_OUT) {  // Closed trade
                FileWrite(handle,
                    ticket,
                    HistoryDealGetInteger(ticket, DEAL_TYPE),
                    HistoryDealGetInteger(ticket, DEAL_TIME),
                    HistoryDealGetInteger(ticket, DEAL_TIME),  // Close time
                    HistoryDealGetDouble(ticket, DEAL_PRICE),
                    HistoryDealGetDouble(ticket, DEAL_PRICE),  // Close price
                    HistoryDealGetDouble(ticket, DEAL_SL),
                    HistoryDealGetDouble(ticket, DEAL_TP),
                    HistoryDealGetDouble(ticket, DEAL_VOLUME),
                    HistoryDealGetDouble(ticket, DEAL_PROFIT),
                    HistoryDealGetString(ticket, DEAL_COMMENT)
                );
            }
        }
    }
    FileClose(handle);
    Print("Trade history exported: ", tradeFile);
}
```

**Testing:**
- Verify trade_history.csv is created in Common/Files
- Check CSV contains all 197 trades from v1.00
- Validate ticket, times, prices, profit match aggregate metrics

**Expected Impact:** Enable detailed classification in v1.02+

---

### 🟢 PRIORITY 4: Fix Config Deposit (MEDIUM)

**File:** `config/active/autobacktest.ini`

**Change:**
```ini
[Tester]
Deposit=1000  # Was 10000 in config, actual was 1000 per CSV
```

**Rationale:**
- CSV shows Initial Balance = 1000.00
- Config shows 10000
- Use $1,000 for consistency (smaller capital for testing)

**Testing:**
- Verify backtest starts with $1,000
- Check OnTester() exports Initial Balance = 1000.00

---

## Validation Checklist

After implementing ALL 4 priorities, verify:

- [ ] Code compiles (0 errors, 0 warnings)
- [ ] Pullback detection logic added to entry flow
- [ ] Confirmation candle function implemented
- [ ] Zone tolerance parameter added to inputs
- [ ] Risk management calculations logged and verified
- [ ] SL verification added after trade execution
- [ ] Individual trade history exported to CSV
- [ ] Config deposit set to $1,000
- [ ] Backtest runs successfully
- [ ] Results CSV collected from Common/Files
- [ ] WR improved from 19.8% (expect 60-70%)
- [ ] DD reduced from 100% (expect <10%)

---

## Expected v1.01 Results

**Conservative Projections:**

| Metric | v1.00 | v1.01 Target | Status |
|--------|-------|--------------|--------|
| Win Rate | 19.8% | 60-70% | 🟡 Improved (not 80% target) |
| Risk:Reward | 1.85 | 1.85 | 🟡 Unchanged (close to target) |
| Trades/Day | 0.18 | 0.18 | ❌ Needs strategy changes |
| Max DD | 100.18% | <10% | ✅ Should fix |

**If v1.01 Results Show:**
- WR 60-70%: ✅ Timing fix worked, proceed to v1.02 for frequency
- WR <50%: ❌ Something else wrong, deep dive needed
- WR >80%: ✅✅ Exceeded expectations, verify not overfitting

---

## Coder Instructions

1. **Read these files first:**
   - `brain/optimization_log.md` (Iteration 1 analysis)
   - `results/journals/AdvancedEA_Iteration1_DEEP_DIVE.md` (detailed code review)
   - `results/journals/AdvancedEA_Iteration1_FAILURE.md` (metrics analysis)
   - `experience/compile_issues.md` (known MQL5 gotchas)
   - `experience/backtest_setup.md` (Wine/MT5 setup)

2. **Implementation workflow:**
   ```bash
   # SETUP
   ./scripts/git_workflow.sh pull
   cat tasks/OPTIMIZATION_TASK.md

   # IMPLEMENT
   nano code/experts/AdvancedEA.mq5
   # Apply all 4 priorities above

   # COMPILE
   ./scripts/compile_ea.sh AdvancedEA
   # Fix errors → re-compile → repeat until 0 errors

   # VALIDATE CONFIG
   ./scripts/validate_config.sh config/active/autobacktest.ini

   # BACKTEST
   ./scripts/run_backtest_native.sh
   # Wait for completion (ShutdownTerminal=1)

   # COLLECT RESULTS
   ./scripts/collect_backtest_results.sh AdvancedEA XAUUSD M5

   # UPDATE EXPERIENCE
   nano experience/compile_issues.md  # if new errors

   # SYNC
   ./scripts/git_workflow.sh sync "Coder: AdvancedEA v1.01 - Entry timing bug fixed"
   ```

3. **After backtest completes:**
   - Copy CSV to `results/AdvancedEA_v1.01_XAUUSD_M5.csv`
   - Notify Backtester: "v1.01 results ready for analysis"

---

## Success Criteria

**v1.01 is SUCCESS if:**
- Compiles cleanly (0 errors)
- WR improves to 60-70% range
- DD drops below 10%
- Trade history CSV exports correctly

**v1.01 is PARTIAL SUCCESS if:**
- WR improves to 40-60% (timing helped but not enough)
- DD still high (risk bug not fixed)
→ Requires v1.02 iteration

**v1.01 is FAILURE if:**
- WR < 40% (timing fix didn't help)
- Account still blown
→ Requires deeper investigation

---

**CRITICAL:** Do NOT skip any of the 4 priorities. All are required for v1.01.

**Em will decide next iteration based on v1.01 results.**
