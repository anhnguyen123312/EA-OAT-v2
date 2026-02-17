# Backtest Journal - Persistent Lessons

## 2026-02-17: Iteration 0 - SimpleEA v1.00
- **Key Finding**: MA crossover on XAUUSD M5 yields ~26% WR - fundamentally unsuitable for 90% WR target
- **WR impact**: MA lag is the #1 killer - by crossover confirmation, move is 60-80% done
- **RR impact**: Fixed 2:1 RR works mechanically, but 26% WR means net loss (-$802 on $10K)
- **Session insight**: All sessions traded equally - no session filter = extra whipsaw losses in Asian/Late NY
- **Rule for future**: Never use MA crossover as primary signal for high-WR strategies. Use PA+S/R with MA only as trend filter.
- **Data gap**: Aggregate CSV metrics insufficient for trade classification. Need individual deal history export for proper Backtester analysis.

## 2026-02-17: Iteration 1 - AdvancedEA v1.00 (SMC/ICT Baseline)
- **Key Finding**: 19.8% WR with 50/50 long/short balance and 1.85 R:R initially suggested signal inversion, BUT deep code analysis revealed the REAL bug: **ENTRY TIMING LOGIC**
- **Root Cause**: Code enters IMMEDIATELY when BOS+OB detected, instead of WAITING for price to PULL BACK to the OB zone
- **WR impact**: Entering before pullback completes = getting stopped out on the pullback, then missing the actual move (80% losses)
- **RR impact**: Actual R:R (1.85) is near target (2.0) because SL/TP DISTANCES are correct - only TIMING is wrong
- **Risk impact**: 100.18% DD (account blown) - with 80% loss rate, even proper risk management can't prevent eventual wipeout
- **Trade frequency**: 0.18/day vs 10/day target - BOS+OB confluence is rare, but when detected, entry timing kills WR
- **Critical bugs identified**:
  1. **ENTRY TIMING** (Priority 1): Enters at market price when BOS+OB detected, doesn't wait for pullback to OB zone
  2. OnTester() missing individual trade history export (blocks detailed trade-by-trade analysis)
  3. Deposit discrepancy ($10K config vs $1K CSV - minor, doesn't affect percentages)
- **Code verification**:
  - ✅ BOS detection: CORRECT (bullish = 1, bearish = -1)
  - ✅ Trade execution: CORRECT (1 → BUY, -1 → SELL)
  - ✅ SL/TP placement: CORRECT (distances and directions)
  - ❌ Entry timing: BROKEN (no pullback wait logic)
- **Rule for future**: When analyzing SMC/ICT strategies, verify entry timing logic waits for pullback completion, not just structure detection
- **Projected impact**: If entry timing fixed (add pullback detection + confirmation candle), WR should improve from 19.8% → **60-70%** (some pullbacks will fail as genuine reversals)
- **Why not 80%?**: Unlike signal inversion (which would flip results), timing fix still allows for failed pullbacks (20-30% loss rate acceptable)
- **Data gap**: Still no individual trade history - Coder MUST add HistoryDealsTotal() export to OnTester() for next iteration
- **Lesson learned**: Initial hypothesis (signal inversion) was wrong - always verify by reading actual code, not just statistical inference

<!-- Backtester updates this file with new discoveries -->
