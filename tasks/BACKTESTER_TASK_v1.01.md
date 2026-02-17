# BACKTESTER_TASK - AdvancedEA v1.01 Analysis

**Status:** READY (awaiting backtest completion)
**Date:** 2026-02-17
**Iteration:** v1.01
**Previous Results:** v1.00 (19.8% WR, 100% DD, 101 trades)

---

## Your Mission

Analyze AdvancedEA v1.01 backtest results and classify every trade into 5 categories:
1. **CORRECT_WIN** - Strategy worked as designed
2. **CORRECT_LOSS** - Stop loss hit correctly (acceptable loss)
3. **FALSE_SIGNAL** - Entry signal was wrong (bad setup)
4. **BAD_TIMING** - Good setup, wrong entry timing
5. **MISSED_EXIT** - Should have exited earlier (TP too far, or missed reversal)

---

## Input Files

You will receive these files after backtest completes:

```
results/AdvancedEA_v1.01_XAUUSD_M5_backtest_YYYY-MM-DD_HH-MM.csv
results/AdvancedEA_v1.01_XAUUSD_M5_trades_YYYY-MM-DD_HH-MM.csv
```

**File 1: backtest_*.csv** - OnTester() metrics (19 columns)
- Columns: TotalTrades, WinRate, ProfitFactor, Drawdown, etc.
- UTF-16LE encoding
- Single row with aggregate metrics

**File 2: trades_*.csv** - Individual trade details
- Columns: Ticket, OpenTime, Type, Lots, OpenPrice, SL, TP, CloseTime, ClosePrice, Profit, etc.
- UTF-16LE encoding
- One row per trade

---

## Analysis Workflow

### Step 1: Read Both CSV Files

```bash
# Files will be in results/ with timestamp
cd /Volumes/Data/Git/EA-OAT-v2
ls -lh results/AdvancedEA_v1.01*
```

**Note:** Files are UTF-16LE encoded. Use appropriate tools:
```bash
iconv -f UTF-16LE -t UTF-8 file.csv
```

Or use MQL5 reading if easier.

### Step 2: Extract Key Metrics

From `backtest_*.csv`:
- Total Trades
- Win Rate %
- Profit Factor
- Max Drawdown %
- Total Net Profit
- Average Win
- Average Loss
- Risk:Reward Ratio

Compare to v1.00 baseline:
- v1.00: 19.8% WR, 100% DD, -$1000 profit, 101 trades

**Expected v1.01 improvement:**
- WR: 60-70% (up from 19.8%)
- DD: < 40% (down from 100%)
- Profit: Positive (from -$1000)
- Trades: ~100 (similar count)

### Step 3: Trade-by-Trade Classification

For EACH trade in `trades_*.csv`:

1. **Read trade details:**
   - Ticket, OpenTime, Type (BUY/SELL)
   - OpenPrice, SL, TP
   - CloseTime, ClosePrice, Profit

2. **Load chart context:**
   - Open XAUUSD M5 chart at OpenTime
   - Check if Order Block or FVG was present
   - Verify pullback to zone
   - Check confirmation candle

3. **Classify the trade:**

   **CORRECT_WIN:**
   - Entry: OB/FVG detected + pullback to zone + confirmation candle
   - Exit: TP hit correctly
   - Session: During active session (London/Overlap/NY main hours)
   - Outcome: Profit > 0

   **CORRECT_LOSS:**
   - Entry: Setup was valid (OB/FVG + pullback + confirmation)
   - Exit: SL hit (acceptable risk, market reversed)
   - Session: Active session
   - Outcome: Profit < 0, but trade followed rules
   - Note: These are expected losses (part of trading)

   **FALSE_SIGNAL:**
   - Entry: OB/FVG detected BUT weak/false
   - Problem: Not a true smart money zone
   - Examples:
     * No institutional volume behind OB
     * FVG too small (< 5 pips)
     * Conflicting signals (both LONG and SHORT setups)
   - Outcome: Usually loss, sometimes lucky win
   - Root Cause: Zone detection logic needs refinement

   **BAD_TIMING:**
   - Entry: Valid OB/FVG zone detected
   - Problem: Entered too early or too late
   - Examples:
     * Entered before pullback completed (v1.00 bug)
     * Entered after price already left zone
     * No confirmation candle (weak momentum)
   - Outcome: Usually loss or small win
   - Root Cause: Entry timing logic (v1.01 fix target)

   **MISSED_EXIT:**
   - Entry: Valid setup, good timing
   - Problem: Exited poorly
   - Examples:
     * TP too far (price reversed before hitting)
     * Should have used trailing SL
     * Didn't detect reversal signals
   - Outcome: Profit left on table (win → smaller win, or win → loss)
   - Root Cause: Exit management needs improvement

