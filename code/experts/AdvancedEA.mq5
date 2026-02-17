//+------------------------------------------------------------------+
//| AdvancedEA.mq5                                                   |
//| EA-OAT-v2 - Smart Money Concepts Expert Advisor                 |
//| Copyright 2026, EA-OAT-v2                                        |
//+------------------------------------------------------------------+
#property copyright "EA-OAT-v2"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input group "═══ Score Threshold ═══"
input double inp_MinSMCScore = 100.0;     // Minimum SMC score for entry

input group "═══ Risk Management ═══"
input double inp_RiskPct = 0.5;           // Risk per trade (%)
input double inp_MaxLot = 3.0;            // Max lot size
input double inp_MinRR = 2.0;             // Min R:R ratio
input double inp_DailyMddMax = 8.0;       // Daily MDD limit (%)
input bool   inp_UseDailyMDD = true;      // Enable daily MDD
input double inp_BELevel_R = 1.0;         // Breakeven at +XR

input group "═══ BOS Detection ═══"
input int    inp_FractalK = 5;            // Fractal depth
input int    inp_LookbackBars = 100;      // Swing lookback
input double inp_MinBodyATR = 0.5;        // Min body (ATR)
input int    inp_MinBreakPts = 150;       // Min break (points)
input int    inp_BOS_TTL = 60;            // BOS TTL (bars)
input int    inp_RetestTolerance = 150;   // Retest zone (points)

input group "═══ Sweep Detection ═══"
input int    inp_LookbackLiq = 40;        // Swing lookback
input double inp_MinWickPct = 40.0;       // Min wick %
input int    inp_Sweep_TTL = 50;          // Sweep TTL

input group "═══ Order Block ═══"
input int    inp_OB_MaxTouches = 3;       // Max touches
input int    inp_OB_TTL = 100;            // OB TTL
input double inp_OB_VolMult = 1.5;        // Volume multiplier

input group "═══ FVG ═══"
input int    inp_FVG_MinPts = 100;        // Min FVG size (points)
input int    inp_FVG_TTL = 80;            // FVG TTL

input group "═══ Entry Timing ═══"
input double inp_ZoneTolerance = 0.0005; // Zone tolerance (0.05%)

//+------------------------------------------------------------------+
//| Enumerations                                                      |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_DIRECTION {
    SIGNAL_NONE = 0,
    SIGNAL_LONG = 1,
    SIGNAL_SHORT = -1
};

enum ENUM_MTF_BIAS {
    MTF_BEARISH = -1,
    MTF_NEUTRAL = 0,
    MTF_BULLISH = 1
};

//+------------------------------------------------------------------+
//| Swing Point (for BOS detection)                                  |
//+------------------------------------------------------------------+
struct SwingPoint {
    double   price;              // Swing price level
    datetime time;               // When swing occurred
    int      barIndex;           // Bar index in history
    int      type;               // 1 = high, -1 = low

    // Constructor
    void Reset() {
        price = 0;
        time = 0;
        barIndex = -1;
        type = 0;
    }
};

//+------------------------------------------------------------------+
//| Break of Structure Signal                                        |
//+------------------------------------------------------------------+
struct BOSSignal {
    bool     valid;              // Is BOS detected?
    int      direction;          // 1 = Bullish, -1 = Bearish
    double   breakLevel;         // Price level that was broken
    datetime breakTime;          // When break occurred
    int      barsAge;            // Age in bars since BOS
    bool     hasRetest;          // Price retested broken level?

    // Constructor
    void Reset() {
        valid = false;
        direction = 0;
        breakLevel = 0;
        breakTime = 0;
        barsAge = 0;
        hasRetest = false;
    }
};

//+------------------------------------------------------------------+
//| Liquidity Sweep Signal                                           |
//+------------------------------------------------------------------+
struct SweepSignal {
    bool     detected;           // Is sweep detected?
    int      side;               // 1 = Bullish sweep, -1 = Bearish sweep
    double   level;              // Price level that was swept
    double   penetration;        // Distance swept (in points)
    datetime time;               // When sweep occurred
    bool     confirmed;          // Close confirmed rejection?
    int      barsAge;            // Age in bars

    // Constructor
    void Reset() {
        detected = false;
        side = 0;
        level = 0;
        penetration = 0;
        time = 0;
        confirmed = false;
        barsAge = 0;
    }
};

//+------------------------------------------------------------------+
//| Order Block                                                       |
//+------------------------------------------------------------------+
struct OrderBlock {
    bool     valid;              // Is OB valid?
    int      direction;          // 1 = Bullish OB, -1 = Bearish OB
    double   priceTop;           // OB zone high
    double   priceBottom;        // OB zone low
    datetime createdTime;        // When OB formed
    int      strength;           // OB quality score (0-10)
    int      touchCount;         // Times price returned to OB
    int      barsAge;            // Age in bars

    // Constructor
    void Reset() {
        valid = false;
        direction = 0;
        priceTop = 0;
        priceBottom = 0;
        createdTime = 0;
        strength = 5;
        touchCount = 0;
        barsAge = 0;
    }
};

//+------------------------------------------------------------------+
//| Fair Value Gap Signal                                            |
//+------------------------------------------------------------------+
struct FVGSignal {
    bool     valid;              // Is FVG valid?
    int      direction;          // 1 = Bullish, -1 = Bearish
    double   priceTop;           // FVG upper bound
    double   priceBottom;        // FVG lower bound
    datetime createdTime;        // When FVG formed
    double   fillPercent;        // 0-100% filled
    bool     filled;             // Completely filled?
    int      barsAge;            // Age in bars

    // Constructor
    void Reset() {
        valid = false;
        direction = 0;
        priceTop = 0;
        priceBottom = 0;
        createdTime = 0;
        fillPercent = 0;
        filled = false;
        barsAge = 0;
    }
};

//+------------------------------------------------------------------+
//| Setup Candidate (Combined Signals)                              |
//+------------------------------------------------------------------+
struct SetupCandidate {
    bool     valid;              // Is candidate valid?
    int      direction;          // 1 = Long, -1 = Short

    // Component flags
    bool     hasBOS;             // Has BOS?
    bool     hasBOSRetest;       // Has BOS retest?
    bool     hasSweep;           // Has Sweep?
    bool     hasOB;              // Has Order Block?
    bool     hasFVG;             // Has FVG?
    int      mtfBias;            // -1, 0, 1

    // Signals
    int      bosAge;
    int      sweepAge;
    int      obStrength;
    int      fvgAge;

    // Scoring
    double   smcScore;           // Total SMC confluence score

