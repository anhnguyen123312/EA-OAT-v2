# Backtest Journal - Persistent Lessons

## 2026-02-17: Iteration 0 - SimpleEA v1.00
- **Key Finding**: MA crossover on XAUUSD M5 yields ~26% WR - fundamentally unsuitable for 90% WR target
- **WR impact**: MA lag is the #1 killer - by crossover confirmation, move is 60-80% done
- **RR impact**: Fixed 2:1 RR works mechanically, but 26% WR means net loss (-$802 on $10K)
- **Session insight**: All sessions traded equally - no session filter = extra whipsaw losses in Asian/Late NY
- **Rule for future**: Never use MA crossover as primary signal for high-WR strategies. Use PA+S/R with MA only as trend filter.
- **Data gap**: Aggregate CSV metrics insufficient for trade classification. Need individual deal history export for proper Backtester analysis.

<!-- Backtester updates this file with new discoveries -->
