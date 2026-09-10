//+------------------------------------------------------------------+
//|                                               NovaGravity_AI_EA.mq5
//|                                 NOVA GRAVITY AI  |  v1.00 (Pro)
//|          Adaptive Multi-Class Expert Advisor for MetaTrader 5
//+------------------------------------------------------------------+
//|  Instruments : Crypto, Forex, Metals (gold), Energy (oil),       |
//|                Indices, Stocks and every USDT-linked symbol      |
//|  Timeframes  : All (M1..MN1) - symbol & timeframe auto-detected  |
//|  Extra       : AI-driven protection layer (weekend guard,        |
//|                regimes QUIET/TREND/VOLATILE, partial -> BE,      |
//|                time stop, gap filter, news blackout, spread cap) |
//+------------------------------------------------------------------+
#property copyright "NOVA GRAVITY AI - Automated Trading Engine"
#property link      ""
#property version   "1.02"
#property description "NOVA GRAVITY AI | Adaptive Multi-Class EA v1.02"
#property description "Auto-detects symbol class (FX/Crypto/Gold/Oil/Indices/Stocks/USDT) and timeframe."
#property description "Protection layer: Friday weekend guard, QUIET/VOLATILE regime filter,"
#property description "partial close -> breakeven, max hold time stop, gap & spread filters."
#property description "NO martingale / NO grid / NO averaging - one position per symbol."

#include <Trade/Trade.mqh>

//====================================================================
//  ENUMS  (unique identifiers - required on build 5200+)
//====================================================================
enum ENUM_NG_RISK_MODE          { NG_RISK_FIXED=0, NG_RISK_PERCENT=1, NG_RISK_MARGIN=2 };
enum ENUM_NG_ENTRY_MODE         { NG_ENTRY_PULLBACK=0, NG_ENTRY_TREND_ONLY=1 };
enum ENUM_NG_REGIME_MODE        { NG_REGIME_AUTO=0, NG_REGIME_ALWAYS=1 };
enum ENUM_NG_FRIDAY_ACTION      { NG_FRIDAY_CLOSE_ALL=0, NG_FRIDAY_BREAKEVEN=1,
                                  NG_FRIDAY_CLOSE_PROFIT_BE_LOSS=2 };
enum ENUM_NG_SYMBOL_CLASS       { NG_CLASS_FOREX=0, NG_CLASS_CRYPTO=1, NG_CLASS_GOLD=2,
                                  NG_CLASS_OIL=3, NG_CLASS_INDEX=4, NG_CLASS_STOCK=5,
                                  NG_CLASS_USDT=6, NG_CLASS_OTHER=7 };
enum ENUM_NG_ROLLOVER_ACTION   { NG_ROLLOVER_BREAKEVEN=0, NG_ROLLOVER_CLOSE=1 };
enum ENUM_NG_TRAIL_MODE        { NG_TRAIL_ATR=0, NG_TRAIL_POINTS=1,
                                  NG_TRAIL_PERCENT=2, NG_TRAIL_LADDER=3 };

// adaptive genome - tunable parameters the AI engine optimizes
struct NG_Genome
{
   double partialTriggerRR;   // partial at X*R
   double partialPct;         // % closed at partial
   double beBufferATR;        // breakeven buffer (x ATR)
   double trailStartRR;       // trail activation (x ATR from entry)
   double trailStepATR;       // trail step (x ATR)
   double slATR;              // initial SL (x ATR)
   double tpATR;              // initial TP (x ATR)
   double adxThreshold;       // ADX entry filter
   double rsiLevel;           // RSI momentum level
};

// per-genome performance record (only POSITIVE outcomes are promoted)
struct NG_Record
{
   NG_Genome  g;
   int        trades;
   int        wins;
   double     net;            // net profit (positive only promoted)
   double     peak;
   double     dd;
   double     score;          // PF * sqrt(N) / (DD%+eps)
   long       lastUsed;       // datetime of last trade
   bool       active;
};

//====================================================================
//  INPUTS
//====================================================================
input group "===== 01 | GENERAL ====="
input string   InpID                      = "NOVA-GRAVITY-AI"; // EA Instance ID (comment)
input long     InpMagicNumber             = 345678;             // Magic number
input bool     InpAutoDetectSymbol        = true;               // Auto-detect symbol (chart)
input string   InpSymbolOverride          = "";                 // Force symbol (""=auto)
input bool     InpAutoDetectTimeframe     = true;               // Auto timeframe (chart)
input ENUM_TIMEFRAMES InpTimeframeOverride= PERIOD_CURRENT;     // Force TF (CURRENT=auto)
input bool     InpAllowNewTrades          = true;               // Master switch: new entries
input int      InpMaxSpreadPoints         = 0;                  // Max spread (points, 0=auto ATR mode)
input double   InpMaxSpreadATRFactor      = 0.20;               // Max spread as fraction of ATR
input int      InpDeviationPoints         = 20;                 // Max slippage deviation (points)
input bool     InpShowPanel               = true;               // Show on-chart status panel

input group "===== 02 | RISK MANAGEMENT ====="
input ENUM_NG_RISK_MODE   InpRiskMode            = NG_RISK_PERCENT; // Sizing mode
input double   InpFixedLots             = 0.01;               // Fixed lots (fixed mode)
input double   InpRiskPercent           = 1.0;                // Risk % of balance per trade
input double   InpMarginRiskPercent     = 10.0;               // Risk % of free margin per trade
input double   InpMaxLots               = 10.0;               // Hard cap on lots
input int      InpMaxOpenPositions      = 1;                  // Max open positions per symbol
input double   InpDailyLossLimitPercent = 3.0;                // Daily loss limit % (0=off)
input int      InpMaxDailyTrades        = 8;                  // Max new trades per day (0=off)
input double   InpGlobalDrawdownStopPercent = 0.0;            // Global DD stop from peak equity % (0=off)

input group "===== 03 | ENTRY SIGNAL ====="
input ENUM_NG_ENTRY_MODE InpEntryMode        = NG_ENTRY_PULLBACK; // Entry mode
input int      InpFastEMA             = 21;                  // Fast EMA
input int      InpSlowEMA             = 55;                  // Slow EMA (trend filter)
input int      InpRSIPeriod           = 14;                  // RSI period
input double   InpRSIMomentumLevel    = 50.0;                // RSI momentum level
input double   InpRSIFadeBuy          = 35.0;                // RSI fade level (volatile range BUY)
input double   InpRSIFadeSell         = 65.0;                // RSI fade level (volatile range SELL)
input int      InpMACDFast            = 12;                  // MACD fast
input int      InpMACDSlow            = 26;                  // MACD slow
input int      InpMACDSignal          = 9;                   // MACD signal
input int      InpADXPeriod           = 14;                  // ADX period
input double   InpADXThreshold        = 22.0;                // ADX threshold (trend strength)
input bool     InpUseHTFAlignment     = true;                // Higher-TF trend alignment
input int      InpHTFMultiplier       = 4;                   // Higher-TF multiplier (x4 of chart TF)
input int      InpBBPeriod            = 20;                  // Bollinger period
input double   InpBBDev               = 2.0;                 // Bollinger deviation
input int      InpPullbackLookback    = 5;                   // Bars window for a touch
input double   InpTouchToleranceATR   = 0.10;                // Touch tolerance (x ATR)
input double   InpMaxEntryDistanceATR = 1.5;                 // Anti-chase: max distance from EMA21 (x ATR)

input group "===== 04 | MARKET REGIME (QUIET / TREND / VOLATILE) ====="
input ENUM_NG_REGIME_MODE InpRegimeMode       = NG_REGIME_AUTO;  // AUTO=adaptive, ALWAYS=ignore regime
input int      InpATRPeriod           = 14;                  // ATR period
input int      InpRegimeLookback      = 120;                 // Bars used to build normal ATR (median)
input double   InpQuietATRFactor      = 0.75;                // ATR < factor*median  -> QUIET (wait)
input double   InpVolatileATRFactor   = 2.00;                // ATR > factor*median  -> VOLATILE
input bool     InpTradeVolatileRange  = false;               // VOLATILE: allow range fade only (no breakout)

input group "===== 05 | TIME & NEWS FILTERS ====="
input int      InpServerGmtOffset     = 999;                 // Server GMT offset (999=auto-detect)
input bool     InpSessionFilter       = false;               // Trade only London+New York
input int      InpLondonStart         = 8;                   // London open (GMT hour)
input int      InpLondonEnd           = 17;                  // London close (GMT hour)
input int      InpNewYorkStart        = 13;                  // New York open (GMT hour)
input int      InpNewYorkEnd          = 22;                  // New York close (GMT hour)
input bool     InpNewsFilter          = true;                // US-data blackout (server hours)
input int      InpNewsBlockStart      = 13;                  // Blackout start (server hour)
input int      InpNewsBlockEnd        = 16;                  // Blackout end (server hour)
input int      InpNewsBracketMinutes  = 15;                  // Extra minutes around blackout
input int      InpNewsFridayExtendHours = 1;                 // Extend blackout on Friday (hours)
input bool     InpAllowCryptoNews     = true;                // Crypto/USDT ignore news blackout

input group "===== 06 | WEEKEND / FRIDAY GUARD (account survival) ====="
input int      InpFridayCutoffHour    = 20;                  // Friday cutoff (server hour): no new trades after
input int      InpFridayLeadMinutes   = 60;                  // Minutes before cutoff: activate protection
input ENUM_NG_FRIDAY_ACTION InpFridayAction = NG_FRIDAY_CLOSE_ALL; // Action before weekend
input int      InpSundayBlockMinutes  = 120;                 // No new trades first X min of Sunday reopen
input bool     InpApplyGuardCrypto    = false;               // Apply weekend guard to crypto/USDT too

input group "===== 07 | EXIT & PROTECTION ====="
input double   InpSL_ATR              = 2.0;                 // Initial stop-loss (x ATR)
input double   InpTP_ATR              = 3.0;                 // Initial take-profit (x ATR, 0=auto RR)
input double   InpMinRR               = 1.4;                 // Min reward:risk for a valid trade
input bool     InpPartialCloseEnabled = true;                // Partial profit-taking at 1R
input double   InpPartialClosePercent = 50.0;                // Volume closed at partial (%)
input double   InpPartialCloseAtRR    = 1.0;                 // Partial trigger (R multiple)
input bool     InpBreakEvenAfterPartial = true;              // SL -> entry + lock right after partial
input double   InpBreakEvenBufferATR  = 0.10;                // Breakeven lock buffer (x ATR)
input bool     InpTrailingEnabled     = true;                // Trailing stop
input double   InpTrailingStartATR    = 1.5;                 // Trail activation (R from entry, x ATR)
input double   InpTrailingStepATR     = 0.5;                 // Trail distance (x ATR)
input bool     InpTimeExitEnabled     = true;                // Time-stop: max holding time
input int      InpMaxHoldBars         = 0;                   // Max hold bars (0=auto per class)
input bool     InpReverseSignalExit   = false;               // Exit when opposite signal appears

input group "===== 08 | SYMBOL CLASS AUTO-ADAPTATION ====="
input bool     InpAutoClass           = true;                // Auto-detect symbol class
input string   InpClassOverride       = "";                  // Force class: FOREX|CRYPTO|GOLD|OIL|INDEX|STOCKS|USDT
input int      InpMaxHoldForex        = 32;                  // Max hold bars H1-equivalent: FOREX
input int      InpMaxHoldCrypto       = 96;                  // Max hold bars H1-equivalent: CRYPTO/USDT
input int      InpMaxHoldGold         = 28;                  // Max hold bars H1-equivalent: GOLD
input int      InpMaxHoldOil          = 28;                  // Max hold bars H1-equivalent: OIL
input int      InpMaxHoldIndex        = 24;                  // Max hold bars H1-equivalent: INDICES
input int      InpMaxHoldStock        = 24;                  // Max hold bars H1-equivalent: STOCKS
input int      InpMaxHoldOther        = 36;                  // Max hold bars H1-equivalent: OTHER

input group "===== 09 | PORTFOLIO SHARING & JOURNAL ====="
input bool     InpPortfolioSharing      = true;                // Share day/week limits across ALL charts of the EA
input double   InpWeeklyLossLimitPercent= 6.0;                 // Weekly loss limit % (0=off) - portfolio-wide
input bool     InpAdaptiveRisk          = true;                // Auto-reduce risk as drawdown grows
input double   InpRiskReductionStartDD  = 5.0;                 // Drawdown % where risk scaling starts
input double   InpRiskReductionFloor    = 0.25;                // Minimum risk multiplier (never below this)
input bool     InpRolloverGuard         = true;                // Guard against negative swap at rollover
input int      InpRolloverStart         = 21;                  // Rollover start (server hour)
input int      InpRolloverEnd           = 22;                  // Rollover end (server hour)
input double   InpRolloverSwapThreshold = -0.5;                // Trigger if position swap < this ($)
input ENUM_NG_ROLLOVER_ACTION InpRolloverAction = NG_ROLLOVER_BREAKEVEN; // Guard action
input bool     InpJournalCSV            = true;                // Write NovaGravity_Journal.csv (MQL5/Files)
input bool     InpNotifyOnGuards        = false;               // Push notification on critical events

input group "===== 10 | PROFIT ENGINES: LADDER / TRAIL / EQUITY GUARD ====="
input bool     InpProfitLadderEnabled   = true;                // 4-degree profit ladder (auto-adaptive)
input int      InpLadderRung1Points     = 40;                  // Rung 1: profit points
input double   InpLadderRung1Percent    = 40.0;                // Rung 1: % of volume closed
input int      InpLadderRung2Points     = 60;                  // Rung 2: profit points
input double   InpLadderRung2Percent    = 30.0;                // Rung 2: % of remaining closed
input int      InpLadderRung3Points     = 100;                 // Rung 3: profit points
input double   InpLadderRung3Percent    = 20.0;                // Rung 3: % of remaining closed
input int      InpLadderRung4Points     = 150;                 // Rung 4: profit points
input double   InpLadderRung4Percent    = 10.0;                // Rung 4: % of remaining closed
input ENUM_NG_TRAIL_MODE InpTrailMode   = NG_TRAIL_ATR;        // Trailing mode (ATR | POINTS | PERCENT | LADDER)
input int      InpTrailFixedPoints      = 250;                 // TRAIL_POINTS: move SL after +X points
input double   InpTrailPercentStep      = 50.0;                // TRAIL_PERCENT: move SL at +% of profit-to-TP
input bool     InpEquityGuardEnabled    = true;                // Equity Guard card (modeled on the reference panel)
input double   InpGuardDailyLossPct     = 5.0;                 // Equity Guard: daily loss % goal
input double   InpGuardMaxDrawdownPct   = 10.0;                // Equity Guard: max drawdown % goal
input double   InpGuardMinFreeMarginPct = 30.0;                // Equity Guard: minimum free-margin % floor
input double   InpGuardMinHedgePct      = 20.0;                // Equity Guard: minimum hedged % (info card)

