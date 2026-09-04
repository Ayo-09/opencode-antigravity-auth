//+------------------------------------------------------------------+
//|                                               SMC_ICT_Pro_V2.mq5 |
//|          AI-SMC/ICT Hybrid Institutional Trading System for MT5   |
//|                                                                  |
//|  مبني بدقة على "المرجع الشامل لاستراتيجية الهجينة المدعومة       |
//|  بالذكاء الاصطناعي — AI-SMC/ICT" (pasted_file_5qAMPS_complete_ai |
//|  _smc_strategy.pdf) وضمن إطار "البرومبت الشامل الاحترافي لبناء   |
//|  وتدقيق واختبار بوت تداول آلي على MT5".                          |
//|                                                                  |
//|  المعمارية المنفذة حرفياً من الملف:                             |
//|  1) التوجه اليومي (Daily Bias) على D1 — الإزاحة الشمعية          |
//|  2) قوة الثلاثة PO3 على 4H/30M: تراكم → تلاعب → توزيع            |
//|  3) تأكيد SMC على 1H: إغلاق الشمعة + CHoCH/MSS + منطقة Bullish   |
//|     FVG / Order Block                                            |
//|  4) محرك الدخول 1M: دخول قناص (Sniper Entry) عند تأكيد CISD      |
//|  5) SL أسفل السيولة الحقيقية داخل FVG — TP عند السيولة التالية   |
//|     بنسبة R:R 1:2 / 1:3 / 1:4 (أقصى)                            |
//|  6) مخاطرة 1–2% لكل صفقة + حد يومي 1–2% + فلتر Anti-Trap +       |
//|     تركيز على افتتاح جلسة لندن                                   |
//|                                                                  |
//|  الالتزامات: لا Martingale، لا Grid غير محدود، لا تحريك SL      |
//|  بعيداً عن السعر، وكل طلبات التداول عبر CTrade مع التحقق من      |
//|  retcode. Comment = اسم ملف البوت (≤31 حرفاً) لأن MT5 لا يحفظ    |
//|  اسم الملف في الصفقة؛ يحفظ فقط Magic وComment.                    |
//+------------------------------------------------------------------+
#property strict
#property copyright "AI-SMC/ICT Bot Toolkit"
#property link      "https://github.com/Ayo-09"
#property version   "3.00"
#property description "AI-SMC/ICT Hybrid Institutional Trading System — Daily Bias + PO3 + SMC Confirm + Sniper Entry (M1)"
#property description "يعمل على الكريبتو (USDT)، الفوركس، السلع، الأسهم، المؤشرات، وجميع الأطر الزمنية. لا يعد بالربح: الاختبار التاريخي ليس ضماناً للأداء الحي."

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

enum ENUM_BIAS
  {
   BIAS_UP   = 0,
   BIAS_DOWN = 1,
   BIAS_FLAT = 2
  };

//+------------------------------------------------------------------+
//| الإدخالات — 1. التعرف التلقائي والتشغيل                            |
//+------------------------------------------------------------------+
input group "=== 1. التعرف التلقائي والتشغيل ==="
input bool               InpEnableEA             = true;       // تفعيل البوت
input int                InpMagic                = 702001;     // Magic Number فريد
input bool               InpAutoDetectAssetType  = true;       // كشف تلقائي لنوع الأصل
input bool               InpOnlyTradeDetected    = false;      // التداول فقط عند التعرف على نوع الأصل

//+------------------------------------------------------------------+
//| الإدخالات — 2. إدارة المخاطر (البرومبت + الملف)                   |
//+------------------------------------------------------------------+
input group "=== 2. إدارة المخاطر ==="
input bool               InpEnableRiskBasedLot    = true;      // لوت مبني على المخاطرة
input double             InpRiskPerTradePercent   = 1.00;      // مخاطرة الصفقة % (1-2% كحد أقصى)
input double             InpMaxRiskPerTradeHardCap = 2.00;     // سقف صلب لمخاطرة الصفقة %
input bool               InpUseFixedLotForTesting = false;     // لوت ثابت (لاختبار فقط)
input double             InpFixedLot               = 0.01;      // اللوت الثابت
input double             InpMaxLot                 = 10.0;      // أقصى لوت للبوت
input double             InpMaxOpenRiskPercent     = 2.00;      // أقصى مخاطرة مفتوحة %
input int                InpMaxOpenPositionsPerSymbol = 1;      // أقصى مراكز لكل رمز
input bool               InpAllowHedge            = false;      // السماح بالهيدج
input double             InpDailyLossLimitPercent = 2.00;      // حد الخسارة اليومي %
input double             InpWeeklyLossLimitPercent = 4.00;     // حد الخسارة الأسبوعي %
input double             InpMaxEquityDrawdownPercent = 10.00;  // حد التراجع %
input int                InpMaxConsecutiveLosses  = 3;         // أقصى خسائر متتالية
input int                InpCooldownMinutes       = 60;        // التبريد بعد الخسائر المتتالية
input int                InpMaxTradesPerDay       = 5;         // أقصى صفقات يومياً
input int                InpMaxTradesPerSession   = 3;         // أقصى صفقات بالجلسة
input bool               InpCloseOnDrawdownLimit  = false;      // إغلاق المراكز عند حد التراجع

//+------------------------------------------------------------------+
//| الإدخالات — 3. فلاتر التنفيذ                                       |
//+------------------------------------------------------------------+
input group "=== 3. فلاتر التنفيذ ==="
input bool               InpEnableSpreadFilter     = true;     // فلتر السبريد
input int                InpMaxSpreadPoints        = 30;       // أقصى سبريد بالنقاط
input int                InpMaxDeviationPoints     = 20;       // أقصى انحراف بالتنفيذ
input bool               InpRequireValidTick        = true;    // اشتراط Tick صالح
input int                InpBlockBeforeWeekendMinutes = 120;    // منع جديد قبل نهاية الأسبوع

//+------------------------------------------------------------------+
//| الإدخالات — 4. جلسات التداول + افتتاح لندن                        |
//+------------------------------------------------------------------+
input group "=== 4. الجلسات وافتتاح لندن ==="
input bool               InpEnableSessionFilter    = true;     // تفعيل فلتر الجلسات
input bool               InpEnableLondonSession    = true;     // جلسة لندن
input int                InpLondonStartHour         = 8;       // بداية لندن (ساعة السيرفر)
input int                InpLondonEndHour           = 17;      // نهاية لندن
input bool               InpEnableNewYorkSession   = true;     // جلسة نيويورك
input int                InpNewYorkStartHour       = 13;      // بداية نيويورك
input int                InpNewYorkEndHour         = 22;      // نهاية نيويورك
input bool               InpAllowOverlapSessions   = true;     // السماح بالتداخل
input bool               InpFocusOnLondonOpening   = true;     // التركيز على افتتاح جلسة لندن
input int                InpLondonOpenStartHour    = 7;       // بداية نافذة افتتاح لندن
input int                InpLondonOpenEndHour      = 11;      // نهاية نافذة افتتاح لندن

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
input double             InpBreakEvenTriggerPoints= 20;       // تفعيل Break-even عند نقاط الربح
input double             InpBreakEvenLockPoints   = 2;        // تثبيت ربح بعد النقل
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
input int                InpDashboardCorner       = 1;         // ركن اللوحة (1..4)

//+------------------------------------------------------------------+
//| الإدخالات — 8. إطار AI-SMC/ICT (حسب الملف المرجعي)                |
//+------------------------------------------------------------------+
input group "=== 8. AI-SMC/ICT: الأطر الزمنية ==="
input ENUM_TIMEFRAMES    InpDailyBiasTF   = PERIOD_D1;   // إطار التوجه اليومي (Daily Bias)
input ENUM_TIMEFRAMES    InpPO3StructureTF= PERIOD_H4;   // إطار هيكل قوة الثلاثة (PO3)
input ENUM_TIMEFRAMES    InpPO3AccumTF    = PERIOD_M30;  // إطار مراقبة التراكم/التلاعب (PO3)
input ENUM_TIMEFRAMES    InpSMCConfirmTF  = PERIOD_H1;   // إطار تأكيد SMC
input ENUM_TIMEFRAMES    InpEntryTF       = PERIOD_M1;   // إطار الدخول القناص (Sniper Entry)

input group "=== 9. AI-SMC/ICT: شروط الإشارة ==="
input int                InpPO3AccumBars           = 12;      // عدد شموع نطاق التراكم
input double             InpPO3RangeATRFactor      = 1.6;     // أقصى اتساع نطاق التراكم (مضاعف المدى)
input int                InpSwingLookback          = 3;       // عدد الشموع حول القمم/القيعان (CHoCH/MSS)
input int                InpSwingScanBars          = 45;      // مسح بنية H1
input double             InpEqualTolerancePercent  = 0.05;    // تسامح السيولة المتساوية %
input int                InpTargetRR               = 2;       // نسبة العائد المستهدفة (2=1:2, 3=1:3, 4=1:4)
input bool               InpRequireBullishFVG      = true;    // اشتراط Bullish/Bearish FVG على H1