4. **Record classification:**

Create `results/AdvancedEA_v1.01_trades_classified.csv`:
```csv
Ticket,OpenTime,Type,Profit,Classification,Reason,Session,ChartNotes
12345,2023-01-15 08:30,BUY,+25.50,CORRECT_WIN,"Valid OB pullback, TP hit",London,"Clean setup at 1925.50"
12346,2023-01-15 14:20,SELL,-18.30,CORRECT_LOSS,"Valid FVG, SL hit by spike",Overlap,"Stopped out correctly"
12347,2023-01-15 02:10,BUY,-22.10,FALSE_SIGNAL,"Weak OB, no volume",Asian,"Avoid Asian session"
12348,2023-01-16 09:15,SELL,-19.40,BAD_TIMING,"Entered before pullback done",London,"v1.00 bug pattern"
12349,2023-01-16 11:30,BUY,+12.20,MISSED_EXIT,"TP too far, reversed at 1935",Overlap,"Should exit at resistance"
```

### Step 4: Calculate Category Statistics

Count trades in each category:

```
CORRECT_WIN:    X trades (Y%)
CORRECT_LOSS:   X trades (Y%)
FALSE_SIGNAL:   X trades (Y%)
BAD_TIMING:     X trades (Y%)
MISSED_EXIT:    X trades (Y%)
---
TOTAL:          X trades (100%)
```

