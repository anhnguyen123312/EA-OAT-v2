# Strategy Research

**Last Updated:** 2026-02-16  
**Status:** Phase 1 - Knowledge Transfer In Progress

---

## 🎯 Trading Methodologies Researched

### 1. SMC/ICT (Smart Money Concepts) ⭐

**Source:** EA-OAT v2.1 documentation, ICT teachings  
**Instrument:** XAUUSD (Spot Gold)  
**Timeframe:** M5 (primary), H1/H4 (multi-timeframe bias)

**Core Concepts:**
- **BOS (Break of Structure):** Identifies trend direction and structural shifts
- **Liquidity Sweep:** Detects when price "hunts" liquidity at fractal high/low then reverses
- **Order Block (OB):** Demand/Supply zones where institutions placed orders
- **Fair Value Gap (FVG):** Price imbalances (gaps) that act as magnets
- **Momentum Breakout:** Confirms directional bias

**Signal Paths:**
- **Path A (Preferred):** BOS + POI (OB or FVG)
- **Path B:** Sweep + POI + Momentum (when no BOS)

**Scoring System:**
- Base: 100 points (BOS + POI)
- Bonuses: BOS (+30), Sweep (+25), OB (+20), FVG (+15), MTF alignment (+20)
- Penalties: Counter-trend (-30), weak OB (-10), touched OB (×0.5)
- **Minimum Entry Score:** 100
- **Excellent Setup:** 200+

**Pros:**
- High win rate when confluence occurs (BOS + Sweep + OB + FVG)
- Clear entry/exit rules based on market structure
- Multi-timeframe bias reduces counter-trend trades

**Cons:**
- Requires many confirmations → fewer trades
- Complex scoring can miss simple high-probability setups
- Strict 100-point threshold may skip 90-99 point setups

---

### 2. Elliott Wave (EW) - WHERE in Market Cycle

**Source:** ELLIOTT_WAVE_REFERENCE.md (373 pages), Prechter's Elliott Wave Principle  
**Integration:** Provides macro context for SMC entries

**Core Concepts:**
- **Wave Structure:** Impulse (5 waves) vs Corrective (3 waves)
- **Fibonacci Ratios:** Wave relationships (0.618, 1.618, 2.618)
- **Wave Counting:** Identify current wave position
- **Trend Context:** Determine if in impulse (trend) or correction (chop)

**Application in EA:**
- **H4/D1 Wave Analysis:** Determine macro bias (impulse up/down vs correction)
- **Entry Timing:** Enter SMC signals aligned with impulse wave direction
- **Avoid Corrections:** Skip trades during ABC corrective structures

**Integration with SMC:**
- EW provides **WHERE** in cycle (impulse wave 3 = strongest)
- SMC provides **WHEN** to enter (BOS + OB at wave retracement)
- Combined: "Enter BOS+OB during wave 3 impulse" = highest probability

**Pros:**
- Macro perspective prevents trading against larger trend
- Wave 3 and Wave 5 setups = highest momentum
- Fibonacci targets align with SMC structure targets

**Cons:**
- Requires manual wave counting (hard to automate)
- Multiple valid wave counts = ambiguity
- Real-time counting difficult on M5 timeframe

**Applicability for M5 XAUUSD:**
- Use H4/D1 for wave counting (macro bias)
- M5 for execution (SMC signals)
- Complexity: MEDIUM-HIGH (wave counting requires expertise)

---

### 3. Volume Profile (VP) - KEY LEVELS (Support/Resistance)

**Source:** Volume Profile fundamentals, Sierra Chart ACSIL studies  
**Integration:** Provides high-probability S/R levels

**Core Concepts:**
- **POC (Point of Control):** Price with highest volume = fair value
- **VAH/VAL (Value Area High/Low):** 70% of volume range
- **HVN (High Volume Node):** Acceptance zones (support/resistance)
- **LVN (Low Volume Node):** Rejection zones (breakout areas)