//+------------------------------------------------------------------+
//| متغيرات عامة                                                       |
//+------------------------------------------------------------------+
CTrade   trade;
string   g_EAComment = "";
string   g_Prefix    = "SMCPRO_";
bool     g_InitOK    = false;

ENUM_ASSET_TYPE g_AssetType = ASSET_OTHER;
string          g_AssetName = "";

double g_PeakEquity=0.0, g_MaxEquity=0.0, g_CurDrawdownPct=0.0, g_MaxDrawdownMoney=0.0;
bool   g_PausedManual=false;
int    g_ConsecutiveLosses=0;
datetime g_LastBlockTime=0;
int    g_LastBarTime=0;
int    g_journalHandle=INVALID_HANDLE;

//--- مصفوفات الأطر الزمنية (series, index 0 = الجاري)
double   d1_h[], d1_l[], d1_c[], d1_o[];
datetime d1_t[];
double   h4_h[], h4_l[], h4_c[], h4_o[];
datetime h4_t[];
double   m30_h[], m30_l[], m30_c[], m30_o[];
datetime m30_t[];
double   h1_h[], h1_l[], h1_c[], h1_o[];
datetime h1_t[];
double   m1_h[], m1_l[], m1_c[], m1_o[];
datetime m1_t[];

//--- نتائج التحليل (تُحسب كل شمعة إدخال جديدة)
bool     g_BuySignalState=false, g_SellSignalState=false;
string   g_LastReasonBuy="", g_LastReasonSell="";
double   g_buySweepLow=0, g_sellSweepHigh=0;
double   g_buyNextLiq=0, g_sellNextLiq=0;
double   g_fvgLow=0, g_fvgHigh=0;

//--- أخبار
struct NewsRow { datetime time; string currency; int impact; string event; };
NewsRow g_newsRows[];
int     g_newsCount=0;

//+------------------------------------------------------------------+
//| تعليق الصفقة: اسم الملف نفسه (≤31 حرفاً)                          |
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
      name = "AI-SMC-ICT-Pro";
   return(name);
  }

//+------------------------------------------------------------------+
//| اسم الإطار الزمني                                                  |
//+------------------------------------------------------------------+
string TFName(int p)
  {
   switch(p)
     {
      case PERIOD_M1:  return("M1");  case PERIOD_M2:  return("M2");
      case PERIOD_M3:  return("M3");  case PERIOD_M4:  return("M4");
      case PERIOD_M5:  return("M5");  case PERIOD_M6:  return("M6");
      case PERIOD_M10: return("M10"); case PERIOD_M12: return("M12");
      case PERIOD_M15: return("M15"); case PERIOD_M20: return("M20");
      case PERIOD_M30: return("M30"); case PERIOD_H1:  return("H1");
      case PERIOD_H2:  return("H2");  case PERIOD_H3:  return("H3");
      case PERIOD_H4:  return("H4");  case PERIOD_H6:  return("H6");
      case PERIOD_H8:  return("H8");  case PERIOD_H12: return("H12");
      case PERIOD_D1:  return("D1");  case PERIOD_W1:  return("W1");
      case PERIOD_MN1: return("MN1");
      default:         return("T"+IntegerToString(PeriodSeconds(p)));
     }
  }

//+------------------------------------------------------------------+
//| كشف نوع الأصل                                                     |
//+------------------------------------------------------------------+
bool IsStablecoin(string s)
  {
   string up=s; StringToUpper(up);
   if(StringFind(up,"USDT")>=0) return(true);
   if(StringFind(up,"USDC")>=0) return(true);
   if(StringFind(up,"BUSD")>=0) return(true);
   if(StringFind(up,"TUSD")>=0) return(true);
   if(StringFind(up,"DAI")>=0)  return(true);
   return(false);
  }

bool IsCryptoBase(string s)
  {
   string up=s; StringToUpper(up);
   string bases[]={"BTC","ETH","XRP","BNB","SOL","ADA","DOGE","LTC","BCH","DOT","LINK","AVAX","NEAR","MATIC","TRX","XLM","ATOM","UNI","SHIB","PEPE","TON","APT","ARB","OP","SUI","SEI","FIL","ETC","HBAR","VET","RUNE","QNT","EGLD","XTZ","FLOW","ALGO","IMX","GALA","AAVE","MKR","CRV","LDO","TIA","INJ","STX","KAVA","ZIL","MANA","SAND","AXS","EOS","IOTA","DASH","ZEC","XMR","NEO","KSM","WAVES"};
   for(int i=0;i<ArraySize(bases);i++)
      if(StringFind(up,bases[i])==0) return(true);
   return(false);
  }

bool IsFxSymbol(string s)
  {
   string up=s; StringToUpper(up);
   if(StringLen(up)!=6) return(false);
   string majors[]={"EUR","GBP","USD","JPY","CHF","AUD","NZD","CAD"};
   int found=0;
   for(int i=0;i<8;i++) if(StringFind(up,majors[i])>=0) found++;
   return(found>=2);
  }

bool IsMetals(string s)
  {
   string up=s; StringToUpper(up);
   if(StringFind(up,"XAU")>=0) return(true);
   if(StringFind(up,"XAG")>=0) return(true);
   if(StringFind(up,"XPT")>=0) return(true);
   if(StringFind(up,"XPD")>=0) return(true);
   if(StringFind(up,"XCU")>=0) return(true);
   return(false);
  }

bool IsEnergyCommodity(string s)
  {
   string up=s; StringToUpper(up);
   if(StringFind(up,"OIL")>=0) return(true);
   if(StringFind(up,"WTI")>=0) return(true);
   if(StringFind(up,"BRENT")>=0) return(true);
   if(StringFind(up,"UKOIL")>=0) return(true);
   if(StringFind(up,"NGAS")>=0) return(true);
   if(StringFind(up,"NATGAS")>=0) return(true);
   return(false);
  }

bool IsIndexSymbol(string s)
  {
   string up=s; StringToUpper(up);
   if(StringFind(up,"US30")>=0)  return(true);
   if(StringFind(up,"US500")>=0) return(true);
   if(StringFind(up,"NAS")>=0)   return(true);
   if(StringFind(up,"SPX")>=0)   return(true);
   if(StringFind(up,"DJI")>=0)   return(true);
   if(StringFind(up,"DAX")>=0)   return(true);
   if(StringFind(up,"GER")>=0)   return(true);
   if(StringFind(up,"DE30")>=0)  return(true);
   if(StringFind(up,"CAC")>=0)   return(true);
   if(StringFind(up,"F40")>=0)   return(true);
   if(StringFind(up,"FTSE")>=0)  return(true);
   if(StringFind(up,"UK100")>=0) return(true);
   if(StringFind(up,"SMI")>=0)   return(true);
   if(StringFind(up,"NIKKEI")>=0)return(true);
   if(StringFind(up,"JPN")>=0)   return(true);
   if(StringFind(up,"AXI")>=0)   return(true);
   if(StringFind(up,"HK50")>=0)  return(true);
   if(StringFind(up,"HKG")>=0)   return(true);
   if(StringFind(up,"VIX")>=0)   return(true);
   return(false);
  }

ENUM_ASSET_TYPE DetectAssetType(string symbol)
  {
   string s=symbol; StringTrimLeft(s); StringTrimRight(s);
   if(IsStablecoin(s) || IsCryptoBase(s)) return(ASSET_CRYPTO);
   if(IsFxSymbol(s)) return(ASSET_FOREX);
   if(IsMetals(s) || IsEnergyCommodity(s)) return(ASSET_COMMODITY);
   if(IsIndexSymbol(s)) return(ASSET_INDEX);
   string up=s; StringToUpper(up);
   if(StringFind(up,".US")>=0 || StringFind(up,".DE")>=0 || StringFind(up,".FR")>=0 ||
      StringFind(up,".UK")>=0 || StringFind(up,".JP")>=0 || StringFind(up,".HK")>=0)
      return(ASSET_STOCK);
   if(StringFind(s,".")>=0) return(ASSET_STOCK);
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
//| أدوات عامة                                                        |
//+------------------------------------------------------------------+
double CurrentSpreadPoints()
  {
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   if(ask<=0||bid<=0||point<=0) return(0.0);
   return(MathAbs(ask-bid)/point);
  }

bool IsSymbolTradable()
  {
   long mode=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE);
   if(mode==SYMBOL_TRADE_MODE_DISABLED) return(false);
   if(mode==SYMBOL_TRADE_MODE_FULL) return(true);
   return(false);
  }

