//+------------------------------------------------------------------+
//|                                                     SimpleEA.mq5 |
//|                                          EA-OAT v2 - Iteration 0 |
//|                          Workflow Validation: MA Crossover Baseline|
//+------------------------------------------------------------------+
#property copyright "EA-OAT v2"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- Input parameters
input int    inp_MA_Fast     = 10;        // Fast MA period
input int    inp_MA_Slow     = 20;        // Slow MA period
input double inp_FixedLot    = 0.10;      // Fixed lot size
input int    inp_TP_Points   = 200;       // Take Profit (points)
input int    inp_SL_Points   = 100;       // Stop Loss (points)
input int    inp_MagicNumber = 123001;    // Magic number
input string inp_Comment     = "SimpleEA"; // Order comment

//--- Global variables
int    g_handleMAFast;
int    g_handleMASlow;
double g_bufMAFast[];
double g_bufMASlow[];
datetime g_lastBarTime;
CTrade g_trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Create MA indicators
   g_handleMAFast = iMA(_Symbol, PERIOD_CURRENT, inp_MA_Fast, 0, MODE_SMA, PRICE_CLOSE);
   g_handleMASlow = iMA(_Symbol, PERIOD_CURRENT, inp_MA_Slow, 0, MODE_SMA, PRICE_CLOSE);

   if(g_handleMAFast == INVALID_HANDLE || g_handleMASlow == INVALID_HANDLE)
   {
      Print("Failed to create MA indicators");
      return INIT_FAILED;
   }

   //--- Set series arrays
   ArraySetAsSeries(g_bufMAFast, true);
   ArraySetAsSeries(g_bufMASlow, true);

   //--- Setup trade object
   g_trade.SetExpertMagicNumber(inp_MagicNumber);
   g_trade.SetDeviationInPoints(10);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);

   g_lastBarTime = 0;

   Print("SimpleEA initialized: MA(", inp_MA_Fast, ") / MA(", inp_MA_Slow, ")");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                    |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_handleMAFast != INVALID_HANDLE) IndicatorRelease(g_handleMAFast);
   if(g_handleMASlow != INVALID_HANDLE) IndicatorRelease(g_handleMASlow);
}

//+------------------------------------------------------------------+
//| Check if new bar formed                                            |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime != g_lastBarTime)
   {
      g_lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Count open positions for this EA                                   |
//+------------------------------------------------------------------+
int CountPositions(ENUM_POSITION_TYPE posType)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetInteger(POSITION_MAGIC) == inp_MagicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_TYPE) == posType)
         {
            count++;
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Close all positions of given type                                  |
//+------------------------------------------------------------------+
void ClosePositions(ENUM_POSITION_TYPE posType)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetInteger(POSITION_MAGIC) == inp_MagicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_TYPE) == posType)
         {
            g_trade.PositionClose(ticket);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Only process on new bar
   if(!IsNewBar()) return;

   //--- Copy MA values (bars 1 and 2 - completed bars only)
   if(CopyBuffer(g_handleMAFast, 0, 0, 3, g_bufMAFast) < 3) return;
   if(CopyBuffer(g_handleMASlow, 0, 0, 3, g_bufMASlow) < 3) return;

   //--- Check crossover on completed bars (shift 1 = previous bar, shift 2 = two bars ago)
   bool bullishCross = (g_bufMAFast[1] > g_bufMASlow[1]) && (g_bufMAFast[2] <= g_bufMASlow[2]);
   bool bearishCross = (g_bufMAFast[1] < g_bufMASlow[1]) && (g_bufMAFast[2] >= g_bufMASlow[2]);

   //--- Get current price
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   //--- BUY signal
   if(bullishCross)
   {
      //--- Close any existing SELL positions first
      ClosePositions(POSITION_TYPE_SELL);

      //--- Open BUY if no existing BUY
      if(CountPositions(POSITION_TYPE_BUY) == 0)
      {
         double sl = ask - inp_SL_Points * point;
         double tp = ask + inp_TP_Points * point;
         g_trade.Buy(inp_FixedLot, _Symbol, ask, sl, tp, inp_Comment);
      }
   }

   //--- SELL signal
   if(bearishCross)
   {
      //--- Close any existing BUY positions first
      ClosePositions(POSITION_TYPE_BUY);

      //--- Open SELL if no existing SELL
      if(CountPositions(POSITION_TYPE_SELL) == 0)
      {
         double sl = bid + inp_SL_Points * point;
         double tp = bid - inp_TP_Points * point;
         g_trade.Sell(inp_FixedLot, _Symbol, bid, sl, tp, inp_Comment);
      }
   }
}

