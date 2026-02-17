# Implementation Plan: AdvancedEA v2.00 (4-Layer SMC Architecture + DCA)

**Created:** 2026-02-17
**Updated:** 2026-02-17
**Author:** PM Agent (Iteration 1 Pipeline)
**Status:** PENDING REVIEW
**Target EA:** AdvancedEA v2.00
**Instrument:** XAUUSD M5

---

## Context

Iteration 0 (SimpleEA) validated the full workflow: compile -> backtest -> CSV export -> analysis.
- Result: 26.43% WR, 10.6 trades/day, -$802 profit, 8.19% DD
- Conclusion: Pipeline works. MA crossover baseline is not viable. Now build real SMC system.

AdvancedEA v1.00 (current code in `code/experts/AdvancedEA.mq5`) has core detector classes implemented but needs restructuring into a proper 4-layer architecture with DCA enabled and enhanced analytics.

**Research Sources Consumed:**
- `brain/strategy_research.md` -- SMC/ICT methodology, quad-methodology design, phased strategy
- `brain/advanced_smc_research.md` -- Detailed MQL5 algorithms for OB, FVG, BOS, Sweep, MTF, scoring
- `brain/design_decisions.md` -- 16 approved architectural/parameter decisions (D1-D16)
- `brain/targets.md` -- Performance targets, milestone roadmap
- `skills/technical-analyst/SKILL.md` -- Confluence Framework (Elliott Wave + Wyckoff + Fibonacci, 0-10)
- `code/experts/AdvancedEA.mq5` -- Existing v1.00 implementation (1411 lines)

---

## Performance Targets (Non-Negotiable)

| Metric | Target | Stretch | Measurement |
|--------|--------|---------|-------------|
| Win Rate | >= 80% | 90% | Profit trades / Total trades |
| Net Profit | >= $80,000 | $100,000+ | Final balance - Initial balance (on $10,000 deposit over 3 years) |
| Max Drawdown | < 10% | < 8% | Peak-to-trough equity |
| Risk:Reward | >= 1:2 | 1:3 | Average winner / Average loser |
| Trades/Day | >= 10 | 15+ | Total trades / Trading days |

**ALL FIVE must be met simultaneously.**

---

## 4-Layer Architecture Overview

```
┌─────────────────────────────────────────────────┐
│           LAYER 0: RISK GATE (Pre-Check)        │
│  Daily MDD check | Session filter | Max pos     │
│  MUST PASS before any detection runs            │
├─────────────────────────────────────────────────┤
│           LAYER 1: DETECTION ENGINE             │
│  BOS | Sweep | OB | FVG | MTF Bias             │
│  Confluence Scorer (score >= 100)               │
│  Signal Paths: A (BOS+POI) or B (Sweep+POI)    │
├─────────────────────────────────────────────────┤
│           LAYER 2: EXECUTION & DCA              │
│  Position sizing (0.5% risk) | SL/TP placement  │
│  DCA Level 0/1/2 | Breakeven | Trailing stop    │
├─────────────────────────────────────────────────┤
│           LAYER 3: ANALYTICS & EXPORT           │
│  Trade classification | Score tracking          │
│  OnTester() CSV export | Pattern breakdown      │
└─────────────────────────────────────────────────┘
```

**Data Flow:**
```
OnTick() → Layer 0 (pass/fail) → Layer 1 (detect+score) → Layer 2 (execute+manage) → Layer 3 (log+export)
```

---

## Milestone 1: Layer 0 -- Risk Gate

**Goal:** Pre-flight checks that MUST pass before any detection or trading occurs. This is the circuit breaker layer that protects capital.

### Deliverables

1. **Daily MDD Circuit Breaker**
   - Track daily start balance (reset at 00:00 server time)
   - Calculate real-time drawdown: `(startBalance - currentEquity) / startBalance * 100`
   - Halt ALL trading when MDD >= 8% (configurable via `inp_DailyMddMax`)
   - Close all open positions on halt
   - Resume next trading day only