input group "===== 11 | ADAPTIVE AI ENGINE (self-learning optimization) ====="
input bool     InpAdaptiveEngine        = true;                // Self-learning optimizer (auto-tunes & filters positive results)
input int      InpAdaptiveEvalEvery     = 10;                  // Evaluate candidate genomes every N closed trades
input int      InpAdaptiveMinSamples    = 12;                  // Min closed trades before a candidate is trusted
input double   InpAdaptiveImprovePct    = 10.0;                // Switch only if new score beats current by %
input bool     InpAdaptivePersist       = true;                // Save best genome + history to MQL5/Files
input bool     InpAdaptiveReset         = false;               // Reset learned state on init
input bool     InpSoundAlerts           = true;                // Audible alerts (PlaySound)
input string   InpCustomSound           = "NovaGravity_alert.wav"; // Custom sound (MQL5/Sounds); falls back to alert.wav

//====================================================================
//  GLOBALS
//====================================================================
CTrade             trade;
int                hFastEMA=INVALID_HANDLE, hSlowEMA=INVALID_HANDLE;
int                hRSI=INVALID_HANDLE, hMACD=INVALID_HANDLE, hADX=INVALID_HANDLE;
int                hATR=INVALID_HANDLE, hBB=INVALID_HANDLE;
int                hFastEMAH=INVALID_HANDLE, hSlowEMAH=INVALID_HANDLE;
ENUM_TIMEFRAMES    g_tf=PERIOD_CURRENT, g_tfHTF=PERIOD_CURRENT;
ENUM_NG_SYMBOL_CLASS  g_class=NG_CLASS_OTHER;
string             g_symbol="";
string             g_className="OTHER";
bool               g_weekendForClass=false;    // does this asset trade over weekend?
int                g_serverGmtOffset=0;
datetime           g_lastBarTime=0, g_lastManageTime=0;
int                g_dayKey=0;
int                g_dayTrades=0;
bool               g_haltToday=false;
bool               g_haltedDD=false;
int                g_alarmCooldownMinute=-1;   // avoid log spam
double             g_peakEquity=0.0;
int                g_regimeCache=1;            // cached regime (0=QUIET,1=NORMAL,2=VOLATILE)
bool               g_pfHalt=false;            // portfolio-wide halt (shared across charts)
bool               g_pfNewHalt=false;         // set once when portfolio limit triggers
bool               g_weekHaltLocal=false;     // local weekly halt (tester / no-sharing fallback)
bool               g_haltedGuard=false;       // equity-guard halt (day/DD/margin floors)
int                g_weekKey=0;               // week key for offset re-detect (DST)
bool               g_journalWarned=false;     // avoid log spam

#define NG_GPFX "NovaGravity_"
#define NG_JOURNAL_FILE "NovaGravity_Journal.csv"
#define NG_ADAPTIVE_FILE "NovaGravity_Adaptive_State.csv"
#define NG_ADAPTIVE_LOG   "NovaGravity_Adaptive_Log.csv"

// --- adaptive engine globals
NG_Genome    g_genome;                    // currently active genome
NG_Genome    g_bestGenome;                // historically best
double       g_bestScore = -1.0;
NG_Record    g_records[];                 // candidates history (kept positive)
int          g_tradesSinceEval = 0;
int          g_adaptiveSwitches = 0;
string       g_adaptiveStatus = "LEARNING";
bool         g_adaptiveInitialized = false;

// --- live counters (dashboard)
int          g_ctOpen=0, g_ctClose=0, g_ctPartial=0, g_ctBE=0, g_ctTrail=0, g_ctGuard=0;
datetime     g_lastSound = 0;
datetime     g_lastPanelDraw = 0;
string       g_lastAdaptiveMsg = "";


// position trackers
struct NG_Position
{
   ulong   ticket;
   int     dir;              // +1 buy / -1 sell
   double  openPrice;
   double  initialVolume;
   double  atrAtEntry;
   double  initialSL;
   double  initialTP;
   datetime openTime;
   bool    partialDone;
   bool    beLocked;
   bool    fridayDone;
   bool    reverseDone;
   bool    rolloverDone;
   int     ladderStep;        // highest ladder rung already executed
   int     genomeIdx;         // which genome indexed this trade
};
NG_Position g_positions[];


// signal struct
struct NG_Signal
{
   int  dir;          // +1 / -1 / 0
   bool isRangeFade;  // entry from VOLATILE range (Bollinger fade)
};

// forward declarations
void NgCloseEvery(const string reason);
bool NgHasGap();
void NgJournalClosed(const ulong ticket);
bool NgDealSnapshot(const ulong positionTicket, double &profit, double &commission, double &swap, double &closePrice, datetime &closeTime, double &closedVolume);
string NgCloseReason(const NG_Position &p, const double closePrice);
double NgClosedPLBetween(const datetime from, const datetime to);
int NgClosedCountBetween(const datetime from, const datetime to);
void NgPortfolioUpdate(bool &halt, bool &newHalt);
void NgNotify(const string msg);
datetime NgWeekStart();
int NgDayKeyInt();
int NgWeekKeyInt();

//====================================================================
//  AUXILIARY
//====================================================================
string NgLogTag() { return "[NovaGravity] "; }

void NgInfo(const string msg)  { Print(NgLogTag()+msg); }
void NgWarn(const string msg)  { Print(NgLogTag()+"WARNING: "+msg); }
void NgError(const string msg) { Print(NgLogTag()+"ERROR: "+msg); }

//---- audible alert with cooldown (never spams)
void NgSound(const string msg)
{
   if(!InpSoundAlerts) return;
   if(MQLInfoInteger(MQL_TESTER)) return;
   datetime now = TimeCurrent();
   if(now - g_lastSound < 5) return;
   g_lastSound = now;
   string snd = InpCustomSound;
   if(StringLen(snd) == 0) snd = "alert.wav";
   PlaySound(snd);
   if(StringLen(msg) > 0) NgInfo(msg);
}

//---- normalize volume by broker VOLUME_STEP (no blind 2-decimals)
double NgNormalizeVolume(double lots)
{
   double step = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_STEP);
   double minv = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_MIN);
   double maxv = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_MAX);
   if(step <= 0.0) step = 0.01;
   if(minv <= 0.0) minv = 0.01;
   if(maxv <= 0.0) maxv = 10000.0;
   lots = MathRound(lots / step) * step;
   if(lots > maxv) lots = maxv;
   if(lots < minv) lots = minv;
   return NormalizeDouble(lots, 8);
}

//---- True number of decimals for volume step (used only for logs/Excel)
int NgVolumeDigits()
{
   double step = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0) return 2;
   int d = (int)MathRound(-MathLog10(step));
   if(d < 0) d = 0;
   return d;
}

//---- risk-based lot sizing
double NgRiskLots(const double slPriceDist)
{
   if(slPriceDist <= 0.0) return NgNormalizeVolume(InpFixedLots);
   if(InpRiskMode == NG_RISK_FIXED) return NgNormalizeVolume(InpFixedLots);

   double tickVal  = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickVal <= 0.0 || tickSize <= 0.0)
      return NgNormalizeVolume(InpFixedLots);

   double riskMoney = 0.0;
   if(InpRiskMode == NG_RISK_PERCENT)
      riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
   else
      riskMoney = AccountInfoDouble(ACCOUNT_MARGIN_FREE) * InpMarginRiskPercent / 100.0;

   //--- adaptive risk: scale down as drawdown grows (survival curve, never martingale)
   if(InpAdaptiveRisk && riskMoney > 0.0)
   {
      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      if(eq > g_peakEquity) g_peakEquity = eq;
      if(g_peakEquity <= 0.0) g_peakEquity = eq;
      double ddPct = (g_peakEquity > 0.0) ? 100.0 * (g_peakEquity - eq) / g_peakEquity : 0.0;
      if(ddPct > InpRiskReductionStartDD)
      {
         double capDD = (InpGlobalDrawdownStopPercent > 0.0) ? InpGlobalDrawdownStopPercent : 20.0;
         double span  = MathMax(capDD - InpRiskReductionStartDD, 1.0);
         double mult  = MathMax(InpRiskReductionFloor,
                                1.0 - (ddPct - InpRiskReductionStartDD) / span);
         riskMoney *= mult;
      }
   }
   if(riskMoney <= 0.0) return NgNormalizeVolume(InpFixedLots);

   double perLotRisk = (slPriceDist / tickSize) * tickVal;
   if(perLotRisk <= 0.0) return NgNormalizeVolume(InpFixedLots);

   double lots = riskMoney / perLotRisk;
   double cap  = InpMaxLots;
   if(lots > cap) lots = cap;
   return NgNormalizeVolume(lots);
}

//---- return normalized price
double NgNormPrice(const double p) { return NormalizeDouble(p, _Digits); }

//====================================================================
//  SYMBOL CLASS DETECTION
//====================================================================
string NgToUpper(const string s)
{
   string r = "";
   int len = StringLen(s);
   StringSetCharacter(r, 0, 0); // ensure valid empty string
   for(int i = 0; i < len; i++)
   {
      ushort c = StringGetCharacter(s, i);
      if(c >= 'a' && c <= 'z') c -= 32;
      r += ShortToString(c);
   }
   return r;
}

ENUM_NG_SYMBOL_CLASS NgDetectClass(const string sym)
{
   string s = NgToUpper(sym);

   if(StringFind(s, "USDT") >= 0 || StringFind(s, "USDt") >= 0 || StringFind(s, "USDC") >= 0 ||
      StringFind(s, "BUSD") >= 0 || StringFind(s, "DAI") >= 0)
      return NG_CLASS_USDT;
   if(StringFind(s, "CRYPTO") >= 0 || StringFind(s, "BITCOIN") >= 0 || StringFind(s, "BTC") >= 0 ||
      StringFind(s, "ETH") >= 0 || StringFind(s, "LTC") >= 0 || StringFind(s, "XRP") >= 0 ||
      StringFind(s, "SOL") >= 0 || StringFind(s, "BNB") >= 0 || StringFind(s, "DOGE") >= 0 ||
      StringFind(s, "ADA") >= 0 || StringFind(s, "DOT") >= 0 || StringFind(s, "AVAX") >= 0 ||
      StringFind(s, "MATIC") >= 0 || StringFind(s, "LINK") >= 0)
      return NG_CLASS_CRYPTO;
   if(StringFind(s, "GOLD") >= 0 || StringFind(s, "XAU") >= 0 || StringFind(s, "XAG") >= 0 ||
      StringFind(s, "SILVER") >= 0 || StringFind(s, "PALLADIUM") >= 0 || StringFind(s, "PLATINUM") >= 0)
      return NG_CLASS_GOLD;
   if(StringFind(s, "USOIL") >= 0 || StringFind(s, "WTI") >= 0 || StringFind(s, "BRENT") >= 0 ||
      StringFind(s, "UKOIL") >= 0 || StringFind(s, "OIL") >= 0 || StringFind(s, "NGAS") >= 0 ||
      StringFind(s, "GAS") >= 0)
      return NG_CLASS_OIL;
   if(StringFind(s, "US30") >= 0 || StringFind(s, "DJ30") >= 0 || StringFind(s, "NAS100") >= 0 ||
      StringFind(s, "USTEC") >= 0 || StringFind(s, "US100") >= 0 || StringFind(s, "SPX") >= 0 ||
      StringFind(s, "US500") >= 0 || StringFind(s, "DE40") >= 0 || StringFind(s, "GER40") >= 0 ||
      StringFind(s, "UK100") >= 0 || StringFind(s, "JP225") >= 0 || StringFind(s, "HK50") >= 0 ||
      StringFind(s, "INDEX") >= 0 || StringFind(s, "IND") >= 0)
      return NG_CLASS_INDEX;
   if(StringFind(s, ".US") >= 0 || StringFind(s, "_US") >= 0 || StringFind(s, "#") >= 0 ||
      StringFind(s, ".STK") >= 0 || StringFind(s, "STOCK") >= 0 || StringFind(s, "SHARE") >= 0)
      return NG_CLASS_STOCK;

   // remaining 6-letter patterns -> forex (EURUSD, GBPJPY, ...)
   if(StringLen(s) == 6)
      return NG_CLASS_FOREX;

   return NG_CLASS_OTHER;
}

string NgClassName(const ENUM_NG_SYMBOL_CLASS cls)
{
   switch(cls)
   {
      case NG_CLASS_FOREX : return "FOREX";
      case NG_CLASS_CRYPTO: return "CRYPTO";
      case NG_CLASS_GOLD  : return "GOLD/METAL";
      case NG_CLASS_OIL   : return "ENERGY/OIL";
      case NG_CLASS_INDEX : return "INDEX";
      case NG_CLASS_STOCK : return "STOCK";
      case NG_CLASS_USDT  : return "USDT-LINKED";
      default             : return "OTHER";
   }
}

//---- does this class trade through the weekend?
bool NgClassHasWeekend(const ENUM_NG_SYMBOL_CLASS cls)
{
   if(InpApplyGuardCrypto) return true; // treat as weekend-closed
   return (cls != NG_CLASS_CRYPTO && cls != NG_CLASS_USDT);
}

int NgClassMaxHoldBars(const ENUM_NG_SYMBOL_CLASS cls)
{
   switch(cls)
   {
      case NG_CLASS_FOREX : return InpMaxHoldForex;
      case NG_CLASS_CRYPTO: return InpMaxHoldCrypto;
      case NG_CLASS_GOLD  : return InpMaxHoldGold;
      case NG_CLASS_OIL   : return InpMaxHoldOil;
      case NG_CLASS_INDEX : return InpMaxHoldIndex;
      case NG_CLASS_STOCK : return InpMaxHoldStock;
      case NG_CLASS_USDT  : return InpMaxHoldCrypto;
      default             : return InpMaxHoldOther;
   }
}

//---- convert class H1-equivalent hold time into bars of the CURRENT timeframe
//     (H1=32 -> M15=128 bars, M5=384 bars, D1=3 bars ...)
int NgMaxHoldForCurrentTF()
{
   int base = NgClassMaxHoldBars(g_class);
   if(InpMaxHoldBars > 0) return InpMaxHoldBars;
   long sec   = PeriodSeconds(g_tf);
   long h1sec = 3600;
   if(sec <= 0) return base;
   double k   = (double)h1sec / (double)sec;   // bars per 1 H1-equivalent
   int bars   = (int)MathRound((double)base * k);
   if(bars < 3) bars = 3;
   return bars;
}

//====================================================================
//  TIMEFRAME / SESSION HELPERS
//====================================================================
ENUM_TIMEFRAMES NgPickStandardTF(const long targetSec)
{
   ENUM_TIMEFRAMES list[] = {PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5,PERIOD_M6,
                             PERIOD_M10,PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30,
                             PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,
                             PERIOD_H12,PERIOD_D1,PERIOD_W1,PERIOD_MN1};
   for(int i=0; i<ArraySize(list); i++)
      if((long)PeriodSeconds(list[i]) >= targetSec)
         return list[i];
   return PERIOD_MN1;
}

