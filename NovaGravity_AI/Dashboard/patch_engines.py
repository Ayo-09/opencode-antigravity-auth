#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Adds: sound engine, adaptive auto-tuner, profit ladder, equity guard,
4 trail modes, live engine cards to the NovaGravity dashboard (v1.02)."""
import re

P = "novagravity_dashboard.html"
s = open(P, encoding="utf-8").read()

# ============ 1) SOUND ENGINE (WebAudio, no files) ============
js_anchor = """/* ---------------- virtual clock ---------------- */"""
sound_js = """/* ---------------- SOUND ENGINE (WebAudio tone synth) ---------------- */
let soundOn=false, audioCtx=null;
const SOUND_DEFS={
  open:{f:[523,659],d:.18,t:"sine"},close:{f:[392,262],d:.22,t:"sine"},
  partial:{f:[659,784],d:.14,t:"triangle"},be:{f:[880],d:.12,t:"triangle"},
  trail:{f:[988,1175],d:.10,t:"triangle"},guard:{f:[220,180],d:.30,t:"sawtooth"},
  switch:{f:[523,659,784,1046],d:.10,t:"sine"},openTrade2:{f:[392,523],d:.16,t:"sine"}
};
function ensureCtx(){try{audioCtx=audioCtx||new (window.AudioContext||window.webkitAudioContext)();return true;}catch(e){return false;}}
function tone(freq,start,dur,type,vol=.14){
  const o=audioCtx.createOscillator(),g=audioCtx.createGain();
  o.type=type;o.frequency.value=freq;o.connect(g);g.connect(audioCtx.destination);
  const t0=audioCtx.currentTime+start;
  g.gain.setValueAtTime(0.0001,t0);
  g.gain.exponentialRampToValueAtTime(vol,t0+.015);
  g.gain.exponentialRampToValueAtTime(0.0001,t0+dur);
  o.start(t0);o.stop(t0+dur+.05);
}
function playSfx(name){
  if(!soundOn||!ensureCtx())return;
  const d=SOUND_DEFS[name]||SOUND_DEFS.open;
  d.f.forEach((f,i)=>tone(f,i*d.d,d.d,d.t));
}
$("chipSound").onclick=()=>{
  soundOn=!soundOn;ensureCtx();
  if(soundOn&&audioCtx&&audioCtx.state==="suspended")audioCtx.resume();
  $("chipSound").textContent=soundOn?"🔊 الصوت: ON":"🔇 الصوت: OFF";
  $("chipSound").classList.toggle("r",!soundOn);
  $("chipSound").classList.toggle("g",soundOn);
  if(soundOn)playSfx("switch");
};

/* ---------------- virtual clock ---------------- */"""
assert js_anchor in s
s = s.replace(js_anchor, sound_js, 1)

# ============ 2) adaptive genome + ladder + guard data in sim ============
s = s.replace("""const MAXBARS=520;
let market={};""",
"""const MAXBARS=520;
let market={};

/* ------ adaptive engine state (auto-tunes, keeps POSITIVE results only) ------ */
const TUNE_BOUNDS={
 partialTriggerRR:[0.6,1.8], partialPct:[20,70], beBufferATR:[0.03,0.30],
 trailStartRR:[0.8,3.0], trailStepATR:[0.2,1.5], slATR:[1.0,4.0],
 tpATR:[1.5,6.0], adxThreshold:[16,32], rsiLevel:[40,60]
};
let tune={genome:{partialTriggerRR:1.0,partialPct:50,beBufferATR:0.10,trailStartRR:1.5,
   trailStepATR:0.5,slATR:2.0,tpATR:3.0,adxThreshold:22,rsiLevel:50},
   records:[],switches:0,lastMsg:"جاري التعلم…",tradesSinceEval:0,bestScore:-1};
function tuneLoad(){try{const v=JSON.parse(localStorage.getItem("ng_tune_v102"));if(v&&v.genome)tune=v;}catch(e){}}
function tuneSave(){try{localStorage.setItem("ng_tune_v102",JSON.stringify(tune));}catch(e){}}
function clampG(g){for(const k in TUNE_BOUNDS){const b=TUNE_BOUNDS[k];g[k]=Math.max(b[0],Math.min(b[1],g[k]));}return g;}
function gCopy(g){return JSON.parse(JSON.stringify(g));}
function gMutate(src){const g=gCopy(src);for(const k in TUNE_BOUNDS){const b=TUNE_BOUNDS[k];g[k]=g[k]+(Math.random()-0.5)*(b[1]-b[0])*0.10;}return clampG(g);}
function recFind(g){return tune.records.findIndex(r=>JSON.stringify(r.g)===JSON.stringify(g));}
function recAdd(g){if(tune.records.length>=40)tune.records.shift();
  tune.records.push({g:gCopy(g),trades:0,wins:0,net:0,peak:0,score:0,active:true,last:Date.now()});}
