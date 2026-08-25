#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Patch generate_package.py: v1.01, broker profiles, new Excel sheet, changelog."""
P = "generate_package.py"
s = open(P, encoding="utf-8").read()

# 1) version strings
s = s.replace("Auto-Multi-Class EA v1.00", "Auto-Multi-Class EA v1.01")
s = s.replace('("Version", "1.00 (Pro)")', '("Version", "1.01 (Pro + Portfolio)")')

# 2) broker/prop profiles before build_xlsx
anchor = '    build_xlsx(os.path.join(OUT, "Excel", "NovaGravity_AI_Settings.xlsx"), rows)'
addition = (
    '    # broker / prop challenge profiles\n'
    '    profiles = {\n'
    '        "NovaGravity_AI_IC_Markets.set": ({\n'
    '            "InpMaxSpreadATRFactor": "0.10", "InpRiskPercent": "1.0", "InpDeviationPoints": "10",\n'
    '            "InpDailyLossLimitPercent": "3.0", "InpWeeklyLossLimitPercent": "6.0",\n'
    '            "InpSessionFilter": "true", "InpNewsFilter": "true", "InpServerGmtOffset": "3"},\n'
    '            "NOVA GRAVITY AI - IC Markets profile (tight spreads, GMT+3)"),\n'
    '        "NovaGravity_AI_Pepperstone.set": ({\n'
    '            "InpMaxSpreadATRFactor": "0.12", "InpRiskPercent": "1.0", "InpDeviationPoints": "15",\n'
    '            "InpDailyLossLimitPercent": "3.0", "InpWeeklyLossLimitPercent": "6.0",\n'
    '            "InpSessionFilter": "true", "InpNewsFilter": "true", "InpServerGmtOffset": "3"},\n'
    '            "NOVA GRAVITY AI - Pepperstone profile (GMT+3)"),\n'
    '        "NovaGravity_AI_Exness.set": ({\n'
    '            "InpMaxSpreadATRFactor": "0.18", "InpRiskPercent": "0.7", "InpDeviationPoints": "25",\n'
    '            "InpDailyLossLimitPercent": "3.0", "InpWeeklyLossLimitPercent": "6.0",\n'
    '            "InpSessionFilter": "true", "InpNewsFilter": "true", "InpServerGmtOffset": "999"},\n'
    '            "NOVA GRAVITY AI - Exness profile (wide spreads, auto offset)"),\n'
    '        "NovaGravity_AI_Prop_Challenge.set": ({\n'
    '            "InpRiskPercent": "0.5", "InpDailyLossLimitPercent": "4.0", "InpWeeklyLossLimitPercent": "8.0",\n'
    '            "InpGlobalDrawdownStopPercent": "10.0", "InpMaxDailyTrades": "6", "InpSessionFilter": "true",\n'
    '            "InpNewsFilter": "true", "InpFridayAction": "NG_FRIDAY_CLOSE_ALL",\n'
    '            "InpAdaptiveRisk": "true", "InpRiskReductionStartDD": "3.0"},\n'
    '            "NOVA GRAVITY AI - PROP CHALLENGE profile (daily 4% / weekly 8% / DD stop 10%)"),\n'
    '    }\n'
    '    for name, (ov, title) in profiles.items():\n'
    '        write_set(os.path.join(OUT, "MQL5", "Experts", "NovaGravity", name), rows, ov, title)\n\n'
)
assert anchor in s
s = s.replace(anchor, addition + anchor, 1)

