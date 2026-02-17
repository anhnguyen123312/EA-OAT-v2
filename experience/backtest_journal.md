# Backtest Journal - Persistent Lessons

## 2026-02-17: Iteration 0 - SimpleEA v1.00
- **Key Finding**: MA crossover on XAUUSD M5 yields ~26% WR - fundamentally unsuitable for 90% WR target
- **WR impact**: MA lag is the #1 killer - by crossover confirmation, move is 60-80% done
- **RR impact**: Fixed 2:1 RR works mechanically, but 26% WR means net loss (-$802 on $10K)
- **Session insight**: All sessions traded equally - no session filter = extra whipsaw losses in Asian/Late NY
- **Rule for future**: Never use MA crossover as primary signal for high-WR strategies. Use PA+S/R with MA only as trend filter.
- **Data gap**: Aggregate CSV metrics insufficient for trade classification. Need individual deal history export for proper Backtester analysis.

## 2026-02-17: Iteration 1 - AdvancedEA v1.00 (SMC/ICT Baseline)
- **Key Finding**: 19.8% WR with 50/50 long/short balance and 1.85 R:R strongly indicates **SIGNAL DIRECTION INVERSION** - the #1 rookie algorithmic trading bug
- **WR impact**: Signal inversion is PRIMARY killer - flipping logic should raise WR from 19.8% → ~80% (inverse)
- **RR impact**: Actual R:R (1.85) is NEAR target (2.0), suggesting SL/TP placement logic is roughly correct
- **Risk impact**: 100.18% DD (account blown) despite 0.5% risk/trade reveals CRITICAL bug - SL not respected OR lot sizing broken
- **Trade frequency**: 0.18/day vs 10/day target - detectors barely triggering (likely due to bugs, not strategy)
- **Critical bugs identified**:
  1. BUY/SELL direction likely inverted in detector output or trade execution
  2. Risk management failure (account blown impossible with proper 0.5% risk)
  3. OnTester() missing individual trade history export (blocks detailed analysis)
  4. Deposit discrepancy ($10K config vs $1K CSV)
- **Rule for future**: When WR is suspiciously low (~20%) with balanced directional trades (50/50), FIRST check for signal inversion before blaming strategy design
- **Projected impact**: If signal inversion fixed, WR should flip to 79-80% (meeting target). If risk management fixed, DD drops to <10%.
- **Data gap**: Still no individual trade history - Coder MUST add HistoryDealsTotal() export to OnTester() for next iteration

<!-- Backtester updates this file with new discoveries -->