//+------------------------------------------------------------------+
//| Tester function - export results to CSV                            |
//+------------------------------------------------------------------+
double OnTester()
{
   //--- Balance metrics (what user wants)
   double initialBalance = TesterStatistics(STAT_INITIAL_DEPOSIT);
   double netProfit      = TesterStatistics(STAT_PROFIT);
   double balanceDD      = TesterStatistics(STAT_BALANCE_DD);  // Max drawdown amount

   //--- Calculate derived balance values
   double finalBalance   = initialBalance + netProfit;
   double minBalance     = initialBalance - balanceDD;  // Min = Initial - Max DD
   // Max balance = higher of initial and final (simplified - no STAT_BALANCE_MAX available)
   double maxBalance     = (finalBalance > initialBalance) ? finalBalance : initialBalance;

   //--- Profit metrics
   double grossProfit    = TesterStatistics(STAT_GROSS_PROFIT);
   double grossLoss      = TesterStatistics(STAT_GROSS_LOSS);
   double profitFactor   = TesterStatistics(STAT_PROFIT_FACTOR);
   double recoveryFactor = TesterStatistics(STAT_RECOVERY_FACTOR);
   double sharpeRatio    = TesterStatistics(STAT_SHARPE_RATIO);
   double expectedPayoff = TesterStatistics(STAT_EXPECTED_PAYOFF);

   //--- Drawdown metrics
   double balanceDDPct   = TesterStatistics(STAT_BALANCE_DDREL_PERCENT);
   double equityDD       = TesterStatistics(STAT_EQUITY_DD);
   double equityDDPct    = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);

   //--- Trade metrics
   double totalTrades    = TesterStatistics(STAT_TRADES);
   double totalDeals     = TesterStatistics(STAT_DEALS);
   double profitTrades   = TesterStatistics(STAT_PROFIT_TRADES);
   double lossTrades     = TesterStatistics(STAT_LOSS_TRADES);
   double longTrades     = TesterStatistics(STAT_LONG_TRADES);
   double shortTrades    = TesterStatistics(STAT_SHORT_TRADES);

   double maxConWins     = TesterStatistics(STAT_MAX_CONWINS);
   double maxConLosses   = TesterStatistics(STAT_MAX_CONLOSSES);

   //--- Calculate derived metrics
   double winRate = (totalTrades > 0) ? (profitTrades / totalTrades * 100.0) : 0;
   double lossRate = (totalTrades > 0) ? (lossTrades / totalTrades * 100.0) : 0;

   //--- Export to CSV with FILE_COMMON flag
   string filename = "backtest_results.csv";
   int handle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_COMMON, ',');
   if(handle != INVALID_HANDLE)
   {
      FileWrite(handle, "Metric", "Value");

      //--- BALANCE METRICS (priority - what user wants)
      FileWrite(handle, "=== BALANCE ===", "");
      FileWrite(handle, "Initial Balance", DoubleToString(initialBalance, 2));
      FileWrite(handle, "Final Balance", DoubleToString(finalBalance, 2));
      FileWrite(handle, "Max Balance", DoubleToString(maxBalance, 2));
      FileWrite(handle, "Min Balance", DoubleToString(minBalance, 2));
      FileWrite(handle, "Net Profit", DoubleToString(netProfit, 2));

      //--- TRADE METRICS (priority - what user wants)
      FileWrite(handle, "=== TRADES ===", "");
      FileWrite(handle, "Total Trades", DoubleToString(totalTrades, 0));
      FileWrite(handle, "Win Trades", DoubleToString(profitTrades, 0));
      FileWrite(handle, "Loss Trades", DoubleToString(lossTrades, 0));
      FileWrite(handle, "Win Rate %", DoubleToString(winRate, 2));
      FileWrite(handle, "Loss Rate %", DoubleToString(lossRate, 2));

      //--- PROFIT METRICS
      FileWrite(handle, "=== PROFIT ===", "");
      FileWrite(handle, "Gross Profit", DoubleToString(grossProfit, 2));
      FileWrite(handle, "Gross Loss", DoubleToString(grossLoss, 2));
      FileWrite(handle, "Profit Factor", DoubleToString(profitFactor, 2));
      FileWrite(handle, "Recovery Factor", DoubleToString(recoveryFactor, 2));
      FileWrite(handle, "Sharpe Ratio", DoubleToString(sharpeRatio, 2));
      FileWrite(handle, "Expected Payoff", DoubleToString(expectedPayoff, 2));

      //--- DRAWDOWN METRICS
      FileWrite(handle, "=== DRAWDOWN ===", "");
      FileWrite(handle, "Balance DD", DoubleToString(balanceDD, 2));
      FileWrite(handle, "Balance DD %", DoubleToString(balanceDDPct, 2));
      FileWrite(handle, "Equity DD", DoubleToString(equityDD, 2));
      FileWrite(handle, "Equity DD %", DoubleToString(equityDDPct, 2));

      //--- ADDITIONAL METRICS
      FileWrite(handle, "=== DETAILS ===", "");
      FileWrite(handle, "Total Deals", DoubleToString(totalDeals, 0));
      FileWrite(handle, "Long Trades", DoubleToString(longTrades, 0));
      FileWrite(handle, "Short Trades", DoubleToString(shortTrades, 0));
      FileWrite(handle, "Max Consecutive Wins", DoubleToString(maxConWins, 0));
      FileWrite(handle, "Max Consecutive Losses", DoubleToString(maxConLosses, 0));

      FileClose(handle);
      Print("CSV exported to Common/Files/", filename);
   }
   else
   {
      Print("ERROR: Failed to open CSV file for writing");
   }

   return netProfit;
}
//+------------------------------------------------------------------+
