---
name: nova-gravity-ea-builder
description: Reusable skill that builds a complete, production-grade adaptive MQL5 Expert Advisor (auto multi-asset: crypto/USDT/forex/metals/oil/indices/stocks, auto symbol & timeframe detection) with account-survival protection layer, plus its .set profiles, settings Excel workbook, interactive neon dashboard (live simulation + real Strategy Tester import, comparisons, costs, AI insights, workspaces, CSV/PNG export) and a single downloadable ZIP. Use when the user asks for an MT5 trading bot with a dashboard, Excel config, .set files, and a packaged download.
---

# NOVA GRAVITY EA BUILDER — reusable pipeline

## When to use
User request mentions: MT5/MQL5 expert advisor + "automated/AI", "works on all symbols/timeframes", dashboard/simulation, Excel settings, `.set` file, Strategy Tester reports, or a single ZIP download. Reuses this exact pipeline; produces a coherent package every time.

## Golden rules (from the project requirements — never violate)
1. **NO** martingale, grid, or averaging. One position per symbol.
2. **NO** 5th indicator on the entry signal (EMA+RSI+MACD+ADX only, plus optional HTF alignment & Bollinger touch).
3. **NO** complex news calendar before the weekend-close and regime filters work (approx blackout window is enough).
4. **NO** genetic optimization on gross profit. Keep the metric **PF × √N / maxDD** as the validation score.
5. If the user injects "account survival" fixes, implement in this priority order:
   Friday close/BE guard → QUIET wait + VOLATILE no-breakout → breakeven lock after partial → gap filter on gold/oil too → max-hold time stop → (then only) entry-quality improvements.
6. Never show "real" results before the user imports their own tester files — simulation must be clearly labeled.

## Pipeline steps

### 1) Requirements → input list
- Extract every setting the user mentioned into `input` declarations grouped by: General / Risk / Entry / Regime / Time-News / Weekend / Exit-Protection / Class-Adaptation.
- Always include the survival inputs: `InpFridayCutoffHour`, `InpFridayLeadMinutes`, `InpFridayAction`, `InpSundayBlockMinutes`, `InpDailyLossLimitPercent`, `InpMaxDailyTrades`, `InpGlobalDrawdownStopPercent`, `InpMaxHoldBars` (+ per-class), `InpServerGmtOffset`, `InpNewsFilter`, `InpMaxSpreadPoints`.

