//+------------------------------------------------------------------+
//|                                            AetherionEngine.mqh   |
//|  Core engine: asset detect, signals, risk, execution, visuals    |
//+------------------------------------------------------------------+
#ifndef AETHERION_ENGINE_MQH
#define AETHERION_ENGINE_MQH

enum ENUM_AE_LANG
  {
   AE_LANG_AR = 0,
   AE_LANG_EN = 1
  };

enum ENUM_AE_STRATEGY
  {
   AE_STRAT_AUTO     = 0,  // Adaptive by regime
   AE_STRAT_TREND    = 1,
   AE_STRAT_RANGE    = 2,
   AE_STRAT_BREAKOUT = 3,
   AE_STRAT_SCALP    = 4
  };

enum ENUM_AE_LOTMODE
  {
   AE_LOT_FIXED  = 0,
   AE_LOT_RISK   = 1,
   AE_LOT_STEP   = 2
  };

enum ENUM_AE_ASSET
  {
   AE_ASSET_FOREX  = 0,
   AE_ASSET_CRYPTO = 1,
   AE_ASSET_METAL  = 2,
   AE_ASSET_ENERGY = 3,
   AE_ASSET_INDEX  = 4,
   AE_ASSET_STOCK  = 5,
   AE_ASSET_USDT   = 6,
   AE_ASSET_OTHER  = 7
  };

enum ENUM_AE_REGIME
  {
   AE_REGIME_TREND   = 0,
   AE_REGIME_RANGE   = 1,
   AE_REGIME_VOLATILE= 2,
   AE_REGIME_QUIET   = 3
  };

enum ENUM_AE_SIGNAL
  {
   AE_SIG_NONE = 0,
   AE_SIG_BUY  = 1,
   AE_SIG_SELL = -1
  };

struct AEConfig
  {
   long              magic;
   string            comment;
   ENUM_AE_LANG      lang;
   bool              autoDetect;
   string            forceSymbol;
   ENUM_TIMEFRAMES   forceTF;
   ENUM_AE_STRATEGY  strategy;
   bool              signalOnNewBar;
   int               confirmBars;
   bool              useHTF;
   bool              usePullback;
   bool              allowBuy;
   bool              allowSell;
   bool              closeOnOpposite;
   bool              oneDirection;
   bool              useEMA;
   int               emaFast;
   int               emaSlow;
   int               emaTrend;
   bool              useRSI;
   int               rsiPeriod;
   double            rsiBuyMin;
   double            rsiBuyMax;
   double            rsiSellMin;
   double            rsiSellMax;
   double            rsiRangeLow;
   double            rsiRangeHigh;
   bool              useMACD;
   int               macdFast;
   int               macdSlow;
   int               macdSignal;
   bool              useADX;
   int               adxPeriod;
   double            adxMin;
   double            adxTrend;
   bool              useBB;
   int               bbPeriod;
   double            bbDev;
   int               atrPeriod;
   double            atrSL;
   double            atrTP;
   double            atrTrail;
   double            minATRPoints;
   double            maxATRPoints;
   ENUM_AE_LOTMODE   lotMode;
   double            fixedLot;
   double            riskPercent;
   double            equityStep;
   double            lotPerStep;
   double            minLot;
   double            maxLot;
   int               maxPositions;
   int               maxPerSymbol;
   int               maxTradesDay;
   int               cooldownBars;
   int               lossStreakMax;
   int               lossStreakBars;
   double            maxDailyLossPct;
   double            maxDrawdownPct;
   bool              emergencyClose;
   bool              autoSpread;
   int               maxSpreadPoints;
   double            spreadATRMax;
   int               spreadStableBars;
   bool              rolloverPause;
   int               slippage;
   bool              retryRequote;
   int               maxRetries;
   bool              useSL;
   bool              useTP;
   int               slPoints;
   int               tpPoints;
   bool              useRR;
   double            rr;
   bool              breakeven;
   int               beTriggerPoints;
   int               beLockPoints;
   bool              trailing;
   int               trailStartPoints;
   int               trailStepPoints;
   bool              partialClose;
   double            partialPercent;
   double            partialRR;
   bool              sessionFilter;
   bool              tradeAsia;
   bool              tradeLondon;
   bool              tradeNY;
   int               fridayCutoffHour;
   int               mondayDelayHours;
   bool              avoidNewsWindow;
   int               newsHourStart;
   int               newsHourEnd;
   int               maxHoldBars;
   int               maxHoldHours;
   int               serverUtcOffset;
   bool              fridayFlatten;
   bool              useAssetProfiles;
   double            cryptoRiskScale;
   double            cryptoATRSL;
   double            metalATRSL;
   double            indexATRSL;
   bool              indexGapFilter;
   bool              showPanel;
   int               panelX;
   int               panelY;
   bool              showTradesOnChart;
   bool              logToJournal;
  };

struct AESnapshot
  {
   string            symbol;
   ENUM_TIMEFRAMES   tf;
   ENUM_AE_ASSET     asset;
   ENUM_AE_REGIME    regime;
   ENUM_AE_STRATEGY  activeStrat;
   ENUM_AE_SIGNAL    lastSignal;
   string            lastReason;
   double            bid;
   double            ask;
   double            spreadPts;
   double            spreadPrice;
   double            atr;
   double            emaF;
   double            emaS;
   double            emaT;
   double            rsi;
   double            macdMain;
   double            macdSig;
   double            adx;
   double            plusDI;
   double            minusDI;
   double            bbUpper;
   double            bbMid;
   double            bbLower;
   double            equity;
   double            balance;
   double            floating;
   double            dailyPnL;
   double            drawdownPct;
   int               openPos;
   int               tradesToday;
   double            winRate;
   double            profitFactor;
   double            netProfit;
   int               wins;
   int               losses;
   bool              spreadOk;
   bool              sessionOk;
   bool              riskOk;
   bool              tradeAllowed;
   string            blockReason;
   datetime          lastBar;
   string            fillingName;
   string            execModeName;
   int               digits;
   double            point;
   double            tickSize;
   double            tickValue;
   double            volMin;
   double            volMax;
   double            volStep;
   int               stopsLevel;
   int               freezeLevel;
   long              calcMode;
  };

class CAetherionEngine
  {
private:
   AEConfig          m_cfg;
   AESnapshot        m_snap;
   CTrade            m_trade;
   CPositionInfo     m_pos;
   CSymbolInfo       m_sym;
   CAccountInfo      m_acc;

   string            m_symbol;
   ENUM_TIMEFRAMES   m_tf;
   string            m_err;
   string            m_pfx;

   int               m_hEmaF;
   int               m_hEmaS;
   int               m_hEmaT;
   int               m_hRsi;
   int               m_hMacd;
   int               m_hAdx;
   int               m_hBb;
   int               m_hAtr;
   int               m_hHtfF;
   int               m_hHtfS;

   datetime          m_lastBarTime;
   datetime          m_lastEntryBar;
   datetime          m_dayStamp;
   double            m_dayStartEquity;
   double            m_peakEquity;
   int               m_tradesToday;
   int               m_wins;
   int               m_losses;
   double            m_grossWin;
   double            m_grossLoss;
   double            m_netProfit;
   bool              m_halted;
   ulong             m_partialDone[];
   int               m_lossStreak;
   datetime          m_streakPauseBar;
   int               m_spreadOkStreak;
   double            m_htfFast;
   double            m_htfSlow;

   ENUM_ORDER_TYPE_FILLING m_filling;

   void              Log(const string msg);
   bool              ResolveSymbolTF();
   ENUM_AE_ASSET     DetectAsset(const string sym);
   ENUM_ORDER_TYPE_FILLING DetectFilling(const string sym);
   string            FillingName(const ENUM_ORDER_TYPE_FILLING f);
   string            ExecName(const long exe);
   bool              CreateIndicators();
   void              ReleaseIndicators();
   bool              Copy1(const int handle,const int buf,double &out,const int shift=1);
   bool              UpdateIndicators();
   void              UpdateQuotes();
   void              UpdateStats();
   void              DetectRegime();
   ENUM_AE_SIGNAL    ComputeSignal(string &reason);
   bool              SessionAllows();
   bool              RolloverBlocked();
   bool              WeekendProtect();
   void              MaybeWeekendFlatten();
   bool              SpreadAllows();
   bool              RiskAllows(string &why);
   ENUM_TIMEFRAMES   HigherTF(const ENUM_TIMEFRAMES tf);
   bool              NewBar();
   bool              GapBar();
   int               CountMagic();
   int               CountSymbol();
   double            ProfileATRSL();
   double            ProfileRiskPct();
   int               ProfileMaxSpread();
   double            NormalizeVolume(double lots);
   double            NormalizePrice(const double price);
   bool              StopsValid(const ENUM_ORDER_TYPE type,double &sl,double &tp);
   double            CalcLots(const double slDistance);
   bool              OpenPosition(const ENUM_AE_SIGNAL sig,const string reason);
   void              ManagePositions();
   void              MaybeTimeExit();
   void              CloseTicket(const ulong ticket,const string why);
   void              FlattenAll(const string why);
   bool              AlreadyPartial(const ulong ticket);
   void              MarkPartial(const ulong ticket);
   void              ResetDayIfNeeded();
   string            TfName(const ENUM_TIMEFRAMES tf);
   string            AssetName(const ENUM_AE_ASSET a);
   string            RegimeName(const ENUM_AE_REGIME r);
   void              PurgeVisuals();

public:
                     CAetherionEngine(void);
                    ~CAetherionEngine(void);
   bool              Init(const AEConfig &cfg);
   void              Deinit(void);
   void              OnTick(void);
   void              RefreshQuotes(void);
   void              DrawLiveTrades(void);
   void              OnTradeTransaction(const MqlTradeTransaction &trans,
                                        const MqlTradeRequest &request,
                                        const MqlTradeResult &result);
   double            TesterScore(void);
   string            LastError(void) const { return(m_err); }
   AESnapshot        Snap(void) const { return(m_snap); }
   string            SymbolName(void) const { return(m_symbol); }
   ENUM_TIMEFRAMES   Timeframe(void) const { return(m_tf); }
   string            Prefix(void) const { return(m_pfx); }
  };

