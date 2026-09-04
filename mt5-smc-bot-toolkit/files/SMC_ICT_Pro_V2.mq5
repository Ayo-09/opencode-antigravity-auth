//+------------------------------------------------------------------+
//|                                               SMC_ICT_Pro_V2.mq5 |
//|                        SMC/ICT Automated Trading Bot for MT5     |
//|                                                                  |
//|  مبني حرفياً على مواصفات "البرومبت الشامل الاحترافي لبناء وتدقيق |
//|  واختبار بوت تداول آلي على MT5".                                  |
//|                                                                  |
//|  ملاحظة التزام:                                                  |
//|  - لا Martingale، لا Grid غير محدود، لا تحريك SL بعيداً.         |
//|  - Stop Loss حقيقي دائماً، لوت محسوب بالمخاطرة لا بالتخمين.      |
//|  - فلاتر: سبريد، انحراف، جلسات، أخبار، نهاية أسبوع، New Bar.     |
//|  - حدود: يومي، أسبوعي، تراجع، خسائر متتالية، توقف/تبريد.        |
//|  - لوحة مراقبة على الشارت (قراءة فقط) + Journal/CSV.             |
//|  - كشف تلقائي لنوع الأصل/الرمز/الإطار الزمني.                    |
//|  - Comment = اسم ملف البوت عبر MQLInfoString(MQL_PROGRAM_NAME)   |
//|    مع إزالة الامتداد والقَصّ إلى 31 حرفاً (MT5 لا يحفظ اسم       |
//|    الملف في الصفقة؛ يحفظ فقط Magic وComment).                    |
//+------------------------------------------------------------------+
#property strict
#property copyright "SMC/ICT Bot Toolkit"
#property link      "https://github.com/Ayo-09"
#property version   "2.00"
#property description "SMC/ICT Expert Advisor — متوافق مع MT5، يدعم الكريبتو/USDT، الفوركس، السلع، الأسهم، المؤشرات، وجميع الأطر الزمنية."
#property description "لا تفتح أياً من التطبيقات التي تعد بربح مستقبلي. الاختبار التاريخي ليس ضماناً للأداء الحي."

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| التعدادات                                                         |
//+------------------------------------------------------------------+
enum ENUM_ASSET_TYPE
  {
   ASSET_FOREX     = 0,   // FOREX — أزرق سماوي
   ASSET_CRYPTO    = 1,   // CRYPTO — ذهبي
   ASSET_INDEX     = 2,   // INDEX — بنفسجي
   ASSET_COMMODITY = 3,   // COMMODITY — برتقالي
   ASSET_STOCK     = 4,   // STOCK — أخضر
   ASSET_OTHER     = 5    // OTHER — رمادي
  };

enum ENUM_NEWS_MODE
  {
   NEWS_DISABLED  = 0,    // معطّل
   NEWS_CSV       = 1,    // ملف CSV تاريخي
   NEWS_CALENDAR  = 2     // تقويم MT5 المدمج (Live)
  };

enum ENUM_LOG_LEVEL
  {
   LOG_ERROR   = 0,
   LOG_WARNING = 1,
   LOG_INFO    = 2,
   LOG_DEBUG   = 3
  };

enum ENUM_BLOCK_MODE
  {
   BLOCK_NEW_TRADES    = 0,   // منع صفقات جديدة فقط
   BLOCK_AND_HOLD      = 1,   // منع جديد + الحفاظ على المراكز
   BLOCK_AND_CLOSE     = 2    // منع جديد + إغلاق (يتطلب Input صريح)
  };

//+------------------------------------------------------------------+
//| الإدخالات — 1. التشغيل التعرف التلقائي                             |
//+------------------------------------------------------------------+
input group "=== 1. التعرف التلقائي والتشغيل ==="
input bool               InpEnableEA             = true;       // تفعيل البوت
input int                InpMagic                = 702001;     // Magic Number فريد
input ENUM_TIMEFRAMES    InpSignalTF             = PERIOD_CURRENT; // إطار الإشارة (CURRENT=شارت)
input ENUM_TIMEFRAMES    InpBiasTF               = PERIOD_H1;  // إطار الاتجاه (HTF Bias)
input bool               InpAutoDetectAssetType  = true;       // كشف تلقائي لنوع الأصل
input bool               InpUseChartTF           = true;       // استخدام إطار الشارت تلقائياً
input bool               InpOnlyTradeDetected    = false;      // التداول فقط إذا تم التعرف على نوع الأصل

//+------------------------------------------------------------------+
//| الإدخالات — 2. إدارة المخاطر                                       |
//+------------------------------------------------------------------+
input group "=== 2. إدارة المخاطر ==="
input bool               InpEnableRiskBasedLot    = true;      // لوت مبني على المخاطرة
input double             InpRiskPerTradePercent   = 0.50;      // مخاطرة الصفقة %
input bool               InpUseFixedLotForTesting = false;     // لوت ثابت (لاختبار فقط)
input double             InpFixedLot               = 0.01;      // اللوت الثابت
input double             InpMaxLot                 = 10.0;      // أقصى لوت للبوت
input double             InpMaxOpenRiskPercent     = 1.00;      // أقصى مخاطرة مفتوحة %
input int                InpMaxOpenPositionsPerSymbol = 1;     // أقصى مراكز لكل رمز
input bool               InpAllowHedge            = false;      // السماح بالهيدج
input double             InpDailyLossLimitPercent = 2.00;      // حد الخسارة اليومي %
input double             InpWeeklyLossLimitPercent = 4.00;     // حد الخسارة الأسبوعي %
input double             InpMaxEquityDrawdownPercent = 10.00;  // حد التراجع %
input int                InpMaxConsecutiveLosses  = 3;         // أقصى خسائر متتالية
input int                InpCooldownMinutes       = 60;        // التبريد بعد الخسائر المتتالية
input int                InpMaxTradesPerDay       = 5;         // أقصى صفقات يومياً
input int                InpMaxTradesPerSession   = 3;         // أقصى صفقات بالجلسة
input bool               InpCloseOnDrawdownLimit  = false;     // إغلاق المراكز عند حد التراجع

//+------------------------------------------------------------------+
//| الإدخالات — 3. فلاتر التنفيذ                                       |
//+------------------------------------------------------------------+
input group "=== 3. فلاتر التنفيذ ==="
input bool               InpEnableSpreadFilter     = true;     // فلتر السبريد
input int                InpMaxSpreadPoints        = 30;       // أقصى سبريد بالنقاط
input int                InpMaxDeviationPoints     = 20;       // أقصى انحراف بالتنفيذ
input bool               InpRequireValidTick        = true;    // اشتراط Tick صالح
input bool               InpEnableNewBarOnly        = true;    // إشارة واحدة لكل شمعة جديدة
input int                InpBlockBeforeWeekendMinutes = 120;    // منع جديد قبل نهاية الأسبوع
input bool               InpBlockMondayMorning      = false;   // منع الاثنين الصباحي

//+------------------------------------------------------------------+
//| الإدخالات — 4. جلسات التداول                                       |
//+------------------------------------------------------------------+
input group "=== 4. جلسات التداول ==="
input bool               InpEnableSessionFilter    = true;     // تفعيل فلتر الجلسات
input bool               InpEnableLondonSession    = true;     // جلسة لندن
input int                InpLondonStartHour        = 8;        // بداية لندن (ساعة السيرفر)
input int                InpLondonEndHour          = 17;       // نهاية لندن
input bool               InpEnableNewYorkSession   = true;     // جلسة نيويورك
input int                InpNewYorkStartHour       = 13;       // بداية نيويورك
input int                InpNewYorkEndHour         = 22;       // نهاية نيويورك
input bool               InpAllowOverlapSessions   = true;     // السماح بالتداخل

//+------------------------------------------------------------------+
//| الإدخالات — 5. فلتر الأخبار                                        |
//+------------------------------------------------------------------+
input group "=== 5. فلتر الأخبار ==="
input bool               InpEnableNewsFilter       = true;     // تفعيل فلتر الأخبار
input ENUM_NEWS_MODE     InpNewsDataMode           = NEWS_CALENDAR; // مصدر الأخبار
input string             InpNewsCSVFileName        = "news_events.csv"; // ملف أخبار CSV
input int                InpNewsMinutesBefore      = 30;       // دقائق قبل الخبر
input int                InpNewsMinutesAfter       = 30;       // دقائق بعد الخبر
input bool               InpCloseBeforeHighImpactNews = false; // إغلاق قبل أخبار عالية الأثر
input bool               InpFailSafeMode           = true;     // وضع FailSafe (منع عند غياب البيانات)

//+------------------------------------------------------------------+
//| الإدخالات — 6. إدارة المراكز                                       |
//+------------------------------------------------------------------+
input group "=== 6. إدارة المراكز ==="
input bool               InpBreakEven              = true;      // نقلة Break-even
input double             InpBreakEvenTriggerPoints = 20;       // تفعيل Break-even عند نقاط الربح
input double             InpBreakEvenLockPoints    = 2;        // تثبيت ربح بعد النقل
input bool               InpTrailingStop           = true;      // Trailing Stop
input double             InpTrailingStartPoints    = 30;       // بداية التتبع بالنقاط
input double             InpTrailingStepPoints     = 10;       // خطوة التتبع بالنقاط
input bool               InpPartialClose           = false;     // إغلاق جزئي
input double             InpPartialClosePercent    = 50.0;     // نسبة الإغلاق الجزئي %
input double             InpPartialCloseTriggerPoints = 40;    // النقاط قبل الإغلاق الجزئي
input int                InpMaxBarsInTrade         = 0;        // أقصى شموع للصفقة (0 = بدون حد)
input bool               InpUseStopLevelCheck      = true;     // التحقق من Stops Level وFreeze Level