function tuneLearn(net){
  if(!$("chkTune").checked)return;
  const idx=recFind(tune.genome);if(idx<0){recAdd(tune.genome);return;}
  const r=tune.records[idx];r.trades++;if(net>0)r.wins++;
  r.net+=net;r.peak+=Math.max(0,net);
  if(r.net<0&&Math.abs(r.peak-r.net)>Math.max(1,Math.abs(r.peak+10)))r.active=false;
  const pf=r.peak>0?(r.net>0?r.peak/Math.max(0.01,r.peak-r.net-Math.max(0,(r.peak-r.net))*(1-r.wins/Math.max(1,r.trades))):0):0;
  const dd=r.peak>0?Math.max(0,(r.peak-r.net)/r.peak):0;
  r.score=pf*Math.sqrt(Math.max(1,r.trades))/(dd+1);
  r.last=Date.now();tune.tradesSinceEval++;
  tuneSave();
}
function tuneEvaluate(){
  if(!$("chkTune").checked)return;
  if(tune.tradesSinceEval<parseInt($("setTuneEvery").value||10,10))return;
  tune.tradesSinceEval=0;
  const min=parseInt($("setTuneMin").value||12,10);
  let best=-1,bs=-1;
  tune.records.forEach(r=>{if(r.active&&r.trades>=min&&r.net>0&&r.score>bs){bs=r.score;best=idxOfRec(r);}});
  if(best<0){tune.lastMsg="لا توجد عينات إيجابية كافية بعد";return;}
  const cur=recFind(tune.genome),cs=cur>=0?tune.records[cur].score:0;
  const improvePct=parseFloat($("setTuneImp").value||10,10);
  if(bs>cs*(1+improvePct/100)){
    tune.genome=gCopy(tune.records[best].g);tune.switches++;tune.bestScore=bs;
    tune.lastMsg="تبديل #"+tune.switches+" | نتيجة "+bs.toFixed(2)+" | صفقات "+tune.records[best].trades;
    playSfx("switch");tuneSave();
  }else tune.lastMsg="أفضل نتيجة "+bs.toFixed(2)+" مقابل الحالية "+cs.toFixed(2)+" — لا ميزة كافية بعد";
}
function idxOfRec(r){return tune.records.indexOf(r);}
tuneLoad();