//+------------------------------------------------------------------+
CAetherionEngine::CAetherionEngine(void)
  {
   m_hEmaF=m_hEmaS=m_hEmaT=m_hRsi=m_hMacd=m_hAdx=m_hBb=m_hAtr=INVALID_HANDLE;
   m_hHtfF=m_hHtfS=INVALID_HANDLE;
   m_lossStreak=0;
   m_streakPauseBar=0;
   m_spreadOkStreak=0;
   m_htfFast=m_htfSlow=0;
   m_lastBarTime=0;
   m_lastEntryBar=0;
   m_dayStamp=0;
   m_dayStartEquity=0;
   m_peakEquity=0;
   m_tradesToday=0;
   m_wins=m_losses=0;
   m_grossWin=m_grossLoss=m_netProfit=0;
   m_halted=false;
   m_err="";
   m_pfx="AE_";
   ZeroMemory(m_snap);
  }

CAetherionEngine::~CAetherionEngine(void) {}

//+------------------------------------------------------------------+
void CAetherionEngine::Log(const string msg)
  {
   if(m_cfg.logToJournal)
      Print("AETHERION | ",m_symbol," ",TfName(m_tf)," | ",msg);
  }

//+------------------------------------------------------------------+
bool CAetherionEngine::Init(const AEConfig &cfg)
  {
   m_cfg=cfg;
   m_err="";

   if(!ResolveSymbolTF())
      return(false);

   if(!SymbolSelect(m_symbol,true))
     {
      m_err="Cannot select symbol "+m_symbol;
      return(false);
     }

   if(!m_sym.Name(m_symbol))
     {
      m_err="SymbolInfo bind failed for "+m_symbol;
      return(false);
     }
   m_sym.Refresh();
   m_sym.RefreshRates();

   long tradeMode=(long)SymbolInfoInteger(m_symbol,SYMBOL_TRADE_MODE);
   if(tradeMode==SYMBOL_TRADE_MODE_DISABLED)
     {
      m_err="Trading disabled on "+m_symbol;
      return(false);
     }

   m_filling=DetectFilling(m_symbol);
   m_trade.SetExpertMagicNumber(m_cfg.magic);
   m_trade.SetDeviationInPoints((ulong)MathMax(m_cfg.slippage,1));
   m_trade.SetTypeFilling(m_filling);
   m_trade.SetAsyncMode(false);
   m_trade.LogLevel(LOG_LEVEL_ERRORS);

   if(!CreateIndicators())
      return(false);

   m_pfx=StringFormat("AE_%d_",(int)m_cfg.magic);
   m_dayStartEquity=m_acc.Equity();
   m_peakEquity=m_dayStartEquity;
   m_dayStamp=iTime(m_symbol,PERIOD_D1,0);

   m_snap.symbol=m_symbol;
   m_snap.tf=m_tf;
   m_snap.asset=DetectAsset(m_symbol);
   m_snap.fillingName=FillingName(m_filling);
   m_snap.execModeName=ExecName((long)SymbolInfoInteger(m_symbol,SYMBOL_TRADE_EXEMODE));
   m_snap.digits=(int)SymbolInfoInteger(m_symbol,SYMBOL_DIGITS);
   m_snap.point=SymbolInfoDouble(m_symbol,SYMBOL_POINT);
   m_snap.tickSize=SymbolInfoDouble(m_symbol,SYMBOL_TRADE_TICK_SIZE);
   m_snap.tickValue=SymbolInfoDouble(m_symbol,SYMBOL_TRADE_TICK_VALUE);
   m_snap.volMin=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_MIN);
   m_snap.volMax=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_MAX);
   m_snap.volStep=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_STEP);
   m_snap.stopsLevel=(int)SymbolInfoInteger(m_symbol,SYMBOL_TRADE_STOPS_LEVEL);
   m_snap.freezeLevel=(int)SymbolInfoInteger(m_symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   m_snap.calcMode=SymbolInfoInteger(m_symbol,SYMBOL_TRADE_CALC_MODE);

   RefreshQuotes();
   UpdateIndicators();
   DetectRegime();

   Log("online  asset="+AssetName(m_snap.asset)+
       "  fill="+m_snap.fillingName+
       "  exec="+m_snap.execModeName+
       "  digits="+IntegerToString(m_snap.digits)+
       "  point="+DoubleToString(m_snap.point,m_snap.digits));

   if(!MQLInfoInteger(MQL_TRADE_ALLOWED) || !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      Log("WARNING: Algo Trading is OFF — enable the AutoTrading button.");

   return(true);
  }

//+------------------------------------------------------------------+
void CAetherionEngine::Deinit(void)
  {
   ReleaseIndicators();
   PurgeVisuals();
  }

//+------------------------------------------------------------------+
bool CAetherionEngine::ResolveSymbolTF()
  {
   if(m_cfg.autoDetect)
     {
      m_symbol=(m_cfg.forceSymbol=="" ? _Symbol : m_cfg.forceSymbol);
      m_tf=(m_cfg.forceTF==PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : m_cfg.forceTF);
     }
   else
     {
      m_symbol=(m_cfg.forceSymbol=="" ? _Symbol : m_cfg.forceSymbol);
      m_tf=(m_cfg.forceTF==PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : m_cfg.forceTF);
     }

   StringTrimLeft(m_symbol);
   StringTrimRight(m_symbol);
   if(m_symbol=="")
     {
      m_err="Empty symbol";
      return(false);
     }
   if(m_tf==PERIOD_CURRENT)
      m_tf=(ENUM_TIMEFRAMES)_Period;
   return(true);
  }

//+------------------------------------------------------------------+
ENUM_AE_ASSET CAetherionEngine::DetectAsset(const string sym)
  {
   string u=sym;
   StringToUpper(u);
   // strip common broker prefixes/suffixes noise
   string raw=u;
   StringReplace(raw,".","");
   StringReplace(raw,"-","");
   StringReplace(raw,"_","");
   // strip broker suffixes only — never delete every 'M' (that breaks AMZN / MSFT / MATIC)
   StringReplace(raw,"MICRO","");
   StringReplace(raw,"PRO","");
   StringReplace(raw,"ECN","");
   StringReplace(raw,"RAW","");
   int nlen=StringLen(raw);
   if(nlen>3)
     {
      ushort last=StringGetCharacter(raw,nlen-1);
      if(last=='M' || last=='m')
         raw=StringSubstr(raw,0,nlen-1);
     }

   if(StringFind(raw,"USDT")>=0 || StringFind(raw,"USDC")>=0 || StringFind(raw,"BUSD")>=0)
      return(AE_ASSET_USDT);

   string crypto[]={"BTC","ETH","XRP","SOL","BNB","ADA","DOGE","LTC","DOT","AVAX",
                    "LINK","MATIC","TON","TRX","ATOM","UNI","NEAR","APT","ARB","OP",
                    "SHIB","PEPE","FIL","ICP","AAVE","XLM","ETC","BCH","LDO","INJ",
                    "SUI","SEI","TIA","WIF","BONK","ORDI","RUNE","FTM","ALGO","VET",
                    "XTZ","EOS","THETA","AXS","SAND","MANA","GALA","IMX","RNDR","FET",
                    "HBAR","MKR","GRT","QNT","EGLD","KAS","STX","RENDER"};
   for(int i=0;i<ArraySize(crypto);i++)
      if(StringFind(raw,crypto[i])>=0)
         return(AE_ASSET_CRYPTO);

   string metals[]={"XAU","XAG","XPT","XPD","GOLD","SILVER","GOLD","PALL","PLAT"};
   for(int i=0;i<ArraySize(metals);i++)
      if(StringFind(raw,metals[i])>=0)
         return(AE_ASSET_METAL);

   string energy[]={"WTI","BRENT","UKOIL","USOIL","XTI","XBR","NATGAS","NGAS","CL","BRN"};
   for(int i=0;i<ArraySize(energy);i++)
      if(StringFind(raw,energy[i])>=0)
         return(AE_ASSET_ENERGY);

   string idx[]={"US30","US500","US100","NAS100","NASDAQ","SPX","SP500","DJ30","DJI",
                 "GER40","GER30","DAX","UK100","FTSE","JP225","NI225","NIKKEI",
                 "FRA40","CAC","AUS200","ESP35","ITA40","HK50","CN50","EU50",
                 "USTEC","UT100","NDX","WS30","DE40","DE30"};
   for(int i=0;i<ArraySize(idx);i++)
      if(StringFind(raw,idx[i])>=0)
         return(AE_ASSET_INDEX);

   long calc=(long)SymbolInfoInteger(sym,SYMBOL_TRADE_CALC_MODE);
   if(calc==SYMBOL_CALC_MODE_EXCH_STOCKS || calc==SYMBOL_CALC_MODE_CFD)
     {
      // CFD could be many things; if 6-letter forex-like keep forex
      int letters=0;
      for(int k=0;k<StringLen(raw);k++)
        {
         ushort c=StringGetCharacter(raw,k);
         if(c>='A' && c<='Z') letters++;
        }
      if(letters>=3 && letters<=5)
         return(AE_ASSET_STOCK);
     }
   if(calc==SYMBOL_CALC_MODE_CFDINDEX || calc==SYMBOL_CALC_MODE_EXCH_FUTURES)
      return(AE_ASSET_INDEX);
   if(calc==SYMBOL_CALC_MODE_FOREX || calc==SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE)
      return(AE_ASSET_FOREX);

   // classic 6-letter FX
   if(StringLen(raw)==6)
      return(AE_ASSET_FOREX);

   return(AE_ASSET_OTHER);
  }

//+------------------------------------------------------------------+
// Filling detection — MT5 2024-2026 safe (FOK / IOC / RETURN / BOC)
// Never assume a static filling. Market execution forbids RETURN.
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING CAetherionEngine::DetectFilling(const string sym)
  {
   const long filling=(long)SymbolInfoInteger(sym,SYMBOL_FILLING_MODE);
   const long exe=(long)SymbolInfoInteger(sym,SYMBOL_TRADE_EXEMODE);

   const bool fok=((filling & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK);
   const bool ioc=((filling & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC);
#ifdef SYMBOL_FILLING_BOC
   const bool boc=((filling & SYMBOL_FILLING_BOC)==SYMBOL_FILLING_BOC);
#else
   const bool boc=false;
#endif

   // Instant / Request: RETURN is always legal; prefer IOC then FOK then RETURN
   if(exe==SYMBOL_TRADE_EXECUTION_INSTANT || exe==SYMBOL_TRADE_EXECUTION_REQUEST)
     {
      if(ioc) return(ORDER_FILLING_IOC);
      if(fok) return(ORDER_FILLING_FOK);
      return(ORDER_FILLING_RETURN);
     }

   // Market execution: RETURN is forbidden
   if(exe==SYMBOL_TRADE_EXECUTION_MARKET)
     {
      if(ioc) return(ORDER_FILLING_IOC);
      if(fok) return(ORDER_FILLING_FOK);
      return(ORDER_FILLING_IOC);
     }

   // Exchange: RETURN usually allowed
   if(exe==SYMBOL_TRADE_EXECUTION_EXCHANGE)
     {
      if(ioc) return(ORDER_FILLING_IOC);
      if(fok) return(ORDER_FILLING_FOK);
      return(ORDER_FILLING_RETURN);
     }

   if(ioc) return(ORDER_FILLING_IOC);
   if(fok) return(ORDER_FILLING_FOK);
   return(ORDER_FILLING_RETURN);
  }

string CAetherionEngine::FillingName(const ENUM_ORDER_TYPE_FILLING f)
  {
   if(f==ORDER_FILLING_FOK)    return("FOK");
   if(f==ORDER_FILLING_IOC)    return("IOC");
   if(f==ORDER_FILLING_RETURN) return("RETURN");
#ifdef ORDER_FILLING_BOC
   if(f==ORDER_FILLING_BOC)    return("BOC");
#endif
   return("?");
  }

string CAetherionEngine::ExecName(const long exe)
  {
   if(exe==SYMBOL_TRADE_EXECUTION_REQUEST)  return("REQUEST");
   if(exe==SYMBOL_TRADE_EXECUTION_INSTANT)  return("INSTANT");
   if(exe==SYMBOL_TRADE_EXECUTION_MARKET)   return("MARKET");
   if(exe==SYMBOL_TRADE_EXECUTION_EXCHANGE) return("EXCHANGE");
   return("UNKNOWN");
  }

//+------------------------------------------------------------------+
bool CAetherionEngine::CreateIndicators()
  {
   ReleaseIndicators();
   m_hEmaF = iMA(m_symbol,m_tf,m_cfg.emaFast,0,MODE_EMA,PRICE_CLOSE);
   m_hEmaS = iMA(m_symbol,m_tf,m_cfg.emaSlow,0,MODE_EMA,PRICE_CLOSE);
   m_hEmaT = iMA(m_symbol,m_tf,m_cfg.emaTrend,0,MODE_EMA,PRICE_CLOSE);
   m_hRsi  = iRSI(m_symbol,m_tf,m_cfg.rsiPeriod,PRICE_CLOSE);
   m_hMacd = iMACD(m_symbol,m_tf,m_cfg.macdFast,m_cfg.macdSlow,m_cfg.macdSignal,PRICE_CLOSE);
   m_hAdx  = iADX(m_symbol,m_tf,m_cfg.adxPeriod);
   m_hBb   = iBands(m_symbol,m_tf,m_cfg.bbPeriod,0,m_cfg.bbDev,PRICE_CLOSE);
   m_hAtr  = iATR(m_symbol,m_tf,m_cfg.atrPeriod);
   if(m_cfg.useHTF)
     {
      ENUM_TIMEFRAMES htf=HigherTF(m_tf);
      m_hHtfF=iMA(m_symbol,htf,m_cfg.emaFast,0,MODE_EMA,PRICE_CLOSE);
      m_hHtfS=iMA(m_symbol,htf,m_cfg.emaSlow,0,MODE_EMA,PRICE_CLOSE);
     }

   if(m_hEmaF==INVALID_HANDLE || m_hEmaS==INVALID_HANDLE || m_hEmaT==INVALID_HANDLE ||
      m_hRsi==INVALID_HANDLE  || m_hMacd==INVALID_HANDLE || m_hAdx==INVALID_HANDLE  ||
      m_hBb==INVALID_HANDLE   || m_hAtr==INVALID_HANDLE ||
      (m_cfg.useHTF && (m_hHtfF==INVALID_HANDLE || m_hHtfS==INVALID_HANDLE)))
     {
      m_err="Indicator handle failed (symbol/TF not ready)";
      return(false);
     }
   return(true);
  }

void CAetherionEngine::ReleaseIndicators()
  {
   if(m_hEmaF!=INVALID_HANDLE) { IndicatorRelease(m_hEmaF); m_hEmaF=INVALID_HANDLE; }
   if(m_hEmaS!=INVALID_HANDLE) { IndicatorRelease(m_hEmaS); m_hEmaS=INVALID_HANDLE; }
   if(m_hEmaT!=INVALID_HANDLE) { IndicatorRelease(m_hEmaT); m_hEmaT=INVALID_HANDLE; }
   if(m_hRsi !=INVALID_HANDLE) { IndicatorRelease(m_hRsi);  m_hRsi =INVALID_HANDLE; }
   if(m_hMacd!=INVALID_HANDLE) { IndicatorRelease(m_hMacd); m_hMacd=INVALID_HANDLE; }
   if(m_hAdx !=INVALID_HANDLE) { IndicatorRelease(m_hAdx);  m_hAdx =INVALID_HANDLE; }
   if(m_hBb  !=INVALID_HANDLE) { IndicatorRelease(m_hBb);   m_hBb  =INVALID_HANDLE; }
   if(m_hAtr !=INVALID_HANDLE) { IndicatorRelease(m_hAtr);  m_hAtr =INVALID_HANDLE; }
   if(m_hHtfF!=INVALID_HANDLE) { IndicatorRelease(m_hHtfF); m_hHtfF=INVALID_HANDLE; }
   if(m_hHtfS!=INVALID_HANDLE) { IndicatorRelease(m_hHtfS); m_hHtfS=INVALID_HANDLE; }
  }

bool CAetherionEngine::Copy1(const int handle,const int buf,double &out,const int shift)
  {
   double a[];
   ArraySetAsSeries(a,true);
   if(CopyBuffer(handle,buf,shift,1,a)<1)
      return(false);
   out=a[0];
   return(MathIsValidNumber(out));
  }

bool CAetherionEngine::UpdateIndicators()
  {
   if(!Copy1(m_hEmaF,0,m_snap.emaF)) return(false);
   if(!Copy1(m_hEmaS,0,m_snap.emaS)) return(false);
   if(!Copy1(m_hEmaT,0,m_snap.emaT)) return(false);
   if(!Copy1(m_hRsi,0,m_snap.rsi))   return(false);
   if(!Copy1(m_hMacd,0,m_snap.macdMain)) return(false);
   if(!Copy1(m_hMacd,1,m_snap.macdSig))  return(false);
   if(!Copy1(m_hAdx,0,m_snap.adx))    return(false);
   if(!Copy1(m_hAdx,1,m_snap.plusDI)) return(false);
   if(!Copy1(m_hAdx,2,m_snap.minusDI))return(false);
   if(!Copy1(m_hBb,1,m_snap.bbUpper)) return(false);
   if(!Copy1(m_hBb,0,m_snap.bbMid))   return(false);
   if(!Copy1(m_hBb,2,m_snap.bbLower)) return(false);
   if(!Copy1(m_hAtr,0,m_snap.atr))    return(false);
   if(m_cfg.useHTF)
     {
      if(!Copy1(m_hHtfF,0,m_htfFast)) return(false);
      if(!Copy1(m_hHtfS,0,m_htfSlow)) return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
void CAetherionEngine::UpdateQuotes()
  {
   MqlTick tick;
   if(!SymbolInfoTick(m_symbol,tick))
     {
      m_snap.bid=SymbolInfoDouble(m_symbol,SYMBOL_BID);
      m_snap.ask=SymbolInfoDouble(m_symbol,SYMBOL_ASK);
     }
   else
     {
      m_snap.bid=tick.bid;
      m_snap.ask=tick.ask;
     }
   double point=SymbolInfoDouble(m_symbol,SYMBOL_POINT);
   if(point<=0) point=_Point;
   m_snap.spreadPrice=m_snap.ask-m_snap.bid;
   m_snap.spreadPts=(point>0 ? m_snap.spreadPrice/point : 0);
   m_snap.equity=m_acc.Equity();
   m_snap.balance=m_acc.Balance();
   m_snap.floating=m_snap.equity-m_snap.balance;
   if(m_snap.equity>m_peakEquity) m_peakEquity=m_snap.equity;
   m_snap.drawdownPct=(m_peakEquity>0 ? 100.0*(m_peakEquity-m_snap.equity)/m_peakEquity : 0);
   m_snap.dailyPnL=m_snap.equity-m_dayStartEquity;
   m_snap.openPos=CountMagic();
   m_snap.tradesToday=m_tradesToday;
   m_snap.digits=(int)SymbolInfoInteger(m_symbol,SYMBOL_DIGITS);
   m_snap.point=point;
   m_snap.tradeAllowed=(bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) &&
                       (bool)MQLInfoInteger(MQL_TRADE_ALLOWED);
  }

void CAetherionEngine::RefreshQuotes()
  {
   ResetDayIfNeeded();
   UpdateQuotes();
   UpdateStats();
   m_snap.spreadOk=SpreadAllows();
   m_snap.sessionOk=SessionAllows();
   string why="";
   m_snap.riskOk=RiskAllows(why);
   if(!m_snap.riskOk) m_snap.blockReason=why;
   else if(!m_snap.spreadOk) m_snap.blockReason="SPREAD";
   else if(!m_snap.sessionOk) m_snap.blockReason=RolloverBlocked()?"ROLLOVER":"SESSION";
   else if(!m_snap.tradeAllowed) m_snap.blockReason="ALGO OFF";
   else m_snap.blockReason="";
  }

void CAetherionEngine::UpdateStats()
  {
   int closed=m_wins+m_losses;
   m_snap.wins=m_wins;
   m_snap.losses=m_losses;
   m_snap.winRate=(closed>0 ? 100.0*m_wins/closed : 0);
   m_snap.profitFactor=(m_grossLoss<0 ? m_grossWin/MathAbs(m_grossLoss) : (m_grossWin>0?99:0));
   m_snap.netProfit=m_netProfit;
  }

void CAetherionEngine::ResetDayIfNeeded()
  {
   datetime d=iTime(m_symbol,PERIOD_D1,0);
   if(d!=0 && d!=m_dayStamp)
     {
      m_dayStamp=d;
      m_dayStartEquity=m_acc.Equity();
      m_tradesToday=0;
      if(m_halted && m_cfg.maxDailyLossPct>0)
         m_halted=false; // new day unlocks daily halt (DD halt stays)
      Log("new trading day — daily counters reset");
     }
  }

//+------------------------------------------------------------------+
void CAetherionEngine::DetectRegime()
  {
   double atrPts=(m_snap.point>0 ? m_snap.atr/m_snap.point : 0);
   double px=m_snap.bid;
   if(px<=0) px=m_snap.ask;
   double atrPct=(px>0 ? 100.0*m_snap.atr/px : 0);
   double quietAdx=MathMin(14.0,m_cfg.adxMin*0.75);

   if(m_snap.adx<quietAdx)
      m_snap.regime=AE_REGIME_QUIET;
   else if(m_snap.adx>=m_cfg.adxTrend)
      m_snap.regime=AE_REGIME_TREND;
   else if(m_snap.adx<m_cfg.adxMin)
      m_snap.regime=AE_REGIME_RANGE;
   else
      m_snap.regime=AE_REGIME_TREND;

   if(m_cfg.minATRPoints>0 && atrPts<m_cfg.minATRPoints)
      m_snap.regime=AE_REGIME_QUIET;

   bool autoVol=false;
   switch(m_snap.asset)
     {
      case AE_ASSET_FOREX:  autoVol=(atrPct>=0.45); break;
      case AE_ASSET_METAL:  autoVol=(atrPct>=0.85); break;
      case AE_ASSET_ENERGY: autoVol=(atrPct>=1.10); break;
      case AE_ASSET_INDEX:
      case AE_ASSET_STOCK:  autoVol=(atrPct>=0.80); break;
      case AE_ASSET_CRYPTO:
      case AE_ASSET_USDT:   autoVol=(atrPct>=2.80); break;
      default:              autoVol=(atrPct>=1.00); break;
     }
   if((m_cfg.maxATRPoints>0 && atrPts>m_cfg.maxATRPoints) || autoVol)
      m_snap.regime=AE_REGIME_VOLATILE;

   if(m_cfg.strategy==AE_STRAT_AUTO)
     {
      if(m_snap.regime==AE_REGIME_RANGE) m_snap.activeStrat=AE_STRAT_RANGE;
      else if(m_snap.regime==AE_REGIME_QUIET || m_snap.regime==AE_REGIME_VOLATILE)
         m_snap.activeStrat=AE_STRAT_TREND; // blocked at signal
      else m_snap.activeStrat=AE_STRAT_TREND;
     }
   else
      m_snap.activeStrat=m_cfg.strategy;
  }

//+------------------------------------------------------------------+
ENUM_AE_SIGNAL CAetherionEngine::ComputeSignal(string &reason)
  {
   reason="";
   const int shift=1; // closed bar — no-repaint
   double close1=iClose(m_symbol,m_tf,shift);
   double high1 =iHigh(m_symbol,m_tf,shift);
   double low1  =iLow(m_symbol,m_tf,shift);
   double open1 =iOpen(m_symbol,m_tf,shift);
   if(close1<=0)
     {
      reason="no-bar";
      return(AE_SIG_NONE);
     }

   bool bullTrend=true,bearTrend=true;
   if(m_cfg.useEMA)
     {
      bullTrend=(m_snap.emaF>m_snap.emaS && close1>=m_snap.emaT*0.999);
      bearTrend=(m_snap.emaF<m_snap.emaS && close1<=m_snap.emaT*1.001);
     }

   bool rsiBuy=true,rsiSell=true,rsiOs=false,rsiOb=false;
   if(m_cfg.useRSI)
     {
      rsiBuy =(m_snap.rsi>=m_cfg.rsiBuyMin  && m_snap.rsi<=m_cfg.rsiBuyMax);
      rsiSell=(m_snap.rsi>=m_cfg.rsiSellMin && m_snap.rsi<=m_cfg.rsiSellMax);
      rsiOs  =(m_snap.rsi<=m_cfg.rsiRangeLow);
      rsiOb  =(m_snap.rsi>=m_cfg.rsiRangeHigh);
     }

   bool macdBuy=true,macdSell=true;
   if(m_cfg.useMACD)
     {
      macdBuy =(m_snap.macdMain>m_snap.macdSig);
      macdSell=(m_snap.macdMain<m_snap.macdSig);
     }

   bool adxOk=true,diBuy=true,diSell=true;
   if(m_cfg.useADX)
     {
      adxOk=(m_snap.adx>=m_cfg.adxMin);
      diBuy =(m_snap.plusDI>m_snap.minusDI);
      diSell=(m_snap.minusDI>m_snap.plusDI);
     }

   bool touchLow =(!m_cfg.useBB) || (low1 <=m_snap.bbLower);
   bool touchHigh=(!m_cfg.useBB) || (high1>=m_snap.bbUpper);
   bool closeAboveBB=(!m_cfg.useBB) || (close1>m_snap.bbUpper);
   bool closeBelowBB=(!m_cfg.useBB) || (close1<m_snap.bbLower);

   if(m_cfg.useHTF)
     {
      if(m_htfFast<=m_htfSlow) bullTrend=false;
      if(m_htfFast>=m_htfSlow) bearTrend=false;
     }

   if(m_snap.regime==AE_REGIME_QUIET)
     { reason="QUIET — no trade"; return(AE_SIG_NONE); }
   if(m_snap.regime==AE_REGIME_VOLATILE)
     { reason="VOLATILE — stand aside"; return(AE_SIG_NONE); }

   ENUM_AE_STRATEGY st=m_snap.activeStrat;
   ENUM_AE_SIGNAL sig=AE_SIG_NONE;

   if(st==AE_STRAT_TREND || st==AE_STRAT_SCALP)
     {
      if(m_cfg.useADX && !adxOk) { reason="ADX weak"; return(AE_SIG_NONE); }
      if(bullTrend && rsiBuy && macdBuy && diBuy)
        { reason="TREND confluence BUY"; sig=AE_SIG_BUY; }
      else if(bearTrend && rsiSell && macdSell && diSell)
        { reason="TREND confluence SELL"; sig=AE_SIG_SELL; }
      else { reason="no-trend-confluence"; return(AE_SIG_NONE); }
     }
   else if(st==AE_STRAT_RANGE)
     {
      if(touchLow && rsiOs && close1>open1)
        { reason="RANGE bounce BUY"; sig=AE_SIG_BUY; }
      else if(touchHigh && rsiOb && close1<open1)
        { reason="RANGE fade SELL"; sig=AE_SIG_SELL; }
      else { reason="no-range-edge"; return(AE_SIG_NONE); }
     }
   else if(st==AE_STRAT_BREAKOUT)
     {
      if(closeAboveBB && macdBuy && bullTrend)
        { reason="BREAKOUT BUY"; sig=AE_SIG_BUY; }
      else if(closeBelowBB && macdSell && bearTrend)
        { reason="BREAKOUT SELL"; sig=AE_SIG_SELL; }
      else { reason="no-breakout"; return(AE_SIG_NONE); }
     }
   else
     {
      reason="idle";
      return(AE_SIG_NONE);
     }

   if(m_cfg.usePullback && st==AE_STRAT_TREND && sig!=AE_SIG_NONE)
     {
      bool pbBuy =(low1<=m_snap.emaF || low1<=m_snap.emaS) && close1>open1;
      bool pbSell=(high1>=m_snap.emaF || high1>=m_snap.emaS) && close1<open1;
      if(sig==AE_SIG_BUY  && !pbBuy)  { reason="no EMA pullback"; return(AE_SIG_NONE); }
      if(sig==AE_SIG_SELL && !pbSell) { reason="no EMA pullback"; return(AE_SIG_NONE); }
      reason=reason+" +pullback";
     }

   if(m_cfg.confirmBars>0 && sig!=AE_SIG_NONE)
     {
      for(int k=1;k<=m_cfg.confirmBars;k++)
        {
         double ck=iClose(m_symbol,m_tf,k);
         double ok=iOpen(m_symbol,m_tf,k);
         if(ck<=0) { reason="confirm-no-bar"; return(AE_SIG_NONE); }
         if(sig==AE_SIG_BUY  && ck<ok) { reason="confirm bars disagree"; return(AE_SIG_NONE); }
         if(sig==AE_SIG_SELL && ck>ok) { reason="confirm bars disagree"; return(AE_SIG_NONE); }
        }
      reason=reason+" +"+IntegerToString(m_cfg.confirmBars)+" bar confirm";
     }
   return(sig);
  }

//+------------------------------------------------------------------+
bool CAetherionEngine::SessionAllows()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt);
   const int h=dt.hour;
   const ENUM_AE_ASSET a=m_snap.asset;

   // Crypto / USDT: 24/7 (some brokers still close weekends — respect trade mode)
   long tradeMode=(long)SymbolInfoInteger(m_symbol,SYMBOL_TRADE_MODE);
   if(tradeMode==SYMBOL_TRADE_MODE_CLOSEONLY || tradeMode==SYMBOL_TRADE_MODE_DISABLED)
      return(false);

   if(RolloverBlocked())
      return(false);

   if(a==AE_ASSET_CRYPTO || a==AE_ASSET_USDT)
     {
      // still honour Friday/Monday if the broker actually closes FX-style
      return(true);
     }

   if(!m_cfg.sessionFilter)
      return(true);

   if(dt.day_of_week==0) // Sunday
     {
      if(m_cfg.mondayDelayHours>0 && h<m_cfg.mondayDelayHours)
         return(false);
     }
   if(dt.day_of_week==1 && m_cfg.mondayDelayHours>0 && h<m_cfg.mondayDelayHours)
      return(false);
   if(dt.day_of_week==5 && m_cfg.fridayCutoffHour>0)
     {
      int cut=m_cfg.fridayCutoffHour;
      if(m_cfg.fridayFlatten) cut=MathMax(0,cut-1);
      if(h>=cut) return(false);
     }
   if(dt.day_of_week==6) // Saturday
      return(false);

   if(m_cfg.avoidNewsWindow)
     {
      int a0=m_cfg.newsHourStart,a1=m_cfg.newsHourEnd;
      if(a0<=a1) { if(h>=a0 && h<a1) return(false); }
      else       { if(h>=a0 || h<a1) return(false); }
     }

   int sh=h;
   if(m_cfg.serverUtcOffset!=0)
      sh=(h-m_cfg.serverUtcOffset+48)%24;
   bool inAsia,inLon,inNY;
   if(m_cfg.serverUtcOffset!=0)
     {
      inAsia=(sh>=0 && sh<8);
      inLon =(sh>=7 && sh<16);
      inNY  =(sh>=12 && sh<21);
     }
   else
     {
      inAsia=(h>=0 && h<8);
      inLon =(h>=8 && h<16);
      inNY  =(h>=13 && h<22);
     }
   bool ok=false;
   if(m_cfg.tradeAsia && inAsia) ok=true;
   if(m_cfg.tradeLondon && inLon) ok=true;
   if(m_cfg.tradeNY && inNY) ok=true;
   return(ok);
  }

bool CAetherionEngine::RolloverBlocked()
  {
   if(!m_cfg.rolloverPause) return(false);
   if(m_snap.asset==AE_ASSET_CRYPTO || m_snap.asset==AE_ASSET_USDT)
      return(false);
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt);
   if(dt.hour==23 && dt.min>=50) return(true);
   if(dt.hour==0  && dt.min<=20) return(true);
   return(false);
  }

bool CAetherionEngine::WeekendProtect()
  {
   if(!m_cfg.fridayFlatten) return(false);
   if(m_snap.asset==AE_ASSET_CRYPTO || m_snap.asset==AE_ASSET_USDT)
      return(false);
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt);
   if(dt.day_of_week==6) return(true);
   if(dt.day_of_week==5 && m_cfg.fridayCutoffHour>0)
     {
      int start=MathMax(0,m_cfg.fridayCutoffHour-1);
      if(dt.hour>=start) return(true);
     }
   return(false);
  }

void CAetherionEngine::MaybeWeekendFlatten()
  {
   if(!WeekendProtect()) return;
   if(CountMagic()<=0) return;
   FlattenAll("friday-flatten");
  }

ENUM_TIMEFRAMES CAetherionEngine::HigherTF(const ENUM_TIMEFRAMES tf)
  {
   if(tf<=PERIOD_M5)  return(PERIOD_M15);
   if(tf<=PERIOD_M15) return(PERIOD_H1);
   if(tf<=PERIOD_M30) return(PERIOD_H1);
   if(tf<=PERIOD_H1)  return(PERIOD_H4);
   if(tf<=PERIOD_H4)  return(PERIOD_D1);
   return(PERIOD_W1);
  }

bool CAetherionEngine::SpreadAllows()
  {
   int cap=m_cfg.maxSpreadPoints;
   if(m_cfg.autoSpread)
      cap=ProfileMaxSpread();
   if(cap>0 && m_snap.spreadPts>cap)
      return(false);
   if(m_cfg.spreadATRMax>0 && m_snap.atr>0 && m_snap.spreadPrice>m_snap.atr*m_cfg.spreadATRMax)
      return(false);
   return(true);
  }

bool CAetherionEngine::RiskAllows(string &why)
  {
   why="";
   if(m_halted) { why="HALTED"; return(false); }
   if(m_cfg.maxDailyLossPct>0 && m_dayStartEquity>0)
     {
      double dd=100.0*(m_dayStartEquity-m_snap.equity)/m_dayStartEquity;
      if(dd>=m_cfg.maxDailyLossPct)
        {
         why="DAILY LOSS";
         if(m_cfg.emergencyClose) FlattenAll("daily-loss");
         m_halted=true;
         return(false);
        }
     }
   if(m_cfg.maxDrawdownPct>0 && m_snap.drawdownPct>=m_cfg.maxDrawdownPct)
     {
      why="MAX DD";
      if(m_cfg.emergencyClose) FlattenAll("max-dd");
      m_halted=true;
      return(false);
     }
   if(m_cfg.maxTradesDay>0 && m_tradesToday>=m_cfg.maxTradesDay)
     { why="DAY CAP"; return(false); }
   if(CountMagic()>=m_cfg.maxPositions)
     { why="MAX POS"; return(false); }
   if(CountSymbol()>=m_cfg.maxPerSymbol)
     { why="SYM CAP"; return(false); }
   if(m_cfg.cooldownBars>0 && m_lastEntryBar>0)
     {
      int shift=iBarShift(m_symbol,m_tf,m_lastEntryBar,false);
      if(shift>=0 && shift<m_cfg.cooldownBars)
        { why="COOLDOWN"; return(false); }
     }
   if(m_cfg.lossStreakMax>0 && m_lossStreak>=m_cfg.lossStreakMax && m_streakPauseBar>0)
     {
      int sh=iBarShift(m_symbol,m_tf,m_streakPauseBar,false);
      if(sh>=0 && sh<m_cfg.lossStreakBars)
        { why="STREAK"; return(false); }
     }
   return(true);
  }

//+------------------------------------------------------------------+
bool CAetherionEngine::NewBar()
  {
   datetime t=iTime(m_symbol,m_tf,0);
   if(t==0) return(false);
   if(t!=m_lastBarTime)
     {
      m_lastBarTime=t;
      return(true);
     }
   return(false);
  }

bool CAetherionEngine::GapBar()
  {
   if(!m_cfg.indexGapFilter) return(false);
   if(m_snap.asset!=AE_ASSET_INDEX && m_snap.asset!=AE_ASSET_STOCK &&
      m_snap.asset!=AE_ASSET_METAL && m_snap.asset!=AE_ASSET_ENERGY) return(false);
   double c1=iClose(m_symbol,m_tf,2);
   double o1=iOpen(m_symbol,m_tf,1);
   if(c1<=0 || o1<=0 || m_snap.atr<=0) return(false);
   return(MathAbs(o1-c1)>m_snap.atr*1.5);
  }

int CAetherionEngine::CountMagic()
  {
   int n=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!m_pos.SelectByIndex(i)) continue;
      if(m_pos.Magic()==m_cfg.magic) n++;
     }
   return(n);
  }