### 2) EA skeleton (single .mq5, `<Trade/Trade.mqh>` only)
- Unique enum members (prefix `NG_`) — mandatory on build 5200+ (no duplicates across enums, strict enum defaults, no duplicate identifiers in scope).
- Auto-detection: symbol from `_Symbol` (or `InpSymbolOverride` with `SymbolSelect`), TF from `_Period`, class via string classification (USDT/USDC → USDT · BTC/ETH/SOL... → CRYPTO · XAU/GOLD/SILVER → GOLD · USOIL/WTI/BRENT → OIL · US30/NAS100/DE40/SPX... → INDEX · .US/#... → STOCK · 6-letter → FOREX · else OTHER). Class drives: max-hold bars, weekend guard, news exemption, session rules.
- Indicators: EMA 21/55, RSI 14, MACD 12/26/9, ADX 14, ATR 14, BB 20/2. Entry = pullback touch of EMA21/55/BB-mid within 5 bars + close in trend direction + ADX≥22 + RSI side + MACD side + anti-chase (≤1.5 ATR from EMA21) + HTF alignment (EMA trend on TF×4).
- Regime engine on bar close only: ATR<0.75×median(120) → QUIET (no entry) · ATR>2.0×median → VOLATILE (range-fade at BB extremes only, no breakout) · else NORMAL.
- Exits/protection: ATR-based SL/TP (min RR), partial at 1R then **instant breakeven lock** (+0.10 ATR buffer), trail after 1.5 ATR, time stop per class (bars = classHold × 60/tfMin), optional reverse-signal exit, Friday guard (at cutoff−lead: close-all | breakeven | profit-close+BE-loss), gap filter `|O1−C2| > 1.5×ATR` applied to ALL classes, daily loss limit (close all + halt), global DD stop, spread filter (points or ATR fraction), news blackout 13–16 server hours (Fri +1h, crypto exempt), session filter with **server offset correction**.
- Sizing: risk % of balance (or fixed / % free margin); round by `SYMBOL_VOLUME_STEP` — never hard 2 decimals.
- Filling: try FOK → IOC → RETURN per `SYMBOL_FILLING_MODE`. Tester-safe (`MQL_TESTER` guard for autotrading checks). On-chart status panel via `OBJ_RECTANGLE_LABEL` + `OBJ_LABEL` (prefix `NG_PANEL_`, cleaned in `OnDeinit`).
- No `WebRequest`, no DLL, no external libs (works in Tester; survives broker restrictions).

### 3) .set profiles (generate — do not hand-write)
Use `generate_package.py` (in `tools/` next to this skill; also shipped in the package). It parses the .mq5 inputs and emits:
- `NovaGravity_AI_EA.set` (PRO defaults)
- `NovaGravity_AI_Pro_Conservative.set` (risk 0.5%, daily loss 2%, session on, ADX 25...)
- `NovaGravity_AI_Crypto_24-7.set` (news off, weekend guard off, hold 96)
`.set` format: `Name=value` lines, enums as their ordinal int, strings quoted, bools `true/false`.

### 4) Excel settings workbook (generate from same parser)
`generate_package.py` also writes `NovaGravity_AI_Settings.xlsx`: Overview · Full Inputs (all 85 + groups + Arabic explanations) · Risk & MM · Symbol Classes · Friday/Weekend · Presets · Runbook checklist · Changelog. Regenerate whenever the .mq5 inputs change — single source of truth.

### 5) Dashboard (single self-contained HTML, offline, RTL Arabic)
Structure (copy from `Dashboard/novagravity_dashboard.html`):
- Neon/glow dark theme, canvas particles, generated SVG logo, market tape for all 8 asset classes.
- **Live simulation** of the exact EA logic (same regime/entry/exit rules, seeded RNG, scenario select: mixed/quiet/volatile/trend/friday/news/spread), candle chart with EMA/BB overlays, hover tooltip with trade details (entry/exit/points/P&L/reason/partial), positions table, equity curve, live spread calculator (bid/ask, points, cost per lot, ATR cap).
- **Import tab**: drag&drop real MT5 `Strategy Tester` HTML reports (parse `<table>` rows: Ticket/Open Time/Type/Size/Item/Price/S/Close Time/Price/S/Commission/Swap/Profit/Balance) + CSV fallback. Everything marked "REAL" only after import — before that the sim badge stays visible.
- **Analysis tab**: metrics cards, time-aligned equity curves (daily alignment), hourly/weekday heatmap, full cost report (commission/swap/slippage per trade, % of gross profit), trades table.
- **Compare tab**: multi-report & multi-timeframe normalized curves (100 base), comparison table with the PF×√N/DD score, radar chart.
- **AI tab**: offline rule engine → actionable insights (PF, sample size, DD, cost drag, slippage, best/worst session hours, Friday losses, crypto class notes) + optional LLM endpoint (stored only in browser, sent only on click).
- **Workspaces tab**: save/load/export-import full workspace JSON (market state + reports + settings) so scenarios switch without re-importing files; autosave every 45s.
- **Exports**: CSV (sim trades, all imported trades, stats) + PNG (chart, stats report, comparison).

### 6) Documentation + packaging
- `Docs/MT5_Compatibility_Review.md`: build-by-build review (5100/5120/5200/5660 + 2026 notes), the strict-compiler rules applied, the design decisions (WebRequest-in-tester, filling modes, VOLUME_STEP, offset), warnings.
- `Docs` + `README.md` (Arabic, RTL) with install/run/report-extraction instructions.
- Logo: generate with an image model (neon N + orbital ring + candles), save `assets/logo_nova_gravity.png`.
- ZIP everything under a single `NovaGravity_AI_Package.zip` (folder layout mirrors `MQL5/...` so the user can drop `MQL5/Experts/NovaGravity` straight into `<MT5 data folder>`).
- Serve the Dashboard with `python3 -m http.server` (bind 0.0.0.0) for a live preview.

## Verification checklist (run before delivery)
- [ ] Brace/paren balance & unique identifiers check on the .mq5 (script or manual).
- [ ] `node` syntax check on the dashboard <script>; run a fake-DOM smoke test (boot + 400 sim steps + synthetic MT5 HTML parse).
- [ ] Regenerate .set + .xlsx after the last .mq5 edit.
- [ ] ZIP contains: .mq5, 3 .set, .xlsx, dashboard HTML, docs, logo, skill itself.
- [ ] No fake "real results" text before user import — badge enforces it.

## Files in this skill
- `SKILL.md` — this document
- `templates/` — EA input-template reference & .set template
- `generate_package.py` — the source-of-truth generator (also in package `tools/`)
