# Targets & Progress

**Last Updated:** 2026-02-17
**Status:** Iteration 0 COMPLETE (Workflow Validated), Ready for Iteration 1

---

## 🎯 Performance Targets (Non-Negotiable)

### Primary Targets

| Metric | Target | Status | Current | Gap |
|--------|--------|--------|---------|-----|
| **Win Rate** | ≥ 90% | ⏳ Pending | - | - |
| **Risk:Reward** | ≥ 1:2 | ⏳ Pending | - | - |
| **Trades/Day** | ≥ 10 | ⏳ Pending | - | - |
| **Max Drawdown** | < 10% | ⏳ Pending | - | - |

**ALL FOUR MUST BE MET SIMULTANEOUSLY**

❌ 95% WR but 5 trades/day = FAIL  
❌ 15 trades/day but 80% WR = FAIL  
✅ 90% WR + 1:2 RR + 10 trades/day + 8% DD = SUCCESS

---

### Secondary Targets (Nice to Have)

| Metric | Target | Priority |
|--------|--------|----------|
| Profit Factor | ≥ 3.0 | Medium |
| Sharpe Ratio | ≥ 2.0 | Medium |
| Max Consecutive Losses | ≤ 3 | Low |
| Recovery Factor | ≥ 5.0 | Low |

---

## 📊 Iteration Progress Log

### Iteration 0: Pre-Test (Workflow Validation)

**Date:** 2026-02-16  
**EA:** SimpleEA (MA Crossover Baseline)  
**Purpose:** Validate Em → Coder → Backtest → CSV → Analyze workflow

**Expected:**
- Compile: ✅ Success
- Backtest: ✅ Completes
- CSV Export: ✅ Generated
- Metrics: Not performance-critical (baseline only)

**Actual Results (2026-02-17):**
- Compile: ✅ 0 errors, 0 warnings
- Backtest: ✅ Completed (3871 trades, 7742 deals)
- CSV Export: ✅ Generated (19 metrics)
- Win Rate: 26.43% (expected for MA crossover baseline)
- Net Profit: -$802.00 (expected negative)
- Max DD: 8.19% (under 10% target)
- Trades/Day: 10.6 (meets target)

**Status:** ✅ COMPLETE - Workflow Validated

---

### Iteration 1: SMC Baseline (First Real Test)

**Date:** TBD  
**EA:** AdvancedEA (Full EA-OAT SMC)  
**Strategy:** BOS + Sweep + OB + FVG + Momentum (score ≥ 100)

**Expected:**
- Win Rate: 70-80% (typical SMC without optimization)
- Trades/Day: 15-20 (M5 should generate signals)
- RR: 1.5-2.0 (structure-based TP)
- DD: Unknown

**Analysis Focus:**
- Which patterns have highest WR? (BOS+OB vs Sweep+FVG, etc.)
- Which patterns fail most? (counter-trend? weak OB?)
- Frequency distribution by score range (100-149 vs 150-199 vs 200+)

**Status:** ⏳ Pending Iteration 0 completion

---

## 🎯 Milestone Roadmap

### Phase 1: SMC Baseline (Current)

**Goal:** Validate SMC-only strategy can meet targets

**Milestones:**
- [x] M1: Workflow validated (Simple EA compiles, backtests, exports CSV) ✅ 2026-02-17
- [ ] M2: SMC EA deployed (AdvancedEA running on M5 XAUUSD)
- [ ] M3: First backtest completed (1 year data, 2023-2024)
- [ ] M4: Root cause analysis (identify why targets missed)
- [ ] M5: Optimization #1 (adjust score threshold or filters)
- [ ] M6: Optimization #2-5 (iterate based on data)
- [ ] M7: Targets met OR pivot decision

**Success:** All 4 targets met with SMC-only → Skip Phase 2, go live  
**Failure:** < 90% WR after 5+ optimizations → Proceed to Phase 2

---

### Phase 2: EW + VP Integration (If Needed)

**Trigger:** Phase 1 WR < 90% after 5+ iterations