int CAetherionEngine::CountSymbol()
  {
   int n=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!m_pos.SelectByIndex(i)) continue;
      if(m_pos.Magic()==m_cfg.magic && m_pos.Symbol()==m_symbol) n++;
     }
   return(n);
  }

double CAetherionEngine::ProfileATRSL()
  {
   if(!m_cfg.useAssetProfiles) return(m_cfg.atrSL);
   switch(m_snap.asset)
     {
      case AE_ASSET_CRYPTO:
      case AE_ASSET_USDT:   return(m_cfg.cryptoATRSL);
      case AE_ASSET_METAL:  return(m_cfg.metalATRSL);
      case AE_ASSET_INDEX:
      case AE_ASSET_ENERGY: return(m_cfg.indexATRSL);
      default:              return(m_cfg.atrSL);
     }
  }

double CAetherionEngine::ProfileRiskPct()
  {
   double r=m_cfg.riskPercent;
   if(m_cfg.useAssetProfiles && (m_snap.asset==AE_ASSET_CRYPTO || m_snap.asset==AE_ASSET_USDT))
      r*=m_cfg.cryptoRiskScale;
   return(r);
  }

int CAetherionEngine::ProfileMaxSpread()
  {
   if(m_cfg.maxSpreadPoints>0 && !m_cfg.autoSpread)
      return(m_cfg.maxSpreadPoints);
   // points, not pips — works for 2/3/4/5 digit and crypto
   switch(m_snap.asset)
     {
      case AE_ASSET_FOREX:  return(m_snap.digits>=4 ? 30 : 30);
      case AE_ASSET_METAL:  return(80);
      case AE_ASSET_ENERGY: return(120);
      case AE_ASSET_INDEX:  return(250);
      case AE_ASSET_STOCK:  return(200);
      case AE_ASSET_CRYPTO:
      case AE_ASSET_USDT:   return(400);
      default:              return(m_cfg.maxSpreadPoints>0?m_cfg.maxSpreadPoints:50);
     }
  }