bool LoadRates(ENUM_TIMEFRAMES tf,int bars,double &h[],double &l[],double &c[],double &o[],datetime &t[])
  {
   MqlRates r[];
   ArraySetAsSeries(r,true);
   int got=CopyRates(_Symbol,tf,0,bars,r);
   if(got<MathMin(bars,10)) return(false);
   ArrayResize(h,got); ArrayResize(l,got); ArrayResize(c,got); ArrayResize(o,got); ArrayResize(t,got);
   for(int i=0;i<got;i++)
     { h[i]=r[i].high; l[i]=r[i].low; c[i]=r[i].close; o[i]=r[i].open; t[i]=r[i].time; }
   return(true);
  }

bool LoadAllTimeframes()
  {
   bool ok=true;
   if(!LoadRates(InpDailyBiasTF,5,d1_h,d1_l,d1_c,d1_o,d1_t)) ok=false;
   if(!LoadRates(InpPO3StructureTF,80,h4_h,h4_l,h4_c,h4_o,h4_t)) ok=false;
   if(!LoadRates(InpPO3AccumTF,90,m30_h,m30_l,m30_c,m30_o,m30_t)) ok=false;
   if(!LoadRates(InpSMCConfirmTF,110,h1_h,h1_l,h1_c,h1_o,h1_t)) ok=false;
   if(!LoadRates(InpEntryTF,60,m1_h,m1_l,m1_c,m1_o,m1_t)) ok=false;
   return(ok);
  }

bool IsNewBar(ENUM_TIMEFRAMES tf)
  {
   datetime t=iTime(_Symbol,tf,0);
   if(t==0) return(false);
   if(t==g_LastBarTime) return(false);
   g_LastBarTime=(int)t;
   return(true);
  }

//+------------------------------------------------------------------+
//| 1) التوجه اليومي (Daily Bias) — الإزاحة الشمعية                   |
//+------------------------------------------------------------------+
ENUM_BIAS GetDailyBias()
  {
   if(ArraySize(d1_t)<4) return(BIAS_FLAT);
   // الشمعة المكتملة (index 1) + الشمعة السابقة (index 2)
   double c1=d1_c[1], o1=d1_o[1];
   double h2=d1_h[2], l2=d1_l[2];
   // إزاحة صاعدة: إغلاق فوق الافتتاح وفوق قمة اليوم السابق
   if(c1>o1 && c1>h2) return(BIAS_UP);
   // إزاحة هابطة: إغلاق تحت الافتتاح وتحت قاع اليوم السابق
   if(c1<o1 && c1<l2) return(BIAS_DOWN);
   return(BIAS_FLAT);
  }

//+------------------------------------------------------------------+
//| 2) قوة الثلاثة PO3: تراكم ثم تلاعب (Manipulation) ثم عودة         |
//+------------------------------------------------------------------+
bool DetectPO3Buy(double &sweptLow)
  {
   if(ArraySize(m30_h)<30) return(false);
   int N=InpPO3AccumBars;
   if(N<3) N=3;
   // نطاق التراكم: من index (1+N) حتى (2) — قبل شمعة التلاعب
   double rngHigh=-1e18, rngLow=1e18;
   for(int i=1+N;i<=2+N;i++)
     {
      if(i>=ArraySize(m30_h)) break;
      if(m30_h[i]>rngHigh) rngHigh=m30_h[i];
      if(m30_l[i]<rngLow)  rngLow=m30_l[i];
     }
   if(rngHigh<=rngLow) return(false);

   // متوسط مدى الشموع الأخيرة (استبدال ATR)
   double avgRange=0; int avgCount=0;
   for(int i=1;i<10 && i<ArraySize(m30_h);i++){ avgRange+=(m30_h[i]-m30_l[i]); avgCount++; }
   if(avgCount>0) avgRange/=avgCount;
   if(avgRange<=0) return(false);

   // التراكم يجب أن يكون نطاقاً ضيقاً نسبياً
   double rangeSize=rngHigh-rngLow;
   if(rangeSize > avgRange*InpPO3RangeATRFactor) return(false);

   // شمعة التلاعب (index 1): فتيل تحت القاع ثم إغلاق أعلى القاع
   double low1=m30_l[1], close1=m30_c[1], open1=m30_o[1];
   double buffer=rangeSize*0.02;
   if(low1 < rngLow+0 && low1 <= rngLow-buffer)
     {
      if(close1 > rngLow && close1 >= open1)
        {
         sweptLow=MathMin(low1,rngLow);
         return(true);
        }
     }
   return(false);
  }

bool DetectPO3Sell(double &sweptHigh)
  {
   if(ArraySize(m30_h)<30) return(false);
   int N=InpPO3AccumBars;
   if(N<3) N=3;
   double rngHigh=-1e18, rngLow=1e18;
   for(int i=1+N;i<=2+N;i++)
     {
      if(i>=ArraySize(m30_h)) break;
      if(m30_h[i]>rngHigh) rngHigh=m30_h[i];
      if(m30_l[i]<rngLow)  rngLow=m30_l[i];
     }
   if(rngHigh<=rngLow) return(false);

   double avgRange=0; int avgCount=0;
   for(int i=1;i<10 && i<ArraySize(m30_h);i++){ avgRange+=(m30_h[i]-m30_l[i]); avgCount++; }
   if(avgCount>0) avgRange/=avgCount;
   if(avgRange<=0) return(false);
   double rangeSize=rngHigh-rngLow;
   if(rangeSize > avgRange*InpPO3RangeATRFactor) return(false);

   double high1=m30_h[1], close1=m30_c[1], open1=m30_o[1];
   double buffer=rangeSize*0.02;
   if(high1 > rngHigh+buffer)
     {
      if(close1 < rngHigh && close1 <= open1)
        {
         sweptHigh=MathMax(high1,rngHigh);
         return(true);
        }
     }
   return(false);
  }

//+------------------------------------------------------------------+
//| 3) تأكيد SMC على H1: CHoCH/MSS + FVG                              |
//+------------------------------------------------------------------+
bool DetectSMCConfirmBuy()
  {
   if(ArraySize(h1_h)<30) return(false);
   int look=InpSwingLookback;
   int scanStart=3;
   int scanEnd=MathMin(ArraySize(h1_h)-2,InpSwingScanBars);
   double swingLow=1e18; int swingLowIdx=-1;
   for(int i=scanStart;i<scanEnd;i++)
     {
      bool isLow=true;
      for(int k=1;k<=look;k++)
        {
         if(i-k<0 || i+k>=ArraySize(h1_l)){isLow=false;break;}
         if(h1_l[i]>=h1_l[i-k]){isLow=false;break;}
         if(h1_l[i]>=h1_l[i+k]){isLow=false;break;}
        }
      if(isLow && h1_l[i]<swingLow){swingLow=h1_l[i]; swingLowIdx=i;}
     }
   if(swingLowIdx<=0) return(false);

   double recentHigh=-1e18;
   for(int i=1;i<swingLowIdx;i++)
      if(h1_h[i]>recentHigh) recentHigh=h1_h[i];
   if(recentHigh<=swingLow) return(false);

   // آخر شمعة مكتملة على H1
   double close1=h1_c[1];
   // CHoCH/MSS: إغلاق فوق آخر قمة بعد الانخفاض
   if(close1>recentHigh) return(true);
   return(false);
  }

bool DetectSMCConfirmSell()
  {
   if(ArraySize(h1_h)<30) return(false);
   int look=InpSwingLookback;
   int scanStart=3;
   int scanEnd=MathMin(ArraySize(h1_h)-2,InpSwingScanBars);
   double swingHigh=-1e18; int swingHighIdx=-1;
   for(int i=scanStart;i<scanEnd;i++)
     {
      bool isHigh=true;
      for(int k=1;k<=look;k++)
        {
         if(i-k<0 || i+k>=ArraySize(h1_h)){isHigh=false;break;}
         if(h1_h[i]<=h1_h[i-k]){isHigh=false;break;}
         if(h1_h[i]<=h1_h[i+k]){isHigh=false;break;}
        }
      if(isHigh && h1_h[i]>swingHigh){swingHigh=h1_h[i]; swingHighIdx=i;}
     }
   if(swingHighIdx<=0) return(false);

   double recentLow=1e18;
   for(int i=1;i<swingHighIdx;i++)
      if(h1_l[i]<recentLow) recentLow=h1_l[i];
   if(recentLow>=swingHigh) return(false);

   double close1=h1_c[1];
   if(close1<recentLow) return(true);
   return(false);
  }

bool FindBullishFVG(double &lo,double &hi)
  {
   if(ArraySize(h1_h)<20) return(false);
   for(int i=2;i<40 && i+2<ArraySize(h1_h);i++)
     {
      if(h1_l[i+2] > h1_h[i])
        {
         lo=h1_h[i];
         hi=h1_l[i+2];
         return(true);
        }
     }
   return(false);
  }

bool FindBearishFVG(double &lo,double &hi)
  {
   if(ArraySize(h1_h)<20) return(false);
   for(int i=2;i<40 && i+2<ArraySize(h1_h);i++)
     {
      if(h1_h[i+2] < h1_l[i])
        {
         lo=h1_h[i+2];
         hi=h1_l[i];
         return(true);
        }
     }
   return(false);
  }