# 3) presets sheet rows
old_preset = '        ["CRYPTO 24/7", "NovaGravity_AI_Crypto_24-7.set", "Risk 1%, news OFF, weekend guard OFF, hold 96 bars, ATR filters adaptive"],\n    ]'
new_preset = (
    '        ["CRYPTO 24/7", "NovaGravity_AI_Crypto_24-7.set", "Risk 1%, news OFF, weekend guard OFF, hold 96 bars, ATR filters adaptive"],\n'
    '        ["IC Markets", "NovaGravity_AI_IC_Markets.set", "Tight spreads: filter 0.10 ATR, deviation 10, GMT+3, sessions ON"],\n'
    '        ["Pepperstone", "NovaGravity_AI_Pepperstone.set", "Spread filter 0.12 ATR, deviation 15, GMT+3, sessions ON"],\n'
    '        ["Exness", "NovaGravity_AI_Exness.set", "Spread filter 0.18 ATR, risk 0.7%, auto GMT offset, sessions ON"],\n'
    '        ["PROP CHALLENGE", "NovaGravity_AI_Prop_Challenge.set", "Risk 0.5%, daily 4%, weekly 8%, global DD stop 10%, adaptive risk from 3% DD"],\n'
    '    ]'
)
assert old_preset in s
s = s.replace(old_preset, new_preset, 1)

# 4) new sheet before changelog + v1.01 row
old_ch = '    # ---------- sheet 8: changelog ----------\n    log = [\n        ["v1.00", "2026-08-25",'
new_ch = (
    '    # ---------- sheet 8: portfolio & journal ----------\n'
    '    port = [\n'
    '        ["InpPortfolioSharing", "true", "Shares day/week P/L across ALL charts running the EA via terminal global variables (cross-chart protection)"],\n'
    '        ["InpWeeklyLossLimitPercent", "6.0", "Portfolio weekly loss limit - closes all + halts until Monday (0=off)"],\n'
    '        ["InpAdaptiveRisk", "true", "Risk scales DOWN as equity drawdown grows (never martingale)"],\n'
    '        ["InpRiskReductionStartDD", "5.0", "Drawdown % where risk reduction begins"],\n'
    '        ["InpRiskReductionFloor", "0.25", "Minimum risk multiplier (25% of configured risk)"],\n'
    '        ["InpRolloverGuard", "true", "Rollover window protection for negative-swap positions (gold/oil) - BE or close"],\n'
    '        ["InpRolloverStart/End", "21 / 22", "Rollover window in server hours (wrap-safe)"],\n'
    '        ["InpRolloverSwapThreshold", "-0.5", "Trigger when accumulated position swap < -0.5 USD"],\n'
    '        ["InpRolloverAction", "BREAKEVEN", "Action: BE (default) or CLOSE"],\n'
    '        ["InpJournalCSV", "true", "Writes MQL5/Files/NovaGravity_Journal.csv (imports into the dashboard)"],\n'
    '        ["InpNotifyOnGuards", "false", "SendNotification push alerts on guard activations (needs MetaQuotes ID)"],\n'
    '        ["OnTester()", "built-in", "Custom optimizer criterion = PF x sqrt(N) / maxDD% - select Custom criterion in the tester"],\n'
    '    ]\n'
    '    sheet("08 - Portfolio & Journal", ["Input", "Default", "Purpose"], port,\n'
    '          widths=[30, 22, 100])\n\n'
    "    # ---------- sheet 9: changelog ----------\n"
    '    log = [\n'
    '        ["v1.01", "2026-08-25",\n'
    '         "Portfolio sharing (cross-chart day/week limits via terminal globals), weekly loss limit, adaptive risk scaling with drawdown, rollover/swap guard, EA trade journal CSV (MQL5/Files), OnTester custom criterion PF x sqrt(N)/DD, weekly server-offset re-detect (DST), push notifications, broker/prop preset profiles (IC/Pepperstone/Exness/Prop Challenge). Dashboard: Monte Carlo bootstrap, overfitting check, Sortino/Kelly/max-consecutive-losses."],\n'
    '        ["v1.00", "2026-08-25",'
)
assert old_ch in s
s = s.replace(old_ch, new_ch, 1)

open(P, "w", encoding="utf-8").write(s)
print("generate_package.py patched OK")