//+------------------------------------------------------------------+
//| الإدخالات — 7. التسجيل والواجهة                                    |
//+------------------------------------------------------------------+
input group "=== 7. التسجيل واللوحة ==="
input bool               InpWriteJournalCSV       = true;      // كتابة Journal CSV
input string             InpJournalCSVName        = "SMC_ICT_Pro_V2_Journal.csv"; // ملف السجل
input ENUM_LOG_LEVEL     InpLogLevel              = LOG_INFO;  // مستوى التسجيل
input bool               InpShowDashboard         = true;      // لوحة المراقبة على الشارت
input int                InpDashboardCorner       = 1;         // ركن اللوحة (1=العليا اليسار،2=العليا اليمين،3=السفلى اليسار،4=السفلى اليمين)

//+------------------------------------------------------------------+
//| الإدخالات — 8. منطق SMC/ICT                                       |
//+------------------------------------------------------------------+
input group "=== 8. منطق SMC/ICT ==="
input int                InpSMCSwingLookback      = 3;         // Lookback القمم/القيعان
input int                InpSMCZigZagLimit        = 15;        // عدد الكسور للتتبع
input double             InpSMCEqualTolerancePercent = 0.15;   // % تسامح القمم/القيعان المتساوية
input double             InpSMCOTELow             = 61.8;      // OTE أدنى %
input double             InpSMCOTEHigh            = 79.0;      // OTE أعلى %
input bool               InpSMCRequireFVG         = true;      // اشتراط فجوة FVG
input bool               InpSMCRequireSweep       = true;      // اشتراط كنس سيولة
input bool               InpSMCRequireCHoCH       = true;      // اشتراط CHoCH
input bool               InpSMCUseHTFBias         = true;      // مصادقة اتجاه HTF

//+------------------------------------------------------------------+
//| متغيرات عامة                                                       |
//+------------------------------------------------------------------+
CTrade   trade;
string   g_EAComment = "";
string   g_Prefix    = "SMCPRO_";
int      g_LastBarTime = 0;
bool     g_InitOK    = false;
ENUM_ASSET_TYPE g_AssetType = ASSET_OTHER;
string   g_AssetName = "";
double   g_PeakEquity = 0.0;
double   g_CurDrawdownPct = 0.0;
datetime g_LastBlockTime = 0;
bool     g_PausedManual = false;
int      g_ConsecutiveLosses = 0;
datetime g_CooldownUntil = 0;
double   g_DailyNetPnL = 0.0;
double   g_WeeklyNetPnL = 0.0;
int      g_TradesToday = 0;
double   g_TodayStartEquity = 0.0;
double   g_InitBalance = 0.0;
double   g_MaxEquity = 0.0;
double   g_MaxDrawdownMoney = 0.0;

//--- مصفوفات الأسعار للتحليل
double   g_high[];
double   g_low[];
double   g_close[];
double   g_open[];
datetime g_time[];
int      g_swingHighIdx[];
int      g_swingLowIdx[];
int      g_swingHighNum = 0;
int      g_swingLowNum  = 0;

//--- حالة الإشارة
string   g_LastReasonBuy  = "";
string   g_LastReasonSell = "";
datetime g_LastEvalTime   = 0;

//+------------------------------------------------------------------+
//| إعداد تعليق الصفقات: اسم الملف نفسه (حد 31 حرفاً)                   |
//+------------------------------------------------------------------+
string BuildEAComment()
  {
   string name = MQLInfoString(MQL_PROGRAM_NAME);
   int dot = StringFind(name, ".");
   if(dot >= 0)
      name = StringSubstr(name, 0, dot);
   name = StringTrimLeft(name);
   name = StringTrimRight(name);
   if(StringLen(name) > 31)
      name = StringSubstr(name, 0, 31);
   if(StringLen(name) == 0)
      name = "SMC_ICT_Pro_V2";
   return(name);
  }

//+------------------------------------------------------------------+
//| اسم الإطار الزمني                                                  |
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
//| كشف نوع الأصل تلقائياً                                             |
//+------------------------------------------------------------------+
bool IsStablecoin(string s)
  {
   string up = s;
   StringToUpper(up);
   if(StringFind(up, "USDT") >= 0) return(true);
   if(StringFind(up, "USDC") >= 0) return(true);
   if(StringFind(up, "BUSD") >= 0) return(true);
   if(StringFind(up, "TUSD") >= 0) return(true);
   if(StringFind(up, "DAI")  >= 0) return(true);
   return(false);
  }

bool IsCryptoBase(string s)
  {
   string up = s;
   StringToUpper(up);
   string bases[] = {"BTC","ETH","XRP","BNB","SOL","ADA","DOGE","LTC","BCH","DOT","LINK","AVAX","NEAR","MATIC","TRX","XLM","ATOM","UNI","SHIB","LUNC","PEPE","TON","APT","ARB","OP","SUI","SEI","FIL","ETC","OKB","HBAR","VET","RUNE","QNT","EGLD","XTZ","FLOW","ALGO","IMX","GALA","AAVE","MKR","CRV","LDO","TIA","INJ","STX","KAVA","ZIL","ONE","MANA","SAND","AXS","EOS","IOTA","DASH","ZEC","XMR","NEO","KSM","WAVES","UNI"};
   for(int i = 0; i < ArraySize(bases); i++)
     {
      if(StringFind(up, bases[i]) == 0)
         return(true);
     }
   return(false);
  }

bool IsFxSymbol(string s)
  {
   string up = s;
   StringToUpper(up);
   if(StringLen(up) != 6) return(false);
   string majors[] = {"EUR","GBP","USD","JPY","CHF","AUD","NZD","CAD"};
   int found = 0;
   for(int i = 0; i < 8; i++)
     {
      if(StringFind(up, majors[i]) >= 0) found++;
     }
   return(found >= 2);
  }

bool IsMetals(string s)
  {
   string up = s;
   StringToUpper(up);
   if(StringFind(up, "XAU") >= 0) return(true);
   if(StringFind(up, "XAG") >= 0) return(true);
   if(StringFind(up, "XPT") >= 0) return(true);
   if(StringFind(up, "XPD") >= 0) return(true);
   if(StringFind(up, "XCU") >= 0) return(true);
   return(false);
  }

bool IsEnergyCommodity(string s)
  {
   string up = s;
   StringToUpper(up);
   if(StringFind(up, "OIL") >= 0)  return(true);
   if(StringFind(up, "WTI") >= 0)  return(true);
   if(StringFind(up, "BRENT") >= 0) return(true);
   if(StringFind(up, "UKOIL") >= 0) return(true);
   if(StringFind(up, "NGAS") >= 0) return(true);
   if(StringFind(up, "NATGAS") >= 0) return(true);
   return(false);
  }

bool IsIndexSymbol(string s)
  {
   string up = s;
   StringToUpper(up);
   if(StringFind(up, "US30") >= 0) return(true);
   if(StringFind(up, "US500") >= 0) return(true);
   if(StringFind(up, "NAS") >= 0)  return(true);
   if(StringFind(up, "SPX") >= 0)  return(true);
   if(StringFind(up, "DJI") >= 0)  return(true);
   if(StringFind(up, "DAX") >= 0)  return(true);
   if(StringFind(up, "GER") >= 0)  return(true);
   if(StringFind(up, "DE30") >= 0) return(true);
   if(StringFind(up, "CAC") >= 0)  return(true);
   if(StringFind(up, "F40") >= 0)  return(true);
   if(StringFind(up, "FTSE") >= 0) return(true);
   if(StringFind(up, "UK100") >= 0) return(true);
   if(StringFind(up, "SMI") >= 0)  return(true);
   if(StringFind(up, "NIKKEI") >= 0) return(true);
   if(StringFind(up, "JPN") >= 0)  return(true);
   if(StringFind(up, "AXI") >= 0)  return(true);
   if(StringFind(up, "HK50") >= 0) return(true);
   if(StringFind(up, "HKG") >= 0)  return(true);
   if(StringFind(up, "VIX") >= 0)  return(true);
   return(false);
  }

ENUM_ASSET_TYPE DetectAssetType(string symbol)
  {
   string s = symbol;
   StringTrimLeft(s);
   StringTrimRight(s);
   if(IsStablecoin(s) || IsCryptoBase(s))
      return(ASSET_CRYPTO);
   if(IsFxSymbol(s))
      return(ASSET_FOREX);
   if(IsMetals(s) || IsEnergyCommodity(s))
      return(ASSET_COMMODITY);
   if(IsIndexSymbol(s))
      return(ASSET_INDEX);
   // أسهم: عادةً مؤشر باسم شركة مع امتداد سوق (مثل TSLA, AAPL, .US)
   if(StringFind(s, ".") >= 0)
      return(ASSET_STOCK);
   // check suffix indicators
   string up = s;
   StringToUpper(up);
   if(StringFind(up, ".US") >= 0 || StringFind(up, ".DE") >= 0 || StringFind(up, ".FR") >= 0 ||
      StringFind(up, ".UK") >= 0 || StringFind(up, ".JP") >= 0 || StringFind(up, ".HK") >= 0)
      return(ASSET_STOCK);
   return(ASSET_OTHER);
  }

