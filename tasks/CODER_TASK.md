# CODER_TASK - Simple EA (Workflow Validation)

## Status: DONE

## Task Type: NEW_EA

## Iteration: 0 (Workflow Validation Test)

---

## EA Name
SimpleEA

## Strategy Description
Simple MA crossover baseline for workflow validation. NOT performance-critical - purpose is to test compile → backtest → CSV export → analysis pipeline end-to-end.

**Logic:** Buy when fast MA crosses above slow MA, Sell when fast MA crosses below slow MA.

---

## Entry Rules (LONG)

1. `MA_Fast[1] > MA_Slow[1]` (fast MA above slow MA on previous bar)
2. `MA_Fast[2] <= MA_Slow[2]` (fast MA was NOT above slow MA 2 bars ago)
3. **→ Bullish crossover confirmed (use completed bars, not current bar 0)**

## Entry Rules (SHORT)

1. `MA_Fast[1] < MA_Slow[1]` (fast MA below slow MA on previous bar)
2. `MA_Fast[2] >= MA_Slow[2]` (fast MA was NOT below slow MA 2 bars ago)
3. **→ Bearish crossover confirmed (use completed bars, not current bar 0)**

---

## Exit Rules

### Take Profit (TP)
- **Fixed:** 200 points (20 pips) from entry

### Stop Loss (SL)
- **Fixed:** 100 points (10 pips) from entry

### Risk:Reward
- RR = 200 / 100 = 2.0 (meets MinRR target)

### Close Opposite Position
- When new signal triggers (e.g., SELL signal → close existing BUY position before opening SELL)

---

## Risk Management

### Lot Size
- **Fixed:** 0.10 lots (simple, no dynamic sizing for this test)

### Max Positions
- **1 position max** (close opposite before opening new)

### No DCA
- DCA disabled for Simple EA

### No Breakeven / Trailing
- Pure TP/SL, no dynamic management

---

## Indicators Required

### MA Fast
- **Type:** Simple Moving Average (SMA)
- **Period:** 10
- **Applied Price:** PRICE_CLOSE
- **Shift:** 0

### MA Slow
- **Type:** Simple Moving Average (SMA)
- **Period:** 20
- **Applied Price:** PRICE_CLOSE
- **Shift:** 0

---

## Parameters (Input Variables)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `inp_MA_Fast` | int | 10 | Fast MA period |
| `inp_MA_Slow` | int | 20 | Slow MA period |
| `inp_FixedLot` | double | 0.10 | Fixed lot size |
| `inp_TP_Points` | int | 200 | Take Profit (points) |
| `inp_SL_Points` | int | 100 | Stop Loss (points) |
| `inp_MagicNumber` | int | 123001 | Magic number for orders |
| `inp_Comment` | string | "SimpleEA" | Order comment |

---

## Backtest Config

### Symbol
`XAUUSD`

### Period
`5` (M5)

### Model
`1` (OHLC 1-min bars - faster, sufficient for M5)

### Date Range
- **FromDate:** `2024.01.01`
- **ToDate:** `2024.12.31`
- **Duration:** 1 year (2024 full year)

### Account Settings
- **Deposit:** `10000` USD
- **Currency:** USD
- **Leverage:** `100`

### Execution
- **Optimization:** `0` (single run, not optimization)
- **Visual:** `0` (no visualization - faster)
- **ShutdownTerminal:** `1` (auto-close MT5 when done)

---

## OnTester Metrics Required

**CRITICAL:** EA MUST include `OnTester()` function that exports to CSV with `FILE_COMMON` flag.

### Metrics to Export (TesterStatistics)

1. **Profit Metrics:**
   - Net Profit (`STAT_PROFIT`)
   - Gross Profit (`STAT_GROSS_PROFIT`)
   - Gross Loss (`STAT_GROSS_LOSS`)
   - Profit Factor (`STAT_PROFIT_FACTOR`)
   - Expected Payoff (`STAT_EXPECTED_PAYOFF`)