//+------------------------------------------------------------------+
//| 4) محرك الدخول 1M: تأكيد CISD (MSS قصير على M1)                   |
//+------------------------------------------------------------------+
bool DetectCISDBuy()
  {
   if(ArraySize(m1_h)<20) return(false);
   double recentHigh=-1e18;
   for(int i=2;i<15 && i<ArraySize(m1_h);i++)
      if(m1_h[i]>recentHigh) recentHigh=m1_h[i];
   if(recentHigh<=-1e17) return(false);
   double close1=m1_c[1];
   return(close1>recentHigh);
  }

bool DetectCISDSell()
  {
   if(ArraySize(m1_h)<20) return(false);
   double recentLow=1e18;
   for(int i=2;i<15 && i<ArraySize(m1_h);i++)
      if(m1_l[i]<recentLow) recentLow=m1_l[i];
   if(recentLow>=1e17) return(false);
   double close1=m1_c[1];
   return(close1<recentLow);
  }

//+------------------------------------------------------------------+
//| السيولة التالية (الهدف)                                           |
//+------------------------------------------------------------------+
double FindNextLiquidityUp(double price)
  {
   double best=0;
   for(int i=1;i<ArraySize(h1_h) && i<80;i++)
      if(h1_h[i]>price && (best==0 || h1_h[i]<best)) best=h1_h[i];
   for(int i=1;i<ArraySize(h4_h) && i<60;i++)
      if(h4_h[i]>price && (best==0 || h4_h[i]<best)) best=h4_h[i];
   return(best);
  }

double FindNextLiquidityDown(double price)
  {
   double best=0;
   for(int i=1;i<ArraySize(h1_l) && i<80;i++)
      if(h1_l[i]<price && (best==0 || h1_l[i]>best)) best=h1_l[i];
   for(int i=1;i<ArraySize(h4_l) && i<60;i++)
      if(h4_l[i]<price && (best==0 || h4_l[i]>best)) best=h4_l[i];
   return(best);
  }

bool PriceInFVG(double price,double lo,double hi)
  {
   if(lo<=0||hi<=0||hi<=lo) return(false);
   return(price>=lo && price<=hi);
  }

//+------------------------------------------------------------------+
//| 5) إشارات الدخول النهائية (مطابقة للملف مع فلتر Anti-Trap)        |
//+------------------------------------------------------------------+
bool IsBuySignal()
  {
   if(!LoadAllTimeframes()){ g_LastReasonBuy="DataError"; return(false); }

   // 1) التوجه اليومي
   ENUM_BIAS bias=GetDailyBias();
   if(bias!=BIAS_UP){ g_LastReasonBuy=(bias==BIAS_FLAT?"DailyBiasFlat":"DailyBiasDown"); return(false); }

   // 2) قوة الثلاثة PO3: تراكم + تلاعب (كنس قيعان)
   double sweptLow=0;
   if(!DetectPO3Buy(sweptLow)){ g_LastReasonBuy="NoPO3-Manipulation"; return(false); }

   // 3) تأكيد SMC على H1: CHoCH/MSS
   if(!DetectSMCConfirmBuy()){ g_LastReasonBuy="NoH1_CHoCH_MSS"; return(false); }

   // 4) FVG صاعدة على H1 (منطقة الدخول)
   double fvgLo=0, fvgHi=0;
   if(InpRequireBullishFVG)
     {
      if(!FindBullishFVG(fvgLo,fvgHi)){ g_LastReasonBuy="NoBullishFVG"; return(false); }
     }
   else
     {
      FindBullishFVG(fvgLo,fvgHi);
     }

   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(ask<=0||bid<=0){ g_LastReasonBuy="InvalidPrice"; return(false); }

   // السعر داخل منطقة FVG (منطقة الخصم/الشراء)
   if(fvgHi>0 && !PriceInFVG(ask,fvgLo,fvgHi)){ g_LastReasonBuy="NotInFVG"; return(false); }

   // 5) محرك الدخول: تأكيد CISD على M1
   if(!DetectCISDBuy()){ g_LastReasonBuy="NoM1_CISD"; return(false); }

   // فلتر Anti-Trap: يجب أن يكون التلاعب قد مسح سيولة حقيقية (قاع سابق)
   bool antiTrap = (sweptLow>0 && sweptLow<ask);
   if(!antiTrap){ g_LastReasonBuy="AntiTrapFail"; return(false); }

   g_buySweepLow=sweptLow;
   g_fvgLow=fvgLo; g_fvgHigh=fvgHi;
   g_buyNextLiq=FindNextLiquidityUp(ask);
   g_LastReasonBuy="AI-SMC/ICT OK: DailyBias+PO3+SMC Confirm(FVG)+CISD";
   return(true);
  }

bool IsSellSignal()
  {
   if(!LoadAllTimeframes()){ g_LastReasonSell="DataError"; return(false); }

   ENUM_BIAS bias=GetDailyBias();
   if(bias!=BIAS_DOWN){ g_LastReasonSell=(bias==BIAS_FLAT?"DailyBiasFlat":"DailyBiasUp"); return(false); }

   double sweptHigh=0;
   if(!DetectPO3Sell(sweptHigh)){ g_LastReasonSell="NoPO3-Manipulation"; return(false); }

   if(!DetectSMCConfirmSell()){ g_LastReasonSell="NoH1_CHoCH_MSS"; return(false); }

   double fvgLo=0, fvgHi=0;
   if(InpRequireBullishFVG)
     {
      if(!FindBearishFVG(fvgLo,fvgHi)){ g_LastReasonSell="NoBearishFVG"; return(false); }
     }
   else
     {
      FindBearishFVG(fvgLo,fvgHi);
     }

   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(ask<=0||bid<=0){ g_LastReasonSell="InvalidPrice"; return(false); }

   if(fvgHi>0 && !PriceInFVG(bid,fvgLo,fvgHi)){ g_LastReasonSell="NotInFVG"; return(false); }

   if(!DetectCISDSell()){ g_LastReasonSell="NoM1_CISD"; return(false); }

   bool antiTrap = (sweptHigh>0 && sweptHigh>bid);
   if(!antiTrap){ g_LastReasonSell="AntiTrapFail"; return(false); }

   g_sellSweepHigh=sweptHigh;
   g_fvgLow=fvgLo; g_fvgHigh=fvgHi;
   g_sellNextLiq=FindNextLiquidityDown(bid);
   g_LastReasonSell="AI-SMC/ICT OK: DailyBias+PO3+SMC Confirm(FVG)+CISD";
   return(true);
  }

//+------------------------------------------------------------------+
//| حساب SL/TP (SL أسفل السيولة داخل FVG · TP عند السيولة أو نطاق RR) |
//+------------------------------------------------------------------+
void GetBuySLTP(double ask,double &sl,double &tp)
  {
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   sl=(g_buySweepLow>0)?(g_buySweepLow-2*point):(ask-20*point);
   if(g_fvgLow>0 && g_fvgLow-2*point<sl) sl=g_fvgLow-2*point;
   double risk=MathMax(ask-sl, 5*point);
   double rrCap=ask+risk*MathMin(InpTargetRR,4);
   if(g_buyNextLiq>0 && g_buyNextLiq>ask && g_buyNextLiq<=rrCap)
      tp=g_buyNextLiq;
   else
      tp=rrCap;
  }

void GetSellSLTP(double bid,double &sl,double &tp)
  {
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   sl=(g_sellSweepHigh>0)?(g_sellSweepHigh+2*point):(bid+20*point);
   if(g_fvgHigh>0 && g_fvgHigh+2*point>sl) sl=g_fvgHigh+2*point;
   double risk=MathMax(sl-bid, 5*point);
   double rrCap=bid-risk*MathMin(InpTargetRR,4);
   if(g_sellNextLiq>0 && g_sellNextLiq<bid && g_sellNextLiq>=rrCap)
      tp=g_sellNextLiq;
   else
      tp=rrCap;
  }

//+------------------------------------------------------------------+
//| حساب اللوت                                                        |
//+------------------------------------------------------------------+
double NormalizeVolume(double rawVolume,const string symbol)
  {
   double min=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   double max=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
   if(step<=0) step=0.01;
   double v=MathFloor(rawVolume/step)*step;
   if(v<min) v=min;
   if(v>max) v=max;
   return(NormalizeDouble(v,2));
  }

