//+------------------------------------------------------------------+
//|                                                    Aetherion.mq5 |
//|                     AETHERION Adaptive Intelligence EA v1.1.0    |
//|          Multi-asset · Auto symbol/TF · MT5 Build 4000+ safe     |
//+------------------------------------------------------------------+
#property copyright   "AETHERION Adaptive Intelligence"
#property link        "https://aetherion.local"
#property version     "1.10"
#property description "AETHERION — Adaptive multi-asset Expert Advisor"
#property description "Auto-detects symbol, timeframe and asset class."
#property description "Forex · Crypto/USDT · Metals · Energy · Indices · Stocks"
#property description "Works on every timeframe. Drop on any chart."
#property strict
#property tester_everytick_calculate

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/AccountInfo.mqh>
#include <ChartObjects/ChartObjectsTxtControls.mqh>

#include "AetherionEngine.mqh"
#include "AetherionPanel.mqh"

//+------------------------------------------------------------------+
//| Inputs                                                             |
//+------------------------------------------------------------------+
input group "===== AETHERION IDENTITY ====="
input long                 InpMagic              = 260824;           // Magic Number
input string               InpTradeComment       = "AETHERION";      // Order comment
input ENUM_AE_LANG         InpLanguage           = AE_LANG_AR;       // Panel language

input group "===== AUTO DETECTION ====="
input bool                 InpAutoDetect         = true;             // Auto detect symbol + timeframe
input string               InpForceSymbol        = "";               // Force symbol (empty = chart)
input ENUM_TIMEFRAMES      InpForceTF            = PERIOD_CURRENT;   // Force timeframe (CURRENT = chart)

input group "===== STRATEGY CORE ====="
input ENUM_AE_STRATEGY     InpStrategy           = AE_STRAT_AUTO;    // Strategy mode
input bool                 InpSignalOnNewBar     = true;             // Signal on new bar only
input int                  InpConfirmBars        = 1;                // Extra same-color confirmation bars
input bool                 InpUseHTF             = true;             // Higher-TF trend filter
input bool                 InpAllowBuy           = true;             // Allow BUY
input bool                 InpAllowSell          = true;             // Allow SELL
input bool                 InpCloseOnOpposite    = true;             // Close on opposite signal
input bool                 InpOneDirection       = true;             // One direction per symbol

input group "===== TREND / EMA ====="
input bool                 InpUseEMA             = true;             // Use EMA filter
input int                  InpEMAFast            = 21;               // Fast EMA
input int                  InpEMASlow            = 55;               // Slow EMA
input int                  InpEMATrend           = 200;              // Trend EMA

input group "===== MOMENTUM / RSI ====="
input bool                 InpUseRSI             = true;             // Use RSI
input int                  InpRSIPeriod          = 14;               // RSI period
input double               InpRSIBuyMin          = 42;               // Trend BUY RSI min
input double               InpRSIBuyMax          = 68;               // Trend BUY RSI max
input double               InpRSISellMin         = 32;               // Trend SELL RSI min
input double               InpRSISellMax         = 58;               // Trend SELL RSI max
input double               InpRSIRangeLow        = 30;               // Range oversold
input double               InpRSIRangeHigh       = 70;               // Range overbought

input group "===== MACD ====="
input bool                 InpUseMACD            = true;             // Use MACD
input int                  InpMACDFast           = 12;               // MACD fast
input int                  InpMACDSlow           = 26;               // MACD slow
input int                  InpMACDSignal         = 9;                // MACD signal

input group "===== ADX REGIME ====="
input bool                 InpUseADX             = true;             // Use ADX regime
input int                  InpADXPeriod          = 14;               // ADX period
input double               InpADXMin             = 18;               // Minimum ADX to trade trend
input double               InpADXTrend           = 25;               // Strong-trend ADX

input group "===== BOLLINGER ====="
input bool                 InpUseBB              = true;             // Use Bollinger (range/breakout)
input int                  InpBBPeriod           = 20;               // BB period
input double               InpBBDev              = 2.0;              // BB deviation

