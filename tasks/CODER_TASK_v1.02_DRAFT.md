# CODER_TASK - AdvancedEA v1.02: PA Confluence Framework

**Status:** DRAFT (pending v1.01 backtest results)
**Date:** 2026-02-17
**Iteration:** v1.02
**Goal:** Add Price Action Confluence Framework to improve trade quality (WR 60-70% → 72-78%)

---

## Executive Summary

**What:** Implement multi-method Price Action confluence scoring system
**Why:** Filter low-quality setups, increase win rate by 12-18%
**How:** Elliott Wave + Wyckoff + Fibonacci analysis with 0-10 scoring

**Expected Impact:**
- WR improvement: +12-18% (from 60-70% to 72-78%)
- Reduce FALSE_SIGNAL trades by 40-60%
- Trade count: Similar (~100 trades)
- Position sizing: Adjusted by confluence score (50% for score 5-6)

---

## Implementation Overview

### Files to Create

1. **code/include/ElliotWave.mqh** - Elliott Wave pattern recognition and scoring
2. **code/include/Wyckoff.mqh** - Wyckoff phase detection and volume analysis
3. **code/include/Fibonacci.mqh** - Auto-Fibonacci levels and pullback analysis
4. **code/include/ConfluenceScore.mqh** - Master confluence calculator

### Files to Modify

1. **code/experts/AdvancedEA.mq5** - Integrate confluence into entry logic

---

## Module 1: ElliotWave.mqh

### Purpose
Identify Elliott Wave position and score quality (0-3 points)

### Required Functions

#### 1. `int GetElliottScore(int direction)`

**Input:**
- `direction`: 1 for LONG, -1 for SHORT

**Process:**
```cpp
1. Identify current wave position using swing high/low analysis
2. Count waves from recent major swing
3. Determine wave type (impulse vs corrective)
4. Check Fibonacci relationships between waves
5. Validate wave structure (wave 3 longest, wave 4 doesn't overlap wave 1)
```

**Output:** Score 0-3
```cpp
Wave 3 (early, strong momentum) → 3 points (BEST)
Wave 3 (mid, continuation) → 2 points
Wave 5 (early, final push) → 2 points
Wave 5 (late, divergence) → 1 point
Wave C or unclear structure → 0 points (SKIP)
```

**Key Implementation Details:**

```cpp
class CElliottWave {
private:
    // Swing detection parameters
    int m_swingBars;           // Bars to confirm swing (default: 5)
    double m_swingThreshold;   // Minimum % move (default: 0.5%)

    // Fibonacci wave relationships
    double m_wave3MinRatio;    // Wave 3 vs Wave 1 (1.618)
    double m_wave5MaxRatio;    // Wave 5 vs Wave 3 (0.618-1.0)

    // Arrays for swing tracking
    double m_swingHighs[];
    double m_swingLows[];
    datetime m_swingTimes[];
    int m_currentWave;

public:
    CElliottWave(int swingBars=5, double threshold=0.005);

    // Core functions
    void UpdateSwings();                           // Scan for new swings
    int IdentifyWavePosition(int direction);       // Determine current wave
    bool ValidateWaveStructure();                  // Check Fibonacci ratios
    int GetElliottScore(int direction);            // Main scoring function

    // Helper functions
    bool IsWave3Strongest();                       // Wave 3 > Wave 1 and 5
    bool HasWave4Overlap();                        // Wave 4 overlaps Wave 1?
    double GetWaveRatio(int wave1, int wave2);     // Fibonacci ratio
};
```

**Validation Rules:**
- Wave 3 must be longest (or equal to wave 5)
- Wave 4 cannot overlap wave 1 price range
- Wave 5 should show momentum divergence (decreasing volume/RSI)

---

## Module 2: Wyckoff.mqh

### Purpose
Detect Wyckoff accumulation/distribution phases and score quality (0-4 points)

### Required Functions

#### 1. `int GetWyckoffScore()`

**Process:**
```cpp
1. Analyze recent price range (50-100 bars)
2. Calculate volume moving average
3. Detect phase characteristics:
   - Accumulation: sideways + decreasing volume + springs
   - Distribution: sideways + increasing volume + upthrusts
   - Markup: uptrend + increasing volume
   - Markdown: downtrend + increasing volume
4. Detect Spring (LPS - Last Point of Support)
5. Score based on phase + spring/LPS detection
```