/* ------ profit ladder definition (mirrors the EA inputs) ------ */
const LADDER=[{pts:40,pct:40},{pts:60,pct:30},{pts:100,pct:20},{pts:150,pct:10}];""")

s = s.replace("""function initMarket(){
  market={};""",
"""function initMarket(){
  market={};""")

# ============ 3) sim market state: ladderStep + trailMode ============
s = s.replace("""      trades:[],equity:[{t:0,v:sim.balance}],dayTrades:0,dayKey:"",halt:false,lastEntryBar:-1,
      pending:null};""",
"""      trades:[],equity:[{t:0,v:sim.balance}],dayTrades:0,dayKey:"",halt:false,lastEntryBar:-1,
      pending:null,ladderStep:0};""")

# ============ 4) manageTrade: ladder + genome exits (replace function) ============
start = s.index("function manageTrade(st){")
end = s.index("function dayPLOf(st){", start)
new_mt = """function manageTrade(st){
  const t=st.trade;if(!t)return;
  const N=st.c.length, i=N-1;
  st.barsSinceEntry=(st.barsSinceEntry||0)+1;
  const hi=st.h[i],lo=st.l[i];
  const atr=t.atr0||atrOf(st);
  let exit=null;
  // ---- PROFIT LADDER (4 auto degrees) ----
  if($("chkLadder")&&$("chkLadder").checked){
    const pts=st.spreadCur*Math.abs(1)*0+((st.trade.dir>0?st.price-st.trade.entry:st.trade.entry-st.price))/st.point;
    LADDER.forEach((rung,ri)=>{
      if(pts>=rung.pts&&st.ladderStep<ri+1){
        const partVol=Math.max(0.001,Math.round(st.trade.lots*rung.pct/100*100)/100);
        if(partVol<st.trade.lots-0.0001){
          st.trade.lots=Math.max(0.001,st.trade.lots-partVol);
          st.ladderStep=ri+1;
          st.trade.partial=true;
          g_ctPartial=(g_ctPartial||0)+1;playSfx("partial");
          st.trade.ladderLog=st.trade.ladderLog||[];st.trade.ladderLog.push(ri+1);
          // BE lock after any rung
          const buf=tune.genome.beBufferATR*atr;
          t.sl=t.dir>0?t.entry+buf:t.entry-buf;
          g_ctBE=(g_ctBE||0)+1;playSfx("be");
        }
      }
    });
  }
  // SL/TP intrabar
  if(t.dir>0){
    if(lo<=t.sl)exit={price:t.sl,reason:"SL"};
    else if(hi>=t.tp)exit={price:t.tp,reason:"TP"};
  }else{
    if(hi>=t.sl)exit={price:t.sl,reason:"SL"};
    else if(lo<=t.tp)exit={price:t.tp,reason:"TP"};
  }
  // 1) partial at adaptive trigger -> BE
  const r1=Math.abs(t.entry-t.sl);
  const prof=t.dir>0?st.price-t.entry:t.entry-st.price;
  const trig=tune.genome.partialTriggerRR*r1;
  if(!t.partial&&prof>=trig&&r1>0){
    const partVol=Math.max(0.001,Math.round(st.trade.lots*tune.genome.partialPct/100*100)/100);
    if(partVol<st.trade.lots-0.0001){st.trade.lots=Math.max(0.001,st.trade.lots-partVol);st.trade.partial=true;
      g_ctPartial=(g_ctPartial||0)+1;playSfx("partial");}
    if(!t.beLock){const buf=tune.genome.beBufferATR*atr;t.sl=t.dir>0?t.entry+buf:t.entry-buf;t.beLock=true;
      g_ctBE=(g_ctBE||0)+1;playSfx("be");}
  }
  // 2) TRAILING - 4 modes
  const mode=$("selTrailMode").value||"atr";
  const startDist=tune.genome.trailStartRR*atr,stepDist=tune.genome.trailStepATR*atr;
  if(prof>=startDist){
    let want=null;
    if(mode==="atr"){want=t.dir>0?st.price-stepDist:st.price+stepDist;}
    else if(mode==="points"){if(prof/st.point>=250)want=t.dir>0?st.price-Math.max(20,250/10)*st.point:st.price+Math.max(20,250/10)*st.point;}
    else if(mode==="percent"){if(prof/(t.tp-t.entry+0.0001)>=0.5)want=t.dir>0?st.price-stepDist:st.price+stepDist;}
    else if(mode==="ladder"&&st.ladderStep>0){
      const basePts=LADDER[st.ladderStep-1].pts;
      const lockPts=Math.max(15,basePts/4)*st.point;
      want=t.dir>0?t.entry+lockPts:t.entry-lockPts;
    }
    if(want!=null){
      if((t.dir>0&&want>t.sl)||(t.dir<0&&want<t.sl)){t.sl=want;g_ctTrail=(g_ctTrail||0)+1;playSfx("trail");}
    }
  }
  // 3) time stop (genome-aware)
  const hb=holdBarsFor(st);
  if(st.barsSinceEntry>=hb)exit=exit||{price:st.price,reason:"TIME-STOP"};
  // 4) Friday guard
  const d=simDate(),meta=CLASS_META[st.cls];
  if(meta.weekend&&isFriday(d)&&MIN()>=19*60)exit=exit||{price:st.price,reason:"FRIDAY-GUARD"};
  // 5) daily/equity guard (equity guard card values)
  if(sim.dailyLoss>0){const eq=equityOf(st);if(eq<=sim.balance*(1-sim.dailyLoss/100)){st.halt=true;
    g_ctGuard=(g_ctGuard||0)+1;playSfx("guard");exit=exit||{price:st.price,reason:"DAILY-LOSS-LIMIT"};}}
  if(exit){
    const slip=(1+Math.floor(rnd()*3))*st.point*(rnd()<0.2?-1:1);
    const pnl=(t.dir>0?1:-1)*(exit.price-t.entry)/st.point*(st.vp||1)*(st.trade.lots||0.01);
    const commission=-(CLASS_META[st.cls]&&st.comm?st.comm*(st.trade.lots||0.01)*2:0);
    const swap=-(doesOvernight(t,simDate())?(st.trade.lots||0.01)*1.5:0);
    const slippagePts=Math.abs(slip/st.point);
    st.trades.push({sym:st.sym,cls:st.cls,dir:t.dir,entry:t.entry,exit:exit.price,sl:t.sl,
      openTime:t.openTime,closeTime:simDate().getTime(),lots:+(st.trade.lots||0.01).toFixed(2),pnl:pnl,
      commission,swap,slippage:slippagePts,reason:exit.reason,partial:t.partial,ladder:st.ladderStep});
    sim.balance+=pnl+commission+swap;
    tuneLearn(pnl+commission+swap);tuneEvaluate();
    g_ctClose=(g_ctClose||0)+1;playSfx("close");
    st.trade=null;st.barsSinceEntry=0;st.ladderStep=0;
  }
}
"""
s = s[:start] + new_mt + s[end:]

open(P, "w", encoding="utf-8").write(s)
print("patch engines step 1 done")