input group "===== ATR / VOLATILITY ====="
input int                  InpATRPeriod          = 14;               // ATR period
input double               InpATRSL              = 1.8;              // SL = ATR ×
input double               InpATRTP              = 2.8;              // TP = ATR × (if not RR)
input double               InpATRTrail           = 1.2;              // Trailing = ATR ×
input double               InpMinATRPoints       = 0;                // Min ATR in points (0=off)
input double               InpMaxATRPoints       = 0;                // Max ATR in points (0=off)

input group "===== RISK / LOTS ====="
input ENUM_AE_LOTMODE      InpLotMode            = AE_LOT_RISK;      // Lot calculation
input double               InpFixedLot           = 0.01;             // Fixed lot
input double               InpRiskPercent        = 0.75;             // Risk % of equity
input double               InpEquityStep         = 1000.0;           // Equity step $
input double               InpLotPerStep         = 0.01;             // Lot per equity step
input double               InpMinLot             = 0.01;             // Min lot
input double               InpMaxLot             = 2.00;             // Max lot
input int                  InpMaxPositions       = 1;                // Max open positions (magic)
input int                  InpMaxPerSymbol       = 1;                // Max per symbol
input int                  InpMaxTradesDay       = 8;                // Max trades / day
input int                  InpCooldownBars       = 2;                // Bars between entries
input int                  InpLossStreakMax      = 3;                // Pause after N losses (0=off)
input int                  InpLossStreakBars     = 6;                // Pause length in bars
input double               InpMaxDailyLossPct    = 3.0;              // Daily loss stop %
input double               InpMaxDrawdownPct     = 12.0;             // Equity DD stop %
input bool                 InpEmergencyClose     = true;             // Flatten on DD breach

input group "===== SPREAD / EXECUTION ====="
input bool                 InpAutoSpread         = true;             // Auto spread ceiling by asset
input int                  InpMaxSpreadPoints    = 35;               // Manual max spread (points)
input double               InpSpreadATRMax       = 0.35;             // Block if spread > ATR×
input int                  InpSpreadStableBars   = 1;                // Spread must stay OK N bars
input bool                 InpRolloverPause      = true;             // Block 23:50–00:20 server
input int                  InpSlippage           = 20;               // Max deviation (points)
input bool                 InpRetryRequote       = true;             // Retry on requote
input int                  InpMaxRetries         = 3;                // Max send retries

input group "===== STOPS / TARGETS ====="
input bool                 InpUseSL              = true;             // Use Stop Loss
input bool                 InpUseTP              = true;             // Use Take Profit
input int                  InpSLPoints           = 0;                // SL points (0 = ATR)
input int                  InpTPPoints           = 0;                // TP points (0 = ATR/RR)
input bool                 InpUseRR              = true;             // TP from risk:reward
input double               InpRR                 = 1.60;             // Reward : Risk
input bool                 InpBreakeven          = true;             // Move to BE
input int                  InpBETriggerPoints    = 0;                // BE trigger points (0=ATR)
input int                  InpBELockPoints       = 10;               // Lock profit at BE (points)
input bool                 InpTrailing           = true;             // Trailing stop
input int                  InpTrailStartPoints   = 0;                // Trail start (0=ATR)
input int                  InpTrailStepPoints    = 0;                // Trail step (0=ATR)
input bool                 InpPartialClose       = true;             // Partial close
input double               InpPartialPercent     = 50.0;             // Partial % 
input double               InpPartialRR          = 1.00;             // Partial at R-multiple

input group "===== SESSIONS / CALENDAR ====="
input bool                 InpSessionFilter      = true;             // Session filter (auto-off crypto)
input bool                 InpTradeAsia          = false;            // Asia 00-08 server
input bool                 InpTradeLondon        = true;             // London 08-16 server
input bool                 InpTradeNewYork       = true;             // NewYork 13-22 server
input int                  InpFridayCutoffHour   = 20;               // Friday cutoff (0=off)
input int                  InpMondayDelayHours   = 1;                // Monday delay hours
input bool                 InpAvoidNewsWindow    = false;            // Pause in news window
input int                  InpNewsHourStart      = 14;               // News window start
input int                  InpNewsHourEnd        = 16;               // News window end
input int                  InpMaxHoldBars        = 0;                // Time-exit bars (0=off)

