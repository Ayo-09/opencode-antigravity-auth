/* AETHERION command deck — no fabricated tester results */
(function () {
  "use strict";

  const I18N = {
    ar: {
      tag: "خبير تكيّفي متعدد الأصول · MT5 · تعرّف تلقائي على الرمز والإطار",
      live: "بث المحاكاة", symbol: "الرمز", tf: "الإطار", strategy: "الاستراتيجية",
      preset: "الإعداد", speed: "السرعة", pause: "إيقاف", play: "تشغيل",
      step: "شمعة", reset: "إعادة", asset: "الفئة", allAssets: "كل الأصول",
      autodetect: "تعرّف تلقائي عند الوضع على الشارت",
      import: "استيراد Strategy Tester", importhint: "HTM / CSV حقيقي — بلا نتائج قبل الرفع",
      compare: "مقارنة التقارير المستوردة", spread: "السبريد الحي",
      equity: "حقوق المحاكاة", float: "عائم", ai: "نظام الذكاء",
      winrate: "نسبة الفوز", pos: "صفقات", today: "اليوم", status: "الحالة",
      tape: "شريط الصفقات الحية", curve: "منحنى متزامن زمنياً",
      curvehint: "محاذاة كل التقارير المستوردة على محور وقت واحد",
      info: "انفوجراف التقارير المستوردة", heat: "مقارنة متعددة الرموز والأطر (من ملفاتك)",
      stAuto: "تلقائي تكيّفي", stTrend: "اتجاه", stRange: "نطاق",
      stBreak: "اختراق", stScalp: "سكالب",
      saveWs: "حفظ مساحة العمل", loadWs: "تحميل",
      clearLab: "مسح التقارير", tapeEmpty: "لا صفقات بعد — Space للتشغيل/الإيقاف",
      toastSaved: "حُفظت مساحة العمل", toastImported: "استُورد التقرير", toastCleared: "مُسحت مكتبة المختبر",
      gateTitle: "لا نتائج واقعية قبل ملفاتك",
      gateBody: "الانفوجراف وتكاليف العمولة/السواب/الانزلاق ومقارنة الرموز وتوصيات الذكاء الاصطناعي تبقى فارغة حتى تسحب تقارير Strategy Tester الحقيقية (HTM أو CSV) من MT5.",
      costs: "تقرير التكاليف · عمولة · سواب · انزلاق",
      aiLab: "ذكاء AETHERION · توصيات قابلة للتنفيذ",
      aiHint: "مستخرجة فقط من تقاريرك المستوردة",
      simNote: "أرقام المحرك البصري فقط — ليست نتيجة مختبر.",
    },
    en: {
      tag: "Adaptive multi-asset EA · MT5 · auto-detects symbol & timeframe",
      live: "SIM LIVE", symbol: "Symbol", tf: "Timeframe", strategy: "Strategy",
      preset: "Preset", speed: "Speed", pause: "Pause", play: "Play",
      step: "Bar", reset: "Reset", asset: "Asset", allAssets: "All assets",
      autodetect: "Auto-detects the moment it is dropped on a chart",
      import: "Import Strategy Tester", importhint: "Real HTM / CSV — no stats before upload",
      compare: "Compare imported reports", spread: "Live spread",
      equity: "Simulation equity", float: "Float", ai: "AI regime",
      winrate: "Win rate", pos: "Positions", today: "Today", status: "Status",
      tape: "Live trade tape", curve: "Time-aligned equity",
      curvehint: "Every imported report snapped onto one time axis",
      info: "Imported-report infographic", heat: "Multi-symbol / TF from your files",
      stAuto: "Adaptive auto", stTrend: "Trend", stRange: "Range",
      stBreak: "Breakout", stScalp: "Scalp",
      saveWs: "Save workspace", loadWs: "Load",
      clearLab: "Clear reports", tapeEmpty: "No trades yet — Space to play/pause",
      toastSaved: "Workspace saved", toastImported: "Report imported", toastCleared: "Lab library cleared",
      gateTitle: "No realistic results before your files",
      gateBody: "Infographic, commission/swap/slippage costs, comparison and AI stay empty until you drop real MT5 Strategy Tester HTM/CSV files.",
      costs: "Cost report · commission · swap · slippage",
      aiLab: "AETHERION intelligence · actionable calls",
      aiHint: "Derived only from reports you imported",
      simNote: "Visual engine numbers only — not a tester result.",
    },
  };

  const $ = (id) => document.getElementById(id);
  const state = {
    lang: "ar",
    playing: true,
    speed: 3.2,
    library: [],
    last: 0,
    acc: 0,
    heat: null,
    importedDeals: [],
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
    syncSpeed();
    fillAssetFilter();
    fillSelect();
    refreshSlots();
    if (state.library.length) paintLab();
  }

  function fmt(n, d = 2) {
    return Number(n).toLocaleString(state.lang === "ar" ? "ar-EG" : "en-US", {
      minimumFractionDigits: d, maximumFractionDigits: d,
    });
  }
  function money(n) {
    return (n >= 0 ? "+" : "") + fmt(n, 2);
  }

  let toastTimer = 0;
  function toast(msg) {
    const el = $("toast");
    if (!el) return;
    el.textContent = msg;
    el.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { el.hidden = true; }, 2800);
  }

  function syncSpeed() {
    const el = $("speed");
    if (el) state.speed = +el.value;
    const lab = $("speedVal");
    if (lab) lab.textContent = state.speed.toFixed(1) + "×";
  }

  function maybeAutoPreset() {
    const cur = $("preset").value;
    if (["conservative", "aggressive", "scalp"].includes(cur)) return;
    const asset = Aetherion.detectAsset($("symbol").value);
    const next = Aetherion.presetForAsset(asset);
    if (next && $("preset").querySelector('option[value="' + next + '"]'))
      $("preset").value = next;
  }

  function resetTape() {
    $("tape").innerHTML = '<li class="empty" data-i18n="tapeEmpty">' + I18N[state.lang].tapeEmpty + '</li>';
  }

  function fillAssetFilter() {
    const sel = $("assetFilter");
    const cur = sel.value || "ALL";
    sel.innerHTML = "";
    const all = document.createElement("option");
    all.value = "ALL";
    all.textContent = I18N[state.lang].allAssets;
    sel.appendChild(all);
    AetherionLab.GROUPS.forEach((g) => {
      const o = document.createElement("option");
      o.value = g.id;
      o.textContent = state.lang === "ar" ? g.ar : g.en;
      sel.appendChild(o);
    });
    if ([...sel.options].some((o) => o.value === cur)) sel.value = cur;
  }

  function fillSelect() {
    const filter = $("assetFilter").value || "ALL";
    const sel = $("symbol");
    const keep = sel.value;
    sel.innerHTML = "";
    AetherionLab.UNIVERSE.filter((s) => filter === "ALL" || s.asset === filter).forEach((s) => {
      const o = document.createElement("option");
      o.value = s.symbol;
      o.textContent = s.symbol + " · " + s.asset;
      sel.appendChild(o);
    });
    if ([...sel.options].some((o) => o.value === keep)) sel.value = keep;
    else if ([...sel.options].some((o) => o.value === "EURUSD")) sel.value = "EURUSD";
  }

  function currentBars() {
    const spec = AetherionLab.specOf($("symbol").value);
    const raw = AetherionLab.synthesizeBars(spec, 760);
    return Aetherion.prepareBars(raw, spec.minutes || 60, $("tf").value);
  }

  function dealsForSymbol(sym) {
    return state.library.flatMap((r) => (r.deals || []).filter((d) => !d.symbol || d.symbol === sym || d.symbol === ""));
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
    const bars = currentBars();
    engine.load(bars);
    state.importedDeals = AetherionLab.attachDealsToBars(bars, dealsForSymbol(sym));
    $("detectText").textContent = `${sym} · ${tf} · ${engine.asset}`;
    $("chartTitle").textContent = sym;
    $("chartSub").textContent = `${tf} · ${engine.asset} · ${$("strategy").value.toUpperCase()}`;
    resetTape();
    state.importedDeals.slice(-8).forEach((d) => pushTape(d, true));
    render();
  }

  function pushTape(deal, imported) {
    const empty = $("tape").querySelector("li.empty");
    if (empty) empty.remove();
    const li = document.createElement("li");
    li.className = deal.side === "BUY" ? "buy" : "sell";
    const pnl = deal.profit || 0;
    const tag = imported ? "LAB" : (deal.exit || "IN");
    li.innerHTML = `<span class="side">${deal.side}</span><span>${tag}</span><span class="px">${Number(deal.open || deal.px || 0).toFixed(engine.digits)}</span><span class="pnl ${pnl >= 0 ? "up" : "dn"}">${money(pnl)}</span>`;
    $("tape").prepend(li);
    while ($("tape").children.length > 24) $("tape").lastChild.remove();
  }

  function tradeTipHtml(deal, bar) {
    if (deal) {
      const pnl = Number(deal.profit) || 0;
      const dur = (deal.tsOpen && deal.tsClose) ? Math.max(0, Math.round((deal.tsClose - deal.tsOpen) / 60000)) : null;
      return `<h4>${deal.side} #${deal.ticket || "—"} · ${deal.symbol || engine.symbol}</h4>
        <div><span class="k">IN</span> <span class="v">${deal.openTime || "—"} @ ${deal.open ?? deal.px ?? "—"}</span></div>
        <div><span class="k">OUT</span> <span class="v">${deal.closeTime || "—"} @ ${deal.close ?? "—"} · ${deal.exit || ""}</span></div>
        <div><span class="k">SL / TP</span> <span class="v">${deal.sl ?? "—"} / ${deal.tp ?? "—"}</span></div>
        <div><span class="k">LOT</span> <span class="v">${deal.lots ?? "—"}</span></div>
        <div><span class="k">P/L</span> <span class="${pnl >= 0 ? "up" : "dn"}">${money(pnl)}</span></div>
        <div><span class="k">COMM / SWAP / SLIP</span> <span class="v">${fmt(deal.commission || 0, 2)} / ${fmt(deal.swap || 0, 2)} / ${fmt(deal.slippage || 0, 2)}</span></div>
        ${dur != null ? `<div><span class="k">HOLD</span> <span class="v">${dur} min</span></div>` : ""}
        ${deal.reason ? `<div><span class="k">WHY</span> <span class="v">${deal.reason}</span></div>` : ""}`;
    }
    if (!bar) return "";
    return `<h4>${engine.symbol} ${engine.tf}</h4>
      <div><span class="k">TIME</span> <span class="v">${bar.time}</span></div>
      <div><span class="k">OHLC</span> <span class="v">${bar.open} / ${bar.high} / ${bar.low} / ${bar.close}</span></div>
      <div><span class="k">SPREAD</span> <span class="v">${Number(engine.liveSpread || bar.spread || 0).toFixed(engine.digits)}</span></div>`;
  }

  function render() {
    const snap = engine.snapshot();
    snap.importedDeals = state.importedDeals;
    chart.draw(snap, {
      onHover(b, idx, hover, deal) {
        if (b) $("ohlc").textContent = `O ${b.open.toFixed(snap.digits)}   H ${b.high.toFixed(snap.digits)}   L ${b.low.toFixed(snap.digits)}   C ${b.close.toFixed(snap.digits)}`;
        const tip = $("crossTip");
        tip.hidden = false;
        tip.innerHTML = tradeTipHtml(deal, b);
        const host = $("chart").getBoundingClientRect();
        const rtl = document.documentElement.dir === "rtl";
        const left = rtl ? host.width - hover.x - 16 : hover.x + 14;
        tip.style.left = Math.max(8, Math.min(host.width - 230, left)) + "px";
        tip.style.top = Math.max(8, hover.y + 12) + "px";
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
    $("dayPnl").className = "subline " + (snap.daily >= 0 ? "pos-ok" : "pos-bad");
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
    AXChart.spark($("spark"), snap.curve.slice(-80).map((c) => c.eq), snap.net >= 0 ? "#00ff9d" : "#ff4d6d");
  }

  function hasLab() {
    return state.library.length > 0;
  }

  function setLabVisible(on) {
    $("labGate").hidden = on;
    $("labSection").hidden = !on;
    $("intelSection").hidden = !on;
    $("compareSection").hidden = !on;
  }

  function paintLab() {
    if (!hasLab()) {
      setLabVisible(false);
      $("importCount").textContent = I18N[state.lang].importhint;
      return;
    }
    setLabVisible(true);
    $("importCount").textContent = state.library.length + (state.lang === "ar" ? " تقرير مستورد" : " imported report(s)");
    const merged = {
      net: state.library.reduce((s, r) => s + (Number(r.stats.net) || 0), 0),
      pf: state.library.reduce((s, r) => s + (Number(r.stats.pf) || 0), 0) / state.library.length,
      wr: state.library.reduce((s, r) => s + (Number(r.stats.winRate) || 0), 0) / state.library.length,
      dd: Math.max(...state.library.map((r) => Number(r.stats.dd) || 0)),
      trades: state.library.reduce((s, r) => s + (Number(r.stats.trades) || 0), 0),
    };
    const cells = [
      ["NET PROFIT", money(merged.net), merged.net >= 0 ? "up" : "dn"],
      ["PROFIT FACTOR", merged.pf.toFixed(2), "hi"],
      ["WIN RATE", merged.wr.toFixed(1) + "%", ""],
      ["MAX DD", merged.dd.toFixed(2) + "%", "dn"],
      ["TRADES", String(merged.trades), ""],
      ["REPORTS", String(state.library.length), ""],
    ];
    $("infoGrid").innerHTML = cells.map(([k, v, c]) => `<div class="stat ${c}"><span>${k}</span><b>${v}</b></div>`).join("");
    $("labSource").textContent = state.library.map((r) => r.source).join(" · ");

    const aligned = AetherionLab.alignCurves(state.library);
    const palette = ["#00f0ff", "#f5c542", "#ff2e97", "#00ff9d", "#7c5cff", "#ff8a3d"];
    AXChart.lineChart($("equityChart"), aligned.map((s, i) => ({
      data: s.data, color: palette[i % palette.length], width: 1.8,
      fill: i === 0 ? "rgba(0,240,255,.06)" : null,
    })), { digits: 0 });

    const cost = AetherionLab.costReport(state.library);
    $("costGrid").innerHTML = [
      ["COMMISSION", fmt(cost.commission, 2), ""],
      ["SWAP", fmt(cost.swap, 2), ""],
      ["SLIPPAGE", fmt(cost.slippage, 2), ""],
      ["COST DRAG", fmt(cost.costDrag, 2), "dn"],
      ["COST / GROSS", cost.costRatio + "%", cost.costRatio >= 25 ? "dn" : "hi"],
      ["NET AFTER COSTS", money(cost.net), cost.net >= 0 ? "up" : "dn"],
    ].map(([k, v, c]) => `<div class="stat ${c}"><span>${k}</span><b>${v}</b></div>`).join("");
    $("costHint").textContent = cost.missingCommission
      ? (state.lang === "ar" ? "التقرير بلا عمولة ظاهرة — صدّر التقرير التفصيلي من MT5" : "No commission column — export the detailed MT5 report")
      : "";
    const rows = cost.bySymbol.slice(0, 8).map((r) =>
      `<tr><td>${r.symbol}</td><td>${r.n}</td><td>${money(r.net)}</td><td>${fmt(r.comm, 2)}</td><td>${fmt(r.swap, 2)}</td></tr>`
    ).join("");
    $("costTable").innerHTML = `<thead><tr><th>SYM</th><th>N</th><th>NET</th><th>COMM</th><th>SWAP</th></tr></thead><tbody>${rows}</tbody>`;

    $("aiList").innerHTML = AetherionLab.aiInsights(state.library, state.lang).map((c) =>
      `<article class="ai-card ${c.level}"><b>${c.title}</b><p>${c.body}</p></article>`
    ).join("");

    runCompare();
  }

  function runCompare() {
    if (!hasLab()) {
      setLabVisible(false);
      return;
    }
    const { matrix, tfs, syms } = AetherionLab.compareMatrix(state.library);
    state.heat = { matrix, tfs, syms };
    AXChart.heatmap($("heat"), matrix, tfs, syms);
    const aligned = AetherionLab.alignCurves(state.library);
    const palette = ["#00f0ff", "#f5c542", "#ff2e97", "#00ff9d", "#7c5cff", "#ff8a3d"];
    AXChart.lineChart($("overlay"), aligned.map((s, i) => ({
      data: s.data, color: palette[i % palette.length], width: 1.6,
    })), { digits: 0 });
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
        if (ev.closed) pushTape(ev.closed);
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

  const ag = $("aurora");
  const blobs = Array.from({ length: 5 }, (_, i) => ({
    x: Math.random(), y: Math.random(), r: 180 + i * 70,
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

  function uiState() {
    return {
      name: "AETHERION " + ($("symbol").value || "") + " " + new Date().toISOString().slice(0, 16),
      lang: state.lang,
      symbol: $("symbol").value,
      tf: $("tf").value,
      strategy: $("strategy").value,
      preset: $("preset").value,
      speed: state.speed,
    };
  }

  function applyWorkspace(ws) {
    if (!ws) return;
    if (ws.ui) {
      state.lang = ws.ui.lang || state.lang;
      if (ws.ui.symbol) $("symbol").value = ws.ui.symbol;
      if (ws.ui.tf) $("tf").value = ws.ui.tf;
      if (ws.ui.strategy) $("strategy").value = ws.ui.strategy;
      if (ws.ui.preset) $("preset").value = ws.ui.preset;
      if (ws.ui.speed) { state.speed = +ws.ui.speed; $("speed").value = state.speed; }
    }
    state.library = Array.isArray(ws.library) ? ws.library : [];
    applyLang();
    fillSelect();
    if (ws.ui && ws.ui.symbol) $("symbol").value = ws.ui.symbol;
    bootEngine();
    paintLab();
  }

  function persist() {
    const ws = AetherionLab.snapshotWorkspace(uiState(), state.library);
    AetherionLab.saveLocal(ws);
    refreshSlots();
    return ws;
  }

  function refreshSlots() {
    const sel = $("wsSlot");
    const slots = AetherionLab.listSlots();
    sel.innerHTML = `<option value="">${state.lang === "ar" ? "مساحات محفوظة" : "Saved workspaces"}</option>`;
    slots.forEach((s) => {
      const o = document.createElement("option");
      o.value = s.name;
      o.textContent = s.name;
      sel.appendChild(o);
    });
  }

  function exportCSV() {
    const rows = [["ticket", "symbol", "tf", "side", "openTime", "closeTime", "open", "close", "sl", "tp", "profit", "commission", "swap", "slippage", "exit", "reason", "source"]];
    const deals = hasLab()
      ? state.library.flatMap((r) => (r.deals || []).map((d) => ({ ...d, source: r.source })))
      : engine.closed.map((d) => ({ ...d, open: d.px, source: "SIM" }));
    deals.forEach((d) => {
      rows.push([d.ticket, d.symbol || engine.symbol, d.tf || engine.tf, d.side, d.openTime || d.t, d.closeTime, d.open || d.px, d.close, d.sl, d.tp, d.profit, d.commission || 0, d.swap || 0, d.slippage || 0, d.exit, d.reason, d.source || ""]);
    });
    download(new Blob([rows.map((r) => r.join(",")).join("\n")], { type: "text/csv;charset=utf-8" }), `AETHERION_${engine.symbol}_${engine.tf}.csv`);
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
    ctx.fillText((hasLab() ? "imported tester  ·  " : "simulation only  ·  ") + new Date().toISOString().slice(0, 16), 24, 70);
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
      const parsed = AetherionLab.parseTester(text, f.name);
      if (!parsed.deals.length && parsed.stats.net == null) continue;
      state.library.push(parsed);
    }
    persist();
    toast(I18N[state.lang].toastImported + " · " + state.library.length);
    const last = state.library[state.library.length - 1];
    if (last && last.stats.symbol && AetherionLab.UNIVERSE.some((s) => s.symbol === last.stats.symbol)) {
      $("symbol").value = last.stats.symbol;
      if (last.stats.tf) $("tf").value = last.stats.tf;
    }
    bootEngine();
    paintLab();
  }

  function bind() {
    $("langBtn").onclick = () => { state.lang = state.lang === "ar" ? "en" : "ar"; applyLang(); persist(); };
    $("playBtn").onclick = () => { state.playing = !state.playing; applyLang(); };
    $("stepBtn").onclick = () => { engine.step(); render(); };
    $("resetBtn").onclick = () => bootEngine();
    $("assetFilter").onchange = () => { fillSelect(); maybeAutoPreset(); bootEngine(); persist(); };
    $("symbol").onchange = () => { maybeAutoPreset(); bootEngine(); persist(); };
    $("tf").onchange = () => { bootEngine(); persist(); };
    $("strategy").onchange = () => { bootEngine(); persist(); };
    $("preset").onchange = () => { bootEngine(); persist(); };
    $("speed").oninput = () => syncSpeed();
    if ($("clearLabBtn")) $("clearLabBtn").onclick = () => {
      state.library = [];
      persist();
      paintLab();
      bootEngine();
      toast(I18N[state.lang].toastCleared);
    };
    window.addEventListener("keydown", (e) => {
      if (e.target && /INPUT|SELECT|TEXTAREA/.test(e.target.tagName)) return;
      if (e.code === "Space") {
        e.preventDefault();
        state.playing = !state.playing;
        applyLang();
      } else if (e.code === "ArrowRight") {
        e.preventDefault();
        engine.step();
        render();
      } else if (e.code === "ArrowLeft") {
        e.preventDefault();
        if (state.playing) { state.playing = false; applyLang(); }
        else if (engine.idx > 210) { engine.idx -= 1; render(); }
      }
    });
    $("csvBtn").onclick = exportCSV;
    $("pngBtn").onclick = exportPNG;
    $("cmpBtn").onclick = runCompare;
    $("importBtn").onclick = () => $("fileIn").click();
    $("fileIn").onchange = (e) => ingestFiles(e.target.files);
    $("saveWsBtn").onclick = () => {
      const ws = persist();
      download(new Blob([JSON.stringify(ws, null, 2)], { type: "application/json" }), (ws.name || "aetherion-workspace").replace(/\s+/g, "_") + ".json");
      toast(I18N[state.lang].toastSaved);
    };
    $("loadWsBtn").onclick = () => $("wsFile").click();
    $("wsFile").onchange = async (e) => {
      const f = e.target.files[0];
      if (!f) return;
      try { applyWorkspace(JSON.parse(await f.text())); persist(); } catch (_) {}
    };
    $("wsSlot").onchange = () => {
      if (!$("wsSlot").value) return;
      applyWorkspace(AetherionLab.loadLocal($("wsSlot").value));
    };
    const drop = $("drop");
    ["dragenter", "dragover"].forEach((ev) => drop.addEventListener(ev, (e) => { e.preventDefault(); drop.style.outline = "1px solid #00f0ff"; }));
    ["dragleave", "drop"].forEach((ev) => drop.addEventListener(ev, (e) => { e.preventDefault(); drop.style.outline = ""; }));
    drop.addEventListener("drop", (e) => ingestFiles(e.dataTransfer.files));
    window.addEventListener("resize", () => {
      render();
      if (hasLab()) paintLab();
    });
    setInterval(() => {
      $("clock").textContent = new Date().toLocaleTimeString(state.lang === "ar" ? "ar-EG" : "en-GB");
    }, 1000);
  }

  function start() {
    applyLang();
    bind();
    const saved = AetherionLab.loadLocal();
    if (saved && saved.library && saved.library.length) applyWorkspace(saved);
    else {
      fillSelect();
      maybeAutoPreset();
      bootEngine();
      setLabVisible(false);
    }
    requestAnimationFrame(tick);
  }

  start();
})();