//+------------------------------------------------------------------+
double CAetherionEngine::NormalizeVolume(double lots)
  {
   double vmin=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_MIN);
   double vmax=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_STEP);
   double vlim=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_LIMIT);
   if(vmin<=0) vmin=0.01;
   if(step<=0) step=0.01;
   if(m_cfg.minLot>0) vmin=MathMax(vmin,m_cfg.minLot);
   if(m_cfg.maxLot>0) vmax=(vmax>0?MathMin(vmax,m_cfg.maxLot):m_cfg.maxLot);
   if(vlim>0)
     {
      double used=0;
      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         if(!m_pos.SelectByIndex(i)) continue;
         if(m_pos.Symbol()==m_symbol) used+=m_pos.Volume();
        }
      vmax=MathMin(vmax,MathMax(0,vlim-used));
     }
   int vdig=0;
   double probe=step;
   while(vdig<8)
     {
      double p=MathPow(10,vdig);
      if(MathAbs(MathRound(probe*p)-probe*p)<1e-8) break;
      vdig++;
     }
   lots=MathFloor(lots/step+1e-12)*step;
   lots=NormalizeDouble(lots,vdig);
   if(lots<vmin) lots=vmin;
   if(vmax>0 && lots>vmax) lots=vmax;
   return(lots);
  }

