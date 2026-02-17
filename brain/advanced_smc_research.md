# Advanced Smart Money Concepts (SMC/ICT) Research

**Last Updated:** 2026-02-17
**Purpose:** Deep dive into SMC/ICT methodologies for algorithmic implementation
**Status:** Research compiled from existing documentation + technical implementation guidance

---

## 🎯 Research Objective

Provide comprehensive technical documentation for implementing advanced Price Action and Smart Money Concepts (SMC/ICT) in MQL5 for XAUUSD M5 trading.

**Focus Areas:**
1. Order Block (OB) detection and validation
2. Liquidity Sweep patterns and execution
3. Fair Value Gap (FVG) identification
4. Break of Structure (BOS) analysis
5. Confluence scoring systems for entry signals
6. Multi-timeframe bias integration

---

## 📚 Core SMC/ICT Concepts

### 1. Order Blocks (OB) - Institutional Footprints

**Definition:**
Order Blocks are zones where institutions placed large orders, causing directional moves. They represent imbalance areas where price is likely to return for liquidity.

**Types:**
- **Bullish OB (Demand Zone):** Last down candle before strong bullish move
- **Bearish OB (Supply Zone):** Last up candle before strong bearish move

**Detection Algorithm (MQL5):**

```mql5
struct OrderBlock {
   datetime time;
   double high;
   double low;
   double open;
   double close;
   ENUM_OB_TYPE type; // BULLISH_OB or BEARISH_OB
   int strength;      // 1-10 based on validation criteria
   bool touched;      // Has price returned to this OB?
   int age;          // Bars since formation
};

// Bullish OB Detection
bool IsBullishOrderBlock(int index) {
   // Last bearish candle before bullish momentum
   if (Close[index] >= Open[index]) return false; // Must be bearish

   // Next 2-3 candles should be strongly bullish
   bool strongBullishMove = true;
   for (int i = index - 1; i >= index - 3 && i >= 0; i--) {
      if (Close[i] <= Open[i]) {
         strongBullishMove = false;
         break;
      }
   }

   if (!strongBullishMove) return false;

   // Momentum confirmation: move should be significant
   double moveSize = 0;
   for (int i = index - 1; i >= index - 3 && i >= 0; i--) {
      moveSize += (Close[i] - Open[i]);
   }

   double atr = iATR(Symbol(), PERIOD_CURRENT, 14, index);
   return (moveSize >= 1.5 * atr); // Significant move
}
```

**Validation Criteria (Strength Scoring):**
- **Base Strength:** 5 points
- **+3:** OB formed at fractal high/low (S/R confluence)
- **+2:** Volume spike on OB candle (if volume data available)
- **+2:** OB zone = 50% Fibonacci retracement of prior swing
- **+1:** OB candle has long wick (liquidity grab)
- **-2:** OB older than 50 bars (aged OB, less reliable)
- **-5:** OB already touched once (strength weakens)

**Strong OB:** Score ≥ 7
**Weak OB:** Score ≤ 4

**Implementation Notes:**
- Store OBs in array, sorted by recency
- Maximum 20 active OBs per direction (memory optimization)
- Remove OBs older than 100 bars or touched 3+ times
- **Entry Zone:** OB high (bearish) or OB low (bullish) ± 5 pips

---

### 2. Fair Value Gap (FVG) - Price Imbalances

**Definition:**
A Fair Value Gap occurs when there's a gap between the high of candle N-2 and the low of candle N (or vice versa). This represents a price imbalance that the market tends to "fill" later.

**Types:**
- **Bullish FVG:** Gap created during upward move (potential support on pullback)
- **Bearish FVG:** Gap created during downward move (potential resistance on rally)

**Detection Algorithm (MQL5):**