double CalculateLot(string symbol,double slPrice)
  {
   if(InpUseFixedLotForTesting)
      return(NormalizeVolume(InpFixedLot,symbol));

   double riskPct=InpRiskPerTradePercent;
   if(riskPct>InpMaxRiskPerTradeHardCap)
      riskPct=InpMaxRiskPerTradeHardCap;
   double riskMoney=AccountInfoDouble(ACCOUNT_EQUITY)*riskPct/100.0;
   if(riskMoney<=0) return(0.0);

   double ask=SymbolInfoDouble(symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(symbol,SYMBOL_BID);
   double open=(ask>0?ask:bid);
   if(open<=0||slPrice<=0||MathAbs(open-slPrice)<_Point) return(0.0);

   double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   double tickVal=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE);
   double tickSize=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
   if(point<=0||tickVal<=0||tickSize<=0) return(0.0);

   double riskPips=MathAbs(open-slPrice)/point;
   double riskPerLot=tickVal*riskPips*point/tickSize;
   if(riskPerLot<=0) return(0.0);

   double vol=NormalizeVolume(riskMoney/riskPerLot,symbol);
   double min=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   double max=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
   if(vol<min||vol>max) return(0.0);
   if(vol>InpMaxLot) vol=InpMaxLot;

   double actualRisk=vol*riskPerLot;
   if(actualRisk>riskMoney*1.05) return(0.0);
   return(vol);
  }

//+------------------------------------------------------------------+
//| عدّ المراكز                                                       |
//+------------------------------------------------------------------+
int CountPositions(string symbol,long magic)
  {
   int cnt=0;
   int total=PositionsTotal();
   for(int i=0;i<total;i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0) continue;
      if(PositionGetString(POSITION_SYMBOL)==symbol && PositionGetInteger(POSITION_MAGIC)==magic)
         cnt++;
     }
   return(cnt);
  }

int CountPositionsByType(string symbol,long magic,long type)
  {
   int cnt=0;
   int total=PositionsTotal();
   for(int i=0;i<total;i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0) continue;
      if(PositionGetString(POSITION_SYMBOL)==symbol &&
         PositionGetInteger(POSITION_MAGIC)==magic &&
         PositionGetInteger(POSITION_TYPE)==type)
         cnt++;
     }
   return(cnt);
  }

double TotalOpenRiskMoney()
  {
   double riskMoney=0.0;
   int total=PositionsTotal();
   for(int i=0;i<total;i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagic) continue;
      double vol=PositionGetDouble(POSITION_VOLUME);
      double open=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      if(vol<=0||sl<=0) continue;
      long type=PositionGetInteger(POSITION_TYPE);
      string sym=PositionGetString(POSITION_SYMBOL);
      double point=SymbolInfoDouble(sym,SYMBOL_POINT);
      double tickVal=SymbolInfoDouble(sym,SYMBOL_TRADE_TICK_VALUE);
      double tickSize=SymbolInfoDouble(sym,SYMBOL_TRADE_TICK_SIZE);
      if(point<=0||tickVal<=0||tickSize<=0) continue;
      double riskPips=(type==POSITION_TYPE_BUY?MathAbs(open-sl):MathAbs(sl-open))/point;
      double riskPerLot=tickVal*riskPips*point/tickSize;
      riskMoney+=vol*riskPerLot;
     }
   return(riskMoney);
  }

//+------------------------------------------------------------------+
//| الفلاتر: يوم/أسبوع/جلسة/أخبار/افتتاح لندن                          |
//+------------------------------------------------------------------+
bool IsWeekendBlocked()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   if(dt.day_of_week==5)
     {
      int minutesTo=(23*60+59)-(dt.hour*60+dt.min);
      if(minutesTo<=InpBlockBeforeWeekendMinutes) return(true);
     }
   if(dt.day_of_week==6 || dt.day_of_week==0) return(true);
   return(false);
  }

bool IsInLondonSession(MqlDateTime dt)
  {
   if(!InpEnableLondonSession) return(false);
   int h=dt.hour;
   if(InpLondonStartHour<=InpLondonEndHour) return(h>=InpLondonStartHour && h<InpLondonEndHour);
   return(h>=InpLondonStartHour || h<InpLondonEndHour);
  }

bool IsInNewYorkSession(MqlDateTime dt)
  {
   if(!InpEnableNewYorkSession) return(false);
   int h=dt.hour;
   if(InpNewYorkStartHour<=InpNewYorkEndHour) return(h>=InpNewYorkStartHour && h<InpNewYorkEndHour);
   return(h>=InpNewYorkStartHour || h<InpNewYorkEndHour);
  }

bool IsInLondonOpening()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   int h=dt.hour;
   if(InpLondonOpenStartHour<=InpLondonOpenEndHour) return(h>=InpLondonOpenStartHour && h<InpLondonOpenEndHour);
   return(h>=InpLondonOpenStartHour || h<InpLondonOpenEndHour);
  }

string SessionName(MqlDateTime dt)
  {
   bool l=IsInLondonSession(dt);
   bool n=IsInNewYorkSession(dt);
   if(l&&n) return("LONDON+NY");
   if(l) return("LONDON");
   if(n) return("NEWYORK");
   return("OFF-SESSION");
  }

bool IsSessionAllowed()
  {
   if(!InpEnableSessionFilter) return(true);
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   bool l=IsInLondonSession(dt);
   bool n=IsInNewYorkSession(dt);
   if(l&&n) return(InpAllowOverlapSessions);
   return(l||n);
  }

//--- أخبار CSV
long ParseDateTimeFromString(string ds)
  {
   string dtStr=ds; StringTrimLeft(dtStr); StringTrimRight(dtStr);
   long first=(long)StringToInteger(dtStr);
   if(first>0) return(first);
   MqlDateTime m; m.year=1970; m.mon=1; m.day=1; m.hour=0; m.min=0; m.sec=0;
   int p1=StringFind(dtStr,"-");
   if(p1<0) p1=StringFind(dtStr,".");
   if(p1<0) p1=StringFind(dtStr,"/");
   if(p1<0) p1=StringFind(dtStr," ");
   if(p1>0)
     {
      m.year=(int)StringToInteger(StringSubstr(dtStr,0,p1));
      string rest=StringSubstr(dtStr,p1+1);
      int p2=StringFind(rest,"-"); if(p2<0) p2=StringFind(rest,"."); if(p2<0) p2=StringFind(rest,"/");
      if(p2<0) p2=StringFind(rest," ");
      if(p2>0)
        {
         m.mon=(int)StringToInteger(StringSubstr(rest,0,p2));
         string rest2=StringSubstr(rest,p2+1);
         int p3=StringFind(rest2," "); if(p3<0) p3=StringFind(rest2,"T");
         if(p3>0)
           {
            m.day=(int)StringToInteger(StringSubstr(rest2,0,p3));
            string rest3=StringSubstr(rest2,p3+1);
            int p4=StringFind(rest3,":");
            if(p4>0)
              {
               m.hour=(int)StringToInteger(StringSubstr(rest3,0,p4));
               m.min=(int)StringToInteger(StringSubstr(rest3,p4+1,2));
              }
           }
        }
     }
   return((long)StructToTime(m));
  }

bool LoadNewsCSV(string fileName)
  {
   int handle=FileOpen(fileName,FILE_READ|FILE_CSV|FILE_ANSI,',',CP_UTF8);
   if(handle==INVALID_HANDLE) return(false);
   ArrayResize(g_newsRows,0); g_newsCount=0;
   while(true)
     {
      if(FileIsEnding(handle)) break;
      string ds=FileReadString(handle);
      if(FileIsEnding(handle) && StringLen(ds)==0) break;
      string cur=FileReadString(handle);
      string imp=FileReadString(handle);
      string ev=FileReadString(handle);
      if(StringFind(ds,"datetime")>=0 || StringFind(ds,"time")>=0) continue;
      if(StringLen(ds)==0) continue;
      NewsRow nr; nr.time=(datetime)ParseDateTimeFromString(ds);
      int impact=0; string impUp=imp; StringToUpper(impUp);
      if(StringFind(impUp,"HIGH")>=0) impact=2;
      else if(StringFind(impUp,"MEDIUM")>=0||StringFind(impUp,"MED")>=0) impact=1;
      nr.currency=cur; nr.impact=impact; nr.event=ev;
      int sz=ArraySize(g_newsRows); ArrayResize(g_newsRows,sz+1); g_newsRows[sz]=nr;
     }
   FileClose(handle);
   g_newsCount=ArraySize(g_newsRows);
   return(g_newsCount>0);
  }

string SymbolBase(string s)
  {
   string up=s; StringToUpper(up);
   string majors[]={"EUR","GBP","USD","JPY","CHF","AUD","NZD","CAD"};
   for(int i=0;i<8;i++)
      if(StringFind(up,majors[i])==0) return(majors[i]);
   return("");
  }

string SymbolQuote(string s)
  {
   string up=s; StringToUpper(up);
   string majors[]={"EUR","GBP","USD","JPY","CHF","AUD","NZD","CAD"};
   for(int i=0;i<8;i++)
      if(StringFind(up,majors[i])>=0 && StringFind(up,majors[i])+3==StringLen(up)) return(majors[i]);
   return("");
  }

