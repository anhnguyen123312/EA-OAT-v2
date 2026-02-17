# Design Decisions

**Last Updated:** 2026-02-16  
**Status:** Phase 1 - Baseline Architecture Defined

---

## 🎯 Strategic Decisions

### Decision 1: SMC-Only Baseline (Phase 1) ⭐

**Decision:** Start with SMC/ICT methodology only, defer EW/VP/OF integration to Phase 2

**Rationale:**
1. **Proven Foundation:** EA-OAT v2.1 already has working SMC logic (BOS, Sweep, OB, FVG)
2. **Complexity Management:** Adding 4 methodologies at once = high debugging difficulty
3. **Workflow Validation:** Need to test Em → Coder → Backtest → Analysis loop first
4. **Data Availability:** EW (manual counting), VP (volume data), OF (Level 2) have dependencies
5. **Iterative Approach:** Validate simple system, add complexity only if needed

**Alternative Considered:**
- Full quad integration from start → **Rejected** (too complex, high risk)

**Expected Outcome:**
- Working EA within 1-2 iterations
- Clear baseline performance metrics
- Foundation for future enhancements

**Status:** ✅ Approved

---

### Decision 2: M5 Primary Timeframe

**Decision:** Use M5 as primary execution timeframe

**Rationale:**
1. **Trade Frequency:** M5 generates 10-20 signals/day (vs H1 = 2-5/day)
2. **Target Alignment:** Need ≥10 trades/day to meet targets
3. **Noise Management:** SMC scoring filters low-quality M5 setups (score ≥ 100)
4. **Multi-Timeframe Bias:** H1/H4 bias prevents counter-trend M5 trades

**Alternative Considered:**
- H1 primary → **Rejected** (too few trades)
- M1 primary → **Rejected** (too noisy, low win rate)

**Trade-off:**
- More signals BUT requires stricter filtering
- Solution: Score ≥ 100 + MTF alignment bonus

**Status:** ✅ Approved

---

### Decision 3: Git-Based Coordination (Em ↔ Coder)

**Decision:** Use Git repo as source of truth for dual-agent workflow

**Rationale:**
1. **Separation of Concerns:** Em (Gateway) and Coder (Node) run on different machines
2. **Async Workflow:** Em can continue research while Coder backtests
3. **Version Control:** Track every iteration (code + config + results)
4. **Rollback Safety:** Can revert to previous version if optimization fails
5. **Audit Trail:** Full history of what changed and why

**Alternative Considered:**
- Shared network folder → **Rejected** (no version control, no history)
- Direct file sync → **Rejected** (conflict resolution issues)

**Workflow:**
```
Em: git pull → research/design → write CODER_TASK.md → git push → node.invoke()
Coder: git pull → implement → compile → backtest → CSV → git push → Telegram
Em: git pull → analyze CSV → decide next iteration
```

**Status:** ✅ Approved

---

### Decision 4: Knowledge Separation (brain/ vs experience/)

**Decision:** Separate strategic knowledge (brain/) from technical knowledge (experience/)

**Rationale:**
1. **Role Clarity:** Em owns strategy, Coder owns implementation
2. **Prevents Confusion:** Em doesn't need to know MQL5 quirks, Coder doesn't decide scoring weights
3. **Focused Learning:** Each agent updates their own knowledge base
4. **Easier Debugging:** Issue = strategy bug (brain/) vs code bug (experience/)

**Structure:**
```
brain/ (Em's knowledge)
  - strategy_research.md (trading methods)
  - optimization_log.md (iteration history)
  - design_decisions.md (this file)
  - targets.md (progress tracker)

experience/ (Coder's knowledge)
  - compile_issues.md (MQL5 errors)
  - mql5_patterns.md (code snippets)
  - wine_quirks.md (macOS/Wine issues)
  - backtest_setup.md (MT5 config tricks)
```

**Status:** ✅ Approved

---

## 🏗️ Architecture Decisions

### Decision 5: OnTester() CSV Export (Mandatory)

**Decision:** Every EA MUST export backtest results to CSV via OnTester() function

