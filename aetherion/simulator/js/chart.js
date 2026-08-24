/* AETHERION cinematic charts */
(function (g) {
  "use strict";

  const C = {
    up: "#00ff9d",
    dn: "#ff4d6d",
    cyan: "#00f0ff",
    gold: "#f5c542",
    mag: "#ff2e97",
    grid: "rgba(255,255,255,0.045)",
    text: "#8b93a7",
  };

  function size(canvas) {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const r = canvas.getBoundingClientRect();
    const w = Math.max(1, r.width), h = Math.max(1, r.height);
    if (canvas.width !== Math.round(w * dpr) || canvas.height !== Math.round(h * dpr)) {
      canvas.width = Math.round(w * dpr);
      canvas.height = Math.round(h * dpr);
    }
    const ctx = canvas.getContext("2d");
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    return { ctx, w, h, dpr };
  }

  function glowLine(ctx, draw, color, blur = 14) {
    ctx.save();
    ctx.shadowColor = color;
    ctx.shadowBlur = blur;
    ctx.strokeStyle = color;
    draw();
    ctx.restore();
  }

  function nice(min, max, n = 6) {
    const span = max - min || 1;
    const step = Math.pow(10, Math.floor(Math.log10(span / n)));
    const err = (n * step) / span;
    const mul = err <= 0.15 ? 10 : err <= 0.35 ? 5 : err <= 0.75 ? 2 : 1;
    const s = step * mul;
    const a = Math.floor(min / s) * s;
    const ticks = [];
    for (let v = a; v <= max + s * 0.01; v += s) ticks.push(v);
    return ticks;
  }

  function priceFmt(v, d) {
    return Number(v).toFixed(d);
  }

  class PriceChart {
    constructor(canvas) {
      this.canvas = canvas;
      this.hover = null;
      this.flash = [];
      this.hits = [];
      this.hotDeal = null;
      canvas.addEventListener("mousemove", (e) => {
        const r = canvas.getBoundingClientRect();
        this.hover = { x: e.clientX - r.left, y: e.clientY - r.top };
      });
      canvas.addEventListener("mouseleave", () => {
        this.hover = null;
        this.hotDeal = null;
        canvas.style.cursor = "crosshair";
      });
    }

    nearestDeal(px, py) {
      let best = null, bestD = 22;
      this.hits.forEach((h) => {
        const d = Math.hypot(h.x - px, h.y - py);
        if (d < bestD) { bestD = d; best = h.deal; }
      });
      return best;
    }

    draw(snap, opts = {}) {
      if (!snap || !snap.bars) return;
      const { ctx, w, h } = size(this.canvas);
      ctx.clearRect(0, 0, w, h);
      const pad = { l: 12, r: 72, t: 52, b: 48 };
      const viewN = Math.min(snap.bars.length, opts.viewN || 120);
      const end = Math.min(snap.idx + 1, snap.bars.length);
      const start = Math.max(0, end - viewN);
      const bars = snap.bars.slice(start, end);
      if (!bars.length) return;
      const lo = Math.min(...bars.map((b) => b.low));
      const hi = Math.max(...bars.map((b) => b.high));
      const extra = (hi - lo) * 0.08 || 1;
      const min = lo - extra, max = hi + extra;
      const cw = (w - pad.l - pad.r) / bars.length;
      const X = (i) => pad.l + i * cw + cw / 2;
      const Y = (p) => pad.t + ((max - p) / (max - min)) * (h - pad.t - pad.b);
      const volH = 40;
      const maxVol = Math.max(...bars.map((b) => b.volume || 1), 1);

      // grid
      ctx.font = "11px IBM Plex Mono";
      nice(min, max, 5).forEach((v) => {
        const y = Y(v);
        ctx.strokeStyle = C.grid;
        ctx.beginPath(); ctx.moveTo(pad.l, y); ctx.lineTo(w - pad.r, y); ctx.stroke();
        ctx.fillStyle = C.text;
        ctx.textAlign = "left";
        ctx.fillText(priceFmt(v, snap.digits), w - pad.r + 8, y + 4);
      });

      // EMA glow
      const paintEma = (series, color, width) => {
        glowLine(ctx, () => {
          ctx.lineWidth = width;
          ctx.beginPath();
          bars.forEach((_, i) => {
            const v = series[start + i];
            if (v == null) return;
            const x = X(i), y = Y(v);
            i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
          });
          ctx.stroke();
        }, color, 12);
      };
      if (snap.emaTSeries) paintEma(snap.emaTSeries, "rgba(245,197,66,.55)", 1.2);
      if (snap.emaSSeries) paintEma(snap.emaSSeries, "rgba(255,46,151,.7)", 1.4);
      if (snap.emaFSeries) paintEma(snap.emaFSeries, "rgba(0,240,255,.95)", 1.6);

      // spread ribbon around last close
      if (bars.length) {
        const last = bars[bars.length - 1];
        const spr = snap.spread || last.spread || 0;
        const y1 = Y(last.close + spr / 2), y2 = Y(last.close - spr / 2);
        ctx.fillStyle = "rgba(245,197,66,0.08)";
        ctx.fillRect(pad.l, Math.min(y1, y2), w - pad.l - pad.r, Math.max(2, Math.abs(y2 - y1)));
      }

      // candles
      bars.forEach((b, i) => {
        const up = b.close >= b.open;
        const col = up ? C.up : C.dn;
        const x = X(i);
        const yO = Y(b.open), yC = Y(b.close), yH = Y(b.high), yL = Y(b.low);
        ctx.save();
        ctx.shadowColor = col;
        ctx.shadowBlur = i === bars.length - 1 ? 18 : 8;
        ctx.strokeStyle = col;
        ctx.lineWidth = 1.2;
        ctx.beginPath(); ctx.moveTo(x, yH); ctx.lineTo(x, yL); ctx.stroke();
        const bw = Math.max(2.2, cw * 0.62);
        const top = Math.min(yO, yC), bh = Math.max(1.4, Math.abs(yC - yO));
        ctx.fillStyle = up ? "rgba(0,255,157,.85)" : "rgba(255,77,109,.88)";
        ctx.fillRect(x - bw / 2, top, bw, bh);
        ctx.restore();
        // volume
        const vh = ((b.volume || 0) / maxVol) * volH;
        ctx.fillStyle = up ? "rgba(0,255,157,.18)" : "rgba(255,77,109,.18)";
        ctx.fillRect(x - bw / 2, h - pad.b + 6 + (volH - vh), bw, vh);
      });

      // live + imported trades
      this.hits = [];
      const mark = (barIndex, price, side, label, deal) => {
        if (barIndex == null || barIndex < start || barIndex >= end || price == null) return;
        const i = barIndex - start;
        const x = X(i), y = Y(price);
        const hot = deal && this.hotDeal && (this.hotDeal.ticket === deal.ticket) && (this.hotDeal.openTime === deal.openTime);
        ctx.save();
        ctx.shadowColor = side === "BUY" ? C.cyan : C.mag;
        ctx.shadowBlur = hot ? 28 : 16;
        ctx.fillStyle = side === "BUY" ? C.cyan : C.mag;
        ctx.beginPath();
        const s = hot ? 1.35 : 1;
        if (side === "BUY") {
          ctx.moveTo(x, y + 10 * s); ctx.lineTo(x - 6 * s, y + 20 * s); ctx.lineTo(x + 6 * s, y + 20 * s);
        } else {
          ctx.moveTo(x, y - 10 * s); ctx.lineTo(x - 6 * s, y - 20 * s); ctx.lineTo(x + 6 * s, y - 20 * s);
        }
        ctx.closePath(); ctx.fill();
        if (hot) {
          ctx.strokeStyle = C.gold;
          ctx.lineWidth = 1.4;
          ctx.beginPath();
          ctx.arc(x, y, 16, 0, Math.PI * 2);
          ctx.stroke();
        }
        ctx.font = "10px IBM Plex Mono";
        ctx.textAlign = "center";
        ctx.fillText(label, x, side === "BUY" ? y + 32 : y - 24);
        ctx.restore();
        if (deal) this.hits.push({ x, y, deal });
      };

      const pool = []
        .concat(snap.closed || [])
        .concat(snap.importedDeals || []);
      pool.forEach((d) => {
        const px = d.px != null ? d.px : d.open;
        if (d.i != null) mark(d.i, px, d.side, (d.side || "B")[0], d);
        if (d.iClose != null && d.close != null) mark(d.iClose, d.close, d.side, "X", d);
      });
      if (snap.pos) {
        mark(snap.pos.i, snap.pos.px, snap.pos.side, snap.pos.side);
        const ySL = Y(snap.pos.sl), yTP = Y(snap.pos.tp), yOP = Y(snap.pos.px);
        ctx.setLineDash([5, 5]);
        ctx.strokeStyle = C.dn; ctx.beginPath(); ctx.moveTo(pad.l, ySL); ctx.lineTo(w - pad.r, ySL); ctx.stroke();
        ctx.strokeStyle = C.up; ctx.beginPath(); ctx.moveTo(pad.l, yTP); ctx.lineTo(w - pad.r, yTP); ctx.stroke();
        ctx.strokeStyle = C.cyan; ctx.setLineDash([]); ctx.beginPath(); ctx.moveTo(pad.l, yOP); ctx.lineTo(w - pad.r, yOP); ctx.stroke();
        ctx.font = "10px IBM Plex Mono";
        ctx.fillStyle = C.dn; ctx.fillText("SL " + priceFmt(snap.pos.sl, snap.digits), w - pad.r - 4, ySL - 4);
        ctx.fillStyle = C.up; ctx.textAlign = "right";
        ctx.fillText("TP " + priceFmt(snap.pos.tp, snap.digits), w - pad.r - 4, yTP - 4);
      }

      // flashes
      this.flash = this.flash.filter((f) => (f.life -= 0.04) > 0);
      this.flash.forEach((f) => {
        ctx.save();
        ctx.globalAlpha = f.life;
        ctx.strokeStyle = f.color;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(f.x, f.y, 18 + (1 - f.life) * 26, 0, Math.PI * 2);
        ctx.stroke();
        ctx.restore();
      });

      // crosshair
      if (this.hover) {
        const i = Math.max(0, Math.min(bars.length - 1, Math.floor((this.hover.x - pad.l) / cw)));
        const b = bars[i];
        const x = X(i);
        ctx.strokeStyle = "rgba(0,240,255,.35)";
        ctx.setLineDash([3, 4]);
        ctx.beginPath(); ctx.moveTo(x, pad.t); ctx.lineTo(x, h - pad.b); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(pad.l, this.hover.y); ctx.lineTo(w - pad.r, this.hover.y); ctx.stroke();
        ctx.setLineDash([]);
        if (opts.onHover) opts.onHover(b, i + start, this.hover);
      }
      return { pad, X, Y, start, bars };
    }

    burst(x, y, color) {
      this.flash.push({ x, y, color, life: 1 });
    }
  }

  function lineChart(canvas, seriesList, opts = {}) {
    const { ctx, w, h } = size(canvas);
    ctx.clearRect(0, 0, w, h);
    const pad = { l: 48, r: 16, t: 16, b: 28 };
    const all = seriesList.flatMap((s) => s.data.map((d) => d.y));
    if (!all.length) return;
    const min = Math.min(...all), max = Math.max(...all);
    const span = max - min || 1;
    const n = Math.max(...seriesList.map((s) => s.data.length), 1);
    const X = (i) => pad.l + (i / Math.max(n - 1, 1)) * (w - pad.l - pad.r);
    const Y = (v) => pad.t + ((max - v) / span) * (h - pad.t - pad.b);
    nice(min, max, 4).forEach((v) => {
      const y = Y(v);
      ctx.strokeStyle = C.grid; ctx.beginPath(); ctx.moveTo(pad.l, y); ctx.lineTo(w - pad.r, y); ctx.stroke();
      ctx.fillStyle = C.text; ctx.font = "10px IBM Plex Mono"; ctx.textAlign = "right";
      ctx.fillText(v.toFixed(opts.digits || 0), pad.l - 6, y + 3);
    });
    seriesList.forEach((s) => {
      glowLine(ctx, () => {
        ctx.lineWidth = s.width || 1.8;
        ctx.beginPath();
        s.data.forEach((d, i) => (i ? ctx.lineTo(X(i), Y(d.y)) : ctx.moveTo(X(i), Y(d.y))));
        ctx.stroke();
      }, s.color, 12);
      if (s.fill) {
        ctx.beginPath();
        s.data.forEach((d, i) => (i ? ctx.lineTo(X(i), Y(d.y)) : ctx.moveTo(X(i), Y(d.y))));
        ctx.lineTo(X(s.data.length - 1), h - pad.b);
        ctx.lineTo(X(0), h - pad.b);
        ctx.closePath();
        ctx.fillStyle = s.fill;
        ctx.fill();
      }
    });
  }

  function heatmap(canvas, matrix, xLabels, yLabels) {
    const { ctx, w, h } = size(canvas);
    ctx.clearRect(0, 0, w, h);
    const pad = { l: 78, r: 16, t: 28, b: 18 };
    const cols = xLabels.length, rows = yLabels.length;
    const cw = (w - pad.l - pad.r) / cols;
    const ch = (h - pad.t - pad.b) / rows;
    ctx.font = "11px Outfit";
    ctx.fillStyle = C.text;
    ctx.textAlign = "center";
    xLabels.forEach((lb, i) => ctx.fillText(lb, pad.l + i * cw + cw / 2, 18));
    ctx.textAlign = "right";
    yLabels.forEach((lb, j) => ctx.fillText(lb, pad.l - 8, pad.t + j * ch + ch / 2 + 4));
    for (let j = 0; j < rows; j++) {
      for (let i = 0; i < cols; i++) {
        const cell = matrix[j][i];
        const v = cell ? cell.pf : 0;
        const t = Math.max(0, Math.min(1, (v - 0.8) / 1.2));
        const col = t < 0.5
          ? lerpCol([58, 16, 32], [245, 197, 66], t * 2)
          : lerpCol([245, 197, 66], [0, 255, 157], (t - 0.5) * 2);
        const x = pad.l + i * cw + 3, y = pad.t + j * ch + 3;
        ctx.fillStyle = `rgba(${col[0]},${col[1]},${col[2]},.88)`;
        roundRect(ctx, x, y, cw - 6, ch - 6, 8);
        ctx.fill();
        if (cell) {
          ctx.fillStyle = "#05060f";
          ctx.textAlign = "center";
          ctx.font = "700 12px IBM Plex Mono";
          ctx.fillText(v.toFixed(2), x + (cw - 6) / 2, y + (ch - 6) / 2 + 1);
          ctx.font = "9px IBM Plex Mono";
          ctx.fillText((cell.net >= 0 ? "+" : "") + Math.round(cell.net), x + (cw - 6) / 2, y + (ch - 6) / 2 + 14);
        }
      }
    }
  }

  function lerpCol(a, b, t) {
    return a.map((v, i) => Math.round(v + (b[i] - v) * t));
  }

  function roundRect(ctx, x, y, w, h, r) {
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
  }

  function spark(canvas, data, color) {
    const { ctx, w, h } = size(canvas);
    ctx.clearRect(0, 0, w, h);
    if (!data.length) return;
    const min = Math.min(...data), max = Math.max(...data);
    const span = max - min || 1;
    glowLine(ctx, () => {
      ctx.lineWidth = 1.6;
      ctx.beginPath();
      data.forEach((v, i) => {
        const x = (i / Math.max(data.length - 1, 1)) * w;
        const y = h - ((v - min) / span) * (h - 4) - 2;
        i ? ctx.lineTo(x, y) : ctx.moveTo(x, y);
      });
      ctx.stroke();
    }, color, 10);
  }

  g.AXChart = { PriceChart, lineChart, heatmap, spark, size };
})(window);
