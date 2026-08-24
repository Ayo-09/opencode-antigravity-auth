/* AETHERION lab — universe, real tester ingest, costs, alignment, AI, workspace */
(function (g) {
  "use strict";

  const UNIVERSE = [
    { symbol: "EURUSD", asset: "FOREX", start: 1.085, vol: 0.0011, drift: 0.00001, spread: 0.00009, digits: 5, minutes: 60, volume: 1800, floor: 0.8 },
    { symbol: "GBPUSD", asset: "FOREX", start: 1.265, vol: 0.0013, drift: 0.000008, spread: 0.00012, digits: 5, minutes: 60, volume: 1400, floor: 1.0 },
    { symbol: "USDJPY", asset: "FOREX", start: 149.2, vol: 0.0010, drift: 0.000012, spread: 0.011, digits: 3, minutes: 60, volume: 1600, floor: 80 },
    { symbol: "AUDUSD", asset: "FOREX", start: 0.662, vol: 0.0012, drift: 0.000006, spread: 0.00012, digits: 5, minutes: 60, volume: 1100, floor: 0.4 },
    { symbol: "USDCAD", asset: "FOREX", start: 1.364, vol: 0.0010, drift: 0.000004, spread: 0.00013, digits: 5, minutes: 60, volume: 1000, floor: 0.9 },
    { symbol: "USDCHF", asset: "FOREX", start: 0.874, vol: 0.0010, drift: 0.000003, spread: 0.00014, digits: 5, minutes: 60, volume: 900, floor: 0.6 },
    { symbol: "NZDUSD", asset: "FOREX", start: 0.598, vol: 0.0013, drift: 0.000005, spread: 0.00016, digits: 5, minutes: 60, volume: 800, floor: 0.35 },
    { symbol: "EURJPY", asset: "FOREX", start: 162.1, vol: 0.0012, drift: 0.00001, spread: 0.018, digits: 3, minutes: 60, volume: 950, floor: 90 },
    { symbol: "GBPJPY", asset: "FOREX", start: 189.4, vol: 0.0015, drift: 0.00001, spread: 0.025, digits: 3, minutes: 60, volume: 880, floor: 100 },
    { symbol: "EURGBP", asset: "FOREX", start: 0.858, vol: 0.0008, drift: 0.000002, spread: 0.00011, digits: 5, minutes: 60, volume: 860, floor: 0.6 },
    { symbol: "AUDJPY", asset: "FOREX", start: 98.8, vol: 0.0013, drift: 0.000008, spread: 0.02, digits: 3, minutes: 60, volume: 700, floor: 50 },
    { symbol: "BTCUSD", asset: "CRYPTO", start: 64200, vol: 0.0065, drift: 0.00004, spread: 8.5, digits: 2, minutes: 60, volume: 420, floor: 1000 },
    { symbol: "ETHUSD", asset: "CRYPTO", start: 3180, vol: 0.0070, drift: 0.00003, spread: 1.4, digits: 2, minutes: 60, volume: 510, floor: 80 },
    { symbol: "SOLUSD", asset: "CRYPTO", start: 148, vol: 0.0095, drift: 0.00005, spread: 0.08, digits: 3, minutes: 60, volume: 380, floor: 5 },
    { symbol: "XRPUSD", asset: "CRYPTO", start: 0.62, vol: 0.0085, drift: 0.00003, spread: 0.0008, digits: 4, minutes: 60, volume: 360, floor: 0.05 },
    { symbol: "BNBUSD", asset: "CRYPTO", start: 575, vol: 0.0072, drift: 0.00003, spread: 0.18, digits: 2, minutes: 60, volume: 300, floor: 20 },
    { symbol: "BTCUSDT", asset: "USDT", start: 64200, vol: 0.0065, drift: 0.00004, spread: 8.5, digits: 2, minutes: 60, volume: 420, floor: 1000 },
    { symbol: "ETHUSDT", asset: "USDT", start: 3180, vol: 0.0070, drift: 0.00003, spread: 1.4, digits: 2, minutes: 60, volume: 510, floor: 80 },
    { symbol: "SOLUSDT", asset: "USDT", start: 148, vol: 0.0095, drift: 0.00005, spread: 0.06, digits: 3, minutes: 60, volume: 380, floor: 5 },
    { symbol: "BNBUSDT", asset: "USDT", start: 575, vol: 0.0072, drift: 0.00003, spread: 0.16, digits: 2, minutes: 60, volume: 300, floor: 20 },
    { symbol: "XRPUSDT", asset: "USDT", start: 0.62, vol: 0.0085, drift: 0.00003, spread: 0.0006, digits: 4, minutes: 60, volume: 360, floor: 0.05 },
    { symbol: "ADAUSDT", asset: "USDT", start: 0.46, vol: 0.009, drift: 0.00002, spread: 0.0004, digits: 4, minutes: 60, volume: 280, floor: 0.04 },
    { symbol: "DOGEUSDT", asset: "USDT", start: 0.148, vol: 0.011, drift: 0.00002, spread: 0.00015, digits: 5, minutes: 60, volume: 260, floor: 0.01 },
    { symbol: "XAUUSD", asset: "METAL", start: 2320, vol: 0.0022, drift: 0.00003, spread: 0.22, digits: 2, minutes: 60, volume: 900, floor: 1200 },
    { symbol: "XAGUSD", asset: "METAL", start: 27.4, vol: 0.0034, drift: 0.00002, spread: 0.018, digits: 3, minutes: 60, volume: 620, floor: 8 },
    { symbol: "XPTUSD", asset: "METAL", start: 980, vol: 0.0030, drift: 0.000015, spread: 0.8, digits: 2, minutes: 60, volume: 240, floor: 400 },
    { symbol: "USOIL", asset: "ENERGY", start: 78.4, vol: 0.0035, drift: 0.00001, spread: 0.03, digits: 3, minutes: 60, volume: 800, floor: 20 },
    { symbol: "UKOIL", asset: "ENERGY", start: 82.1, vol: 0.0034, drift: 0.00001, spread: 0.035, digits: 3, minutes: 60, volume: 720, floor: 20 },
    { symbol: "NATGAS", asset: "ENERGY", start: 2.85, vol: 0.006, drift: 0.00001, spread: 0.008, digits: 3, minutes: 60, volume: 500, floor: 0.8 },
    { symbol: "US30", asset: "INDEX", start: 39200, vol: 0.0020, drift: 0.00002, spread: 1.6, digits: 1, minutes: 60, volume: 700, floor: 20000 },
    { symbol: "US500", asset: "INDEX", start: 5280, vol: 0.0018, drift: 0.00002, spread: 0.5, digits: 2, minutes: 60, volume: 680, floor: 2000 },
    { symbol: "NAS100", asset: "INDEX", start: 17840, vol: 0.0024, drift: 0.000025, spread: 1.4, digits: 1, minutes: 60, volume: 640, floor: 8000 },
    { symbol: "GER40", asset: "INDEX", start: 18220, vol: 0.0021, drift: 0.000018, spread: 1.2, digits: 1, minutes: 60, volume: 540, floor: 8000 },
    { symbol: "UK100", asset: "INDEX", start: 8240, vol: 0.0017, drift: 0.000012, spread: 1.0, digits: 1, minutes: 60, volume: 480, floor: 4000 },
    { symbol: "JP225", asset: "INDEX", start: 38600, vol: 0.0023, drift: 0.00002, spread: 8, digits: 0, minutes: 60, volume: 420, floor: 15000 },
    { symbol: "AAPL", asset: "STOCK", start: 188.5, vol: 0.0028, drift: 0.00002, spread: 0.02, digits: 2, minutes: 60, volume: 1200, floor: 40 },
    { symbol: "TSLA", asset: "STOCK", start: 242, vol: 0.0048, drift: 0.00003, spread: 0.04, digits: 2, minutes: 60, volume: 1100, floor: 20 },
    { symbol: "NVDA", asset: "STOCK", start: 118, vol: 0.0042, drift: 0.00004, spread: 0.03, digits: 2, minutes: 60, volume: 1300, floor: 10 },
    { symbol: "MSFT", asset: "STOCK", start: 415, vol: 0.0022, drift: 0.00002, spread: 0.03, digits: 2, minutes: 60, volume: 900, floor: 80 },
    { symbol: "AMZN", asset: "STOCK", start: 186, vol: 0.0026, drift: 0.00002, spread: 0.03, digits: 2, minutes: 60, volume: 850, floor: 40 },
  ];

  const GROUPS = [
    { id: "FOREX", ar: "فوركس", en: "Forex" },
    { id: "CRYPTO", ar: "كريبتو", en: "Crypto" },
    { id: "USDT", ar: "أزواج USDT", en: "USDT pairs" },
    { id: "METAL", ar: "معادن", en: "Metals" },
    { id: "ENERGY", ar: "طاقة", en: "Energy" },
    { id: "INDEX", ar: "مؤشرات", en: "Indices" },
    { id: "STOCK", ar: "أسهم", en: "Stocks" },
  ];

  const LS_KEY = "aetherion.workspace.v2";
  const LS_SLOTS = "aetherion.slots.v2";
  const barCache = {};

  function mulberry32(a) {
    return function () {
      let t = (a += 0x6d2b79f5);
      t = Math.imul(t ^ (t >>> 15), t | 1);
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  function hashStr(s) {
    let h = 2166136261;
    for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 16777619);
    return h >>> 0;
  }

  function specOf(symbol) {
    return UNIVERSE.find((s) => s.symbol === symbol) || { ...UNIVERSE[0], symbol };
  }

  function synthesizeBars(spec, n = 720) {
    const key = spec.symbol + ":" + n;
    if (barCache[key]) return barCache[key];
    const rnd = mulberry32(0xae7e + hashStr(spec.symbol));
    let price = spec.start;
    const bars = [];
    const t0 = Date.UTC(2025, 0, 6, 0, 0);
    const step = (spec.minutes || 60) * 60000;
    const crypto = spec.asset === "CRYPTO" || spec.asset === "USDT";
    for (let i = 0, added = 0; added < n && i < n * 2; i++) {
      const ts = new Date(t0 + step * i);
      if (!crypto && ts.getUTCDay() === 0) continue;
      if (!crypto && ts.getUTCDay() === 6) continue;
      const vol = spec.vol * ((Math.floor(i / 80) % 3 === 2) ? 1.35 : 0.85);
      const drift = spec.drift + ((Math.floor(i / 110) % 2 === 0) ? 0.00015 : -0.00012);
      const shock = (rnd() * 2 - 1) * vol + drift;
      const o = price;
      const c = Math.max(spec.floor, price * (1 + shock));
      const wick = Math.abs((rnd() - 0.5) * 2) * vol * 0.6 * price;
      const h = Math.max(o, c) + wick;
      const l = Math.max(spec.floor, Math.min(o, c) - wick);
      const spread = spec.spread * (1.15 + 0.35 * Math.abs((rnd() - 0.5) * 2));
      bars.push({
        time: ts.toISOString().slice(0, 16),
        open: +o.toFixed(spec.digits),
        high: +h.toFixed(spec.digits),
        low: +l.toFixed(spec.digits),
        close: +c.toFixed(spec.digits),
        volume: +(Math.abs((rnd() - 0.5) * 2) * spec.volume * 0.4 + spec.volume).toFixed(2),
        spread: +spread.toFixed(spec.digits),
      });
      price = c;
      added++;
    }
    barCache[key] = bars;
    return bars;
  }

  function parseStamp(raw) {
    if (raw == null || raw === "") return null;
    if (raw instanceof Date && !isNaN(raw)) return raw.getTime();
    if (typeof raw === "number" && Number.isFinite(raw)) return raw < 1e12 ? raw * 1000 : raw;
    const s = String(raw).trim();
    if (!s) return null;
    const m = s.match(/(\d{4})[./-](\d{1,2})[./-](\d{1,2})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?/);
    if (m) {
      return Date.UTC(+m[1], +m[2] - 1, +m[3], +(m[4] || 0), +(m[5] || 0), +(m[6] || 0));
    }
    const t = Date.parse(s);
    return Number.isFinite(t) ? t : null;
  }

  function num(v) {
    if (v == null || v === "") return null;
    if (typeof v === "number") return Number.isFinite(v) ? v : null;
    const s = String(v).replace(/\s/g, "").replace(/[%]/g, "").replace(/,/g, "");
    const n = parseFloat(s);
    return Number.isFinite(n) ? n : null;
  }

  function stripTags(html) {
    return String(html || "").replace(/<[^>]+>/g, " ").replace(/&nbsp;/g, " ").replace(/\s+/g, " ").trim();
  }

  function grabStat(text, labels) {
    for (const label of labels) {
      const re = new RegExp(label + "[\\s\\S]{0,80}?</td>\\s*<td[^>]*>\\s*(?:<b>)?\\s*([\\-0-9.,%]+)", "i");
      const m = text.match(re);
      if (m) return num(m[1]);
    }
    return null;
  }

  function grabText(text, labels) {
    for (const label of labels) {
      const re = new RegExp(label + "[\\s\\S]{0,80}?</td>\\s*<td[^>]*>\\s*(?:<b>)?\\s*([^<]+)", "i");
      const m = text.match(re);
      if (m) return stripTags(m[1]);
    }
    return "";
  }

  function headerIndex(headers, aliases) {
    const h = headers.map((x) => x.toLowerCase());
    for (const a of aliases) {
      const i = h.findIndex((x) => x.includes(a));
      if (i >= 0) return i;
    }
    return -1;
  }

  function dealFromCells(headers, cells, fallback) {
    const gi = (aliases) => {
      const i = headerIndex(headers, aliases);
      return i >= 0 ? cells[i] : "";
    };
    const sideRaw = String(gi(["type", "dir", "side", "buy", "نوع"]) || cells.find((c) => /buy|sell/i.test(c)) || "buy");
    const side = /sell/i.test(sideRaw) ? "SELL" : "BUY";
    const openTime = gi(["open time", "time", "وقت"]) || cells[0];
    const closeTime = gi(["close time", "وقت الإغلاق"]);
    const profit = num(gi(["profit", "ربح"]));
    const comm = num(gi(["commission", "comm", "عمولة"])) || 0;
    const swap = num(gi(["swap", "swap/roll", "سواب"])) || 0;
    const spread = num(gi(["spread", "سبريد"]));
    const open = num(gi(["price", "open", "سعر"]));
    const close = num(gi(["close", "price close", "إغلاق"]));
    const sl = num(gi(["s/l", "sl", "stop"]));
    const tp = num(gi(["t/p", "tp", "take"]));
    const lots = num(gi(["volume", "lots", "size", "حجم"])) || 0.1;
    const slip = num(gi(["slippage", "deviation", "انزلاق"]));
    return {
      ticket: gi(["ticket", "deal", "order", "رقم"]) || fallback.ticket,
      symbol: gi(["symbol", "item", "رمز"]) || fallback.symbol,
      tf: gi(["tf", "period", "إطار"]) || fallback.tf,
      side,
      openTime,
      closeTime: closeTime || openTime,
      open,
      close,
      sl,
      tp,
      lots,
      profit: profit == null ? 0 : profit,
      commission: comm,
      swap,
      spread,
      slippage: slip,
      reason: gi(["comment", "تعليق"]) || "",
      exit: gi(["exit", "خروج"]) || "",
    };
  }

  function parseHtmlTester(text, name) {
    const out = emptyReport(name);
    out.stats.symbol = grabText(text, ["Symbol", "الرمز"]);
    out.stats.tf = (grabText(text, ["Period", "الإطار", "الفترة"]).match(/[MNHDW]\d+|MN1/i) || [""])[0];
    out.stats.net = grabStat(text, ["Total Net Profit", "صافي الربح"]);
    out.stats.grossProfit = grabStat(text, ["Gross Profit", "إجمالي الربح"]);
    out.stats.grossLoss = grabStat(text, ["Gross Loss", "إجمالي الخسارة"]);
    out.stats.pf = grabStat(text, ["Profit Factor", "عامل الربح"]);
    out.stats.dd = grabStat(text, ["Maximal Drawdown", "أقصى هبوط"]);
    out.stats.trades = grabStat(text, ["Total Trades", "Total Deals", "إجمالي الصفقات"]);
    out.stats.winRate = grabStat(text, ["Profit Trades", "صفقات رابحة"]);
    out.stats.commission = grabStat(text, ["Commission", "العمولة"]);
    out.stats.swap = grabStat(text, ["Swap", "السواب"]);
    out.stats.deposit = grabStat(text, ["Initial Deposit", "الإيداع الأولي"]) || 10000;
    out.stats.spreadModel = grabText(text, ["Spread", "السبريد"]);
    out.stats.model = grabText(text, ["Modelling quality", "Model", "جودة النمذجة"]);

    const rows = [...text.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/gi)];
    let headers = [];
    rows.forEach((rm) => {
      const ths = [...rm[1].matchAll(/<th[^>]*>([\s\S]*?)<\/th>/gi)].map((c) => stripTags(c[1]));
      if (ths.length >= 6 && /time|deal|symbol|type|volume|price/i.test(ths.join(" "))) {
        headers = ths;
        return;
      }
      const cells = [...rm[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)].map((c) => stripTags(c[1]));
      if (headers.length && cells.length >= 6 && /buy|sell/i.test(cells.join(" "))) {
        out.deals.push(dealFromCells(headers, cells, {
          ticket: 1000 + out.deals.length,
          symbol: out.stats.symbol,
          tf: out.stats.tf,
        }));
      }
    });
    return finalizeReport(out);
  }

  function parseCsvTester(text, name) {
    const out = emptyReport(name);
    const lines = text.replace(/^\uFEFF/, "").split(/\r?\n/).filter((l) => l.trim());
    if (!lines.length) return finalizeReport(out);
    const split = (line) => {
      const cols = [];
      let cur = "", q = false;
      for (let i = 0; i < line.length; i++) {
        const ch = line[i];
        if (ch === '"') q = !q;
        else if (ch === "," && !q) { cols.push(cur); cur = ""; }
        else cur += ch;
      }
      cols.push(cur);
      return cols.map((c) => c.trim());
    };
    const headers = split(lines.shift());
    for (const line of lines) {
      const cells = split(line);
      if (cells.every((c) => !c)) continue;
      out.deals.push(dealFromCells(headers, cells, {
        ticket: 1000 + out.deals.length,
        symbol: "",
        tf: "",
      }));
    }
    if (out.deals[0]) {
      out.stats.symbol = out.deals[0].symbol;
      out.stats.tf = out.deals[0].tf;
    }
    return finalizeReport(out);
  }

  function parseJsonTester(text, name) {
    try {
      const data = JSON.parse(text);
      if (data && data.deals) {
        const out = emptyReport(name);
        Object.assign(out.stats, data.stats || {});
        out.deals = data.deals;
        return finalizeReport(out);
      }
    } catch (_) {}
    return parseCsvTester(text, name);
  }

  function emptyReport(name) {
    return {
      source: name,
      importedAt: new Date().toISOString(),
      real: true,
      stats: {},
      deals: [],
      curve: [],
    };
  }

  function finalizeReport(out) {
    const deposit = out.stats.deposit || 10000;
    let eq = deposit;
    let peak = deposit;
    let gw = 0, gl = 0, comm = 0, swap = 0, slip = 0;
    out.deals.forEach((d, i) => {
      d.commission = Number(d.commission) || 0;
      d.swap = Number(d.swap) || 0;
      d.slippage = Number(d.slippage) || 0;
      d.profit = Number(d.profit) || 0;
      d.tsOpen = parseStamp(d.openTime);
      d.tsClose = parseStamp(d.closeTime) || d.tsOpen;
      comm += d.commission;
      swap += d.swap;
      slip += d.slippage;
      const net = d.profit + d.commission + d.swap;
      if (d.profit >= 0) gw += d.profit; else gl += d.profit;
      eq += net;
      peak = Math.max(peak, eq);
      out.curve.push({
        t: d.closeTime || d.openTime || i,
        ts: d.tsClose || i,
        eq: +eq.toFixed(2),
        dd: peak ? +((100 * (peak - eq)) / peak).toFixed(2) : 0,
      });
    });
    const n = out.deals.length;
    const wins = out.deals.filter((d) => d.profit > 0).length;
    if (out.stats.net == null) out.stats.net = +(eq - deposit).toFixed(2);
    if (out.stats.trades == null) out.stats.trades = n;
    if (out.stats.winRate == null) out.stats.winRate = n ? +((100 * wins) / n).toFixed(2) : 0;
    if (out.stats.pf == null) out.stats.pf = gl < 0 ? +(gw / Math.abs(gl)).toFixed(2) : (gw > 0 ? 9 : 0);
    if (out.stats.dd == null) out.stats.dd = out.curve.length ? Math.max(...out.curve.map((c) => c.dd)) : 0;
    if (out.stats.commission == null) out.stats.commission = +comm.toFixed(2);
    if (out.stats.swap == null) out.stats.swap = +swap.toFixed(2);
    out.stats.slippage = +(out.stats.slippage || slip).toFixed(2);
    out.stats.grossProfit = out.stats.grossProfit == null ? +gw.toFixed(2) : out.stats.grossProfit;
    out.stats.grossLoss = out.stats.grossLoss == null ? +gl.toFixed(2) : out.stats.grossLoss;
    out.stats.deposit = deposit;
    out.stats.wins = wins;
    out.stats.losses = n - wins;
    return out;
  }

  function parseTester(text, name = "import") {
    const raw = String(text || "");
    if (/^\s*[\{\[]/.test(raw)) return parseJsonTester(raw, name);
    if (/<html|Strategy Tester|Total Net Profit|Maximal Drawdown/i.test(raw)) return parseHtmlTester(raw, name);
    return parseCsvTester(raw, name);
  }

  function attachDealsToBars(bars, deals) {
    if (!bars.length) return deals;
    const stamps = bars.map((b) => parseStamp(b.time));
    return deals.map((d) => {
      const t = d.tsOpen || parseStamp(d.openTime);
      let best = 0, bestAbs = Infinity;
      if (t != null) {
        for (let i = 0; i < stamps.length; i++) {
          if (stamps[i] == null) continue;
          const a = Math.abs(stamps[i] - t);
          if (a < bestAbs) { bestAbs = a; best = i; }
        }
      }
      const te = d.tsClose || parseStamp(d.closeTime);
      let end = best;
      if (te != null) {
        let eAbs = Infinity;
        for (let i = 0; i < stamps.length; i++) {
          if (stamps[i] == null) continue;
          const a = Math.abs(stamps[i] - te);
          if (a < eAbs) { eAbs = a; end = i; }
        }
      }
      return { ...d, i: best, iClose: end, aligned: t != null };
    });
  }

  function alignCurves(reports) {
    const series = reports.filter((r) => r.curve && r.curve.length);
    const stamps = new Set();
    series.forEach((r) => r.curve.forEach((p) => {
      const ts = p.ts || parseStamp(p.t);
      if (ts != null) stamps.add(ts);
    }));
    const axis = [...stamps].sort((a, b) => a - b);
    if (!axis.length) {
      return series.map((r) => ({
        name: (r.stats.symbol || r.source) + " " + (r.stats.tf || ""),
        data: r.curve.map((p) => ({ y: p.eq, t: p.t })),
      }));
    }
    return series.map((r) => {
      const pts = r.curve
        .map((p) => ({ ts: p.ts || parseStamp(p.t), y: p.eq }))
        .filter((p) => p.ts != null)
        .sort((a, b) => a.ts - b.ts);
      let j = 0;
      const data = axis.map((ts) => {
        while (j < pts.length - 1 && pts[j + 1].ts <= ts) j++;
        return { t: ts, y: pts.length ? pts[Math.min(j, pts.length - 1)].y : 0 };
      });
      return { name: (r.stats.symbol || r.source) + " " + (r.stats.tf || ""), data };
    });
  }

  function costReport(reports) {
    const deals = reports.flatMap((r) => r.deals || []);
    const comm = deals.reduce((s, d) => s + (Number(d.commission) || 0), 0);
    const swap = deals.reduce((s, d) => s + (Number(d.swap) || 0), 0);
    const slip = deals.reduce((s, d) => s + (Number(d.slippage) || 0), 0);
    const spread = deals.reduce((s, d) => s + (Number(d.spread) || 0), 0);
    const gross = deals.filter((d) => d.profit > 0).reduce((s, d) => s + d.profit, 0);
    const loss = deals.filter((d) => d.profit < 0).reduce((s, d) => s + d.profit, 0);
    const net = deals.reduce((s, d) => s + (d.profit || 0) + (d.commission || 0) + (d.swap || 0), 0);
    const costs = Math.abs(comm) + Math.abs(swap) + Math.abs(slip);
    const byHour = Array.from({ length: 24 }, (_, h) => ({ h, n: 0, pnl: 0 }));
    const bySymbol = {};
    deals.forEach((d) => {
      const ts = d.tsOpen || parseStamp(d.openTime);
      if (ts != null) {
        const h = new Date(ts).getUTCHours();
        byHour[h].n += 1;
        byHour[h].pnl += (d.profit || 0);
      }
      const sym = d.symbol || "?";
      if (!bySymbol[sym]) bySymbol[sym] = { symbol: sym, n: 0, net: 0, comm: 0, swap: 0 };
      bySymbol[sym].n += 1;
      bySymbol[sym].net += (d.profit || 0) + (d.commission || 0) + (d.swap || 0);
      bySymbol[sym].comm += d.commission || 0;
      bySymbol[sym].swap += d.swap || 0;
    });
    return {
      deals: deals.length,
      commission: +comm.toFixed(2),
      swap: +swap.toFixed(2),
      slippage: +slip.toFixed(2),
      spreadSum: +spread.toFixed(5),
      gross: +gross.toFixed(2),
      loss: +loss.toFixed(2),
      net: +net.toFixed(2),
      costDrag: +costs.toFixed(2),
      costRatio: gross > 0 ? +((costs / gross) * 100).toFixed(1) : 0,
      byHour,
      bySymbol: Object.values(bySymbol).sort((a, b) => b.net - a.net),
      missingSlippage: deals.every((d) => !d.slippage),
      missingCommission: deals.every((d) => !d.commission),
    };
  }

  function aiInsights(reports, lang) {
    const ar = lang === "ar";
    const t = (a, e) => (ar ? a : e);
    if (!reports.length) {
      return [{
        level: "wait",
        title: t("بانتظار تقرير حقيقي", "Waiting for a real report"),
        body: t(
          "لن أقدّم أي رقم أو توصية قبل أن تستورد ملف Strategy Tester من MT5 (HTM أو CSV).",
          "No figure or recommendation is shown until you import an MT5 Strategy Tester HTM/CSV."
        ),
      }];
    }
    const cost = costReport(reports);
    const stats = reports.reduce((acc, r) => {
      acc.net += Number(r.stats.net) || 0;
      acc.pf.push(Number(r.stats.pf) || 0);
      acc.dd.push(Number(r.stats.dd) || 0);
      acc.wr.push(Number(r.stats.winRate) || 0);
      acc.trades += Number(r.stats.trades) || (r.deals || []).length;
      return acc;
    }, { net: 0, pf: [], dd: [], wr: [], trades: 0 });
    const pf = stats.pf.reduce((s, v) => s + v, 0) / stats.pf.length;
    const dd = Math.max(...stats.dd, 0);
    const wr = stats.wr.reduce((s, v) => s + v, 0) / stats.wr.length;
    const out = [];

    if (pf < 1) {
      out.push({
        level: "bad",
        title: t("عامل الربح تحت 1 — الحافة سالبة", "Profit factor under 1 — negative edge"),
        body: t(
          "أوقف الحساب الحقيقي. خفّض InpRiskPercent إلى 0.40 وجرّب Aetherion_Conservative.set ثم أعد الاختبار بـ Every tick based on real ticks.",
          "Do not go live. Drop InpRiskPercent to 0.40, load Aetherion_Conservative.set, retest with every-tick real ticks."
        ),
      });
    } else if (pf < 1.3) {
      out.push({
        level: "warn",
        title: t("الحافة رقيقة", "Thin edge"),
        body: t(
          `PF = ${pf.toFixed(2)}. ارفع InpADXMin وInpConfirmBars درجة واحدة وفعّل InpAvoidNewsWindow حتى لا تُؤكل الحافة بالأخبار.`,
          `PF = ${pf.toFixed(2)}. Raise InpADXMin and InpConfirmBars by one step and enable InpAvoidNewsWindow.`
        ),
      });
    } else {
      out.push({
        level: "ok",
        title: t("عامل الربح مقبول إحصائياً", "Profit factor is statistically usable"),
        body: t(
          `متوسط PF = ${pf.toFixed(2)} على ${reports.length} تقريراً. أبقِ المخاطرة ≤ 0.75٪ ولا ترفع اللوت بعد سلسلة أرباح.`,
          `Mean PF = ${pf.toFixed(2)} across ${reports.length} report(s). Keep risk ≤ 0.75% and do not raise lot after a winning streak.`
        ),
      });
    }

    if (dd >= 15) {
      out.push({
        level: "bad",
        title: t("هبوط يتجاوز حد الأمان", "Drawdown breaches the safety cap"),
        body: t(
          `أقصى DD = ${dd.toFixed(1)}٪. فعّل InpEmergencyClose وخفّض InpMaxDrawdownPct إلى 10 وInpMaxDailyLossPct إلى 2.`,
          `Max DD = ${dd.toFixed(1)}%. Keep InpEmergencyClose on, set InpMaxDrawdownPct to 10 and InpMaxDailyLossPct to 2.`
        ),
      });
    } else if (dd >= 10) {
      out.push({
        level: "warn",
        title: t("الهبوط يقترب من سقف البوت", "Drawdown approaching the EA cap"),
        body: t(
          `DD = ${dd.toFixed(1)}٪. تجنّب الإعداد Aggressive على هذا الرمز واستخدم ملف Gold/Crypto إن كان الأصل متقلباً.`,
          `DD = ${dd.toFixed(1)}%. Avoid the Aggressive preset on this symbol; use Gold/Crypto profiles on volatile assets.`
        ),
      });
    }

    if (wr >= 60 && pf < 1.4) {
      out.push({
        level: "warn",
        title: t("فوز كثير وهدف صغير", "High win-rate, small winners"),
        body: t(
          `نسبة الفوز ${wr.toFixed(1)}٪ لكن PF ضعيف. ارفع InpRR إلى 1.8–2.0 وفعّل الإغلاق الجزئي عند 1R حتى لا تُغلق الأرباح مبكراً.`,
          `Win rate ${wr.toFixed(1)}% but PF is weak. Raise InpRR to 1.8–2.0 and keep partial close at 1R.`
        ),
      });
    }

    if (cost.costRatio >= 25) {
      out.push({
        level: "bad",
        title: t("التكاليف تبتلع الحافة", "Costs are eating the edge"),
        body: t(
          `العمولة+السواب+الانزلاق ≈ ${cost.costRatio}% من إجمالي الربح. لا تستخدم سكالب على هذا الوسيط. انتقل إلى H1/H4 وAetherion_Forex.set أو Aetherion_Crypto.set.`,
          `Commission+swap+slippage ≈ ${cost.costRatio}% of gross profit. Do not scalp this broker. Move to H1/H4 with Forex or Crypto presets.`
        ),
      });
    } else if (cost.costRatio >= 12) {
      out.push({
        level: "warn",
        title: t("تكاليف مرتفعة نسبياً", "Elevated trading costs"),
        body: t(
          `اسحب سقف السبريد: InpAutoSpread=true وInpSpreadATRMax=0.25. راقب عمولة الرمز في مواصفات العقد.`,
          `Tighten the spread gate: InpAutoSpread=true and InpSpreadATRMax=0.25. Check the symbol contract commission.`
        ),
      });
    }

    if (cost.missingCommission || cost.missingSlippage) {
      out.push({
        level: "info",
        title: t("التقرير ناقص أعمدة تكلفة", "Report is missing cost columns"),
        body: t(
          "صدّر تقرير MT5 التفصيلي (Save as Report) وليس الملخص. نحتاج Commission وSwap ويفضّل سعر الأمر مقابل سعر الصفقة لحساب الانزلاق.",
          "Export the detailed MT5 report (Save as Report), not the summary. We need Commission, Swap, and ideally order vs deal price for slippage."
        ),
      });
    }

    const hours = cost.byHour.filter((h) => h.n >= 3).sort((a, b) => a.pnl - b.pnl);
    if (hours.length && hours[0].pnl < 0) {
      const h = hours[0].h;
      out.push({
        level: "warn",
        title: t("ساعة سلبية متكررة", "A persistently losing hour"),
        body: t(
          `الساعة ${String(h).padStart(2, "0")}:00 UTC خاسرة. أغلقها عبر نافذة الأخبار أو عطّل الجلسة التي تغطيها (آسيا/لندن/نيويورك).`,
          `Hour ${String(h).padStart(2, "0")}:00 UTC is a loser. Block it with the news window or disable that session.`
        ),
      });
    }

    if (stats.trades < 30) {
      out.push({
        level: "info",
        title: t("العيّنة صغيرة", "Sample is too small"),
        body: t(
          `فقط ${stats.trades} صفقة. لا تعتمد القرار قبل 100 صفقة على تيكات حقيقية عبر رموز متعددة.`,
          `Only ${stats.trades} trades. Do not decide before ~100 real-tick trades across several symbols.`
        ),
      });
    }

    const cryptoReps = reports.filter((r) => /USDT|BTC|ETH|SOL|XRP|BNB|ADA|DOGE/i.test((r.stats.symbol || "") + r.source));
    if (cryptoReps.length && dd >= 12) {
      out.push({
        level: "warn",
        title: t("الكريبتو يحتاج وقفاً أوسع", "Crypto needs a wider stop"),
        body: t(
          "حمّل Aetherion_Crypto.set: InpCryptoATRSL=2.4 ومخاطرة × 0.70. لا تستخدم إعداد السكالب على BTCUSDT.",
          "Load Aetherion_Crypto.set: InpCryptoATRSL=2.4 and risk × 0.70. Do not scalp BTCUSDT with the scalp preset."
        ),
      });
    }

    if (!out.some((x) => x.level === "ok") && pf >= 1.3 && dd < 10) {
      out.push({
        level: "ok",
        title: t("جاهز لتجريبي ممتد لا لحساب حي فوري", "Ready for an extended demo, not instant live"),
        body: t(
          "شغّل أسبوعين على Demo لنفس الوسيط ثم انقل الإعداد دون تغيير اللوت.",
          "Run two weeks on the same broker's demo, then go live without changing the lot."
        ),
      });
    }
    return out;
  }

  function compareMatrix(reports) {
    const tfs = [];
    const syms = [];
    reports.forEach((r) => {
      const s = r.stats.symbol || r.source;
      const t = r.stats.tf || "?";
      if (!syms.includes(s)) syms.push(s);
      if (!tfs.includes(t)) tfs.push(t);
    });
    const matrix = syms.map((s) => tfs.map((t) => {
      const hit = reports.find((r) => (r.stats.symbol || r.source) === s && (r.stats.tf || "?") === t);
      if (!hit) return null;
      return { pf: Number(hit.stats.pf) || 0, net: Number(hit.stats.net) || 0, wr: Number(hit.stats.winRate) || 0, dd: Number(hit.stats.dd) || 0, trades: Number(hit.stats.trades) || 0 };
    }));
    return { matrix, tfs, syms };
  }

  function snapshotWorkspace(ui, library) {
    return {
      version: 2,
      name: ui.name || "AETHERION workspace",
      savedAt: new Date().toISOString(),
      ui: {
        lang: ui.lang,
        symbol: ui.symbol,
        tf: ui.tf,
        strategy: ui.strategy,
        preset: ui.preset,
        speed: ui.speed,
      },
      library,
    };
  }

  function saveLocal(ws) {
    localStorage.setItem(LS_KEY, JSON.stringify(ws));
    const slots = listSlots();
    const name = ws.name || "workspace";
    const next = [{ name, savedAt: ws.savedAt }, ...slots.filter((s) => s.name !== name)].slice(0, 12);
    localStorage.setItem(LS_SLOTS, JSON.stringify(next));
    try { localStorage.setItem(LS_KEY + ":" + name, JSON.stringify(ws)); } catch (_) {}
  }

  function loadLocal(name) {
    const raw = name ? localStorage.getItem(LS_KEY + ":" + name) : localStorage.getItem(LS_KEY);
    if (!raw) return null;
    try { return JSON.parse(raw); } catch (_) { return null; }
  }

  function listSlots() {
    try { return JSON.parse(localStorage.getItem(LS_SLOTS) || "[]"); } catch (_) { return []; }
  }

  g.AetherionLab = {
    UNIVERSE, GROUPS, specOf, synthesizeBars, parseTester, attachDealsToBars,
    alignCurves, costReport, aiInsights, compareMatrix,
    snapshotWorkspace, saveLocal, loadLocal, listSlots, parseStamp,
  };
})(window);
