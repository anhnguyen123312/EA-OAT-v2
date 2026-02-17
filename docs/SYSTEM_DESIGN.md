# EA-OAT v2 System Design Document

**Version:** 2.0  
**Last Updated:** 2026-02-16  
**Status:** Phase 1 - Baseline Architecture  
**Author:** Em (Manager)

---

## 📋 Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Overview](#system-overview)
3. [Architecture](#architecture)
4. [Trading Strategy](#trading-strategy)
5. [Workflow](#workflow)
6. [Data Flow](#data-flow)
7. [Component Specifications](#component-specifications)
8. [Configuration](#configuration)
9. [Testing & Validation](#testing--validation)
10. [Deployment](#deployment)

---

## 🎯 Executive Summary

**Mission:** Build automated XAUUSD trading system achieving 90% Win Rate, 1:2 Risk:Reward, 10+ trades/day, <10% Max Drawdown

**Approach:** Iterative dual-agent development (Em = Manager/Brain, Coder = Worker/Hands) with Git-based coordination

**Phase 1:** SMC/ICT methodology baseline (BOS, Sweep, Order Block, FVG, Momentum scoring)

**Phase 2 (If Needed):** Add Elliott Wave (macro bias) + Volume Profile (key levels) filters

**Phase 3 (If Needed):** Add Order Flow (delta confirmation) on GC futures

**Platform:** MetaTrader 5 (MT5) on macOS via Wine

**Instrument:** XAUUSD (Spot Gold)

**Timeframe:** M5 (primary execution), H1/H4 (multi-timeframe bias)

---

## 🏗️ System Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      EA-OAT v2 System                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐          ┌──────────────┐                │
│  │   Gateway    │          │   Node       │                │
│  │   (Máy A)    │          │   (Máy B)    │                │
│  │              │          │              │                │
│  │  EM MANAGER  │◄────────►│    CODER     │                │
│  │              │   Git    │              │                │
│  │  - Research  │          │  - Implement │                │
│  │  - Design    │          │  - Compile   │                │
│  │  - Analyze   │          │  - Backtest  │                │
│  │  - Decide    │          │  - Report    │                │
│  └──────────────┘          └──────────────┘                │
│         │                         │                         │
│         │ brain/                  │ experience/             │
│         │ - strategy              │ - compile_issues        │
│         │ - optimization          │ - mql5_patterns         │
│         │ - decisions             │ - wine_quirks           │
│         │ - targets               │ - backtest_setup        │
│         │                         │                         │
│         └─────────┬───────────────┘                         │
│                   │                                         │
│                   ▼                                         │
│          ┌────────────────┐                                 │
│          │   Git Repo     │                                 │
│          │                │                                 │
│          │  tasks/        │◄─── Source of Truth            │
│          │  code/         │                                 │
│          │  results/      │                                 │
│          │  config/       │                                 │
│          │  brain/        │                                 │
│          │  experience/   │                                 │
│          └────────────────┘                                 │
│                   │                                         │
│                   ▼                                         │
│          ┌────────────────┐                                 │
│          │   MT5 Tester   │                                 │
│          │   (Wine/macOS) │                                 │
│          │                │                                 │
│          │  - Backtests   │                                 │
│          │  - CSV Export  │                                 │
│          └────────────────┘                                 │
│                   │                                         │
│                   ▼                                         │
│          ┌────────────────┐                                 │
│          │   Telegram     │                                 │
│          │   Reports      │                                 │
│          └────────────────┘                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

1. **Em (Manager)** - Strategic brain, runs on Gateway
2. **Coder (Worker)** - Implementation hands, runs on Node with MT5
3. **Git Repo** - Version control and coordination hub
4. **MT5 Tester** - Backtesting engine (Wine on macOS)
5. **Telegram** - Status reporting and alerts

---

## 🧠 Architecture

### Dual-Agent System

#### Em (Manager) - Gateway Brain

**Role:** Think, Research, Design, Analyze, Decide

**Responsibilities:**
- Research trading methodologies (SMC, EW, VP, OF)
- Design EA logic (entry/exit rules, scoring, parameters)
- Analyze backtest results (CSV parsing, root cause analysis)
- Solve problems independently (why WR < 90%? research solutions)
- Write task specifications (CODER_TASK.md, OPTIMIZATION_TASK.md)
- Track iteration history (optimization_log.md)

**Knowledge Base:**
- `brain/strategy_research.md` - Trading methods researched
- `brain/optimization_log.md` - Iteration history
- `brain/design_decisions.md` - Architecture choices
- `brain/targets.md` - Progress tracker

**Does NOT:**
- Write .mq5 code directly
- Compile or run MT5
- Make implementation decisions (e.g., which MQL5 function to use)

---

#### Coder (Worker) - Node Hands

**Role:** Execute, Implement, Compile, Backtest, Report

**Responsibilities:**
- Implement EA per Em's specifications (CODER_TASK.md)
- Compile .mq5 files (handle compile errors)
- Run MT5 backtests (automated via .ini config)
- Export results to CSV (OnTester() function)
- Report status to Telegram (when done)
- Document technical issues (experience/)

**Knowledge Base:**
- `experience/compile_issues.md` - MQL5 compilation errors & fixes
- `experience/mql5_patterns.md` - Reusable code snippets
- `experience/wine_quirks.md` - macOS/Wine specific issues
- `experience/backtest_setup.md` - MT5 config gotchas

**Does NOT:**
- Design trading strategy
- Analyze backtest results
- Decide parameter values
- Make strategic decisions

---

### Git-Based Coordination

**Repo Structure:**
```
EA-OAT-v2/
├── brain/              ← Em's knowledge (strategy, decisions, targets)
├── experience/         ← Coder's knowledge (technical issues, patterns)
├── tasks/              ← Task files (Em writes, Coder reads)
│   ├── CODER_TASK.md
│   ├── OPTIMIZATION_TASK.md
│   └── archive/        ← Completed tasks
├── code/               ← Source code (Coder writes)
│   ├── experts/        ← EA .mq5 files
│   ├── include/        ← Shared libraries .mqh
│   └── indicators/     ← Custom indicators
├── config/             ← Backtest configurations
│   ├── templates/      ← Reusable .ini templates
│   └── active/         ← Current configs
├── results/            ← Backtest outputs (Coder writes, Em reads)
│   ├── YYYY-MM-DD_EAName_Symbol_Period.csv
│   └── logs/           ← MT5 tester logs
├── docs/               ← Documentation (this file, etc.)
└── skills/             ← Skill files for claude code
    ├── em-manager/
    └── coder-worker/
```

**Workflow:**
```
Em:    git pull → read brain/ + experience/ → research/design → write CODER_TASK.md → git push → node.invoke(Coder)
Coder: git pull → read brain/ + experience/ + tasks/ → implement → compile → backtest → save results/ → git push → Telegram: "✅ Done"
Em:    git pull → read results/CSV → analyze → targets met? → NO: write OPTIMIZATION_TASK.md → loop | YES: "🎯 DONE" → @Boss
```

---

## 📈 Trading Strategy

### Phase 1: SMC/ICT Baseline

**Methodology:** Smart Money Concepts (Break of Structure, Liquidity Sweep, Order Block, Fair Value Gap, Momentum)

**Instrument:** XAUUSD (Spot Gold)

**Timeframe:** M5 (execution), H1/H4 (bias)

**Entry Paths:**
- **Path A (Preferred):** BOS + POI (Order Block OR Fair Value Gap)
- **Path B:** Sweep + POI + Momentum (when no BOS)

**Scoring System:**
```
Base:        +100  (BOS + POI)
Bonuses:     +30   (BOS)
             +25   (Sweep)
             +20   (OB)
             +15   (FVG valid)
             +20   (MTF aligned)
             +10   (Strong OB)
             +10   (RR ≥ 2.5)
Penalties:   -30   (Counter-trend)
             -10   (Weak OB)
             ×0.5  (Touched OB ≥3)

Entry Threshold: TOTAL ≥ 100
```

**Entry Conditions (ALL must be true):**
1. ✅ Candidate valid (Path A or B)
2. ✅ Score ≥ 100
3. ✅ Momentum NOT against SMC
4. ✅ Session open (07:00-23:00 GMT+7)
5. ✅ Spread OK (< MaxSpread)
6. ✅ Trigger candle (bullish/bearish body ≥ 0.30 ATR)
7. ✅ RR ≥ MinRR (2.0)
8. ✅ Daily MDD < 8%

**Risk Management:**
- Risk per trade: 0.5% (default)
- Position sizing: `Lots = (Balance × Risk%) / (SL_Distance × Value_Per_Point)`
- Max lot: 3.0 (hard cap)
- DCA triggers: +0.75R (add 0.5× lot), +1.5R (add 0.33× lot)
- Breakeven: +1R profit → move SL to entry
- Daily MDD: 8% → close all, halt until next day

**Exit Rules:**
- Take Profit: Structure-based (swing/OB/FVG target) or Entry + (Risk × MinRR)
- Stop Loss: Structure-based (Sweep/OB/FVG) + ATR, min 1000 points
- Trailing: Start at +1R, step +0.5R, distance 2× ATR

---

### Phase 2: EW + VP Integration (If Phase 1 Fails)

**Trigger:** Phase 1 WR < 90% after 5+ optimization iterations

**Additions:**
- **Elliott Wave (H4/D1):** Macro bias (only take SMC signals aligned with impulse wave direction)
- **Volume Profile (H1):** Key levels (POC, VAH, VAL) as confluence zones

**Updated Scoring:**
```
TOTAL = (EW × 0.25) + (VP × 0.35) + (SMC × 0.40)
Entry: TOTAL ≥ 60
```

**Expected Impact:**
- Fewer trades (8-15/day) but higher WR (85-90%)
- Reduced counter-trend false positives

---

### Phase 3: Order Flow (Futures Only, If Phase 2 Fails)

**Trigger:** Phase 2 WR < 90% AND access to GC futures (CQG Level 2 data)

**Additions:**
- **Delta Analysis (M5):** ASK - BID volume per bar
- **Cumulative Delta (CVD):** Running sum of delta
- **Delta Divergence:** Price new high but delta doesn't = exhaustion
- **Absorption:** Large passive orders stopping price = reversal

**Full Quad Scoring:**
```
TOTAL = (EW × 0.20) + (VP × 0.30) + (SMC × 0.30) + (OF × 0.20)
Entry: TOTAL ≥ 60
```

**Platform Change:** Switch to GC futures (CME) via MT5 + CQG feed

---

## ⚙️ Workflow

### Iteration Loop

```
┌─────────────────────────────────────────────────────────┐
│                   ITERATION LOOP                        │
│                                                         │
│  1. Em: git pull                                        │
│     └─ Read brain/ + experience/ (refresh context)     │
│                                                         │
│  2. Em: Research & Design                               │
│     ├─ If Iteration 0: Design baseline EA              │
│     ├─ If Iteration N: Analyze previous CSV            │
│     │  ├─ Root cause: Why WR < 90%?                    │
│     │  ├─ Pattern analysis: Which setups failed?       │
│     │  └─ Research: How to fix this problem?           │
│     └─ Design solution                                  │
│                                                         │
│  3. Em: Write Task Spec                                 │
│     ├─ CODER_TASK.md (new EA) OR                       │
│     └─ OPTIMIZATION_TASK.md (improve EA)               │
│                                                         │
│  4. Em: git add + commit + push                         │
│                                                         │
│  5. Em: node.invoke(Coder)                              │
│     └─ Trigger Coder to start work                     │
│                                                         │
│  6. Coder: git pull                                     │
│     └─ Read brain/ + experience/ + tasks/              │
│                                                         │
│  7. Coder: Implement                                    │
│     ├─ Write/modify .mq5 code per spec                 │
│     ├─ Compile (fix errors if any)                     │
│     └─ Update experience/ (technical lessons)          │
│                                                         │
│  8. Coder: Backtest                                     │
│     ├─ Create .ini config                              │
│     ├─ Run MT5 tester (Wine)                           │
│     ├─ Wait for completion                             │
│     └─ Collect CSV + logs                              │
│                                                         │
│  9. Coder: git add + commit + push                      │
│     └─ Push code + results/ + experience/              │
│                                                         │
│ 10. Coder: Telegram report                              │
│     └─ "✅ CODER REPORT: Task complete, CSV pushed"    │
│                                                         │
│ 11. Em: git pull                                        │
│     └─ Fetch latest code + results/                    │
│                                                         │
│ 12. Em: Analyze CSV                                     │
│     ├─ Parse metrics (WR, RR, trades/day, DD)          │
│     ├─ Pattern breakdown (which signals won/lost)      │
│     ├─ Root cause analysis (if targets missed)         │
│     └─ Update brain/optimization_log.md                │
│                                                         │
│ 13. Em: Decision                                        │
│     ├─ ALL targets met? → "🎯 DONE" → Forward test     │
│     ├─ Targets missed? → Research → OPTIMIZATION_TASK  │
│     └─ Stuck (10+ iterations)? → Pivot or ask Boss     │
│                                                         │
│ 14. REPEAT (Step 3) until targets met                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Data Flow

### Input Data Sources

1. **OHLC Data:**
   - Source: MT5 XAUUSD historical data
   - Timeframes: M5 (primary), H1, H4 (MTF bias)
   - Period: 1-2 years for backtest validation

2. **Volume Data (Phase 2):**
   - Source: MT5 tick volume (approximation)
   - Used for: Volume Profile POC, VAH, VAL calculation
   - Note: Not real volume (XAUUSD spot), sufficient for profile shape

3. **Level 2 Data (Phase 3, futures only):**
   - Source: CQG feed (GC futures)
   - Used for: Order Flow delta, CVD, absorption
   - Requires: Platform switch to futures

---

### Data Processing Pipeline

```
MT5 Historical Data
      │
      ▼
┌─────────────────┐
│ Detectors (M5)  │
│ - BOS           │
│ - Sweep         │
│ - Order Block   │
│ - FVG           │
│ - Momentum      │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│ MTF Bias (H1/H4)│
│ - Trend filter  │
│ - Alignment     │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│ Arbiter (M5)    │
│ - Scoring       │
│ - Validation    │
│ - Entry trigger │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│ Executor (M5)   │
│ - Position size │
│ - Entry/SL/TP   │
│ - Order place   │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│ Risk Manager    │
│ - DCA logic     │
│ - Breakeven     │
│ - Trailing      │
│ - Daily MDD     │
└─────────────────┘
      │
      ▼
┌─────────────────┐
│ OnTester()      │
│ - Collect stats │
│ - Export CSV    │
└─────────────────┘
      │
      ▼
  results/CSV ──► Em Analysis
```

---

## 🔧 Component Specifications

### 1. Detector Components (M5)

#### BOS Detector
- **Input:** OHLC data, lookback 50 bars
- **Output:** {direction: ±1, breakLevel: price, valid: bool, ttl: 60}
- **Logic:** Find swing high/low (Fractal K=3), detect close beyond swing with min distance (70 pts) and body (0.6 ATR)

#### Sweep Detector
- **Input:** OHLC data, lookback 40 bars
- **Output:** {side: ±1, level: price, distance: bars, valid: bool, ttl: 24}
- **Logic:** Scan bars 0-3, detect wick beyond fractal high/low but close inside, min wick 35% of range

#### Order Block Detector
- **Input:** OHLC data, lookback 30 bars
- **Output:** {direction: ±1, top/bottom: price, volume: ratio, touches: count, valid: bool, ttl: 40}
- **Logic:** Find last opposite-color candle before BOS, validate volume ≥ 1.0× avg, track touches

#### FVG Detector
- **Input:** OHLC data, lookback 20 bars
- **Output:** {direction: ±1, top/bottom: price, state: 0|1|2, valid: bool, ttl: 30}
- **Logic:** Detect 3-candle gap (bar[2] high < bar[0] low OR bar[2] low > bar[0] high), min gap 30% ATR

#### Momentum Detector
- **Input:** EMA(10), EMA(20)
- **Output:** {direction: ±1, strength: 0-10, valid: bool}
- **Logic:** EMA(10) > EMA(20) = bullish, calculate slope strength

---

### 2. MTF Bias (H1/H4)

- **Input:** H1/H4 OHLC
- **Output:** {bias: ±1, strength: 0-10}
- **Logic:** Calculate trend (EMA crossover or BOS on higher timeframe), pass bias to M5 arbiter
- **Bonus:** +20 points if M5 signal aligned with H1/H4 bias
- **Penalty:** -30 points if M5 signal counter-trend

---

### 3. Arbiter (Scoring & Validation)

- **Input:** All detector signals + MTF bias
- **Output:** {direction: ±1, score: 0-300, valid: bool, entryMethod: LIMIT|STOP}
- **Logic:**
  1. Validate candidate (Path A or B)
  2. Calculate base score (100 if BOS + POI)
  3. Add bonuses (BOS +30, Sweep +25, etc.)
  4. Apply penalties (counter-trend -30, weak OB -10, etc.)
  5. Disqualify if Momentum against SMC (score = 0)
  6. Return score ≥ 100 = valid signal

---

### 4. Executor (Entry/Exit Logic)

- **Input:** Valid signal from Arbiter
- **Output:** Order (type, entry, SL, TP, lots)
- **Logic:**
  1. Find trigger candle (last 4 bars, body ≥ 0.30 ATR)
  2. Calculate entry price (LIMIT = POI, STOP = trigger ± buffer)
  3. Calculate SL (structure-based + ATR, min 1000 pts)
  4. Calculate TP (structure target or Entry + Risk × MinRR)
  5. Validate RR ≥ 2.0
  6. Calculate lot size (risk 0.5%, max 3.0)
  7. Place order (BUY STOP / SELL STOP / BUY LIMIT / SELL LIMIT)

---

### 5. Risk Manager (Position Management)

- **Input:** Open positions, current price, original entry/SL
- **Output:** Modified SL (BE, trailing), DCA orders, halt signal
- **Logic:**
  1. **DCA:** If profit ≥ +0.75R or +1.5R, add position (0.5× or 0.33× lot)
  2. **Breakeven:** If profit ≥ +1R, move SL to entry
  3. **Trailing:** If profit ≥ +1R, trail SL (step +0.5R, distance 2× ATR)
  4. **Daily MDD:** Calculate (StartDayBalance - CurrentEquity) / StartDayBalance, if ≥ 8% → close all, halt
  5. **Sync SL:** All positions same side share same SL (when BE or trailing)

---

### 6. OnTester (CSV Export)

- **Input:** TesterStatistics (built-in MT5 function)
- **Output:** CSV file in Common/Files
- **Metrics Exported:**
  - Net Profit, Gross Profit, Gross Loss
  - Profit Factor, Recovery Factor, Sharpe Ratio
  - Total Trades, Profit Trades, Loss Trades
  - Win Rate %, Max Consecutive Wins/Losses
  - Balance DD, Equity DD (absolute + %)
  - Expected Payoff
- **Format:** 2-column CSV (Metric, Value)
- **File:** `backtest_results.csv` (FILE_COMMON flag)

---

## 📋 Configuration

### EA Parameters (Input Variables)

#### Detector Parameters
```cpp
input int    inp_FractalK        = 3;      // Swing detection bars
input int    inp_LookbackSwing   = 50;     // BOS lookback
input int    inp_LookbackLiq     = 40;     // Sweep lookback
input double inp_MinBodyATR      = 0.6;    // Min candle body (ATR)
input int    inp_MinBreakPts     = 70;     // Min BOS distance (points)
input double inp_MinWickPct      = 35.0;   // Min sweep wick (%)
```

#### Scoring Parameters
```cpp
input int    inp_MinScore        = 100;    // Entry threshold
input int    inp_BonusBOS        = 30;     // BOS bonus
input int    inp_BonusSweep      = 25;     // Sweep bonus
input int    inp_BonusOB         = 20;     // OB bonus
input int    inp_BonusFVG        = 15;     // FVG bonus
input int    inp_BonusMTF        = 20;     // MTF alignment bonus
input int    inp_PenaltyCounter  = -30;    // Counter-trend penalty
```

#### Risk Parameters
```cpp
input double inp_RiskPercent     = 0.5;    // Risk per trade (%)
input double inp_MaxLotPerSide   = 3.0;    // Max lot per direction
input double inp_MinRR           = 2.0;    // Min Risk:Reward
input double inp_DailyMDD        = 8.0;    // Daily MDD limit (%)
input int    inp_MinStopPts      = 1000;   // Min SL distance (points)
```

#### DCA Parameters
```cpp
input bool   inp_EnableDCA       = true;   // Enable DCA
input int    inp_MaxDcaAddons    = 2;      // Max DCA count
input double inp_DCA1_RMultiple  = 0.75;   // DCA #1 trigger (+0.75R)
input double inp_DCA1_LotMult    = 0.5;    // DCA #1 lot (0.5×)
input double inp_DCA2_RMultiple  = 1.5;    // DCA #2 trigger (+1.5R)
input double inp_DCA2_LotMult    = 0.33;   // DCA #2 lot (0.33×)
```

#### Breakeven & Trailing
```cpp
input bool   inp_EnableBE        = true;   // Enable breakeven
input double inp_BE_RMultiple    = 1.0;    // BE trigger (+1R)
input bool   inp_EnableTrailing  = true;   // Enable trailing
input double inp_Trail_StartR    = 1.0;    // Trail start (+1R)
input double inp_Trail_StepR     = 0.5;    // Trail step (+0.5R)
input double inp_Trail_ATRMult   = 2.0;    // Trail distance (2× ATR)
```

#### Session & Spread
```cpp
input string inp_SessionStart    = "07:00"; // Session start (GMT+7)
input string inp_SessionEnd      = "23:00"; // Session end (GMT+7)
input int    inp_MaxSpread       = 50;      // Max spread (points)
```

---

### Backtest Configuration (.ini)

```ini
[Tester]
Expert=AdvancedEA              # ✅ EA name only (NO path prefix)
Symbol=XAUUSD                  # Spot Gold
Period=5                       # M5
Model=1                        # OHLC 1-min (faster, sufficient for M5)
Optimization=0                 # Single run (not optimization)
FromDate=2023.01.01            # Start date
ToDate=2024.12.31              # End date
Deposit=10000                  # Starting balance
Currency=USD
Leverage=100
Visual=0                       # No visualization (faster)
ShutdownTerminal=1             # Auto-close MT5 when done
```

**Critical:** `Expert=` must use NAME ONLY. `Expert=Experts\Name` will FAIL.

---

## 🧪 Testing & Validation

### Test Phases

#### Phase 0: Workflow Validation
- **EA:** SimpleEA (MA crossover baseline)
- **Purpose:** Validate compile → backtest → CSV → analyze workflow
- **Success Criteria:** Workflow runs end-to-end without errors
- **Not performance-critical**

#### Phase 1: SMC Baseline Backtest
- **EA:** AdvancedEA (full SMC logic)
- **Period:** 2023-2024 (2 years)
- **Metrics:** WR, RR, trades/day, DD, profit factor
- **Analysis:** Pattern breakdown, root cause if targets missed

#### Phase 2: Optimization Iterations
- **Method:** Analyze CSV → identify root cause → adjust parameters/logic → re-test
- **Iterations:** 5-10 expected until targets met or pivot decision
- **Documentation:** Every iteration logged in brain/optimization_log.md

#### Phase 3: Forward Test (Demo)
- **Trigger:** Backtest targets met (90% WR + 1:2 RR + 10 trades/day + <10% DD)
- **Duration:** 1 month minimum
- **Validation:** Forward test confirms backtest results (no overfitting)

#### Phase 4: Live Deployment
- **Trigger:** Forward test validates + Boss approval
- **Start:** Micro lot (0.01) for 1 week
- **Scale:** Gradually increase to target lot size (3.0 max)

---

### Validation Checklist

**Before Live:**
- [ ] Backtest WR ≥ 90% (1+ year data)
- [ ] Backtest RR ≥ 1:2 (average across all trades)
- [ ] Backtest Trades/Day ≥ 10 (consistent frequency)
- [ ] Backtest Max DD < 10% (capital protection)
- [ ] Forward test (demo) ≥ 1 month validates backtest
- [ ] Code reviewed (no hardcoded dates, no look-ahead bias)
- [ ] Risk parameters validated (0.5% risk, 3.0 max lot, 8% MDD)
- [ ] Boss approval

---

## 🚀 Deployment

### Environment Setup

#### Coder Node (macOS with MT5)
- **Wine:** `/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64`
- **WINEPREFIX:** `~/Library/Application Support/net.metaquotes.wine.metatrader5`
- **MT5 Base:** `$WINEPREFIX/drive_c/Program Files/MetaTrader 5`
- **EA Folder:** `$MT5_BASE/MQL5/Experts`
- **CSV Output:** `$WINEPREFIX/drive_c/users/$(whoami)/AppData/Roaming/MetaQuotes/Terminal/Common/Files`

#### Git Repo
- **Location:** `/Volumes/data/EA-OAT-v2/` (local clone)
- **Remote:** TBD (GitHub repo to be created)
- **Branches:** `main` (stable), `dev` (active development)

#### Telegram
- **Bot:** TBD (webhook or poll-based)
- **Reports:** Coder sends "✅ CODER REPORT" when task done, Em sends analysis updates

---

### Deployment Steps

1. **Init Git Repo:**
   ```bash
   cd /Volumes/data/EA-OAT-v2
   git init
   git remote add origin <GitHub URL>
   git add .
   git commit -m "Initial commit: EA-OAT v2 baseline"
   git push -u origin main
   ```

2. **Clone on Both Machines:**
   - Gateway (Em): `git clone <URL> ~/ea-oat-v2`
   - Node (Coder): `git clone <URL> /Volumes/data/EA-OAT-v2`

3. **Validate Workflow (Iteration 0):**
   - Em writes CODER_TASK.md (Simple EA)
   - Em: `git push` → `node.invoke(Coder)`
   - Coder: `git pull` → implement → compile → backtest → CSV → `git push`
   - Em: `git pull` → analyze CSV → "✅ Workflow validated"

4. **Begin Iteration 1 (SMC Baseline):**
   - Em writes CODER_TASK.md (Advanced EA)
   - Repeat workflow loop
   - Iterate until targets met

5. **Forward Test (Demo):**
   - Deploy EA to MT5 demo account
   - Run for 1 month
   - Monitor daily (Telegram alerts)

6. **Live Deployment:**
   - Boss approval
   - Start micro lot (0.01)
   - Scale gradually

---

## 📊 Success Metrics

### Primary Targets (Phase 1)

| Metric | Target | Status | Current |
|--------|--------|--------|---------|
| Win Rate | ≥ 90% | ⏳ | - |
| Risk:Reward | ≥ 1:2 | ⏳ | - |
| Trades/Day | ≥ 10 | ⏳ | - |
| Max DD | < 10% | ⏳ | - |

**ALL FOUR MUST BE MET.**

### Secondary Metrics

- Profit Factor: ≥ 3.0 (nice to have)
- Sharpe Ratio: ≥ 2.0 (nice to have)
- Max Consecutive Losses: ≤ 3 (nice to have)

---

## 📚 References

- [EA-OAT v2.1 Business Rules](/Users/sh1su1/.openclaw/trading-system-development/docs/ea-oat/business/)
- [EA-OAT v2.1 Code Logic](/Users/sh1su1/.openclaw/trading-system-development/docs/ea-oat/code_logic/)
- [Elliott Wave Reference](/Users/sh1su1/.openclaw/workspace-trader/docs/ELLIOTT_WAVE_REFERENCE.md)
- [Order Flow Reference](/Users/sh1su1/.openclaw/workspace-trader/docs/ORDER_FLOW_REFERENCE.md)
- [Em Manager Skill](/Volumes/data/EA-OAT-v2/skills/em-manager/SKILL.md)
- [Coder Worker Skill](/Volumes/data/EA-OAT-v2/skills/coder-worker/SKILL.md)

---

**Next Steps:** Create CODER_TASK.md (Iteration 0 - Simple EA workflow validation)

---

**Document Version:** 2.0  
**Last Updated:** 2026-02-16  
**Author:** Em (Manager)  
**Status:** ✅ Complete - Ready for Phase 1 execution