ENUM_TIMEFRAMES NgHTF()
{
   long curSec = (long)PeriodSeconds(g_tf);
   long target = curSec * InpHTFMultiplier;
   return NgPickStandardTF(target);
}

//---- detect broker server offset against GMT (hours)
int NgDetectServerOffset()
{
   if(InpServerGmtOffset != 999)
      return InpServerGmtOffset;
   datetime srv = TimeTradeServer();
   datetime gmt = TimeGMT();
   double diff  = (double)(srv - gmt) / 3600.0;
   int off      = (int)MathRound(diff);
   return off;
}

//---- server local clock parts
void NgServerNow(MqlDateTime &dt)
{
   TimeToStruct(TimeTradeServer(), dt);
}

bool NgIsFriday()
{
   MqlDateTime dt; NgServerNow(dt);
   return (dt.day_of_week == 5);
}

int NgServerMinutes()
{
   MqlDateTime dt; NgServerNow(dt);
   return dt.hour * 60 + dt.min;
}

bool NgInHourWindow(int hour, const int startH, const int endH)
{
   if(startH == endH) return false;
   int s = startH, e = endH;
   if(s < 0) s += 24; if(s > 23) s -= 24;
   if(e < 0) e += 24; if(e > 23) e -= 24;
   if(s <= e) return (hour >= s && hour < e);
   return (hour >= s || hour < e);   // window crosses midnight
}

//---- session converted from GMT hours to server hours using detected offset
bool NgInTradingSession()
{
   if(!InpSessionFilter) return true;
   int off = g_serverGmtOffset;
   MqlDateTime dt; NgServerNow(dt);
   int hSrv = dt.hour;

   int lonS = ((InpLondonStart + off) % 24 + 24) % 24;
   int lonE = ((InpLondonEnd   + off) % 24 + 24) % 24;
   int nyS  = ((InpNewYorkStart + off) % 24 + 24) % 24;
   int nyE  = ((InpNewYorkEnd   + off) % 24 + 24) % 24;

   // London session (wrap-safe)
   bool lon = false, ny = false;
   if(lonS <= lonE) lon = (hSrv >= lonS && hSrv < lonE);
   else             lon = (hSrv >= lonS || hSrv < lonE);
   if(nyS <= nyE)   ny  = (hSrv >= nyS && hSrv < nyE);
   else             ny  = (hSrv >= nyS || hSrv < nyE);
   return (lon || ny);
}

//---- US data blackout (approx, server time brackets - no external calendar)
bool NgInNewsBlackout()
{
   if(!InpNewsFilter) return false;
   if(InpAllowCryptoNews &&
      (g_class == NG_CLASS_CRYPTO || g_class == NG_CLASS_USDT))
      return false;

   MqlDateTime dt; NgServerNow(dt);
   int sH = InpNewsBlockStart, eH = InpNewsBlockEnd;
   if(NgIsFriday()) eH += InpNewsFridayExtendHours;

   int sMin = sH * 60 - InpNewsBracketMinutes;
   int eMin = eH * 60 + InpNewsBracketMinutes;
   int now  = dt.hour * 60 + dt.min;
   // wrap-safe compare (window may cross midnight only if extended)
   if(sMin <= eMin) return (now >= sMin && now <= eMin);
   return (now >= sMin || now <= eMin);
}

//---- rollover (swap) window, server time, wrap-safe
bool NgInRolloverWindow()
{
   MqlDateTime dt; NgServerNow(dt);
   return NgInHourWindow(dt.hour, InpRolloverStart, InpRolloverEnd);
}

//====================================================================
//  INDICATOR HELPERS
//====================================================================
double NgBuf(const int handle, const int buffer, const int shift)
{
   if(handle == INVALID_HANDLE) return EMPTY_VALUE;
   double v[1];
   if(CopyBuffer(handle, buffer, shift, 1, v) < 1) return EMPTY_VALUE;
   return v[0];
}

bool NgBufSeries(const int handle, const int buffer, const int total, double &arr[])
{
   if(handle == INVALID_HANDLE) return false;
   ArraySetAsSeries(arr, true);
   return (CopyBuffer(handle, buffer, 0, total, arr) == total);
}

//====================================================================
//  REGIME DETECTION  (Quiet / Normal / Volatile)
//====================================================================
// returns: 0=QUIET, 1=NORMAL, 2=VOLATILE
int NgDetectRegime()
{
   if(InpRegimeMode == NG_REGIME_ALWAYS) return 1;
   double atr[];
   int have = CopyBuffer(hATR, 0, 1, InpRegimeLookback, atr);
   if(have < InpRegimeLookback / 2) return 1;   // not enough data -> assume normal

   ArraySetAsSeries(atr, true);
   double vals[];
   int n = have;
   ArrayResize(vals, n);
   for(int i = 0; i < n; i++) vals[i] = atr[i];
   ArraySort(vals);

   double median = vals[n / 2];
   if(median <= 0.0) return 1;
   double cur = atr[1];
   if(cur <= 0.0) return 1;
   if(cur < InpQuietATRFactor * median)    return 0; // QUIET -> wait
   if(cur > InpVolatileATRFactor * median) return 2; // VOLATILE -> wait/range only
   return 1;
}

//====================================================================
//  SIGNAL ENGINE
//====================================================================
bool NgTrendUp(const int shift) // main TF + optional HTF alignment
{
   double f = NgBuf(hFastEMA, 0, shift);
   double s = NgBuf(hSlowEMA, 0, shift);
   if(f == EMPTY_VALUE || s == EMPTY_VALUE) return false;
   if(f <= s) return false;
   if(InpUseHTFAlignment)
   {
      double fh = NgBuf(hFastEMAH, 0, 1);
      double sh = NgBuf(hSlowEMAH, 0, 1);
      if(fh == EMPTY_VALUE || sh == EMPTY_VALUE) return false;
      if(fh <= sh) return false;
   }
   return true;
}

bool NgTrendDown(const int shift)
{
   double f = NgBuf(hFastEMA, 0, shift);
   double s = NgBuf(hSlowEMA, 0, shift);
   if(f == EMPTY_VALUE || s == EMPTY_VALUE) return false;
   if(f >= s) return false;
   if(InpUseHTFAlignment)
   {
      double fh = NgBuf(hFastEMAH, 0, 1);
      double sh = NgBuf(hSlowEMAH, 0, 1);
      if(fh == EMPTY_VALUE || sh == EMPTY_VALUE) return false;
      if(fh >= sh) return false;
   }
   return true;
}

//---- pullback touched EMA21/EMA55 or BB mid within window, candle closed in trend direction
bool NgPullbackLong()
{
   if(!NgTrendUp(1)) return false;
   double adx = NgBuf(hADX, 0, 1);
   double pdi = NgBuf(hADX, 1, 1);
   double mdi = NgBuf(hADX, 2, 1);
   if(adx == EMPTY_VALUE || pdi == EMPTY_VALUE || mdi == EMPTY_VALUE) return false;
   if(adx < g_genome.adxThreshold) return false;
   if(pdi <= mdi) return false;

   double rsi = NgBuf(hRSI, 0, 1);
   double macdM = NgBuf(hMACD, 0, 1);
   double macdS = NgBuf(hMACD, 1, 1);
   if(rsi == EMPTY_VALUE || macdM == EMPTY_VALUE || macdS == EMPTY_VALUE) return false;
   if(rsi < g_genome.rsiLevel) return false;
   if(macdM <= macdS) return false;

   double atr = NgBuf(hATR, 0, 1);
   if(atr == EMPTY_VALUE || atr <= 0.0) return false;

   double emaF[], emaS[], bbM[];
   int want = InpPullbackLookback + 2;
   if(!NgBufSeries(hFastEMA, 0, want, emaF)) return false;
   if(!NgBufSeries(hSlowEMA, 0, want, emaS)) return false;
   if(!NgBufSeries(hBB, 0, want, bbM)) return false;

   double tol = InpTouchToleranceATR * atr;
   bool touched = false;
   for(int i = 1; i <= InpPullbackLookback; i++)
   {
      double low  = iLow(g_symbol, g_tf, i);
      double cl   = iClose(g_symbol, g_tf, i);
      double op   = iOpen(g_symbol, g_tf, i);
      if(low <= 0.0 || cl <= 0.0) continue;
      if(low <= emaF[i] + tol || low <= emaS[i] + tol || low <= bbM[i] + tol)
         if(cl > op) // closed in trend direction
            touched = true;
   }
   if(!touched) return false;

   // anti-chase: don't buy far above fast EMA (wait for deeper pullback)
   double cl1 = iClose(g_symbol, g_tf, 1);
   if(cl1 <= 0.0) return false;
   if(cl1 - emaF[1] > InpMaxEntryDistanceATR * atr) return false;
   return true;
}

bool NgPullbackShort()
{
   if(!NgTrendDown(1)) return false;
   double adx = NgBuf(hADX, 0, 1);
   double pdi = NgBuf(hADX, 1, 1);
   double mdi = NgBuf(hADX, 2, 1);
   if(adx == EMPTY_VALUE || pdi == EMPTY_VALUE || mdi == EMPTY_VALUE) return false;
   if(adx < g_genome.adxThreshold) return false;
   if(mdi <= pdi) return false;

   double rsi = NgBuf(hRSI, 0, 1);
   double macdM = NgBuf(hMACD, 0, 1);
   double macdS = NgBuf(hMACD, 1, 1);
   if(rsi == EMPTY_VALUE || macdM == EMPTY_VALUE || macdS == EMPTY_VALUE) return false;
   if(rsi > g_genome.rsiLevel) return false;
   if(macdM >= macdS) return false;

   double atr = NgBuf(hATR, 0, 1);
   if(atr == EMPTY_VALUE || atr <= 0.0) return false;

   double emaF[], emaS[], bbM[];
   int want = InpPullbackLookback + 2;
   if(!NgBufSeries(hFastEMA, 0, want, emaF)) return false;
   if(!NgBufSeries(hSlowEMA, 0, want, emaS)) return false;
   if(!NgBufSeries(hBB, 0, want, bbM)) return false;

   double tol = InpTouchToleranceATR * atr;
   bool touched = false;
   for(int i = 1; i <= InpPullbackLookback; i++)
   {
      double hi  = iHigh(g_symbol, g_tf, i);
      double cl  = iClose(g_symbol, g_tf, i);
      double op  = iOpen(g_symbol, g_tf, i);
      if(hi <= 0.0 || cl <= 0.0) continue;
      if(hi >= emaF[i] - tol || hi >= emaS[i] - tol || hi >= bbM[i] - tol)
         if(cl < op)
            touched = true;
   }
   if(!touched) return false;

   double cl1 = iClose(g_symbol, g_tf, 1);
   if(cl1 <= 0.0) return false;
   if(emaF[1] - cl1 > InpMaxEntryDistanceATR * atr) return false;
   return true;
}

//====================================================================
//  GAP FILTER  (full ATR-based, all classes)
//====================================================================
bool NgHasGap()
{
   double o1 = iOpen(g_symbol, g_tf, 1);
   double c2 = iClose(g_symbol, g_tf, 2);
   if(o1 <= 0.0 || c2 <= 0.0) return false;
   double gap = MathAbs(o1 - c2);
   double atr = NgBuf(hATR, 0, 2);
   if(atr <= 0.0) return false;
   return (gap > 1.5 * atr);
}

//====================================================================
//  SIGNAL EVALUATION (called on new bar)
//====================================================================
bool NgEvaluateSignal(NG_Signal &sig)
{
   sig.dir = 0;
   sig.isRangeFade = false;

   int regime = NgDetectRegime();
   if(regime == 0) return false;                 // QUIET -> wait, never trade
   if(regime == 2 && !InpTradeVolatileRange) return false; // VOLATILE -> wait

   if(regime == 2)
   {
      // VOLATILE: range-fade only (Bollinger + RSI extremes), never breakout
      double bbL = NgBuf(hBB, 2, 1);
      double bbU = NgBuf(hBB, 1, 1);
      double rsi = NgBuf(hRSI, 0, 1);
      if(bbL == EMPTY_VALUE || bbU == EMPTY_VALUE || rsi == EMPTY_VALUE) return false;
      double cl = iClose(g_symbol, g_tf, 1);
      double op = iOpen(g_symbol, g_tf, 1);
      if(cl <= 0.0) return false;
      if(cl <= bbL && rsi <= InpRSIFadeBuy && cl > op && !NgHasGap())
      {
         sig.dir = 1; sig.isRangeFade = true; return true;
      }
      if(cl >= bbU && rsi >= InpRSIFadeSell && cl < op && !NgHasGap())
      {
         sig.dir = -1; sig.isRangeFade = true; return true;
      }
      return false;
   }

   // NORMAL regime: pullback continuation entries
   if(InpEntryMode == NG_ENTRY_PULLBACK)
   {
      if(NgPullbackLong())  { sig.dir = 1;  return true; }
      if(NgPullbackShort()) { sig.dir = -1; return true; }
      return false;
   }

   // TREND_ONLY mode (no pullback requirement)
   if(NgTrendUp(1) && !NgPullbackLong())
   {
      double rsi = NgBuf(hRSI, 0, 1);
      if(rsi != EMPTY_VALUE && rsi >= InpRSIMomentumLevel)
         { sig.dir = 1;  return true; }
   }
   if(NgTrendDown(1) && !NgPullbackShort())
   {
      double rsi = NgBuf(hRSI, 0, 1);
      if(rsi != EMPTY_VALUE && rsi <= InpRSIMomentumLevel)
         { sig.dir = -1; return true; }
   }
   return false;
}

//====================================================================
//  TRADING PRIMITIVES
//====================================================================
bool NgFillingOK(const ENUM_ORDER_TYPE_FILLING mode)
{
   long fill = SymbolInfoInteger(g_symbol, SYMBOL_FILLING_MODE);
   if(mode == ORDER_FILLING_FOK)   return ((fill & SYMBOL_FILLING_FOK) != 0);
   if(mode == ORDER_FILLING_IOC)   return ((fill & SYMBOL_FILLING_IOC) != 0);
   return true;   // RETURN / flexible: always allow the attempt
}