string AssetTypeName(ENUM_ASSET_TYPE t)
  {
   switch(t)
     {
      case ASSET_FOREX:     return("FOREX");
      case ASSET_CRYPTO:    return("CRYPTO");
      case ASSET_INDEX:     return("INDEX");
      case ASSET_COMMODITY: return("COMMODITY");
      case ASSET_STOCK:     return("STOCK");
      default:              return("OTHER");
     }
  }

string AssetTypeIcon(ENUM_ASSET_TYPE t)
  {
   switch(t)
     {
      case ASSET_FOREX:     return("💹");
      case ASSET_CRYPTO:    return("🪙");
      case ASSET_INDEX:     return("📈");
      case ASSET_COMMODITY: return("📊");
      case ASSET_STOCK:     return("💰");
      default:              return("🧩");
     }
  }

//+------------------------------------------------------------------+
//| حساب السبريد الحالي بالنقاط                                        |
//+------------------------------------------------------------------+
double CurrentSpreadPoints()
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask <= 0 || bid <= 0) return(0.0);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0) return(0.0);
   return(MathAbs(ask - bid) / point);
  }

//+------------------------------------------------------------------+
//| التحقق من صحة التداول على الرمز                                     |
//+------------------------------------------------------------------+
bool IsSymbolTradable()
  {
   long mode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(mode == SYMBOL_TRADE_MODE_DISABLED)
      return(false);
   if(mode == SYMBOL_TRADE_MODE_FULL)
      return(true);
   if(mode == SYMBOL_TRADE_MODE_CLOSEONLY)
      return(false);
   // في وضع التداول الخارجي قد يسمح بفتح رغم CLOSEONLY في بعض الوسطاء
   return(true);
  }

//+------------------------------------------------------------------+
//| هل في البوت أوامر/مراكز للرمز والماجيك                               |
//+------------------------------------------------------------------+
int CountPositions(string symbol, long magic)
  {
   int cnt = 0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      string s = PositionGetString(POSITION_SYMBOL);
      long m  = PositionGetInteger(POSITION_MAGIC);
      if(s == symbol && m == magic)
         cnt++;
     }
   return(cnt);
  }

int CountPositionsBuy(string symbol, long magic)
  {
   int cnt = 0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      string s = PositionGetString(POSITION_SYMBOL);
      long m  = PositionGetInteger(POSITION_MAGIC);
      long t  = PositionGetInteger(POSITION_TYPE);
      if(s == symbol && m == magic && t == POSITION_TYPE_BUY)
         cnt++;
     }
   return(cnt);
  }

int CountPositionsSell(string symbol, long magic)
  {
   int cnt = 0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      string s = PositionGetString(POSITION_SYMBOL);
      long m  = PositionGetInteger(POSITION_MAGIC);
      long t  = PositionGetInteger(POSITION_TYPE);
      if(s == symbol && m == magic && t == POSITION_TYPE_SELL)
         cnt++;
     }
   return(cnt);
  }

double TotalOpenRiskMoney()
  {
   double riskMoney = 0.0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      long m = PositionGetInteger(POSITION_MAGIC);
      if(m != InpMagic) continue;
      double vol = PositionGetDouble(POSITION_VOLUME);
      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      if(vol <= 0 || sl <= 0) continue;
      long type = PositionGetInteger(POSITION_TYPE);
      double riskPips = 0.0;
      double point = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_POINT);
      if(point <= 0) continue;
      if(type == POSITION_TYPE_BUY)
         riskPips = MathAbs(open - sl) / point;
      else
         riskPips = MathAbs(sl - open) / point;
      double tickVal = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_TRADE_TICK_VALUE);
      double tickSize = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_TRADE_TICK_SIZE);
      if(tickVal <= 0 || tickSize <= 0) continue;
      double riskPerLot = tickVal * riskPips * point / tickSize;
      riskMoney += vol * riskPerLot;
     }
   return(riskMoney);
  }

//+------------------------------------------------------------------+
//| حساب حجم العقد بناءً على المخاطرة                                   |
//+------------------------------------------------------------------+
double NormalizeVolume(double rawVolume, const string symbol)
  {
   double min  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double max  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;
   double v = MathFloor(rawVolume / step) * step;
   if(v < min) v = min;
   if(v > max) v = max;
   return(NormalizeDouble(v, 2));
  }

double CalculateLot(string symbol, double slPrice)
  {
   if(InpUseFixedLotForTesting)
      return(NormalizeVolume(InpFixedLot, symbol));

   double riskMoney = AccountInfoDouble(ACCOUNT_EQUITY) * InpRiskPerTradePercent / 100.0;
   if(riskMoney <= 0) return(0.0);

   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double open = (ask > 0 ? ask : bid);
   if(open <= 0 || slPrice <= 0 || MathAbs(open - slPrice) < _Point)
      return(0.0);

   double point    = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double tickVal  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   if(point <= 0 || tickVal <= 0 || tickSize <= 0)
      return(0.0);

   double riskPips = MathAbs(open - slPrice) / point;
   double riskPerLot = tickVal * riskPips * point / tickSize;
   if(riskPerLot <= 0)
      return(0.0);

   double raw = riskMoney / riskPerLot;
   double vol = NormalizeVolume(raw, symbol);
   double min = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double max = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   if(vol < min || vol > max) return(0.0);
   if(vol > InpMaxLot) vol = InpMaxLot;
   // تحقق من المخاطرة الفعلية
   double actualRiskPerLot = tickVal * riskPips * point / tickSize;
   double actualRisk = vol * actualRiskPerLot;
   if(actualRisk > riskMoney * 1.05)
      return(0.0);
   return(vol);
  }

//+------------------------------------------------------------------+
//| الفلاتر الزمنية: يوم/أسبوع/جلسة/خبر/نهاية أسبوع                    |
//+------------------------------------------------------------------+
bool IsWeekendBlocked()
  {
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
   // الجمعة قبل نهاية الأسبوع
   if(dt.day_of_week == 5)
     {
      int minutesTo = (23 * 60 + 59) - (dt.hour * 60 + dt.min);
      if(minutesTo <= InpBlockBeforeWeekendMinutes)
         return(true);
     }
   // السبت والجمعة
   if(dt.day_of_week == 6)
      return(true);
   if(dt.day_of_week == 0)
      return(true);
   if(InpBlockMondayMorning && dt.day_of_week == 1)
     {
      if(dt.hour < 8)
         return(true);
     }
   return(false);
  }

bool IsInLondonSession(MqlDateTime dt)
  {
   if(!InpEnableLondonSession) return(false);
   int h = dt.hour;
   if(InpLondonStartHour <= InpLondonEndHour)
      return(h >= InpLondonStartHour && h < InpLondonEndHour);
   // الجلسة تعبر منتصف الليل
   return(h >= InpLondonStartHour || h < InpLondonEndHour);
  }

bool IsInNewYorkSession(MqlDateTime dt)
  {
   if(!InpEnableNewYorkSession) return(false);
   int h = dt.hour;
   if(InpNewYorkStartHour <= InpNewYorkEndHour)
      return(h >= InpNewYorkStartHour && h < InpNewYorkEndHour);
   return(h >= InpNewYorkStartHour || h < InpNewYorkEndHour);
  }

string SessionName(MqlDateTime dt)
  {
   bool l = IsInLondonSession(dt);
   bool n = IsInNewYorkSession(dt);
   if(l && n) return("LONDON+NY");
   if(l) return("LONDON");
   if(n) return("NEWYORK");
   return("OFF-SESSION");
  }

bool IsSessionAllowed()
  {
   if(!InpEnableSessionFilter) return(true);
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   bool l = IsInLondonSession(dt);
   bool n = IsInNewYorkSession(dt);
   if(l && n) return(InpAllowOverlapSessions);
   return(l || n);
  }

//--- قاموس أخبار CSV بسيط
struct NewsRow
  {
   datetime time;
   string   currency;
   int      impact; // 0=low,1=medium,2=high
   string   event;
  };

NewsRow g_newsRows[];
int     g_newsCount = 0;