```mql5
struct FairValueGap {
   datetime time;
   double upperBound;  // Top of the gap
   double lowerBound;  // Bottom of the gap
   ENUM_FVG_TYPE type; // BULLISH_FVG or BEARISH_FVG
   bool filled;        // Has price returned to fill the gap?
   double fillPercent; // 0-100% of gap filled
};

// Bullish FVG Detection
bool IsBullishFVG(int index) {
   // Check if there's a gap between bar[index+2].high and bar[index].low
   // with bar[index+1] being the "jumping" candle

   if (index + 2 >= Bars) return false;

   double prevHigh = High[index + 2];
   double currLow = Low[index];

   // Gap must exist
   if (currLow <= prevHigh) return false;

   // Middle candle should be bullish with strong momentum
   if (Close[index + 1] <= Open[index + 1]) return false;

   double gapSize = currLow - prevHigh;
   double atr = iATR(Symbol(), PERIOD_CURRENT, 14, index);

   // Gap should be significant (at least 0.3 ATR)
   return (gapSize >= 0.3 * atr);
}

// Store FVG
void StoreFVG(int index, ENUM_FVG_TYPE type) {
   FairValueGap fvg;
   fvg.time = Time[index];

   if (type == BULLISH_FVG) {
      fvg.lowerBound = High[index + 2];
      fvg.upperBound = Low[index];
   } else {
      fvg.upperBound = Low[index + 2];
      fvg.lowerBound = High[index];
   }

   fvg.type = type;
   fvg.filled = false;
   fvg.fillPercent = 0.0;

   // Add to FVG array
   ArrayResize(FVGArray, ArraySize(FVGArray) + 1);
   FVGArray[ArraySize(FVGArray) - 1] = fvg;
}
```

**Validation Criteria:**
- **Minimum Gap Size:** 0.3 ATR (filters noise on M5)
- **Maximum Gap Size:** 2.0 ATR (too wide = not tradable)
- **Age Limit:** 30 bars (recent gaps more reliable)
- **Fill Detection:** Price must enter gap zone (between bounds)

**Trading Logic:**
- **Entry Trigger:** Price returns to FVG zone (50% fill or better)
- **Confluence:** FVG + OB at same level = high probability setup
- **Target:** Opposite side of FVG + structure target

---

### 3. Break of Structure (BOS) - Trend Confirmation

**Definition:**
Break of Structure occurs when price breaks a significant swing high (in uptrend) or swing low (in downtrend), confirming trend direction and signaling continuation.

**Types:**
- **Bullish BOS:** Price breaks above previous swing high
- **Bearish BOS:** Price breaks below previous swing low

**Detection Algorithm (MQL5):**

```mql5
struct SwingPoint {
   datetime time;
   double price;
   ENUM_SWING_TYPE type; // SWING_HIGH or SWING_LOW
   int index;
};

// Swing High Detection (Fractal-based)
bool IsSwingHigh(int index, int leftBars = 5, int rightBars = 5) {
   if (index - rightBars < 0 || index + leftBars >= Bars) return false;

   double highPrice = High[index];

   // Check left side
   for (int i = 1; i <= leftBars; i++) {
      if (High[index + i] >= highPrice) return false;
   }

   // Check right side
   for (int i = 1; i <= rightBars; i++) {
      if (High[index - i] > highPrice) return false;
   }

   return true;
}

// BOS Detection
bool IsBullishBOS(int index) {
   // Find last significant swing high
   SwingPoint lastSwingHigh = GetLastSwingHigh(index + 1);

   if (lastSwingHigh.price == 0) return false;

   // Current close must break above swing high
   if (Close[index] <= lastSwingHigh.price) return false;

   // Confirmation: candle must be bullish with momentum
   if (Close[index] <= Open[index]) return false;

   double candleBody = Close[index] - Open[index];
   double atr = iATR(Symbol(), PERIOD_CURRENT, 14, index);

   // Body must be at least 0.5 ATR (strong momentum)
   return (candleBody >= 0.5 * atr);
}
```

**Validation Criteria:**
- **Swing Significance:** Swing must be at least 20 bars old
- **Break Strength:** Close must be beyond swing level (not just wick)
- **Momentum:** Breaking candle body ≥ 0.5 ATR
- **Volume Confirmation:** Increased volume on break (if available)