    // Entry details
    double   entryPrice;         // Proposed entry
    double   stopLoss;           // Proposed SL
    double   takeProfit;         // Proposed TP
    double   riskReward;         // R:R ratio

    // Constructor
    void Reset() {
        valid = false;
        direction = 0;
        hasBOS = false;
        hasBOSRetest = false;
        hasSweep = false;
        hasOB = false;
        hasFVG = false;
        mtfBias = 0;
        bosAge = 999;
        sweepAge = 999;
        obStrength = 0;
        fvgAge = 999;
        smcScore = 0;
        entryPrice = 0;
        stopLoss = 0;
        takeProfit = 0;
        riskReward = 0;
    }
};

//+------------------------------------------------------------------+
//| Helper Functions for Indicators                                  |
//+------------------------------------------------------------------+
double GetATR(string symbol, ENUM_TIMEFRAMES period, int atr_period, int shift) {
    int handle = iATR(symbol, period, atr_period);
    if(handle == INVALID_HANDLE) return 0;

    double buffer[];
    ArraySetAsSeries(buffer, true);
    if(CopyBuffer(handle, 0, shift, 1, buffer) <= 0) {
        IndicatorRelease(handle);
        return 0;
    }

    double value = buffer[0];
    IndicatorRelease(handle);
    return value;
}

double GetMA(string symbol, ENUM_TIMEFRAMES period, int ma_period, int ma_shift,
             ENUM_MA_METHOD ma_method, ENUM_APPLIED_PRICE applied_price, int shift) {
    int handle = iMA(symbol, period, ma_period, ma_shift, ma_method, applied_price);
    if(handle == INVALID_HANDLE) return 0;

    double buffer[];
    ArraySetAsSeries(buffer, true);
    if(CopyBuffer(handle, 0, shift, 1, buffer) <= 0) {
        IndicatorRelease(handle);
        return 0;
    }

    double value = buffer[0];
    IndicatorRelease(handle);
    return value;
}