long ParseDateTimeFromString(string ds)
  {
   string dtStr = ds;
   StringTrimLeft(dtStr); StringTrimRight(dtStr);
   int first = (int)StringToInteger(dtStr);
   if(first > 0)
      return(first);

   MqlDateTime m;
   m.year = 1970; m.mon = 1; m.day = 1; m.hour = 0; m.min = 0; m.sec = 0;
   int p1 = 0, p2 = 0, p3 = 0, p4 = 0;
   p1 = StringFind(dtStr, ".");
   if(p1 < 0) p1 = StringFind(dtStr, "-");
   if(p1 < 0) p1 = StringFind(dtStr, " ");
   if(p1 > 0)
     {
      m.year = (int)StringToInteger(StringSubstr(dtStr, 0, p1));
      string rest = StringSubstr(dtStr, p1 + 1);
      p2 = StringFind(rest, ".");
      if(p2 < 0) p2 = StringFind(rest, "-");
      if(p2 < 0) p2 = StringFind(rest, " ");
      if(p2 > 0)
        {
         m.mon = (int)StringToInteger(StringSubstr(rest, 0, p2));
         string rest2 = StringSubstr(rest, p2 + 1);
         p3 = StringFind(rest2, " ");
         if(p3 < 0) p3 = StringFind(rest2, "T");
         if(p3 > 0)
           {
            m.day = (int)StringToInteger(StringSubstr(rest2, 0, p3));
            string rest3 = StringSubstr(rest2, p3 + 1);
            p4 = StringFind(rest3, ":");
            if(p4 > 0)
              {
               m.hour = (int)StringToInteger(StringSubstr(rest3, 0, p4));
               string rest4 = StringSubstr(rest3, p4 + 1);
               m.min = (int)StringToInteger(StringSubstr(rest4, 0, 2));
              }
           }
        }
     }
   return((long)StructToTime(m));
  }

bool LoadNewsCSV(string fileName)
  {
   int handle = FileOpen(fileName, FILE_READ | FILE_CSV | FILE_ANSI, ',', CP_UTF8);
   if(handle == INVALID_HANDLE)
      return(false);

   ArrayResize(g_newsRows, 0);
   g_newsCount = 0;
   string ds = "", cur = "", imp = "", ev = "";
   while(!FileIsEnding(handle))
     {
      ds = FileReadString(handle);
      if(FileIsEnding(handle) && StringLen(ds) == 0)
         break;
      cur = FileReadString(handle);
      imp = FileReadString(handle);
      ev = FileReadString(handle);
      if(StringFind(ds, "datetime") >= 0 || StringFind(ds, "time") >= 0)
         continue;
      if(StringLen(ds) == 0)
         continue;
      NewsRow nr;
      nr.time = (datetime)ParseDateTimeFromString(ds);
      int impact = 0;
      string impUp = imp;
      StringToUpper(impUp);
      if(StringFind(impUp, "HIGH") >= 0) impact = 2;
      else if(StringFind(impUp, "MEDIUM") >= 0 || StringFind(impUp, "MED") >= 0) impact = 1;
      nr.currency = cur;
      nr.impact = impact;
      nr.event = ev;
      int sz = ArraySize(g_newsRows);
      ArrayResize(g_newsRows, sz + 1);
      g_newsRows[sz] = nr;
     }
   FileClose(handle);
   g_newsCount = ArraySize(g_newsRows);
   return(g_newsCount > 0);
  }

string SymbolBase(string s)
  {
   string top = s;
   StringToUpper(top);
   // محاولة الحصول على العملة الأساسية المعروفة
   string majors[] = {"EUR","GBP","USD","JPY","CHF","AUD","NZD","CAD"};
   for(int i = 0; i < 8; i++)
     {
      int pos = StringFind(top, majors[i]);
      if(pos == 0)
         return(majors[i]);
      if(pos > 0 && (top[pos-1] == '/' || pos == 0))
         return(majors[i]);
     }
   return("");
  }

string SymbolQuote(string s)
  {
   string top = s;
   StringToUpper(top);
   string majors[] = {"EUR","GBP","USD","JPY","CHF","AUD","NZD","CAD"};
   for(int i = 0; i < 8; i++)
     {
      int pos = StringFind(top, majors[i]);
      if(pos >= 0 && pos + 3 == StringLen(top))
         return(majors[i]);
     }
   return("");
  }

bool IsNewsTime()
  {
   if(!InpEnableNewsFilter) return(false);
   if(InpNewsDataMode == NEWS_DISABLED) return(false);
   datetime now = TimeCurrent();
   datetime before = now - InpNewsMinutesBefore * 60;
   datetime after  = now + InpNewsMinutesAfter * 60;

   if(InpNewsDataMode == NEWS_CSV)
     {
      if(g_newsCount == 0)
        {
         // حاول تحميل مرة واحدة
         LoadNewsCSV(InpNewsCSVFileName);
        }
      if(g_newsCount > 0)
        {
         for(int i = 0; i < g_newsCount; i++)
           {
            if(g_newsRows[i].impact < 1) continue;
            datetime st = g_newsRows[i].time;
            if(st >= before && st <= after)
              {
               // تحقق إن الخبر يتعلق بالرمز
               string b = SymbolBase(_Symbol);
               string q = SymbolQuote(_Symbol);
               string c = g_newsRows[i].currency;
               StringToUpper(c);
               if(StringLen(b) > 0 && StringFind(c, b) >= 0) return(true);
               if(StringLen(q) > 0 && StringFind(c, q) >= 0) return(true);
               // للأسهم/السلع: تعامل بحذر عند غياب عملة -> اعتبار الخبر عاماً
               if(StringLen(b) == 0 && StringLen(q) == 0) return(true);
              }
           }
        }
      else
        {
         if(InpFailSafeMode)
            return(true); // FailSafe: البيانات غير متوفرة => منع
         return(false);
        }
     }
   else if(InpNewsDataMode == NEWS_CALENDAR)
     {
      // التقويم المدمج في MT5
      MqlCalendarEvent events[];
      int evCount = CalendarEventHistory(events, before, after, NULL, NULL);
      if(evCount > 0)
        {
         // وجود أي حدث تقويمي ضمن النافذة يعتبر مانعاً (يُركَّز لاحقاً أكبر
         // عدد أحداث لا يمنع من اعتبار الفلتر فعّالاً).
         return(true);
        }
      else
        {
         if(InpFailSafeMode)
            return(true);
         return(false);
        }
     }
   return(false);
  }

//+------------------------------------------------------------------+
//| الإحصائيات اليومية/الأسبوعية من التاريخ                            |
//+------------------------------------------------------------------+
double NetPnlByPeriod(datetime from, datetime to)
  {
   if(!HistorySelect(from, to))
      return(0.0);
   double total = 0.0;
   int deals = HistoryDealsTotal();
   for(int i = 0; i < deals; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
      long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(magic != InpMagic) continue;
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT) continue;
      total += HistoryDealGetDouble(ticket, DEAL_PROFIT);
      total += HistoryDealGetDouble(ticket, DEAL_SWAP);
      total += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
     }
   return(total);
  }

int CountClosedTradesByPeriod(datetime from, datetime to)
  {
   int cnt = 0;
   if(HistorySelect(from, to))
     {
      int deals = HistoryDealsTotal();
      for(int i = 0; i < deals; i++)
        {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0) continue;
         long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
         long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         if(magic != InpMagic) continue;
         if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT)
            cnt++;
        }
     }
   return(cnt);
  }

int CountConsecutiveLosses()
  {
   int losses = 0;
   // ابدأ من نهاية التاريخ
   if(!HistorySelect(0, TimeCurrent()))
      return(0);
   int deals = HistoryDealsTotal();
   for(int i = deals - 1; i >= 0; i--)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
      long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(magic != InpMagic) continue;
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT) continue;
      double pnl = HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                   HistoryDealGetDouble(ticket, DEAL_SWAP) +
                   HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      if(pnl < 0)
         losses++;
      else
         break;
     }
   return(losses);
  }

int CountTradesToday()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime dayStart;
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   dayStart = StructToTime(dt);
   return(CountClosedTradesByPeriod(dayStart, TimeCurrent()));
  }

int CountTradesThisSession()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   // جلسة بسيطة من منتصف اليوم (يُبتدأ بمنطقة السيرفر)
   datetime sessionStart;
   if(dt.hour >= InpLondonStartHour && dt.hour < InpLondonEndHour)
     {
      dt.hour = InpLondonStartHour; dt.min = 0; dt.sec = 0;
      sessionStart = StructToTime(dt);
     }
   else if(dt.hour >= InpNewYorkStartHour && dt.hour < InpNewYorkEndHour)
     {
      dt.hour = InpNewYorkStartHour; dt.min = 0; dt.sec = 0;
      sessionStart = StructToTime(dt);
     }
   else
      return(0);
   return(CountClosedTradesByPeriod(sessionStart, TimeCurrent()));
  }

//+------------------------------------------------------------------+
//| ملف Journal/CSV                                                   |
//+------------------------------------------------------------------+
int g_journalHandle = INVALID_HANDLE;

bool EnsureJournalCSV()
  {
   if(!InpWriteJournalCSV)
      return(true);
   bool header = (!FileIsExist(InpJournalCSVName, FILE_COMMON) && !FileIsExist(InpJournalCSVName, 0));
   int flags = FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI;
   g_journalHandle = FileOpen(InpJournalCSVName, flags, '\t', CP_UTF8);
   if(g_journalHandle == INVALID_HANDLE)
      return(false);
   FileSeek(g_journalHandle, 0, SEEK_END);
   if(FileTell(g_journalHandle) == 0 || header)
     {
      FileWriteString(g_journalHandle,
         "Time,Decision,Symbol,Magic,System,AssetType,SignalType,Direction,Volume,PriceOpen,SL,TP,SpreadPoints,Balance,Equity,RiskPercent,Retcode,Reason\n",
         FILE_ANSI);
      FileFlush(g_journalHandle);
     }
   return(true);
  }