double CAetherionEngine::NormalizePrice(const double price)
  {
   double tick=SymbolInfoDouble(m_symbol,SYMBOL_TRADE_TICK_SIZE);
   int digits=(int)SymbolInfoInteger(m_symbol,SYMBOL_DIGITS);
   if(tick<=0) return(NormalizeDouble(price,digits));
   return(NormalizeDouble(MathRound(price/tick)*tick,digits));
  }

bool CAetherionEngine::StopsValid(const ENUM_ORDER_TYPE type,double &sl,double &tp)
  {
   double point=SymbolInfoDouble(m_symbol,SYMBOL_POINT);
   int stops=(int)SymbolInfoInteger(m_symbol,SYMBOL_TRADE_STOPS_LEVEL);
   int freeze=(int)SymbolInfoInteger(m_symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   int lvl=MathMax(stops,freeze);
   // ECN often reports 0 — enforce a 2-point minimum safety
   if(lvl<=0) lvl=2;
   double minDist=lvl*point;

   if(type==ORDER_TYPE_BUY)
     {
      if(sl>0 && (m_snap.bid-sl)<minDist) sl=NormalizePrice(m_snap.bid-minDist);
      if(tp>0 && (tp-m_snap.ask)<minDist) tp=NormalizePrice(m_snap.ask+minDist);
      if(sl>0 && sl>=m_snap.bid) return(false);
      if(tp>0 && tp<=m_snap.ask) return(false);
     }
   else
     {
      if(sl>0 && (sl-m_snap.ask)<minDist) sl=NormalizePrice(m_snap.ask+minDist);
      if(tp>0 && (m_snap.bid-tp)<minDist) tp=NormalizePrice(m_snap.bid-minDist);
      if(sl>0 && sl<=m_snap.ask) return(false);
      if(tp>0 && tp>=m_snap.bid) return(false);
     }
   sl=(sl>0?NormalizePrice(sl):0);
   tp=(tp>0?NormalizePrice(tp):0);
   return(true);
  }

double CAetherionEngine::CalcLots(const double slDistance)
  {
   double lots=m_cfg.fixedLot;
   if(m_cfg.lotMode==AE_LOT_STEP)
     {
      double steps=(m_cfg.equityStep>0 ? m_acc.Equity()/m_cfg.equityStep : 1);
      lots=steps*m_cfg.lotPerStep;
     }
   else if(m_cfg.lotMode==AE_LOT_RISK)
     {
      double riskMoney=m_acc.Equity()*ProfileRiskPct()/100.0;
      double tickSize=SymbolInfoDouble(m_symbol,SYMBOL_TRADE_TICK_SIZE);
      double tickVal =SymbolInfoDouble(m_symbol,SYMBOL_TRADE_TICK_VALUE);
      if(tickSize>0 && tickVal>0 && slDistance>0)
        {
         double lossPerLot=(slDistance/tickSize)*tickVal;
         if(lossPerLot>0)
            lots=riskMoney/lossPerLot;
        }
     }
   // margin cap
   double margin=0;
   ENUM_ORDER_TYPE t=ORDER_TYPE_BUY;
   if(OrderCalcMargin(t,m_symbol,lots,m_snap.ask,margin) && margin>0)
     {
      double free=m_acc.FreeMargin();
      if(margin>free*0.6)
        {
         double scale=(free*0.6)/margin;
         lots*=scale;
        }
     }
   return(NormalizeVolume(lots));
  }

//+------------------------------------------------------------------+
bool CAetherionEngine::OpenPosition(const ENUM_AE_SIGNAL sig,const string reason)
  {
   if(sig==AE_SIG_NONE) return(false);
   if(sig==AE_SIG_BUY && !m_cfg.allowBuy) return(false);
   if(sig==AE_SIG_SELL && !m_cfg.allowSell) return(false);

   if(m_cfg.closeOnOpposite)
     {
      for(int i=PositionsTotal()-1;i>=0;i--)
        {
         if(!m_pos.SelectByIndex(i)) continue;
         if(m_pos.Magic()!=m_cfg.magic || m_pos.Symbol()!=m_symbol) continue;
         if((sig==AE_SIG_BUY && m_pos.PositionType()==POSITION_TYPE_SELL) ||
            (sig==AE_SIG_SELL && m_pos.PositionType()==POSITION_TYPE_BUY))
            CloseTicket(m_pos.Ticket(),"opposite");
        }
     }

   if(m_cfg.oneDirection && CountSymbol()>0)
      return(false);

   UpdateQuotes();
   double atrSL=ProfileATRSL();
   double slDist=0;
   if(m_cfg.slPoints>0) slDist=m_cfg.slPoints*m_snap.point;
   else slDist=m_snap.atr*atrSL;
   if(slDist<=0) slDist=50*m_snap.point;

   double tpDist=0;
   if(m_cfg.tpPoints>0) tpDist=m_cfg.tpPoints*m_snap.point;
   else if(m_cfg.useRR && m_cfg.rr>0) tpDist=slDist*m_cfg.rr;
   else tpDist=m_snap.atr*m_cfg.atrTP;

   double price=0,sl=0,tp=0;
   ENUM_ORDER_TYPE otype;
   if(sig==AE_SIG_BUY)
     {
      otype=ORDER_TYPE_BUY;
      price=m_snap.ask;
      sl=(m_cfg.useSL? price-slDist:0);
      tp=(m_cfg.useTP? price+tpDist:0);
     }
   else
     {
      otype=ORDER_TYPE_SELL;
      price=m_snap.bid;
      sl=(m_cfg.useSL? price+slDist:0);
      tp=(m_cfg.useTP? price-tpDist:0);
     }

   if(!StopsValid(otype,sl,tp))
     {
      Log("invalid stops after normalize — skip");
      return(false);
     }

   double lots=CalcLots(slDist);
   if(lots<=0)
     {
      Log("lot size zero after normalize");
      return(false);
     }

   // refresh filling each send — some symbols flip on session
   m_filling=DetectFilling(m_symbol);
   m_trade.SetTypeFilling(m_filling);
   m_trade.SetExpertMagicNumber(m_cfg.magic);
   m_trade.SetDeviationInPoints((ulong)m_cfg.slippage);

   bool ok=false;
   for(int attempt=0; attempt<m_cfg.maxRetries && !ok; attempt++)
     {
      m_sym.RefreshRates();
      UpdateQuotes();
      if(sig==AE_SIG_BUY) price=m_snap.ask; else price=m_snap.bid;
      if(sig==AE_SIG_BUY)
        {
         sl=(m_cfg.useSL? price-slDist:0);
         tp=(m_cfg.useTP? price+tpDist:0);
        }
      else
        {
         sl=(m_cfg.useSL? price+slDist:0);
         tp=(m_cfg.useTP? price-tpDist:0);
        }
      StopsValid(otype,sl,tp);

      if(sig==AE_SIG_BUY)
         ok=m_trade.Buy(lots,m_symbol,price,sl,tp,m_cfg.comment);
      else
         ok=m_trade.Sell(lots,m_symbol,price,sl,tp,m_cfg.comment);

      uint rc=m_trade.ResultRetcode();
      if(ok && (rc==TRADE_RETCODE_DONE || rc==TRADE_RETCODE_PLACED || rc==TRADE_RETCODE_DONE_PARTIAL))
        {
         m_tradesToday++;
         m_lastEntryBar=iTime(m_symbol,m_tf,0);
         m_snap.lastSignal=sig;
         m_snap.lastReason=reason;
         Log((sig==AE_SIG_BUY?"BUY ":"SELL ")+DoubleToString(lots,2)+
             " @ "+DoubleToString(price,m_snap.digits)+
             " SL "+DoubleToString(sl,m_snap.digits)+
             " TP "+DoubleToString(tp,m_snap.digits)+
             " | "+reason+" | fill="+FillingName(m_filling));
         return(true);
        }

      // unsupported filling — cycle FOK/IOC/RETURN
      if(rc==TRADE_RETCODE_INVALID_FILL)
        {
         if(m_filling==ORDER_FILLING_IOC)      m_filling=ORDER_FILLING_FOK;
         else if(m_filling==ORDER_FILLING_FOK) m_filling=ORDER_FILLING_RETURN;
         else                                  m_filling=ORDER_FILLING_IOC;
         m_trade.SetTypeFilling(m_filling);
         Log("fill mode rejected, retry "+FillingName(m_filling));
         continue;
        }
      if(rc==TRADE_RETCODE_REQUOTE || rc==TRADE_RETCODE_PRICE_CHANGED || rc==TRADE_RETCODE_PRICE_OFF)
        {
         if(!m_cfg.retryRequote) break;
         Log("requote/price changed — retry");
         continue;
        }
      Log("OrderSend fail ret="+IntegerToString((int)rc)+" "+m_trade.ResultRetcodeDescription());
      break;
     }
   return(false);
  }

//+------------------------------------------------------------------+
void CAetherionEngine::ManagePositions()
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!m_pos.SelectByIndex(i)) continue;
      if(m_pos.Magic()!=m_cfg.magic || m_pos.Symbol()!=m_symbol) continue;

      const ulong ticket=m_pos.Ticket();
      const long type=m_pos.PositionType();
      const double open=m_pos.PriceOpen();
      const double sl=m_pos.StopLoss();
      const double tp=m_pos.TakeProfit();
      const double vol=m_pos.Volume();
      const double bid=m_snap.bid;
      const double ask=m_snap.ask;
      const double atr=m_snap.atr;

      double beTrig=(m_cfg.beTriggerPoints>0? m_cfg.beTriggerPoints*m_snap.point : atr*0.8);
      double lock  =m_cfg.beLockPoints*m_snap.point;
      double trailStart=(m_cfg.trailStartPoints>0? m_cfg.trailStartPoints*m_snap.point : atr*m_cfg.atrTrail);
      double trailStep =(m_cfg.trailStepPoints>0? m_cfg.trailStepPoints*m_snap.point : atr*0.4);

      // partial
      if(m_cfg.partialClose && !AlreadyPartial(ticket) && m_cfg.partialRR>0)
        {
         double risk=MathAbs((sl>0? sl-open : atr*ProfileATRSL()));
         double target=risk*m_cfg.partialRR;
         bool hit=false;
         if(type==POSITION_TYPE_BUY  && bid>=open+target) hit=true;
         if(type==POSITION_TYPE_SELL && ask<=open-target) hit=true;
         if(hit)
           {
            double vmin=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_MIN);
            double step=SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_STEP);
            double part=NormalizeVolume(vol*m_cfg.partialPercent/100.0);
            if(part>=vmin && (vol-part)>=vmin-1e-8)
              {
               if(m_trade.PositionClosePartial(ticket,part))
                 {
                  MarkPartial(ticket);
                  Log("partial close "+DoubleToString(part,2)+" ticket "+IntegerToString((int)ticket));
                  if(m_pos.SelectByTicket(ticket))
                    {
                     double lock=m_cfg.beLockPoints*m_snap.point;
                     double beSL=(type==POSITION_TYPE_BUY
                                  ? NormalizePrice(open+lock)
                                  : NormalizePrice(open-lock));
                     bool better=(type==POSITION_TYPE_BUY
                                  ? (m_pos.StopLoss()==0 || beSL>m_pos.StopLoss())
                                  : (m_pos.StopLoss()==0 || beSL<m_pos.StopLoss()));
                     if(better && !m_trade.PositionModify(ticket,beSL,m_pos.TakeProfit()))
                        Log("BE after partial fail "+m_trade.ResultRetcodeDescription());
                     else if(better)
                        Log("SL -> BE after partial");
                    }
                 }
              }
           }
        }

      double newSL=sl;
      bool modify=false;

      if(m_cfg.breakeven && beTrig>0)
        {
         if(type==POSITION_TYPE_BUY && bid>=open+beTrig)
           {
            double candidate=NormalizePrice(open+lock);
            if(candidate>sl || sl==0) { newSL=candidate; modify=true; }
           }
         if(type==POSITION_TYPE_SELL && ask<=open-beTrig)
           {
            double candidate=NormalizePrice(open-lock);
            if(sl==0 || candidate<sl) { newSL=candidate; modify=true; }
           }
        }

      if(m_cfg.trailing && trailStart>0 && trailStep>0)
        {
         if(type==POSITION_TYPE_BUY && bid>=open+trailStart)
           {
            double candidate=NormalizePrice(bid-trailStep);
            if(candidate>newSL) { newSL=candidate; modify=true; }
           }
         if(type==POSITION_TYPE_SELL && ask<=open-trailStart)
           {
            double candidate=NormalizePrice(ask+trailStep);
            if(newSL==0 || candidate<newSL) { newSL=candidate; modify=true; }
           }
        }

      if(modify)
        {
         int freeze=(int)SymbolInfoInteger(m_symbol,SYMBOL_TRADE_FREEZE_LEVEL);
         double minDist=MathMax(freeze,2)*m_snap.point;
         if(type==POSITION_TYPE_BUY  && (bid-newSL)<minDist) continue;
         if(type==POSITION_TYPE_SELL && (newSL-ask)<minDist) continue;
         if(!m_trade.PositionModify(ticket,newSL,tp))
            Log("modify fail "+m_trade.ResultRetcodeDescription());
        }
     }
   MaybeTimeExit();
  }