2. **Session Filter**
   - Default: 07:00 - 23:00 GMT+7 (Decision D13)
   - Input parameters: `inp_SessionStartHour`, `inp_SessionEndHour`
   - Skip OnTick processing outside session hours
   - Allow disabling session filter for initial backtesting (`inp_UseSessionFilter = false`)

3. **Maximum Position Check**
   - Max simultaneous positions: 1 for baseline (`inp_MaxPositions = 1`)
   - When DCA enabled: max positions = 3 (original + 2 DCA additions)
   - Check PositionsTotal() before any new entry

4. **Dynamic Lot Size Validation**
   - Verify lot size within broker limits (SYMBOL_VOLUME_MIN, SYMBOL_VOLUME_MAX)
   - Verify sufficient margin for proposed trade
   - Reject trade if lot calculation returns 0 or negative

### Acceptance Criteria
- [ ] Trading halts when daily MDD >= 8% and resumes next day
- [ ] No trades placed outside session hours (when filter enabled)
- [ ] No new positions opened when max positions reached
- [ ] Lot validation prevents invalid orders
- [ ] All gate failures logged with reason: `"GATE:MDD"`, `"GATE:SESSION"`, `"GATE:MAXPOS"`, `"GATE:LOT"`

---

## Milestone 2: Layer 1 -- Detection Engine (PA + Confluence)

**Goal:** 5 SMC pattern detectors + confluence scorer that generates entry signals with a score >= 100.

### Deliverables

1. **Break of Structure (BOS) Detector** -- `CBOSDetector`
   - Swing high/low identification (fractal-based, K=5 left/right bars)
   - Bullish BOS: close breaks above previous swing high with momentum
   - Bearish BOS: close breaks below previous swing low with momentum
   - Momentum confirmation: candle body >= 0.5 ATR (Decision D14)
   - Minimum break distance: 150 points (XAUUSD noise filter)
   - BOS retest detection: price returns to broken level within tolerance (150 pts)
   - TTL: 60 bars (BOS expires after 60 bars without entry)
   - Scoring: BOS +30 pts, BOS+Retest +50 pts (replaces +30)

2. **Order Block (OB) Detector** -- `COrderBlockDetector`
   - Bullish OB: last bearish candle before strong bullish move (3-candle validation, move >= 1.5 ATR)
   - Bearish OB: last bullish candle before strong bearish move
   - Strength scoring (0-10): base 8, age penalty (-1 to -3), touch penalty (-1 to -3)
   - Storage: 1 active bullish + 1 active bearish OB (most recent wins)
   - Invalidation: age > 100 bars OR touched >= 3 times
   - Scoring: Strong OB (>= 7) +20 pts, Weak OB (4-6) +10 pts, Very Weak (<= 3) -10 pts

3. **Fair Value Gap (FVG) Detector** -- `CFVGDetector`
   - Bullish FVG: gap between bar[i+2].high and bar[i].low during upward move
   - Bearish FVG: gap between bar[i+2].low and bar[i].high during downward move
   - Minimum gap size: max(0.3 ATR, 100 points)
   - Maximum gap size: 2.0 ATR
   - Fill tracking: 0-100% (invalidate at >= 85% filled)
   - TTL: 80 bars
   - Scoring: FVG present +15 pts

4. **Liquidity Sweep Detector** -- `CSweepDetector`
   - Lookback: 40 bars for recent swing highs/lows
   - Penetration range: 0.1-0.3 ATR beyond swing level
   - Rejection confirmation: close back inside prior range
   - Wick ratio validation: >= 40% of candle range (configurable)
   - TTL: 50 bars
   - Scoring: Sweep +25 pts

5. **Multi-Timeframe (MTF) Bias Analyzer** -- `CMTFBiasAnalyzer`
   - H1 trend: EMA(20) vs EMA(50)
   - H4 trend: EMA(20) vs EMA(50)
   - Bias states: BULLISH (both agree up), BEARISH (both agree down), NEUTRAL (mixed)
   - Scoring: Aligned +20 pts, Neutral 0 pts, Counter-trend -30 pts

