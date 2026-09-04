//+------------------------------------------------------------------+
//| TradeMonitor_Script.mq5                                          |
//| مراقب الصفقات على MT5: يسجل كل صفقة فور حدوثها في ملف CSV          |
//| (وقت الدخول/الخروج، الرمز، الربح، الإطار، الماجيك، التعليق)        |
//| لا يغيّر أي منطق في البوت — طبقة مراقبة/توثيق خارجية فقط.          |
//+------------------------------------------------------------------+
#property copyright "SMC/ICT Bot Toolkit"
#property version   "1.00"
#property script_show_inputs
#property strict

input string InpLogFile   = "SMCTrades_Log.csv";  // اسم ملف السجل داخل MQL5\Files
input bool   InpShowPrint = true;                  // طباعة في Experts
input bool   InpOverwrite = true;                  // إنشاء ملف جديد عند التشغيل

string Header = "TimeOpen,Event,Direction,Symbol,Timeframe,Volume,PriceOpen,PriceSL,PriceTP,PriceClose,Profit,Swap,Commission,Balance,Magic,Comment,Age_sec";

int    g_FileHandle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| اسم الإطار الزمني بالصيغة القصيرة                                    |
//+------------------------------------------------------------------+
string TFName(int p)
  {
   switch(p)
     {
      case PERIOD_M1:  return("M1");
      case PERIOD_M2:  return("M2");
      case PERIOD_M3:  return("M3");
      case PERIOD_M4:  return("M4");
      case PERIOD_M5:  return("M5");
      case PERIOD_M6:  return("M6");
      case PERIOD_M10: return("M10");
      case PERIOD_M12: return("M12");
      case PERIOD_M15: return("M15");
      case PERIOD_M20: return("M20");
      case PERIOD_M30: return("M30");
      case PERIOD_H1:  return("H1");
      case PERIOD_H2:  return("H2");
      case PERIOD_H3:  return("H3");
      case PERIOD_H4:  return("H4");
      case PERIOD_H6:  return("H6");
      case PERIOD_H8:  return("H8");
      case PERIOD_H12: return("H12");
      case PERIOD_D1:  return("D1");
      case PERIOD_W1:  return("W1");
      case PERIOD_MN1: return("MN1");
      default:         return("T" + IntegerToString(PeriodSeconds(p)));
     }
  }

//+------------------------------------------------------------------+
//| اسم الدولة/الوحدة الحالية                                            |
//+------------------------------------------------------------------+
string StateName(int stateId)
  {
   switch(stateId)
     {
      case TRADE_TRANSACTION_DEAL_ADD:            return("DEAL_ADD");
      case TRADE_TRANSACTION_DEAL_UPDATE:         return("DEAL_UPDATE");
      case TRADE_TRANSACTION_DEAL_DELETE:         return("DEAL_DELETE");
      case TRADE_TRANSACTION_POSITION_ADD:        return("POSITION_OPEN");
      case TRADE_TRANSACTION_POSITION_UPDATE:     return("POSITION_UPDATE");
      case TRADE_TRANSACTION_POSITION_REMOVE:     return("POSITION_CLOSED");
      case TRADE_TRANSACTION_ORDER_ADD:           return("ORDER_ADD");
      case TRADE_TRANSACTION_ORDER_UPDATE:        return("ORDER_UPDATE");
      case TRADE_TRANSACTION_ORDER_DELETE:        return("ORDER_DELETE");
      case TRADE_TRANSACTION_HISTORY_ADD:         return("HISTORY_ADD");
      case TRADE_TRANSACTION_HISTORY_UPDATE:      return("HISTORY_UPDATE");
      case TRADE_TRANSACTION_HISTORY_DELETE:      return("HISTORY_DELETE");
      default:                                    return("TX_" + IntegerToString(stateId));
     }
  }

//+------------------------------------------------------------------+
//| اتجاه الصفقة                                                       |
//+------------------------------------------------------------------+
string DirName(long type)
  {
   if(type == POSITION_TYPE_BUY)  return("BUY");
   if(type == POSITION_TYPE_SELL) return("SELL");
   return("?");
  }