**Output:** Score 0-4
```cpp
Accumulation + LPS detected → 4 points (BEST)
Accumulation + Spring → 3 points
Ranging (unclear) → 2 points
Distribution or Markdown → 0 points (SKIP)
```

**Key Implementation Details:**

```cpp
class CWyckoff {
private:
    // Volume analysis
    int m_volumePeriod;           // MA period (default: 20)
    double m_volumeSpike;         // Spike threshold (1.5x MA)

    // Range detection
    int m_rangeBars;              // Bars to analyze (default: 50)
    double m_rangeThreshold;      // Sideways threshold (2% range)

    // Spring detection
    double m_springPenetration;   // Support break % (0.3%)
    int m_springRecoveryBars;     // Max bars to recover (3)

    // Phase tracking
    enum WYCKOFF_PHASE {
        PHASE_ACCUMULATION,
        PHASE_MARKUP,
        PHASE_DISTRIBUTION,
        PHASE_MARKDOWN,
        PHASE_RANGING
    };

    WYCKOFF_PHASE m_currentPhase;
    bool m_springDetected;
    bool m_lpsDetected;

public:
    CWyckoff(int volumePeriod=20, int rangeBars=50);

    // Core functions
    WYCKOFF_PHASE DetectPhase();                   // Identify current phase
    bool DetectSpring(double supportLevel);        // Spring pattern
    bool DetectLPS();                              // Last Point of Support
    int GetWyckoffScore();                         // Main scoring function

    // Helper functions
    double CalculateVolumeMA();                    // Volume average
    bool IsSideways(int bars);                     // Range-bound?
    bool HasVolumeIncrease();                      // Volume rising?
};
```

**Phase Detection Logic:**

**Accumulation:**
- Price range < 2% over 50 bars
- Volume decreasing (current < MA)
- Springs: price breaks support briefly, then recovers

**Distribution:**
- Price range < 2% over 50 bars
- Volume increasing (current > MA)
- Upthrusts: price breaks resistance briefly, then fails

**Markup/Markdown:**
- Clear trend (price > 3% move)
- Volume confirms trend direction

---

## Module 3: Fibonacci.mqh

### Purpose
Calculate Fibonacci retracement/extension levels and score pullback quality (0-3 points)

### Required Functions

#### 1. `int GetFibonacciScore(int direction, double entryPrice)`

**Process:**
```cpp
1. Identify swing high and swing low (last 50-100 bars)
2. Calculate Fibonacci retracement levels:
   - 23.6%, 38.2%, 50.0%, 61.8%, 78.6%
3. Calculate extension levels:
   - 127.2%, 138.2%, 161.8%, 200.0%
4. Determine where current price sits (pullback %)
5. Check if TP target aligns with extension level
6. Score based on pullback depth + extension alignment
```

**Output:** Score 0-3
```cpp
38.2-50% pullback + 161.8% extension target → 3 points (GOLDEN)
50-61.8% pullback + 138.2% extension target → 2 points (GOOD)
61.8-78.6% deep pullback + any target → 1 point (ACCEPTABLE)
Poor alignment (< 38.2% or > 78.6%) → 0 points (SKIP)
```

**Key Implementation Details:**

```cpp
class CFibonacci {
private:
    // Swing detection
    int m_swingBars;              // Bars for swing (default: 50)
    double m_swingThreshold;      // Min % move (default: 1.0%)

    // Fibonacci levels
    double m_retraceLevels[5];    // 23.6, 38.2, 50.0, 61.8, 78.6
    double m_extensionLevels[4];  // 127.2, 138.2, 161.8, 200.0

    // Current levels
    double m_swingHigh;
    double m_swingLow;
    double m_fibLevels[];         // Calculated prices

public:
    CFibonacci(int swingBars=50);

    // Core functions
    void CalculateFibonacci(int direction);        // Calculate all levels
    double GetClosestLevel(double price);          // Nearest Fib level
    double GetPullbackPercent(double price);       // Retrace %
    bool IsExtensionTarget(double tp, int dir);    // TP at extension?
    int GetFibonacciScore(int direction, double entryPrice, double tp);

    // Helper functions
    void FindSwingHighLow(int bars);               // Identify swings
    double CalculateLevel(double level);           // Price for Fib %
    string GetLevelName(double price);             // e.g., "61.8% retrace"
};
```

**Scoring Logic:**