bool NgOpenPosition(const int dir, const double lots, const double sl, const double tp, const string cmt)
{
   if(lots <= 0.0) return false;
   bool ok = false;

   if(NgFillingOK(ORDER_FILLING_FOK))
   {
      trade.SetTypeFilling(ORDER_FILLING_FOK);
      ok = (dir > 0) ? trade.Buy(lots, g_symbol, 0.0, sl, tp, cmt)
                     : trade.Sell(lots, g_symbol, 0.0, sl, tp, cmt);
   }
   if(!ok && NgFillingOK(ORDER_FILLING_IOC))
   {
      trade.SetTypeFilling(ORDER_FILLING_IOC);
      ok = (dir > 0) ? trade.Buy(lots, g_symbol, 0.0, sl, tp, cmt)
                     : trade.Sell(lots, g_symbol, 0.0, sl, tp, cmt);
   }
   if(!ok && NgFillingOK(ORDER_FILLING_RETURN))
   {
      trade.SetTypeFilling(ORDER_FILLING_RETURN);
      ok = (dir > 0) ? trade.Buy(lots, g_symbol, 0.0, sl, tp, cmt)
                     : trade.Sell(lots, g_symbol, 0.0, sl, tp, cmt);
   }
   if(!ok)
   {
      if(g_alarmCooldownMinute != TimeCurrent() / 60)
      {
         NgError("Open failed dir=" + IntegerToString(dir) +
                 " rc=" + IntegerToString(trade.ResultRetcode()) +
                 " " + trade.ResultRetcodeDescription());
         g_alarmCooldownMinute = (int)(TimeCurrent() / 60);
      }
      return false;
   }
   g_ctOpen++;
   NgSound("open.trade");
   NgInfo("OPEN " + cmt + " | dir=" + (dir > 0 ? "BUY" : "SELL") +
          " lots=" + DoubleToString(lots, NgVolumeDigits()) +
          " price=" + DoubleToString(trade.ResultPrice(), _Digits) +
          " SL=" + DoubleToString(sl, _Digits) + " TP=" + DoubleToString(tp, _Digits));
   return true;
}

bool NgCloseTicket(const ulong ticket, const string reason)
{
   if(!PositionSelectByTicket(ticket)) return true;
   trade.PositionClose(ticket);
   bool ok = (trade.ResultRetcode() == TRADE_RETCODE_DONE);
   if(ok) NgInfo("CLOSE t=" + IntegerToString(ticket) + " | " + reason);
   else   NgWarn("Close failed t=" + IntegerToString(ticket) + " rc=" +
                 IntegerToString(trade.ResultRetcode()));
   return ok;
}

bool NgModifySL(const ulong ticket, const double newSL)
{
   if(!PositionSelectByTicket(ticket)) return false;
   double tp = PositionGetDouble(POSITION_TP);
   double oldSL = PositionGetDouble(POSITION_SL);
   double slNorm = NgNormPrice(newSL);
   if(MathAbs(slNorm - oldSL) < _Point) return true; // nothing to do
   bool ok = trade.PositionModify(ticket, slNorm, tp);
   if(ok) NgInfo("MOVE SL t=" + IntegerToString(ticket) + " -> " + DoubleToString(slNorm, _Digits));
   return ok;
}

bool NgClosePartial(const ulong ticket, const double volume)
{
   if(!PositionSelectByTicket(ticket)) return false;
   double cur = PositionGetDouble(POSITION_VOLUME);
   if(volume >= cur - 1e-9) return false;
   bool ok = trade.PositionClosePartial(ticket, volume);
   if(ok) NgInfo("PARTIAL t=" + IntegerToString(ticket) + " vol=" + DoubleToString(volume, NgVolumeDigits()));
   return ok;
}

//====================================================================
//  POSITION TRACKERS
//====================================================================
bool NgTrackerIndex(const ulong ticket, int &idx)
{
   idx = -1;
   for(int i = 0; i < ArraySize(g_positions); i++)
      if(g_positions[i].ticket == ticket) { idx = i; return true; }
   return false;
}

void NgTrackerAdd(const ulong ticket, const int dir)
{
   int n = ArraySize(g_positions);
   ArrayResize(g_positions, n + 1);
   g_positions[n].ticket = ticket;
   g_positions[n].dir = dir;
   g_positions[n].openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   g_positions[n].initialVolume = PositionGetDouble(POSITION_VOLUME);
   g_positions[n].atrAtEntry = NgBuf(hATR, 0, 1);
   if(g_positions[n].atrAtEntry <= 0.0) g_positions[n].atrAtEntry = _Point * 100;
   g_positions[n].initialSL = PositionGetDouble(POSITION_SL);
   g_positions[n].initialTP = PositionGetDouble(POSITION_TP);
   g_positions[n].openTime = (datetime)PositionGetInteger(POSITION_TIME);
   g_positions[n].partialDone = false;
   g_positions[n].beLocked = false;
   g_positions[n].fridayDone = false;
   g_positions[n].reverseDone = false;
   g_positions[n].ladderStep = 0;
   g_positions[n].genomeIdx = NgRecordFind(g_genome);
   if(g_positions[n].genomeIdx < 0)
   {
      NgRecordAdd(g_genome);
      g_positions[n].genomeIdx = ArraySize(g_records) - 1;
   }
}

void NgSyncTrackers()
{
   // remove trackers of closed positions (journal the close first)
   for(int i = ArraySize(g_positions) - 1; i >= 0; i--)
   {
      ulong t = g_positions[i].ticket;
      if(!PositionSelectByTicket(t))
      {
         NgJournalClosed(t);
         ArrayRemove(g_positions, i, 1);
         continue;
      }
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) { ArrayRemove(g_positions, i, 1); continue; }
   }
   // add new positions
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      int idx;
      if(!NgTrackerIndex(ticket, idx))
         NgTrackerAdd(ticket, (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1);
   }
}

int NgCountOpen()
{
   int cnt = 0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      cnt++;
   }
   return cnt;
}

double NgFloatingPL()
{
   double pl = 0.0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      pl += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   return pl;
}

//====================================================================
//  DAILY STATS (trades + loss limit)
//====================================================================
datetime NgDayStart()
{
   MqlDateTime dt; NgServerNow(dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   return StructToTime(dt);
}

bool NgHistoryDay(datetime &from, datetime &to)
{
   from = NgDayStart();
   to   = from + 86400;
   return HistorySelect(from, to);
}

double NgDayClosedPL()
{
   datetime from, to;
   if(!NgHistoryDay(from, to)) return 0.0;
   double pl = 0.0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != g_symbol) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagicNumber) continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
      pl += HistoryDealGetDouble(ticket, DEAL_PROFIT)
          + HistoryDealGetDouble(ticket, DEAL_COMMISSION)
          + HistoryDealGetDouble(ticket, DEAL_SWAP);
   }
   return pl;
}

int NgDayOpenCount()
{
   datetime from, to;
   if(!NgHistoryDay(from, to)) return 0;
   int cnt = 0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != g_symbol) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != InpMagicNumber) continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_IN)
         cnt++;
   }
   return cnt;
}

void NgRefreshDay()
{
   MqlDateTime dt; NgServerNow(dt);
   int key = (dt.year * 100 + dt.mon) * 100 + dt.day;
   if(key != g_dayKey)
   {
      g_dayKey = key;
      g_dayTrades = 0;
      g_haltToday = false;
      g_haltedDD = false;
      g_haltedGuard = false;
   }
   //--- weekly: re-detect server GMT offset (DST changes) + reset weekly halt
   int wk = NgWeekKeyInt();
   if(wk != g_weekKey)
   {
      g_weekKey = wk;
      g_weekHaltLocal = false;
      g_serverGmtOffset = NgDetectServerOffset();
      NgInfo("Week rollover -> server offset re-detected: " + IntegerToString(g_serverGmtOffset) + "h GMT");
   }
}

//====================================================================
//  ADAPTIVE AI ENGINE
//  - tunable genome mutated by small deltas after every evaluation
//  - only POSITIVE (profitable) candidate results are kept & promoted
//  - best genome auto-selected & persisted; entry/exit logic consumes it
//  - always clamped to safe bounds (never martingale / never reckless)
//====================================================================
void NgGenomeDefaults(NG_Genome &g)
{
   g.partialTriggerRR = InpPartialCloseAtRR;
   g.partialPct       = InpPartialClosePercent;
   g.beBufferATR      = InpBreakEvenBufferATR;
   g.trailStartRR     = InpTrailingStartATR;
   g.trailStepATR     = InpTrailingStepATR;
   g.slATR            = InpSL_ATR;
   g.tpATR            = InpTP_ATR;
   g.adxThreshold     = InpADXThreshold;
   g.rsiLevel         = InpRSIMomentumLevel;
}

void NgGenomeClamp(NG_Genome &g)
{
   if(g.partialTriggerRR < 0.60) g.partialTriggerRR = 0.60;
   if(g.partialTriggerRR > 1.80) g.partialTriggerRR = 1.80;
   if(g.partialPct < 20.0) g.partialPct = 20.0;
   if(g.partialPct > 70.0) g.partialPct = 70.0;
   if(g.beBufferATR < 0.03) g.beBufferATR = 0.03;
   if(g.beBufferATR > 0.30) g.beBufferATR = 0.30;
   if(g.trailStartRR < 0.80) g.trailStartRR = 0.80;
   if(g.trailStartRR > 3.00) g.trailStartRR = 3.00;
   if(g.trailStepATR < 0.20) g.trailStepATR = 0.20;
   if(g.trailStepATR > 1.50) g.trailStepATR = 1.50;
   if(g.slATR < 1.00) g.slATR = 1.00;
   if(g.slATR > 4.00) g.slATR = 4.00;
   if(g.tpATR < 1.50) g.tpATR = 1.50;
   if(g.tpATR > 6.00) g.tpATR = 6.00;
   if(g.adxThreshold < 16.0) g.adxThreshold = 16.0;
   if(g.adxThreshold > 32.0) g.adxThreshold = 32.0;
   if(g.rsiLevel < 40.0) g.rsiLevel = 40.0;
   if(g.rsiLevel > 60.0) g.rsiLevel = 60.0;
}

// small delta mutation: +/- n% of the range, always clamped
void NgGenomeMutate(NG_Genome &src, NG_Genome &dst, const int seed)
{
   dst = src;
   MathSrand(seed);
   dst.partialTriggerRR += (MathRand()/32767.0 - 0.5) * 0.20;
   dst.partialPct       += (MathRand()/32767.0 - 0.5) * 12.0;
   dst.beBufferATR      += (MathRand()/32767.0 - 0.5) * 0.08;
   dst.trailStartRR     += (MathRand()/32767.0 - 0.5) * 0.40;
   dst.trailStepATR     += (MathRand()/32767.0 - 0.5) * 0.30;
   dst.slATR            += (MathRand()/32767.0 - 0.5) * 0.60;
   dst.tpATR            += (MathRand()/32767.0 - 0.5) * 0.80;
   dst.adxThreshold     += (MathRand()/32767.0 - 0.5) * 3.0;
   dst.rsiLevel         += (MathRand()/32767.0 - 0.5) * 5.0;
   NgGenomeClamp(dst);
}

bool NgGenomeEqual(const NG_Genome &a, const NG_Genome &b)
{
   return (MathAbs(a.partialTriggerRR-b.partialTriggerRR) < 1e-6 &&
           MathAbs(a.partialPct-b.partialPct) < 1e-6 &&
           MathAbs(a.beBufferATR-b.beBufferATR) < 1e-6 &&
           MathAbs(a.trailStartRR-b.trailStartRR) < 1e-6 &&
           MathAbs(a.trailStepATR-b.trailStepATR) < 1e-6 &&
           MathAbs(a.slATR-b.slATR) < 1e-6 &&
           MathAbs(a.tpATR-b.tpATR) < 1e-6 &&
           MathAbs(a.adxThreshold-b.adxThreshold) < 1e-6 &&
           MathAbs(a.rsiLevel-b.rsiLevel) < 1e-6);
}

int NgRecordFind(const NG_Genome &g)
{
   for(int i = 0; i < ArraySize(g_records); i++)
      if(NgGenomeEqual(g_records[i].g, g)) return i;
   return -1;
}

void NgRecordAdd(const NG_Genome &g)
{
   int n = ArraySize(g_records);
   if(n >= 40)
   {
      ArrayRemove(g_records, 0, 1);
      n = ArraySize(g_records);
   }
   ArrayResize(g_records, n + 1);
   g_records[n].g = g;
   g_records[n].trades = 0;
   g_records[n].wins = 0;
   g_records[n].net = 0.0;
   g_records[n].peak = 0.0;
   g_records[n].dd = 0.0;
   g_records[n].score = 0.0;
   g_records[n].lastUsed = TimeCurrent();
   g_records[n].active = true;
}

// called on every CLOSED position: keeps only positive-performing genomes
void NgAdaptiveLearn(const int genomeIdx, const double profit, const double comm, const double swap)
{
   if(!InpAdaptiveEngine) return;
   if(MQLInfoInteger(MQL_TESTER)) return;        // tester keeps its own optimizer
   if(genomeIdx < 0 || genomeIdx >= ArraySize(g_records)) return;
   double net = profit + comm + swap;

   // index-based update (references to array elements are NOT allowed in MQL5)
   g_records[genomeIdx].trades++;
   if(net > 0.0) g_records[genomeIdx].wins++;
   g_records[genomeIdx].net += net;
   g_records[genomeIdx].peak += (net > 0.0 ? net : 0.0);
   if(g_records[genomeIdx].net < 0.0 && g_records[genomeIdx].net < -MathAbs(g_records[genomeIdx].peak) * 0.5)
      g_records[genomeIdx].active = false;       // disappointing genome: demoted
   // score: win-ratio-weighted PF * sqrt(trades) / dd
   double gpk = g_records[genomeIdx].peak;
   double gnt = g_records[genomeIdx].net;
   int    gtr = MathMax(g_records[genomeIdx].trades, 1);
   double pf  = (gpk > 0.0 && gnt > 0.0) ? gpk / MathMax(0.01, gpk - gnt - (gpk - gnt) * (1.0 - (double)g_records[genomeIdx].wins / gtr)) : 0.0;
   if(pf <= 0.0) pf = 0.0;
   double ddPct = (gpk > 0.0) ? MathMax(0.0, (gpk - gnt) / gpk * 100.0) : 0.0;
   g_records[genomeIdx].score = pf * MathSqrt((double)gtr) / (ddPct + 1.0);
   g_records[genomeIdx].lastUsed = TimeCurrent();
   g_tradesSinceEval++;
}

// evaluation: pick best ACTIVE, positive-genome record; switch with hysteresis
void NgAdaptiveEvaluate()
{
   if(!InpAdaptiveEngine) return;
   if(MQLInfoInteger(MQL_TESTER)) return;
   if(g_tradesSinceEval < InpAdaptiveEvalEvery) return;
   g_tradesSinceEval = 0;

   int bestIdx = -1;
   double bestScore = -1.0;
   for(int i = 0; i < ArraySize(g_records); i++)
   {
      if(!g_records[i].active) continue;
      if(g_records[i].trades < InpAdaptiveMinSamples) continue;
      if(g_records[i].net <= 0.0) continue;       // only POSITIVE results promoted
      if(g_records[i].score > bestScore)
      {
         bestScore = g_records[i].score;
         bestIdx = i;
      }
   }

   int curIdx = NgRecordFind(g_genome);
   double curScore = (curIdx >= 0) ? g_records[curIdx].score : 0.0;
   bool improve = (bestIdx >= 0 && bestScore > curScore * (1.0 + InpAdaptiveImprovePct/100.0));

   if(improve)
   {
      g_genome = g_records[bestIdx].g;
      g_adaptiveSwitches++;
      g_bestGenome = g_genome;
      g_bestScore = bestScore;
      g_adaptiveStatus = "OPTIMIZED";
      g_lastAdaptiveMsg = "switch #" + IntegerToString(g_adaptiveSwitches) +
                          " | score " + DoubleToString(bestScore, 2) +
                          " | T=" + IntegerToString(g_records[bestIdx].trades) +
                          " | partial@" + DoubleToString(g_genome.partialTriggerRR,2) + "R " +
                          DoubleToString(g_genome.partialPct,0) + "%" +
                          " | SL " + DoubleToString(g_genome.slATR,2) + "x TP " + DoubleToString(g_genome.tpATR,2) + "x" +
                          " | ADX " + DoubleToString(g_genome.adxThreshold,1) +
                          " | RSI " + DoubleToString(g_genome.rsiLevel,1);
      NgSound("adaptive.switch");
      NgInfo("ADAPTIVE: " + g_lastAdaptiveMsg);
      NgAdaptivePersistState();
   }
   else if(bestIdx >= 0)
   {
      g_adaptiveStatus = "LEARNING";
      g_lastAdaptiveMsg = "best score " + DoubleToString(bestScore, 2) +
                          " vs current " + DoubleToString(curScore, 2) + " (not enough edge yet)";
   }
   else
   {
      g_adaptiveStatus = "LEARNING";
      g_lastAdaptiveMsg = "insufficient positive samples (" + IntegerToString(g_tradesSinceEval) + ")";
   }
}