**Scoring:**
- **BOS Alone:** +30 points (base score)
- **BOS + Retest (pullback to broken level):** +50 points (highest probability)
- **BOS on HTF alignment (H1/H4 also showing BOS):** +20 points (MTF bonus)

---

### 4. Liquidity Sweep - Stop Hunt Detection

**Definition:**
Liquidity Sweep occurs when price briefly moves beyond a swing high/low to trigger stop losses, then reverses sharply. This is institutional accumulation/distribution.

**Pattern Recognition:**

```mql5
struct LiquiditySweep {
   datetime time;
   double sweepLevel;     // Price level that was swept
   ENUM_SWEEP_TYPE type;  // BULLISH_SWEEP or BEARISH_SWEEP
   double penetration;    // How far beyond level (pips)
   bool confirmed;        // Did price reverse after sweep?
};

// Bullish Sweep Detection (sweep low then reverse up)
bool IsBullishLiquiditySweep(int index) {
   // Find recent swing low
   SwingPoint recentLow = GetRecentSwingLow(index + 1, 20); // Within 20 bars

   if (recentLow.price == 0) return false;

   // Check if current candle swept below swing low
   if (Low[index] >= recentLow.price) return false;

   double penetration = recentLow.price - Low[index];
   double atr = iATR(Symbol(), PERIOD_CURRENT, 14, index);

   // Penetration should be small (5-15 pips or 0.1-0.3 ATR)
   if (penetration < 0.1 * atr || penetration > 0.3 * atr) return false;

   // CRITICAL: Candle must CLOSE back above the swept level (rejection)
   if (Close[index] <= recentLow.price) return false;

   // Candle should have long lower wick (stop hunt signature)
   double lowerWick = Open[index] - Low[index];
   double candleRange = High[index] - Low[index];

   // Wick should be at least 60% of total range
   return (lowerWick >= 0.6 * candleRange);
}
```

**Validation Criteria:**
- **Swing Recency:** Swept level must be within last 10-30 bars
- **Penetration Range:** 0.1-0.3 ATR (too small = no sweep, too large = breakout)
- **Rejection Confirmation:** Close must be back inside prior range
- **Wick Ratio:** Lower/upper wick ≥ 60% of candle range

**Scoring:**
- **Sweep Detected:** +25 points
- **Sweep + OB at rejection zone:** +40 points (very high probability)
- **Sweep + FVG fill:** +35 points

---

### 5. Multi-Timeframe (MTF) Bias Integration

**Concept:**
Higher timeframe trend provides directional bias. Only take M5 signals aligned with H1/H4 trend to avoid counter-trend trades.

**Implementation:**

```mql5
enum ENUM_MTF_BIAS {
   MTF_BULLISH,    // H1 and H4 both bullish
   MTF_BEARISH,    // H1 and H4 both bearish
   MTF_NEUTRAL     // Mixed or ranging
};

ENUM_MTF_BIAS GetMTFBias() {
   // H1 Bias
   bool h1Bullish = IsTrendBullish(PERIOD_H1);
   bool h1Bearish = IsTrendBearish(PERIOD_H1);

   // H4 Bias
   bool h4Bullish = IsTrendBullish(PERIOD_H4);
   bool h4Bearish = IsTrendBearish(PERIOD_H4);

   // Both timeframes must agree
   if (h1Bullish && h4Bullish) return MTF_BULLISH;
   if (h1Bearish && h4Bearish) return MTF_BEARISH;

   return MTF_NEUTRAL;
}

bool IsTrendBullish(ENUM_TIMEFRAMES timeframe) {
   // Simple trend detection: 20 EMA > 50 EMA
   double ema20 = iMA(Symbol(), timeframe, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema50 = iMA(Symbol(), timeframe, 50, 0, MODE_EMA, PRICE_CLOSE, 0);

   // Alternative: BOS-based trend (more aligned with SMC)
   // Check if last 2 swing highs are ascending (bullish trend)

   return (ema20 > ema50);
}
```