**Expected distribution for v1.01:**
- If entry timing fix worked:
  * BAD_TIMING should be < 15% (down from v1.00's ~40%)
  * CORRECT_WIN should be 50-60%
  * CORRECT_LOSS should be 10-20% (acceptable losses)

- If still poor:
  * BAD_TIMING > 30% → Entry timing still broken
  * FALSE_SIGNAL > 30% → Zone detection broken

### Step 5: Session Analysis

Break down by trading session:

```
Asian (00:00-08:00 GMT):     X trades, Y% WR
London (08:00-12:00 GMT):    X trades, Y% WR
Overlap (12:00-16:00 GMT):   X trades, Y% WR
NY (16:00-00:00 GMT):        X trades, Y% WR
```

**Expected patterns:**
- Asian: Low WR (< 40%), many FALSE_SIGNAL (thin liquidity)
- London: High WR (60-70%), best CORRECT_WIN ratio
- Overlap: Good WR (55-65%), second best
- NY: Moderate WR (50-60%), more choppy

### Step 6: Correlation Analysis

Find patterns linking multiple factors:

**Example correlations to check:**

1. **Loss Categories by Session:**
   - Are FALSE_SIGNAL losses concentrated in Asian session?
   - Are BAD_TIMING losses more common in NY session (choppy)?

2. **Win Rate by Entry Type:**
   - OB entries: X% WR
   - FVG entries: Y% WR
   - Which is more reliable?

3. **Profit Factor by Category:**
   - CORRECT trades: Avg profit vs avg loss ratio
   - FALSE_SIGNAL trades: How bad are they? (-$20 avg loss?)

4. **Time-of-Day Patterns:**
   - First hour of London (08:00-09:00): WR?
   - NY close (23:00-00:00): WR?

### Step 7: Root Cause Identification

Based on category statistics, identify TOP 3 ROOT CAUSES of losses:

**Template:**

```
ROOT CAUSE #1: [Category] - [Problem]
Trades affected: X (Y% of total losses)
Evidence: [Specific examples from classified trades]
Proposed fix: [Specific code change for v1.02]
Expected impact: [Estimated WR improvement]

ROOT CAUSE #2: ...
ROOT CAUSE #3: ...
```

**Example for v1.00 (what we found):**

```
ROOT CAUSE #1: BAD_TIMING - Entering before pullback completes
Trades affected: 41 trades (51% of total losses)
Evidence:
  - Ticket 12348: Entered at 1920.30, price continued to 1918.50 before reversing
  - Ticket 12355: Entered at 1932.10, pullback not done (reached 1930.80)
Proposed fix:
  - Add zone tolerance check (within 0.05% of OB level)
  - Add confirmation candle requirement (body >= 60% of range)
Expected impact: WR +40% (from 19.8% to 60%+)
```

---

## Output Files to Create

### 1. `results/AdvancedEA_v1.01_trades_classified.csv`

All trades with classifications (see Step 3 format).

### 2. `results/journals/AdvancedEA_v1.01_ANALYSIS.md`

Comprehensive analysis report:

```markdown
# AdvancedEA v1.01 Backtest Analysis

**Date:** 2026-02-17
**Backtest Period:** 2023-01-01 to 2026-01-01 (3 years)
**Symbol:** XAUUSD
**Timeframe:** M5
**Model:** Real Ticks

---

## Executive Summary

**Key Metrics:**
- Total Trades: X
- Win Rate: X%
- Profit Factor: X.XX
- Max Drawdown: X%
- Net Profit: $X

**Comparison to v1.00:**
- WR: +X% (from 19.8% to X%)
- DD: -X% (from 100% to X%)
- Profit: +$X (from -$1000 to $X)

**Verdict:** [SUCCESS / PARTIAL / FAILURE]

---

## Trade Classification Breakdown

[Insert category statistics from Step 4]

---

## Session Analysis

[Insert session breakdown from Step 5]

---

## Root Cause Analysis

[Insert top 3 root causes from Step 7]

---

## Recommendations for Next Iteration

**If v1.01 WR 60-70%:**
- ✅ Entry timing fix WORKED
- ➡️ Proceed to v1.02: PA Confluence Framework
- Expected v1.02 WR: 72-78%

**If v1.01 WR 50-59%:**
- ⚠️ Entry timing PARTIALLY fixed
- ➡️ v1.01b: Tune tolerance and confirmation thresholds
- Then v1.02

**If v1.01 WR < 50%:**
- ❌ Entry timing fix FAILED or new issues emerged
- ➡️ Deep dive for NEW root cause
- May need complete redesign

---

## Detailed Trade Examples

### Example CORRECT_WIN:
[Screenshot + analysis of 2-3 best trades]

### Example CORRECT_LOSS:
[Screenshot + analysis of acceptable losses]

### Example FALSE_SIGNAL:
[Screenshot + why signal was false]

### Example BAD_TIMING:
[Screenshot + timing issue details]

### Example MISSED_EXIT:
[Screenshot + better exit opportunity]

---

## Next Steps

1. Present analysis to Em (Team Lead)
2. Em creates OPTIMIZATION_TASK for next iteration
3. If targets met (WR >= 80%, Profit >= $80k), mark COMPLETE
4. If targets not met, proceed to v1.02 or v1.01b

**END OF ANALYSIS**
```

### 3. Update `experience/backtest_journal.md`

Add lessons learned from v1.01 analysis:

```markdown
## v1.01 Learnings (2026-02-17)

**What worked:**
- [List successful elements]

**What didn't work:**
- [List failures]

**Gotchas discovered:**
- [New issues found]

**For next time:**
- [Improvements to process]
```

---

## Tools and Resources

### Useful Scripts

```bash
# Convert UTF-16LE to UTF-8
iconv -f UTF-16LE -t UTF-8 input.csv > output.csv

# Count trades by classification
grep "CORRECT_WIN" trades_classified.csv | wc -l

# Calculate WR by session
grep "London" trades_classified.csv | grep "+" | wc -l
```

### Chart Analysis

Open MT5 and load XAUUSD M5 chart:
1. Navigate to trade OpenTime
2. Look for OB/FVG zones (will be highlighted if EA logged them)
3. Check if pullback completed
4. Check if confirmation candle present
5. Take screenshot if needed

### Reference Files

- `code/experts/AdvancedEA.mq5` - Implementation to understand logic
- `results/AdvancedEA_v1.01_CHANGES.md` - What was changed in v1.01
- `tasks/OPTIMIZATION_TASK.md` - What v1.01 was supposed to fix
- `results/AdvancedEA_Iteration1_DEEP_DIVE.md` - v1.00 analysis (for comparison)

---

## Quality Checklist

Before submitting analysis to Em:

- [ ] Both CSV files read successfully
- [ ] ALL trades classified (no "Unknown" category)
- [ ] Category percentages add up to 100%
- [ ] Session analysis complete (all 4 sessions)
- [ ] Top 3 root causes identified with evidence
- [ ] Comparison to v1.00 metrics complete
- [ ] Verdict clear (SUCCESS/PARTIAL/FAILURE)
- [ ] Recommendations specific and actionable
- [ ] Example trades included (with screenshots if possible)
- [ ] experience/backtest_journal.md updated
- [ ] Git commit with meaningful message

---

## Time Estimate

- CSV file reading and basic stats: 10 minutes
- Trade-by-trade classification: 30-60 minutes (depending on trade count)
- Session and correlation analysis: 15 minutes
- Root cause identification: 20 minutes
- Writing comprehensive report: 30 minutes
- **Total: 1.5 to 2.5 hours**

---

## Success Criteria

Your analysis is successful if:

1. **Complete:** Every trade classified
2. **Accurate:** Classifications match chart reality
3. **Insightful:** Root causes are specific and fixable
4. **Actionable:** Em can create clear v1.02 task from your findings
5. **Evidence-Based:** Screenshots/data support conclusions

---

**Ready to start when backtest completes!**