// ---- persistence (CSV): genome + records, survives restarts
void NgAdaptivePersistState()
{
   if(!InpAdaptivePersist) return;
   if(MQLInfoInteger(MQL_TESTER)) return;
   int h = FileOpen(NG_ADAPTIVE_FILE, FILE_WRITE | FILE_CSV | FILE_ANSI, ',');
   if(h == INVALID_HANDLE) return;
   FileWrite(h, "version", "1.02");
   FileWrite(h, "switches", IntegerToString(g_adaptiveSwitches));
   FileWrite(h, "bestScore", DoubleToString(g_bestScore, 4));
   FileWrite(h, "status", g_adaptiveStatus);
   FileWrite(h, "pTrig", DoubleToString(g_genome.partialTriggerRR, 3));
   FileWrite(h, "pPct",  DoubleToString(g_genome.partialPct, 1));
   FileWrite(h, "beBuf", DoubleToString(g_genome.beBufferATR, 3));
   FileWrite(h, "tStart", DoubleToString(g_genome.trailStartRR, 3));
   FileWrite(h, "tStep", DoubleToString(g_genome.trailStepATR, 3));
   FileWrite(h, "slATR", DoubleToString(g_genome.slATR, 3));
   FileWrite(h, "tpATR", DoubleToString(g_genome.tpATR, 3));
   FileWrite(h, "adxTh", DoubleToString(g_genome.adxThreshold, 2));
   FileWrite(h, "rsiLv", DoubleToString(g_genome.rsiLevel, 2));
   FileClose(h);
}

void NgAdaptiveLoadState()
{
   if(!InpAdaptivePersist) return;
   if(MQLInfoInteger(MQL_TESTER)) return;
   int h = FileOpen(NG_ADAPTIVE_FILE, FILE_READ | FILE_CSV | FILE_ANSI, ',');
   if(h == INVALID_HANDLE) return;
   string a, b;
   while(!FileIsEnding(h))
   {
      a = FileReadString(h);
      b = FileReadString(h);
      if(a == "switches") g_adaptiveSwitches = (int)StringToInteger(b);
      if(a == "bestScore") g_bestScore = StringToDouble(b);
      if(a == "status") g_adaptiveStatus = b;
      if(a == "pTrig") g_genome.partialTriggerRR = StringToDouble(b);
      if(a == "pPct")  g_genome.partialPct = StringToDouble(b);
      if(a == "beBuf") g_genome.beBufferATR = StringToDouble(b);
      if(a == "tStart") g_genome.trailStartRR = StringToDouble(b);
      if(a == "tStep") g_genome.trailStepATR = StringToDouble(b);
      if(a == "slATR") g_genome.slATR = StringToDouble(b);
      if(a == "tpATR") g_genome.tpATR = StringToDouble(b);
      if(a == "adxTh") g_genome.adxThreshold = StringToDouble(b);
      if(a == "rsiLv") g_genome.rsiLevel = StringToDouble(b);
   }
   FileClose(h);
   NgGenomeClamp(g_genome);
}

//====================================================================
//  PORTFOLIO HELPERS  (terminal-wide; live-only sharing)
//====================================================================
datetime NgWeekStart()
{
   MqlDateTime dt; NgServerNow(dt);
   int back = (dt.day_of_week == 0) ? 6 : (dt.day_of_week - 1); // Monday = week start
   datetime now = TimeTradeServer();
   datetime midnight = (datetime)(now - (dt.hour * 3600 + dt.min * 60 + dt.sec));
   return (datetime)(midnight - back * 86400);
}

int NgDayKeyInt()
{
   MqlDateTime dt; NgServerNow(dt);
   return (dt.year * 100 + dt.mon) * 100 + dt.day;
}

int NgWeekKeyInt()
{
   MqlDateTime dt; TimeToStruct(NgWeekStart(), dt);
   return (dt.year * 100 + dt.mon) * 100 + dt.day;
}

double NgClosedPLBetween(const datetime from, const datetime to)
{
   if(!HistorySelect(from, to)) return 0.0;
   double pl = 0.0;
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong t = HistoryDealGetTicket(i);
      if(t == 0) continue;
      if(HistoryDealGetString(t, DEAL_SYMBOL) != g_symbol) continue;
      if(HistoryDealGetInteger(t, DEAL_MAGIC) != InpMagicNumber) continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(t, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
      pl += HistoryDealGetDouble(t, DEAL_PROFIT)
          + HistoryDealGetDouble(t, DEAL_COMMISSION)
          + HistoryDealGetDouble(t, DEAL_SWAP);
   }
   return pl;
}

int NgClosedCountBetween(const datetime from, const datetime to)
{
   if(!HistorySelect(from, to)) return 0;
   int cnt = 0;
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong t = HistoryDealGetTicket(i);
      if(t == 0) continue;
      if(HistoryDealGetString(t, DEAL_SYMBOL) != g_symbol) continue;
      if(HistoryDealGetInteger(t, DEAL_MAGIC) != InpMagicNumber) continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(t, DEAL_ENTRY) == DEAL_ENTRY_IN) cnt++;
   }
   return cnt;
}

//---- share own day/week stats + aggregate ALL instances via terminal global variables
void NgPortfolioUpdate(bool &halt, bool &newHalt)
{
   halt = false; newHalt = false;
   if(MQLInfoInteger(MQL_TESTER)) return;            // tester: isolated local limits only
   if(!InpPortfolioSharing) return;

   string mk = IntegerToString(InpMagicNumber);
   datetime dayFrom = NgDayStart();
   datetime to      = TimeTradeServer() + 3600;
   datetime weekFrom = NgWeekStart();

   //--- publish own accumulators (per instance, keyed by magic)
   GlobalVariableSet(NG_GPFX + "DayKey_"    + mk, NgDayKeyInt());
   GlobalVariableSet(NG_GPFX + "DayPnl_"    + mk, NgClosedPLBetween(dayFrom, to));
   GlobalVariableSet(NG_GPFX + "DayTrades_" + mk, NgClosedCountBetween(dayFrom, to));
   GlobalVariableSet(NG_GPFX + "WeekKey_"   + mk, NgWeekKeyInt());
   GlobalVariableSet(NG_GPFX + "WeekPnl_"   + mk, NgClosedPLBetween(weekFrom, to));

   //--- aggregate across every instance
   double dayPnl = 0.0, weekPnl = 0.0;
   int    dayTrades = 0, weekTrades = 0;
   int total = GlobalVariablesTotal();
   for(int i = 0; i < total; i++)
   {
      string nm = GlobalVariableName(i);
      if(StringFind(nm, NG_GPFX + "DayPnl_") == 0)
      {
         string mk2 = StringSubstr(nm, StringLen(NG_GPFX) + StringLen("DayPnl_"));
         if((int)GlobalVariableGet(NG_GPFX + "DayKey_" + mk2) == NgDayKeyInt())
         {
            dayPnl += GlobalVariableGet(nm);
            dayTrades += (int)GlobalVariableGet(NG_GPFX + "DayTrades_" + mk2);
         }
      }
      if(StringFind(nm, NG_GPFX + "WeekPnl_") == 0)
      {
         string mk2 = StringSubstr(nm, StringLen(NG_GPFX) + StringLen("WeekPnl_"));
         if((int)GlobalVariableGet(NG_GPFX + "WeekKey_" + mk2) == NgWeekKeyInt())
         {
            weekPnl += GlobalVariableGet(nm);
         }
      }
   }

   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   if(bal <= 0.0) return;

   //--- day halt (auto reset on new day)
   int dayHaltKey = (int)GlobalVariableGet(NG_GPFX + "DayHaltKey");
   int dayHalt    = (int)GlobalVariableGet(NG_GPFX + "DayHalt");
   if(dayHaltKey != NgDayKeyInt())
   {
      dayHalt = 0;
      GlobalVariableSet(NG_GPFX + "DayHalt", 0);
      GlobalVariableSet(NG_GPFX + "DayHaltKey", NgDayKeyInt());
   }
   if(dayHalt == 0 && InpDailyLossLimitPercent > 0.0 &&
      dayPnl <= -bal * InpDailyLossLimitPercent / 100.0)
   {
      dayHalt = 1;
      GlobalVariableSet(NG_GPFX + "DayHalt", 1);
      GlobalVariableSet(NG_GPFX + "DayHaltKey", NgDayKeyInt());
      newHalt = true;
      NgNotify("PORTFOLIO DAILY LIMIT (" + DoubleToString(dayPnl, 2) +
               " across " + IntegerToString(dayTrades) + " trades) - closing all");
   }

   //--- week halt (auto reset on new week)
   int weekHaltKey = (int)GlobalVariableGet(NG_GPFX + "WeekHaltKey");
   int weekHalt    = (int)GlobalVariableGet(NG_GPFX + "WeekHalt");
   if(weekHaltKey != NgWeekKeyInt())
   {
      weekHalt = 0;
      GlobalVariableSet(NG_GPFX + "WeekHalt", 0);
      GlobalVariableSet(NG_GPFX + "WeekHaltKey", NgWeekKeyInt());
   }
   if(weekHalt == 0 && InpWeeklyLossLimitPercent > 0.0 &&
      weekPnl <= -bal * InpWeeklyLossLimitPercent / 100.0)
   {
      weekHalt = 1;
      GlobalVariableSet(NG_GPFX + "WeekHalt", 1);
      GlobalVariableSet(NG_GPFX + "WeekHaltKey", NgWeekKeyInt());
      newHalt = true;
      NgNotify("PORTFOLIO WEEKLY LIMIT (" + DoubleToString(weekPnl, 2) + ") - closing all");
   }

   halt = (dayHalt == 1 || weekHalt == 1);
}

//====================================================================
//  JOURNAL (CSV in MQL5/Files - imports into the dashboard)
//====================================================================
void NgNotify(const string msg)
{
   if(!InpNotifyOnGuards) return;
   if(MQLInfoInteger(MQL_TESTER)) return;
   SendNotification(NgLogTag() + msg);
}

bool NgDealSnapshot(const ulong positionTicket, double &profit, double &commission,
                    double &swap, double &closePrice, datetime &closeTime, double &closedVolume)
{
   if(!HistorySelectByPosition(positionTicket)) return false;
   bool found = false;
   for(int i = 0; i < HistoryDealsTotal(); i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
      profit     += HistoryDealGetDouble(d, DEAL_PROFIT);
      commission += HistoryDealGetDouble(d, DEAL_COMMISSION);
      swap       += HistoryDealGetDouble(d, DEAL_SWAP);
      closePrice  = HistoryDealGetDouble(d, DEAL_PRICE);
      closeTime   = (datetime)HistoryDealGetInteger(d, DEAL_TIME);
      closedVolume+= HistoryDealGetDouble(d, DEAL_VOLUME);
      found = true;
   }
   return found;
}

string NgCloseReason(const NG_Position &p, const double closePrice)
{
   if(p.dir > 0)
   {
      if(closePrice <= p.initialSL + _Point) return "SL";
      if(p.initialTP > 0.0 && closePrice >= p.initialTP - _Point) return "TP";
   }
   else
   {
      if(closePrice >= p.initialSL - _Point) return "SL";
      if(p.initialTP > 0.0 && closePrice <= p.initialTP + _Point) return "TP";
   }
   if(p.partialDone) return "PARTIAL+CLOSE";
   if(p.fridayDone)  return "FRIDAY-GUARD";
   if(p.rolloverDone)return "ROLLOVER-GUARD";
   return "MANUAL/OTHER";
}

void NgJournalClosed(const ulong ticket)
{
   if(!InpJournalCSV) return;
   if(MQLInfoInteger(MQL_TESTER)) return;   // tester has its own report
   int idx = -1;
   if(!NgTrackerIndex(ticket, idx)) return;
   NG_Position p = g_positions[idx];

   double profit = 0.0, comm = 0.0, swap = 0.0, closePrice = 0.0, vol = 0.0;
   datetime closeTime = 0;
   if(!NgDealSnapshot(ticket, profit, comm, swap, closePrice, closeTime, vol)) return;
   if(closeTime == 0) closeTime = TimeCurrent();
   string reason = NgCloseReason(p, closePrice);

   int h = FileOpen(NG_JOURNAL_FILE, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI, ',');
   if(h == INVALID_HANDLE)
   {
      if(!g_journalWarned)
      {
         g_journalWarned = true;
         NgWarn("Cannot open journal file " + NG_JOURNAL_FILE + " (check MQL5/Files permissions)");
      }
      return;
   }
   if(FileSize(h) == 0)
      FileWrite(h, "ticket", "symbol", "type", "size", "openTime", "openPrice",
                   "closeTime", "closePrice", "commission", "swap", "profit", "reason", "magic");
   FileSeek(h, 0, SEEK_END);
   FileWrite(h,
      (string)ticket,
      g_symbol,
      (p.dir > 0 ? "buy" : "sell"),
      DoubleToString(p.initialVolume, NgVolumeDigits()),
      TimeToString(p.openTime),
      DoubleToString(p.openPrice, _Digits),
      TimeToString(closeTime),
      DoubleToString(closePrice, _Digits),
      DoubleToString(comm, 2),
      DoubleToString(swap, 2),
      DoubleToString(profit, 2),
      reason,
      IntegerToString(InpMagicNumber));
   FileClose(h);
   g_ctClose++;
   NgInfo("JOURNAL: t=" + IntegerToString(ticket) + " " + reason +
          " pnl=" + DoubleToString(profit, 2));
   NgAdaptiveLearn(p.genomeIdx, profit, comm, swap);
   NgAdaptiveEvaluate();
}