**Scoring Logic:**
- **MTF Aligned (M5 signal = H1/H4 bias):** +20 points
- **MTF Neutral:** 0 points (allowed but no bonus)
- **MTF Counter-trend:** -30 points (strong penalty, may skip trade)

**Filter Application:**
- If `RequireMTFAlignment = true`: Skip trades with MTF counter-trend penalty
- If `RequireMTFAlignment = false`: Allow but apply -30 penalty to score

---

## 🎯 Confluence Scoring System (Enhanced)

### Scoring Framework

**Base Score Components:**

| Component | Points | Condition |
|-----------|--------|-----------|
| **BOS** | +30 | Break of Structure detected |
| **BOS + Retest** | +50 | BOS with pullback to broken level |
| **Liquidity Sweep** | +25 | Sweep detected and confirmed |
| **Order Block** | +20 | Strong OB (score ≥ 7) |
| **Order Block (Weak)** | +10 | Weak OB (score 4-6) |
| **Fair Value Gap** | +15 | FVG present at entry zone |
| **MTF Alignment** | +20 | H1 and H4 bias aligned |
| **Momentum Candle** | +10 | Trigger candle ≥ 0.5 ATR body |

**Penalties:**

| Penalty | Points | Condition |
|---------|--------|-----------|
| **Counter-trend** | -30 | Against H1/H4 bias |
| **Weak OB** | -10 | OB score ≤ 3 |
| **Touched OB** | ×0.5 | OB already tested once (multiply final score) |
| **Low RR** | -20 | Risk:Reward < 1.5 |

**Entry Threshold:**
- **Minimum Score:** 100 points
- **Excellent Setup:** 150+ points (BOS + Sweep + Strong OB + FVG + MTF = 165)
- **Perfect Setup:** 200+ points (rare, extremely high confidence)

### Example Scoring Scenarios

**Scenario 1: BOS + Strong OB + MTF**
```
BOS: +30
Strong OB: +20
MTF Alignment: +20
Momentum Candle: +10
─────────────────
TOTAL: 80 points → SKIP (below 100 threshold)
```

**Scenario 2: BOS + Sweep + Strong OB + FVG + MTF**
```
BOS: +30
Sweep: +25
Strong OB: +20
FVG: +15
MTF Alignment: +20
Momentum Candle: +10
─────────────────
TOTAL: 120 points → ENTER (meets threshold)
```

**Scenario 3: BOS Retest + Sweep + Strong OB + FVG + MTF**
```
BOS Retest: +50 (instead of +30)
Sweep: +25
Strong OB: +20
FVG: +15
MTF Alignment: +20
Momentum Candle: +10
─────────────────
TOTAL: 140 points → EXCELLENT ENTRY
```

**Scenario 4: Strong Setup BUT Counter-trend**
```
BOS: +30
Strong OB: +20
FVG: +15
Momentum: +10
Counter-trend: -30
─────────────────
TOTAL: 45 points → SKIP (below threshold + counter-trend)
```

---

## 🔧 Implementation Architecture (MQL5)

### Class Structure

```mql5
// Main EA Class
class CSmartMoneyEA {
private:
   // Detectors
   COrderBlockDetector m_obDetector;
   CFVGDetector m_fvgDetector;
   CBOSDetector m_bosDetector;
   CLiquiditySweepDetector m_sweepDetector;
   CMTFBiasAnalyzer m_mtfAnalyzer;

   // Scorers
   CConfluenceScorer m_scorer;

   // Risk Manager
   CRiskManager m_riskMgr;

   // Trade Manager
   CTradeManager m_tradeMgr;

public:
   void OnTick();
   void ScanForSetups();
   double CalculateConfluenceScore(CSetup &setup);
   bool ValidateEntry(CSetup &setup);
   void ExecuteTrade(CSetup &setup);
};

// Setup Structure
struct CSetup {
   ENUM_SETUP_TYPE type; // LONG or SHORT
   double entryPrice;
   double stopLoss;
   double takeProfit;

   // Components (for scoring)
   bool hasBOS;
   bool hasBOSRetest;
   bool hasSweep;
   COrderBlock* orderBlock;
   CFairValueGap* fvg;
   ENUM_MTF_BIAS mtfBias;

   // Scoring
   double confluenceScore;
   double riskReward;
};
```

