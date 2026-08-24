---
name: aetherion-mt5-ea
description: Rebuild a multi-asset MetaTrader 5 Expert Advisor with auto symbol/timeframe detection, SET/Excel presets, a live glowing simulator, real Strategy Tester ingest (no fabricated results), cost/slippage analytics, workspace save/load, and rule-based AI recommendations. Use when the user asks for an MT5 bot, MQL5 EA, Strategy Tester dashboard, or a reusable trading-lab workflow.
---

# AETHERION MT5 EA + Lab — reusable skill

Use this skill to recreate the **entire pipeline** that produced AETHERION: branded multi-asset EA, broker-safe execution, presets, interactive deck, and an honest tester lab.

## Non-negotiables

1. **Auto-detect** `_Symbol` and `_Period` the moment the EA is dropped on a chart. Never hard-code one pair.
2. **Every asset class**: Forex, Crypto, every `USDT/USDC` pair, metals, energy, indices, stocks. Classify from the symbol name **and** `SYMBOL_TRADE_CALC_MODE`.
3. **Never invent live results.** The simulator may animate how the engine *behaves*. Infographic, PF, costs, heatmap and AI stay **empty** until the user imports real Strategy Tester HTM/CSV.
4. **Filling is per-symbol, per-send.** Read `SYMBOL_FILLING_MODE` + `SYMBOL_TRADE_EXEMODE`. Market execution must not use `ORDER_FILLING_RETURN`. Cycle FOK → IOC → RETURN on `TRADE_RETCODE_INVALID_FILL` (10030).
5. **Normalize everything**: lot (`VOLUME_MIN/STEP/MAX/LIMIT`), price (`TICK_SIZE`), stops (`STOPS_LEVEL` / `FREEZE_LEVEL`, minimum 2 points if broker reports 0).
6. **No martingale.** Risk % of equity, daily loss halt, max DD flatten.
7. Brand it. New name, new mark, bilingual HUD (AR/EN).

## Folder contract

```
<name>/
  MQL5/Experts/<Name>/   # .mq5 + engine.mqh + panel.mqh (same folder)
  Presets/*.set          # MT5 Inputs → Load
  Settings/*.xlsx + .csv # every input, every preset, warnings
  Tester/                # optional sample HTM layout — never auto-shown as results
  simulator/             # live deck, binds 0.0.0.0
  skill/SKILL.md         # this playbook
  docs/WARNINGS.md
```

## MQL5 engine (must compile on MT5 Build 4000+)

Inputs grouped: Identity, Auto detect, Strategy, EMA/RSI/MACD/ADX/BB/ATR, Risk, Spread, Exits, Sessions, Asset profiles, HUD.

On init:

- Resolve symbol/TF (`force` override only if non-empty).
- `SymbolSelect`, abort if `SYMBOL_TRADE_MODE_DISABLED`.
- Detect asset: `USDT` substring → USDT 24/7; crypto token list; metals; energy; indices; else calc-mode / 6-letter FX. Strip only trailing micro `M` / MICRO / PRO / ECN / RAW — never `StringReplace` every `M` (breaks AMZN / MSFT / MATIC).
- Detect filling (Instant/Request → IOC|FOK|RETURN; Market → IOC|FOK only; Exchange → IOC|FOK|RETURN).
- Create indicator handles on **that** symbol/TF; `IndicatorRelease` in deinit.
- Prefix all objects `AE_<magic>_` and delete only those.

On tick:

- New-bar option (closed bar, no repaint). Optional `confirmBars` same-color closed bars.
- Higher-TF EMA filter (`useHTF`) — M5→M15, M15→H1, H1→H4, H4→D1.
- Session filter **off** for crypto/USDT; Friday cutoff + Monday delay for FX/indices/stocks.
- Rollover pause 23:50–00:20 server time (not crypto/USDT).
- Spread gate: auto cap by asset **or** `spread > ATR × k`, plus `spreadStableBars` consecutive OK bars.
- Pause after `lossStreakMax` losses for `lossStreakBars`.
- Signal = confluence (trend / range / breakout) chosen by ADX regime when strategy = Auto.
- Size lots from risk % / tick value; cap by free margin 60%.
- Manage BE, ATR trail, partial at R-multiple, time-exit.
- Draw live SL/TP/open + arrows.
- `OnTester` score = `PF × √N × (profit?1:0.25) / DD%` — never optimize raw profit.

## Presets + Excel

Generate `.set` in MT5 tester form:

```
InpName=value||start||step||stop||Y|N
```

Ship at least: Default, Conservative, Aggressive, Crypto/USDT, Forex, Gold, Scalp.

Excel sheets: All Parameters, Presets, Asset Profiles, Optimization ranges, Warnings, Install.

Crypto profile: risk × 0.70, ATR SL 2.4, 24/7, wide spread cap.  
Gold: ATR SL 2.2 + news window.  
Indices/stocks: skip opening gap > 1.5 ATR.

## Interactive deck

- Client-side OHLC **only** to show the bot moving. Label every HUD number `SIM`.
- Universe must include majors, crosses, BTC/ETH/SOL ± USD/USDT, XAU/XAG, USOIL/UKOIL, US30/US500/NAS100/GER40, AAPL/TSLA/NVDA…
- Import **real** MT5 reports: HTML (`Total Net Profit`, deals table with Commission/Swap) and CSV (flexible headers). Multiple files accumulate.
- Time-align equity curves onto one UTC axis before overlay.
- Cost report: commission, swap, slippage, cost/gross %, per-symbol table. If columns missing, say so — do not invent.
- Hover on a marker: ticket, in/out time & price, SL/TP, lot, P/L, comm/swap/slip, hold minutes, comment.
- Workspace JSON + `localStorage` slots: UI state + imported library. Switching scenarios must **not** require re-import.
- AI = deterministic diagnostics on **imported** stats only (PF, DD, WR vs PF, cost ratio, losing UTC hour, sample size, crypto DD). Each card is an actionable input change (`InpRiskPercent`, preset file, session filter…).
- Export CSV/PNG of *whatever is on screen* (imported if present, otherwise clearly marked SIM).
- Bind preview server to `0.0.0.0`. No localhost API calls from the page.

## Honest empty state

Until `library.length > 0`:

- Hide infographic, cost panel, AI, heatmap.
- Show a gate: “no realistic results before your files”.
- Do **not** fetch bundled `report_*.json` into those panels.

## Warnings to keep in the product

Demo first · no martingale · real ticks in tester · filling auto · invalid stops 10016 · lot/margin · hedging vs netting · crypto weekend `TRADE_MODE` · gaps/news · Algo Trading button · no curve-fit · not financial advice.

## Ship checklist

- [ ] EA compiles 0 errors with includes in the same folder
- [ ] Drop on BTCUSDT M15, XAUUSD H1, EURUSD M5, US30 H4, AAPL — HUD shows the right asset class
- [ ] Simulator opens with SIM-only numbers and a closed lab gate
- [ ] Dropping a real `Report_*.htm` unlocks costs + AI + aligned curves
- [ ] Saving a workspace and reloading restores files + settings
- [ ] Hovering a trade marker shows entry/exit/P/L
- [ ] SET files load in MT5 Inputs without missing keys
