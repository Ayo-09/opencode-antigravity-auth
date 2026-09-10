#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Adds advanced metrics + overfit check + Monte Carlo to the dashboard."""
import re

P = "novagravity_dashboard.html"
s = open(P, encoding="utf-8").read()

# ---------------------------------------------------------------- 1) HTML: new cards in Analysis tab
anchor = """    <div class="grid g2" style="margin-top:14px">
      <div class="card">
        <h3>الانحياز الزمني (ساعة & يوم)</h3>"""
new_cards = """    <div class="grid g2" style="margin-top:14px">
      <div class="card">
        <h3>مؤشرات متقدمة + فحص التجهيز الزائد (Overfitting)</h3>
        <div class="grid g4" id="extraStats"></div>
        <div id="ofResult" style="margin-top:10px"></div>
      </div>
      <div class="card">
        <h3>Monte Carlo — 1000 سيناريو (تُعاد عيّنتها من صفقاتك الحقيقية)</h3>
        <div class="ctl">
          <button class="btn acc" id="btnMC">🎲 تشغيل المحاكاة الاحتمالية</button>
          <span class="mut" style="font-size:11.5px">Bootstrap بإعادة العيّنة (with replacement) — لا افتراضات توزيع</span>
        </div>
        <canvas id="mcCanvas" height="160" style="margin-top:10px"></canvas>
        <div class="grid g4" id="mcStats" style="margin-top:8px"></div>
      </div>
    </div>
    <div class="grid g2" style="margin-top:14px">
      <div class="card">
        <h3>الانحياز الزمني (ساعة & يوم)</h3>"""
assert anchor in s
s = s.replace(anchor, new_cards, 1)

# ---------------------------------------------------------------- 2) import hint: EA journal
s = s.replace(
    """    <pre class="mut" style="font-size:11.5px;line-height:1.8;overflow:auto">ticket,openTime,type,size,item,openPrice,openSlippage,closeTime,closePrice,closeSlippage,commission,swap,profit
12345,2025.08.25 12:30,buy,0.10,XAUUSD,2651.2,1,2025.08.26 09:10,2669.5,2,0,0.15,182.30</pre>""",
    """    <pre class="mut" style="font-size:11.5px;line-height:1.8;overflow:auto">ticket,symbol,type,size,openTime,openPrice,closeTime,closePrice,commission,swap,profit,reason,magic
12345,XAUUSD,buy,0.10,2025.08.25 12:30,2651.20,2025.08.26 09:10,2669.50,0,0.15,182.30,TP,345678</pre>
    <p class="hint">✅ هذا هو تنسيق <b>NovaGravity_Journal.csv</b> الذي يكتبه البوت نفسه داخل <span class="mut">MQL5/Files</span> — يمكنك استيراد صفقاتك الحية بنفس الطريقة التي تستورد بها تقارير الـ Tester.</p>""")

