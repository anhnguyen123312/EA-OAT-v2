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

## Iteration 1: AdvancedEA (SMC Baseline)

**Date:** TBD
**EA Version:** -
**Strategy:** BOS + Sweep + OB + FVG + Momentum (score ≥ 100)
**Status:** ⏳ Pending - awaiting Researcher/PM/Technical pipeline

<!-- Em will update after Iteration 1 backtest -->