**Rationale:**
1. **Automated Analysis:** Em can parse CSV programmatically (no manual report reading)
2. **Standardized Format:** Same metrics across all EA versions
3. **Git-Friendly:** CSV diffs show metric changes between versions
4. **Workflow Enabler:** Without CSV, Em cannot analyze → breaks automation

**Implementation:**
```mql5
double OnTester() {
   // Collect TesterStatistics
   double winRate = (totalTrades > 0) ? (profitTrades / totalTrades * 100.0) : 0;
   ...
   
   // Export to CSV with FILE_COMMON flag
   int handle = FileOpen("backtest_results.csv", FILE_WRITE|FILE_CSV|FILE_COMMON, ',');
   FileWrite(handle, "Win Rate %", DoubleToString(winRate, 2));
   ...
   FileClose(handle);
   
   return netProfit;
}
```

**Critical:** FILE_COMMON flag ensures CSV goes to Common/Files (accessible outside Wine sandbox)

**Status:** ✅ Mandatory for all EAs

---

### Decision 6: Score Threshold = 100 (Baseline)

**Decision:** Entry threshold starts at 100 points (from EA-OAT v2.1)

**Rationale:**
1. **Proven Baseline:** EA-OAT v2.1 used 100 as minimum
2. **Quality Filter:** Prevents low-confidence setups (score 50-99)
3. **Tunable:** Can lower to 90 or raise to 120 based on backtest results

**Scoring System:**
- Base: 100 (BOS + POI)
- Bonuses: BOS +30, Sweep +25, OB +20, FVG +15, MTF +20, Strong OB +10
- Penalties: Counter-trend -30, Weak OB -10, Touched OB ×0.5
- **Total ≥ 100 = Entry**

**Optimization Strategy:**
- If WR < 90%: Raise threshold to 120 (more selective)
- If Trades < 10/day: Lower threshold to 90 (more signals)

**Status:** ✅ Baseline = 100, adjustable via optimization

---

### Decision 7: Risk Management = 0.5% Per Trade

**Decision:** Default risk = 0.5% of balance per trade

**Rationale:**
1. **Conservative Start:** Protects capital during validation phase
2. **Daily MDD Protection:** 8% MDD limit = ~16 consecutive losses (unlikely)
3. **Scalable:** Can increase to 1% if system proves stable

**Position Sizing:**
```
Lots = (Balance × 0.5%) ÷ (SL_Distance × Value_Per_Point)
Max Lot: 3.0 (hard cap)
```