**Golden Zone (3 points):**
- Entry at 38.2-50% retracement
- TP target at 161.8% extension
- Maximum potential R:R (1:3+)

**Good Zone (2 points):**
- Entry at 50-61.8% retracement
- TP target at 138.2% extension
- Strong R:R (1:2 to 1:2.5)

**Deep Zone (1 point):**
- Entry at 61.8-78.6% retracement
- Any extension target
- Acceptable R:R (1:1.5 to 1:2)

---

## Module 4: ConfluenceScore.mqh

### Purpose
Combine all three methods into unified 0-10 score

### Required Functions

#### 1. `double CalculateConfluence(int direction, double entryPrice, double tp)`

**Process:**
```cpp
1. Call GetElliottScore(direction) → 0-3
2. Call GetWyckoffScore() → 0-4
3. Call GetFibonacciScore(direction, entryPrice, tp) → 0-3
4. Sum all scores → Total 0-10
5. Return total score
```

**Output:** Score 0-10
```cpp
9-10: EXCELLENT → Full position size (100%)
7-8:  GOOD → Full position size (100%)
5-6:  MODERATE → Reduced position size (50%)
0-4:  SKIP → No trade
```

**Key Implementation Details:**

```cpp
class CConfluenceScore {
private:
    CElliottWave* m_elliott;
    CWyckoff* m_wyckoff;
    CFibonacci* m_fibonacci;

    // Score breakdown storage
    int m_elliottScore;
    int m_wyckoffScore;
    int m_fibonacciScore;
    double m_totalScore;

public:
    CConfluenceScore();
    ~CConfluenceScore();

    // Initialization
    bool Initialize();
    void Deinitialize();

    // Core function
    double CalculateConfluence(int direction, double entryPrice, double tp);

    // Getters for individual scores
    int GetElliottScore() { return m_elliottScore; }
    int GetWyckoffScore() { return m_wyckoffScore; }
    int GetFibonacciScore() { return m_fibonacciScore; }

    // Logging
    string GetScoreBreakdown();  // "Score:7.0|EW:2|WY:3|FB:2"
};
```

---

## Integration into AdvancedEA.mq5

### Step 1: Include Headers

```cpp
#include <Trade\Trade.mqh>
#include <ConfluenceScore.mqh>  // Master header (includes others)
```

### Step 2: Global Variables

```cpp
CConfluenceScore* g_confluence = NULL;
```

### Step 3: OnInit() Modifications

```cpp
int OnInit() {
    // ... existing initialization ...

    // Initialize confluence calculator
    g_confluence = new CConfluenceScore();
    if(!g_confluence.Initialize()) {
        Print("ERROR: Failed to initialize Confluence calculator");
        return INIT_FAILED;
    }

    return INIT_SUCCEEDED;
}
```

### Step 4: OnDeinit() Modifications

```cpp
void OnDeinit(const int reason) {
    if(g_confluence != NULL) {
        g_confluence.Deinitialize();
        delete g_confluence;
        g_confluence = NULL;
    }
}
```

### Step 5: OnTick() Entry Logic Modifications

**BEFORE (v1.01):**
```cpp
if(no open positions) {
    if(CheckLongEntry()) → OpenLong();
    if(CheckShortEntry()) → OpenShort();
}
```

**AFTER (v1.02):**
```cpp
if(no open positions) {
    // Check LONG setup
    if(CheckLongEntry()) {
        // Calculate confluence BEFORE entry
        double longConfluence = g_confluence.CalculateConfluence(
            1,                    // direction: LONG
            longEntry.entryPrice,
            longEntry.tp
        );

        if(longConfluence >= 5.0) {
            OpenLong(longEntry, longConfluence);
        } else {
            Print("SKIP LONG: Low confluence (", longConfluence, "/10)");
        }
    }

    // Check SHORT setup
    if(CheckShortEntry()) {
        double shortConfluence = g_confluence.CalculateConfluence(
            -1,                   // direction: SHORT
            shortEntry.entryPrice,
            shortEntry.tp
        );

        if(shortConfluence >= 5.0) {
            OpenShort(shortEntry, shortConfluence);
        } else {
            Print("SKIP SHORT: Low confluence (", shortConfluence, "/10)");
        }
    }
}
```

### Step 6: OpenLong()/OpenShort() Signature Changes

**BEFORE:**
```cpp
bool OpenLong(SEntryCandidate &candidate)
```

