/* AETHERION engine — mirrors MQL5 AetherionEngine.mqh */
(function (g) {
  "use strict";

  const ASSET_KEYS = {
    USDT: ["USDT", "USDC", "BUSD"],
    CRYPTO: ["BTC", "ETH", "XRP", "SOL", "BNB", "ADA", "DOGE", "LTC", "DOT", "AVAX", "LINK", "MATIC", "TON", "TRX", "NEAR", "APT", "SUI", "SHIB", "PEPE", "ATOM", "UNI", "ARB", "OP", "FIL", "INJ", "MKR"],
    METAL: ["XAU", "XAG", "XPT", "XPD", "GOLD", "SILVER"],
    ENERGY: ["WTI", "BRENT", "UKOIL", "USOIL", "XTI", "XBR", "NATGAS", "NGAS"],
    INDEX: ["US30", "US500", "US100", "NAS100", "NASDAQ", "SPX", "SP500", "GER40", "GER30", "DAX", "UK100", "JP225", "USTEC", "NDX", "DJ30", "DE40", "FRA40", "HK50"],
  };

  const PRESETS = {
    balanced: { risk: 0.75, atrSL: 1.8, rr: 1.6, adxMin: 18, rsiBuy: [42, 68], rsiSell: [32, 58], newBar: true, confirmBars: 1, useHTF: true, lossStreakMax: 3, lossStreakBars: 6, spreadStableBars: 1, rolloverPause: true, pullback: true, fridayFlatten: true, maxHoldHours: 24 },
    conservative: { risk: 0.4, atrSL: 2.4, rr: 2.0, adxMin: 22, rsiBuy: [45, 65], rsiSell: [35, 55], newBar: true, confirmBars: 2, useHTF: true, lossStreakMax: 2, lossStreakBars: 8, spreadStableBars: 2, rolloverPause: true, pullback: true, fridayFlatten: true, maxHoldHours: 36 },
    aggressive: { risk: 1.5, atrSL: 1.4, rr: 1.2, adxMin: 14, rsiBuy: [40, 72], rsiSell: [28, 60], newBar: false, confirmBars: 0, useHTF: false, lossStreakMax: 0, lossStreakBars: 6, spreadStableBars: 0, rolloverPause: false, pullback: false, fridayFlatten: false, maxHoldHours: 0 },
    crypto: { risk: 0.5, atrSL: 2.4, rr: 1.8, adxMin: 16, rsiBuy: [40, 70], rsiSell: [30, 60], newBar: true, confirmBars: 1, useHTF: true, lossStreakMax: 3, lossStreakBars: 6, spreadStableBars: 1, rolloverPause: false, pullback: true, fridayFlatten: false, maxHoldHours: 48 },
    forex: { risk: 0.75, atrSL: 1.8, rr: 1.6, adxMin: 18, rsiBuy: [42, 68], rsiSell: [32, 58], newBar: true, confirmBars: 1, useHTF: true, lossStreakMax: 3, lossStreakBars: 6, spreadStableBars: 1, rolloverPause: true, pullback: true, fridayFlatten: true, maxHoldHours: 24 },
    gold: { risk: 0.6, atrSL: 2.2, rr: 1.8, adxMin: 20, rsiBuy: [42, 68], rsiSell: [32, 58], newBar: true, confirmBars: 1, useHTF: true, lossStreakMax: 3, lossStreakBars: 8, spreadStableBars: 2, rolloverPause: true, pullback: true, fridayFlatten: true, maxHoldHours: 36 },
    scalp: { risk: 0.35, atrSL: 1.2, rr: 1.1, adxMin: 12, rsiBuy: [38, 75], rsiSell: [25, 62], newBar: false, confirmBars: 0, useHTF: false, lossStreakMax: 4, lossStreakBars: 4, spreadStableBars: 1, rolloverPause: true, pullback: false, fridayFlatten: true, maxHoldHours: 8 },
  };

  const TF_MIN = { M1: 1, M5: 5, M15: 15, M30: 30, H1: 60, H4: 240, D1: 1440, W1: 10080 };

  function detectAsset(sym) {
    let u = String(sym || "").toUpperCase().replace(/[.\-_]/g, "");
    u = u.replace(/MICRO|PRO|ECN|RAW/g, "");
    if (u.length > 3 && /[Mm]$/.test(u)) u = u.slice(0, -1);
    if (ASSET_KEYS.USDT.some((k) => u.includes(k))) return "USDT";
    if (ASSET_KEYS.CRYPTO.some((k) => u.includes(k))) return "CRYPTO";
    if (ASSET_KEYS.METAL.some((k) => u.includes(k))) return "METAL";
    if (ASSET_KEYS.ENERGY.some((k) => u.includes(k))) return "ENERGY";
    if (ASSET_KEYS.INDEX.some((k) => u.includes(k))) return "INDEX";
    if (/^[A-Z]{1,5}$/.test(u) && u.length <= 5 && !/USD|EUR|GBP|JPY|CHF|AUD|NZD|CAD/.test(u)) return "STOCK";
    if (u.length === 6) return "FOREX";
    return "OTHER";
  }

  function fillingFor(asset) {
    if (asset === "USDT" || asset === "CRYPTO" || asset === "STOCK" || asset === "INDEX") return { fill: "IOC", exec: "MARKET" };
    return { fill: "IOC", exec: "INSTANT" };
  }

  function profile(asset, preset) {
    const p = { ...PRESETS[preset] || PRESETS.balanced };
    if (asset === "USDT" || asset === "CRYPTO") p.atrSL = Math.max(p.atrSL, 2.4);
    if (asset === "METAL") p.atrSL = Math.max(p.atrSL, 2.2);
    if (asset === "INDEX" || asset === "ENERGY") p.atrSL = Math.max(p.atrSL, 2.0);
    if (asset === "USDT" || asset === "CRYPTO") p.risk *= 0.7;
    return p;
  }

  function spreadCap(asset) {
    return { FOREX: 30, METAL: 80, ENERGY: 120, INDEX: 250, STOCK: 200, CRYPTO: 400, USDT: 400, OTHER: 50 }[asset] || 50;
  }

  function ema(values, period) {
    const k = 2 / (period + 1);
    const out = new Array(values.length);
    let e = values[0];
    for (let i = 0; i < values.length; i++) {
      e = values[i] * k + e * (1 - k);
      out[i] = e;
    }
    return out;
  }

  function rsi(closes, period = 14) {
    const out = new Array(closes.length).fill(50);
    let ag = 0, al = 0;
    for (let i = 1; i <= period && i < closes.length; i++) {
      const ch = closes[i] - closes[i - 1];
      if (ch >= 0) ag += ch; else al -= ch;
    }
    ag /= period; al /= period;
    if (closes.length > period) out[period] = al === 0 ? 100 : 100 - 100 / (1 + ag / al);
    for (let i = period + 1; i < closes.length; i++) {
      const ch = closes[i] - closes[i - 1];
      const g = Math.max(ch, 0), l = Math.max(-ch, 0);
      ag = (ag * (period - 1) + g) / period;
      al = (al * (period - 1) + l) / period;
      out[i] = al === 0 ? 100 : 100 - 100 / (1 + ag / al);
    }
    return out;
  }

  function atr(highs, lows, closes, period = 14) {
    const tr = highs.map((h, i) => {
      if (i === 0) return h - lows[i];
      return Math.max(h - lows[i], Math.abs(h - closes[i - 1]), Math.abs(lows[i] - closes[i - 1]));
    });
    const out = [];
    let a = tr.slice(0, period).reduce((s, v) => s + v, 0) / period;
    for (let i = 0; i < tr.length; i++) {
      if (i < period) out.push(a);
      else {
        a = (a * (period - 1) + tr[i]) / period;
        out.push(a);
      }
    }
    return out;
  }

  function macd(closes, fast = 12, slow = 26, sig = 9) {
    const ef = ema(closes, fast), es = ema(closes, slow);
    const main = ef.map((v, i) => v - es[i]);
    const signal = ema(main, sig);
    return { main, signal };
  }

  function adx(highs, lows, closes, period = 14) {
    const plus = [0], minus = [0], tr = [highs[0] - lows[0]];
    for (let i = 1; i < closes.length; i++) {
      const up = highs[i] - highs[i - 1];
      const dn = lows[i - 1] - lows[i];
      plus.push(up > dn && up > 0 ? up : 0);
      minus.push(dn > up && dn > 0 ? dn : 0);
      tr.push(Math.max(highs[i] - lows[i], Math.abs(highs[i] - closes[i - 1]), Math.abs(lows[i] - closes[i - 1])));
    }
    const sm = (arr) => {
      const o = [];
      let a = arr.slice(0, period).reduce((s, v) => s + v, 0);
      for (let i = 0; i < arr.length; i++) {
        if (i < period) o.push(a / period);
        else {
          a = a - a / period + arr[i];
          o.push(a / period);
        }
      }
      return o;
    };
    const str = sm(tr), p = sm(plus), m = sm(minus);
    const pdi = p.map((v, i) => (str[i] ? (100 * v) / str[i] : 0));
    const mdi = m.map((v, i) => (str[i] ? (100 * v) / str[i] : 0));
    const dx = pdi.map((v, i) => {
      const s = v + mdi[i];
      return s ? (100 * Math.abs(v - mdi[i])) / s : 0;
    });
    return { adx: ema(dx, period), pdi, mdi };
  }

  function bb(closes, period = 20, dev = 2) {
    const mid = [], up = [], lo = [];
    for (let i = 0; i < closes.length; i++) {
      const a = Math.max(0, i - period + 1);
      const slice = closes.slice(a, i + 1);
      const mu = slice.reduce((s, v) => s + v, 0) / slice.length;
      const sd = Math.sqrt(slice.reduce((s, v) => s + (v - mu) ** 2, 0) / slice.length);
      mid.push(mu); up.push(mu + dev * sd); lo.push(mu - dev * sd);
    }
    return { mid, up, lo };
  }

  function resample(bars, fromMin, toMin) {
    if (!bars.length || toMin <= fromMin) return bars.slice();
    const ratio = Math.max(1, Math.round(toMin / fromMin));
    const out = [];
    for (let i = 0; i < bars.length; i += ratio) {
      const chunk = bars.slice(i, i + ratio);
      out.push({
        time: chunk[0].time,
        open: chunk[0].open,
        high: Math.max(...chunk.map((c) => c.high)),
        low: Math.min(...chunk.map((c) => c.low)),
        close: chunk[chunk.length - 1].close,
        volume: chunk.reduce((s, c) => s + (c.volume || 0), 0),
        spread: chunk[chunk.length - 1].spread,
      });
    }
    return out;
  }

  function upsample(bars, fromMin, toMin) {
    if (!bars.length || toMin >= fromMin) return bars.slice();
    const ratio = Math.max(1, Math.round(fromMin / toMin));
    const out = [];
    for (const b of bars) {
      const span = b.close - b.open;
      for (let k = 0; k < ratio; k++) {
        const t = k / ratio;
        const mid = b.open + span * t;
        const wobble = (b.high - b.low) * 0.15 * Math.sin((k + 1) * 1.7);
        const o = k === 0 ? b.open : out[out.length - 1].close;
        const c = k === ratio - 1 ? b.close : mid + wobble;
        out.push({
          time: b.time,
          open: o,
          high: Math.max(o, c, b.high * (0.998 + t * 0.002)),
          low: Math.min(o, c, b.low * (1.002 - t * 0.002)),
          close: c,
          volume: (b.volume || 0) / ratio,
          spread: b.spread,
        });
      }
    }
    return out;
  }

  function prepareBars(raw, nativeMin, tf) {
    const want = TF_MIN[tf] || 60;
    if (want === nativeMin) return raw.slice();
    if (want > nativeMin) return resample(raw, nativeMin, want);
    return upsample(raw, nativeMin, want);
  }

  function higherTF(tf) {
    return { M1: "M15", M5: "M15", M15: "H1", M30: "H1", H1: "H4", H4: "D1", D1: "W1", W1: "W1" }[tf] || "H4";
  }

  function parseBarHM(t) {
    const s = String(t || "");
    const m = s.match(/T(\d{2}):(\d{2})/) || s.match(/\s(\d{2}):(\d{2})/);
    if (m) return { h: +m[1], m: +m[2] };
    const d = new Date(t);
    if (!Number.isNaN(+d)) return { h: d.getUTCHours(), m: d.getUTCMinutes() };
    return { h: 12, m: 0 };
  }

  function presetForAsset(asset) {
    if (asset === "CRYPTO" || asset === "USDT") return "crypto";
    if (asset === "METAL") return "gold";
    if (asset === "FOREX") return "forex";
    return "balanced";
  }

  function digitsOf(bars) {
    const c = bars[0] ? bars[0].close : 1;
    if (c > 1000) return 2;
    if (c > 50) return 3;
    if (c > 5) return 4;
    return 5;
  }

  function pointOf(d) {
    return Math.pow(10, -d);
  }

  class Engine {
    constructor() {
      this.reset();
    }

    reset(opts = {}) {
      this.symbol = opts.symbol || "EURUSD";
      this.tf = opts.tf || "H1";
      this.strategy = opts.strategy || "auto";
      this.preset = opts.preset || "balanced";
      this.asset = detectAsset(this.symbol);
      this.cfg = profile(this.asset, this.preset);
      this.bars = [];
      this.idx = 210;
      this.equity = 10000;
      this.balance = 10000;
      this.peak = 10000;
      this.dayStart = 10000;
      this.pos = null;
      this.closed = [];
      this.curve = [{ t: 0, eq: 10000, dd: 0 }];
      this.wins = 0;
      this.losses = 0;
      this.gw = 0;
      this.gl = 0;
      this.today = 0;
      this.lastReason = this.asset === "USDT" || this.asset === "CRYPTO" ? "جلسة 24/7 — بانتظار التقاء تكيّفي" : "بانتظار التقاء الاتجاه";
      this.lastSignal = 0;
      this.halted = false;
      this.liveSpread = 0;
      this.tick = 0;
      this.lossStreak = 0;
      this.streakPauseUntil = -1;
      this.spreadOkStreak = 0;
      Object.assign(this, fillingFor(this.asset));
    }

    load(bars) {
      this.bars = bars;
      this.closes = bars.map((b) => b.close);
      this.highs = bars.map((b) => b.high);
      this.lows = bars.map((b) => b.low);
      this.emaF = ema(this.closes, 21);
      this.emaS = ema(this.closes, 55);
      this.emaT = ema(this.closes, 200);
      this.rsi = rsi(this.closes, 14);
      this.atr = atr(this.highs, this.lows, this.closes, 14);
      this.macd = macd(this.closes);
      this.adx = adx(this.highs, this.lows, this.closes, 14);
      this.bb = bb(this.closes, 20, 2);
      this.digits = digitsOf(bars);
      this.point = pointOf(this.digits);
      this.idx = Math.min(210, bars.length - 2);
      const fromMin = TF_MIN[this.tf] || 60;
      const htfName = higherTF(this.tf);
      const toMin = TF_MIN[htfName] || fromMin * 4;
      const ratio = Math.max(1, Math.round(toMin / fromMin));
      const htf = ratio <= 1 ? bars.slice() : resample(bars, fromMin, toMin);
      const hf = ema(htf.map((b) => b.close), 21);
      const hs = ema(htf.map((b) => b.close), 55);
      this.htfFast = bars.map((_, i) => hf[Math.min(hf.length - 1, Math.floor(i / ratio))] || 0);
      this.htfSlow = bars.map((_, i) => hs[Math.min(hs.length - 1, Math.floor(i / ratio))] || 0);
    }

    bar() {
      return this.bars[this.idx] || this.bars[this.bars.length - 1];
    }

    regime() {
      const a = this.adx.adx[this.idx] || 0;
      const close = this.closes[this.idx] || 0;
      const atrv = this.atr[this.idx] || 0;
      const atrPct = close > 0 ? (100 * atrv) / close : 0;
      const quietAdx = Math.min(14, (this.cfg.adxMin || 18) * 0.75);
      const volCap = { FOREX: 0.45, METAL: 0.85, ENERGY: 1.1, INDEX: 0.8, STOCK: 0.8, CRYPTO: 2.8, USDT: 2.8 }[this.asset] || 1;
      if (a < quietAdx) return "QUIET";
      if (atrPct >= volCap) return "VOLATILE";
      if (a >= 25) return "TREND";
      if (a < this.cfg.adxMin) return "RANGE";
      return "TREND";
    }

    activeStrat() {
      if (this.strategy !== "auto") return this.strategy;
      const r = this.regime();
      if (r === "RANGE") return "range";
      return "trend";
    }

    snapshot() {
      const b = this.bar() || { close: 0, spread: 0 };
      const spr = this.liveSpread || b.spread || 0;
      const ask = b.close + spr / 2;
      const bid = b.close - spr / 2;
      const dd = this.peak > 0 ? (100 * (this.peak - this.equity)) / this.peak : 0;
      const n = this.wins + this.losses;
      const pf = this.gl < 0 ? this.gw / Math.abs(this.gl) : this.gw > 0 ? 9 : 0;
      const wr = n ? (100 * this.wins) / n : 0;
      const atrv = this.atr[this.idx] || 0;
      const pts = this.point ? spr / this.point : 0;
      const cap = spreadCap(this.asset);
      const spreadOk = pts <= cap && (atrv <= 0 || spr <= atrv * 0.35);
      const hm = parseBarHM(b.time);
      const roll = !!(this.cfg.rolloverPause && this.asset !== "CRYPTO" && this.asset !== "USDT" &&
        ((hm.h === 23 && hm.m >= 50) || (hm.h === 0 && hm.m <= 20)));
      const streakHold = this.cfg.lossStreakMax > 0 && this.lossStreak >= this.cfg.lossStreakMax && this.idx < this.streakPauseUntil;
      const spreadWait = this.cfg.spreadStableBars > 0 && this.spreadOkStreak < this.cfg.spreadStableBars;
      let block = "";
      if (this.halted) block = "HALTED";
      else if (streakHold) block = "STREAK";
      else if (!spreadOk) block = "SPREAD";
      else if (spreadWait) block = "SPREAD WAIT";
      else if (roll) block = "ROLLOVER";
      else if (this.regime() === "QUIET") block = "QUIET";
      else if (this.regime() === "VOLATILE") block = "VOLATILE";
      else if (this.pos) block = "IN TRADE";
      return {
        symbol: this.symbol,
        tf: this.tf,
        asset: this.asset,
        bid, ask,
        spread: spr,
        spreadPts: pts,
        spreadOk,
        atr: atrv,
        emaF: this.emaF[this.idx],
        emaS: this.emaS[this.idx],
        emaT: this.emaT[this.idx],
        rsi: this.rsi[this.idx],
        adx: this.adx.adx[this.idx],
        regime: this.regime(),
        strat: this.activeStrat(),
        equity: this.equity,
        balance: this.balance,
        floating: this.equity - this.balance,
        daily: this.equity - this.dayStart,
        dd,
        winRate: wr,
        pf,
        openPos: this.pos ? 1 : 0,
        today: this.today,
        lastReason: this.lastReason,
        lastSignal: this.lastSignal,
        block,
        fill: this.fill,
        exec: this.exec,
        digits: this.digits,
        pos: this.pos,
        closed: this.closed,
        net: this.equity - 10000,
        idx: this.idx,
        bars: this.bars,
        curve: this.curve,
        emaFSeries: this.emaF,
        emaSSeries: this.emaS,
        emaTSeries: this.emaT,
      };
    }

    signal() {
      const i = this.idx;
      const close = this.closes[i];
      const high = this.highs[i];
      const low = this.lows[i];
      const open = this.bars[i].open;
      let bull = this.emaF[i] > this.emaS[i] && close >= this.emaT[i] * 0.999;
      let bear = this.emaF[i] < this.emaS[i] && close <= this.emaT[i] * 1.001;
      if (this.cfg.useHTF) {
        if ((this.htfFast[i] || 0) <= (this.htfSlow[i] || 0)) bull = false;
        if ((this.htfFast[i] || 0) >= (this.htfSlow[i] || 0)) bear = false;
      }
      const [b0, b1] = this.cfg.rsiBuy;
      const [s0, s1] = this.cfg.rsiSell;
      const rsiBuy = this.rsi[i] >= b0 && this.rsi[i] <= b1;
      const rsiSell = this.rsi[i] >= s0 && this.rsi[i] <= s1;
      const rsiOs = this.rsi[i] <= 30;
      const rsiOb = this.rsi[i] >= 70;
      const macdBuy = this.macd.main[i] > this.macd.signal[i];
      const macdSell = this.macd.main[i] < this.macd.signal[i];
      const adxOk = (this.adx.adx[i] || 0) >= this.cfg.adxMin;
      const diBuy = this.adx.pdi[i] > this.adx.mdi[i];
      const diSell = this.adx.mdi[i] > this.adx.pdi[i];
      const rg = this.regime();
      if (rg === "QUIET") return { sig: 0, reason: "QUIET — no trade" };
      if (rg === "VOLATILE") return { sig: 0, reason: "VOLATILE — stand aside" };
      const st = this.activeStrat();
      let sig = 0;
      let reason = "وضع الخمول";
      if (st === "trend" || st === "scalp") {
        if (!adxOk) return { sig: 0, reason: "ADX ضعيف — السوق بلا اتجاه واضح" };
        if (bull && rsiBuy && macdBuy && diBuy) { sig = 1; reason = "تلاقي اتجاه شرائي · EMA+RSI+MACD+DI"; }
        else if (bear && rsiSell && macdSell && diSell) { sig = -1; reason = "تلاقي اتجاه بيعي · EMA+RSI+MACD+DI"; }
        else return { sig: 0, reason: "لا تلاقي اتجاهي بعد" };
      } else if (st === "range") {
        if (low <= this.bb.lo[i] && rsiOs && close > open) { sig = 1; reason = "ارتداد نطاق من الحد السفلي"; }
        else if (high >= this.bb.up[i] && rsiOb && close < open) { sig = -1; reason = "ارتداد نطاق من الحد العلوي"; }
        else return { sig: 0, reason: "السعر داخل النطاق" };
      } else if (st === "break") {
        if (close > this.bb.up[i] && macdBuy && bull) { sig = 1; reason = "اختراق صاعد لبولينجر"; }
        else if (close < this.bb.lo[i] && macdSell && bear) { sig = -1; reason = "اختراق هابط لبولينجر"; }
        else return { sig: 0, reason: "لا اختراق مؤكد" };
      } else {
        return { sig: 0, reason };
      }
      if (this.cfg.pullback && st === "trend" && sig) {
        const pbBuy = (low <= this.emaF[i] || low <= this.emaS[i]) && close > open;
        const pbSell = (high >= this.emaF[i] || high >= this.emaS[i]) && close < open;
        if (sig === 1 && !pbBuy) return { sig: 0, reason: "no EMA pullback" };
        if (sig === -1 && !pbSell) return { sig: 0, reason: "no EMA pullback" };
        reason += " +pullback";
      }
      const need = this.cfg.confirmBars || 0;
      if (need > 0 && sig) {
        for (let k = 0; k < need; k++) {
          const j = i - k;
          if (j < 0) return { sig: 0, reason: "confirm-no-bar" };
          const ck = this.closes[j];
          const ok = this.bars[j].open;
          if (sig === 1 && ck < ok) return { sig: 0, reason: "confirm bars disagree" };
          if (sig === -1 && ck > ok) return { sig: 0, reason: "confirm bars disagree" };
        }
        reason += " +" + need + " bar confirm";
      }
      return { sig, reason };
    }

    open(sig, reason) {
      const b = this.bar();
      const atrv = this.atr[this.idx] || Math.abs(b.close) * 0.002;
      const slDist = atrv * this.cfg.atrSL;
      const tpDist = slDist * this.cfg.rr;
      const px = b.close;
      const pos = {
        side: sig > 0 ? "BUY" : "SELL",
        px,
        sl: sig > 0 ? px - slDist : px + slDist,
        tp: sig > 0 ? px + tpDist : px - tpDist,
        t: b.time,
        i: this.idx,
        lots: 0.1,
        reason,
        ticket: 88000 + this.closed.length + 1,
      };
      this.pos = pos;
      this.lastSignal = sig;
      this.lastReason = reason;
      this.today += 1;
      return pos;
    }

    closePos(price, tag) {
      const p = this.pos;
      if (!p) return null;
      const R = Math.abs(p.px - p.sl) || 1e-9;
      const pts = p.side === "BUY" ? price - p.px : p.px - price;
      const riskMoney = this.balance * (this.cfg.risk / 100);
      const pnl = riskMoney * (pts / R) - Math.abs(this.liveSpread || 0) * 0.05;
      this.equity += pnl;
      this.balance = this.equity;
      this.peak = Math.max(this.peak, this.equity);
      if (this.equity < this.peak * 0.88) this.halted = true;
      if (pnl >= 0) { this.wins++; this.gw += pnl; this.lossStreak = 0; }
      else {
        this.losses++; this.gl += pnl; this.lossStreak += 1;
        if (this.cfg.lossStreakMax > 0 && this.lossStreak >= this.cfg.lossStreakMax)
          this.streakPauseUntil = this.idx + (this.cfg.lossStreakBars || 6);
      }
      const deal = {
        ...p,
        close: price,
        closeTime: this.bar().time,
        profit: pnl,
        exit: tag,
        spread: this.liveSpread,
        symbol: this.symbol,
        tf: this.tf,
      };
      this.closed.push(deal);
      this.pos = null;
      this.lastReason = tag === "TP" ? "إصابة الهدف" : tag === "SL" ? "وقف الخسارة" : tag;
      return deal;
    }

    manage() {
      if (!this.pos) return null;
      const b = this.bar();
      const p = this.pos;
      const hm = parseBarHM(b.time);
      const d = new Date(b.time);
      const dow = Number.isNaN(+d) ? -1 : d.getUTCDay();
      if (this.cfg.fridayFlatten && this.asset !== "CRYPTO" && this.asset !== "USDT" && dow === 5 && hm.h >= 19)
        return this.closePos(b.close, "FRIDAY");
      const holdH = this.cfg.maxHoldHours || 0;
      if (holdH > 0 && this.asset !== "CRYPTO" && this.asset !== "USDT") {
        const bars = Math.max(1, Math.round((holdH * 60) / (TF_MIN[this.tf] || 60)));
        if (this.idx - (p.i || 0) >= bars) return this.closePos(b.close, "TIME");
      }
      if (p.side === "BUY") {
        if (b.low <= p.sl) return this.closePos(p.sl, "SL");
        if (b.high >= p.tp) return this.closePos(p.tp, "TP");
      } else {
        if (b.high >= p.sl) return this.closePos(p.sl, "SL");
        if (b.low <= p.tp) return this.closePos(p.tp, "TP");
      }
      // mark-to-market
      const last = b.close;
      const R = Math.abs(p.px - p.sl) || 1e-9;
      const pts = p.side === "BUY" ? last - p.px : p.px - last;
      const riskMoney = this.balance * (this.cfg.risk / 100);
      this.equity = this.balance + riskMoney * (pts / R);
      this.peak = Math.max(this.peak, this.equity);
      return null;
    }

    step() {
      if (this.idx >= this.bars.length - 1) return { done: true };
      this.idx += 1;
      this.tick += 1;
      const b = this.bar();
      const base = b.spread || this.point * 10;
      this.liveSpread = Math.max(this.point, base * (0.85 + 0.45 * Math.abs(Math.sin(this.tick * 0.17 + this.idx * 0.03))));
      const closed = this.manage();
      let opened = null;
      const sprNow = this.point ? this.liveSpread / this.point : 0;
      const atrv = this.atr[this.idx] || 0;
      const spreadOk = sprNow <= spreadCap(this.asset) && (atrv <= 0 || this.liveSpread <= atrv * 0.35);
      if (spreadOk) this.spreadOkStreak += 1; else this.spreadOkStreak = 0;
      if (!this.pos && !this.halted) {
        const snap = this.snapshot();
        if (snap.block && snap.block !== "IN TRADE") {
          this.lastReason = snap.block === "SPREAD" ? "السبريد أعلى من سقف الأصل"
            : snap.block === "SPREAD WAIT" ? "انتظار استقرار السبريد"
            : snap.block === "ROLLOVER" ? "إيقاف الرول أوفر 23:50–00:20"
            : snap.block === "STREAK" ? "إيقاف بعد سلسلة خسائر"
            : snap.block;
        } else if (snap.spreadOk) {
          const s = this.signal();
          this.lastReason = s.reason;
          if (s.sig) opened = this.open(s.sig, s.reason);
        } else {
          this.lastReason = "السبريد أعلى من سقف الأصل";
        }
      }
      const dd = this.peak > 0 ? (100 * (this.peak - this.equity)) / this.peak : 0;
      this.curve.push({ t: b.time, eq: this.equity, dd });
      return { done: false, opened, closed, snap: this.snapshot() };
    }
  }

  function parseTester(text, name = "import") {
    const out = { source: name, stats: {}, deals: [], curve: [] };
    const html = /<html|Strategy Tester|Total Net Profit/i.test(text);
    if (html) {
      const grab = (label) => {
        const re = new RegExp(label + "[^<]*</td>\\s*<td[^>]*>\\s*<b>?\\s*([\\-0-9.,%]+)", "i");
        const m = text.match(re);
        return m ? parseFloat(m[1].replace(/,/g, "")) : null;
      };
      out.stats.net = grab("Total Net Profit");
      out.stats.pf = grab("Profit Factor");
      out.stats.dd = grab("Maximal Drawdown");
      out.stats.trades = grab("Total Trades");
      out.stats.winRate = grab("Profit Trades");
      out.stats.symbol = (text.match(/Symbol<\/td>\s*<td[^>]*>\s*<b>([^<]+)/i) || [])[1] || "";
      out.stats.tf = (text.match(/Period<\/td>\s*<td[^>]*>([A-Z0-9]+)/i) || [])[1] || "";
      const rowRe = /<tr[^>]*>([\s\S]*?)<\/tr>/gi;
      let rm;
      while ((rm = rowRe.exec(text))) {
        const cells = [...rm[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)].map((c) => c[1].replace(/<[^>]+>/g, "").trim());
        if (cells.length < 10) continue;
        if (!/BUY|SELL|buy|sell/i.test(cells.join(" "))) continue;
        const side = (cells.find((c) => /buy|sell/i.test(c)) || "").toUpperCase();
        const nums = cells.map((c) => parseFloat(c.replace(/,/g, ""))).filter((n) => Number.isFinite(n));
        out.deals.push({
          openTime: cells[0],
          ticket: nums[0],
          symbol: cells[2] || out.stats.symbol,
          side: side.includes("SELL") ? "SELL" : "BUY",
          lots: nums[1] || 0.1,
          open: nums[2],
          sl: nums[3],
          tp: nums[4],
          close: nums[5],
          closeTime: cells[9] || cells[8],
          profit: nums[nums.length - 2] || nums[nums.length - 1],
          reason: cells[cells.length - 1],
        });
      }
    } else {
      const lines = text.split(/\r?\n/).filter(Boolean);
      const head = lines.shift().split(",").map((h) => h.trim());
      for (const line of lines) {
        const cols = line.split(",");
        const rec = {};
        head.forEach((h, i) => (rec[h] = cols[i]));
        out.deals.push({
          ticket: rec.ticket,
          symbol: rec.symbol,
          tf: rec.tf,
          side: rec.side || rec.Type,
          openTime: rec.openTime || rec.Time,
          closeTime: rec.closeTime,
          open: +rec.open || +rec.Price,
          close: +rec.close,
          sl: +rec.sl,
          tp: +rec.tp,
          lots: +rec.lots || +rec.Volume,
          profit: +rec.profit || +rec.Profit,
          spread: +rec.spread,
          reason: rec.reason || rec.Comment,
          exit: rec.exit,
        });
      }
    }
    let eq = 10000, peak = 10000;
    out.deals.forEach((d, i) => {
      eq += Number(d.profit) || 0;
      peak = Math.max(peak, eq);
      out.curve.push({ t: d.closeTime || i, eq, dd: peak ? (100 * (peak - eq)) / peak : 0 });
    });
    if (out.stats.net == null) out.stats.net = eq - 10000;
    if (out.stats.trades == null) out.stats.trades = out.deals.length;
    const w = out.deals.filter((d) => d.profit > 0).length;
    if (out.stats.winRate == null) out.stats.winRate = out.deals.length ? (100 * w) / out.deals.length : 0;
    const gw = out.deals.filter((d) => d.profit > 0).reduce((s, d) => s + d.profit, 0);
    const gl = out.deals.filter((d) => d.profit < 0).reduce((s, d) => s + d.profit, 0);
    if (out.stats.pf == null) out.stats.pf = gl < 0 ? gw / Math.abs(gl) : 0;
    return out;
  }

  g.Aetherion = {
    Engine, PRESETS, detectAsset, fillingFor, spreadCap, prepareBars, parseTester, TF_MIN, profile, higherTF, presetForAsset,
  };
})(window);