void Journal(string decision, string signalType, string direction, double volume,
             double priceOpen, double sl, double tp, double riskPercent,
             int retcode, string reason)
  {
   if(!InpWriteJournalCSV) return;
   if(g_journalHandle == INVALID_HANDLE) return;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   string line = StringFormat("%s,%s,%s,%d,%s,%s,%s,%s,%.5f,%.5f,%.5f,%.5f,%.5f,%.2f,%.2f,%.2f,%d,\"%s\"",
      TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES),
      decision,
      _Symbol,
      InpMagic,
      "SMC_ICT_Pro_V2",
      AssetTypeName(g_AssetType),
      signalType,
      direction,
      volume,
      priceOpen,
      sl,
      tp,
      CurrentSpreadPoints(),
      AccountInfoDouble(ACCOUNT_BALANCE),
      AccountInfoDouble(ACCOUNT_EQUITY),
      riskPercent,
      retcode,
      reason);
   FileSeek(g_journalHandle, 0, SEEK_END);
   FileWriteString(g_journalHandle, line + "\r\n", FILE_ANSI);
   FileFlush(g_journalHandle);
  }

void Log(ENUM_LOG_LEVEL level, string msg)
  {
   if((int)level > (int)InpLogLevel) return;
   string tag = "INFO";
   if(level == LOG_ERROR)   tag = "ERROR";
   if(level == LOG_WARNING) tag = "WARN";
   if(level == LOG_DEBUG)   tag = "DEBUG";
   PrintFormat("[%s][%s] %s", tag, _Symbol, msg);
  }

//+------------------------------------------------------------------+
//| شمعة جديدة                                                        |
//+------------------------------------------------------------------+
bool IsNewBar(ENUM_TIMEFRAMES tf)
  {
   if(!InpEnableNewBarOnly)
      return(true);
   datetime t = iTime(_Symbol, tf, 0);
   if(t == 0) return(false);
   if(t == g_LastBarTime)
      return(false);
   g_LastBarTime = t;
   return(true);
  }