input group "===== ASSET PROFILES ====="
input bool                 InpUseAssetProfiles   = true;             // Adapt SL/risk by asset class
input double               InpCryptoRiskScale    = 0.70;             // Crypto risk scale
input double               InpCryptoATRSL        = 2.40;             // Crypto ATR SL
input double               InpMetalATRSL         = 2.20;             // Metals ATR SL
input double               InpIndexATRSL         = 2.00;             // Indices ATR SL
input bool                 InpIndexGapFilter     = true;             // Skip first bar after gap

input group "===== DASHBOARD / CHART ====="
input bool                 InpShowPanel          = true;             // On-chart HUD
input int                  InpPanelX             = 18;               // Panel X
input int                  InpPanelY             = 28;               // Panel Y
input bool                 InpShowTradesOnChart  = true;             // Draw live trades
input bool                 InpLogToJournal       = true;             // Journal logs
input int                  InpTimerSec           = 1;                // HUD refresh seconds

//+------------------------------------------------------------------+
CAetherionEngine g_engine;
CAetherionPanel  g_panel;

//+------------------------------------------------------------------+
int OnInit()
  {
   AEConfig cfg;
   cfg.magic              = InpMagic;
   cfg.comment            = InpTradeComment;
   cfg.lang               = InpLanguage;
   cfg.autoDetect         = InpAutoDetect;
   cfg.forceSymbol        = InpForceSymbol;
   cfg.forceTF            = InpForceTF;
   cfg.strategy           = InpStrategy;
   cfg.signalOnNewBar     = InpSignalOnNewBar;
   cfg.confirmBars        = MathMax(InpConfirmBars,0);
   cfg.useHTF             = InpUseHTF;
   cfg.allowBuy           = InpAllowBuy;
   cfg.allowSell          = InpAllowSell;
   cfg.closeOnOpposite    = InpCloseOnOpposite;
   cfg.oneDirection       = InpOneDirection;
   cfg.useEMA             = InpUseEMA;
   cfg.emaFast            = MathMax(InpEMAFast,2);
   cfg.emaSlow            = MathMax(InpEMASlow,3);
   cfg.emaTrend           = MathMax(InpEMATrend,10);
   cfg.useRSI             = InpUseRSI;
   cfg.rsiPeriod          = MathMax(InpRSIPeriod,2);
   cfg.rsiBuyMin          = InpRSIBuyMin;
   cfg.rsiBuyMax          = InpRSIBuyMax;
   cfg.rsiSellMin         = InpRSISellMin;
   cfg.rsiSellMax         = InpRSISellMax;
   cfg.rsiRangeLow        = InpRSIRangeLow;
   cfg.rsiRangeHigh       = InpRSIRangeHigh;
   cfg.useMACD            = InpUseMACD;
   cfg.macdFast           = InpMACDFast;
   cfg.macdSlow           = InpMACDSlow;
   cfg.macdSignal         = InpMACDSignal;
   cfg.useADX             = InpUseADX;
   cfg.adxPeriod          = MathMax(InpADXPeriod,2);
   cfg.adxMin             = InpADXMin;
   cfg.adxTrend           = InpADXTrend;
   cfg.useBB              = InpUseBB;
   cfg.bbPeriod           = MathMax(InpBBPeriod,5);
   cfg.bbDev              = InpBBDev;
   cfg.atrPeriod          = MathMax(InpATRPeriod,2);
   cfg.atrSL              = InpATRSL;
   cfg.atrTP              = InpATRTP;
   cfg.atrTrail           = InpATRTrail;
   cfg.minATRPoints       = InpMinATRPoints;
   cfg.maxATRPoints       = InpMaxATRPoints;
   cfg.lotMode            = InpLotMode;
   cfg.fixedLot           = InpFixedLot;
   cfg.riskPercent        = InpRiskPercent;
   cfg.equityStep         = InpEquityStep;
   cfg.lotPerStep         = InpLotPerStep;
   cfg.minLot             = InpMinLot;
   cfg.maxLot             = InpMaxLot;
   cfg.maxPositions       = MathMax(InpMaxPositions,1);
   cfg.maxPerSymbol       = MathMax(InpMaxPerSymbol,1);
   cfg.maxTradesDay       = InpMaxTradesDay;
   cfg.cooldownBars       = MathMax(InpCooldownBars,0);
   cfg.lossStreakMax      = MathMax(InpLossStreakMax,0);
   cfg.lossStreakBars     = MathMax(InpLossStreakBars,1);
   cfg.maxDailyLossPct    = InpMaxDailyLossPct;
   cfg.maxDrawdownPct     = InpMaxDrawdownPct;
   cfg.emergencyClose     = InpEmergencyClose;
   cfg.autoSpread         = InpAutoSpread;
   cfg.maxSpreadPoints    = InpMaxSpreadPoints;
   cfg.spreadATRMax       = InpSpreadATRMax;
   cfg.spreadStableBars   = MathMax(InpSpreadStableBars,0);
   cfg.rolloverPause      = InpRolloverPause;
   cfg.slippage           = InpSlippage;
   cfg.retryRequote       = InpRetryRequote;
   cfg.maxRetries         = MathMax(InpMaxRetries,1);
   cfg.useSL              = InpUseSL;
   cfg.useTP              = InpUseTP;
   cfg.slPoints           = InpSLPoints;
   cfg.tpPoints           = InpTPPoints;
   cfg.useRR              = InpUseRR;
   cfg.rr                 = InpRR;
   cfg.breakeven          = InpBreakeven;
   cfg.beTriggerPoints    = InpBETriggerPoints;
   cfg.beLockPoints       = InpBELockPoints;
   cfg.trailing           = InpTrailing;
   cfg.trailStartPoints   = InpTrailStartPoints;
   cfg.trailStepPoints    = InpTrailStepPoints;
   cfg.partialClose       = InpPartialClose;
   cfg.partialPercent     = InpPartialPercent;
   cfg.partialRR          = InpPartialRR;
   cfg.sessionFilter      = InpSessionFilter;
   cfg.tradeAsia          = InpTradeAsia;
   cfg.tradeLondon        = InpTradeLondon;
   cfg.tradeNY            = InpTradeNewYork;
   cfg.fridayCutoffHour   = InpFridayCutoffHour;
   cfg.mondayDelayHours   = InpMondayDelayHours;
   cfg.avoidNewsWindow    = InpAvoidNewsWindow;
   cfg.newsHourStart      = InpNewsHourStart;
   cfg.newsHourEnd        = InpNewsHourEnd;
   cfg.maxHoldBars        = InpMaxHoldBars;
   cfg.useAssetProfiles   = InpUseAssetProfiles;
   cfg.cryptoRiskScale    = InpCryptoRiskScale;
   cfg.cryptoATRSL        = InpCryptoATRSL;
   cfg.metalATRSL         = InpMetalATRSL;
   cfg.indexATRSL         = InpIndexATRSL;
   cfg.indexGapFilter     = InpIndexGapFilter;
   cfg.showPanel          = InpShowPanel;
   cfg.panelX             = InpPanelX;
   cfg.panelY             = InpPanelY;
   cfg.showTradesOnChart  = InpShowTradesOnChart;
   cfg.logToJournal       = InpLogToJournal;

   if(!g_engine.Init(cfg))
     {
      Print("AETHERION: init failed — ",g_engine.LastError());
      return(INIT_FAILED);
     }

   if(InpShowPanel)
     {
      if(!g_panel.Init(GetPointer(g_engine),cfg.panelX,cfg.panelY,cfg.lang))
         Print("AETHERION: panel init skipped (tester/non-visual).");
     }

   EventSetTimer(MathMax(InpTimerSec,1));
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   g_panel.Destroy();
   g_engine.Deinit();
   Comment("");
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   g_engine.OnTick();
   if(InpShowTradesOnChart)
      g_engine.DrawLiveTrades();
  }

//+------------------------------------------------------------------+
void OnTimer()
  {
   g_engine.RefreshQuotes();
   if(InpShowPanel)
      g_panel.Render();
  }

//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   g_engine.OnTradeTransaction(trans,request,result);
  }

//+------------------------------------------------------------------+
double OnTester()
  {
   return(g_engine.TesterScore());
  }

//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   g_panel.OnChartEvent(id,lparam,dparam,sparam);
  }
//+------------------------------------------------------------------+