bool IsNewsTime()
  {
   if(!InpEnableNewsFilter) return(false);
   if(InpNewsDataMode==NEWS_DISABLED) return(false);
   datetime now=TimeCurrent();
   datetime before=now-InpNewsMinutesBefore*60;
   datetime after=now+InpNewsMinutesAfter*60;

   if(InpNewsDataMode==NEWS_CSV)
     {
      if(g_newsCount==0) LoadNewsCSV(InpNewsCSVFileName);
      if(g_newsCount>0)
        {
         for(int i=0;i<g_newsCount;i++)
           {
            if(g_newsRows[i].impact<1) continue;
            datetime st=g_newsRows[i].time;
            if(st>=before && st<=after)
              {
               string b=SymbolBase(_Symbol);
               string q=SymbolQuote(_Symbol);
               string c=g_newsRows[i].currency; StringToUpper(c);
               if(StringLen(b)>0 && StringFind(c,b)>=0) return(true);
               if(StringLen(q)>0 && StringFind(c,q)>=0) return(true);
               if(StringLen(b)==0 && StringLen(q)==0) return(true);
              }
           }
        }
      else
        {
         if(InpFailSafeMode) return(true);
         return(false);
        }
     }
   else if(InpNewsDataMode==NEWS_CALENDAR)
     {
      MqlCalendarEvent events[];
      int evCount=CalendarEventHistory(events,before,after,NULL,NULL);
      if(evCount>0) return(true);
      if(InpFailSafeMode) return(true);
      return(false);
     }
   return(false);
  }

//+------------------------------------------------------------------+
//| الإحصائيات                                                        |
//+------------------------------------------------------------------+
double NetPnlByPeriod(datetime from,datetime to)
  {
   double total=0.0;
   if(!HistorySelect(from,to)) return(0.0);
   for(int i=HistoryDealsTotal()-1;i>=0;i--)
     {
      ulong ticket=HistoryDealGetTicket(i);
      if(ticket==0) continue;
      if(HistoryDealGetInteger(ticket,DEAL_MAGIC)!=InpMagic) continue;
      long entry=HistoryDealGetInteger(ticket,DEAL_ENTRY);
      if(entry!=DEAL_ENTRY_OUT && entry!=DEAL_ENTRY_INOUT) continue;
      total+=HistoryDealGetDouble(ticket,DEAL_PROFIT);
      total+=HistoryDealGetDouble(ticket,DEAL_SWAP);
      total+=HistoryDealGetDouble(ticket,DEAL_COMMISSION);
     }
   return(total);
  }

int CountClosedTradesByPeriod(datetime from,datetime to)
  {
   int cnt=0;
   if(HistorySelect(from,to))
     {
      for(int i=HistoryDealsTotal()-1;i>=0;i--)
        {
         ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0) continue;
         if(HistoryDealGetInteger(ticket,DEAL_MAGIC)!=InpMagic) continue;
         long entry=HistoryDealGetInteger(ticket,DEAL_ENTRY);
         if(entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_INOUT) cnt++;
        }
     }
   return(cnt);
  }

int CountConsecutiveLosses()
  {
   int losses=0;
   if(!HistorySelect(0,TimeCurrent())) return(0);
   for(int i=HistoryDealsTotal()-1;i>=0;i--)
     {
      ulong ticket=HistoryDealGetTicket(i);
      if(ticket==0) continue;
      if(HistoryDealGetInteger(ticket,DEAL_MAGIC)!=InpMagic) continue;
      long entry=HistoryDealGetInteger(ticket,DEAL_ENTRY);
      if(entry!=DEAL_ENTRY_OUT && entry!=DEAL_ENTRY_INOUT) continue;
      double pnl=HistoryDealGetDouble(ticket,DEAL_PROFIT)+HistoryDealGetDouble(ticket,DEAL_SWAP)+HistoryDealGetDouble(ticket,DEAL_COMMISSION);
      if(pnl<0) losses++; else break;
     }
   return(losses);
  }

int CountTradesToday()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   dt.hour=0; dt.min=0; dt.sec=0;
   return(CountClosedTradesByPeriod(StructToTime(dt),TimeCurrent()));
  }

int CountTradesThisSession()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   datetime sessionStart=0;
   if(dt.hour>=InpLondonStartHour && dt.hour<InpLondonEndHour){dt.hour=InpLondonStartHour;dt.min=0;dt.sec=0;sessionStart=StructToTime(dt);}
   else if(dt.hour>=InpNewYorkStartHour && dt.hour<InpNewYorkEndHour){dt.hour=InpNewYorkStartHour;dt.min=0;dt.sec=0;sessionStart=StructToTime(dt);}
   if(sessionStart==0) return(0);
   return(CountClosedTradesByPeriod(sessionStart,TimeCurrent()));
  }

//+------------------------------------------------------------------+
//| Journal/CSV                                                       |
//+------------------------------------------------------------------+
bool EnsureJournalCSV()
  {
   if(!InpWriteJournalCSV) return(true);
   bool header=(!FileIsExist(InpJournalCSVName,FILE_COMMON) && !FileIsExist(InpJournalCSVName,0));
   int flags=FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI;
   g_journalHandle=FileOpen(InpJournalCSVName,flags,'\t',CP_UTF8);
   if(g_journalHandle==INVALID_HANDLE) return(false);
   if(header)
     {
      string headerLine="Time,Decision,Symbol,Magic,System,AssetType,SignalType,Direction,Volume,PriceOpen,SL,TP,SpreadPoints,Balance,Equity,RiskPercent,Retcode,Reason";
      FileWriteString(g_journalHandle,headerLine+"\r\n");
     }
   return(true);
  }

void Journal(string decision,string signalType,string direction,double volume,
             double priceOpen,double sl,double tp,double riskPercent,int retcode,string reason)
  {
   if(!InpWriteJournalCSV||g_journalHandle==INVALID_HANDLE) return;
   string line=StringFormat("%s,%s,%s,%d,%s,%s,%s,%s,%.5f,%.5f,%.5f,%.5f,%.5f,%.2f,%.2f,%.2f,%d,\"%s\"",
      TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES),decision,_Symbol,InpMagic,"AI-SMC-ICT-V2",
      AssetTypeName(g_AssetType),signalType,direction,volume,priceOpen,sl,tp,CurrentSpreadPoints(),
      AccountInfoDouble(ACCOUNT_BALANCE),AccountInfoDouble(ACCOUNT_EQUITY),riskPercent,retcode,reason);
   FileSeek(g_journalHandle,0,SEEK_END);
   FileWriteString(g_journalHandle,line+"\r\n");
   FileFlush(g_journalHandle);
  }

void Log(ENUM_LOG_LEVEL level,string msg)
  {
   if((int)level>(int)InpLogLevel) return;
   string tag="INFO";
   if(level==LOG_ERROR) tag="ERROR";
   if(level==LOG_WARNING) tag="WARN";
   if(level==LOG_DEBUG) tag="DEBUG";
   PrintFormat("[%s][%s] %s",tag,_Symbol,msg);
  }