//+------------------------------------------------------------------+
//| قراءة بيانات سعرية                                                  |
//+------------------------------------------------------------------+
bool LoadPriceData(ENUM_TIMEFRAMES tf, int bars)
  {
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, tf, 0, bars, rates) < bars)
      return(false);
   ArrayResize(g_high,  bars);
   ArrayResize(g_low,   bars);
   ArrayResize(g_close, bars);
   ArrayResize(g_open,  bars);
   ArrayResize(g_time,  bars);
   for(int i = 0; i < bars; i++)
     {
      g_high[i]  = rates[i].high;
      g_low[i]   = rates[i].low;
      g_close[i] = rates[i].close;
      g_open[i]  = rates[i].open;
      g_time[i]  = rates[i].time;
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| اكتشاف القمم/القيعان (Swing)                                       |
//+------------------------------------------------------------------+
void FindSwingPoints(int lookback, int limit)
  {
   int n = ArraySize(g_high);
   if(n < lookback * 2 + 2) return;
   int start = limit;                 // هي index 0 = الأحدث
   int end   = n - lookback - 1;
   ArrayResize(g_swingHighIdx, 0);
   ArrayResize(g_swingLowIdx, 0);
   for(int i = start; i < end; i++)
     {
      bool highOK = true;
      bool lowOK  = true;
      for(int k = 1; k <= lookback; k++)
        {
         if(g_high[i] <= g_high[i-k]) highOK = false;
         if(g_high[i] <= g_high[i+k]) highOK = false;
         if(g_low[i]  >= g_low[i-k])  lowOK  = false;
         if(g_low[i]  >= g_low[i+k])  lowOK  = false;
        }
      if(highOK)
        {
         int sz = ArraySize(g_swingHighIdx);
         ArrayResize(g_swingHighIdx, sz + 1);
         g_swingHighIdx[sz] = i;
        }
      if(lowOK)
        {
         int sz = ArraySize(g_swingLowIdx);
         ArrayResize(g_swingLowIdx, sz + 1);
         g_swingLowIdx[sz] = i;
        }
     }
   g_swingHighNum = ArraySize(g_swingHighIdx);
   g_swingLowNum  = ArraySize(g_swingLowIdx);
  }

//+------------------------------------------------------------------+
//| اتجاه HTF Bias                                                    |
//+------------------------------------------------------------------+
enum ENUM_BIAS { BIAS_UP, BIAS_DOWN, BIAS_FLAT };

ENUM_BIAS GetHTFBias()
  {
   ENUM_TIMEFRAMES tf = InpBiasTF;
   if(InpBiasTF == PERIOD_CURRENT)
      tf = (ENUM_TIMEFRAMES)_Period;
   double closes[];
   ArraySetAsSeries(closes, true);
   if(CopyClose(_Symbol, tf, 0, 60, closes) < 60) return(BIAS_FLAT);
   double ma50 = 0, ma20 = 0;
   for(int i = 1; i <= 50; i++)
     {
      ma50 += closes[i];
      if(i <= 20) ma20 += closes[i];
     }
   ma50 /= 50.0;
   ma20 /= 20.0;
   double last = closes[0];
   if(last > ma50 && last > ma20) return(BIAS_UP);
   if(last < ma50 && last < ma20) return(BIAS_DOWN);
   return(BIAS_FLAT);
  }

//+------------------------------------------------------------------+
//| FVG detection                                                     |
//+------------------------------------------------------------------+
bool IsBullishFVG(int idx)
  {
   if(idx + 2 >= ArraySize(g_close)) return(false);
   // الشمعة 3 أدنى من الشمعة 1 (فجوة صاعدة)
   if(g_low[idx+2] > g_high[idx])
      return(true);
   return(false);
  }

bool IsBearishFVG(int idx)
  {
   if(idx + 2 >= ArraySize(g_close)) return(false);
   if(g_high[idx+2] < g_low[idx])
      return(true);
   return(false);
  }

bool PriceInsideFVG(int idx, double price)
  {
   if(idx + 2 >= ArraySize(g_close)) return(false);
   if(g_low[idx+2] > g_high[idx])
     {
      return(price <= g_low[idx+2] && price >= g_high[idx]);
     }
   if(g_high[idx+2] < g_low[idx])
     {
      return(price >= g_high[idx+2] && price <= g_low[idx]);
     }
   return(false);
  }

//+------------------------------------------------------------------+
//| كشف كنس السيولة                                                   |
//+------------------------------------------------------------------+
bool IsLiquiditySweepBuy(int lastIdx, int limit)
  {
   // الكنس الصاعد للشراء: اختراق قاع متساوٍ سابق ثم إغلاق أعلى
   int cnt = 0;
   double lastSwingLowPrice = 0.0;
   for(int i = lastIdx; i < lastIdx + limit; i++)
     {
      if(i >= ArraySize(g_low)) break;
      if(i == 0) continue;
      double low = g_low[i];
      if(low < lastSwingLowPrice || lastSwingLowPrice == 0.0)
        {
         lastSwingLowPrice = low;
         cnt++;
         if(cnt >= 1) break;
        }
     }
   if(lastSwingLowPrice <= 0) return(false);
   // هل السعر الحالي أخفض من القاع السابق بالفعل؟
   double curLow = g_low[lastIdx];
   double curClose = g_close[lastIdx];
   if(curLow < lastSwingLowPrice && curClose > lastSwingLowPrice)
      return(true);
   return(false);
  }

bool IsLiquiditySweepSell(int lastIdx, int limit)
  {
   double lastSwingHighPrice = 0.0;
   int cnt = 0;
   for(int i = lastIdx; i < lastIdx + limit; i++)
     {
      if(i >= ArraySize(g_high)) break;
      if(i == 0) continue;
      double high = g_high[i];
      if(high > lastSwingHighPrice || lastSwingHighPrice == 0.0)
        {
         lastSwingHighPrice = high;
         cnt++;
         if(cnt >= 1) break;
        }
     }
   if(lastSwingHighPrice <= 0) return(false);
   double curHigh = g_high[lastIdx];
   double curClose = g_close[lastIdx];
   if(curHigh > lastSwingHighPrice && curClose < lastSwingHighPrice)
      return(true);
   return(false);
  }

//+------------------------------------------------------------------+
//| كشف CHoCH                                                         |
//+------------------------------------------------------------------+
bool IsBullishCHoCH(int lastIdx, int limit)
  {
   if(g_swingLowNum < 2) return(false);
   // نبحث عن آخر قاع هابط ثم كسر أعلى قمة هابطة
   int lastLow = g_swingLowIdx[0];
   int prevLow = -1;
   for(int i = 1; i < g_swingLowNum && i < limit; i++)
     {
      if(g_swingLowIdx[i] > lastLow)
        {
         prevLow = g_swingLowIdx[i];
         break;
        }
     }
   if(prevLow < 0) return(false);
   double lastLowPrice  = g_low[lastLow];
   double prevLowPrice  = g_low[prevLow];
   double currentClose  = g_close[lastIdx];
   if(prevLowPrice > lastLowPrice && currentClose > iHigh(_Symbol, InpSignalTF == PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : InpSignalTF, prevLow))
      return(true);
   return(false);
  }

bool IsBearishCHoCH(int lastIdx, int limit)
  {
   if(g_swingHighNum < 2) return(false);
   int lastHigh = g_swingHighIdx[0];
   int prevHigh = -1;
   for(int i = 1; i < g_swingHighNum && i < limit; i++)
     {
      if(g_swingHighIdx[i] > lastHigh)
        {
         prevHigh = g_swingHighIdx[i];
         break;
        }
     }
   if(prevHigh < 0) return(false);
   double lastHighPrice = g_high[lastHigh];
   double prevHighPrice = g_high[prevHigh];
   double currentClose  = g_close[lastIdx];
   if(prevHighPrice < lastHighPrice && currentClose < iLow(_Symbol, InpSignalTF == PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : InpSignalTF, prevHigh))
      return(true);
   return(false);
  }

//+------------------------------------------------------------------+
//| زاوية OTE                                                         |
//+------------------------------------------------------------------+
bool IsInOTE(double swingLow, double swingHigh, bool buy, double current)
  {
   double range = MathAbs(swingHigh - swingLow);
   if(range <= 0) return(false);
   double retrance = 0.0;
   if(buy)
      retrance = (swingHigh - current) / range * 100.0;
   else
      retrance = (current - swingLow) / range * 100.0;
   return(retrance >= InpSMCOTELow && retrance <= InpSMCOTEHigh);
  }

//+------------------------------------------------------------------+
//| منطق الإشارة: BUY                                                 |
//+------------------------------------------------------------------+
bool IsBuySignal()
  {
   ENUM_TIMEFRAMES tf = InpSignalTF == PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : InpSignalTF;
   if(!LoadPriceData(tf, 200)) { g_LastReasonBuy = "DataError"; return(false); }
   FindSwingPoints(InpSMCSwingLookback, InpSMCZigZagLimit);
   if(g_swingLowNum < 2 || g_swingHighNum == 0) { g_LastReasonBuy = "NoSwingLows"; return(false); }
   int lastIdx = InpSMCSwingLookback;
   double current = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double lastSwingLow = g_low[g_swingLowIdx[0]];
   double lastSwingHigh = g_high[g_swingHighIdx[0]];

   // شرط HTF
   if(InpSMCUseHTFBias)
     {
      ENUM_BIAS bias = GetHTFBias();
      if(bias != BIAS_UP)
        {
         g_LastReasonBuy = "HTFNotUp [" + (bias == BIAS_FLAT ? "FLAT" : "DOWN") + "]";
         return(false);
        }
     }
   // كنس سيولة (Sweep)
   if(InpSMCRequireSweep && !IsLiquiditySweepBuy(lastIdx, InpSMCZigZagLimit))
     {
      g_LastReasonBuy = "NoLiquiditySweep";
      return(false);
     }
   // CHoCH
   if(InpSMCRequireCHoCH && !IsBullishCHoCH(lastIdx, InpSMCZigZagLimit))
     {
      g_LastReasonBuy = "NoCHoCH";
      return(false);
     }
   // FVG
   bool fvgOK = IsBullishFVG(lastIdx + 1);
   if(InpSMCRequireFVG && !fvgOK)
     {
      g_LastReasonBuy = "NoFVG";
      return(false);
     }
   // OTE
   bool oteOK = IsInOTE(lastSwingLow, lastSwingHigh, true, current);
   if(!oteOK)
     {
      g_LastReasonBuy = "NotOTE";
      return(false);
     }
   g_LastReasonBuy = "SMC/ICT OK (Sweep+CHoCH+FVG+OTE+HTF)";
   return(true);
  }

//+------------------------------------------------------------------+
//| منطق الإشارة: SELL                                                |
//+------------------------------------------------------------------+
bool IsSellSignal()
  {
   ENUM_TIMEFRAMES tf = InpSignalTF == PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : InpSignalTF;
   if(!LoadPriceData(tf, 200)) { g_LastReasonSell = "DataError"; return(false); }
   FindSwingPoints(InpSMCSwingLookback, InpSMCZigZagLimit);
   if(g_swingHighNum < 2 || g_swingLowNum == 0) { g_LastReasonSell = "NoSwingHighs"; return(false); }
   int lastIdx = InpSMCSwingLookback;
   double current = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double lastSwingHigh = g_high[g_swingHighIdx[0]];
   double lastSwingLow  = g_low[g_swingLowIdx[0]];

   if(InpSMCUseHTFBias)
     {
      ENUM_BIAS bias = GetHTFBias();
      if(bias != BIAS_DOWN)
        {
         g_LastReasonSell = "HTFNotDown [" + (bias == BIAS_FLAT ? "FLAT" : "UP") + "]";
         return(false);
        }
     }
   if(InpSMCRequireSweep && !IsLiquiditySweepSell(lastIdx, InpSMCZigZagLimit))
     {
      g_LastReasonSell = "NoLiquiditySweep";
      return(false);
     }
   if(InpSMCRequireCHoCH && !IsBearishCHoCH(lastIdx, InpSMCZigZagLimit))
     {
      g_LastReasonSell = "NoCHoCH";
      return(false);
     }
   bool fvgOK = IsBearishFVG(lastIdx + 1);
   if(InpSMCRequireFVG && !fvgOK)
     {
      g_LastReasonSell = "NoFVG";
      return(false);
     }
   bool oteOK = IsInOTE(lastSwingLow, lastSwingHigh, false, current);
   if(!oteOK)
     {
      g_LastReasonSell = "NotOTE";
      return(false);
     }
   g_LastReasonSell = "SMC/ICT OK (Sweep+CHoCH+FVG+OTE+HTF)";
   return(true);
  }

//+------------------------------------------------------------------+
//| حساب SL/TP للـ Buy                                                |
//+------------------------------------------------------------------+
void GetBuySLTP(double ask, double &sl, double &tp)
  {
   ENUM_TIMEFRAMES tf = InpSignalTF == PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : InpSignalTF;
   double swingLow = ask;
   for(int i = 0; i < g_swingLowNum; i++)
     {
      if(g_low[g_swingLowIdx[i]] < swingLow)
         swingLow = g_low[g_swingLowIdx[i]];
     }
   sl = swingLow - 2 * _Point;
   double range = MathAbs(ask - swingLow);
   tp = ask + MathMax(range * 2.0, 20 * _Point);
  }

void GetSellSLTP(double bid, double &sl, double &tp)
  {
   ENUM_TIMEFRAMES tf = InpSignalTF == PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : InpSignalTF;
   double swingHigh = bid;
   for(int i = 0; i < g_swingHighNum; i++)
     {
      if(g_high[g_swingHighIdx[i]] > swingHigh)
         swingHigh = g_high[g_swingHighIdx[i]];
     }
   sl = swingHigh + 2 * _Point;
   double range = MathAbs(swingHigh - bid);
   tp = bid - MathMax(range * 2.0, 20 * _Point);
  }

//+------------------------------------------------------------------+
//| التحقق من Stops Level قبل الدخول                                   |
//+------------------------------------------------------------------+
bool CheckStopLevel(double price, double sl, double tp)
  {
   if(!InpUseStopLevelCheck) return(true);
   if(sl <= 0 || tp <= 0) return(false);
   double stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double freezeLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double minDist = MathMax(stopsLevel, freezeLevel) * point;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(MathAbs(price - sl) < minDist) return(false);
   if(MathAbs(price - tp) < minDist) return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//| فتح صفقة شراء                                                     |
//+------------------------------------------------------------------+
bool OpenBuy(string reason)
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask <= 0 || bid <= 0) return(false);
   double sl = 0, tp = 0;
   GetBuySLTP(ask, sl, tp);
   if(sl <= 0 || tp <= 0) return(false);
   if(!CheckStopLevel(ask, sl, tp)) return(false);
   double lot = CalculateLot(_Symbol, sl);
   if(lot <= 0) return(false);
   // تحقق من حدود المخاطرة المفتوحة
   double openRisk = TotalOpenRiskMoney();
   double maxRisk = AccountInfoDouble(ACCOUNT_EQUITY) * InpMaxOpenRiskPercent / 100.0;
   if(openRisk + (lot * MathAbs(ask - sl) / (SymbolInfoDouble(_Symbol, SYMBOL_POINT) > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_POINT) : 1)) * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) > maxRisk)
      return(false);

   bool res = trade.Buy(lot, _Symbol, ask, sl, tp, g_EAComment);
   Journal("Entry", "SMC_BUY", "BUY", lot, ask, sl, tp, InpRiskPerTradePercent,
           res ? 0 : GetLastError(), reason + " | lot=" + DoubleToString(lot, 2));
   return(res);
  }