void CAetherionEngine::MaybeTimeExit()
  {
   int limit=m_cfg.maxHoldBars;
   bool crypto=(m_snap.asset==AE_ASSET_CRYPTO || m_snap.asset==AE_ASSET_USDT);
   if(limit<=0 && m_cfg.maxHoldHours>0 && !crypto)
     {
      int sec=(int)PeriodSeconds(m_tf);
      if(sec<=0) sec=3600;
      limit=(int)MathMax(1,(m_cfg.maxHoldHours*3600.0)/sec);
     }
   if(limit<=0) return;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!m_pos.SelectByIndex(i)) continue;
      if(m_pos.Magic()!=m_cfg.magic || m_pos.Symbol()!=m_symbol) continue;
      int sh=iBarShift(m_symbol,m_tf,m_pos.Time(),false);
      if(sh>=limit)
         CloseTicket(m_pos.Ticket(),"time-exit");
     }
  }

void CAetherionEngine::CloseTicket(const ulong ticket,const string why)
  {
   if(m_trade.PositionClose(ticket))
      Log("closed "+IntegerToString((int)ticket)+" "+why);
   else
      Log("close fail "+IntegerToString((int)ticket)+" "+m_trade.ResultRetcodeDescription());
  }

void CAetherionEngine::FlattenAll(const string why)
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!m_pos.SelectByIndex(i)) continue;
      if(m_pos.Magic()!=m_cfg.magic) continue;
      CloseTicket(m_pos.Ticket(),why);
     }
  }