### Detection Pipeline

```mql5
void CSmartMoneyEA::OnTick() {
   // 1. Update all detectors
   m_obDetector.Update();
   m_fvgDetector.Update();
   m_bosDetector.Update();
   m_sweepDetector.Update();
   m_mtfAnalyzer.Update();

   // 2. Scan for new setups
   CSetup setup;
   if (ScanForSetups(setup)) {

      // 3. Calculate confluence score
      setup.confluenceScore = m_scorer.Calculate(setup);

      // 4. Validate entry
      if (ValidateEntry(setup)) {

         // 5. Execute trade
         ExecuteTrade(setup);
      }
   }
}

bool CSmartMoneyEA::ScanForSetups(CSetup &setup) {
   // Check for BOS
   if (m_bosDetector.HasBullishBOS()) {
      setup.type = SETUP_LONG;
      setup.hasBOS = true;

      // Look for retest or sweep
      if (m_sweepDetector.HasBullishSweep()) {
         setup.hasSweep = true;
      }

      // Look for POI (OB or FVG)
      COrderBlock* ob = m_obDetector.GetNearestBullishOB();
      if (ob != NULL) {
         setup.orderBlock = ob;
         setup.entryPrice = ob.low; // Enter at OB low
         setup.stopLoss = ob.low - (2.0 * ATR); // SL below OB
      }

      CFairValueGap* fvg = m_fvgDetector.GetNearestBullishFVG();
      if (fvg != NULL) {
         setup.fvg = fvg;
         // Adjust entry if FVG is closer
      }

      // MTF Bias
      setup.mtfBias = m_mtfAnalyzer.GetBias();

      // Calculate TP (structure-based)
      setup.takeProfit = CalculateStructureTarget(SETUP_LONG);

      // Validate RR
      setup.riskReward = (setup.takeProfit - setup.entryPrice) /
                         (setup.entryPrice - setup.stopLoss);

      return (setup.riskReward >= MinRR); // 2.0 minimum
   }

   // Similar logic for bearish setups...

   return false;
}
```

---

## 📊 Performance Optimization Strategies

### 1. Score Threshold Tuning

**Problem:** Too few/many trades
**Solution:**

```
If WR ≥ 90% but Trades/Day < 10:
   → Lower threshold from 100 to 90 (more signals)

If Trades/Day ≥ 10 but WR < 90%:
   → Raise threshold from 100 to 120 (more selective)
```

### 2. Component Weight Adjustment

**Problem:** Certain patterns have higher/lower WR
**Solution:** Backtest each component individually

```
Pattern Analysis:
- BOS + OB: 85% WR (40 trades)
- Sweep + FVG: 92% WR (25 trades)
- BOS + Sweep + OB + FVG: 95% WR (12 trades)

Optimization:
→ Increase Sweep weight from +25 to +35
→ Decrease OB-only weight from +20 to +15
```

### 3. MTF Filter Strictness

**Problem:** Counter-trend trades reducing WR
**Solution:**

```
Current: Allow counter-trend with -30 penalty
Strict Mode: Reject counter-trend entirely

If (MTF_COUNTER_TREND && RequireStrictMTF):
   return false; // Skip trade completely
```

### 4. OB Age Management

**Problem:** Old OBs have lower reliability
**Solution:**

```
OB Strength Decay:
- Age 0-20 bars: Full strength (no penalty)
- Age 21-50 bars: -1 point per 10 bars
- Age 51-100 bars: -2 points per 10 bars
- Age > 100 bars: Remove from active OBs
```

---

## 🎯 Advanced Concepts for Phase 2

### Volume Profile Integration

**When to Add:** If Phase 1 (SMC-only) WR < 90%

**Concept:**
Volume Profile identifies POC (Point of Control) = price with highest volume = fair value. OBs and FVGs near POC have higher probability.