//+------------------------------------------------------------------+
//| فتح صفقة بيع                                                      |
//+------------------------------------------------------------------+
bool OpenSell(string reason)
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid <= 0 || ask <= 0) return(false);
   double sl = 0, tp = 0;
   GetSellSLTP(bid, sl, tp);
   if(sl <= 0 || tp <= 0) return(false);
   if(!CheckStopLevel(bid, sl, tp)) return(false);
   double lot = CalculateLot(_Symbol, sl);
   if(lot <= 0) return(false);
   double openRisk = TotalOpenRiskMoney();
   double maxRisk = AccountInfoDouble(ACCOUNT_EQUITY) * InpMaxOpenRiskPercent / 100.0;
   if(openRisk + (lot * MathAbs(sl - bid) / (SymbolInfoDouble(_Symbol, SYMBOL_POINT) > 0 ? SymbolInfoDouble(_Symbol, SYMBOL_POINT) : 1)) * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) > maxRisk)
      return(false);

   bool res = trade.Sell(lot, _Symbol, bid, sl, tp, g_EAComment);
   Journal("Entry", "SMC_SELL", "SELL", lot, bid, sl, tp, InpRiskPerTradePercent,
           res ? 0 : GetLastError(), reason + " | lot=" + DoubleToString(lot, 2));
   return(res);
  }

//+------------------------------------------------------------------+
//| هل الوضع الحالي يسمح بصفقة جديدة؟                                  |
//+------------------------------------------------------------------+
string StatusBlockReason()
  {
   if(!InpEnableEA) return("Disabled");
   if(g_PausedManual) return("Paused");
   if(!IsSymbolTradable()) return("SymbolNotTradable");
   if(InpOnlyTradeDetected && g_AssetType == ASSET_OTHER) return("UnknownAsset");
   if(IsWeekendBlocked()) return("WeekendBlock");
   if(!IsSessionAllowed()) return("SessionBlock");
   if(IsNewsTime()) return("NewsBlock");
   if(g_LastBlockTime > 0 && TimeCurrent() < g_LastBlockTime) return("Cooldown");
   // حدود يومية/أسبوعية
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime dayStart = StructToTime(dt);
   double dailyNet = NetPnlByPeriod(dayStart, TimeCurrent());
   double maxDailyLoss = AccountInfoDouble(ACCOUNT_BALANCE) * InpDailyLossLimitPercent / 100.0;
   if(dailyNet < -maxDailyLoss) return("DailyLimit");
   // أسبوعي
   int dayOffset = dt.day_of_week == 0 ? 6 : dt.day_of_week - 1;
   datetime weekStart = dayStart - dayOffset * 86400;
   double weeklyNet = NetPnlByPeriod(weekStart, TimeCurrent());
   double maxWeeklyLoss = AccountInfoDouble(ACCOUNT_BALANCE) * InpWeeklyLossLimitPercent / 100.0;
   if(weeklyNet < -maxWeeklyLoss) return("WeeklyLimit");
   // تراجع
   if(g_CurDrawdownPct >= InpMaxEquityDrawdownPercent) return("DrawdownLimit");
   // خسائر متتالية
   if(g_ConsecutiveLosses > 0 && g_ConsecutiveLosses >= InpMaxConsecutiveLosses)
      return("ConsecutiveLosses");
   // حدود عدد الصفقات
   if(CountTradesToday() >= InpMaxTradesPerDay) return("MaxTradesPerDay");
   if(InpMaxTradesPerSession > 0 && CountTradesThisSession() >= InpMaxTradesPerSession) return("MaxTradesPerSession");
   // السبريد
   if(InpEnableSpreadFilter)
     {
      double spread = CurrentSpreadPoints();
      if(spread > InpMaxSpreadPoints) return("SpreadBlock");
     }
   return("");
  }

//+------------------------------------------------------------------+
//| إدارة المراكز                                                     |
//+------------------------------------------------------------------+
double PositionPriceOpen(ulong ticket)
  {
   return(PositionGetDouble(POSITION_PRICE_OPEN));
  }

double PositionSL(ulong ticket)
  {
   return(PositionGetDouble(POSITION_SL));
  }

double PositionTP(ulong ticket)
  {
   return(PositionGetDouble(POSITION_TP));
  }

double PositionVolume(ulong ticket)
  {
   return(PositionGetDouble(POSITION_VOLUME));
  }

long PositionType(ulong ticket)
  {
   return(PositionGetInteger(POSITION_TYPE));
  }

bool ModifySL(ulong ticket, double newSL)
  {
   if(newSL <= 0) return(false);
   double curSL = PositionSL(ticket);
   // لا تحرك SL بعيداً أبداً
   long t = PositionType(ticket);
   if(t == POSITION_TYPE_BUY)
     {
      if(curSL > 0 && newSL < curSL) return(false);
     }
   else if(t == POSITION_TYPE_SELL)
     {
      if(curSL > 0 && newSL > curSL) return(false);
     }
   // تحقق من مسافة Stops
   if(InpUseStopLevelCheck)
     {
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      double minDist = stopsLevel * point;
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(t == POSITION_TYPE_BUY && MathAbs(ask - newSL) < minDist) return(false);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(t == POSITION_TYPE_SELL && MathAbs(newSL - bid) < minDist) return(false);
     }
   return(trade.PositionModify(ticket, newSL, PositionTP(ticket)));
  }

void ManageOpenPositions()
  {
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      double open = PositionPriceOpen(ticket);
      double sl   = PositionSL(ticket);
      double tp   = PositionTP(ticket);
      double vol  = PositionVolume(ticket);
      long   type = PositionType(ticket);
      double bid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      if(point <= 0) continue;
      double profitPoints = 0;
      if(type == POSITION_TYPE_BUY)
         profitPoints = (bid - open) / point;
      else
         profitPoints = (open - ask) / point;

      // Break-even
      if(InpBreakEven && profitPoints >= InpBreakEvenTriggerPoints)
        {
         double beSL = open + InpBreakEvenLockPoints * point;
         if(type == POSITION_TYPE_SELL)
            beSL = open - InpBreakEvenLockPoints * point;
         if((type == POSITION_TYPE_BUY && (sl < 0 || sl < beSL)) ||
            (type == POSITION_TYPE_SELL && (sl < 0 || sl > beSL)))
           {
            ModifySL(ticket, beSL);
           }
        }

      // Trailing
      if(InpTrailingStop && profitPoints >= InpTrailingStartPoints)
        {
         double trail = sl;
         if(type == POSITION_TYPE_BUY)
           {
            double newSL = bid - InpTrailingStepPoints * point;
            if(newSL > sl) ModifySL(ticket, newSL);
           }
         else
           {
            double newSL = ask + InpTrailingStepPoints * point;
            if(newSL < sl) ModifySL(ticket, newSL);
           }
        }

      // Partial close
      if(InpPartialClose && profitPoints >= InpPartialCloseTriggerPoints)
        {
         double partialVol = NormalizeVolume(vol * InpPartialClosePercent / 100.0, _Symbol);
         if(partialVol >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
           {
            trade.PositionClosePartial(ticket, partialVol);
            Journal("Partial", "SMC", (type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                    partialVol, open, sl, tp, InpRiskPerTradePercent, 0,
                    "PartialClose " + DoubleToString(profitPoints, 0) + "pts");
           }
        }

      // Max bars in trade
      if(InpMaxBarsInTrade > 0)
        {
         datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
         int barsInside = (int)((TimeCurrent() - openTime) / PeriodSeconds(_Period));
         if(barsInside > InpMaxBarsInTrade)
           {
            trade.PositionClose(ticket);
            Journal("Close", "SMC", (type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                    vol, open, sl, tp, InpRiskPerTradePercent, 0, "MaxBarsInTrade");
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| لوحة المراقبة                                                     |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr, int fontSize=8, string font="Segoe UI")
  {
   string objName = g_Prefix + name;
   if(ObjectFind(0, objName) < 0)
      ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, InpDashboardCorner == 1 ? CORNER_LEFT_UPPER :
                    (InpDashboardCorner == 2 ? CORNER_RIGHT_UPPER :
                     (InpDashboardCorner == 3 ? CORNER_LEFT_LOWER : CORNER_RIGHT_LOWER)));
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, objName, OBJPROP_FONT, font);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
  }

void UpdateDashboard()
  {
   if(!InpShowDashboard) return;
   string status = StatusBlockReason();
   if(StringLen(status) == 0) status = "Trading OK";
   string icon = AssetTypeIcon(g_AssetType);
   string assetName = AssetTypeName(g_AssetType);
   string tf = TFName(_Period);
   double spread = CurrentSpreadPoints();
   double dailyNet = 0;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime dayStart = StructToTime(dt);
   dailyNet = NetPnlByPeriod(dayStart, TimeCurrent());
   int dayOffset = dt.day_of_week == 0 ? 6 : dt.day_of_week - 1;
   datetime weekStart = dayStart - dayOffset * 86400;
   double weeklyNet = NetPnlByPeriod(weekStart, TimeCurrent());
   MqlDateTime nowD;
   TimeToStruct(TimeCurrent(), nowD);
   string sess = SessionName(nowD);

   CreateLabel("T1", 10, 12, "🤖 SMC ICT PRO V2", clrAqua, 10, "Segoe UI");
   CreateLabel("T2", 10, 30, "🔧 Language: MQL5  |  API: MT5  |  Strict: ON", clrSlateGray, 8);
   CreateLabel("T3", 10, 46, "Status: " + status, (StringLen(status) == 0 ? clrLime : orange), 9);
   CreateLabel("T4", 10, 62, "EA Name (Comment): " + g_EAComment, clrLightGray, 8);
   CreateLabel("T5", 10, 78, icon + " Asset: " + assetName + "  |  Symbol: " + _Symbol + "  |  TF: " + tf, clrAqua, 8);
   CreateLabel("T6", 10, 94, "Magic: " + IntegerToString(InpMagic), clrLightGray, 8);
   CreateLabel("T7", 10, 110, "Balance: " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) +
              "  Equity: " + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2), clrWhite, 8);
   CreateLabel("T8", 10, 126, "P/L Daily: " + DoubleToString(dailyNet, 2) +
              "  Weekly: " + DoubleToString(weeklyNet, 2), dailyNet < 0 ? clrRed : clrLime, 8);
   CreateLabel("T9", 10, 142, "Drawdown: " + DoubleToString(g_CurDrawdownPct, 2) + "%", g_CurDrawdownPct > InpMaxEquityDrawdownPercent ? clrRed : clrLightGray, 8);
   CreateLabel("T10", 10, 158, "Trades Today: " + IntegerToString(CountTradesToday()) +
              "  Session: " + IntegerToString(CountTradesThisSession()) +
              "  Consec Loss: " + IntegerToString(g_ConsecutiveLosses), clrLightGray, 8);
   CreateLabel("T11", 10, 174, "Spread: " + DoubleToString(spread, 0) + " / " + IntegerToString(InpMaxSpreadPoints) + " pts",
              spread > InpMaxSpreadPoints ? clrRed : clrLightGray, 8);
   CreateLabel("T12", 10, 190, "Session: " + sess + "  |  NewsFilter: " +
              (InpEnableNewsFilter ? (IsNewsTime() ? "BLOCK" : "OK") : "OFF"), clrLightGray, 8);
   CreateLabel("T13", 10, 206, "Buy Signal: " + (IsBuySignal() ? "YES" : "NO") + "  " + g_LastReasonBuy, clrLime, 7);
   CreateLabel("T14", 10, 222, "Sell Signal: " + (IsSellSignal() ? "YES" : "NO") + "  " + g_LastReasonSell, clrRed, 7);
   CreateLabel("T15", 10, 238, "Open Risk: " + DoubleToString(TotalOpenRiskMoney(), 2) +
              " / " + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY) * InpMaxOpenRiskPercent / 100.0, 2), clrLightGray, 7);
  }