//====================================================================
//  WEEKEND GUARD
//====================================================================
bool NgWeekendBlocked()
{
   if(!NgClassHasWeekend(g_class)) return false; // 24/7 crypto & no guard
   MqlDateTime dt; NgServerNow(dt);
   int dow = dt.day_of_week;

   if(dow == 6) return true; // Saturday: absolutely no new trades
   if(dow == 5) // Friday
   {
      if(dt.hour >= InpFridayCutoffHour) return true;
   }
   if(dow == 0) // Sunday: skip the reopen gap window
   {
      if(dt.hour * 60 + dt.min < InpSundayBlockMinutes) return true;
   }
   return false;
}

//---- execute Friday protection (close or breakeven) ahead of the gap
void NgFridayGuard()
{
   if(!NgClassHasWeekend(g_class)) return;
   MqlDateTime dt; NgServerNow(dt);
   if(dt.day_of_week != 5) return;
   int minNow = dt.hour * 60 + dt.min;
   int actionAt = InpFridayCutoffHour * 60 - InpFridayLeadMinutes;
   if(minNow < actionAt) return;

   for(int i = 0; i < ArraySize(g_positions); i++)
   {
      ulong t = g_positions[i].ticket;
      if(!PositionSelectByTicket(t)) continue;
      if(g_positions[i].fridayDone) continue;

      if(InpFridayAction == NG_FRIDAY_CLOSE_ALL)
      {
         if(NgCloseTicket(t, "FRIDAY GUARD :: close all before weekend"))
            g_positions[i].fridayDone = true;
      }
      else if(InpFridayAction == NG_FRIDAY_BREAKEVEN)
      {
         double open = PositionGetDouble(POSITION_PRICE_OPEN);
         double buf  = g_positions[i].atrAtEntry * InpBreakEvenBufferATR;
         double beSL = (g_positions[i].dir > 0) ? open + buf : open - buf;
         if(NgModifySL(t, beSL)) g_positions[i].fridayDone = true;
      }
      else // NG_FRIDAY_CLOSE_PROFIT_BE_LOSS
      {
         double pl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         if(pl > 0.0)
         {
            if(NgCloseTicket(t, "FRIDAY GUARD :: lock profit"))
               g_positions[i].fridayDone = true;
         }
         else
         {
            double open = PositionGetDouble(POSITION_PRICE_OPEN);
            double buf  = g_positions[i].atrAtEntry * InpBreakEvenBufferATR;
            double beSL = (g_positions[i].dir > 0) ? open + buf : open - buf;
            if(NgModifySL(t, beSL)) g_positions[i].fridayDone = true;
         }
      }
   }
}

//====================================================================
//  PROFIT LADDER  (4 degrees, auto-adaptive points -> snapshots the reference)
//====================================================================
int NgLadderRung(const int dir, const double entry, const double currentPrice)
{
   double pts = SymbolInfoDouble(g_symbol, SYMBOL_POINT);
   if(pts <= 0.0) return 0;
   double profit = (dir > 0) ? (currentPrice - entry) : (entry - currentPrice);
   double pPts = profit / pts;
   int done = 0;
   if(pPts >= InpLadderRung1Points) done = 1;
   if(pPts >= InpLadderRung2Points) done = 2;
   if(pPts >= InpLadderRung3Points) done = 3;
   if(pPts >= InpLadderRung4Points) done = 4;
   return done;
}

void NgExecuteLadder(const ulong ticket, NG_Position &pos, const int rung, const double currentPrice)
{
   if(!InpProfitLadderEnabled) return;
   if(rung <= pos.ladderStep) return;             // already executed
   if(!PositionSelectByTicket(ticket)) return;
   if(PositionGetInteger(POSITION_TICKET) != (long)ticket) return;

   double vol = PositionGetDouble(POSITION_VOLUME);
   double pct = 0.0;
   int points = 0;
   switch(rung)
   {
      case 1: pct = InpLadderRung1Percent; points = InpLadderRung1Points; break;
      case 2: pct = InpLadderRung2Percent; points = InpLadderRung2Points; break;
      case 3: pct = InpLadderRung3Percent; points = InpLadderRung3Points; break;
      case 4: pct = InpLadderRung4Percent; points = InpLadderRung4Points; break;
   }
   double closeVol = NgNormalizeVolume(vol * pct / 100.0);
   if(closeVol >= vol - 1e-9) closeVol = 0.0;     // never close the whole position here
   if(closeVol > 0.0 && NgClosePartial(ticket, closeVol))
   {
      pos.ladderStep = rung;
      g_ctPartial++;
      NgSound("partial.ladder");
      NgInfo("LADDER rung " + IntegerToString(rung) + " (+" + IntegerToString(points) +
             " pts) closed " + DoubleToString(pct, 0) + "%  vol=" + DoubleToString(closeVol, NgVolumeDigits()));
      // after any ladder rung: SL must be at/above entry (lock)
      if(InpBreakEvenAfterPartial)
      {
         double open = PositionGetDouble(POSITION_PRICE_OPEN);
         double atr  = pos.atrAtEntry;
         if(atr <= 0.0) atr = NgBuf(hATR, 0, 1);
         double buf  = g_genome.beBufferATR * atr;
         double beSL = (pos.dir > 0) ? open + buf : open - buf;
         if(NgModifySL(ticket, beSL))
         {
            pos.beLocked = true;
            g_ctBE++;
            NgSound("breakeven.lock");
         }
      }
   }
}

//====================================================================
//  EQUITY GUARD  (capital-protection card: loss/DD/free-margin floors)
//====================================================================
bool NgEquityGuardViolation(string &why)
{
   if(!InpEquityGuardEnabled) return false;
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   if(bal <= 0.0 || eq <= 0.0) return false;

   // free margin floor
   double free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double marginNow = AccountInfoDouble(ACCOUNT_MARGIN_USE);
   if(marginNow > 0.0)
   {
      double freePct = 100.0 * free / MathMax(bal, 1.0);
      if(freePct < InpGuardMinFreeMarginPct)
      {
         why = "FREE MARGIN " + DoubleToString(freePct, 1) + "% < " +
               DoubleToString(InpGuardMinFreeMarginPct, 0) + "%";
         return true;
      }
   }

   // max drawdown floor (from peak equity)
   if(g_peakEquity > 0.0)
   {
      double ddPct = 100.0 * (g_peakEquity - eq) / g_peakEquity;
      if(ddPct >= InpGuardMaxDrawdownPct)
      {
         why = "DRAWDOWN " + DoubleToString(ddPct, 1) + "% >= " +
               DoubleToString(InpGuardMaxDrawdownPct, 0) + "%";
         return true;
      }
   }

   // daily loss floor
   double dayLoss = NgDayClosedPL() + NgFloatingPL();
   double lim = bal * InpGuardDailyLossPct / 100.0;
   if(dayLoss <= -lim)
   {
      why = "DAY LOSS " + DoubleToString(dayLoss, 2) + " <= -" +
            DoubleToString(InpGuardDailyLossPct, 0) + "%";
      return true;
   }
   return false;
}

//====================================================================
//  POSITION MANAGEMENT (every tick)
//====================================================================
void NgManagePositions()
{
   for(int i = ArraySize(g_positions) - 1; i >= 0; i--)
   {
      ulong t = g_positions[i].ticket;
      if(!PositionSelectByTicket(t)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      double open     = g_positions[i].openPrice;
      double atr      = g_positions[i].atrAtEntry;
      int    dir      = g_positions[i].dir;
      double curSL    = PositionGetDouble(POSITION_SL);
      double vol      = PositionGetDouble(POSITION_VOLUME);
      double slDist   = MathAbs(open - curSL);
      double priceNow = (dir > 0) ? SymbolInfoDouble(g_symbol, SYMBOL_BID)
                                  : SymbolInfoDouble(g_symbol, SYMBOL_ASK);
      double profitDist = (dir > 0) ? (priceNow - open) : (open - priceNow);
      if(slDist <= 0.0 || atr <= 0.0) atr = NgBuf(hATR, 0, 1);

      //--- 0) PROFIT LADDER (4 adaptive degrees) - before any other exit logic
      if(InpProfitLadderEnabled)
      {
         int rung = NgLadderRung(dir, open, priceNow);
         NgExecuteLadder(t, g_positions[i], rung, priceNow);
         if(!PositionSelectByTicket(t)) continue;   // ladder may have changed volume
         vol = PositionGetDouble(POSITION_VOLUME);
      }

      //--- 1) partial at 1R -> immediate breakeven lock
      if(InpPartialCloseEnabled && !g_positions[i].partialDone)
      {
         double trigger = g_genome.partialTriggerRR * slDist;
         if(profitDist >= trigger && slDist > 0.0)
         {
            double partVol = NgNormalizeVolume(vol * g_genome.partialPct / 100.0);
            if(partVol < vol * 0.01) partVol = vol;
            if(partVol < vol - 1e-9 && NgClosePartial(t, partVol))
            {
               g_positions[i].partialDone = true;
               g_ctPartial++;
               NgSound("partial.done");
            }
            if(g_positions[i].partialDone && InpBreakEvenAfterPartial && !g_positions[i].beLocked)
            {
               double buf  = g_genome.beBufferATR * atr;
               double beSL = (dir > 0) ? open + buf : open - buf;
               if(NgModifySL(t, beSL))
               {
                  g_positions[i].beLocked = true;
                  g_ctBE++;
                  NgSound("breakeven.lock");
               }
            }
         }
      }

      //--- 1b) rollover/swap guard
      if(InpRolloverGuard && !g_positions[i].rolloverDone && NgInRolloverWindow())
      {
         double posSwap = PositionGetDouble(POSITION_SWAP);
         if(posSwap < InpRolloverSwapThreshold)
         {
            if(InpRolloverAction == NG_ROLLOVER_CLOSE)
            {
               if(NgCloseTicket(t, "ROLLOVER-GUARD (swap " + DoubleToString(posSwap, 2) + ")"))
               {
                  g_positions[i].rolloverDone = true;
                  g_ctGuard++;
                  NgSound("guard.rollover");
                  continue;
               }
            }
            else
            {
               double buf  = g_genome.beBufferATR * atr;
               double beSL = (dir > 0) ? open + buf : open - buf;
               if(NgModifySL(t, beSL))
               {
                  g_positions[i].rolloverDone = true;
                  g_ctGuard++;
                  NgSound("guard.rollover");
               }
            }
         }
      }

      //--- 2) TRAILING - 4 modes (ATR | POINTS | PERCENT | LADDER), auto-adaptive
      if(InpTrailingEnabled && !(InpTrailMode == NG_TRAIL_LADDER && !InpProfitLadderEnabled))
      {
         double startDist = g_genome.trailStartRR * atr;
         double stepDist  = g_genome.trailStepATR * atr;
         double desired = curSL;
         bool activate = false;

         switch(InpTrailMode)
         {
            case NG_TRAIL_POINTS:
            {
               double pPts = profitDist / SymbolInfoDouble(g_symbol, SYMBOL_POINT);
               if(pPts >= InpTrailFixedPoints)
               {
                  double stepPts = MathMax(20, InpTrailFixedPoints / 10);
                  desired = (dir > 0) ? (priceNow - stepPts * SymbolInfoDouble(g_symbol, SYMBOL_POINT))
                                      : (priceNow + stepPts * SymbolInfoDouble(g_symbol, SYMBOL_POINT));
                  activate = true;
               }
               break;
            }
            case NG_TRAIL_PERCENT:
            {
               double tpDist = g_genome.tpATR * atr;
               double pct = (tpDist > 0.0) ? 100.0 * profitDist / tpDist : 0.0;
               if(pct >= InpTrailPercentStep)
               {
                  desired = (dir > 0) ? (priceNow - stepDist) : (priceNow + stepDist);
                  activate = true;
               }
               break;
            }
            case NG_TRAIL_LADDER:
            {
               // trail rides on the highest executed ladder rung
               int rung = g_positions[i].ladderStep;
               if(rung > 0 && profitDist >= startDist)
               {
                  int basePts = 0;
                  if(rung == 1) basePts = InpLadderRung1Points;
                  if(rung == 2) basePts = InpLadderRung2Points;
                  if(rung == 3) basePts = InpLadderRung3Points;
                  if(rung == 4) basePts = InpLadderRung4Points;
                  double lockPts = SymbolInfoDouble(g_symbol, SYMBOL_POINT) * MathMax(15, basePts / 4);
                  desired = (dir > 0) ? (open + lockPts) : (open - lockPts);
                  activate = true;
               }
               break;
            }
            default: // NG_TRAIL_ATR
            {
               if(profitDist >= startDist && stepDist > 0.0)
               {
                  desired = (dir > 0) ? (priceNow - stepDist) : (priceNow + stepDist);
                  activate = true;
               }
               break;
            }
         }

         if(activate)
         {
            double floorSL = g_positions[i].initialSL;
            if(g_positions[i].partialDone && g_positions[i].beLocked)
               floorSL = (dir > 0) ? (open + g_genome.beBufferATR * atr)
                                   : (open - g_genome.beBufferATR * atr);
            bool improve = (dir > 0) ? (desired > floorSL + _Point) : (desired < floorSL - _Point);
            if(improve)
            {
               if((dir > 0 && desired > curSL + _Point) || (dir < 0 && desired < curSL - _Point))
               {
                  if(NgModifySL(t, desired))
                  {
                     g_ctTrail++;
                  }
               }
            }
         }
      }

      //--- 3) time-stop
      if(InpTimeExitEnabled)
      {
         int maxBars = NgMaxHoldForCurrentTF();
         long barSec = PeriodSeconds(g_tf);
         if(barSec > 0 && maxBars > 0)
         {
            long held = (long)(TimeCurrent() - g_positions[i].openTime);
            if(held >= (long)maxBars * barSec)
            {
               NgCloseTicket(t, "TIME-STOP (max hold " + IntegerToString(maxBars) + " bars)");
               continue;
            }
         }
      }

      //--- 4) exit on opposite signal (optional)
      if(InpReverseSignalExit && !g_positions[i].reverseDone)
      {
         double emaF = NgBuf(hFastEMA, 0, 1);
         double emaS = NgBuf(hSlowEMA, 0, 1);
         if(emaF != EMPTY_VALUE && emaS != EMPTY_VALUE)
         {
            if(dir > 0 && emaF < emaS)
            {
               NgCloseTicket(t, "REVERSE SIGNAL (trend flipped down)");
               g_positions[i].reverseDone = true;
               continue;
            }
            if(dir < 0 && emaF > emaS)
            {
               NgCloseTicket(t, "REVERSE SIGNAL (trend flipped up)");
               g_positions[i].reverseDone = true;
               continue;
            }
         }
      }
   }
}

//====================================================================
//  DAILY LOSS LIMIT + GLOBAL DD STOP + HALT
//====================================================================
void NgProtectionLayer()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0.0) return;

   //--- Equity Guard (daily loss / max DD / free-margin floors)
   string guardWhy = "";
   if(NgEquityGuardViolation(guardWhy) && !g_haltedGuard)
   {
      NgCloseEvery("EQUITY GUARD :: " + guardWhy);
      g_haltedGuard = true;
      g_ctGuard++;
      NgSound("guard.equity");
      NgWarn("EQUITY GUARD triggered: " + guardWhy + " - all positions closed, trading halted");
   }

   //--- global drawdown stop from peak equity
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity > g_peakEquity) g_peakEquity = equity;
   if(InpGlobalDrawdownStopPercent > 0.0 && g_peakEquity > 0.0 && !g_haltedDD)
   {
      double dd = 100.0 * (g_peakEquity - equity) / g_peakEquity;
      if(dd >= InpGlobalDrawdownStopPercent)
      {
         NgCloseEvery("GLOBAL DD STOP (" + DoubleToString(dd, 2) + "%)");
         g_haltedDD = true;
         NgWarn("Trading halted for the day - global drawdown stop reached");
      }
   }

   //--- daily loss limit (per symbol; portfolio-wide limit handled in NgPortfolioUpdate)
   if(InpDailyLossLimitPercent > 0.0 && !g_haltToday)
   {
      double loss = NgDayClosedPL() + NgFloatingPL();
      double limit = balance * InpDailyLossLimitPercent / 100.0;
      if(loss <= -limit)
      {
         NgCloseEvery("DAILY LOSS LIMIT (" + DoubleToString(loss, 2) + ")");
         g_haltToday = true;
         NgWarn("Trading halted for today - daily loss limit reached");
         NgNotify("DAILY LOSS LIMIT reached (" + DoubleToString(loss, 2) + ")");
      }
   }

   //--- weekly loss limit (fallback when portfolio sharing is off or in the tester)
   if(InpWeeklyLossLimitPercent > 0.0 && !g_weekHaltLocal)
   {
      double wLoss = NgClosedPLBetween(NgWeekStart(), TimeTradeServer() + 3600) + NgFloatingPL();
      double wLimit = balance * InpWeeklyLossLimitPercent / 100.0;
      if(wLoss <= -wLimit)
      {
         NgCloseEvery("WEEKLY LOSS LIMIT (" + DoubleToString(wLoss, 2) + ")");
         g_weekHaltLocal = true;
         NgWarn("Trading halted for this week - weekly loss limit reached");
         NgNotify("WEEKLY LOSS LIMIT reached (" + DoubleToString(wLoss, 2) + ")");
      }
   }
}