# ---------------------------------------------------------------- 3) JS: new functions
js_anchor = """function renderRealTrades(){"""
new_js = """/* ---------------- advanced metrics / overfit / Monte Carlo ---------------- */
function trueNet(t){return (t.profit||0)+(t.commission||0)+(t.swap||0);}
function extraMetrics(r){
  const T=r.rows||[];
  const nets=T.map(trueNet);
  const win=nets.filter(v=>v>0),loss=nets.filter(v=>v<=0);
  const avgW=win.length?win.reduce((a,b)=>a+b,0)/win.length:0;
  const avgL=loss.length?Math.abs(loss.reduce((a,b)=>a+b,0)/loss.length):0;
  // Sortino: mean / downside deviation (per trade)
  const mean=nets.reduce((a,b)=>a+b,0)/(nets.length||1);
  const down=nets.map(v=>Math.min(0,v-mean));
  const dd=Math.sqrt(down.reduce((a,b)=>a+b*b,0)/(nets.length||1));
  const sortino=dd>0?mean/dd:0;
  // Kelly: W - (1-W)/R
  const W=nets.length?win.length/nets.length:0;
  const R=avgL>0?avgW/avgL:0;
  const kelly=R>0?(W-(1-W)/R):0;
  // max consecutive losses
  let streak=0,mx=0;
  for(const v of nets){if(v<=0){streak++;mx=Math.max(mx,streak);}else streak=0;}
  return {sortino,kelly,maxConsec:mx,W,avgW,avgL,mean,nets};
}
function overfitCheck(r){
  const T=[...(r.rows||[])].sort((a,b)=>a.closeTime-b.closeTime);
  if(T.length<16)return null;
  const half=Math.floor(T.length/2);
  const stat=arr=>{
    let gp=0,gl=0,win=0;
    arr.forEach(t=>{const n=trueNet(t);if(n>0){gp+=n;win++;}else gl+=n;});
    const pf=gl!==0?gp/Math.abs(gl):(gp>0?99:0);
    let cur=0,pk=0,dd=0;
    arr.forEach(t=>{cur+=trueNet(t);pk=Math.max(pk,cur);dd=Math.min(dd,cur-pk);});
    return {pf,winRate:arr.length?win/arr.length*100:0,exp:arr.length?(gp+gl)/arr.length:0,ddPct:pk?Math.abs(dd)/Math.max(1,pk)*100:0};
  };
  const A=stat(T.slice(0,half)),B=stat(T.slice(half));
  const ratio=B.pf/(A.pf||0.01);
  let verdict,cls;
  if(B.pf<A.pf*0.7){verdict="⚠ تدهور واضح في النصف الثاني — رائحة تجهيز زائد (Overfitting)";cls="crit";}
  else if(B.pf>A.pf*1.3){verdict="✅ استقرار/تحسّن — النصف الثاني أفضل من الأول";cls="ok";}
  else{verdict="🟡 استقرار مقبول بين النصفين";cls="info";}
  return {A,B,ratio,verdict,cls};
}
let mcCache=null;
function runMonteCarlo(){
  const r=REPORTS[selReportIdx];if(!r){alert('استورد تقارير أولاً');return;}
  const nets=(r.rows||[]).map(trueNet);
  if(nets.length<8){alert('عيّنة صغيرة جداً (أقل من 8 صفقات) — لا معنى للإعادة العينية');return;}
  const N=nets.length,RUNS=1000,base=10000;
  let fins=[],dd95=0,ruin=0,losing=0;
  const ddArr=[];
  for(let run=0;run<RUNS;run++){
    let bal=base,peak=base,dd=0;
    for(let i=0;i<N;i++){
      bal+=nets[Math.floor(Math.random()*N)];
      peak=Math.max(peak,bal);
      dd=Math.max(dd,(peak-bal)/peak*100);
      if(bal<=base*0.25){ruin++;break;}
    }
    fins.push(bal-base);
    ddArr.push(dd);
    if(bal<base)losing++;
  }
  fins.sort((a,b)=>a-b);ddArr.sort((a,b)=>a-b);
  const med=f=>f[Math.floor(f.length/2)];
  const p5=f=>f[Math.floor(f.length*0.05)];
  const p95=f=>f[Math.floor(f.length*0.95)];
  mcCache={med:med(fins),p5:p5(fins),p95:p95(fins),losing:losing/RUNS*100,
    ddMed:med(ddArr),dd95:p95(ddArr),ruin:ruin/RUNS*100,N,RUNS};
  // render
  const stats=[["متوسط النتيجة (وسيط)",fmtMoney(mcCache.med),mcCache.med>=0?"ok":"bad"],
    ["فترة ثقة 5%-95%",fmtMoney(mcCache.p5)+" → "+fmtMoney(mcCache.p95),""],
    ["احتمال سيناريو خاسر",fmt(mcCache.losing,1)+"%","warn"],
    ["تراجع وسيط",fmt(mcCache.ddMed,1)+"%","warn"],
    ["تراجع P95",fmt(mcCache.dd95,1)+"%","bad"],
    ["احتمال تلف 75% من الحساب",fmt(mcCache.ruin,2)+"%","bad"]];
  $("mcStats").innerHTML=stats.map(c=>`<div class="stat"><div class="lab">${c[0]}</div><div class="val ${c[2]}">${c[1]}</div></div>`).join("");
  // histogram
  const slot=setupCanvas($("mcCanvas"));const {x,w,h}=slot;x.clearRect(0,0,w,h);
  const mn=Math.min(...fins),mx=Math.max(...fins);
  const bins=28,bw=w/bins;
  const hist=new Array(bins).fill(0);
  fins.forEach(v=>{let b=Math.floor((v-mn)/(mx-mn||1)*bins);b=clamp(b,0,bins-1);hist[b]++;});
  const mh=Math.max(...hist,1);
  for(let i=0;i<bins;i++){
    const v=(mn+(i+0.5)*(mx-mn)/bins);
    const col=v>=0?"rgba(52,211,153,.75)":"rgba(251,113,133,.75)";
    x.fillStyle=col;x.shadowColor=v>=0?"#34d399":"#fb7185";x.shadowBlur=5;
    x.fillRect(i*bw+1,h-8-hist[i]/mh*(h-22),bw-2,hist[i]/mh*(h-22));x.shadowBlur=0;
  }
  x.fillStyle="#7f9cc0";x.font="10px Segoe UI";x.textAlign="left";
  x.fillText(fmtMoney(mn)+"  ←  نتيجة السيناريو  →  "+fmtMoney(mx),8,14);
  $("btnMC").textContent="🎲 إعادة تشغيل (أُنجز ×"+RUNS+")";
}
function renderExtra(){
  const r=REPORTS[selReportIdx];if(!r)return;
  const m=extraMetrics(r);
  $("extraStats").innerHTML=`
    <div class="stat"><div class="lab">Sortino (لكل صفقة)</div><div class="val ${m.sortino>=1?"ok":m.sortino>=0?"warn":"bad"}">${fmt(m.sortino,2)}</div></div>
    <div class="stat"><div class="lab">Kelly % (حدّ أقصى نظري)</div><div class="val ${m.kelly>=0?"ok":"bad"}">${fmt(Math.max(0,m.kelly*100),1)}%</div></div>
    <div class="stat"><div class="lab">أقصى خسائر متتالية</div><div class="val">${m.maxConsec}</div></div>
    <div class="stat"><div class="lab">متوسط ربح / خسارة</div><div class="val">${fmtMoney(m.avgW)} / ${fmtMoney(-m.avgL)}</div></div>`;
  const of=overfitCheck(r);
  if(of){
    $("ofResult").innerHTML=`<div class="insight ${of.cls}">
      <b>فحص Overfitting — نصف زمني أول/ثاني (${of.A.pf.toFixed(2)} → ${of.B.pf.toFixed(2)})</b>
      <div>${of.verdict}</div>
      <div style="margin-top:4px" class="mut">النصف الأول: PF ${fmt(of.A.pf,2)} · نجاح ${fmt(of.A.winRate,1)}% · تراجع ${fmt(of.A.ddPct,1)}% &nbsp;|&nbsp; النصف الثاني: PF ${fmt(of.B.pf,2)} · نجاح ${fmt(of.B.winRate,1)}% · تراجع ${fmt(of.B.ddPct,1)}%</div></div>`;
  }else{
    $("ofResult").innerHTML=`<div class="hint">تحتاج ≥ 16 صفقة لإجراء فحص التجهيز الزائد — ${r.trades} متوفرة حالياً.</div>`;
  }
}

function renderRealTrades(){"""
assert js_anchor in s
s = s.replace(js_anchor, new_js, 1)

# ---------------------------------------------------------------- 4) hook into renderAnalysis + wire button
s = s.replace("""  renderAnEquity();
  renderHeat();
  renderRealTrades();
}""",
"""  renderAnEquity();
  renderHeat();
  renderRealTrades();
  renderExtra();
  if(mcCache)$("btnMC").textContent="🎲 إعادة تشغيل (أُنجز ×"+mcCache.RUNS+")";
}""")
s = s.replace("$('btnLLM').onclick=runLLM;",
"$('btnLLM').onclick=runLLM;\n$('btnMC').onclick=runMonteCarlo;")

# ---------------------------------------------------------------- 5) version strings
s=s.replace('<h1>NOVA GRAVITY AI <em>| ENGINE v1.00</em></h1>','<h1>NOVA GRAVITY AI <em>| ENGINE v1.01</em></h1>')
s=s.replace('NOVA GRAVITY AI v1.00','NOVA GRAVITY AI v1.01')

open(P,"w",encoding="utf-8").write(s)
print("dashboard patched OK")