**Implementation:**
```mql5
double CalculatePOC(ENUM_TIMEFRAMES timeframe, int lookback) {
   // Build volume profile
   double volumeByPrice[1000];
   ArrayInitialize(volumeByPrice, 0);

   double priceMin = Low[iLowest(Symbol(), timeframe, MODE_LOW, lookback, 0)];
   double priceMax = High[iHighest(Symbol(), timeframe, MODE_HIGH, lookback, 0)];
   double priceStep = (priceMax - priceMin) / 1000;

   // Accumulate volume at each price level
   for (int i = 0; i < lookback; i++) {
      double barVolume = Volume[i];
      double barLow = Low[i];
      double barHigh = High[i];

      // Distribute volume across price range
      for (double p = barLow; p <= barHigh; p += priceStep) {
         int index = (int)((p - priceMin) / priceStep);
         volumeByPrice[index] += barVolume;
      }
   }

   // Find price with max volume
   int maxIndex = ArrayMaximum(volumeByPrice);
   return priceMin + (maxIndex * priceStep);
}

// Confluence Scoring Addition
if (MathAbs(setup.entryPrice - POC_H1) < 10 * Point) {
   score += 15; // Entry near H1 POC
}
```

### Elliott Wave Integration

**When to Add:** If Phase 2 (SMC + VP) WR < 90%

**Concept:**
Elliott Wave identifies market cycle position. Wave 3 and Wave 5 = highest momentum phases. Only trade SMC signals during impulse waves.

**Simplified Implementation:**
```mql5
enum ENUM_WAVE_PHASE {
   WAVE_IMPULSE,     // Waves 1, 3, 5 (trend)
   WAVE_CORRECTION   // Waves 2, 4, ABC (chop)
};

ENUM_WAVE_PHASE DetectWavePhase(ENUM_TIMEFRAMES tf) {
   // Simplified: Compare recent swing sizes
   double swing1 = GetLastSwingSize(tf, 1);
   double swing2 = GetLastSwingSize(tf, 2);
   double swing3 = GetLastSwingSize(tf, 3);

   // Impulse: swings increasing in size (wave 3 extension)
   if (swing1 > swing2 && swing2 > swing3) {
      return WAVE_IMPULSE;
   }

   // Correction: swings decreasing or choppy
   return WAVE_CORRECTION;
}

// Filter Application
if (DetectWavePhase(PERIOD_H4) == WAVE_CORRECTION) {
   score -= 20; // Reduce score during corrections
}
```

---

## 📚 Reference Sources

### Internal Documentation
- **/Volumes/Data/Git/EA-OAT-v2/brain/strategy_research.md** - Comprehensive SMC/ICT methodology overview
- **/Volumes/Data/Git/EA-OAT-v2/brain/design_decisions.md** - Architectural and parameter decisions
- **/Volumes/Data/Git/EA-OAT-v2/brain/targets.md** - Performance targets and iteration tracking

### External Sources (Limited Access)

**Note:** Due to web access restrictions during research, the following are recommended sources for manual reference:

**Smart Money Concepts:**
- **ICT (Inner Circle Trader):** YouTube channel and teachings (Michael J. Huddleston)
  - Concepts: Order blocks, liquidity sweeps, fair value gaps, premium/discount zones
  - URL: https://www.youtube.com/@InnerCircleTrader (manual verification needed)

- **TradingView Pine Script Libraries:**
  - LuxAlgo Smart Money Concepts indicator
  - Toodegrees SMC indicator
  - URL: https://www.tradingview.com/scripts/ (search "Smart Money Concepts")

**Order Flow and Market Microstructure:**
- **Market Microstructure (Academic):**
  - Wikipedia: https://en.wikipedia.org/wiki/Market_microstructure
  - Concepts: Bid-ask spread, order book dynamics, institutional trading patterns

**MQL5 Implementation:**
- **MQL5 Documentation:**
  - Official reference: https://www.mql5.com/en/docs
  - Trading strategies articles: https://www.mql5.com/en/articles/trading-strategies