2. **Trade Metrics:**
   - Total Trades (`STAT_TRADES`)
   - Profit Trades (`STAT_PROFIT_TRADES`)
   - Loss Trades (`STAT_LOSS_TRADES`)
   - **Win Rate %** (calculated: `profit_trades / total_trades × 100`)
   - Long Trades (`STAT_LONG_TRADES`)
   - Short Trades (`STAT_SHORT_TRADES`)

3. **Risk Metrics:**
   - Balance Drawdown (`STAT_BALANCE_DD`)
   - Balance DD % (`STAT_BALANCE_DDREL_PERCENT`)
   - Equity Drawdown (`STAT_EQUITY_DD`)
   - Equity DD % (`STAT_EQUITY_DDREL_PERCENT`)
   - Max Consecutive Wins (`STAT_MAX_CONWINS`)
   - Max Consecutive Losses (`STAT_MAX_CONLOSSES`)

4. **Quality Metrics:**
   - Sharpe Ratio (`STAT_SHARPE_RATIO`)
   - Recovery Factor (`STAT_RECOVERY_FACTOR`)

### CSV Format
- **Filename:** `backtest_results.csv`
- **Location:** Common/Files (via `FILE_COMMON` flag)
- **Format:** 2-column CSV (Metric, Value)
- **Decimal Places:** 2 for currency, 2 for percentages, 0 for counts

### Example OnTester() Implementation

```mql5
double OnTester()
{
   // Collect metrics
   double netProfit = TesterStatistics(STAT_PROFIT);
   double grossProfit = TesterStatistics(STAT_GROSS_PROFIT);
   double grossLoss = TesterStatistics(STAT_GROSS_LOSS);
   double profitFactor = TesterStatistics(STAT_PROFIT_FACTOR);
   double expectedPayoff = TesterStatistics(STAT_EXPECTED_PAYOFF);
   
   double totalTrades = TesterStatistics(STAT_TRADES);
   double profitTrades = TesterStatistics(STAT_PROFIT_TRADES);
   double lossTrades = TesterStatistics(STAT_LOSS_TRADES);
   double winRate = (totalTrades > 0) ? (profitTrades / totalTrades * 100.0) : 0;
   
   double balanceDD = TesterStatistics(STAT_BALANCE_DD);
   double balanceDDPct = TesterStatistics(STAT_BALANCE_DDREL_PERCENT);
   double equityDD = TesterStatistics(STAT_EQUITY_DD);
   double equityDDPct = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
   
   double sharpeRatio = TesterStatistics(STAT_SHARPE_RATIO);
   double recoveryFactor = TesterStatistics(STAT_RECOVERY_FACTOR);
   
   // Export to CSV
   int handle = FileOpen("backtest_results.csv", FILE_WRITE|FILE_CSV|FILE_COMMON, ',');
   if(handle != INVALID_HANDLE)
   {
      FileWrite(handle, "Metric", "Value");
      FileWrite(handle, "Net Profit", DoubleToString(netProfit, 2));
      FileWrite(handle, "Gross Profit", DoubleToString(grossProfit, 2));
      FileWrite(handle, "Gross Loss", DoubleToString(grossLoss, 2));
      FileWrite(handle, "Profit Factor", DoubleToString(profitFactor, 2));
      FileWrite(handle, "Expected Payoff", DoubleToString(expectedPayoff, 2));
      FileWrite(handle, "Total Trades", DoubleToString(totalTrades, 0));
      FileWrite(handle, "Profit Trades", DoubleToString(profitTrades, 0));
      FileWrite(handle, "Loss Trades", DoubleToString(lossTrades, 0));
      FileWrite(handle, "Win Rate %", DoubleToString(winRate, 2));
      FileWrite(handle, "Balance DD", DoubleToString(balanceDD, 2));
      FileWrite(handle, "Balance DD %", DoubleToString(balanceDDPct, 2));
      FileWrite(handle, "Equity DD", DoubleToString(equityDD, 2));
      FileWrite(handle, "Equity DD %", DoubleToString(equityDDPct, 2));
      FileWrite(handle, "Sharpe Ratio", DoubleToString(sharpeRatio, 2));
      FileWrite(handle, "Recovery Factor", DoubleToString(recoveryFactor, 2));
      FileClose(handle);
   }
   
   return netProfit;
}
```