bool CAetherionEngine::AlreadyPartial(const ulong ticket)
  {
   int n=ArraySize(m_partialDone);
   for(int i=0;i<n;i++) if(m_partialDone[i]==ticket) return(true);
   return(false);
  }

void CAetherionEngine::MarkPartial(const ulong ticket)
  {
   int n=ArraySize(m_partialDone);
   ArrayResize(m_partialDone,n+1);
   m_partialDone[n]=ticket;
  }

//+------------------------------------------------------------------+
void CAetherionEngine::OnTick()
  {
   ResetDayIfNeeded();
   UpdateQuotes();
   if(!UpdateIndicators())
      return;
   DetectRegime();
   MaybeWeekendFlatten();
   ManagePositions();

   bool go=true;
   if(m_cfg.signalOnNewBar)
      go=NewBar();
   else
      NewBar(); // still track

   if(!go) return;
   if(GapBar()) { m_snap.blockReason="GAP"; return; }

   if(SpreadAllows()) m_spreadOkStreak++;
   else               m_spreadOkStreak=0;

   string why;
   if(!RiskAllows(why)) { m_snap.blockReason=why; return; }
   if(!SpreadAllows())  { m_snap.blockReason="SPREAD"; return; }
   if(m_cfg.spreadStableBars>0 && m_spreadOkStreak<m_cfg.spreadStableBars)
     { m_snap.blockReason="SPREAD WAIT"; return; }
   if(!SessionAllows()) { m_snap.blockReason=RolloverBlocked()?"ROLLOVER":"SESSION"; return; }
   if(!m_snap.tradeAllowed) { m_snap.blockReason="ALGO OFF"; return; }

   string reason;
   ENUM_AE_SIGNAL sig=ComputeSignal(reason);
   m_snap.lastReason=reason;
   if(sig!=AE_SIG_NONE)
     {
      m_snap.lastSignal=sig;
      OpenPosition(sig,reason);
     }
  }