//+------------------------------------------------------------------+
//| فحص Stops Level                                                   |
//+------------------------------------------------------------------+
bool CheckStopLevel(double price,double sl,double tp)
  {
   if(!InpUseStopLevelCheck) return(true);
   if(sl<=0||tp<=0) return(false);
   double stopsLevel=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double freezeLevel=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   double minDist=MathMax(stopsLevel,freezeLevel)*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   if(MathAbs(price-sl)<minDist) return(false);
   if(MathAbs(price-tp)<minDist) return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//| فتح الصفقات                                                       |
//+------------------------------------------------------------------+
bool OpenBuy(string reason)
  {
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(ask<=0||bid<=0) return(false);
   double sl=0,tp=0;
   GetBuySLTP(ask,sl,tp);
   if(sl<=0||tp<=0) return(false);
   if(!CheckStopLevel(ask,sl,tp)) return(false);
   double lot=CalculateLot(_Symbol,sl);
   if(lot<=0) return(false);

   double openRisk=TotalOpenRiskMoney();
   double maxRisk=AccountInfoDouble(ACCOUNT_EQUITY)*InpMaxOpenRiskPercent/100.0;
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   double newRisk=lot*MathAbs(ask-sl)/point*SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   if(openRisk+newRisk>maxRisk) return(false);

   bool res=trade.Buy(lot,_Symbol,ask,sl,tp,g_EAComment);
   Journal("Entry","AI_SMC_BUY","BUY",lot,ask,sl,tp,InpRiskPerTradePercent,res?0:GetLastError(),reason+" | lot="+DoubleToString(lot,2));
   return(res);
  }

bool OpenSell(string reason)
  {
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(bid<=0||ask<=0) return(false);
   double sl=0,tp=0;
   GetSellSLTP(bid,sl,tp);
   if(sl<=0||tp<=0) return(false);
   if(!CheckStopLevel(bid,sl,tp)) return(false);
   double lot=CalculateLot(_Symbol,sl);
   if(lot<=0) return(false);

   double openRisk=TotalOpenRiskMoney();
   double maxRisk=AccountInfoDouble(ACCOUNT_EQUITY)*InpMaxOpenRiskPercent/100.0;
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   double newRisk=lot*MathAbs(sl-bid)/point*SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   if(openRisk+newRisk>maxRisk) return(false);

   bool res=trade.Sell(lot,_Symbol,bid,sl,tp,g_EAComment);
   Journal("Entry","AI_SMC_SELL","SELL",lot,bid,sl,tp,InpRiskPerTradePercent,res?0:GetLastError(),reason+" | lot="+DoubleToString(lot,2));
   return(res);
  }

//+------------------------------------------------------------------+
//| حالة الحظر                                                        |
//+------------------------------------------------------------------+
string StatusBlockReason()
  {
   if(!InpEnableEA) return("Disabled");
   if(g_PausedManual) return("Paused");
   if(!IsSymbolTradable()) return("SymbolNotTradable");
   if(InpOnlyTradeDetected && g_AssetType==ASSET_OTHER) return("UnknownAsset");
   if(IsWeekendBlocked()) return("WeekendBlock");
   if(!IsSessionAllowed()) return("SessionBlock");
   if(InpFocusOnLondonOpening && !IsInLondonOpening()) return("NotLondonOpen");
   if(IsNewsTime()) return("NewsBlock");

   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   dt.hour=0;dt.min=0;dt.sec=0;
   datetime dayStart=StructToTime(dt);
   double dailyNet=NetPnlByPeriod(dayStart,TimeCurrent());
   double maxDailyLoss=AccountInfoDouble(ACCOUNT_BALANCE)*InpDailyLossLimitPercent/100.0;
   if(dailyNet<-maxDailyLoss) return("DailyLimit");

   int dayOffset=dt.day_of_week==0?6:dt.day_of_week-1;
   datetime weekStart=dayStart-dayOffset*86400;
   double weeklyNet=NetPnlByPeriod(weekStart,TimeCurrent());
   double maxWeeklyLoss=AccountInfoDouble(ACCOUNT_BALANCE)*InpWeeklyLossLimitPercent/100.0;
   if(weeklyNet<-maxWeeklyLoss) return("WeeklyLimit");

   if(g_CurDrawdownPct>=InpMaxEquityDrawdownPercent) return("DrawdownLimit");
   if(g_ConsecutiveLosses>0 && g_ConsecutiveLosses>=InpMaxConsecutiveLosses) return("ConsecutiveLosses");
   if(CountTradesToday()>=InpMaxTradesPerDay) return("MaxTradesPerDay");
   if(InpMaxTradesPerSession>0 && CountTradesThisSession()>=InpMaxTradesPerSession) return("MaxTradesPerSession");

   if(InpEnableSpreadFilter)
     {
      double spread=CurrentSpreadPoints();
      if(spread>InpMaxSpreadPoints) return("SpreadBlock");
     }
   return("");
  }

//+------------------------------------------------------------------+
//| إدارة المراكز                                                     |
//+------------------------------------------------------------------+
double PositionPL(long type)
  {
   double open=PositionGetDouble(POSITION_PRICE_OPEN);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   if(type==POSITION_TYPE_BUY) return(bid-open);
   return(open-ask);
  }

bool ModifySL(ulong ticket,double newSL)
  {
   double curSL=PositionGetDouble(POSITION_SL);
   long type=PositionGetInteger(POSITION_TYPE);
   // لا تُحرّك الوقف بعيداً أبداً
   if(type==POSITION_TYPE_BUY && curSL>0 && newSL<curSL) return(false);
   if(type==POSITION_TYPE_SELL && curSL>0 && newSL>curSL) return(false);
   if(InpUseStopLevelCheck)
     {
      double stopsLevel=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
      double minDist=stopsLevel*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
      double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      if(type==POSITION_TYPE_BUY && MathAbs(ask-newSL)<minDist) return(false);
      if(type==POSITION_TYPE_SELL && MathAbs(newSL-bid)<minDist) return(false);
     }
   return(trade.PositionModify(ticket,newSL,PositionGetDouble(POSITION_TP)));
  }

void ManageOpenPositions()
  {
   int total=PositionsTotal();
   for(int i=0;i<total;i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagic) continue;

      long type=PositionGetInteger(POSITION_TYPE);
      double open=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      double vol=PositionGetDouble(POSITION_VOLUME);
      double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
      if(point<=0) continue;
      double profitPoints=PositionPL(type)/point;

      if(InpBreakEven && profitPoints>=InpBreakEvenTriggerPoints)
        {
         double beSL=open+InpBreakEvenLockPoints*point;
         if(type==POSITION_TYPE_SELL) beSL=open-InpBreakEvenLockPoints*point;
         if((type==POSITION_TYPE_BUY && (sl<=0||sl<beSL)) ||
            (type==POSITION_TYPE_SELL && (sl<=0||sl>beSL)))
            ModifySL(ticket,beSL);
        }

      if(InpTrailingStop && profitPoints>=InpTrailingStartPoints)
        {
         if(type==POSITION_TYPE_BUY)
           {
            double newSL=SymbolInfoDouble(_Symbol,SYMBOL_BID)-InpTrailingStepPoints*point;
            if(newSL>sl) ModifySL(ticket,newSL);
           }
         else
           {
            double newSL=SymbolInfoDouble(_Symbol,SYMBOL_ASK)+InpTrailingStepPoints*point;
            if(newSL<sl) ModifySL(ticket,newSL);
           }
        }

      if(InpPartialClose && profitPoints>=InpPartialCloseTriggerPoints)
        {
         double partialVol=NormalizeVolume(vol*InpPartialClosePercent/100.0,_Symbol);
         if(partialVol>=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN))
           {
            trade.PositionClosePartial(ticket,partialVol);
            Journal("Partial","AI_SMC",(type==POSITION_TYPE_BUY?"BUY":"SELL"),partialVol,open,sl,tp,InpRiskPerTradePercent,0,"Partial "+DoubleToString(profitPoints,0)+"pts");
           }
        }

      if(InpMaxBarsInTrade>0)
        {
         datetime openTime=(datetime)PositionGetInteger(POSITION_TIME);
         int barsInside=(int)((TimeCurrent()-openTime)/PeriodSeconds(_Period));
         if(barsInside>InpMaxBarsInTrade)
           {
            trade.PositionClose(ticket);
            Journal("Close","AI_SMC",(type==POSITION_TYPE_BUY?"BUY":"SELL"),vol,open,sl,tp,InpRiskPerTradePercent,0,"MaxBarsInTrade");
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| لوحة المراقبة                                                     |
//+------------------------------------------------------------------+
void CreateLabel(string name,int x,int y,string text,color clr,int fontSize=8,string font="Segoe UI")
  {
   string objName=g_Prefix+name;
   if(ObjectFind(0,objName)<0) ObjectCreate(0,objName,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,objName,OBJPROP_CORNER,
      InpDashboardCorner==1?CORNER_LEFT_UPPER:
      InpDashboardCorner==2?CORNER_RIGHT_UPPER:
      InpDashboardCorner==3?CORNER_LEFT_LOWER:CORNER_RIGHT_LOWER);
   ObjectSetInteger(0,objName,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,objName,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,objName,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,objName,OBJPROP_FONTSIZE,fontSize);
   ObjectSetString(0,objName,OBJPROP_FONT,font);
   ObjectSetString(0,objName,OBJPROP_TEXT,text);
   ObjectSetInteger(0,objName,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,objName,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,objName,OBJPROP_BACK,false);
  }

void UpdateDashboard()
  {
   if(!InpShowDashboard) return;
   string status=StatusBlockReason();
   if(StringLen(status)==0) status="Trading OK";
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   dt.hour=0;dt.min=0;dt.sec=0;
   datetime dayStart=StructToTime(dt);
   double dailyNet=NetPnlByPeriod(dayStart,TimeCurrent());
   int dayOffset=dt.day_of_week==0?6:dt.day_of_week-1;
   double weeklyNet=NetPnlByPeriod(dayStart-dayOffset*86400,TimeCurrent());
   double spread=CurrentSpreadPoints();

   CreateLabel("T1",10,12,"🤖 AI-SMC/ICT PRO V2",clrAqua,10);
   CreateLabel("T2",10,30,"Architecture: Daily Bias → PO3 → SMC Confirm → Sniper Entry (M1)",clrSlateGray,8);
   CreateLabel("T3",10,46,"Status: "+status,(StringLen(status)==0?clrLime:orange),9);
   CreateLabel("T4",10,62,"EA Name (Comment): "+g_EAComment+"  |  Magic: "+IntegerToString(InpMagic),clrLightGray,8);
   CreateLabel("T5",10,78,AssetTypeIcon(g_AssetType)+" Asset: "+g_AssetName+"  |  Symbol: "+_Symbol+"  |  TF: "+TFName(_Period),clrAqua,8);
   CreateLabel("T6",10,94,"Balance: "+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)+"  Equity: "+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2),clrWhite,8);
   CreateLabel("T7",10,110,"P/L Daily: "+DoubleToString(dailyNet,2)+"  Weekly: "+DoubleToString(weeklyNet,2),dailyNet<0?clrRed:clrLime,8);
   CreateLabel("T8",10,126,"Drawdown: "+DoubleToString(g_CurDrawdownPct,2)+"%",g_CurDrawdownPct>InpMaxEquityDrawdownPercent?clrRed:clrLightGray,8);
   CreateLabel("T9",10,142,"Trades Today: "+IntegerToString(CountTradesToday())+"  Session: "+IntegerToString(CountTradesThisSession())+"  Consec Loss: "+IntegerToString(g_ConsecutiveLosses),clrLightGray,8);
   CreateLabel("T10",10,158,"Spread: "+DoubleToString(spread,0)+"/"+IntegerToString(InpMaxSpreadPoints)+" pts",spread>InpMaxSpreadPoints?clrRed:clrLightGray,8);
   CreateLabel("T11",10,174,"Session: "+SessionName(dt)+"  |  LondonOpen: "+(IsInLondonOpening()?"YES":"NO")+"  |  News: "+(IsNewsTime()?"BLOCK":"OK"),clrLightGray,8);
   CreateLabel("T12",10,190,"DailyBias: "+EnumToString(GetDailyBias()),clrLightGray,8);
   CreateLabel("T13",10,206,"Buy Signal: "+(g_BuySignalState?"YES":"NO")+"  "+g_LastReasonBuy,g_BuySignalState?clrLime:clrGray,7);
   CreateLabel("T14",10,222,"Sell Signal: "+(g_SellSignalState?"YES":"NO")+"  "+g_LastReasonSell,g_SellSignalState?clrRed:clrGray,7);
   CreateLabel("T15",10,238,"Open Risk: "+DoubleToString(TotalOpenRiskMoney(),2)+" / "+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY)*InpMaxOpenRiskPercent/100.0,2),clrLightGray,7);
  }

