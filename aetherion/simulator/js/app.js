/* AETHERION command deck */
(function () {
  "use strict";

  const I18N = {
    ar: {
      tag: "خبير تكيّفي متعدد الأصول · MT5 · تعرّف تلقائي على الرمز والإطار",
      live: "بث حي", symbol: "الرمز", tf: "الإطار", strategy: "الاستراتيجية",
      preset: "الإعداد", speed: "السرعة", pause: "إيقاف", play: "تشغيل",
      step: "شمعة", reset: "إعادة",
      autodetect: "تعرّف تلقائي عند الوضع على الشارت",
      import: "استيراد Strategy Tester", importhint: "HTM / CSV من المختبر الحقيقي",
      compare: "مقارنة الرموز × الأطر", spread: "السبريد الحي",
      equity: "حقوق الملكية", float: "عائم", ai: "نظام الذكاء",
      winrate: "نسبة الفوز", pos: "صفقات", today: "اليوم", status: "الحالة",
      tape: "شريط الصفقات الحية", curve: "منحنى حقوق الملكية والهبوط",
      curvehint: "مرتبط بنتائج المختبر الحقيقية عند الاستيراد",
      info: "انفوجراف نتائج الاختبار", heat: "مقارنة متعددة الرموز والأطر",
      stAuto: "تلقائي تكيّفي", stTrend: "اتجاه", stRange: "نطاق",
      stBreak: "اختراق", stScalp: "سكالب",
    },
    en: {
      tag: "Adaptive multi-asset EA · MT5 · auto-detects symbol & timeframe",
      live: "LIVE", symbol: "Symbol", tf: "Timeframe", strategy: "Strategy",
      preset: "Preset", speed: "Speed", pause: "Pause", play: "Play",
      step: "Bar", reset: "Reset",
      autodetect: "Auto-detects the moment it is dropped on a chart",
      import: "Import Strategy Tester", importhint: "Real-lab HTM / CSV",
      compare: "Compare symbols × TFs", spread: "Live spread",
      equity: "Equity", float: "Float", ai: "AI regime",
      winrate: "Win rate", pos: "Positions", today: "Today", status: "Status",
      tape: "Live trade tape", curve: "Equity & drawdown",
      curvehint: "Binds to real tester files when imported",
      info: "Backtest infographic", heat: "Multi-symbol / multi-TF comparison",
      stAuto: "Adaptive auto", stTrend: "Trend", stRange: "Range",
      stBreak: "Breakout", stScalp: "Scalp",
    },
  };

  const $ = (id) => document.getElementById(id);
  const state = {
    lang: "ar",
    playing: true,
    speed: 3.2,
    market: null,
    catalog: [],
    reports: {},
    imported: null,
    last: 0,
    acc: 0,
    heat: null,
  };

  const engine = new Aetherion.Engine();
  const chart = new AXChart.PriceChart($("chart"));

  function applyLang() {
    const pack = I18N[state.lang];
    document.documentElement.lang = state.lang;
    document.documentElement.dir = state.lang === "ar" ? "rtl" : "ltr";
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const k = el.getAttribute("data-i18n");
      if (pack[k]) el.textContent = pack[k];
    });
    $("langBtn").textContent = state.lang === "ar" ? "EN" : "عربي";
    $("playBtn").textContent = state.playing ? pack.pause : pack.play;
  }

  function fmt(n, d = 2) {
    return Number(n).toLocaleString(state.lang === "ar" ? "ar-EG" : "en-US", {
      minimumFractionDigits: d, maximumFractionDigits: d,
    });
  }

  function money(n) {
    const s = (n >= 0 ? "+" : "") + fmt(n, 2);
    return s;
  }

  function fillSelect() {
    const sel = $("symbol");
    sel.innerHTML = "";
    Object.keys(state.market || {}).forEach((s) => {
      const o = document.createElement("option");
      o.value = s; o.textContent = s;
      sel.appendChild(o);
    });
    if ([...sel.options].some((o) => o.value === "EURUSD")) sel.value = "EURUSD";
  }

  function currentBars() {
    const sym = $("symbol").value;
    const pack = state.market[sym];
    if (!pack) return [];
    const native = pack.meta.minutes || 60;
    return Aetherion.prepareBars(pack.bars, native, $("tf").value);
  }

  function bootEngine() {
    const sym = $("symbol").value;
    const tf = $("tf").value;
    engine.reset({
      symbol: sym,
      tf,
      strategy: $("strategy").value,
      preset: $("preset").value,
    });
    engine.load(currentBars());
    const asset = engine.asset;
    $("detectText").textContent = `${sym} · ${tf} · ${asset}`;
    $("chartTitle").textContent = sym;
    $("chartSub").textContent = `${tf} · ${asset} · ${$("strategy").value.toUpperCase()}`;
    $("tape").innerHTML = "";
    paintInfo(reportOf(sym));
    render();
  }

  function reportOf(sym) {
    return state.imported && state.imported.stats && (state.imported.stats.symbol === sym || !state.imported.stats.symbol)
      ? { ...state.imported.stats, deals: state.imported.deals, curve: state.imported.curve, source: state.imported.source }
      : state.reports[sym];
  }

  function pushTape(deal) {
    const li = document.createElement("li");
    li.className = deal.side === "BUY" ? "buy" : "sell";
    const pnl = deal.profit || 0;
    li.innerHTML = `<span class="side">${deal.side}</span><span>${deal.exit || "IN"}</span><span class="px">${Number(deal.open || deal.px).toFixed(engine.digits)}</span><span class="pnl ${pnl >= 0 ? "up" : "dn"}">${money(pnl)}</span>`;
    $("tape").prepend(li);
    while ($("tape").children.length > 24) $("tape").lastChild.remove();
  }

  function render() {
    const snap = engine.snapshot();
    chart.draw(snap, {
      onHover(b) {
        $("ohlc").textContent = `O ${b.open.toFixed(snap.digits)}   H ${b.high.toFixed(snap.digits)}   L ${b.low.toFixed(snap.digits)}   C ${b.close.toFixed(snap.digits)}`;
        const tip = $("crossTip");
        tip.hidden = false;
        tip.textContent = `${b.time}  ·  spread ${Number(snap.spread).toFixed(snap.digits)}`;
        const r = $("chart").getBoundingClientRect();
        const x = chart.hover.x;
        tip.style.left = (document.documentElement.dir === "rtl" ? r.width - x - 160 : x + 12) + "px";
        tip.style.top = chart.hover.y + 12 + "px";
      },
    });
    if (!chart.hover) {
      const b = engine.bar();
      if (b) $("ohlc").textContent = `O ${b.open.toFixed(snap.digits)}   H ${b.high.toFixed(snap.digits)}   L ${b.low.toFixed(snap.digits)}   C ${b.close.toFixed(snap.digits)}`;
      $("crossTip").hidden = true;
    }

    $("spreadPts").textContent = snap.spreadPts.toFixed(1);
    $("spreadState").textContent = snap.spreadOk ? "OK" : "WIDE";
    $("spreadState").className = snap.spreadOk ? "pos-ok" : "pos-warn";
    $("bid").textContent = snap.bid.toFixed(snap.digits);
    $("ask").textContent = snap.ask.toFixed(snap.digits);
    $("atr").textContent = snap.atr.toFixed(snap.digits);
    const cap = Aetherion.spreadCap(snap.asset);
    $("spreadBar").style.height = Math.min(100, (snap.spreadPts / cap) * 100) + "%";

    $("equity").textContent = fmt(snap.equity, 2);
    $("dayPnl").textContent = money(snap.daily);
    $("dayPnl").className = snap.daily >= 0 ? "pos-ok" : "pos-bad";
    $("dd").textContent = snap.dd.toFixed(2) + "%";
    $("flt").textContent = money(snap.floating);
    $("regime").textContent = snap.regime;
    $("wr").textContent = snap.winRate.toFixed(0) + "%";
    $("pf").textContent = snap.pf.toFixed(2);
    $("wrRing").style.setProperty("--p", snap.winRate + "%");
    $("pfRing").style.setProperty("--p", Math.min(100, (snap.pf / 2) * 100) + "%");
    $("posN").textContent = snap.openPos;
    $("todayN").textContent = snap.today;
    $("reason").textContent = snap.lastReason;
    $("ready").textContent = snap.block || "READY";
    $("ready").className = snap.block && snap.block !== "IN TRADE" ? "pos-warn" : "pos-ok";
    $("fill").textContent = snap.fill;
    $("exec").textContent = snap.exec;
    $("net").textContent = money(snap.net);
    $("net").className = snap.net >= 0 ? "pos-ok" : "pos-bad";

    const eq = snap.curve.slice(-80).map((c) => c.eq);
    AXChart.spark($("spark"), eq, snap.net >= 0 ? "#00ff9d" : "#ff4d6d");
    drawEquity(snap);
  }

  function drawEquity(snap) {
    const src = state.imported && state.imported.curve && state.imported.curve.length
      ? state.imported.curve
      : snap.curve;
    AXChart.lineChart($("equityChart"), [
      { data: src.map((c) => ({ y: c.eq })), color: "#00f0ff", fill: "rgba(0,240,255,.08)", width: 2 },
      { data: src.map((c) => ({ y: 10000 - c.dd * 40 })), color: "rgba(255,46,151,.7)", width: 1.2 },
    ], { digits: 0 });
  }

  function paintInfo(rep) {
    const snap = engine.snapshot();
    const s = rep || {};
    const cells = [
      ["NET PROFIT", money(s.net ?? snap.net), (s.net ?? snap.net) >= 0 ? "up" : "dn"],
      ["PROFIT FACTOR", (s.pf ?? snap.pf).toFixed(2), "hi"],
      ["WIN RATE", ((s.winRate ?? snap.winRate) || 0).toFixed(1) + "%", ""],
      ["MAX DD", ((s.dd ?? snap.dd) || 0).toFixed(2) + "%", "dn"],
      ["TRADES", String(s.trades ?? snap.closed.length), ""],
      ["SPREAD AVG", fmt(s.spreadAvg ?? snap.spread, snap.digits), ""],
    ];
    $("infoGrid").innerHTML = cells.map(([k, v, c]) => `<div class="stat ${c}"><span>${k}</span><b>${v}</b></div>`).join("");
    $("labSource").textContent = s.source
      ? "Imported · " + s.source
      : (rep ? `Tester fixture · ${engine.symbol}` : "Live engine");
  }

  function tick(ts) {
    aurora(ts);
    if (!state.last) state.last = ts;
    const dt = Math.min(64, ts - state.last);
    state.last = ts;
    if (state.playing) {
      state.acc += dt * state.speed;
      while (state.acc > 280) {
        state.acc -= 280;
        const ev = engine.step();
        if (ev.opened) {
          pushTape({ ...ev.opened, profit: 0, exit: "IN", open: ev.opened.px });
          const r = $("chart").getBoundingClientRect();
          chart.burst(r.width * 0.82, r.height * 0.4, ev.opened.side === "BUY" ? "#00f0ff" : "#ff2e97");
        }
        if (ev.closed) {
          pushTape(ev.closed);
          paintInfo(reportOf(engine.symbol));
        }
        if (ev.done) {
          state.playing = false;
          applyLang();
          break;
        }
      }
    }
    render();
    requestAnimationFrame(tick);
  }

  /* aurora backdrop */
  const ag = $("aurora");
  const blobs = Array.from({ length: 5 }, (_, i) => ({
    x: Math.random(), y: Math.random(),
    r: 180 + i * 70,
    hue: [188, 46, 320, 150, 210][i],
    vx: 0.00012 * (i % 2 ? 1 : -1),
    vy: 0.00008 * (i % 3 ? 1 : -1),
  }));
  function aurora(ts) {
    const { ctx, w, h } = AXChart.size(ag);
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = "#05060f";
    ctx.fillRect(0, 0, w, h);
    ctx.globalCompositeOperation = "lighter";
    blobs.forEach((b, i) => {
      b.x += b.vx; b.y += b.vy;
      if (b.x < 0 || b.x > 1) b.vx *= -1;
      if (b.y < 0 || b.y > 1) b.vy *= -1;
      const g = ctx.createRadialGradient(b.x * w, b.y * h, 0, b.x * w, b.y * h, b.r);
      g.addColorStop(0, `hsla(${b.hue + Math.sin(ts / 2000 + i) * 18},100%,58%,.16)`);
      g.addColorStop(1, "transparent");
      ctx.fillStyle = g;
      ctx.beginPath(); ctx.arc(b.x * w, b.y * h, b.r, 0, Math.PI * 2); ctx.fill();
    });
    ctx.globalCompositeOperation = "source-over";
  }

  function exportCSV() {
    const rows = [["ticket", "symbol", "tf", "side", "openTime", "closeTime", "open", "close", "sl", "tp", "profit", "exit", "reason"]];
    engine.closed.forEach((d) => {
      rows.push([d.ticket, engine.symbol, engine.tf, d.side, d.t, d.closeTime, d.px, d.close, d.sl, d.tp, d.profit, d.exit, d.reason]);
    });
    const blob = new Blob([rows.map((r) => r.join(",")).join("\n")], { type: "text/csv;charset=utf-8" });
    download(blob, `AETHERION_${engine.symbol}_${engine.tf}.csv`);
  }

  function exportPNG() {
    const src = $("chart");
    const out = document.createElement("canvas");
    out.width = src.width; out.height = src.height + 80;
    const ctx = out.getContext("2d");
    ctx.fillStyle = "#05060f";
    ctx.fillRect(0, 0, out.width, out.height);
    ctx.drawImage(src, 0, 80);
    ctx.fillStyle = "#f5c542";
    ctx.font = "700 28px Outfit";
    ctx.fillText("AETHERION  ·  " + engine.symbol + " " + engine.tf, 24, 48);
    ctx.fillStyle = "#8b93a7";
    ctx.font = "14px IBM Plex Mono";
    ctx.fillText("Adaptive Intelligence  ·  live spread  ·  " + new Date().toISOString().slice(0, 16), 24, 70);
    out.toBlob((b) => download(b, `AETHERION_${engine.symbol}_${engine.tf}.png`));
  }

  function download(blob, name) {
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = name;
    a.click();
    setTimeout(() => URL.revokeObjectURL(a.href), 1500);
  }

  async function ingestFiles(files) {
    for (const f of files) {
      const text = await f.text();
      const parsed = Aetherion.parseTester(text, f.name);
      state.imported = parsed;
      parsed.deals.forEach(pushTape);
      paintInfo({ ...parsed.stats, source: f.name, deals: parsed.deals, curve: parsed.curve });
      if (parsed.stats.symbol && state.market[parsed.stats.symbol]) {
        $("symbol").value = parsed.stats.symbol;
        if (parsed.stats.tf) $("tf").value = parsed.stats.tf;
        bootEngine();
      }
      drawEquity(engine.snapshot());
    }
  }

  function runCompare() {
    const tfs = ["M15", "M30", "H1", "H4", "D1"];
    const syms = Object.keys(state.market);
    const matrix = [];
    const overlay = [];
    const palette = ["#00f0ff", "#f5c542", "#ff2e97", "#00ff9d", "#7c5cff", "#ff8a3d", "#67f6ff", "#e8eefc", "#4dd4ff", "#c9a227", "#ff6bb5"];
    syms.forEach((sym, si) => {
      const row = [];
      tfs.forEach((tf) => {
        const e = new Aetherion.Engine();
        e.reset({ symbol: sym, tf, strategy: $("strategy").value, preset: $("preset").value });
        const pack = state.market[sym];
        e.load(Aetherion.prepareBars(pack.bars, pack.meta.minutes || 60, tf));
        let guard = 0;
        while (guard++ < 4000) {
          const ev = e.step();
          if (ev.done) break;
        }
        const s = e.snapshot();
        row.push({ pf: s.pf || 0, net: s.net, wr: s.winRate, dd: s.dd, trades: s.closed.length });
        if (tf === $("tf").value) {
          overlay.push({
            data: e.curve.map((c) => ({ y: c.eq })),
            color: palette[si % palette.length],
            width: 1.5,
          });
        }
      });
      matrix.push(row);
    });
    state.heat = { matrix, tfs, syms };
    AXChart.heatmap($("heat"), matrix, tfs, syms);
    AXChart.lineChart($("overlay"), overlay, { digits: 0 });
  }

  function bind() {
    $("langBtn").onclick = () => { state.lang = state.lang === "ar" ? "en" : "ar"; applyLang(); };
    $("playBtn").onclick = () => { state.playing = !state.playing; applyLang(); };
    $("stepBtn").onclick = () => { engine.step(); render(); };
    $("resetBtn").onclick = () => bootEngine();
    $("symbol").onchange = bootEngine;
    $("tf").onchange = bootEngine;
    $("strategy").onchange = bootEngine;
    $("preset").onchange = bootEngine;
    $("speed").oninput = (e) => (state.speed = +e.target.value);
    $("csvBtn").onclick = exportCSV;
    $("pngBtn").onclick = exportPNG;
    $("cmpBtn").onclick = runCompare;
    $("importBtn").onclick = () => $("fileIn").click();
    $("fileIn").onchange = (e) => ingestFiles(e.target.files);
    const drop = $("drop");
    ["dragenter", "dragover"].forEach((ev) => drop.addEventListener(ev, (e) => { e.preventDefault(); drop.style.outline = "1px solid #00f0ff"; }));
    ["dragleave", "drop"].forEach((ev) => drop.addEventListener(ev, (e) => { e.preventDefault(); drop.style.outline = ""; }));
    drop.addEventListener("drop", (e) => ingestFiles(e.dataTransfer.files));
    window.addEventListener("resize", () => { render(); if (state.heat) AXChart.heatmap($("heat"), state.heat.matrix, state.heat.tfs, state.heat.syms); });
    setInterval(() => {
      $("clock").textContent = new Date().toLocaleTimeString(state.lang === "ar" ? "ar-EG" : "en-GB");
    }, 1000);
  }

  async function loadJSON(url) {
    const r = await fetch(url);
    if (!r.ok) throw new Error(url);
    return r.json();
  }

  async function start() {
    applyLang();
    bind();
    try {
      state.market = await loadJSON("data/market.json");
      state.catalog = await loadJSON("data/catalog.json");
      await Promise.all(Object.keys(state.market).map(async (s) => {
        try { state.reports[s] = await loadJSON("data/report_" + s + ".json"); } catch (_) {}
      }));
    } catch (err) {
      console.warn("fixture load", err);
      state.market = {};
    }
    fillSelect();
    bootEngine();
    requestAnimationFrame(tick);
    setTimeout(runCompare, 350);
  }

  start();
})();