//+------------------------------------------------------------------+
void CAetherionEngine::OnTradeTransaction(const MqlTradeTransaction &trans,
                                          const MqlTradeRequest &request,
                                          const MqlTradeResult &result)
  {
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD)
      return;
   ulong deal=trans.deal;
   if(deal==0) return;
   if(!HistoryDealSelect(deal)) return;
   if((long)HistoryDealGetInteger(deal,DEAL_MAGIC)!=m_cfg.magic) return;
   if(HistoryDealGetString(deal,DEAL_SYMBOL)!=m_symbol) return;

   long entry=(long)HistoryDealGetInteger(deal,DEAL_ENTRY);
   if(entry!=DEAL_ENTRY_OUT && entry!=DEAL_ENTRY_INOUT && entry!=DEAL_ENTRY_OUT_BY)
      return;
   double profit=HistoryDealGetDouble(deal,DEAL_PROFIT)
                +HistoryDealGetDouble(deal,DEAL_SWAP)
                +HistoryDealGetDouble(deal,DEAL_COMMISSION);
   m_netProfit+=profit;
   if(profit>=0)
     {
      m_wins++;
      m_grossWin+=profit;
      m_lossStreak=0;
     }
   else
     {
      m_losses++;
      m_grossLoss+=profit;
      m_lossStreak++;
      if(m_cfg.lossStreakMax>0 && m_lossStreak>=m_cfg.lossStreakMax)
         m_streakPauseBar=iTime(m_symbol,m_tf,0);
     }
  }

double CAetherionEngine::TesterScore()
  {
   double pf=m_snap.profitFactor;
   if(pf<=0) pf=0;
   if(pf>10) pf=10;
   int n=m_wins+m_losses;
   double dd=MathMax(m_snap.drawdownPct,1.0);
   // robust custom metric for genetic optimisation
   return(pf * MathSqrt((double)MathMax(n,1)) * (m_netProfit>0?1.0:0.25) / dd);
  }

//+------------------------------------------------------------------+
void CAetherionEngine::PurgeVisuals()
  {
   int total=ObjectsTotal(0,-1,-1);
   for(int i=total-1;i>=0;i--)
     {
      string name=ObjectName(0,i,-1,-1);
      if(StringFind(name,m_pfx)==0)
         ObjectDelete(0,name);
     }
  }

void CAetherionEngine::DrawLiveTrades()
  {
   if(!m_cfg.showTradesOnChart) return;
   // remove stale AE lines then redraw current positions
   int total=ObjectsTotal(0,0,-1);
   for(int i=total-1;i>=0;i--)
     {
      string name=ObjectName(0,i,0,-1);
      if(StringFind(name,m_pfx+"TR_")==0)
         ObjectDelete(0,name);
     }

   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!m_pos.SelectByIndex(i)) continue;
      if(m_pos.Magic()!=m_cfg.magic || m_pos.Symbol()!=m_symbol) continue;
      ulong t=m_pos.Ticket();
      bool buy=(m_pos.PositionType()==POSITION_TYPE_BUY);
      color cOpen =(buy? clrAqua:clrHotPink);
      color cSL   =clrTomato;
      color cTP   =clrLime;
      string nOpen=m_pfx+"TR_OP_"+IntegerToString((int)t);
      string nSL  =m_pfx+"TR_SL_"+IntegerToString((int)t);
      string nTP  =m_pfx+"TR_TP_"+IntegerToString((int)t);
      string nArr =m_pfx+"TR_AR_"+IntegerToString((int)t);

      ObjectCreate(0,nOpen,OBJ_HLINE,0,0,m_pos.PriceOpen());
      ObjectSetInteger(0,nOpen,OBJPROP_COLOR,cOpen);
      ObjectSetInteger(0,nOpen,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(0,nOpen,OBJPROP_WIDTH,1);
      ObjectSetInteger(0,nOpen,OBJPROP_BACK,true);
      ObjectSetInteger(0,nOpen,OBJPROP_SELECTABLE,false);
      ObjectSetString(0,nOpen,OBJPROP_TOOLTIP,"AETHERION open "+DoubleToString(m_pos.PriceOpen(),m_snap.digits));

      if(m_pos.StopLoss()>0)
        {
         ObjectCreate(0,nSL,OBJ_HLINE,0,0,m_pos.StopLoss());
         ObjectSetInteger(0,nSL,OBJPROP_COLOR,cSL);
         ObjectSetInteger(0,nSL,OBJPROP_STYLE,STYLE_DOT);
         ObjectSetInteger(0,nSL,OBJPROP_WIDTH,1);
         ObjectSetInteger(0,nSL,OBJPROP_SELECTABLE,false);
        }
      if(m_pos.TakeProfit()>0)
        {
         ObjectCreate(0,nTP,OBJ_HLINE,0,0,m_pos.TakeProfit());
         ObjectSetInteger(0,nTP,OBJPROP_COLOR,cTP);
         ObjectSetInteger(0,nTP,OBJPROP_STYLE,STYLE_DOT);
         ObjectSetInteger(0,nTP,OBJPROP_WIDTH,1);
         ObjectSetInteger(0,nTP,OBJPROP_SELECTABLE,false);
        }
      ObjectCreate(0,nArr,OBJ_ARROW,0,m_pos.Time(),m_pos.PriceOpen());
      ObjectSetInteger(0,nArr,OBJPROP_ARROWCODE,buy?233:234);
      ObjectSetInteger(0,nArr,OBJPROP_COLOR,cOpen);
      ObjectSetInteger(0,nArr,OBJPROP_WIDTH,2);
      ObjectSetInteger(0,nArr,OBJPROP_ANCHOR,buy?ANCHOR_TOP:ANCHOR_BOTTOM);
      ObjectSetInteger(0,nArr,OBJPROP_SELECTABLE,false);
     }
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
string CAetherionEngine::TfName(const ENUM_TIMEFRAMES tf)
  {
   switch(tf)
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
      case PERIOD_MN1: return("MN");
      default:         return("TF"+IntegerToString((int)tf));
     }
  }

string CAetherionEngine::AssetName(const ENUM_AE_ASSET a)
  {
   switch(a)
     {
      case AE_ASSET_FOREX:  return("FOREX");
      case AE_ASSET_CRYPTO: return("CRYPTO");
      case AE_ASSET_USDT:   return("USDT");
      case AE_ASSET_METAL:  return("METAL");
      case AE_ASSET_ENERGY: return("ENERGY");
      case AE_ASSET_INDEX:  return("INDEX");
      case AE_ASSET_STOCK:  return("STOCK");
      default:              return("OTHER");
     }
  }

string CAetherionEngine::RegimeName(const ENUM_AE_REGIME r)
  {
   switch(r)
     {
      case AE_REGIME_TREND:    return("TREND");
      case AE_REGIME_RANGE:    return("RANGE");
      case AE_REGIME_VOLATILE: return("VOLATILE");
      case AE_REGIME_QUIET:    return("QUIET");
      default:                 return("?");
     }
  }

#endif
//+------------------------------------------------------------------+