---

## Special Instructions

### Workflow Validation Focus

**This EA is NOT performance-critical.** The goal is to validate:
1. ✅ Code compiles without errors
2. ✅ MT5 backtest runs successfully
3. ✅ OnTester() exports CSV to Common/Files
4. ✅ CSV contains all required metrics
5. ✅ Em can parse CSV and extract metrics

**Expected Performance:**
- Win Rate: ~40-50% (MA crossover is not a high-WR strategy)
- Trades: 50-200 trades (depends on market chop)
- This is NORMAL and ACCEPTABLE for Simple EA

**If Performance is Terrible:**
- That's OK! This is just a workflow test
- Em will still analyze CSV to validate pipeline
- Next iteration (Advanced EA with SMC) will target 90% WR

### Code Structure

```
SimpleEA.mq5
├── #property (version, strict, copyright)
├── Input parameters (inp_MA_Fast, inp_MA_Slow, etc.)
├── Global variables (MA handles, last signal, etc.)
├── OnInit() - Initialize MA indicators
├── OnDeinit() - Release handles
├── OnTick() - Main logic
│   ├── Check for new bar (avoid multiple entries per bar)
│   ├── Calculate MA values
│   ├── Detect crossover
│   ├── Close opposite position if exists
│   ├── Open new position (BUY/SELL)
└── OnTester() - Export CSV (REQUIRED)
```

### Critical MT5 Details

1. **Use completed bars (shift 1, 2) for crossover detection:**
   - `MA_Fast[1]` and `MA_Slow[1]` (previous bar)
   - `MA_Fast[2]` and `MA_Slow[2]` (2 bars ago)
   - **DO NOT use bar 0** (current forming bar - unreliable)

2. **One entry per new bar:**
   - Track `lastBarTime` or `lastBarVolume` to avoid multiple entries
   - Only process logic when new bar forms

3. **Close opposite before opening new:**
   - If SELL signal triggers and BUY position exists → close BUY first
   - Then open SELL position

4. **Config .ini CRITICAL:**
   - `Expert=SimpleEA` (NAME ONLY, no path prefix)
   - `Expert=Experts\SimpleEA` ← **WRONG, will FAIL**

---

## Success Criteria (Workflow Validation)

### ✅ Compilation
- Zero errors (warnings are OK)
- No deprecated function usage (if possible)

### ✅ Backtest Execution
- MT5 completes backtest without crash
- Backtest duration: ~1-5 minutes (M5, 1 year, Model 1)

### ✅ CSV Export
- `backtest_results.csv` exists in Common/Files
- Contains all 15 metrics listed above
- Values are numeric (not "inf" or "nan")

### ✅ Git Workflow
- Code pushed to `code/experts/SimpleEA.mq5`
- CSV pushed to `results/2026-02-16_SimpleEA_XAUUSD_M5.csv`
- Logs pushed to `results/logs/2026-02-16_SimpleEA.log` (if available)
- experience/ updated with any compile/backtest issues encountered

---

## Expected Timeline

- Implementation: 30 minutes
- Compilation: 1-2 attempts (handle any syntax errors)
- Backtest: 2-5 minutes
- Git push + Telegram report: 5 minutes

**Total:** ~1 hour

---

## Notes for Coder

- Keep it simple - this is a workflow test, not a trading masterpiece
- Focus on clean code structure that can serve as template for Advanced EA
- Document any Wine/MT5 quirks in experience/wine_quirks.md
- Document any MQL5 patterns learned in experience/mql5_patterns.md

---

**Created:** 2026-02-16  
**Author:** Em (Manager)  
**Priority:** HIGH (blocks all future iterations)  
**Iteration:** 0 (Pre-baseline workflow validation)
