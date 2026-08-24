//+------------------------------------------------------------------+
//|                                             AetherionPanel.mqh   |
//|  On-chart HUD — bilingual AR/EN, live spread, trades, regime     |
//+------------------------------------------------------------------+
#ifndef AETHERION_PANEL_MQH
#define AETHERION_PANEL_MQH

class CAetherionPanel
  {
private:
   CAetherionEngine *m_eng;
   int               m_x;
   int               m_y;
   ENUM_AE_LANG      m_lang;
   string            m_pfx;
   bool              m_ready;
   bool              m_collapsed;

   string            T(const string ar,const string en) const;
   void              Box(const string name,const int x,const int y,const int w,const int h,
                         const color bg,const color bd,const int z);
   void              Lab(const string name,const int x,const int y,const int w,const int h,
                         const string text,const color fg,const int size,const int anchor=ALIGN_LEFT);
   void              Kill(const string name);
   string            Money(const double v) const;
   color             Heat(const double v) const;
   string            TfStr(const ENUM_TIMEFRAMES tf) const;
   string            AssetStr(const ENUM_AE_ASSET a) const;
   string            RegimeStr(const ENUM_AE_REGIME r) const;
   string            StratStr(const ENUM_AE_STRATEGY s) const;

public:
                     CAetherionPanel(void):m_eng(NULL),m_ready(false),m_collapsed(false){}
   bool              Init(CAetherionEngine *eng,const int x,const int y,const ENUM_AE_LANG lang);
   void              Destroy(void);
   void              Render(void);
   void              OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
  };

//+------------------------------------------------------------------+
bool CAetherionPanel::Init(CAetherionEngine *eng,const int x,const int y,const ENUM_AE_LANG lang)
  {
   if(eng==NULL) return(false);
   m_eng=eng;
   m_x=x; m_y=y; m_lang=lang;
   m_pfx=eng.Prefix()+"HUD_";
   m_ready=true;
   Render();
   return(true);
  }

void CAetherionPanel::Destroy(void)
  {
   int total=ObjectsTotal(0,-1,-1);
   for(int i=total-1;i>=0;i--)
     {
      string n=ObjectName(0,i,-1,-1);
      if(StringFind(n,m_pfx)==0)
         ObjectDelete(0,n);
     }
   m_ready=false;
  }

string CAetherionPanel::T(const string ar,const string en) const
  {
   return(m_lang==AE_LANG_AR ? ar : en);
  }

void CAetherionPanel::Kill(const string name){ ObjectDelete(0,name); }

void CAetherionPanel::Box(const string name,const int x,const int y,const int w,const int h,
                          const color bg,const color bd,const int z)
  {
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_COLOR,bd);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,z);
  }

void CAetherionPanel::Lab(const string name,const int x,const int y,const int w,const int h,
                          const string text,const color fg,const int size,const int anchor)
  {
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,fg);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetString(0,name,OBJPROP_FONT,"Consolas");
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,20);
  }

string CAetherionPanel::Money(const double v) const
  {
   return((v>=0?"+":"")+DoubleToString(v,2));
  }

color CAetherionPanel::Heat(const double v) const
  {
   if(v>0) return(clrSpringGreen);
   if(v<0) return(clrTomato);
   return(clrSilver);
  }

string CAetherionPanel::TfStr(const ENUM_TIMEFRAMES tf) const
  {
   switch(tf)
     {
      case PERIOD_M1: return("M1"); case PERIOD_M5: return("M5");
      case PERIOD_M15:return("M15");case PERIOD_M30:return("M30");
      case PERIOD_H1: return("H1"); case PERIOD_H4: return("H4");
      case PERIOD_D1: return("D1"); case PERIOD_W1: return("W1");
      case PERIOD_MN1:return("MN"); case PERIOD_H2: return("H2");
      case PERIOD_H6: return("H6"); case PERIOD_H12:return("H12");
      default: return("TF");
     }
  }

string CAetherionPanel::AssetStr(const ENUM_AE_ASSET a) const
  {
   switch(a)
     {
      case AE_ASSET_FOREX:  return(T("فوركس","FOREX"));
      case AE_ASSET_CRYPTO: return(T("كريبتو","CRYPTO"));
      case AE_ASSET_USDT:   return("USDT");
      case AE_ASSET_METAL:  return(T("معادن","METAL"));
      case AE_ASSET_ENERGY: return(T("طاقة","ENERGY"));
      case AE_ASSET_INDEX:  return(T("مؤشر","INDEX"));
      case AE_ASSET_STOCK:  return(T("سهم","STOCK"));
      default:              return(T("أخرى","OTHER"));
     }
  }

string CAetherionPanel::RegimeStr(const ENUM_AE_REGIME r) const
  {
   switch(r)
     {
      case AE_REGIME_TREND:    return(T("اتجاه","TREND"));
      case AE_REGIME_RANGE:    return(T("نطاق","RANGE"));
      case AE_REGIME_VOLATILE: return(T("تذبذب","VOLATILE"));
      case AE_REGIME_QUIET:    return(T("هدوء","QUIET"));
      default: return("?");
     }
  }

string CAetherionPanel::StratStr(const ENUM_AE_STRATEGY s) const
  {
   switch(s)
     {
      case AE_STRAT_AUTO:     return(T("تلقائي","AUTO"));
      case AE_STRAT_TREND:    return(T("اتجاه","TREND"));
      case AE_STRAT_RANGE:    return(T("نطاق","RANGE"));
      case AE_STRAT_BREAKOUT: return(T("اختراق","BREAK"));
      case AE_STRAT_SCALP:    return(T("سكالب","SCALP"));
      default: return("?");
     }
  }

