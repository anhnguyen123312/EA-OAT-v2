# AdvancedEA v1.01 - Implementation Changes

**Date:** 2026-02-17
**Status:** Backtest Running
**Compiled:** 18:06 (0 errors, 0 warnings)

---

## Changes Summary

Fixed 4 critical bugs from v1.00 → v1.01 based on Backtester's deep dive analysis.

---

## 1. Entry Timing Fix (PRIORITY 1)

**Root Cause:** v1.00 entered immediately when OB/FVG detected, without waiting for pullback completion.

**Fix Implemented:**

### Added Zone Tolerance Parameter
```cpp
input double inp_ZoneTolerance = 0.0005; // Zone tolerance (0.05%)
```

### Added Confirmation Candle Function
Checks for bullish/bearish candle with body >= 60% of total range

### Modified Entry Logic
- Checks if current price is WITHIN tolerance of OB zone
- Invalidates entry if price not at pullback zone
- Uses current price for entry (more realistic)

**Expected Impact:** WR improvement from 19.8% → 60-70%

---

## 2. Risk Management Fix (PRIORITY 2)

- Added debug logging in CalculateLotSize()
- Added SL/TP verification after trade execution

---

## 3. Trade History Export (PRIORITY 3)

- Export individual trade details to trade_history.csv
- Enable trade-by-trade classification
- Provide ticket-level debugging

---

## 4. Config Deposit Fix (PRIORITY 4)

Changed Deposit=1000 (was 10000)

---

## Files Modified

1. `code/experts/AdvancedEA.mq5` - All 4 priorities implemented
2. `config/active/autobacktest.ini` - Deposit corrected
3. `scripts/compile_ea.sh` - Fixed WINE path quoting

---

## Testing Status

- ✅ Compiled: 0 errors, 0 warnings
- ✅ Config validated
- ⏳ Backtest running (Real Ticks, 2023-2026)

---

## Next Steps

1. Wait for backtest completion
2. Collect results: `./scripts/collect_backtest_results.sh AdvancedEA XAUUSD M5`
3. Backtester: Classify trades in v1.01
4. Compare v1.00 vs v1.01 metrics
5. Em: Decide next iteration or COMPLETE