**Application in EA:**
- **H1 Volume Profile:** Calculate POC, VAH, VAL daily
- **Entry Confluence:** Enter SMC signals near POC or VAH/VAL
- **Target Selection:** Use HVN as TP targets, LVN as breakout confirmation

**Integration with SMC:**
- VP provides **KEY LEVELS** (where to look for setups)
- SMC provides **SIGNAL** (BOS + OB at POC = high confluence)
- Combined: "BOS+OB near POC" = institutional entry zone

**Pros:**
- Objective levels (volume-based, not subjective)
- POC acts as magnet (high retest probability)
- HVN zones = strong S/R

**Cons:**
- Requires tick/volume data (may not be available on all MT5 feeds)
- Calculation overhead (profile building)
- XAUUSD volume on spot may not reflect futures liquidity

**Applicability for M5 XAUUSD:**
- Use H1/H4 profiles for daily levels
- Complexity: MEDIUM (calculation straightforward)
- Data dependency: MEDIUM-HIGH (need reliable volume feed)

---

### 4. Order Flow (OF) - CONFIRM Entry Timing

**Source:** ORDER_FLOW_REFERENCE.md (126 pages), NinjaTrader footprint analysis  
**Integration:** Final confirmation before entry

**Core Concepts:**
- **Delta (Δ):** ASK volume - BID volume (buying pressure vs selling pressure)
- **Cumulative Delta (CVD):** Running sum of delta (institutional direction)
- **Delta Divergence:** Price makes new high but delta doesn't = exhaustion
- **Absorption:** Large passive orders absorbing aggressive orders = reversal
- **Stacked Imbalance:** 3+ consecutive imbalances = strong S/R

**Application in EA:**
- **M5 Footprint Analysis:** Calculate bar delta, detect divergence
- **Entry Confirmation:** Only enter SMC signal if delta aligns (no divergence)
- **Exit Signal:** Delta divergence at TP zone = exit early

**Integration with SMC:**
- OF provides **WHEN** to pull trigger (delta confirmation)
- SMC provides **WHERE** (BOS + OB)
- Combined: "BOS+OB + positive delta = institutions buying" = high confidence

**Pros:**
- Real-time institutional activity (order flow = footprints)
- Delta divergence = early reversal warning
- Absorption zones = precise entry/exit

**Cons:**
- Requires Level 2 data (Bid/Ask volume) - not available on MT5 XAUUSD spot
- Calculation intensive (tick-by-tick processing)
- Footprint analysis complex to automate

**Applicability for M5 XAUUSD:**
- **BLOCKED** on MT5 XAUUSD (no Bid/Ask volume data)
- Alternative: Use futures XAUUSD (GC) on CQG feed
- Complexity: HIGH (tick processing + visualization)
- **Decision:** Defer Order Flow to Phase 2 (after baseline EA working)

---

## 🎯 Unified Strategy Design: Quad-Methodology Integration

### Original Triple-to-Quad Concept

**Triple (EW + VP + OF):**
- EW: WHERE in cycle
- VP: KEY LEVELS (S/R)
- OF: WHEN to enter (confirmation)

**Quad (+ SMC/ICT):**
- EW: Macro bias (impulse vs correction)
- VP: High-probability zones (POC, VAH/VAL)
- SMC: Signal generation (BOS + OB + Sweep + FVG)
- OF: Final confirmation (delta alignment)

**Integration Flow:**
```
1. EW Analysis (H4/D1) → Determine macro bias (impulse up/down?)
2. VP Calculation (H1) → Identify key levels (POC, VAH, VAL)
3. SMC Detection (M5) → Wait for BOS + OB near VP level
4. OF Confirmation (M5) → Check delta alignment (institutions buying/selling?)
5. Entry Execution → If all align, execute trade
```

**Unified Scoring:**
```
TOTAL SCORE = (EW × W1) + (VP × W2) + (SMC × W3) + (OF × W4)

Proposed Weights:
- W1 (EW):  0.20 (macro context)
- W2 (VP):  0.30 (key levels)
- W3 (SMC): 0.30 (primary signal)
- W4 (OF):  0.20 (confirmation)

Entry Threshold: TOTAL ≥ 60
```