//+------------------------------------------------------------------+
void CAetherionPanel::Render(void)
  {
   if(!m_ready || m_eng==NULL) return;
   AESnapshot s=m_eng.Snap();
   const int W=312;
   const int H=(m_collapsed?46:318);
   const color bg =C'8,10,22';
   const color bd =C'0,230,255';
   const color gold=C'245,197,66';
   const color dim =C'150,160,190';
   const color cyan=C'0,240,255';

   Box(m_pfx+"BG",m_x,m_y,W,H,bg,bd,5);
   Box(m_pfx+"HD",m_x,m_y,W,46,C'6,8,18',gold,6);

   Lab(m_pfx+"TTL",m_x+12,m_y+8,200,20,"AETHERION",gold,13);
   Lab(m_pfx+"SUB",m_x+12,m_y+26,240,16,
       T("ذكاء تكيّفي متعدد الأصول","ADAPTIVE MULTI-ASSET AI"),dim,8);

   // collapse hit target
   Box(m_pfx+"BTN",m_x+W-36,m_y+10,24,24,C'14,18,36',cyan,8);
   Lab(m_pfx+"BTNL",m_x+W-29,m_y+12,20,20,m_collapsed?"+":"-",cyan,14);

   if(m_collapsed)
     {
      ChartRedraw(0);
      return;
     }

   int y=m_y+56;
   int x=m_x+14;

   Lab(m_pfx+"SYM",x,y,280,18,
       s.symbol+"   ·   "+TfStr(s.tf)+"   ·   "+AssetStr(s.asset),clrWhite,11);
   y+=20;
   Lab(m_pfx+"REG",x,y,280,16,
       T("النظام ","REGIME ")+RegimeStr(s.regime)+"   "+T("الاستراتيجية ","STRAT ")+StratStr(s.activeStrat),
       cyan,9);
   y+=22;

   color spc=(s.spreadOk? clrSpringGreen:clrOrangeRed);
   Lab(m_pfx+"SP",x,y,290,16,
       T("السبريد الحي ","LIVE SPREAD ")+DoubleToString(s.spreadPts,1)+" pt   "+
       DoubleToString(s.spreadPrice,s.digits),spc,10);
   y+=18;
   Lab(m_pfx+"BA",x,y,290,16,
       "BID "+DoubleToString(s.bid,s.digits)+"   ASK "+DoubleToString(s.ask,s.digits),dim,9);
   y+=20;

   Lab(m_pfx+"EQ",x,y,290,16,
       T("حقوق ","EQ ")+DoubleToString(s.equity,2)+"   "+T("عائم ","FLT ")+Money(s.floating),
       Heat(s.floating),10);
   y+=18;
   Lab(m_pfx+"DD",x,y,290,16,
       T("ربح اليوم ","DAY ")+Money(s.dailyPnL)+"   DD "+DoubleToString(s.drawdownPct,2)+"%",
       Heat(s.dailyPnL),10);
   y+=20;

   Lab(m_pfx+"ST",x,y,290,16,
       T("صفقات ","POS ")+IntegerToString(s.openPos)+
       T("   اليوم ","  TODAY ")+IntegerToString(s.tradesToday)+
       "   WR "+DoubleToString(s.winRate,1)+"%   PF "+DoubleToString(s.profitFactor,2),
       dim,9);
   y+=20;

   Lab(m_pfx+"IN",x,y,290,16,
       "RSI "+DoubleToString(s.rsi,1)+
       "  ADX "+DoubleToString(s.adx,1)+
       "  ATR "+DoubleToString(s.atr,s.digits),cyan,9);
   y+=18;
   Lab(m_pfx+"EMA",x,y,290,16,
       "EMA "+DoubleToString(s.emaF,s.digits)+" / "+DoubleToString(s.emaS,s.digits)+
       " / "+DoubleToString(s.emaT,s.digits),dim,8);
   y+=20;

   string sig="IDLE";
   color  sc=dim;
   if(s.lastSignal==AE_SIG_BUY)  { sig="BUY";  sc=clrSpringGreen; }
   if(s.lastSignal==AE_SIG_SELL) { sig="SELL"; sc=clrHotPink; }
   Lab(m_pfx+"SG",x,y,290,16,T("إشارة ","SIGNAL ")+sig+"  "+s.lastReason,sc,9);
   y+=20;

   string blk=(s.blockReason==""? T("جاهز","READY"):s.blockReason);
   color  bc=(s.blockReason==""? clrSpringGreen:clrGold);
   if(!s.tradeAllowed) { blk=T("التداول الآلي مغلق","ALGO TRADING OFF"); bc=clrOrangeRed; }
   Lab(m_pfx+"BL",x,y,290,16,T("الحالة ","STATUS ")+blk,bc,10);
   y+=20;

   Lab(m_pfx+"EX",x,y,290,16,
       T("تنفيذ ","EXEC ")+s.execModeName+"  "+T("ملء ","FILL ")+s.fillingName+
       "  SL"+IntegerToString(s.stopsLevel),dim,8);

   ChartRedraw(0);
  }

void CAetherionPanel::OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(!m_ready) return;
   if(id==CHARTEVENT_OBJECT_CLICK && (sparam==m_pfx+"BTN" || sparam==m_pfx+"BTNL"))
     {
      m_collapsed=!m_collapsed;
      if(m_collapsed)
        {
         // hide body labels by redrawing collapsed
        }
      Render();
     }
  }

#endif
//+------------------------------------------------------------------+