//+------------------------------------------------------------------+
//| Trigger Candle Detection - FIXED: Design Decision 14            |
//+------------------------------------------------------------------+
bool HasTriggerCandle(int direction, double minBodyATR, int lookback) {
    double atr = GetATR(_Symbol, _Period, 14, 1);
    if(atr <= 0) return false;

    for(int i = 0; i < lookback; i++) {
        double open = iOpen(_Symbol, _Period, i);
        double close = iClose(_Symbol, _Period, i);
        double body = MathAbs(close - open);

        if(direction == 1) {  // Bullish trigger
            if(close > open && body >= minBodyATR * atr) {
                return true;
            }
        } else if(direction == -1) {  // Bearish trigger
            if(close < open && body >= minBodyATR * atr) {
                return true;
            }
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Confirmation Candle Detection - PRIORITY 1 FIX                   |
//+------------------------------------------------------------------+
bool IsConfirmationCandle(int direction) {
    double open0 = iOpen(_Symbol, PERIOD_CURRENT, 0);
    double close0 = iClose(_Symbol, PERIOD_CURRENT, 0);
    double high0 = iHigh(_Symbol, PERIOD_CURRENT, 0);
    double low0 = iLow(_Symbol, PERIOD_CURRENT, 0);

    double bodySize = MathAbs(close0 - open0);
    double totalRange = high0 - low0;

    if(totalRange <= 0) return false;

    if(direction == 1) {  // LONG - need bullish confirmation
        // Bullish engulfing or strong bullish candle (body >= 60% of range)
        return (close0 > open0 && bodySize >= 0.6 * totalRange);
    } else {  // SHORT - need bearish confirmation
        // Bearish engulfing or strong bearish candle
        return (close0 < open0 && bodySize >= 0.6 * totalRange);
    }
}

//+------------------------------------------------------------------+
//| BOS Detector Class                                               |
//+------------------------------------------------------------------+
class CBOSDetector {
private:
    // Parameters
    int      m_fractalK;         // Fractal depth (default: 5)
    int      m_lookbackBars;     // Lookback window (default: 100)
    double   m_minBodyATR;       // Min candle body (default: 0.5)
    int      m_minBreakPts;      // Min break distance (default: 150 pts)
    int      m_ttl;              // Time-to-live (default: 60 bars)
    int      m_retestTolerance;  // Retest zone (default: 150 pts)

    // State
    SwingPoint m_lastSwingHigh;
    SwingPoint m_lastSwingLow;
    BOSSignal  m_currentBOS;

public:
    //+------------------------------------------------------------------+
    //| Initialize detector                                              |
    //+------------------------------------------------------------------+
    bool Init(int fractalK, int lookback, double minBodyATR, int minBreakPts,
              int ttl, int retestTolerance) {
        m_fractalK = fractalK;
        m_lookbackBars = lookback;
        m_minBodyATR = minBodyATR;
        m_minBreakPts = minBreakPts;
        m_ttl = ttl;
        m_retestTolerance = retestTolerance;

        m_lastSwingHigh.Reset();
        m_lastSwingLow.Reset();
        m_currentBOS.Reset();

        return true;
    }

    //+------------------------------------------------------------------+
    //| Update swing points (call on every bar)                         |
    //+------------------------------------------------------------------+
    void Update() {
        // Update swing highs
        for(int i = m_fractalK; i < m_lookbackBars; i++) {
            if(IsSwingHigh(i)) {
                // Found a swing high more recent than current
                if(m_lastSwingHigh.barIndex == -1 || i < m_lastSwingHigh.barIndex) {
                    m_lastSwingHigh.price = iHigh(_Symbol, _Period, i);
                    m_lastSwingHigh.time = iTime(_Symbol, _Period, i);
                    m_lastSwingHigh.barIndex = i;
                    m_lastSwingHigh.type = 1;
                    break;  // Found most recent, stop
                }
            }
        }

        // Update swing lows
        for(int i = m_fractalK; i < m_lookbackBars; i++) {
            if(IsSwingLow(i)) {
                if(m_lastSwingLow.barIndex == -1 || i < m_lastSwingLow.barIndex) {
                    m_lastSwingLow.price = iLow(_Symbol, _Period, i);
                    m_lastSwingLow.time = iTime(_Symbol, _Period, i);
                    m_lastSwingLow.barIndex = i;
                    m_lastSwingLow.type = -1;
                    break;
                }
            }
        }

        // Age current BOS
        if(m_currentBOS.valid) {
            m_currentBOS.barsAge++;
            if(m_currentBOS.barsAge > m_ttl) {
                m_currentBOS.Reset();  // Expired
            }
        }
    }

    //+------------------------------------------------------------------+
    //| Detect BOS on current bar                                       |
    //+------------------------------------------------------------------+
    BOSSignal DetectBOS() {
        BOSSignal signal;
        signal.Reset();

        // Return existing BOS if still valid
        if(m_currentBOS.valid && m_currentBOS.barsAge < m_ttl) {
            return m_currentBOS;
        }

        // Check for bullish BOS (break above swing high)
        if(m_lastSwingHigh.price > 0) {
            double close0 = iClose(_Symbol, _Period, 0);
            double open0 = iOpen(_Symbol, _Period, 0);
            double body = close0 - open0;
            double atr = GetATR(_Symbol, _Period, 14, 1);

            // Conditions:
            // 1. Close breaks above swing high
            // 2. Candle is bullish
            // 3. Body >= minBodyATR × ATR
            // 4. Break distance >= minBreakPts
            if(close0 > m_lastSwingHigh.price &&
               close0 > open0 &&
               body >= m_minBodyATR * atr &&
               (close0 - m_lastSwingHigh.price) >= m_minBreakPts * _Point) {

                signal.valid = true;
                signal.direction = 1;
                signal.breakLevel = m_lastSwingHigh.price;
                signal.breakTime = iTime(_Symbol, _Period, 0);
                signal.barsAge = 0;
                signal.hasRetest = false;

                m_currentBOS = signal;
                return signal;
            }
        }

        // Check for bearish BOS (break below swing low)
        if(m_lastSwingLow.price > 0) {
            double close0 = iClose(_Symbol, _Period, 0);
            double open0 = iOpen(_Symbol, _Period, 0);
            double body = open0 - close0;
            double atr = GetATR(_Symbol, _Period, 14, 1);

            if(close0 < m_lastSwingLow.price &&
               close0 < open0 &&
               body >= m_minBodyATR * atr &&
               (m_lastSwingLow.price - close0) >= m_minBreakPts * _Point) {

                signal.valid = true;
                signal.direction = -1;
                signal.breakLevel = m_lastSwingLow.price;
                signal.breakTime = iTime(_Symbol, _Period, 0);
                signal.barsAge = 0;
                signal.hasRetest = false;

                m_currentBOS = signal;
                return signal;
            }
        }

        return signal;  // No BOS detected
    }

    //+------------------------------------------------------------------+
    //| Check for BOS retest                                            |
    //+------------------------------------------------------------------+
    void UpdateBOSRetest() {
        if(!m_currentBOS.valid || m_currentBOS.hasRetest) return;

        double high0 = iHigh(_Symbol, _Period, 0);
        double low0 = iLow(_Symbol, _Period, 0);
        double tolerance = m_retestTolerance * _Point;

        // Bullish BOS: check if price returned down to break level
        if(m_currentBOS.direction == 1) {
            if(low0 <= m_currentBOS.breakLevel + tolerance) {
                m_currentBOS.hasRetest = true;
            }
        }
        // Bearish BOS: check if price returned up to break level
        else if(m_currentBOS.direction == -1) {
            if(high0 >= m_currentBOS.breakLevel - tolerance) {
                m_currentBOS.hasRetest = true;
            }
        }
    }

    //+------------------------------------------------------------------+
    //| Get current BOS signal                                          |
    //+------------------------------------------------------------------+
    BOSSignal GetCurrentBOS() {
        return m_currentBOS;
    }

private:
    //+------------------------------------------------------------------+
    //| Check if bar is a swing high (fractal)                          |
    //+------------------------------------------------------------------+
    bool IsSwingHigh(int index) {
        if(index - m_fractalK < 0 || index + m_fractalK >= iBars(_Symbol, _Period)) {
            return false;
        }

        double centerHigh = iHigh(_Symbol, _Period, index);

        // Check left side (must be lower)
        for(int i = 1; i <= m_fractalK; i++) {
            if(iHigh(_Symbol, _Period, index + i) >= centerHigh) {
                return false;
            }
        }

        // Check right side (must be lower)
        for(int i = 1; i <= m_fractalK; i++) {
            if(iHigh(_Symbol, _Period, index - i) > centerHigh) {
                return false;
            }
        }

        return true;
    }

    //+------------------------------------------------------------------+
    //| Check if bar is a swing low (fractal)                           |
    //+------------------------------------------------------------------+
    bool IsSwingLow(int index) {
        if(index - m_fractalK < 0 || index + m_fractalK >= iBars(_Symbol, _Period)) {
            return false;
        }

        double centerLow = iLow(_Symbol, _Period, index);

        // Check left side (must be higher)
        for(int i = 1; i <= m_fractalK; i++) {
            if(iLow(_Symbol, _Period, index + i) <= centerLow) {
                return false;
            }
        }

        // Check right side (must be higher)
        for(int i = 1; i <= m_fractalK; i++) {
            if(iLow(_Symbol, _Period, index - i) < centerLow) {
                return false;
            }
        }

        return true;
    }
};

//+------------------------------------------------------------------+
//| Sweep Detector Class                                             |
//+------------------------------------------------------------------+
class CSweepDetector {
private:
    int      m_lookbackBars;     // Lookback for swings (default: 40)
    double   m_minWickPct;       // Min wick % (default: 40%)
    int      m_ttl;              // Time-to-live (default: 50)

    SweepSignal m_currentSweep;

public:
    bool Init(int lookback, double minWickPct, int ttl) {
        m_lookbackBars = lookback;
        m_minWickPct = minWickPct;
        m_ttl = ttl;
        m_currentSweep.Reset();
        return true;
    }

    void Update() {
        if(m_currentSweep.detected) {
            m_currentSweep.barsAge++;
            if(m_currentSweep.barsAge > m_ttl) {
                m_currentSweep.Reset();
            }
        }
    }

    SweepSignal DetectSweep() {
        SweepSignal signal;
        signal.Reset();

        // Return existing sweep if still valid
        if(m_currentSweep.detected && m_currentSweep.barsAge < m_ttl) {
            return m_currentSweep;
        }

        // Find recent swing low
        double swingLow = 9999999;
        int swingLowIdx = -1;
        for(int i = 1; i < m_lookbackBars; i++) {
            double low = iLow(_Symbol, _Period, i);
            if(low < swingLow) {
                swingLow = low;
                swingLowIdx = i;
            }
        }

        // Find recent swing high
        double swingHigh = 0;
        int swingHighIdx = -1;
        for(int i = 1; i < m_lookbackBars; i++) {
            double high = iHigh(_Symbol, _Period, i);
            if(high > swingHigh) {
                swingHigh = high;
                swingHighIdx = i;
            }
        }

        double atr = GetATR(_Symbol, _Period, 14, 1);
        double low0 = iLow(_Symbol, _Period, 0);
        double high0 = iHigh(_Symbol, _Period, 0);
        double close0 = iClose(_Symbol, _Period, 0);
        double candleRange = high0 - low0;

        // Check bullish sweep (sweep low, reject up)
        if(swingLowIdx >= 0 && low0 < swingLow) {
            double penetration = swingLow - low0;
            double lowerWick = MathMin(iOpen(_Symbol, _Period, 0), close0) - low0;

            // Conditions:
            // 1. Penetration between 0.1-0.3 ATR
            // 2. Close back above swing low
            // 3. Lower wick >= 60% of range
            if(penetration >= 0.1 * atr &&
               penetration <= 0.3 * atr &&
               close0 > swingLow &&
               candleRange > 0 &&
               lowerWick >= m_minWickPct / 100.0 * candleRange) {

                signal.detected = true;
                signal.side = 1;
                signal.level = swingLow;
                signal.penetration = penetration / _Point;
                signal.time = iTime(_Symbol, _Period, 0);
                signal.confirmed = true;
                signal.barsAge = 0;

                m_currentSweep = signal;
                return signal;
            }
        }

        // Check bearish sweep (sweep high, reject down)
        if(swingHighIdx >= 0 && high0 > swingHigh) {
            double penetration = high0 - swingHigh;
            double upperWick = high0 - MathMax(iOpen(_Symbol, _Period, 0), close0);

            if(penetration >= 0.1 * atr &&
               penetration <= 0.3 * atr &&
               close0 < swingHigh &&
               candleRange > 0 &&
               upperWick >= m_minWickPct / 100.0 * candleRange) {

                signal.detected = true;
                signal.side = -1;
                signal.level = swingHigh;
                signal.penetration = penetration / _Point;
                signal.time = iTime(_Symbol, _Period, 0);
                signal.confirmed = true;
                signal.barsAge = 0;

                m_currentSweep = signal;
                return signal;
            }
        }

        return signal;
    }

    SweepSignal GetCurrentSweep() {
        return m_currentSweep;
    }
};

//+------------------------------------------------------------------+
//| Order Block Detector Class                                       |
//+------------------------------------------------------------------+
class COrderBlockDetector {
private:
    int      m_maxTouches;
    int      m_ttl;
    double   m_volMultiplier;

    OrderBlock m_bullishOB;
    OrderBlock m_bearishOB;

public:
    bool Init(int maxTouches, int ttl, double volMultiplier) {
        m_maxTouches = maxTouches;
        m_ttl = ttl;
        m_volMultiplier = volMultiplier;
        m_bullishOB.Reset();
        m_bearishOB.Reset();
        return true;
    }

    void Update() {
        // Age OBs
        if(m_bullishOB.valid) {
            m_bullishOB.barsAge++;
            if(m_bullishOB.barsAge > m_ttl || m_bullishOB.touchCount >= m_maxTouches) {
                m_bullishOB.Reset();
            }
        }

        if(m_bearishOB.valid) {
            m_bearishOB.barsAge++;
            if(m_bearishOB.barsAge > m_ttl || m_bearishOB.touchCount >= m_maxTouches) {
                m_bearishOB.Reset();
            }
        }

        // Check for touches
        double high0 = iHigh(_Symbol, _Period, 0);
        double low0 = iLow(_Symbol, _Period, 0);

        if(m_bullishOB.valid) {
            if(low0 <= m_bullishOB.priceTop && high0 >= m_bullishOB.priceBottom) {
                m_bullishOB.touchCount++;
            }
        }

        if(m_bearishOB.valid) {
            if(low0 <= m_bearishOB.priceTop && high0 >= m_bearishOB.priceBottom) {
                m_bearishOB.touchCount++;
            }
        }
    }

    void DetectOrderBlocks() {
        // Scan recent bars for bullish OB
        for(int i = 1; i < 10; i++) {
            if(IsBullishOB(i)) {
                // Found a bullish OB, store it
                m_bullishOB.valid = true;
                m_bullishOB.direction = 1;
                m_bullishOB.priceTop = iHigh(_Symbol, _Period, i);
                m_bullishOB.priceBottom = iLow(_Symbol, _Period, i);
                m_bullishOB.createdTime = iTime(_Symbol, _Period, i);
                m_bullishOB.strength = CalculateOBStrength(m_bullishOB);
                m_bullishOB.touchCount = 0;
                m_bullishOB.barsAge = 0;
                break;  // Take most recent
            }
        }

        // Scan for bearish OB
        for(int i = 1; i < 10; i++) {
            if(IsBearishOB(i)) {
                m_bearishOB.valid = true;
                m_bearishOB.direction = -1;
                m_bearishOB.priceTop = iHigh(_Symbol, _Period, i);
                m_bearishOB.priceBottom = iLow(_Symbol, _Period, i);
                m_bearishOB.createdTime = iTime(_Symbol, _Period, i);
                m_bearishOB.strength = CalculateOBStrength(m_bearishOB);
                m_bearishOB.touchCount = 0;
                m_bearishOB.barsAge = 0;
                break;
            }
        }
    }

    OrderBlock GetBullishOB() { return m_bullishOB; }
    OrderBlock GetBearishOB() { return m_bearishOB; }

private:
    bool IsBullishOB(int index) {
        // Bearish candle
        double close = iClose(_Symbol, _Period, index);
        double open = iOpen(_Symbol, _Period, index);
        if(close >= open) return false;

        // Check next 2-3 candles are bullish with momentum
        double totalMove = 0;
        for(int i = index - 1; i >= MathMax(0, index - 3); i--) {
            double c = iClose(_Symbol, _Period, i);
            double o = iOpen(_Symbol, _Period, i);
            if(c <= o) return false;  // Not bullish
            totalMove += (c - o);
        }

        double atr = GetATR(_Symbol, _Period, 14, index);
        return (totalMove >= 1.5 * atr);
    }

    bool IsBearishOB(int index) {
        // Bullish candle
        double close = iClose(_Symbol, _Period, index);
        double open = iOpen(_Symbol, _Period, index);
        if(close <= open) return false;

        // Check next 2-3 candles are bearish with momentum
        double totalMove = 0;
        for(int i = index - 1; i >= MathMax(0, index - 3); i--) {
            double c = iClose(_Symbol, _Period, i);
            double o = iOpen(_Symbol, _Period, i);
            if(c >= o) return false;
            totalMove += (o - c);
        }

        double atr = GetATR(_Symbol, _Period, 14, index);
        return (totalMove >= 1.5 * atr);
    }

    int CalculateOBStrength(OrderBlock &ob) {
        // FIXED: Start with base 8 to allow Strong OBs (>=7)
        int score = 8;

        // Age penalty (gradual)
        if(ob.barsAge > 80) score -= 3;
        else if(ob.barsAge > 50) score -= 1;

        // Touch penalty (first touch okay, multiple touches reduce strength)
        if(ob.touchCount >= 2) score -= 3;
        else if(ob.touchCount >= 1) score -= 1;

        // Clamp 0-10
        if(score < 0) score = 0;
        if(score > 10) score = 10;

        return score;
    }
};

//+------------------------------------------------------------------+
//| FVG Detector Class                                               |
//+------------------------------------------------------------------+
class CFVGDetector {
private:
    int      m_minPts;
    int      m_ttl;

    FVGSignal m_bullishFVG;
    FVGSignal m_bearishFVG;

public:
    bool Init(int minPts, int ttl) {
        m_minPts = minPts;
        m_ttl = ttl;
        m_bullishFVG.Reset();
        m_bearishFVG.Reset();
        return true;
    }

    void Update() {
        if(m_bullishFVG.valid) {
            m_bullishFVG.barsAge++;
            UpdateFVGFill(m_bullishFVG);
            if(m_bullishFVG.barsAge > m_ttl || m_bullishFVG.filled) {
                m_bullishFVG.Reset();
            }
        }

        if(m_bearishFVG.valid) {
            m_bearishFVG.barsAge++;
            UpdateFVGFill(m_bearishFVG);
            if(m_bearishFVG.barsAge > m_ttl || m_bearishFVG.filled) {
                m_bearishFVG.Reset();
            }
        }
    }

    void DetectFVGs() {
        // Scan for bullish FVG (gap between bar[i+2].high and bar[i].low)
        for(int i = 2; i < 20; i++) {
            double high_i_plus_2 = iHigh(_Symbol, _Period, i + 2);
            double low_i = iLow(_Symbol, _Period, i);
            double gapSize = low_i - high_i_plus_2;
            double atr = GetATR(_Symbol, _Period, 14, i);

            if(gapSize >= 0.3 * atr && gapSize <= 2.0 * atr &&
               gapSize >= m_minPts * _Point) {

                // Check middle candle is bullish
                if(iClose(_Symbol, _Period, i + 1) > iOpen(_Symbol, _Period, i + 1)) {
                    m_bullishFVG.valid = true;
                    m_bullishFVG.direction = 1;
                    m_bullishFVG.priceTop = low_i;
                    m_bullishFVG.priceBottom = high_i_plus_2;
                    m_bullishFVG.createdTime = iTime(_Symbol, _Period, i);
                    m_bullishFVG.fillPercent = 0;
                    m_bullishFVG.filled = false;
                    m_bullishFVG.barsAge = 0;
                    break;
                }
            }
        }

        // Scan for bearish FVG
        for(int i = 2; i < 20; i++) {
            double low_i_plus_2 = iLow(_Symbol, _Period, i + 2);
            double high_i = iHigh(_Symbol, _Period, i);
            double gapSize = low_i_plus_2 - high_i;
            double atr = GetATR(_Symbol, _Period, 14, i);

            if(gapSize >= 0.3 * atr && gapSize <= 2.0 * atr &&
               gapSize >= m_minPts * _Point) {

                if(iClose(_Symbol, _Period, i + 1) < iOpen(_Symbol, _Period, i + 1)) {
                    m_bearishFVG.valid = true;
                    m_bearishFVG.direction = -1;
                    m_bearishFVG.priceTop = low_i_plus_2;
                    m_bearishFVG.priceBottom = high_i;
                    m_bearishFVG.createdTime = iTime(_Symbol, _Period, i);
                    m_bearishFVG.fillPercent = 0;
                    m_bearishFVG.filled = false;
                    m_bearishFVG.barsAge = 0;
                    break;
                }
            }
        }
    }

    FVGSignal GetBullishFVG() { return m_bullishFVG; }
    FVGSignal GetBearishFVG() { return m_bearishFVG; }

private:
    void UpdateFVGFill(FVGSignal &fvg) {
        double high0 = iHigh(_Symbol, _Period, 0);
        double low0 = iLow(_Symbol, _Period, 0);
        double gapSize = fvg.priceTop - fvg.priceBottom;

        if(gapSize <= 0) return;

        double filled = 0;
        if(fvg.direction == 1) {  // Bullish FVG
            if(low0 <= fvg.priceTop) {
                filled = fvg.priceTop - MathMax(low0, fvg.priceBottom);
            }
        } else {  // Bearish FVG
            if(high0 >= fvg.priceBottom) {
                filled = MathMin(high0, fvg.priceTop) - fvg.priceBottom;
            }
        }

        fvg.fillPercent = (filled / gapSize) * 100.0;

        if(fvg.fillPercent >= 85.0) {
            fvg.filled = true;
        }
    }
};

//+------------------------------------------------------------------+
//| MTF Bias Analyzer Class                                          |
//+------------------------------------------------------------------+
class CMTFBiasAnalyzer {
public:
    int GetMTFBias() {
        // H1 trend
        double ema20_h1 = GetMA(_Symbol, PERIOD_H1, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
        double ema50_h1 = GetMA(_Symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
        bool h1Bullish = (ema20_h1 > ema50_h1);
        bool h1Bearish = (ema20_h1 < ema50_h1);

        // H4 trend
        double ema20_h4 = GetMA(_Symbol, PERIOD_H4, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
        double ema50_h4 = GetMA(_Symbol, PERIOD_H4, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
        bool h4Bullish = (ema20_h4 > ema50_h4);
        bool h4Bearish = (ema20_h4 < ema50_h4);

        // Both agree
        if(h1Bullish && h4Bullish) return MTF_BULLISH;
        if(h1Bearish && h4Bearish) return MTF_BEARISH;

        return MTF_NEUTRAL;
    }
};

//+------------------------------------------------------------------+
//| Confluence Scorer Class                                          |
//+------------------------------------------------------------------+
class CConfluenceScorer {
private:
    double m_minRR;

public:
    bool Init(double minRR) {
        m_minRR = minRR;
        return true;
    }

    SetupCandidate BuildCandidate(BOSSignal &bos, SweepSignal &sweep,
                                   OrderBlock &ob_bull, OrderBlock &ob_bear,
                                   FVGSignal &fvg_bull, FVGSignal &fvg_bear,
                                   int mtfBias) {
        SetupCandidate candidate;
        candidate.Reset();

        // Determine direction (BOS or Sweep)
        if(bos.valid) {
            candidate.direction = bos.direction;
            candidate.hasBOS = true;
            candidate.hasBOSRetest = bos.hasRetest;
            candidate.bosAge = bos.barsAge;
        } else if(sweep.detected) {
            candidate.direction = sweep.side;
            candidate.hasSweep = true;
            candidate.sweepAge = sweep.barsAge;
        } else {
            return candidate;  // No signal
        }

        // Check for OB in direction
        if(candidate.direction == 1 && ob_bull.valid) {
            candidate.hasOB = true;
            candidate.obStrength = ob_bull.strength;
        } else if(candidate.direction == -1 && ob_bear.valid) {
            candidate.hasOB = true;
            candidate.obStrength = ob_bear.strength;
        }

        // Check for FVG in direction
        if(candidate.direction == 1 && fvg_bull.valid) {
            candidate.hasFVG = true;
            candidate.fvgAge = fvg_bull.barsAge;
        } else if(candidate.direction == -1 && fvg_bear.valid) {
            candidate.hasFVG = true;
            candidate.fvgAge = fvg_bear.barsAge;
        }

        // MTF bias
        candidate.mtfBias = mtfBias;

        // Entry/SL/TP
        CalculateEntryLevels(candidate, bos, ob_bull, ob_bear, fvg_bull, fvg_bear);

        // Score
        candidate.smcScore = CalculateScore(candidate);

        // Valid if score >= 100
        candidate.valid = (candidate.smcScore >= 100.0);

        return candidate;
    }

    double CalculateScore(SetupCandidate &candidate) {
        double score = 0;

        // BOS
        if(candidate.hasBOS) {
            score += candidate.hasBOSRetest ? 50 : 30;
        }

        // Sweep
        if(candidate.hasSweep) {
            score += 25;
        }

        // OB
        if(candidate.hasOB) {
            if(candidate.obStrength >= 7) score += 20;
            else if(candidate.obStrength >= 4) score += 10;
            else score -= 10;
        }

        // FVG
        if(candidate.hasFVG) {
            score += 15;
        }

        // MTF
        if(candidate.mtfBias == candidate.direction) {
            score += 20;
        } else if(candidate.mtfBias == -candidate.direction) {
            score -= 30;
        }

        // R:R penalty
        if(candidate.riskReward < 1.5) {
            score -= 20;
        }

        // OB touch multiplier
        if(candidate.hasOB && candidate.obStrength <= 5) {
            score *= 0.5;
        }

        return score;
    }

private:
    void CalculateEntryLevels(SetupCandidate &candidate, BOSSignal &bos,
                               OrderBlock &ob_bull, OrderBlock &ob_bear,
                               FVGSignal &fvg_bull, FVGSignal &fvg_bear) {
        double atr = GetATR(_Symbol, _Period, 14, 0);

        if(candidate.direction == 1) {  // LONG
            // PRIORITY 1 FIX: Check if price is NEAR the OB zone
            double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double obZone = 0;

            if(candidate.hasOB && ob_bull.valid) {
                obZone = ob_bull.priceBottom;
                double tolerance = inp_ZoneTolerance * currentPrice;

                // Price must be AT the OB zone (within tolerance)
                if(MathAbs(currentPrice - obZone) > tolerance) {
                    // Price not at OB yet - invalidate candidate
                    candidate.valid = false;
                    return;
                }

                // Price is at OB zone - use current price for entry
                candidate.entryPrice = currentPrice;
            } else {
                // No OB - use current ask
                candidate.entryPrice = currentPrice;
            }

            // SL: below OB or entry - 2 ATR
            if(candidate.hasOB && ob_bull.valid) {
                candidate.stopLoss = ob_bull.priceBottom - (2.0 * atr);
            } else {
                candidate.stopLoss = candidate.entryPrice - (2.0 * atr);
            }

            // TP: next structure or entry + 2×SL distance
            double slDist = candidate.entryPrice - candidate.stopLoss;
            candidate.takeProfit = candidate.entryPrice + (2.0 * slDist);
        }
        else {  // SHORT
            // PRIORITY 1 FIX: Check if price is NEAR the OB zone
            double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double obZone = 0;

            if(candidate.hasOB && ob_bear.valid) {
                obZone = ob_bear.priceTop;
                double tolerance = inp_ZoneTolerance * currentPrice;

                // Price must be AT the OB zone (within tolerance)
                if(MathAbs(currentPrice - obZone) > tolerance) {
                    // Price not at OB yet - invalidate candidate
                    candidate.valid = false;
                    return;
                }

                // Price is at OB zone - use current price for entry
                candidate.entryPrice = currentPrice;
            } else {
                // No OB - use current bid
                candidate.entryPrice = currentPrice;
            }

            if(candidate.hasOB && ob_bear.valid) {
                candidate.stopLoss = ob_bear.priceTop + (2.0 * atr);
            } else {
                candidate.stopLoss = candidate.entryPrice + (2.0 * atr);
            }

            double slDist = candidate.stopLoss - candidate.entryPrice;
            candidate.takeProfit = candidate.entryPrice - (2.0 * slDist);
        }

        // Calculate R:R
        double reward = MathAbs(candidate.takeProfit - candidate.entryPrice);
        double risk = MathAbs(candidate.entryPrice - candidate.stopLoss);
        candidate.riskReward = (risk > 0) ? (reward / risk) : 0;
    }
};

//+------------------------------------------------------------------+
//| Risk Manager Class                                               |
//+------------------------------------------------------------------+
class CRiskManager {
private:
    double m_riskPct;
    double m_maxLot;
    double m_dailyMddMax;
    bool   m_useDailyMDD;
    double m_dailyStartBalance;
    bool   m_tradingHalted;
    double m_beLevel_R;

public:
    bool Init(double riskPct, double maxLot, double dailyMddMax,
              bool useMDD, double beLevel_R) {
        m_riskPct = riskPct;
        m_maxLot = maxLot;
        m_dailyMddMax = dailyMddMax;
        m_useDailyMDD = useMDD;
        m_beLevel_R = beLevel_R;
        m_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        m_tradingHalted = false;
        return true;
    }

    double CalculateLotSize(double slDistancePts) {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double riskAmount = balance * (m_riskPct / 100.0);

        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

        double lots = (riskAmount / slDistancePts) * (tickSize / tickValue);

        // PRIORITY 2 FIX: Log all risk calculation values
        Print("RISK CALC: Balance=", balance, " Risk%=", m_riskPct,
              " RiskAmt=", riskAmount, " SL_Pts=", slDistancePts,
              " TickVal=", tickValue, " TickSize=", tickSize,
              " Lots_Raw=", lots);

        // Limits
        double lotMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double lotMax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
        double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

        lots = MathMax(lots, lotMin);
        lots = MathMin(lots, m_maxLot);
        lots = MathMin(lots, lotMax);
        lots = MathFloor(lots / lotStep) * lotStep;

        return lots;
    }

    bool CheckDailyMDD() {
        if(!m_useDailyMDD) return true;

        // Reset check
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        static int lastDay = -1;

        if(dt.day != lastDay) {
            lastDay = dt.day;
            m_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
            m_tradingHalted = false;
        }

        double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        double dd = ((m_dailyStartBalance - currentBalance) / m_dailyStartBalance) * 100.0;

        if(dd >= m_dailyMddMax) {
            if(!m_tradingHalted) {
                Print("🔴 TRADING HALTED - Daily MDD: ", dd, "%");
                m_tradingHalted = true;
            }
            return false;
        }

        return true;
    }

    bool IsTradingHalted() { return m_tradingHalted; }

    void ManagePositions() {
        for(int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong ticket = PositionGetTicket(i);
            if(!PositionSelectByTicket(ticket)) continue;
            if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

            ApplyBreakeven(ticket);
        }
    }

private:
    void ApplyBreakeven(ulong ticket) {
        if(!PositionSelectByTicket(ticket)) return;

        double entry = PositionGetDouble(POSITION_PRICE_OPEN);
        double sl = PositionGetDouble(POSITION_SL);
        double tp = PositionGetDouble(POSITION_TP);
        double current = PositionGetDouble(POSITION_PRICE_CURRENT);
        int type = (int)PositionGetInteger(POSITION_TYPE);

        double risk = MathAbs(entry - sl);
        double profit = (type == POSITION_TYPE_BUY) ? (current - entry) : (entry - current);
        double profitR = (risk > 0) ? (profit / risk) : 0;

        if(profitR >= m_beLevel_R) {
            // Check if already at BE
            if(MathAbs(sl - entry) > 10 * _Point) {
                CTrade trade;
                if(trade.PositionModify(ticket, entry, tp)) {
                    Print("🎯 Breakeven applied: ", ticket);
                }
            }
        }
    }
};

//+------------------------------------------------------------------+
//| Global Objects                                                    |
//+------------------------------------------------------------------+
CBOSDetector*        g_bosDetector = NULL;
CSweepDetector*      g_sweepDetector = NULL;
COrderBlockDetector* g_obDetector = NULL;
CFVGDetector*        g_fvgDetector = NULL;
CMTFBiasAnalyzer*    g_mtfAnalyzer = NULL;
CConfluenceScorer*   g_scorer = NULL;
CRiskManager*        g_riskMgr = NULL;

datetime g_lastBarTime = 0;

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit() {
    Print("AdvancedEA v1.00 - Initializing...");

    // Create detectors
    g_bosDetector = new CBOSDetector();
    g_bosDetector.Init(inp_FractalK, inp_LookbackBars, inp_MinBodyATR,
                       inp_MinBreakPts, inp_BOS_TTL, inp_RetestTolerance);

    g_sweepDetector = new CSweepDetector();
    g_sweepDetector.Init(inp_LookbackLiq, inp_MinWickPct, inp_Sweep_TTL);

    g_obDetector = new COrderBlockDetector();
    g_obDetector.Init(inp_OB_MaxTouches, inp_OB_TTL, inp_OB_VolMult);

    g_fvgDetector = new CFVGDetector();
    g_fvgDetector.Init(inp_FVG_MinPts, inp_FVG_TTL);

    g_mtfAnalyzer = new CMTFBiasAnalyzer();

    g_scorer = new CConfluenceScorer();
    g_scorer.Init(inp_MinRR);

    g_riskMgr = new CRiskManager();
    g_riskMgr.Init(inp_RiskPct, inp_MaxLot, inp_DailyMddMax,
                   inp_UseDailyMDD, inp_BELevel_R);

    g_lastBarTime = iTime(_Symbol, _Period, 0);

    Print("✅ AdvancedEA initialized successfully");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    if(CheckPointer(g_bosDetector) == POINTER_DYNAMIC) delete g_bosDetector;
    if(CheckPointer(g_sweepDetector) == POINTER_DYNAMIC) delete g_sweepDetector;
    if(CheckPointer(g_obDetector) == POINTER_DYNAMIC) delete g_obDetector;
    if(CheckPointer(g_fvgDetector) == POINTER_DYNAMIC) delete g_fvgDetector;
    if(CheckPointer(g_mtfAnalyzer) == POINTER_DYNAMIC) delete g_mtfAnalyzer;
    if(CheckPointer(g_scorer) == POINTER_DYNAMIC) delete g_scorer;
    if(CheckPointer(g_riskMgr) == POINTER_DYNAMIC) delete g_riskMgr;
}

//+------------------------------------------------------------------+
//| OnTick                                                            |
//+------------------------------------------------------------------+
void OnTick() {
    // Check for new bar
    datetime currentBarTime = iTime(_Symbol, _Period, 0);
    bool newBar = (currentBarTime != g_lastBarTime);
    if(!newBar) {
        g_riskMgr.ManagePositions();  // Manage BE/trailing every tick
        return;
    }
    g_lastBarTime = currentBarTime;

    // Daily MDD check
    if(!g_riskMgr.CheckDailyMDD()) return;

    // Update all detectors
    g_bosDetector.Update();
    g_sweepDetector.Update();
    g_obDetector.Update();
    g_fvgDetector.Update();

    // Detect patterns
    BOSSignal bos = g_bosDetector.DetectBOS();
    g_bosDetector.UpdateBOSRetest();

    SweepSignal sweep = g_sweepDetector.DetectSweep();

    g_obDetector.DetectOrderBlocks();
    OrderBlock ob_bull = g_obDetector.GetBullishOB();
    OrderBlock ob_bear = g_obDetector.GetBearishOB();

    g_fvgDetector.DetectFVGs();
    FVGSignal fvg_bull = g_fvgDetector.GetBullishFVG();
    FVGSignal fvg_bear = g_fvgDetector.GetBearishFVG();

    int mtfBias = g_mtfAnalyzer.GetMTFBias();

    // Build candidate
    SetupCandidate candidate = g_scorer.BuildCandidate(bos, sweep,
                                                        ob_bull, ob_bear,
                                                        fvg_bull, fvg_bear,
                                                        mtfBias);

    if(!candidate.valid) return;
    if(candidate.smcScore < inp_MinSMCScore) return;
    if(candidate.riskReward < inp_MinRR) return;

    // FIXED: Check for trigger candle before entry
    if(!HasTriggerCandle(candidate.direction, 0.30, 4)) return;

    // PRIORITY 1 FIX: Check for confirmation candle at POI zone
    if(!IsConfirmationCandle(candidate.direction)) return;

    // Check for existing positions
    if(PositionsTotal() > 0) return;  // Only 1 position at a time

    // Calculate lot
    double slDist = MathAbs(candidate.entryPrice - candidate.stopLoss) / _Point;
    double lots = g_riskMgr.CalculateLotSize(slDist);

    // Place order
    CTrade trade;
    bool success = false;

    // FIXED: Include MTF in comment
    string comment = StringFormat("SMC:%.0f|BOS:%d|SW:%d|OB:%d|FVG:%d|MTF:%d",
                                   candidate.smcScore,
                                   candidate.hasBOS ? 1 : 0,
                                   candidate.hasSweep ? 1 : 0,
                                   candidate.hasOB ? 1 : 0,
                                   candidate.hasFVG ? 1 : 0,
                                   mtfBias);

    if(candidate.direction == 1) {
        success = trade.Buy(lots, _Symbol, 0, candidate.stopLoss,
                           candidate.takeProfit, comment);
    } else {
        success = trade.Sell(lots, _Symbol, 0, candidate.stopLoss,
                            candidate.takeProfit, comment);
    }

    if(success) {
        Print("✅ Trade opened: ", comment, " | Lot: ", lots, " | R:R: ", candidate.riskReward);

        // PRIORITY 2 FIX: Verify SL was actually set
        if(PositionSelect(_Symbol)) {
            double actualSL = PositionGetDouble(POSITION_SL);
            double actualTP = PositionGetDouble(POSITION_TP);
            Print("SL VERIFY: Requested=", candidate.stopLoss, " Actual=", actualSL,
                  " | TP Requested=", candidate.takeProfit, " Actual=", actualTP);
        }
    } else {
        Print("❌ Trade FAILED: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
    }
}

//+------------------------------------------------------------------+
//| OnTester                                                          |
//+------------------------------------------------------------------+
double OnTester() {
    // Trade counts
    double totalTrades = TesterStatistics(STAT_TRADES);
    double profitTrades = TesterStatistics(STAT_PROFIT_TRADES);
    double lossTrades = TesterStatistics(STAT_LOSS_TRADES);

    // Gross profit/loss
    double grossProfit = TesterStatistics(STAT_GROSS_PROFIT);
    double grossLoss = TesterStatistics(STAT_GROSS_LOSS);

    // Calculate win rate
    double winRate = (totalTrades > 0) ? (profitTrades / totalTrades * 100.0) : 0;

    // Calculate R:R (avg win / avg loss)
    double avgWin = (profitTrades > 0) ? grossProfit / profitTrades : 0;
    double avgLoss = (lossTrades > 0) ? MathAbs(grossLoss) / lossTrades : 0;
    double rr = (avgLoss > 0) ? avgWin / avgLoss : 0;

    // Other metrics
    double maxDD = TesterStatistics(STAT_BALANCE_DDREL_PERCENT);
    double profitFactor = TesterStatistics(STAT_PROFIT_FACTOR);

    // CSV export
    string filename = "AdvancedEA_backtest_" + TimeToString(TimeCurrent(), TIME_DATE) + ".csv";
    int handle = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_COMMON | FILE_ANSI);

    if(handle != INVALID_HANDLE) {
        FileWrite(handle, "Metric", "Value");
        FileWrite(handle, "Win Rate %", DoubleToString(winRate, 2));
        FileWrite(handle, "Risk Reward", DoubleToString(rr, 2));
        FileWrite(handle, "Total Trades", DoubleToString(totalTrades, 0));
        FileWrite(handle, "Max DD %", DoubleToString(maxDD, 2));
        FileWrite(handle, "Profit Factor", DoubleToString(profitFactor, 2));
        FileWrite(handle, "Net Profit", DoubleToString(TesterStatistics(STAT_PROFIT), 2));
        FileWrite(handle, "Sharpe Ratio", DoubleToString(TesterStatistics(STAT_SHARPE_RATIO), 2));
        FileClose(handle);

        Print("✅ CSV exported: ", filename);
    }

    // PRIORITY 3 FIX: Export individual trade history
    string tradeFile = "trade_history.csv";
    int tradeHandle = FileOpen(tradeFile, FILE_WRITE|FILE_CSV|FILE_COMMON, ",");
    if(tradeHandle != INVALID_HANDLE) {
        // Header
        FileWrite(tradeHandle, "Ticket", "Type", "OpenTime", "CloseTime",
                  "OpenPrice", "ClosePrice", "SL", "TP", "Lots",
                  "Profit", "Comment");

        // Loop through history
        HistorySelect(0, TimeCurrent());
        int totalDeals = HistoryDealsTotal();
        int exportCount = 0;

        for(int i = 0; i < totalDeals; i++) {
            ulong ticket = HistoryDealGetTicket(i);
            if(ticket > 0) {
                ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
                if(entry == DEAL_ENTRY_OUT) {  // Closed trade
                    long dealType = HistoryDealGetInteger(ticket, DEAL_TYPE);
                    datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
                    double dealPrice = HistoryDealGetDouble(ticket, DEAL_PRICE);
                    double dealVolume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
                    double dealProfit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                    string dealComment = HistoryDealGetString(ticket, DEAL_COMMENT);

                    FileWrite(tradeHandle,
                        IntegerToString(ticket),
                        IntegerToString(dealType),
                        TimeToString(dealTime, TIME_DATE|TIME_MINUTES),
                        TimeToString(dealTime, TIME_DATE|TIME_MINUTES),
                        DoubleToString(dealPrice, _Digits),
                        DoubleToString(dealPrice, _Digits),
                        "0",  // SL not available in deal history
                        "0",  // TP not available in deal history
                        DoubleToString(dealVolume, 2),
                        DoubleToString(dealProfit, 2),
                        dealComment
                    );
                    exportCount++;
                }
            }
        }
        FileClose(tradeHandle);
        Print("✅ Trade history exported: ", tradeFile, " (", exportCount, " trades)");
    }

    return winRate;
}