**Goal:** Add macro bias (EW) and key levels (VP) to filter SMC signals

**Milestones:**
- [ ] M8: EW detector implemented (H4/D1 wave counting)
- [ ] M9: VP calculator implemented (H1 POC, VAH, VAL)
- [ ] M10: Unified scoring (EW × 0.25 + VP × 0.35 + SMC × 0.40 ≥ 60)
- [ ] M11: Backtest with filters (expect fewer trades, higher WR)
- [ ] M12: Optimization iterations (adjust weights, thresholds)
- [ ] M13: Targets met OR proceed to Phase 3

**Success:** 90% WR + 10+ trades/day → Go live  
**Failure:** Still < 90% WR → Consider Phase 3 (OF) or pivot

---

### Phase 3: Order Flow (Futures Only, If Needed)

**Trigger:** Phase 2 WR < 90% AND access to GC futures (Level 2 data)

**Goal:** Add final confirmation layer (delta, CVD, absorption)

**Milestones:**
- [ ] M14: Switch to GC futures (CQG feed with Bid/Ask volume)
- [ ] M15: Delta calculation (M5 footprint analysis)
- [ ] M16: Delta divergence detector
- [ ] M17: Full quad scoring (EW + VP + SMC + OF)
- [ ] M18: Backtest with all filters
- [ ] M19: Targets met OR strategic pivot

---

## 📈 Performance Tracking Template

### Iteration X: [EA Name]

**Date:** YYYY-MM-DD  
**EA Version:** vX.X  
**Strategy:** [Brief description]  
**Config:** [Symbol, Period, Date range, Deposit]

**Results:**
- Win Rate: X.X% (Target: 90%)
- Risk:Reward: 1:X (Target: 1:2)
- Trades/Day: X.X (Target: 10)
- Max DD: X.X% (Target: <10%)
- Total Trades: XXX
- Profit Factor: X.X
- Sharpe Ratio: X.X

**Pattern Analysis:**
- Best Pattern: [Pattern type] (XX% WR, XX trades)
- Worst Pattern: [Pattern type] (XX% WR, XX trades)
- Most Frequent: [Pattern type] (XX% of trades)

**Root Cause (if targets missed):**
- [Why did we miss WR target?]
- [Why did we miss frequency target?]
- [What patterns failed most?]

**Decision:**
- [ ] Optimize parameters (specify changes)
- [ ] Add filters (specify which)
- [ ] Pivot strategy
- [ ] Targets met → Forward test

**Next Task:** [OPTIMIZATION_TASK.md filename or "DONE"]

---

## 🎯 Current Focus

**Phase:** 1 (SMC Baseline)
**Iteration:** 0 DONE → 1 Next (SMC Baseline)
**Blocker:** None
**Next Action:** Launch full 6-agent pipeline for Iteration 1 (Researcher → PM → Technical → Reviewer → Coder → Backtester)

**Timeline:**
- Iteration 0 (Simple EA): 1 day
- Iteration 1 (SMC EA): 2-3 days (including backtest time)
- Optimization cycles: 1-2 days per iteration
- **Estimated:** 1-2 weeks to Phase 1 completion (targets met or pivot decision)

---

## 🚦 Status Definitions

- ⏳ **Pending:** Not started yet
- 🔄 **In Progress:** Currently working on
- ✅ **Complete:** Finished and validated
- ❌ **Failed:** Did not meet target (root cause documented)
- 🔀 **Pivoted:** Changed strategy based on data

---

## 🎯 Success Criteria (Final)

**System is READY FOR LIVE when:**
1. ✅ Win Rate ≥ 90% (on 1+ year backtest)
2. ✅ Risk:Reward ≥ 1:2 (average across all trades)
3. ✅ Trades/Day ≥ 10 (consistent frequency)
4. ✅ Max DD < 10% (capital protection)
5. ✅ Forward test (demo) validates backtest results (1 month minimum)
6. ✅ Boss approval

**DO NOT GO LIVE** until ALL 6 criteria met.

---

**Next Update:** After Iteration 0 completion (Simple EA backtest results)