**AFTER:**
```cpp
bool OpenLong(SEntryCandidate &candidate, double confluenceScore)
```

### Step 7: Position Sizing Based on Confluence

```cpp
bool OpenLong(SEntryCandidate &candidate, double confluenceScore) {
    // Calculate base lot size (existing logic)
    double baseLots = CalculateLotSize(candidate.sl);

    // CONFLUENCE ADJUSTMENT
    double lotMultiplier = 1.0;
    if(confluenceScore >= 9.0) {
        lotMultiplier = 1.0;  // Full size (EXCELLENT)
    } else if(confluenceScore >= 7.0) {
        lotMultiplier = 1.0;  // Full size (GOOD)
    } else if(confluenceScore >= 5.0) {
        lotMultiplier = 0.5;  // Half size (MODERATE)
    } else {
        // Should never reach here (filtered in OnTick)
        Print("ERROR: Confluence too low: ", confluenceScore);
        return false;
    }

    double finalLots = NormalizeLots(baseLots * lotMultiplier);

    // Execute trade with confluence in comment
    string comment = StringFormat(
        "Score:%.1f|EW:%d|WY:%d|FB:%d",
        confluenceScore,
        g_confluence.GetElliottScore(),
        g_confluence.GetWyckoffScore(),
        g_confluence.GetFibonacciScore()
    );

    if(!m_trade.Buy(finalLots, _Symbol, candidate.entryPrice,
                    candidate.sl, candidate.tp, comment)) {
        Print("ERROR: Failed to open LONG trade");
        return false;
    }

    return true;
}
```

### Step 8: OnTester() CSV Export Enhancement

Add confluence metrics to CSV export:

```cpp
double OnTester() {
    // ... existing 19 metrics ...

    // NEW: Confluence metrics
    double avgConfluence = 0.0;
    double avgConfluenceWins = 0.0;
    double avgConfluenceLoss = 0.0;
    int countExcellent = 0;  // 9-10
    int countGood = 0;       // 7-8
    int countModerate = 0;   // 5-6

    // Parse trade comments to extract confluence scores
    HistorySelect(0, TimeCurrent());
    int total = HistoryDealsTotal();

    for(int i = 0; i < total; i++) {
        ulong ticket = HistoryDealGetTicket(i);
        if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
            string comment = HistoryDealGetString(ticket, DEAL_COMMENT);
            double score = ExtractConfluenceScore(comment);

            if(score > 0) {
                avgConfluence += score;

                double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                if(profit > 0) avgConfluenceWins += score;
                else avgConfluenceLoss += score;

                if(score >= 9.0) countExcellent++;
                else if(score >= 7.0) countGood++;
                else if(score >= 5.0) countModerate++;
            }
        }
    }

    if(total > 0) avgConfluence /= total;
    if(totalWins > 0) avgConfluenceWins /= totalWins;
    if(totalLosses > 0) avgConfluenceLoss /= totalLosses;

    // Append to CSV
    FileWriteString(handle, StringFormat(",%.2f", avgConfluence));
    FileWriteString(handle, StringFormat(",%.2f", avgConfluenceWins));
    FileWriteString(handle, StringFormat(",%.2f", avgConfluenceLoss));
    FileWriteString(handle, StringFormat(",%d", countExcellent));
    FileWriteString(handle, StringFormat(",%d", countGood));
    FileWriteString(handle, StringFormat(",%d", countModerate));

    FileClose(handle);
    return customMetric;
}

// Helper function
double ExtractConfluenceScore(string comment) {
    // Parse "Score:7.5|EW:2|WY:3|FB:2"
    int pos = StringFind(comment, "Score:");
    if(pos < 0) return 0.0;

    string scoreStr = StringSubstr(comment, pos + 6, 4);  // "7.5|"
    pos = StringFind(scoreStr, "|");
    if(pos > 0) scoreStr = StringSubstr(scoreStr, 0, pos);

    return StringToDouble(scoreStr);
}
```

---

## Testing Requirements

### Unit Tests (Manual)

1. **Elliott Wave Detection:**
   - Manually verify wave counting on XAUUSD chart (2023-2024)
   - Check that wave 3 is longest, wave 4 doesn't overlap wave 1
   - Verify scoring: wave 3 early = 3, wave 5 late = 1