---

## 🎯 Phase 1 Strategy: SMC-Only Baseline

**Rationale:**
- Start simple, validate workflow
- SMC already has proven rules (EA-OAT v2.1)
- EW/VP/OF add complexity → defer to Phase 2

**Implementation:**
- Use existing SMC logic (BOS, Sweep, OB, FVG, Momentum)
- Existing scoring system (base 100 + bonuses/penalties)
- Existing entry/exit rules (TRADING_RULES.md)
- Test on M5 XAUUSD with historical data

**Success Criteria (Phase 1):**
- Win Rate: ≥ 90%
- Risk/Reward: ≥ 1:2
- Trades/day: ≥ 10
- Max Drawdown: < 10%

**If Phase 1 Meets Targets:**
- Proceed to live demo
- Skip Phase 2 (EW/VP/OF integration)

**If Phase 1 Fails:**
- Root cause analysis
- Decide: Optimize SMC parameters OR integrate EW/VP for better filtering

---

## 🎯 Phase 2 Strategy: Add EW + VP (if needed)

**Only proceed if Phase 1 < 90% WR**

**EW Integration:**
- H4 wave counting (manual or simplified algorithm)
- Filter: Only take SMC signals aligned with impulse wave direction
- Expected Impact: Reduce counter-trend false positives

**VP Integration:**
- H1 Volume Profile (POC, VAH, VAL)
- Filter: Only take SMC signals near POC ± 10 pips or VAH/VAL
- Expected Impact: Higher confluence = higher win rate

**Updated Scoring:**
```
TOTAL = (EW × 0.25) + (VP × 0.35) + (SMC × 0.40)
Entry: TOTAL ≥ 60
```

---

## 🎯 Phase 3 Strategy: Add OF (futures only)

**Only proceed if:**
- Phase 2 implemented AND
- Access to GC futures (CQG Level 2 data) AND
- Win rate still < 90%

**OF Integration:**
- M5 delta calculation (ASK - BID volume)
- Cumulative delta tracking
- Delta divergence detection
- Filter: Only enter SMC+EW+VP signal if delta aligns (no divergence)

**Full Quad Scoring:**
```
TOTAL = (EW × 0.20) + (VP × 0.30) + (SMC × 0.30) + (OF × 0.20)
Entry: TOTAL ≥ 60
```

---

## 📊 Comparison: SMC vs Triple vs Quad

| Method | Win Rate (Est.) | Trades/Day | Complexity | Data Req. |
|--------|-----------------|------------|------------|-----------|
| SMC Only | 70-80% | 15-20 | LOW | OHLC only |
| SMC + EW + VP | 80-85% | 10-15 | MEDIUM | OHLC + Volume |
| Full Quad (+ OF) | 85-90% | 8-12 | HIGH | Level 2 + Tick |

**Trade-off:**
- More methodologies = Higher accuracy BUT Fewer signals
- Goal: 90% WR + 10 trades/day
- **Start with SMC, add filters only if needed**

---

## 🔍 Research TODOs

- [ ] Validate SMC scoring system with backtest data
- [ ] Research simplified EW wave counting (programmable rules)
- [ ] Investigate Volume Profile calculation on MT5 (tick volume vs real volume)
- [ ] Explore Order Flow alternatives (e.g., Market Depth, Time & Sales)
- [ ] Benchmark: Compare SMC-only vs SMC+EW+VP on same dataset

---

## 📚 References

- [EA-OAT v2.1 Documentation](/Users/sh1su1/.openclaw/trading-system-development/docs/ea-oat/)
- [Elliott Wave Reference](/Users/sh1su1/.openclaw/workspace-trader/docs/ELLIOTT_WAVE_REFERENCE.md)
- [Order Flow Reference](/Users/sh1su1/.openclaw/workspace-trader/docs/ORDER_FLOW_REFERENCE.md)
- [Volume Profile Fundamentals](internal research)
- [SMC/ICT Teachings](YouTube, forums)

---

**Status:** Phase 1 baseline strategy defined. Ready for design decisions and first EA implementation.