void ClearDashboard()
  {
   for(int i=1;i<=30;i++)
     {
      string objName=g_Prefix+"T"+IntegerToString(i);
      if(ObjectFind(0,objName)>=0) ObjectDelete(0,objName);
     }
  }

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_EAComment=BuildEAComment();
   g_AssetType=DetectAssetType(_Symbol);
   g_AssetName=AssetTypeName(g_AssetType);

   trade.SetExpertMagicNumber(InpMagic>0?(ulong)InpMagic:702001UL);
   trade.SetDeviationInPoints((ulong)InpMaxDeviationPoints);

   g_PeakEquity=AccountInfoDouble(ACCOUNT_EQUITY);
   g_MaxEquity=g_PeakEquity;

   if(InpEnableNewsFilter && InpNewsDataMode==NEWS_CSV)
     {
      if(!LoadNewsCSV(InpNewsCSVFileName))
         Log(LOG_WARNING,"تعذر تحميل ملف الأخبار: "+InpNewsCSVFileName+" — FailSafe="+(InpFailSafeMode?"ON":"OFF"));
     }

   if(!EnsureJournalCSV())
      Log(LOG_WARNING,"تعذر إنشاء ملف Journal CSV");

   // تحميل أولي
   LoadAllTimeframes();
   g_BuySignalState=IsBuySignal();
   g_SellSignalState=IsSellSignal();

   if(InpShowDashboard) UpdateDashboard();

   Log(LOG_INFO,"OnInit OK | EA="+g_EAComment+" | Magic="+IntegerToString(InpMagic)+" | Symbol="+_Symbol+" | TF="+TFName(_Period)+" | Asset="+g_AssetName);
   Log(LOG_INFO,"AI-SMC/ICT: DailyBias="+TFName(InpDailyBiasTF)+" | PO3="+TFName(InpPO3StructureTF)+"/"+TFName(InpPO3AccumTF)+" | Confirm="+TFName(InpSMCConfirmTF)+" | Entry="+TFName(InpEntryTF));
   Log(LOG_INFO,"⚠️ الاختبار التاريخي ليس ضماناً للأداء الحي. لا تنتقل لحساب حقيقي قبل Baseline + Stress + Forward + Demo.");
   g_InitOK=true;
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ClearDashboard();
   if(g_journalHandle!=INVALID_HANDLE)
     {
      FileFlush(g_journalHandle);
      FileClose(g_journalHandle);
     }
   Log(LOG_INFO,"OnDeinit reason="+IntegerToString(reason));
  }

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick()
  {
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq>g_MaxEquity) g_MaxEquity=eq;
   g_CurDrawdownPct=g_MaxEquity>0?(g_MaxEquity-eq)/g_MaxEquity*100.0:0.0;
   if(g_CurDrawdownPct*g_MaxEquity/100.0>g_MaxDrawdownMoney) g_MaxDrawdownMoney=g_CurDrawdownPct*g_MaxEquity/100.0;
   g_ConsecutiveLosses=CountConsecutiveLosses();

   ManageOpenPositions();

   static int tickCount=0;
   tickCount++;
   if(InpShowDashboard && tickCount%5==0) UpdateDashboard();

   if(g_InitOK && !InpEnableEA) return;

   if(InpRequireValidTick)
     {
      if(SymbolInfoDouble(_Symbol,SYMBOL_BID)<=0 || SymbolInfoDouble(_Symbol,SYMBOL_ASK)<=0) return;
     }

   // محرك الإشارة يعمل على إطار الدخول (M1)
   if(!IsNewBar(InpEntryTF)) return;

   // تحديث حالات الإشارة
   g_BuySignalState=IsBuySignal();
   g_SellSignalState=IsSellSignal();

   if(InpMaxOpenPositionsPerSymbol>0 && CountPositions(_Symbol,(long)InpMagic)>=InpMaxOpenPositionsPerSymbol)
      return;

   string block=StatusBlockReason();
   if(StringLen(block)>0)
     {
      Log(LOG_DEBUG,"Blocked: "+block+" | Buy="+g_BuySignalState+" Sell="+g_SellSignalState);
      return;
     }

   bool allowBuy=true, allowSell=true;
   if(!InpAllowHedge)
     {
      if(CountPositionsByType(_Symbol,(long)InpMagic,POSITION_TYPE_BUY)>0) allowBuy=false;
      if(CountPositionsByType(_Symbol,(long)InpMagic,POSITION_TYPE_SELL)>0) allowSell=false;
     }

   if(allowBuy && g_BuySignalState)
     {
      if(OpenBuy(g_LastReasonBuy))
         Log(LOG_INFO,"BUY Entry | "+g_LastReasonBuy+" | "+_Symbol+" | Magic="+IntegerToString(InpMagic)+" | Comment="+g_EAComment);
     }
   else if(allowSell && g_SellSignalState)
     {
      if(OpenSell(g_LastReasonSell))
         Log(LOG_INFO,"SELL Entry | "+g_LastReasonSell+" | "+_Symbol+" | Magic="+IntegerToString(InpMagic)+" | Comment="+g_EAComment);
     }
  }

//+------------------------------------------------------------------+
//| OnTradeTransaction                                                |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   g_ConsecutiveLosses=CountConsecutiveLosses();
   UpdateDashboard();

   if(trans.type==TRADE_TRANSACTION_DEAL_ADD)
     {
      if(!HistorySelect(0,TimeCurrent())) return;
      for(int i=0;i<HistoryDealsTotal();i++)
        {
         ulong deal=HistoryDealGetTicket(i);
         if(deal==0 || deal!=trans.deal) continue;
         long magic=HistoryDealGetInteger(deal,DEAL_MAGIC);
         long entry=HistoryDealGetInteger(deal,DEAL_ENTRY);
         if(magic==InpMagic && (entry==DEAL_ENTRY_OUT||entry==DEAL_ENTRY_INOUT))
           {
            double pnl=HistoryDealGetDouble(deal,DEAL_PROFIT)+HistoryDealGetDouble(deal,DEAL_SWAP)+HistoryDealGetDouble(deal,DEAL_COMMISSION);
            Log(LOG_INFO,"Trade Closed | Deal="+IntegerToString(deal)+" | P/L="+DoubleToString(pnl,2));
            Journal("Close","AI_SMC","CLOSED",0,0,0,0,0,0,"Closed deal P/L="+DoubleToString(pnl,2));
           }
         break;
        }
     }

   if(InpCloseOnDrawdownLimit && g_CurDrawdownPct>=InpMaxEquityDrawdownPercent)
     {
      for(int i=0;i<PositionsTotal();i++)
        {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0) continue;
         if(PositionGetInteger(POSITION_MAGIC)!=InpMagic) continue;
         trade.PositionClose(ticket);
        }
      Log(LOG_WARNING,"DrawdownLimit: تم إغلاق المراكز (بتفعيل صريح)");
     }
  }

//+------------------------------------------------------------------+
//| OnChartEvent (محجوز — لا أزرار يدوية في هذه النسخة)               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
  }
//+------------------------------------------------------------------+
