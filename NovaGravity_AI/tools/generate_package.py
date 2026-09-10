#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
NOVA GRAVITY AI - package generator
Parses the .mq5 source, extracts every input (type/name/default/comment),
then emits:
  1) .set profile files (MT5 import-ready)
  2) NovaGravity_AI_Settings.xlsx  (full settings workbook)

Run:  python3 generate_package.py
"""
import os, re, sys, datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EA   = os.path.join(ROOT, "MQL5", "Experts", "NovaGravity", "NovaGravity_AI_EA.mq5")
OUT  = ROOT

ENUM_MAP = {}
def load_enums(p):
    src = open(p, encoding="utf-8").read()
    for m in re.finditer(r'enum\s+(\w+)\s*\{([^}]*)\}', src):
        name = m.group(1)
        members = []
        for i, mm in enumerate(re.finditer(r'(\w+)(?:\s*=\s*(\d+))?', m.group(2))):
            idname = mm.group(1)
            if idname in ("enum", "input", "string", "int", "double", "bool", "long"):
                continue
            members.append((idname, int(mm.group(2)) if mm.group(2) else len(members)))
        ENUM_MAP[name] = members

def load_inputs(p):
    src = open(p, encoding="utf-8").read()
    rows = []
    pat = re.compile(r'^input\s+([\w ]+)\s+(\w+)\s*=\s*([^;]+);(.*)$', re.M)
    for m in pat.finditer(src):
        typ = m.group(1).strip()
        name = m.group(2)
        val = m.group(3).strip()
        cmt = m.group(4).split("//", 1)[1].strip() if "//" in m.group(4) else ""
        rows.append({"type": typ, "name": name, "default": val, "comment": cmt})
    return rows

def set_value(r):
    typ, val = r["type"], r["default"]
    if typ == "string":
        return '"' + val.strip('"') + '"'
    if typ == "bool":
        return "true" if val.lower() == "true" else "false"
    if typ.startswith("ENUM_"):
        members = ENUM_MAP.get(typ, [])
        for nm, idx in members:
            if nm == val:
                return str(idx)
        # ENUM_TIMEFRAMES special values
        tf = {"PERIOD_CURRENT": 0, "PERIOD_M1": 1, "PERIOD_M5": 5, "PERIOD_M15": 15,
              "PERIOD_M30": 30, "PERIOD_H1": 16385, "PERIOD_H4": 16388, "PERIOD_D1": 16408,
              "PERIOD_W1": 32769, "PERIOD_MN1": 49153}
        return str(tf.get(val, 0))
    return val

def render_set(rows, overrides, title):
    lines = [
        "; -----------------------------------------------------------------",
        ";  %s" % title,
        ";  NOVA GRAVITY AI  |  MetaTrader 5  |  Auto-Multi-Class EA v1.02",
        ";  Generated: %s" % datetime.date.today().isoformat(),
        ";  Import:  File > Open Data Folder > MQL5/Experts/NovaGravity/",
        ";          2) right-click the EA on the chart -> Properties -> Load",
        "; -----------------------------------------------------------------",
        "",
    ]
    for r in rows:
        val = overrides.get(r["name"], r["default"])
        v = set_value({**r, "default": val})
        lines.append("%s=%s" % (r["name"], v))
        if r["comment"]:
            pass
    lines.append("")
    return "\n".join(lines)

def write_set(path, rows, overrides, title):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(render_set(rows, overrides, title))
    print("  [set]  %s" % os.path.relpath(path, ROOT))

def fmt(v, t):
    if t == "double":
        return repr(float(v))
    return str(v)

def build_xlsx(path, rows):
    from openpyxl import Workbook
    from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
    from openpyxl.utils import get_column_letter

    wb = Workbook()
    HDR_FILL = PatternFill("solid", fgColor="12263A")
    HDR_FONT = Font(color="E8F6FF", bold=True, size=11)
    SUB_FILL = PatternFill("solid", fgColor="0E1B2E")
    SUB_FONT = Font(color="6FD3FF", bold=True, size=11)
    thin = Side(style="thin", color="24466B")
    BORDER = Border(left=thin, right=thin, top=thin, bottom=thin)
    WARN_FILL = PatternFill("solid", fgColor="3A1F1F")

    def sheet(title, headers, data, widths=None, title_note=None):
        ws = wb.create_sheet(title)
        col = 1
        for h in headers:
            c = ws.cell(1, col, h)
            c.fill, c.font, c.border = HDR_FILL, HDR_FONT, BORDER
            c.alignment = Alignment(horizontal="center", vertical="center")
            col += 1
        r = 2
        for row in data:
            col = 1
            for v in row:
                c = ws.cell(r, col, v)
                c.border = BORDER
                c.alignment = Alignment(vertical="top", wrap_text=(col <= 2))
                col += 1
            r += 1
        if widths:
            for i, w in enumerate(widths, start=1):
                ws.column_dimensions[get_column_letter(i)].width = w
        ws.freeze_panes = "A2"
        if title_note:
            ws.cell(r + 1, 1, title_note).font = Font(italic=True, color="88AACC")
        return ws

    # ---------- sheet 1: overview ----------
    ws = wb.active
    ws.title = "01 - Overview"
    ws.sheet_view.showGridLines = False
    ws.column_dimensions["A"].width = 34
    ws.column_dimensions["B"].width = 90
    data = [
        ("Bot Name", "NOVA GRAVITY AI"),
        ("Version", "1.02 (Pro + Engines + AI)"),
        ("Platform", "MetaTrader 5 (MQL5) - current builds (5100+, tested against build notes up to 5660)"),
        ("Instruments", "Crypto / USDT-linked / Forex / Gold & Metals / Oil & Energy / Indices / Stocks"),
        ("Timeframes", "ALL (M1..MN1) - auto-detected from the chart"),
        ("Auto-Detection", "Symbol class + timeframe are detected automatically when attached to any chart"),
        ("File to compile", "MQL5/Experts/NovaGravity/NovaGravity_AI_EA.mq5"),
        ("Preset set files", "NovaGravity_AI_EA.set (Pro), _Conservative, _Crypto_24-7"),
        ("Core logic", "Pullback continuation: EMA21/55 + RSI + MACD + ADX, HTF alignment, BB mid touch"),
        ("Regime engine", "QUIET=wait / NORMAL=trend / VOLATILE=range-fade only (no breakout)"),
        ("Protection layer", "Friday weekend guard, partial->breakeven, time-stop, gap filter, news blackout, spread cap, daily loss limit"),
        ("NO (by design)", "Martingale, grid, averaging, 5th indicator, complex news calendar, genetic optimization on gross profit"),
        ("Sizing", "Risk % of balance (or fixed / % free margin), volume rounded to broker VOLUME_STEP"),
        ("Validation metric", "PF x sqrt(trades) / maxDD (unchanged - kept as the reference objective)"),
        ("Disclaimer", "Trading involves risk. Test on demo before live; past performance does not guarantee future results."),
    ]
    r = 2
    for k, v in data:
        ws.cell(r, 1, k).font = Font(bold=True, color="6FD3FF")
        ws.cell(r, 1).fill = SUB_FILL
        ws.cell(r, 2, v).alignment = Alignment(wrap_text=True, vertical="top")
        r += 1

    # ---------- sheet 2: full inputs ----------
    headers = ["#", "Group", "Input name", "Type", "Default", "Arabic explanation", "Notes"]
    groups = []
    cur = "GENERAL"
    for i, r in enumerate(rows, start=1):
        # group from mq5 section markers handled below
        groups.append(cur)
    # parse group markers
    src = open(EA, encoding="utf-8").read()
    order = re.findall(r'input group "([^"]+)"', src)
    cur = None
    group_of = {}
    for m in re.finditer(r'input group "([^"]+)", src', src):
        pass
    # simpler: line-based
    cur_group = "GENERAL"
    for ln in src.split("\n"):
        mm = re.match(r'\s*input group "(.+)"', ln)
        if mm:
            cur_group = mm.group(1)
            continue
        mm2 = re.match(r'\s*input\s+([\w ]+)\s+(\w+)\s*=', ln)
        if mm2:
            group_of[mm2.group(2)] = cur_group

    data2 = []
    for i, r in enumerate(rows, start=1):
        data2.append([i, group_of.get(r["name"], "GENERAL"), r["name"], r["type"],
                      fmt(r["default"], r["type"]), r["comment"], ""])
    sheet("02 - Full Inputs", headers, data2, widths=[5, 26, 32, 18, 16, 52, 40])

    # ---------- sheet 3: risk table ----------
    risk = [
        ["Sizing mode", "RISK_PERCENT", "1.0% per trade - recommended for survival (never raise above 2%)"],
        ["Fixed lots", "0.01", "Used when mode = FIXED, or as fallback when tick data is missing"],
        ["Daily loss limit", "3.0%", "Closes all & halts until next day. THE key account-survival switch"],
        ["Max open positions", "1", "One position per symbol - no averaging/grid."],
        ["Max daily trades", "8", "Prevents over-trading; 0 = unlimited"],
        ["Global DD stop", "0.0", "Optional hard stop from peak equity (suggest 10-15% for prop firms)"],
        ["Volume rounding", "VOLUME_STEP", "Auto-detected per symbol (0.001 / 0.01 / 1.0 ...) - never hard 2 decimals"],
    ]
    sheet("03 - Risk & MM", ["Setting", "Default", "Why / recommendation"], risk,
          widths=[26, 20, 110])

    # ---------- sheet 4: classes ----------
    classes = [
        ["FOREX", "EURUSD GBPJPY AUDCAD...", "32 bars (H1)", "ON (13-16 server)", "OFF", "Yes"],
        ["GOLD/METAL", "XAUUSD XAGUSD GOLD", "28 bars (H1)", "ON", "OFF", "Yes"],
        ["ENERGY/OIL", "USOIL WTI BRENT NGAS", "28 bars (H1)", "ON", "OFF", "Yes"],
        ["INDEX", "US30 NAS100 DE40 SPX500", "24 bars (H1)", "ON", "OFF", "Yes"],
        ["STOCK", "AAPL.US TSLA.US #MSFT", "24 bars (H1)", "ON", "OFF", "Yes"],
        ["CRYPTO", "BTCUSD ETHUSD SOLUSD", "96 bars (H1)", "IGNORED (24/7)", "No", "Optional"],
        ["USDT-linked", "BTCUSDT ETHUSDT XRPUSDT...", "96 bars (H1)", "IGNORED (24/7)", "No", "Optional"],
        ["OTHER", "Any custom", "36 bars (H1)", "ON", "OFF", "Yes"],
    ]
    sheet("04 - Symbol Classes", ["Class", "Example symbols", "Max hold (H1-equivalent)",
                                   "News blackout", "Weekend guard", "Session filter"],
          classes, widths=[18, 42, 24, 26, 16, 16])

    # ---------- sheet 5: friday/weekend ----------
    fri = [
        ["InpFridayCutoffHour", "20", "Server hour after which NO new trades on Friday"],
        ["InpFridayLeadMinutes", "60", "Protection fires 1h before cutoff (19:00): close all / BE"],
        ["InpFridayAction", "CLOSE_ALL", "Most protective. Alternatives: BREAKEVEN, CLOSE_PROFIT_BE_LOSS"],
        ["InpSundayBlockMinutes", "120", "No new entries for first 2h after Sunday reopen (gap window)"],
        ["InpApplyGuardCrypto", "false", "Set true only if your crypto CFD broker also closes weekends"],
        ["Priority", "GOLD > INDICES > STOCKS > OIL > FOREX", "Metals/indices gap hardest - always guarded"],
    ]
    sheet("05 - Friday Weekend", ["Input", "Default", "Purpose"], fri, widths=[30, 22, 100])

    # ---------- sheet 6: presets ----------
    presets = [
        ["PRO (default)", "NovaGravity_AI_EA.set", "Risk 1%, daily loss 3%, partial at 1R -> BE, trail, time-stop, news ON, Friday CLOSE_ALL"],
        ["CONSERVATIVE", "NovaGravity_AI_Pro_Conservative.set", "Risk 0.5%, daily loss 2%, sessions ON, ADX 25, MaxHold tighter, trailing sooner"],
        ["CRYPTO 24/7", "NovaGravity_AI_Crypto_24-7.set", "Risk 1%, news OFF, weekend guard OFF, hold 96 bars, ATR filters adaptive"],
        ["IC Markets", "NovaGravity_AI_IC_Markets.set", "Tight spreads: filter 0.10 ATR, deviation 10, GMT+3, sessions ON"],
        ["Pepperstone", "NovaGravity_AI_Pepperstone.set", "Spread filter 0.12 ATR, deviation 15, GMT+3, sessions ON"],
        ["Exness", "NovaGravity_AI_Exness.set", "Spread filter 0.18 ATR, risk 0.7%, auto GMT offset, sessions ON"],
        ["PROP CHALLENGE", "NovaGravity_AI_Prop_Challenge.set", "Risk 0.5%, daily 4%, weekly 8%, global DD stop 10%, adaptive risk from 3% DD"],
    ]
    sheet("06 - Presets", ["Profile", "Set file", "Configuration"],
          presets, widths=[22, 34, 110])

    # ---------- sheet 7: runbook checklist ----------
    check = [
        ["1", "Copy NOVA folder into  MQL5/Experts/  (File > Open Data Folder)"],
        ["2", "Compile: MetaEditor (F7). Fix zero errors before attaching"],
        ["3", "Attach to chart -> Properties -> Inputs -> Load -> NovaGravity_AI_EA.set"],
        ["4", "Tester: choose symbol/TF/dates -> run 'Every tick based on real ticks' recommended"],
        ["5", "Verify on-chart panel: class, TF, regime, spread, session, positions"],
        ["6", "Check Experts log for INIT OK and class detection line"],
        ["7", "Demo 2-4 weeks BEFORE live. Never raise risk > 1-2% per trade"],
        ["8", "Export tester report (HTML) and import into the Dashboard for analysis"],
        ["9", "Check spread & commissions of your broker against the dashboard cost report"],
    ]
    sheet("07 - Runbook", ["#", "Action"], check, widths=[4, 130])

    # ---------- sheet 8: portfolio & journal ----------
    port = [
        ["InpPortfolioSharing", "true", "Shares day/week P/L across ALL charts running the EA via terminal global variables (cross-chart protection)"],
        ["InpWeeklyLossLimitPercent", "6.0", "Portfolio weekly loss limit - closes all + halts until Monday (0=off)"],
        ["InpAdaptiveRisk", "true", "Risk scales DOWN as equity drawdown grows (never martingale)"],
        ["InpRiskReductionStartDD", "5.0", "Drawdown % where risk reduction begins"],
        ["InpRiskReductionFloor", "0.25", "Minimum risk multiplier (25% of configured risk)"],
        ["InpRolloverGuard", "true", "Rollover window protection for negative-swap positions (gold/oil) - BE or close"],
        ["InpRolloverStart/End", "21 / 22", "Rollover window in server hours (wrap-safe)"],
        ["InpRolloverSwapThreshold", "-0.5", "Trigger when accumulated position swap < -0.5 USD"],
        ["InpRolloverAction", "BREAKEVEN", "Action: BE (default) or CLOSE"],
        ["InpJournalCSV", "true", "Writes MQL5/Files/NovaGravity_Journal.csv (imports into the dashboard)"],
        ["InpNotifyOnGuards", "false", "SendNotification push alerts on guard activations (needs MetaQuotes ID)"],
        ["OnTester()", "built-in", "Custom optimizer criterion = PF x sqrt(N) / maxDD% - select Custom criterion in the tester"],
    ]
    sheet("08 - Portfolio & Journal", ["Input", "Default", "Purpose"], port,
          widths=[30, 22, 100])

    # ---------- sheet 9: changelog ----------
    log = [
        ["v1.01", "2026-08-25",
         "Portfolio sharing (cross-chart day/week limits via terminal globals), weekly loss limit, adaptive risk scaling with drawdown, rollover/swap guard, EA trade journal CSV (MQL5/Files), OnTester custom criterion PF x sqrt(N)/DD, weekly server-offset re-detect (DST), push notifications, broker/prop preset profiles (IC/Pepperstone/Exness/Prop Challenge). Dashboard: Monte Carlo bootstrap, overfitting check, Sortino/Kelly/max-consecutive-losses."],
        ["v1.00", "2026-08-25",
         "Complete rebuild: auto symbol-class & timeframe detection; Friday weekend guard (close/BE 1h before cutoff); QUIET=wait & VOLATILE=range-only; partial -> immediate breakeven lock; per-class max-hold time stop; gap filter extended to gold/oil/all classes; news blackout (13-16 server, extended Friday, crypto exempt); server GMT offset auto-detect; VOLUME_STEP lot rounding; pullback EMA21/55 + BB mid entries with HTF alignment; anti-chase filter; daily loss limit; optional global DD stop; on-chart panel."],
    ]
    sheet("08 - Changelog", ["Version", "Date", "Summary"], log, widths=[10, 14, 130])

    wb.save(path)
    print("  [xlsx] %s" % os.path.relpath(path, ROOT))

if __name__ == "__main__":
    print("NOVA GRAVITY AI - package generator")
    load_enums(EA)
    rows = load_inputs(EA)
    print("  parsed %d inputs" % len(rows))

    # default PRO profile
    write_set(os.path.join(OUT, "MQL5", "Experts", "NovaGravity", "NovaGravity_AI_EA.set"),
              rows, {}, "NOVA GRAVITY AI - PRO profile (defaults)")

    # conservative profile
    cons = {
        "InpRiskPercent": "0.5", "InpDailyLossLimitPercent": "2.0", "InpMaxDailyTrades": "5",
        "InpSessionFilter": "true", "InpADXThreshold": "25.0", "InpMaxOpenPositions": "1",
        "InpTrailingStartATR": "1.0", "InpTrailingStepATR": "0.4", "InpMaxHoldBars": "0",
        "InpGlobalDrawdownStopPercent": "8.0",
    }
    write_set(os.path.join(OUT, "MQL5", "Experts", "NovaGravity", "NovaGravity_AI_Pro_Conservative.set"),
              rows, cons, "NOVA GRAVITY AI - CONSERVATIVE profile (capital protection)")

    # crypto 24/7 profile
    crypto = {
        "InpAllowCryptoNews": "true", "InpNewsFilter": "false", "InpApplyGuardCrypto": "false",
        "InpSessionFilter": "false", "InpMaxHoldCrypto": "96", "InpMaxHoldBars": "0",
        "InpRiskPercent": "1.0", "InpDailyLossLimitPercent": "4.0", "InpMaxDailyTrades": "10",
        "InpFridayAction": "NG_FRIDAY_CLOSE_ALL",
    }
    write_set(os.path.join(OUT, "MQL5", "Experts", "NovaGravity", "NovaGravity_AI_Crypto_24-7.set"),
              rows, crypto, "NOVA GRAVITY AI - CRYPTO 24/7 profile (weekend-open markets)")

    # broker / prop challenge profiles
    profiles = {
        "NovaGravity_AI_IC_Markets.set": ({
            "InpMaxSpreadATRFactor": "0.10", "InpRiskPercent": "1.0", "InpDeviationPoints": "10",
            "InpDailyLossLimitPercent": "3.0", "InpWeeklyLossLimitPercent": "6.0",
            "InpSessionFilter": "true", "InpNewsFilter": "true", "InpServerGmtOffset": "3"},
            "NOVA GRAVITY AI - IC Markets profile (tight spreads, GMT+3)"),
        "NovaGravity_AI_Pepperstone.set": ({
            "InpMaxSpreadATRFactor": "0.12", "InpRiskPercent": "1.0", "InpDeviationPoints": "15",
            "InpDailyLossLimitPercent": "3.0", "InpWeeklyLossLimitPercent": "6.0",
            "InpSessionFilter": "true", "InpNewsFilter": "true", "InpServerGmtOffset": "3"},
            "NOVA GRAVITY AI - Pepperstone profile (GMT+3)"),
        "NovaGravity_AI_Exness.set": ({
            "InpMaxSpreadATRFactor": "0.18", "InpRiskPercent": "0.7", "InpDeviationPoints": "25",
            "InpDailyLossLimitPercent": "3.0", "InpWeeklyLossLimitPercent": "6.0",
            "InpSessionFilter": "true", "InpNewsFilter": "true", "InpServerGmtOffset": "999"},
            "NOVA GRAVITY AI - Exness profile (wide spreads, auto offset)"),
        "NovaGravity_AI_Prop_Challenge.set": ({
            "InpRiskPercent": "0.5", "InpDailyLossLimitPercent": "4.0", "InpWeeklyLossLimitPercent": "8.0",
            "InpGlobalDrawdownStopPercent": "10.0", "InpMaxDailyTrades": "6", "InpSessionFilter": "true",
            "InpNewsFilter": "true", "InpFridayAction": "NG_FRIDAY_CLOSE_ALL",
            "InpAdaptiveRisk": "true", "InpRiskReductionStartDD": "3.0"},
            "NOVA GRAVITY AI - PROP CHALLENGE profile (daily 4% / weekly 8% / DD stop 10%)"),
    }
    for name, (ov, title) in profiles.items():
        write_set(os.path.join(OUT, "MQL5", "Experts", "NovaGravity", name), rows, ov, title)

    build_xlsx(os.path.join(OUT, "Excel", "NovaGravity_AI_Settings.xlsx"), rows)
    print("done.")