6. **Confluence Scorer** -- `CConfluenceScorer`
   - Scoring table:

   | Component | Points | Condition |
   |-----------|--------|-----------|
   | BOS | +30 | Break of Structure detected |
   | BOS + Retest | +50 | BOS with pullback (replaces +30) |
   | Liquidity Sweep | +25 | Sweep confirmed |
   | Strong OB (>= 7) | +20 | Order Block at entry zone |
   | Weak OB (4-6) | +10 | Weaker Order Block |
   | FVG | +15 | Fair Value Gap at entry |
   | MTF Aligned | +20 | H1+H4 agree with direction |
   | Momentum Candle | +10 | Trigger candle body >= 0.30 ATR |
   | Counter-trend | -30 | Against H1/H4 bias |
   | Very Weak OB (<= 3) | -10 | Poor quality OB |
   | Low R:R (< 1.5) | -20 | Insufficient reward |
   | Touched OB | x0.5 | OB already tested (multiply final) |

   - Entry threshold: >= 100 points (configurable: `inp_MinSMCScore`)
   - Signal paths:
     - **Path A (Preferred):** BOS/BOS-Retest + POI (OB or FVG) + MTF -> score check
     - **Path B:** Sweep + POI + Momentum (when no BOS) -> score check
   - Trigger candle: bullish/bearish candle body >= 0.30 ATR within last 4 bars (Decision D14)

### Acceptance Criteria
- [ ] All 5 detectors compile without errors or warnings
- [ ] Each detector generates signals on historical M5 XAUUSD data (2023-2025)
- [ ] BOS correctly identifies swing breaks with momentum confirmation
- [ ] OB strength decays with age and touch count
- [ ] FVG fill tracking works (0-100%, invalidates at 85%)
- [ ] MTF analyzer reads H1/H4 data correctly from M5 chart
- [ ] Scorer produces correct totals per scoring table
- [ ] Only Path A or Path B signals generate entries (not random combinations)
- [ ] Score logged in trade comment: `"SMC:XXX|BOS:Y|RT:Y|SW:Y|OB:Y|FVG:Y|MTF:Y"`

---

## Milestone 3: Layer 2 -- Execution & DCA Position Management

**Goal:** Entry execution, position sizing, DCA scaling, breakeven, and trailing stop management.

### Deliverables

1. **Position Sizing** (Decision D7)
   - Risk per trade: 0.5% of account balance (`inp_RiskPct = 0.5`)
   - Lot calculation: `(Balance * 0.005) / (SL_Distance_Points * Tick_Value / Tick_Size)`
   - Max lot: 3.0 hard cap (`inp_MaxLot = 3.0`)
   - Lot step normalization: round down to broker's lot step