**Community Resources:**
- **Forex Factory Forums:** Smart Money trading discussions (access restricted during research)
- **BabyPips:** Educational content on price action and institutional trading

---

## 🎯 Implementation Checklist

### Phase 1: Core SMC Components

- [ ] **Order Block Detector**
  - [ ] Bullish OB detection (last bearish candle before rally)
  - [ ] Bearish OB detection (last bullish candle before selloff)
  - [ ] Strength scoring algorithm (7-point validation)
  - [ ] OB storage and management (max 20 active)
  - [ ] Age-based decay and removal

- [ ] **Fair Value Gap Detector**
  - [ ] Bullish FVG detection (3-candle gap pattern)
  - [ ] Bearish FVG detection
  - [ ] Gap size validation (0.3-2.0 ATR)
  - [ ] Fill percentage tracking
  - [ ] FVG invalidation when fully filled

- [ ] **Break of Structure Detector**
  - [ ] Swing high/low identification (fractal-based)
  - [ ] Bullish BOS detection (break above swing high)
  - [ ] Bearish BOS detection (break below swing low)
  - [ ] Momentum confirmation (candle body ≥ 0.5 ATR)
  - [ ] BOS retest detection (pullback to broken level)

- [ ] **Liquidity Sweep Detector**
  - [ ] Recent swing identification (10-30 bars)
  - [ ] Sweep penetration measurement (0.1-0.3 ATR)
  - [ ] Rejection confirmation (close back inside range)
  - [ ] Wick ratio validation (≥60% of candle)

- [ ] **MTF Bias Analyzer**
  - [ ] H1 trend detection (EMA or BOS-based)
  - [ ] H4 trend detection
  - [ ] Bias alignment check (both TFs agree)
  - [ ] Bias conflict detection (counter-trend penalty)

- [ ] **Confluence Scorer**
  - [ ] Component scoring logic (BOS, Sweep, OB, FVG, MTF)
  - [ ] Penalty application (counter-trend, weak OB)
  - [ ] Threshold validation (≥100 points)
  - [ ] Score logging for optimization

### Phase 2: Risk and Trade Management

- [ ] **Position Sizing**
  - [ ] 0.5% risk per trade calculation
  - [ ] Lot size validation (max 3.0 lots)
  - [ ] SL distance calculation (OB-based or ATR-based)

- [ ] **DCA Management**
  - [ ] Profit milestone detection (+0.75R, +1.5R)
  - [ ] DCA lot calculation (0.5×, 0.33× original)
  - [ ] Total lot enforcement (< maxLot)
  - [ ] DCA counter tracking (max 2 additions)

- [ ] **Breakeven and Trailing**
  - [ ] Breakeven trigger (+1R profit)
  - [ ] SL movement to entry price
  - [ ] Trailing stop activation (after BE)

- [ ] **Daily Drawdown Protection**
  - [ ] Daily start balance tracking
  - [ ] Real-time MDD calculation
  - [ ] Circuit breaker at 8% MDD
  - [ ] Trading halt until next day

### Phase 3: Backtesting and Analysis

- [ ] **OnTester() CSV Export**
  - [ ] Collect TesterStatistics
  - [ ] Calculate custom metrics (WR, RR, trades/day)
  - [ ] Write to CSV with FILE_COMMON flag
  - [ ] Include setup details (BOS, Sweep, OB, FVG flags)

- [ ] **Trade-by-Trade Logging**
  - [ ] Entry conditions (confluence score, components)
  - [ ] Exit reason (TP, SL, BE, manual)
  - [ ] Pattern classification (for Backtester analysis)

---

## 🚀 Next Steps

1. **Technical Analyst:** Convert this research into MQL5 technical specifications
2. **Reviewer:** Validate research completeness and technical accuracy
3. **Coder:** Implement detectors and scorers in MQL5
4. **Backtester:** Analyze which components have highest predictive power

---

**Status:** ✅ Research Complete
**Ready for:** Technical Analysis Phase (conversion to MQL5 specs)