void NgCloseEvery(const string reason)
{
   int total = PositionsTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
      NgCloseTicket(ticket, reason);
   }
}

//====================================================================
//  SPREAD FILTER
//====================================================================
bool NgSpreadOK()
{
   double bid = SymbolInfoDouble(g_symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(g_symbol, SYMBOL_ASK);
   if(bid <= 0.0 || ask <= 0.0) return false;
   double spreadPrice = ask - bid;
   double point = SymbolInfoDouble(g_symbol, SYMBOL_POINT);
   if(point <= 0.0) return true;

   if(InpMaxSpreadPoints > 0)
   {
      long spreadPts = (long)MathRound(spreadPrice / point);
      return (spreadPts <= InpMaxSpreadPoints);
   }
   double atr = NgBuf(hATR, 0, 1);
   if(atr <= 0.0) return true;
   return (spreadPrice <= InpMaxSpreadATRFactor * atr);
}

//====================================================================
//  ON-CHART PANEL
//====================================================================
//====================================================================
//  NG DASHBOARD  (bitmap logo + gradient cards + live state)
//  corner-anchored overlay: never scales or scrolls the chart
//====================================================================
color NgMix(const int step, const int max)
{
   // cyan -> magenta -> gold soft gradient (RGB lerp, clamped)
   double k = (max > 0) ? (double)step / (double)max : 0.0;
   if(k < 0.0) k = 0.0;
   if(k > 1.0) k = 1.0;
   int r = 34 + (int)((251 - 34) * k);
   int g = 211 + (int)((110 - 211) * k);
   int b = 238 + (int)((36  - 238) * k);
   return (color)((r << 16) | (g << 8) | b);
}

void NgObjLabel(const string name, const int x, const int y, const string text,
                const color col, const int size, const bool right=false)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI");
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_RIGHT);
}

void NgObjRect(const string name, const int x, const int y, const int wdt, const int hgt,
               const color bg, const color border)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, wdt);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, hgt);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
}

// small "pill": rectangle + centered text label (uses two objects)
void NgObjPill(const string name, const int x, const int y, const int wdt, const int hgt,
               const string text, const color col, const bool on)
{
   color bg = on ? col : (color)C'15,30,50';
   color br = on ? col : (color)C'40,60,90';
   color fg = on ? (color)C'4,10,20' : (color)C'110,140,170';
   NgObjRect(name + "_B", x, y, wdt, hgt, bg, br);
   NgObjLabel(name + "_T", x + wdt - 6, y + 3, text, fg, on ? 9 : 8, true);
}

void NgDrawPanel(const int regime, const bool spreadOK, const bool newsBlocked, const bool sessionOK)
{
   if(!InpShowPanel) return;

   const int W  = 344;                  // panel width (px) - right anchored
   const int X0 = 6;                    // distance of panel right edge from chart right
   const int C  = X0 + 6;               // X for titles (near right edge)
   int y = 4;

   // ================= HEADER : BITMAP LOGO + NAME =================
   if(ObjectFind(0, "NGP_LOGO") < 0)
   {
      ObjectCreate(0, "NGP_LOGO", OBJ_BITMAP_LABEL, 0, 0, 0);
      ObjectSetString(0, "NGP_LOGO", OBJPROP_BMPFILE, "Images\\NovaGravity_Logo.bmp");
   }
   ObjectSetInteger(0, "NGP_LOGO", OBJPROP_XDISTANCE, X0);
   ObjectSetInteger(0, "NGP_LOGO", OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, "NGP_LOGO", OBJPROP_XSIZE, 44);
   ObjectSetInteger(0, "NGP_LOGO", OBJPROP_YSIZE, 44);
   ObjectSetInteger(0, "NGP_LOGO", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, "NGP_LOGO", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "NGP_LOGO", OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, "NGP_LOGO", OBJPROP_BACK, false);

   NgObjLabel("NGP_NAMET",  52, y + 1,  "NOVA GRAVITY AI", clrAqua, 14, false);
   NgObjLabel("NGP_NAMET2", 52, y + 20, "PROFIT ENGINE  |  v1.02", clrMagenta, 9, false);
   y += 50;

   // ================= STATUS ROW =================
   bool halted = (g_haltToday || g_haltedDD || g_haltedGuard || g_pfHalt);
   double eqNow = AccountInfoDouble(ACCOUNT_EQUITY);
   bool inDD = (g_peakEquity > 0.0 && eqNow < g_peakEquity);
   color statCol = halted ? clrOrangeRed : (inDD ? clrGold : clrLimeGreen);
   NgObjPill("NGP_STAT", X0, y, 78, 20, (halted ? "HALTED" : "RUNNING"), statCol, true);
   NgObjLabel("NGP_SYMT", X0 + 88, y + 3, g_symbol + " | " + EnumToString(g_tf) + " | " + g_className +
              " | " + (regime == 0 ? "QUIET" : (regime == 2 ? "VOLATILE" : "NORMAL")), clrWhite, 9, false);
   y += 26;

   // ================= CARD HELPERS =================
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double ddPct  = (g_peakEquity > 0.0) ? 100.0*(g_peakEquity-eqNow)/g_peakEquity : 0.0;
   double dayPL  = NgDayClosedPL() + NgFloatingPL();
   double dayPct = (bal > 0.0) ? -100.0*dayPL/bal : 0.0;
   double freePct = (bal > 0.0) ? 100.0*AccountInfoDouble(ACCOUNT_MARGIN_FREE)/bal : 0.0;
   double marginLvl = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);

   // ================= 1) EQUITY GUARD =================
   NgObjRect("NGP_EG", X0, y, W, 40, (color)C'10,24,42', (color)C'34,211,238');
   NgObjLabel("NGP_EG_T", C, y + 3, "EQUITY GUARD  [ ! ]", (color)C'34,211,238', 10, false);
   NgObjLabel("NGP_EG_D", C,  y + 19, "DAY LOSS  %" + DoubleToString(dayPct,1) + "  of  " + DoubleToString(InpGuardDailyLossPct,0) + "%",
              (dayPct >= InpGuardDailyLossPct*0.8 ? (color)C'251,113,133' : (color)C'52,211,153'), 8, false);
   NgObjLabel("NGP_EG_DD", 118, y + 19, "DD  %" + DoubleToString(ddPct,1) + "  of  " + DoubleToString(InpGuardMaxDrawdownPct,0) + "%",
              (ddPct >= InpGuardMaxDrawdownPct*0.8 ? (color)C'251,113,133' : (color)C'251,191,36'), 8, false);
   NgObjLabel("NGP_EG_M", 190, y + 19, "MARGIN  %" + DoubleToString(freePct,1) + "  of  " + DoubleToString(InpGuardMinFreeMarginPct,0) + "%",
              (freePct < InpGuardMinFreeMarginPct*1.5 ? (color)C'251,191,36' : (color)C'52,211,153'), 8, false);
   y += 46;

   // ================= 2) LIVE ALERTS =================
   NgObjRect("NGP_AL", X0, y, W, 92, (color)C'10,24,42', (color)C'232,121,249');
   NgObjLabel("NGP_AL_T", C, y + 3, "LIVE ALERTS", (color)C'232,121,249', 10, false);
   int ax[3] = {X0 + 4, X0 + 4 + 112, X0 + 4 + 224};
   int ay[2] = {y + 20, y + 52};
   int counts[6] = {g_ctOpen, g_ctClose, g_ctPartial, g_ctBE, g_ctTrail, g_ctGuard};
   string labs[6] = {"OPEN", "CLOSE", "PARTIAL", "BREAKEVEN", "TRAIL", "GUARD"};
   color  cols[6] = {(color)C'52,211,153', (color)C'251,113,133', (color)C'251,191,36',
                     (color)C'34,211,238', (color)C'167,139,250', (color)C'232,121,249'};
   for(int r2 = 0; r2 < 2; r2++)
   {
      for(int c2 = 0; c2 < 3; c2++)
      {
         int idx = r2*3 + c2;
         string nm = "NGP_AL_" + IntegerToString(r2) + "_" + IntegerToString(c2);
         NgObjRect(nm+"_B", ax[c2], ay[r2], 104, 27, (color)C'14,32,56', (color)C'40,70,110');
         NgObjLabel(nm+"_V", ax[c2]+98, ay[r2]+2, IntegerToString(counts[idx]), cols[idx], 12, true);
         NgObjLabel(nm+"_L", ax[c2]+98, ay[r2]+16, labs[idx], (color)C'127,156,192', 8, true);
      }
   }
   y += 98;

   // ================= 3) TRAILING STEP (3 stages) =================
   NgObjRect("NGP_TR", X0, y, W, 92, (color)C'10,24,42', (color)C'251,191,36');
   NgObjLabel("NGP_TR_T", C, y + 3, "TRAILING STEP - PROFIT PROTECT", (color)C'251,191,36', 10, false);
   string stag[3] = {"1-PARTIAL", "2-BREAKEVEN", "3-TRAIL"};
   string sv1[3] = {DoubleToString(g_genome.partialTriggerRR,2) + "R",
                    DoubleToString(g_genome.beBufferATR,2) + "x ATR",
                    "start " + DoubleToString(g_genome.trailStartRR,2) + "R"};
   string sv2[3] = {DoubleToString(g_genome.partialPct,0) + "%",
                    "lock +3 pts",
                    "step " + DoubleToString(g_genome.trailStepATR,2) + "x"};
   color  scol[3] = {(color)C'52,211,153', (color)C'34,211,238', (color)C'232,121,249'};
   for(int c2 = 0; c2 < 3; c2++)
   {
      string nm = "NGP_TR_" + IntegerToString(c2);
      NgObjRect(nm+"_B", ax[c2], y+18, 104, 66, (color)C'14,32,56', scol[c2]);
      NgObjLabel(nm+"_T", ax[c2]+98, y+21, stag[c2], scol[c2], 9, true);
      NgObjLabel(nm+"_1", ax[c2]+98, y+36, sv1[c2], clrWhite, 8, true);
      NgObjLabel(nm+"_2", ax[c2]+98, y+51, sv2[c2], (color)C'217,236,255', 8, true);
      NgObjLabel(nm+"_3", ax[c2]+98, y+66, (c2==2 ? "ACTIVE" : "ACTIVE"), (color)C'127,156,192', 8, true);
   }
   y += 98;

   // ================= 4) FOUR TRAIL MODES =================
   NgObjLabel("NGP_TM_T", C, y, "TRAIL MODES", (color)C'167,139,250', 10, false);
   y += 17;
   string modeN[4] = {"ATR", "POINTS", "PERCENT", "LADDER"};
   color  modeC[4] = {(color)C'34,211,238', (color)C'52,211,153', (color)C'251,191,36', (color)C'232,121,249'};
   for(int c2 = 0; c2 < 4; c2++)
   {
      string nm = "NGP_TM_" + IntegerToString(c2);
      bool on = (InpTrailMode == (ENUM_NG_TRAIL_MODE)c2);
      NgObjPill(nm, X0 + c2*84, y, 78, 17, modeN[c2], modeC[c2], on);
   }
   y += 23;

   // ================= 5) PROFIT LADDER =================
   NgObjLabel("NGP_LD_T", C, y, "PROFIT LADDER", (color)C'251,191,36', 10, false);
   y += 17;
   string lpN[4] = {"1", "2", "3", "4"};
   int    lpPts[4] = {InpLadderRung1Points, InpLadderRung2Points, InpLadderRung3Points, InpLadderRung4Points};
   double lpPct[4] = {InpLadderRung1Percent, InpLadderRung2Percent, InpLadderRung3Percent, InpLadderRung4Percent};
   color  lpCol[4] = {(color)C'52,211,153', (color)C'34,211,238', (color)C'232,121,249', (color)C'251,191,36'};
   int maxRung = 0;
   for(int i = 0; i < ArraySize(g_positions); i++)
      if(g_positions[i].ladderStep > maxRung) maxRung = g_positions[i].ladderStep;
   for(int c2 = 0; c2 < 4; c2++)
   {
      string nm = "NGP_LD_" + IntegerToString(c2);
      bool on = (maxRung >= c2+1);
      NgObjRect(nm+"_B", X0 + c2*84, y, 78, 40, on ? (color)C'20,48,40' : (color)C'14,32,56', lpCol[c2]);
      NgObjLabel(nm+"_N", X0 + c2*84 + 72, y+1, lpN[c2], lpCol[c2], 10, true);
      NgObjLabel(nm+"_P", X0 + c2*84 + 72, y+16, IntegerToString(lpPts[c2]) + " -> " + IntegerToString((int)lpPct[c2]) + "%", clrWhite, 9, true);
      NgObjLabel(nm+"_S", X0 + c2*84 + 72, y+29, on ? "DONE" : "WAIT", (color)C'127,156,192', 8, true);
   }
   y += 46;

   // ================= 6) ADAPTIVE AI ENGINE =================
   NgObjRect("NGP_AD", X0, y, W, 64, (color)C'10,24,42', (color)C'167,139,250');
   NgObjLabel("NGP_AD_T", C, y + 3, "ADAPTIVE AI ENGINE", (color)C'167,139,250', 10, false);
   NgObjLabel("NGP_AD_S", 210, y + 4, g_adaptiveStatus, (g_adaptiveStatus=="OPTIMIZED" ? clrLimeGreen : (color)C'167,139,250'), 8, true);
   NgObjLabel("NGP_AD_1", C, y+20, "partial " + DoubleToString(g_genome.partialTriggerRR,2) + "R | " +
              DoubleToString(g_genome.partialPct,0) + "% | BE " + DoubleToString(g_genome.beBufferATR,2) + "x",
              (color)C'217,236,255', 8, false);
   NgObjLabel("NGP_AD_2", C, y+36, "SL " + DoubleToString(g_genome.slATR,2) + "x | TP " + DoubleToString(g_genome.tpATR,2) +
              "x | ADX " + DoubleToString(g_genome.adxThreshold,1) + " | RSI " + DoubleToString(g_genome.rsiLevel,1),
              (color)C'217,236,255', 8, false);
   NgObjLabel("NGP_AD_3", C, y+51, "switches " + IntegerToString(g_adaptiveSwitches) + " | " + g_lastAdaptiveMsg,
              (color)C'127,156,192', 8, false);
   y += 70;

   // ================= 7) ACCOUNT | SETTINGS =================
   NgObjRect("NGP_AC", X0, y, W, 74, (color)C'10,24,42', (color)C'52,211,153');
   NgObjLabel("NGP_AC_T", C, y + 3, "ACCOUNT | SETTINGS", (color)C'52,211,153', 10, false);
   NgObjLabel("NGP_AC_1", C,  y+21, "BALANCE  " + DoubleToString(bal,2), (color)C'251,191,36', 8, false);
   NgObjLabel("NGP_AC_2", C,  y+37, "EQUITY   " + DoubleToString(eqNow,2), (color)C'52,211,153', 8, false);
   NgObjLabel("NGP_AC_3", C,  y+53, "FREE MARGIN  " + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE),2), (color)C'34,211,238', 8, false);
   NgObjLabel("NGP_AC_4", 160, y+21, "MARGIN L  " + (marginLvl>0 ? DoubleToString(marginLvl,1)+"%" : "n/a"), (color)C'232,121,249', 8, true);
   NgObjLabel("NGP_AC_5", 160, y+37, "LOT " + DoubleToString(InpFixedLots,2) + " | MAGIC " + IntegerToString(InpMagicNumber), clrWhite, 8, true);
   NgObjLabel("NGP_AC_6", 160, y+53, "RISK " + DoubleToString(InpRiskPercent,1) + "% | SPREAD " + (spreadOK ? "OK" : "HIGH"),
              spreadOK ? clrLimeGreen : (color)C'251,113,133', 8, true);
   y += 80;

   // ================= FOOTER =================
   NgObjLabel("NGP_FT", C, y, "SOUND " + (InpSoundAlerts ? "ON" : "OFF") +
              " | NEWS " + (newsBlocked ? "BLOCK" : "CLEAR") +
              " | SESS " + (sessionOK ? "OPEN" : "CLOSED") +
              " | " + TimeToString(TimeTradeServer(), TIME_DATE|TIME_MINUTES),
              (color)C'127,156,192', 8, false);
}