2. **SL/TP Placement**
   - SL: Below/above OB zone + 2.0 ATR buffer (or structure-based)
   - TP: Next structure target (swing high/low) with min R:R = 2.0 (Decision D11)
   - If R:R < 2.0: skip trade entirely (don't reduce TP)

3. **DCA Strategy (ENABLED)** (Decisions D7, D8)

   | DCA Level | Trigger | Position Size | Cumulative |
   |-----------|---------|---------------|------------|
   | Level 0 (Original) | Confluence signal (score >= 100) | 100% of calculated lot | 100% |
   | Level 1 | Profit reaches +0.75R | 50% of original lot | 150% |
   | Level 2 | Profit reaches +1.5R | 33% of original lot | 183% |

   - **R = ORIGINAL SL distance** (fixed reference, doesn't change when BE moves)
   - DCA only when IN PROFIT (never average down) (Decision D8)
   - Total lot enforcement: sum of all positions < `inp_MaxLot` (3.0)
   - DCA counter: max 2 additions per trade (`inp_MaxDCA = 2`)
   - Each DCA position gets same SL as original (updated to BE if BE already triggered)
   - Each DCA position gets same TP as original
   - Input parameter: `inp_EnableDCA = true` (enabled by default for v2.00)

4. **Breakeven Management** (Decision D9)
   - Trigger: profit >= +1.0R (original SL distance)
   - Action: Move SL to entry price for ALL same-direction positions
   - Buffer: entry + spread (to avoid premature BE trigger)
   - Once at BE: position is risk-free

5. **Trailing Stop** (after BE)
   - Activation: after breakeven triggered
   - Step: every 0.5R of additional profit
   - Trail method: move SL up/down by 0.5R increments
   - Input parameter: `inp_EnableTrailing = true`
   - Input parameter: `inp_TrailStep_R = 0.5` (trail step in R multiples)

### Acceptance Criteria
- [ ] Position size never exceeds 0.5% risk per trade
- [ ] Lot size never exceeds 3.0 (total across all DCA positions)
- [ ] R:R >= 2.0 enforced before entry (skip if insufficient)
- [ ] DCA Level 1 triggers at exactly +0.75R with 50% lot
- [ ] DCA Level 2 triggers at exactly +1.5R with 33% lot
- [ ] DCA only adds when position is in profit (never when losing)
- [ ] Breakeven triggers at +1.0R and moves ALL same-side positions
- [ ] Trailing stop advances in 0.5R steps after BE
- [ ] Trade comment includes DCA status: `"DCA:0/2"`, `"DCA:1/2"`, `"DCA:2/2"`

---

## Milestone 4: Layer 3 -- Analytics & Enhanced Metrics

**Goal:** Comprehensive trade logging, score tracking, and OnTester() CSV export for data-driven iteration.

### Deliverables

1. **Trade Classification Tags**
   - Every trade tagged in comment with full signal components
   - Format: `"SMC:120|BOS:1|RT:0|SW:1|OB:1|FVG:0|MTF:1|DCA:0/2"`
   - Exit reason tracking: TP hit, SL hit, BE hit, Trail stop, MDD halt, Manual

2. **OnTester() CSV Export** (Decision D5)
   - File: `AdvancedEA_backtest_YYYY.MM.DD.csv`
   - Flag: `FILE_WRITE | FILE_CSV | FILE_COMMON | FILE_ANSI`
   - **Metrics (30+ columns):**

   **Standard Metrics (19):**
   - Total Trades, Profit Trades, Loss Trades
   - Win Rate %, Gross Profit, Gross Loss, Net Profit
   - Profit Factor, Sharpe Ratio, Recovery Factor
   - Max DD %, Max DD $, Expected Payoff
   - Avg Win $, Avg Loss $, Risk:Reward Ratio
   - Max Consecutive Wins, Max Consecutive Losses
   - Total Deals

   **Balance Tracking (4):**
   - Initial Balance, Final Balance, Max Balance, Min Balance

   **SMC-Specific (7+):**
   - Avg SMC Score (all trades)
   - Avg SMC Score (winners only)
   - Avg SMC Score (losers only)
   - Score Distribution: trades scoring 100-119, 120-149, 150-199, 200+
   - Pattern Breakdown: BOS-only count, Sweep-only count, BOS+Sweep count

   **DCA Metrics (4):**
   - Trades with DCA Level 1 triggered
   - Trades with DCA Level 2 triggered
   - Avg profit of DCA trades vs non-DCA trades
   - Total DCA additions

3. **Trade-by-Trade Journal** (in-memory, exported via OnTester)
   - Entry time, exit time, direction
   - Entry price, SL, TP, actual exit price
   - Confluence score and component flags
   - DCA levels triggered
   - Exit reason (TP/SL/BE/Trail/MDD)
   - P&L in dollars and R-multiples

### Acceptance Criteria
- [ ] CSV contains all 30+ metrics
- [ ] CSV uses FILE_COMMON flag (accessible outside Wine sandbox)
- [ ] CSV uses FILE_ANSI encoding (readable without conversion)
- [ ] Backtest completes on 3-year date range (2023-2025) without timeout
- [ ] Score distribution enables Backtester to analyze which score ranges perform best
- [ ] DCA metrics distinguish DCA vs non-DCA trade performance
- [ ] Pattern breakdown shows which signal paths (A vs B) perform best

---

## Milestone 5: Integration Testing

**Goal:** Verify all 4 layers work together correctly end-to-end.

### Deliverables

1. **End-to-End Backtest**
   - Config: XAUUSD, M5, 2023.01.01 to 2025.12.31, $10,000 deposit
   - Model: Every tick based on real ticks (Model=1) or Open prices (Model=0) for speed
   - Verify: EA compiles, runs full backtest, produces CSV with all metrics

2. **Layer Integration Verification**
   - Layer 0 -> Layer 1: Risk gate blocks detection when MDD exceeded
   - Layer 1 -> Layer 2: Only scored signals (>= 100) reach execution
   - Layer 2 -> Layer 3: All trades logged with full component tags
   - DCA flow: original entry -> +0.75R DCA1 -> +1.0R BE -> +1.5R DCA2 -> trail

3. **Edge Case Testing**
   - MDD halt mid-trade (existing position + halt + no new entries)
   - DCA at max lot (original + DCA1 would exceed 3.0 -> skip DCA1)
   - Session boundary (open trade at session end -> manage but no new entries)
   - No signal day (zero trades -> CSV still exports with 0 values)
   - Rapid reversal (BOS detected, immediately reversed -> score check prevents entry)

4. **Backtest Configuration**
   ```ini
   [Tester]
   Expert=AdvancedEA
   Symbol=XAUUSD
   Period=5
   Model=1
   Optimization=0
   FromDate=2023.01.01
   ToDate=2025.12.31
   Deposit=10000
   Currency=USD
   Leverage=100
   Visual=0
   ShutdownTerminal=0
   Login=<existing>
   Server=<existing>
   ```

### Acceptance Criteria
- [ ] EA compiles with 0 errors, 0 warnings
- [ ] Backtest completes on 3-year date range without crash or timeout
- [ ] CSV exported with all 30+ metrics populated
- [ ] Layer 0 correctly blocks trading during MDD breach
- [ ] DCA levels trigger at correct R-multiples (+0.75R, +1.5R)
- [ ] Breakeven triggers at +1.0R for all same-side positions
- [ ] Trailing stop advances in 0.5R steps
- [ ] Trade comments contain all signal component flags
- [ ] Score distribution shows trades across multiple score ranges

---

## File Structure & Module Organization

```
code/experts/
  AdvancedEA.mq5          -- Main EA file (all layers in single file for MQL5 simplicity)

Internal Class Organization (within AdvancedEA.mq5):
  // Layer 0: Risk Gate
  class CRiskGate           -- MDD check, session filter, max positions, lot validation

  // Layer 1: Detection
  class CBOSDetector         -- Break of Structure detection
  class CSweepDetector       -- Liquidity Sweep detection
  class COrderBlockDetector  -- Order Block detection + strength scoring
  class CFVGDetector         -- Fair Value Gap detection + fill tracking
  class CMTFBiasAnalyzer     -- Multi-timeframe trend bias (H1/H4)
  class CConfluenceScorer    -- Score calculation from all detectors

  // Layer 2: Execution
  class CPositionManager     -- Entry execution, lot sizing, SL/TP placement
  class CDCAManager          -- DCA level tracking, addition logic
  class CTradeManager        -- Breakeven, trailing stop management

  // Layer 3: Analytics
  class CTradeLogger         -- Trade classification, score tracking
  class CCSVExporter         -- OnTester() CSV generation

  // Structs
  struct SwingPoint          -- Swing high/low data
  struct BOSSignal           -- BOS detection result
  struct SweepSignal         -- Sweep detection result
  struct OrderBlock          -- OB zone data
  struct FVGSignal           -- FVG zone data
  struct SetupCandidate      -- Combined signal for scoring
  struct TradeRecord         -- Trade journal entry
```

**Note:** MQL5 doesn't support multi-file includes easily in Wine/macOS. Keep all code in a single .mq5 file to avoid path resolution issues (learned from Iteration 0 experience).

---

## DCA Strategy Summary

```
Timeline of a winning trade with DCA:

  Entry ────────────── +0.75R ──── +1.0R ──── +1.5R ──── +2.0R (TP)
    │                     │          │          │          │
    │                     │          │          │          └── TP hit (all positions close)
    │                     │          │          │
    │                     │          │          └── DCA Level 2: add 0.33x lot
    │                     │          │
    │                     │          └── BREAKEVEN: move all SL to entry
    │                     │
    │                     └── DCA Level 1: add 0.50x lot
    │
    └── Level 0 (Original): entry at confluence signal (1.0x lot)

  Trailing: After BE, trail every +0.5R
    +1.0R: SL → entry
    +1.5R: SL → entry + 0.5R
    +2.0R: SL → entry + 1.0R
    ... continues until TP or trail stop hit
```

**DCA Position Summary:**

| Level | Trigger | Lot Size | SL | TP |
|-------|---------|----------|----|----|
| 0 (Original) | Score >= 100 | 1.0x calculated | Structure-based | R:R >= 2.0 target |
| 1 | +0.75R profit | 0.5x original | Same as original (or BE) | Same as original |
| 2 | +1.5R profit | 0.33x original | Same as original (or BE) | Same as original |

---

## Risk Management Rules Summary

| Rule | Value | Source |
|------|-------|--------|
| Risk per trade | 0.5% of balance | Decision D7 |
| Max lot (total) | 3.0 | Decision D7 |
| Daily MDD halt | 8% | Decision D12 |
| Min R:R for entry | 2.0 | Decision D11 |
| Breakeven trigger | +1.0R | Decision D9 |
| DCA direction | Profit only (never average down) | Decision D8 |
| Score threshold | 100 (tuneable) | Decision D6 |
| Session hours | 07:00-23:00 GMT+7 (tuneable) | Decision D13 |
| Max positions | 1 base + 2 DCA = 3 max | New |

---

## Guardrails

### Must Have
- OnTester() CSV export with FILE_COMMON flag (mandatory, Decision D5)
- Score threshold as input parameter (tuneable without recompile)
- All 16 approved design decisions (D1-D16) respected
- 0.5% risk per trade, 8% daily MDD circuit breaker
- MTF bias check (H1 + H4)
- DCA enabled by default with proper R-based triggers
- Expert=AdvancedEA in config (name only, no path, Decision D10)
- Trigger candle confirmation (Decision D14)

### Must NOT Have
- No Order Flow (blocked on MT5 XAUUSD -- no bid/ask volume data)
- No ML/AI components (out of scope)
- No multi-symbol support (XAUUSD only)
- No averaging down (DCA only when profitable, Decision D8)
- No live trading logic (backtest-only for this iteration)

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Too few signals (< 10/day) | Missed trade target | Lower score threshold (100 -> 90), widen OB/FVG zones |
| Too many signals (noise) | Low win rate | Raise score threshold (100 -> 120), enable strict MTF filter |
| DCA increases drawdown | Higher DD | DCA only in profit, max 3 positions, 3.0 lot cap |
| Backtest overfitting | Live differs | Walk-forward: train 2023-2024, validate 2025 |
| Complex code = compile errors | Delays | Build incrementally (layer by layer), test after each |
| MQL5 memory limits | Runtime crash | Limit OB/FVG storage, cleanup on every bar |
| Trailing stop whipsaws | Premature exit | 0.5R step provides buffer; can widen if needed |

---

## Task Flow (Agent Pipeline)

```
PM (this plan)
  -> Technical Analyst: Convert to CODER_TASK.md (exact MQL5 specs per layer)
  -> Reviewer: Validate plan + specs (quality gate)
  -> Coder: Implement AdvancedEA.mq5 v2.00 (all 4 layers)
  -> Backtester: Analyze results, classify trades, identify root causes
  -> Lead (Em): Decision -- optimize, iterate, or pivot
```

---

## Success Criteria (Plan Approval)

This plan is approved when:
1. Technical Analyst can write CODER_TASK.md without ambiguity for each layer
2. Reviewer confirms all 16 design decisions are respected
3. Coder has clear acceptance criteria for every milestone
4. DCA parameters are specific and testable (+0.75R, +1.5R triggers)
5. Backtester knows what metrics to analyze (SMC scores, DCA performance, pattern breakdown)
6. Lead can make data-driven iteration decisions from CSV output

---

**Next Action:** Technical Analyst reads this plan -> creates `tasks/CODER_TASK.md`
