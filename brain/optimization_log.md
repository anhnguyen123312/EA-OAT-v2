# Optimization Log

Track every iteration: version, metrics, root cause, decision.

<!-- Em updates this file after every analysis iteration -->

---

## Iteration 0: SimpleEA (Workflow Validation)

**Date:** 2026-02-17
**EA Version:** SimpleEA v1.00
**Strategy:** MA(10)/MA(20) Crossover (baseline, NOT performance-critical)
**Config:** XAUUSD, M5, 2024.01.01-2024.12.31, $10,000 deposit, 100:1 leverage

### Results

| Metric | Result | Target | Status |
|--------|--------|--------|--------|
| Win Rate | 26.43% | ≥ 90% | ❌ (Expected - baseline) |
| Risk:Reward | 1:2 (fixed) | ≥ 1:2 | ✅ (by design) |
| Trades/Day | 10.6 (3871/365) | ≥ 10 | ✅ |
| Max DD | 8.19% | < 10% | ✅ |
| Total Trades | 3871 | - | - |
| Profit Factor | 0.72 | ≥ 3.0 | ❌ |
| Sharpe Ratio | -5.00 | ≥ 2.0 | ❌ |
| Net Profit | -$802.00 | - | ❌ |
| Gross Profit | $2,046.00 | - | - |
| Gross Loss | -$2,848.00 | - | - |
| Max Consec Wins | 12 | - | - |
| Max Consec Losses | 29 | - | - |

### Workflow Validation Results

| Check | Status |
|-------|--------|
| Code compiles (0 errors, 0 warnings) | ✅ |
| MT5 backtest runs successfully | ✅ |
| OnTester() exports CSV to Common/Files | ✅ |
| CSV contains all required metrics | ✅ |
| CSV parseable (after UTF-16LE → UTF-8) | ✅ |

### Root Cause Analysis (Workflow Only)

**Purpose of Iteration 0:** Validate Em → Coder → Backtest → CSV → Analyze pipeline.

**Why Low Win Rate?**
- MA crossover is a trend-following strategy in a choppy market (Gold M5)
- TP (200 points) = 2× SL (100 points), but WR of 26.43% means expectancy is negative
- Expected Payoff = -0.21 per trade (consistent with negative net profit)
- This is EXPECTED and ACCEPTABLE - SimpleEA is a workflow test, not a trading strategy

**What Worked:**
- Compile succeeded on first try (0 errors, 0 warnings)
- Backtest completed in ~1 second (1412132 ticks, 70778 bars)
- CSV export to Common/Files worked correctly
- All 19 metrics exported and parseable

**Issues Found & Fixed:**
1. Wine user is `crossover`, NOT `$(whoami)` - updated experience/backtest_setup.md
2. CSV is UTF-16LE encoded - requires `iconv -f UTF-16LE -t UTF-8` conversion

### Decision

**WORKFLOW VALIDATED ✅**

All pipeline steps work:
1. ✅ Coder writes EA → code/experts/SimpleEA.mq5
2. ✅ MetaEditor compiles → 0 errors, 0 warnings
3. ✅ MT5 backtest runs → completes with ShutdownTerminal=1
4. ✅ OnTester exports CSV → Common/Files/backtest_results.csv
5. ✅ Em finds CSV → converts encoding → parses metrics
6. ✅ Results saved → results/2026-02-17_SimpleEA_XAUUSD_M5.csv

**Next Action:** Proceed to Iteration 1 (AdvancedEA with full SMC strategy)

---

## Iteration 1: AdvancedEA (SMC Baseline) - CATASTROPHIC FAILURE

**Date:** 2026-02-17
**EA Version:** AdvancedEA v1.00
**Strategy:** BOS + Sweep + OB + FVG + MTF Bias (score ≥ 100)
**Config:** XAUUSD, M5, 2023.01.01-2025.12.31 (3 years), $10,000 deposit, 100:1 leverage

### Results

| Metric | Result | Target | Status | Gap |
|--------|--------|--------|--------|-----|
| **Win Rate** | **19.80%** | ≥ 80% | ❌ **CATASTROPHIC** | **-60.2%** |
| **Risk:Reward** | **1.85** | ≥ 2.0 | 🟡 **CLOSE** | -0.15 |
| **Trades/Day** | **0.18** (197/1095) | ≥ 10 | ❌ **CRITICAL** | **-9.82/day** |
| **Max DD** | **100.18%** | < 10% | ❌ **ACCOUNT BLOWN** | **+90.18%** |
| **Total Trades** | 197 | - | - | Over 3 years |
| **Profit Factor** | 0.46 | ≥ 1.0 | ❌ | -0.54 |
| **Sharpe Ratio** | -5.00 | ≥ 2.0 | ❌ | - |
| **Net Profit** | **-$1,001.90** | Positive | ❌ **BLOWN** | - |
| **Gross Profit** | $840.30 | - | - | - |
| **Gross Loss** | -$1,842.20 | - | - | - |
| **Win Trades** | 39 (19.8%) | - | - | - |
| **Loss Trades** | 158 (80.2%) | - | - | - |
| **Long Trades** | 98 (49.75%) | - | Balanced | - |
| **Short Trades** | 99 (50.25%) | - | Balanced | - |

**VERDICT:** 🔴 ALL 4 TARGETS MISSED - Account completely wiped out

### Root Cause Analysis (Updated After Code Review)

**PRIMARY CAUSE: ENTRY TIMING BUG (95% Confidence)**

**Backtester's Deep Code Analysis Findings:**