void ClearDashboard()
  {
   for(int i = 1; i <= 30; i++)
     {
      string objName = g_Prefix + "T" + IntegerToString(i);
      if(ObjectFind(0, objName) >= 0)
         ObjectDelete(0, objName);
     }
  }

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_EAComment = BuildEAComment();
   g_AssetType = DetectAssetType(_Symbol);
   g_AssetName = AssetTypeName(g_AssetType);

   if(InpMagic != 0)
      trade.SetExpertMagicNumber((ulong)InpMagic);
   else
      trade.SetExpertMagicNumber(702001UL);
   trade.SetDeviationInPoints((ulong)InpMaxDeviationPoints);

   g_InitBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_TodayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_PeakEquity = g_TodayStartEquity;
   g_MaxEquity = g_TodayStartEquity;

   // تحميل أخبار CSV عند اختيارها
   if(InpEnableNewsFilter && InpNewsDataMode == NEWS_CSV)
     {
      if(!LoadNewsCSV(InpNewsCSVFileName))
         Log(LOG_WARNING, "تعذر تحميل ملف الأخبار: " + InpNewsCSVFileName + " — FailSafe=" + (InpFailSafeMode ? "ON" : "OFF"));
     }

   if(!EnsureJournalCSV())
      Log(LOG_WARNING, "تعذر إنشاء ملف Journal CSV");

   if(InpShowDashboard)
      UpdateDashboard();

   Log(LOG_INFO, "OnInit OK | EA=" + g_EAComment + " | Magic=" + IntegerToString(InpMagic) +
       " | Symbol=" + _Symbol + " | TF=" + TFName(_Period) + " | Asset=" + g_AssetName);
   Log(LOG_INFO, "⚠️ الاختبار التاريخي/التحسين ليس ضماناً للأداء الحي. لا تنتقل لحساب حقيقي قبل Baseline + Stress + Forward + Demo.");
   g_InitOK = true;
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ClearDashboard();
   if(g_journalHandle != INVALID_HANDLE)
     {
      FileFlush(g_journalHandle);
      FileClose(g_journalHandle);
     }
   Log(LOG_INFO, "OnDeinit reason=" + IntegerToString(reason));
  }

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick()
  {
   // تحديث حالة التراجع
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq > g_MaxEquity) g_MaxEquity = eq;
   double ddown = g_MaxEquity > 0 ? (g_MaxEquity - eq) / g_MaxEquity * 100.0 : 0.0;
   g_CurDrawdownPct = ddown;
   if(ddown * g_MaxEquity / 100.0 > g_MaxDrawdownMoney) g_MaxDrawdownMoney = ddown * g_MaxEquity / 100.0;

   // تحديث الخسائر المتتالية
   g_ConsecutiveLosses = CountConsecutiveLosses();

   // إدارة المراكز
   ManageOpenPositions();

   // تحديث اللوحة كل 5 ثوانٍ تقريباً
   static int tickCount = 0;
   tickCount++;
   if(InpShowDashboard && (tickCount % 5 == 0))
      UpdateDashboard();

   if(g_InitOK && !InpEnableEA)
      return;

   // لا تتداول بدون tick صالح
   if(InpRequireValidTick)
     {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(ask <= 0 || bid <= 0) return;
     }

   // شمعة جديدة فقط
   ENUM_TIMEFRAMES tf = InpSignalTF == PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : InpSignalTF;
   if(!IsNewBar(tf))
      return;

   // منع تكرار الدخول في نفس الاتجاه
   if(InpMaxOpenPositionsPerSymbol > 0 && CountPositions(_Symbol, (long)InpMagic) >= InpMaxOpenPositionsPerSymbol)
      return;

   string block = StatusBlockReason();
   if(StringLen(block) > 0)
     {
      // لا تسجل نفس الرفض مراراً
      string key = "BLOCK_" + block;
      Log(LOG_DEBUG, "Blocked: " + block);
      return;
     }

   bool allowBuy = true;
   bool allowSell = true;
   if(!InpAllowHedge)
     {
      int buyCnt = CountPositionsBuy(_Symbol, (long)InpMagic);
      int sellCnt = CountPositionsSell(_Symbol, (long)InpMagic);
      if(buyCnt > 0) allowBuy = false;
      if(sellCnt > 0) allowSell = false;
     }

   if(allowBuy && IsBuySignal())
     {
      if(OpenBuy(g_LastReasonBuy))
         Log(LOG_INFO, "BUY Entry | " + g_LastReasonBuy + " | " + _Symbol + " | Magic=" + IntegerToString(InpMagic) + " | Comment=" + g_EAComment);
     }
   else if(allowSell && IsSellSignal())
     {
      if(OpenSell(g_LastReasonSell))
         Log(LOG_INFO, "SELL Entry | " + g_LastReasonSell + " | " + _Symbol + " | Magic=" + IntegerToString(InpMagic) + " | Comment=" + g_EAComment);
     }
  }

//+------------------------------------------------------------------+
//| OnTradeTransaction                                                |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   // تحديث الإحصائيات العامة
   g_ConsecutiveLosses = CountConsecutiveLosses();
   UpdateDashboard();

   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
     {
      if(!HistorySelect(0, TimeCurrent()))
         return;
      for(int i = 0; i < HistoryDealsTotal(); i++)
        {
         ulong deal = HistoryDealGetTicket(i);
         if(deal == 0 || deal != trans.deal)
            continue;
         long magic = HistoryDealGetInteger(deal, DEAL_MAGIC);
         long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
         if(magic == InpMagic && (entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT))
           {
            double pnl = HistoryDealGetDouble(deal, DEAL_PROFIT) +
                         HistoryDealGetDouble(deal, DEAL_SWAP) +
                         HistoryDealGetDouble(deal, DEAL_COMMISSION);
            Log(LOG_INFO, "Trade Closed | Deal=" + IntegerToString(deal) +
                " | P/L=" + DoubleToString(pnl, 2));
            Journal("Close", "SMC", "CLOSED", 0, 0, 0, 0, 0, 0,
                    "Closed deal P/L=" + DoubleToString(pnl, 2));
           }
         break;
        }
     }
   // عند تفعيل CloseOnDrawdownLimit
   if(InpCloseOnDrawdownLimit && g_CurDrawdownPct >= InpMaxEquityDrawdownPercent)
     {
      int total = PositionsTotal();
      for(int i = 0; i < total; i++)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0) continue;
         if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
         trade.PositionClose(ticket);
        }
      Log(LOG_WARNING, "DrawdownLimit تم إغلاق المراكز (يُحدد حصراً بواسطة Input)");
     }
  }

//+------------------------------------------------------------------+
//| OnChartEvent (احتياطي: لا نظام أزرار في هذه النسخة كما المطلوب)     |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   // باستثناء التحديث البصري البسيط: لا نضيف نظام أزرار يدوية في هذه النسخة،
   // لأن ذلك من "ملف التعديلات الثانوي" الذي طُلب عدم اعتماده حالياً.
  }

//+------------------------------------------------------------------+