//+------------------------------------------------------------------+
//| فتح الملف                                                           |
//+------------------------------------------------------------------+
bool OpenLog()
  {
   int flags = FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI;
   if(InpOverwrite)
      flags = FILE_WRITE | FILE_CSV | FILE_ANSI;

   g_FileHandle = FileOpen(InpLogFile, flags, '\t', CP_UTF8);
   if(g_FileHandle == INVALID_HANDLE)
     {
      PrintFormat("TradeMonitor: تعذر فتح '%s' — err=%d", InpLogFile, GetLastError());
      return(false);
     }

   if(InpOverwrite)
     {
      FileWriteString(g_FileHandle, Header + "\r\n", FILE_ANSI);
      FileFlush(g_FileHandle);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| إغلاق الملف                                                          |
//+------------------------------------------------------------------+
void CloseLog()
  {
   if(g_FileHandle != INVALID_HANDLE)
     {
      FileFlush(g_FileHandle);
      FileClose(g_FileHandle);
      g_FileHandle = INVALID_HANDLE;
     }
  }

//+------------------------------------------------------------------+
//| كتابة صف واحد                                                       |
//+------------------------------------------------------------------+
void AppendRow(const string row)
  {
   if(g_FileHandle == INVALID_HANDLE) return;
   FileSeek(g_FileHandle, 0, SEEK_END);
   FileWriteString(g_FileHandle, row + "\r\n", FILE_ANSI);
   FileFlush(g_FileHandle);
  }

//+------------------------------------------------------------------+
//| حساب العمولة من تاريخ الصفقة (إن وُجدت)                             |
//+------------------------------------------------------------------+
double CommissionForPosition(const ulong posTicket)
  {
   double comm = 0.0;
   if(HistorySelectByPosition(posTicket))
     {
      int deals = HistoryDealsTotal();
      for(int i = 0; i < deals; i++)
        {
         ulong dt = HistoryDealGetTicket(i);
         if(dt == 0) continue;
         comm += HistoryDealGetDouble(dt, DEAL_COMMISSION);
        }
     }
   return(comm);
  }

//+------------------------------------------------------------------+
//| تسجيل صفقة                                                        |
//+------------------------------------------------------------------+
void LogPosition(ulong ticket, string eventName)
  {
   if(!PositionSelectByTicket(ticket))
     {
      if(InpShowPrint)
         PrintFormat("TradeMonitor: الصفقة %I64u غير متاحة (أُغلقت) — event=%s", ticket, eventName);
      return;
     }

   long   type     = PositionGetInteger(POSITION_TYPE);
   string sym      = PositionGetString(POSITION_SYMBOL);
   string tf       = TFName(_Period);
   double volume   = PositionGetDouble(POSITION_VOLUME);
   double open     = PositionGetDouble(POSITION_PRICE_OPEN);
   double sl       = PositionGetDouble(POSITION_SL);
   double tp       = PositionGetDouble(POSITION_TP);
   double profit   = PositionGetDouble(POSITION_PROFIT);
   double swap     = PositionGetDouble(POSITION_SWAP);
   double bal      = AccountInfoDouble(ACCOUNT_BALANCE);
   long   magic    = PositionGetInteger(POSITION_MAGIC);
   string comment  = PositionGetString(POSITION_COMMENT);
   double comm     = CommissionForPosition(ticket);

   double close    = open;
   if(profit != 0.0 || swap != 0.0)
      close        = open + (profit + swap) / (volume * (type == POSITION_TYPE_BUY ? 1 : -1)) / (_Point == 0 ? 1 : 1);

   string row = StringFormat(
      "%s,%s,%s,%s,%s,%.5f,%.5f,%.5f,%.5f,%.5f,%.2f,%.2f,%.2f,%.2f,%d,%d,\"%s\",%d",
      TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES),
      eventName,
      DirName(type),
      sym,
      tf,
      volume,
      open,
      sl,
      tp,
      close,
      profit,
      swap,
      comm,
      bal,
      (long)magic,
      (int)ticket,
      comment,
      MathRound(TimeCurrent() - (datetime)PositionGetInteger(POSITION_TIME)));

   AppendRow(row);

   if(InpShowPrint)
      PrintFormat("TradeMonitor[%s]: %s %s qty=%.2f magic=%d comment='%s' open=%.5f SL=%.5f TP=%.5f profit=%.2f",
                  eventName, sym, DirName(type), volume, (long)magic, comment, open, sl, tp, profit);
  }

//+------------------------------------------------------------------+
//| OnTradeTransaction                                                |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   ulong posTicket = trans.position;
   if(posTicket == 0)
      posTicket = trans.deal;

   // الأحداث الخاصة بالمراكز فقط (فتح/إغلاق/تحديث)
   switch(trans.type)
     {
      case TRADE_TRANSACTION_POSITION_ADD:
         LogPosition(posTicket, "POSITION_OPEN");
         break;
      case TRADE_TRANSACTION_POSITION_UPDATE:
         LogPosition(posTicket, "POSITION_UPDATE");
         break;
      case TRADE_TRANSACTION_POSITION_REMOVE:
         LogPosition(posTicket, "POSITION_CLOSED");
         break;
      default:
         break;
     }
  }

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!OpenLog())
      return(INIT_FAILED);

   PrintFormat("TradeMonitor: بدأ المراقبة على %s %s — %s", _Symbol, TFName(_Period), TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));

   // تسجيل الصفقات المفتوحة حالياً
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
         LogPosition(ticket, "POSITION_INITIAL");
     }
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| OnDeinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   CloseLog();
   if(InpShowPrint)
      PrintFormat("TradeMonitor: انتهت المراقبة — reason=%d", reason);
  }
//+------------------------------------------------------------------+