**DCA Rules:**
- DCA #1: +0.75R profit → add 0.5× original lot
- DCA #2: +1.5R profit → add 0.33× original lot
- **R = ORIGINAL SL distance** (doesn't change when BE moves)

**Status:** ✅ Approved

---

### Decision 8: DCA When Profitable (Not Averaging Down)

**Decision:** DCA only when position is IN PROFIT (not when losing)

**Rationale:**
1. **Risk Control:** Averaging down = magnifying losses (dangerous)
2. **Trend Following:** Adding to winners = riding momentum
3. **Institutional Behavior:** Pros scale in when right, cut when wrong

**Logic:**
```
IF profit ≥ +0.75R AND dcaCount < 2 AND totalLot < maxLot
  → Add DCA #1 (0.5× original lot)

IF profit ≥ +1.5R AND dcaCount < 2 AND totalLot < maxLot
  → Add DCA #2 (0.33× original lot)
```

**Status:** ✅ Approved (never DCA when losing)

---

### Decision 9: Breakeven at +1R (Protect Capital)

**Decision:** Move SL to entry when profit ≥ +1R

**Rationale:**
1. **Risk Elimination:** Once +1R, zero risk (worst case = breakeven)
2. **Psychological:** Removes stress, allows position to run
3. **Trailing Start:** BE first, then trailing begins

**Implementation:**
```
IF profit ≥ +1R (original SL distance)
  → Move ALL positions (same side) SL to entry price
  → Now risk-free
```

**Status:** ✅ Approved

---

### Decision 10: Config File Format = .ini (Expert= Name Only)

**Decision:** MT5 backtest config uses .ini format with `Expert=Name` (no path)

**Rationale:**
1. **MT5 Requirement:** Terminal expects .ini format for automated backtests
2. **Critical Gotcha:** `Expert=Experts\Name` FAILS ("not found" error)
3. **Correct:** `Expert=Name` (EA name only, no path prefix)

**Example:**
```ini
[Tester]
Expert=SimpleEA          # ✅ CORRECT
Expert=Experts\SimpleEA  # ❌ WRONG - will fail
Symbol=XAUUSD
Period=5
...
```

**Status:** ✅ Mandatory format (documented in Coder skill)

---

## 🎨 Parameter Design Decisions

### Decision 11: MinRR = 2.0 (Risk:Reward)

**Decision:** Minimum Risk/Reward ratio = 2.0 (2:1 reward:risk)

**Rationale:**
1. **Profitability Math:** With 90% WR, even 1.5:1 RR is profitable
2. **Conservative:** 2:1 provides cushion (can win with 60% WR)
3. **Quality Filter:** Forces better entry points (wait for pullback)

**Implementation:**
```
RR = (TP - Entry) / (Entry - SL)  [LONG]

IF RR < 2.0 → Skip entry (insufficient reward)
```

**Optimization:**
- If WR > 90%: Can lower to 1.5 (more signals)
- If WR < 80%: Raise to 2.5 (better quality)

**Status:** ✅ Baseline = 2.0

---

### Decision 12: Daily MDD = 8% (Circuit Breaker)

**Decision:** Stop trading when daily drawdown ≥ 8%

**Rationale:**
1. **Capital Protection:** Prevents catastrophic loss days
2. **Emotional Reset:** Forces break, prevents revenge trading
3. **Math:** 8% MDD = ~16 consecutive 0.5% losses (unlikely with 90% WR)

**Implementation:**
```
Daily MDD = (StartDayBalance - CurrentEquity) / StartDayBalance × 100%

IF Daily MDD ≥ 8%:
  → Close all positions
  → Halt trading until next day (00:00 GMT+7)
  → Reset counter
```

**Status:** ✅ Approved

---

### Decision 13: Session = 07:00 - 23:00 GMT+7 (Full Day)

**Decision:** Trade full day (16 hours) unless proven ineffective

**Rationale:**
1. **Maximize Signals:** Need ≥10 trades/day, can't afford to skip sessions
2. **XAUUSD 24h Market:** Gold trades nearly 24/7, all sessions valid
3. **Backtest Data:** Let data decide if certain sessions underperform

**Alternative Considered:**
- Multi-session (Asia/London/NY windows) → **Defer to optimization** if full-day WR < 90%

**Status:** ✅ Start with full day, optimize if needed

---

### Decision 14: Trigger Candle Requirement

**Decision:** Require bullish/bearish candle confirmation before entry

**Rationale:**
1. **Reduces False Signals:** Structure alone isn't enough, need price action
2. **Momentum Confirmation:** Candle body ≥ 0.30 ATR = real momentum
3. **Timing:** Scan last 4 bars (0-3) for trigger

**Implementation:**
```
Trigger Candle (LONG):
  - Bullish candle (close > open)
  - Body ≥ 0.30 ATR
  - Within last 4 bars

Use trigger high/low for entry calculation
```

**Status:** ✅ Approved

---

## 🚀 Workflow Design Decisions

### Decision 15: Three-Tier EA Strategy (Validation Approach)

**Decision:** Build 3 EAs in sequence: Simple → Advanced → ML (if needed)

**Rationale:**
1. **Simple EA (MA Crossover):** Validates workflow (compile → backtest → CSV → analyze)
2. **Advanced EA (Full EA-OAT):** Real strategy with all detectors
3. **ML EA:** Only if Advanced fails to meet targets

**Benefit:**
- Catch workflow bugs early (Simple EA)
- Baseline comparison (Simple vs Advanced)
- ML fallback if logic-based fails

**Status:** ✅ Approved (start with Simple EA first)

---

### Decision 16: Iteration Loop = Analyze → Optimize → Test → Repeat

**Decision:** Never stop iterating until ALL targets met simultaneously

**Rationale:**
1. **Targets Are Non-Negotiable:** 90% WR AND 1:2 RR AND 10+ trades/day AND <10% DD
2. **Partial Success ≠ Done:** 95% WR but 5 trades/day = FAIL (need 10+)
3. **Root Cause Analysis:** Every iteration must identify WHY it failed

**Iteration Workflow:**
```
1. Analyze backtest CSV
   - Which trades won/lost?
   - Which patterns worked/failed?
   - What's the root cause of low WR or low frequency?

2. Research solutions
   - How do pros solve this problem?
   - What parameter adjustments make sense?

3. Design optimization
   - Write OPTIMIZATION_TASK.md with exact changes
   - Expected impact documented

4. Test
   - Coder implements → backtest → CSV

5. Repeat until targets met
```

**Status:** ✅ Approved (relentless iteration)

---

## 📊 Trade-offs Acknowledged

### Trade-off 1: Signals vs Quality

**More Filters → Higher WR BUT Fewer Signals**

Example:
- Score ≥ 100: 15 trades/day, 75% WR
- Score ≥ 150: 8 trades/day, 88% WR
- **Sweet Spot:** Score ≥ 120? (need backtest data)

**Strategy:** Start at 100, raise if WR too low, lower if frequency too low

---

### Trade-off 2: M5 Noise vs Frequency

**M5 Gives Signals BUT Also Noise**

Solution:
- Multi-timeframe bias (H1/H4) filters counter-trend
- Score ≥ 100 filters weak setups
- Trigger candle requirement reduces false entries

---

### Trade-off 3: Complexity vs Debuggability

**Simple System = Easier Debug, Complex System = Higher WR**

Phase 1 Decision: **Start simple**
- SMC-only first
- Add EW/VP only if needed
- Complexity justified by data, not theory

---

## 🔄 Future Decision Points

### When to Add EW/VP Integration?

**Trigger:** Phase 1 (SMC-only) WR < 90% after 5+ optimization iterations

**Decision Tree:**
```
IF WR < 90% AND tried 5+ optimizations
  → Analyze: Is problem counter-trend trades?
    → YES: Add EW macro bias
    → NO: Analyze: Is problem weak POI zones?
      → YES: Add VP key levels
      → NO: Research other root causes
```

---

### When to Pivot Strategy?

**Trigger:** 10+ iterations without improvement (WR stuck at 70-80%)

**Options:**
1. Different methodology (e.g., pure price action, indicator-based)
2. Different instrument (e.g., EURUSD instead of XAUUSD)
3. Different timeframe (e.g., H1 instead of M5)
4. Ask Boss for strategic decision

---

## 📝 Summary of Key Decisions

| # | Decision | Status |
|---|----------|--------|
| 1 | SMC-only baseline (Phase 1) | ✅ Approved |
| 2 | M5 primary timeframe | ✅ Approved |
| 3 | Git-based coordination | ✅ Approved |
| 4 | Knowledge separation (brain/ vs experience/) | ✅ Approved |
| 5 | OnTester() CSV export (mandatory) | ✅ Mandatory |
| 6 | Score threshold = 100 | ✅ Baseline |
| 7 | Risk = 0.5% per trade | ✅ Approved |
| 8 | DCA when profitable only | ✅ Approved |
| 9 | Breakeven at +1R | ✅ Approved |
| 10 | Config .ini Expert=Name only | ✅ Mandatory |
| 11 | MinRR = 2.0 | ✅ Baseline |
| 12 | Daily MDD = 8% | ✅ Approved |
| 13 | Session = 07:00-23:00 GMT+7 | ✅ Start full day |
| 14 | Trigger candle requirement | ✅ Approved |
| 15 | Three-tier EA strategy | ✅ Approved |
| 16 | Relentless iteration loop | ✅ Approved |

---

**Next:** Write targets.md and docs/SYSTEM_DESIGN.md