2. **Wyckoff Phase Detection:**
   - Identify accumulation ranges on chart
   - Verify spring detection (support break + recovery)
   - Check volume analysis (MA calculation)

3. **Fibonacci Levels:**
   - Compare auto-Fib levels with manual TradingView Fib tool
   - Verify pullback % calculation
   - Check extension target alignment

4. **Confluence Integration:**
   - Test with known setups (capture screenshots)
   - Verify score calculation: elliott + wyckoff + fib = total
   - Check position sizing adjustment (50% for score 5-6)

### Integration Test

Run backtest on AdvancedEA v1.02 with confluence enabled:

**Expected Results:**
- Trade count: ~80-100 (20-30% reduction due to filtering)
- Win Rate: 72-78% (up from 60-70%)
- Avg Confluence: 7.5+ (mostly GOOD/EXCELLENT setups)
- Moderate trades (5-6 score): < 20% of total

### Validation Checklist

- [ ] All 4 .mqh files compile without errors
- [ ] AdvancedEA.mq5 compiles without errors
- [ ] OnTester() exports 25 metrics (19 base + 6 confluence)
- [ ] Trade comments include confluence breakdown
- [ ] Position sizing adjusts for score 5-6 (50% reduction)
- [ ] Trades with score < 5 are skipped entirely
- [ ] Backtest runs to completion
- [ ] CSV contains confluence columns

---

## Error Handling

### Common Issues and Solutions

1. **Insufficient swing data:**
   - Problem: Not enough bars to identify Elliott waves
   - Solution: Return score 0, skip trade

2. **Conflicting signals:**
   - Problem: Elliott says wave 5, Wyckoff says accumulation
   - Solution: Still calculate all scores, total may be moderate (5-6)

3. **No clear Fibonacci levels:**
   - Problem: Choppy market, no clear swings
   - Solution: Return Fib score 0

4. **Memory allocation failures:**
   - Problem: Failed to create CConfluenceScore object
   - Solution: Log error, return INIT_FAILED from OnInit()

### Debug Logging

Add verbose logging during development:

```cpp
// In ConfluenceScore.mqh
Print("=== Confluence Analysis ===");
Print("Direction: ", (direction == 1 ? "LONG" : "SHORT"));
Print("Entry: ", entryPrice, ", TP: ", tp);
Print("Elliott Score: ", m_elliottScore, "/3");
Print("Wyckoff Score: ", m_wyckoffScore, "/4");
Print("Fibonacci Score: ", m_fibonacciScore, "/3");
Print("TOTAL: ", m_totalScore, "/10");
Print("=========================");
```

Remove or disable in production builds.

---

## Success Criteria

**v1.02 is successful if:**

1. **Compilation:** 0 errors, 0 warnings
2. **Backtest Completion:** Runs 2023-2026 without crashes
3. **Win Rate:** 72-78% (improvement from v1.01's 60-70%)
4. **Trade Quality:** 80%+ trades have confluence >= 7.0
5. **Risk Management:** Position sizing correctly adjusts for score 5-6
6. **CSV Export:** All 25 metrics exported correctly
7. **Trade Comments:** All trades have Score:X.X|EW:X|WY:X|FB:X format

**Failure Criteria (triggers redesign):**

- WR < 65% (no improvement from v1.01)
- Avg Confluence < 6.0 (system not filtering properly)
- Trade count < 30 (over-filtering)
- Compilation errors that can't be resolved in 2 hours

---

## Next Steps After v1.02

**If WR 72-78% achieved:**
- Proceed to v1.03: DCA + Adaptive Risk Management

**If WR 65-72%:**
- Tune confluence thresholds (maybe require 6+ instead of 5+)
- Adjust individual module scoring weights

**If WR < 65%:**
- Deep dive into which confluence component is weak
- Consider disabling weakest component
- May need v1.02b iteration before v1.03

---

## References

- `docs/ROADMAP_TO_80_PERCENT.md` - Strategic plan
- `skills/technical-analyst/SKILL.md` - Enhanced with confluence specs
- `experience/mql5_patterns.md` - MQL5 coding patterns
- `brain/implementation_plan.md` - PM's detailed plan (when created)
- `docs/quick-ref-skillssh.md` - Confluence framework reference

---

**END OF CODER_TASK v1.02 DRAFT**

*This task will be finalized after v1.01 backtest results confirm WR >= 60% and justify proceeding to confluence enhancement.*