//====================================================================
//  EXPERTS EVENTS
//====================================================================
int OnInit()
{
   //--- resolved symbol & timeframe (auto = chart symbol / chart TF)
   if(StringLen(InpSymbolOverride) > 0 && SymbolSelect(InpSymbolOverride, true))
      g_symbol = InpSymbolOverride;
   else
      g_symbol = _Symbol;

   if(InpAutoDetectTimeframe || InpTimeframeOverride == PERIOD_CURRENT)
      g_tf = (ENUM_TIMEFRAMES)_Period;
   else
      g_tf = InpTimeframeOverride;

   g_tfHTF = NgHTF();

   //--- symbol class
   if(StringLen(InpClassOverride) > 0)
   {
      string s = NgToUpper(InpClassOverride);
      if(StringFind(s, "FOREX") >= 0)     g_class = NG_CLASS_FOREX;
      else if(StringFind(s, "CRYPTO") >= 0) g_class = NG_CLASS_CRYPTO;
      else if(StringFind(s, "GOLD") >= 0)   g_class = NG_CLASS_GOLD;
      else if(StringFind(s, "OIL") >= 0)    g_class = NG_CLASS_OIL;
      else if(StringFind(s, "INDEX") >= 0)  g_class = NG_CLASS_INDEX;
      else if(StringFind(s, "STOCK") >= 0 || StringFind(s, "STOCKS") >= 0) g_class = NG_CLASS_STOCK;
      else if(StringFind(s, "USDT") >= 0)   g_class = NG_CLASS_USDT;
      else g_class = (InpAutoClass ? NgDetectClass(g_symbol) : NG_CLASS_OTHER);
   }
   else
      g_class = (InpAutoClass ? NgDetectClass(g_symbol) : NG_CLASS_OTHER);
   g_className = NgClassName(g_class);

   g_serverGmtOffset = NgDetectServerOffset();

   //--- allowed trading? (in the Strategy Tester these flags are not applicable)
   if(!MQLInfoInteger(MQL_TESTER))
   {
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      {
         NgError("Algo-trading for the terminal is disabled. Enable Tools > Options > Expert Advisors.");
         return INIT_FAILED;
      }
      if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
      {
         NgError("Algo-trading for this chart is disabled (AutoTrading button).");
         return INIT_FAILED;
      }
   }

   //--- indicators
   hFastEMA = iMA(g_symbol, g_tf, InpFastEMA, 0, MODE_SMA, PRICE_CLOSE);
   hSlowEMA = iMA(g_symbol, g_tf, InpSlowEMA, 0, MODE_SMA, PRICE_CLOSE);
   hRSI     = iRSI(g_symbol, g_tf, InpRSIPeriod, PRICE_CLOSE);
   hMACD    = iMACD(g_symbol, g_tf, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
   hADX     = iADX(g_symbol, g_tf, InpADXPeriod);
   hATR     = iATR(g_symbol, g_tf, InpATRPeriod);
   hBB      = iBands(g_symbol, g_tf, InpBBPeriod, 0, InpBBDev, PRICE_CLOSE);
   if(InpUseHTFAlignment)
   {
      hFastEMAH = iMA(g_symbol, g_tfHTF, InpFastEMA, 0, MODE_SMA, PRICE_CLOSE);
      hSlowEMAH = iMA(g_symbol, g_tfHTF, InpSlowEMA, 0, MODE_SMA, PRICE_CLOSE);
   }

   if(hFastEMA == INVALID_HANDLE || hSlowEMA == INVALID_HANDLE || hRSI == INVALID_HANDLE ||
      hMACD == INVALID_HANDLE || hADX == INVALID_HANDLE || hATR == INVALID_HANDLE ||
      hBB == INVALID_HANDLE)
   {
      NgError("Indicator initialization failed - wrong symbol/timeframe or insufficient history.");
      return INIT_FAILED;
   }

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.LogLevel(LOG_LEVEL_ERRORS);

   g_peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_lastBarTime = iTime(g_symbol, g_tf, 0);

   //--- adaptive engine boot
   NgGenomeDefaults(g_genome);
   NgGenomeDefaults(g_bestGenome);
   if(InpAdaptiveReset) FileDelete(NG_ADAPTIVE_FILE);
   NgAdaptiveLoadState();
   NgRecordAdd(g_genome);
   g_adaptiveInitialized = true;
   if(g_bestScore > 0.0)
      NgInfo("ADAPTIVE: restored best score " + DoubleToString(g_bestScore, 2) +
             " | switches=" + IntegerToString(g_adaptiveSwitches));
   else
      NgInfo("ADAPTIVE: fresh learning loop (evaluate every " +
             IntegerToString(InpAdaptiveEvalEvery) + " closed trades)");

   NgInfo("INIT OK | symbol=" + g_symbol + " class=" + g_className +
          " TF=" + EnumToString(g_tf) + " HTF=" + EnumToString(g_tfHTF) +
          " serverOffset=" + IntegerToString(g_serverGmtOffset) + "h GMT" +
          " | maxHold(bars)=" + IntegerToString(NgMaxHoldForCurrentTF()));

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(hFastEMA != INVALID_HANDLE) IndicatorRelease(hFastEMA);
   if(hSlowEMA != INVALID_HANDLE) IndicatorRelease(hSlowEMA);
   if(hRSI     != INVALID_HANDLE) IndicatorRelease(hRSI);
   if(hMACD    != INVALID_HANDLE) IndicatorRelease(hMACD);
   if(hADX     != INVALID_HANDLE) IndicatorRelease(hADX);
   if(hATR     != INVALID_HANDLE) IndicatorRelease(hATR);
   if(hBB      != INVALID_HANDLE) IndicatorRelease(hBB);
   if(hFastEMAH != INVALID_HANDLE) IndicatorRelease(hFastEMAH);
   if(hSlowEMAH != INVALID_HANDLE) IndicatorRelease(hSlowEMAH);
   if(InpShowPanel)
   {
      ObjectsDeleteAll(0, "NG_PANEL_");
      ObjectsDeleteAll(0, "NGP_");
   }
   NgAdaptivePersistState();
   NgInfo("DEINIT reason=" + IntegerToString(reason));
}

void OnTick()
{
   NgRefreshDay();

   //--- new bar ?
   datetime barTime = iTime(g_symbol, g_tf, 0);
   bool newBar = (barTime != g_lastBarTime);
   if(newBar)
   {
      g_lastBarTime = barTime;
      g_regimeCache = NgDetectRegime();     // regime refresh on bar close only
   }

   //--- safety: auto-trading must be on (not enforced while back-testing)
   if(!MQLInfoInteger(MQL_TESTER))
   {
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return;
      if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) return;
   }

   //--- sync trackers & manage any open positions (protection first)
   NgSyncTrackers();
   NgManagePositions();
   NgFridayGuard();
   NgProtectionLayer();

   //--- portfolio-wide limits (shared across every chart running the EA)
   bool pfHalt = false, pfNew = false;
   NgPortfolioUpdate(pfHalt, pfNew);
   g_pfHalt = pfHalt;
   if(pfNew) NgCloseEvery("PORTFOLIO LIMIT (day/week shared across charts)");

   //--- filters shared by all entries (also drive the status panel)
   bool spreadOK = NgSpreadOK();
   bool newsBlocked = NgInNewsBlackout();
   bool sessionOK  = NgInTradingSession();
   bool weekendOK  = !NgWeekendBlocked();
   //--- dashboard redraw: 1s throttle (80+ objects; keeps the chart snappy)
   datetime nowS = TimeCurrent();
   if(nowS - g_lastPanelDraw >= 1 || newBar)
   {
      g_lastPanelDraw = nowS;
      NgDrawPanel(g_regimeCache, spreadOK, newsBlocked, sessionOK);
   }

   if(!InpAllowNewTrades) return;
   if(g_haltToday || g_haltedDD || g_haltedGuard || g_pfHalt) return;

   if(!newBar) return;
   if(!weekendOK || !spreadOK || newsBlocked || !sessionOK) return;
   if(NgHasGap()) { NgInfo("GAP detected (>1.5 ATR) - entry skipped for safety"); return; }
   if(NgCountOpen() >= InpMaxOpenPositions) return;
   if(InpMaxDailyTrades > 0 && g_dayTrades >= InpMaxDailyTrades) return;

   //--- signal
   NG_Signal sig;
   if(!NgEvaluateSignal(sig)) return;
   if(sig.dir == 0) return;

   //--- build SL/TP (genome-driven when the adaptive engine is live)
   double atr = NgBuf(hATR, 0, 1);
   if(atr <= 0.0) return;
   double slDist = g_genome.slATR * atr;
   double tpDist = (g_genome.tpATR > 0.0) ? (g_genome.tpATR * atr) : (InpMinRR * slDist);
   if(tpDist / slDist < InpMinRR) return; // reward:risk must be acceptable

   double entry = (sig.dir > 0) ? SymbolInfoDouble(g_symbol, SYMBOL_ASK)
                                : SymbolInfoDouble(g_symbol, SYMBOL_BID);
   double sl = (sig.dir > 0) ? entry - slDist : entry + slDist;
   double tp = (sig.dir > 0) ? entry + tpDist : entry - tpDist;
   sl = NgNormPrice(sl);
   tp = NgNormPrice(tp);

   double lots = NgRiskLots(slDist);
   if(lots <= 0.0) return;

   string cmt = InpID + "|" + g_className + "|" + (sig.isRangeFade ? "RANGE" : "PULLBACK");

   if(NgOpenPosition(sig.dir, lots, sl, tp, cmt))
   {
      g_dayTrades++;
      NgSyncTrackers();
   }
}
//+------------------------------------------------------------------+
//  END  |  NOVA GRAVITY AI v1.00  |  Auto-detect + Protection Layer
//+------------------------------------------------------------------+

//====================================================================
//  ONTESTER  - custom optimization criterion: PF * sqrt(N) / maxDD%
//  (select "Custom criterion" in the Strategy Tester optimizer)
//====================================================================
double OnTester()
{
   ulong seen[];
   double grossProfit = 0.0, grossLoss = 0.0;
   double cur = 0.0, peak = 0.0, ddMax = 0.0;
   int trades = 0;

   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
      if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagicNumber) continue;

      ulong posID = (ulong)HistoryDealGetInteger(d, DEAL_POSITION_ID);
      bool dup = false;
      for(int k = 0; k < ArraySize(seen); k++)
         if(seen[k] == posID) { dup = true; break; }
      if(dup) continue;
      int sz = ArraySize(seen);
      ArrayResize(seen, sz + 1);
      seen[sz] = posID;

      double p = HistoryDealGetDouble(d, DEAL_PROFIT)
               + HistoryDealGetDouble(d, DEAL_COMMISSION)
               + HistoryDealGetDouble(d, DEAL_SWAP);
      if(p >= 0.0) grossProfit += p; else grossLoss -= p;
      cur += p;
      if(cur > peak) peak = cur;
      double dd = peak - cur;
      if(dd > ddMax) ddMax = dd;
      trades++;
   }

   double pf = (grossLoss > 0.0) ? grossProfit / grossLoss : ((grossProfit > 0.0) ? 99.0 : 0.0);
   double base = (peak > 0.0) ? peak : 1.0;
   double ddPct = 100.0 * ddMax / base;
   if(ddPct <= 0.0) ddPct = 0.01;
   double score = pf * MathSqrt((double)trades) / ddPct;
   NgInfo("OnTester: PF=" + DoubleToString(pf, 2) + " T=" + IntegerToString(trades) +
          " DD%=" + DoubleToString(ddPct, 2) + " score=" + DoubleToString(score, 2));
   return score;
}