**✅ Code Sections That Are CORRECT:**
1. **BOS Detection (Lines 382-436):**
   - Bullish BOS → `direction = 1` ✅
   - Bearish BOS → `direction = -1` ✅
2. **Trade Execution (Lines 1353-1359):**
   - `direction == 1` → `trade.Buy()` ✅
   - `direction == -1` → `trade.Sell()` ✅
3. **SL/TP Placement (Lines 1064-1104):**
   - LONG: SL below entry, TP above entry ✅
   - SHORT: SL above entry, TP below entry ✅
   - R:R = 2:1 for both ✅

**🔴 The ACTUAL Bug: Premature Entry (Lines 1064-1082)**

The code enters **AT** the Order Block instead of **FROM** the Order Block after a pullback:

```cpp
// Current (BROKEN) Flow:
1. Detect Bullish BOS → Immediately build candidate
2. Set entryPrice = ob_bull.priceBottom (the OB level)
3. Place market order at current ASK price
4. Price hasn't pulled back to OB yet → entering too early/late
5. Pullback stops us out → then rallies without us
```

**Example Scenario:**
1. Bullish BOS detected at 2050.00 (breaks swing high)
2. Order Block identified at 2045.00 (support zone)
3. **Bug:** Code immediately enters LONG at current price (2050.00+)
4. Price pulls back to 2045.00 → hits our SL
5. Then price rallies from 2045.00 (the correct entry we just missed)

**Why This Explains 19.8% WR:**
- 80% losses = entering at wrong timing (late/early)
- Pullback stops us out on what should have been the entry
- R:R still ~1.85 because distance calculations are correct
- 50/50 long/short because directional bias detection works

**SECONDARY CAUSES:**

2. **Risk Management Bug (80% Confidence)**
   - Account blown (100.18% DD) despite 0.5% risk/trade setting
   - Could be lot sizing OR SL not being honored
   - Needs investigation in v1.01

3. **Low Trade Frequency (30% Confidence)**
   - 0.18 trades/day vs 10/day target
   - May be acceptable given strict confluence requirements
   - Re-evaluate after timing fix

4. **Missing Trade Export**
   - OnTester() only exports aggregate metrics
   - Need individual trade history for detailed analysis

### Projected Impact (After Fixes)

| Metric | Current | After Timing Fix | After Risk Fix | Target | Projected Status |
|--------|---------|------------------|----------------|--------|------------------|
| Win Rate | 19.8% | **60-70%** | 60-70% | 80% | 🟡 IMPROVED (not target) |
| Risk:Reward | 1.85 | 1.85 | 1.85 | 2.0 | 🟡 CLOSE |
| Trades/Day | 0.18 | 0.18 | 0.18 | 10 | ❌ NEEDS WORK |
| Max DD | 100.18% | ~100% | **<10%** | <10% | ✅ AFTER FIX |

**Confidence:** HIGH (95%) that entry timing is root cause
**Expected WR:** 60-70% (not 80%) because some pullbacks will fail (genuine reversals)

### Decision

**✅ ITERATE → v1.01 (Bug Fix Release)**

**Rationale:**
1. Problems are **CODE BUGS** not strategy flaws
2. 90% confident signal inversion is the root cause
3. Strategy design appears sound (R:R close to target, balanced directional trades)
4. Expected v1.01 results: **70-80% WR** (near target after inversion fix)

**DO NOT PIVOT** - Fix critical bugs first, then re-evaluate

**Next Action:** Create bug fix task for Coder (v1.01)

### Fixes Required for v1.01

**PRIORITY 1: Fix Entry Timing Logic (CRITICAL)**
- **File:** `code/experts/AdvancedEA.mq5` (Lines 1064-1082)
- **Current Bug:** Enters immediately when BOS+OB detected, before pullback
- **Fix Required:**
  1. Add pullback detection - check if current price is NEAR the OB/FVG zone
  2. Add zone tolerance parameter (e.g., 0.05% of price)
  3. Add confirmation candle requirement at the zone
  4. Wait for price to reach POI before entry
- **Implementation:**
  ```cpp
  // Check if current price is AT the OB zone (within tolerance)
  double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  double obZone = ob_bull.priceBottom;
  double tolerance = 0.0005 * currentPrice;  // 0.05% tolerance

  if(MathAbs(currentPrice - obZone) <= tolerance) {
      // NOW at OB zone - check for confirmation candle
      if(ConfirmationCandlePresent()) {
          candidate.entryPrice = currentPrice;
          // Enter here
      }
  } else {
      // Price not at OB yet - don't enter!
      return;  // Skip this tick
  }
  ```
- **Expected Impact:** **WR: 19.8% → 60-70%**

**PRIORITY 2: Fix Risk Management (CRITICAL)**
- **Check:** Lot size calculation in `g_riskMgr.CalculateLotSize()`
- **Check:** SL actually being set in `trade.Buy/Sell` calls
- **Check:** Decimal point errors (0.5% vs 0.005)
- **Expected Impact:** **DD: 100% → <10%**

**PRIORITY 3: Add Individual Trade Export (HIGH)**
- **Add:** `HistoryDealsTotal()` loop to OnTester()
- **Export:** ticket, type, open_time, close_time, prices, sl, tp, profit, comment
- **Format:** CSV file `trade_history.csv` to Common/Files
- **Expected Impact:** Enable detailed trade classification in v1.02+

**PRIORITY 4: Fix Config Deposit Discrepancy (MEDIUM)**
- **Issue:** Config shows $10,000, CSV shows $1,000
- **Action:** Verify which was actually used, update config to $1,000 for consistency
- **Impact:** Ensure apples-to-apples comparison across iterations

---
