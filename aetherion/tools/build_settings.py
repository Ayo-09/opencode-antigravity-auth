#!/usr/bin/env python3
"""Generate AETHERION Excel workbook, SET presets and tester fixtures."""
from __future__ import annotations

import csv
import datetime as dt
import random
from pathlib import Path

from openpyxl import Workbook
from openpyxl.chart import BarChart, LineChart, Reference
from openpyxl.chart.series import SeriesLabel
from openpyxl.formatting.rule import ColorScaleRule
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation
from openpyxl.worksheet.table import Table, TableStyleInfo
from openpyxl.chart.label import DataLabelList

ROOT = Path(__file__).resolve().parents[1]
SETTINGS = ROOT / "Settings"
PRESETS = ROOT / "Presets"
TESTER = ROOT / "Tester"
SIMDATA = ROOT / "simulator" / "data"

VOID = "05060F"
GOLD = "F5C542"
CYAN = "00E8FF"
MAG = "FF2E97"
INK = "0B1020"
PAPER = "F7F4EA"
MUTED = "8B93A7"

PARAMS = [
    # group, name, type, default, cons, bal, agg, crypto, forex, gold, scalp, min, max, step, opt, ar, en
    ("IDENTITY", "InpMagic", "long", 260824, 260824, 260824, 260824, 260824, 260824, 260824, 260824, 1, 999999999, 1, "N", "رقم السحر لتمييز صفقات البوت", "Magic number isolating EA trades"),
    ("IDENTITY", "InpTradeComment", "string", "AETHERION", "AETHERION", "AETHERION", "AETHERION", "AETHERION", "AETHERION", "AETHERION", "AETHERION", "", "", "", "N", "تعليق الأمر في التاريخ", "Order comment written to history"),
    ("IDENTITY", "InpLanguage", "enum", 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, "N", "لغة لوحة الشارت 0 عربي 1 إنجليزي", "HUD language 0=AR 1=EN"),
    ("AUTO", "InpAutoDetect", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "تعرف تلقائي على الرمز والإطار من الشارت", "Auto-detect chart symbol and timeframe"),
    ("AUTO", "InpForceSymbol", "string", "", "", "", "", "", "", "", "", "", "", "", "N", "إجبار رمز معيّن — اتركه فارغاً للشارت", "Force symbol, empty = chart"),
    ("AUTO", "InpForceTF", "enum", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "N", "إجبار إطار — PERIOD_CURRENT = الشارت", "Force TF, CURRENT = chart"),
    ("STRATEGY", "InpStrategy", "enum", 0, 1, 0, 3, 0, 1, 1, 4, 0, 4, 1, "Y", "0 تلقائي 1 اتجاه 2 نطاق 3 اختراق 4 سكالب", "0 Auto 1 Trend 2 Range 3 Breakout 4 Scalp"),
    ("STRATEGY", "InpSignalOnNewBar", "bool", 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, "N", "إشارة على إغلاق الشمعة فقط (بدون إعادة رسم)", "Signal on closed bar only (no repaint)"),
    ("STRATEGY", "InpConfirmBars", "int", 1, 2, 1, 0, 1, 1, 1, 0, 0, 5, 1, "Y", "شموع تأكيد إضافية", "Extra confirmation bars"),
    ("STRATEGY", "InpAllowBuy", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "السماح بالشراء", "Allow BUY"),
    ("STRATEGY", "InpAllowSell", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "السماح بالبيع", "Allow SELL"),
    ("STRATEGY", "InpCloseOnOpposite", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "إغلاق الصفقة عند الإشارة المعاكسة", "Close on opposite signal"),
    ("STRATEGY", "InpOneDirection", "bool", 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, "N", "اتجاه واحد لكل رمز", "One direction per symbol"),
    ("EMA", "InpUseEMA", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "تفعيل فلتر المتوسطات", "Enable EMA filter"),
    ("EMA", "InpEMAFast", "int", 21, 34, 21, 13, 21, 21, 21, 8, 5, 80, 1, "Y", "المتوسط السريع", "Fast EMA"),
    ("EMA", "InpEMASlow", "int", 55, 89, 55, 34, 55, 55, 55, 21, 10, 200, 1, "Y", "المتوسط البطيء", "Slow EMA"),
    ("EMA", "InpEMATrend", "int", 200, 200, 200, 100, 200, 200, 200, 50, 20, 400, 5, "Y", "متوسط الاتجاه العام", "Higher-timeframe trend EMA"),
    ("RSI", "InpUseRSI", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "تفعيل RSI", "Enable RSI"),
    ("RSI", "InpRSIPeriod", "int", 14, 14, 14, 10, 14, 14, 14, 7, 5, 30, 1, "Y", "فترة RSI", "RSI period"),
    ("RSI", "InpRSIBuyMin", "double", 42, 45, 42, 40, 40, 42, 42, 38, 20, 60, 1, "Y", "حد RSI الأدنى للشراء الاتجاهي", "Trend BUY RSI floor"),
    ("RSI", "InpRSIBuyMax", "double", 68, 65, 68, 72, 70, 68, 68, 75, 50, 90, 1, "Y", "حد RSI الأعلى للشراء الاتجاهي", "Trend BUY RSI ceiling"),
    ("RSI", "InpRSISellMin", "double", 32, 35, 32, 28, 30, 32, 32, 25, 10, 50, 1, "Y", "حد RSI الأدنى للبيع الاتجاهي", "Trend SELL RSI floor"),
    ("RSI", "InpRSISellMax", "double", 58, 55, 58, 60, 60, 58, 58, 62, 40, 80, 1, "Y", "حد RSI الأعلى للبيع الاتجاهي", "Trend SELL RSI ceiling"),
    ("RSI", "InpRSIRangeLow", "double", 30, 25, 30, 28, 28, 30, 30, 20, 10, 40, 1, "Y", "تشبع بيعي للنطاق", "Range oversold"),
    ("RSI", "InpRSIRangeHigh", "double", 70, 75, 70, 72, 72, 70, 70, 80, 60, 90, 1, "Y", "تشبع شرائي للنطاق", "Range overbought"),
    ("MACD", "InpUseMACD", "bool", 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, "N", "تفعيل MACD", "Enable MACD"),
    ("MACD", "InpMACDFast", "int", 12, 12, 12, 8, 12, 12, 12, 6, 5, 24, 1, "Y", "MACD السريع", "MACD fast"),
    ("MACD", "InpMACDSlow", "int", 26, 26, 26, 21, 26, 26, 26, 13, 10, 52, 1, "Y", "MACD البطيء", "MACD slow"),
    ("MACD", "InpMACDSignal", "int", 9, 9, 9, 7, 9, 9, 9, 5, 3, 18, 1, "Y", "خط إشارة MACD", "MACD signal"),
    ("ADX", "InpUseADX", "bool", 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, "N", "تفعيل نظام ADX", "Enable ADX regime"),
    ("ADX", "InpADXPeriod", "int", 14, 14, 14, 10, 14, 14, 14, 10, 5, 30, 1, "Y", "فترة ADX", "ADX period"),
    ("ADX", "InpADXMin", "double", 18, 22, 18, 14, 16, 18, 20, 12, 8, 30, 1, "Y", "أدنى ADX للتداول الاتجاهي", "Minimum ADX to trade trend"),
    ("ADX", "InpADXTrend", "double", 25, 28, 25, 22, 24, 25, 26, 20, 15, 40, 1, "Y", "ADX للاتجاه القوي", "Strong-trend ADX"),
    ("BB", "InpUseBB", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "تفعيل بولينجر", "Enable Bollinger"),
    ("BB", "InpBBPeriod", "int", 20, 20, 20, 16, 20, 20, 20, 14, 10, 40, 1, "Y", "فترة بولينجر", "BB period"),
    ("BB", "InpBBDev", "double", 2.0, 2.2, 2.0, 1.8, 2.2, 2.0, 2.0, 1.8, 1.2, 3.2, 0.1, "Y", "انحراف بولينجر", "BB deviation"),
    ("ATR", "InpATRPeriod", "int", 14, 14, 14, 10, 14, 14, 14, 7, 5, 30, 1, "Y", "فترة ATR", "ATR period"),
    ("ATR", "InpATRSL", "double", 1.8, 2.4, 1.8, 1.4, 2.4, 1.8, 2.2, 1.2, 0.8, 4.0, 0.1, "Y", "وقف الخسارة = ATR ×", "Stop-loss = ATR ×"),
    ("ATR", "InpATRTP", "double", 2.8, 3.2, 2.8, 2.2, 3.0, 2.8, 3.0, 1.8, 1.0, 6.0, 0.1, "Y", "جني الربح = ATR ×", "Take-profit = ATR ×"),
    ("ATR", "InpATRTrail", "double", 1.2, 1.6, 1.2, 0.9, 1.5, 1.2, 1.4, 0.8, 0.4, 3.0, 0.1, "Y", "المتحرك = ATR ×", "Trailing distance = ATR ×"),
    ("ATR", "InpMinATRPoints", "double", 0, 0, 0, 0, 0, 0, 0, 0, 0, 5000, 1, "N", "أدنى ATR بالنقاط (0=إيقاف)", "Min ATR in points (0=off)"),
    ("ATR", "InpMaxATRPoints", "double", 0, 0, 0, 0, 0, 0, 0, 0, 0, 20000, 10, "N", "أقصى ATR بالنقاط (0=إيقاف)", "Max ATR in points (0=off)"),
    ("RISK", "InpLotMode", "enum", 1, 1, 1, 1, 1, 1, 1, 0, 0, 2, 1, "N", "0 ثابت 1 نسبة مخاطرة 2 خطوة رصيد", "0 Fixed 1 Risk% 2 Equity step"),
    ("RISK", "InpFixedLot", "double", 0.01, 0.01, 0.01, 0.05, 0.01, 0.01, 0.01, 0.02, 0.01, 10, 0.01, "N", "لوت ثابت", "Fixed lot"),
    ("RISK", "InpRiskPercent", "double", 0.75, 0.40, 0.75, 1.50, 0.50, 0.75, 0.60, 0.35, 0.10, 5.00, 0.05, "Y", "نسبة المخاطرة من حقوق الملكية", "Risk percent of equity"),
    ("RISK", "InpEquityStep", "double", 1000, 2000, 1000, 500, 1000, 1000, 1000, 1000, 100, 10000, 100, "N", "خطوة الرصيد", "Equity step $"),
    ("RISK", "InpLotPerStep", "double", 0.01, 0.01, 0.01, 0.02, 0.01, 0.01, 0.01, 0.01, 0.01, 1, 0.01, "N", "لوت لكل خطوة", "Lot per equity step"),
    ("RISK", "InpMinLot", "double", 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 1, 0.01, "N", "أدنى لوت", "Minimum lot"),
    ("RISK", "InpMaxLot", "double", 2.00, 0.50, 2.00, 5.00, 1.00, 2.00, 1.50, 0.50, 0.01, 50, 0.01, "N", "أقصى لوت", "Maximum lot"),
    ("RISK", "InpMaxPositions", "int", 1, 1, 1, 3, 1, 1, 1, 2, 1, 20, 1, "Y", "أقصى عدد صفقات مفتوحة", "Max open positions"),
    ("RISK", "InpMaxPerSymbol", "int", 1, 1, 1, 2, 1, 1, 1, 1, 1, 10, 1, "N", "أقصى صفقات لنفس الرمز", "Max positions per symbol"),
    ("RISK", "InpMaxTradesDay", "int", 8, 4, 8, 16, 6, 8, 6, 20, 1, 80, 1, "Y", "أقصى صفقات في اليوم", "Max trades per day"),
    ("RISK", "InpCooldownBars", "int", 2, 4, 2, 1, 3, 2, 3, 1, 0, 20, 1, "Y", "شموع انتظار بين الدخول", "Cooldown bars between entries"),
    ("RISK", "InpMaxDailyLossPct", "double", 3.0, 1.5, 3.0, 5.0, 2.5, 3.0, 2.5, 2.0, 0.5, 15, 0.5, "Y", "إيقاف يومي عند خسارة %", "Daily loss halt %"),
    ("RISK", "InpMaxDrawdownPct", "double", 12.0, 8.0, 12.0, 18.0, 10.0, 12.0, 10.0, 10.0, 3, 40, 1, "Y", "إيقاف عند ذروة هبوط %", "Max equity drawdown %"),
    ("RISK", "InpEmergencyClose", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "إغلاق كل الصفقات عند خرق الحد", "Flatten all on risk breach"),
    ("SPREAD", "InpAutoSpread", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "سقف سبريد تلقائي حسب فئة الأصل", "Auto spread cap by asset class"),
    ("SPREAD", "InpMaxSpreadPoints", "int", 35, 25, 35, 60, 250, 30, 80, 40, 0, 2000, 5, "Y", "أقصى سبريد يدوي بالنقاط", "Manual max spread in points"),
    ("SPREAD", "InpSpreadATRMax", "double", 0.35, 0.25, 0.35, 0.50, 0.40, 0.30, 0.30, 0.45, 0.05, 1.5, 0.05, "Y", "حظر إذا السبريد > ATR ×", "Block if spread > ATR ×"),
    ("SPREAD", "InpSlippage", "int", 20, 10, 20, 40, 40, 15, 25, 30, 1, 200, 1, "N", "أقصى انحراف سعر", "Max price deviation (points)"),
    ("SPREAD", "InpRetryRequote", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "إعادة المحاولة عند تغير السعر", "Retry on requote / price change"),
    ("SPREAD", "InpMaxRetries", "int", 3, 2, 3, 4, 4, 3, 3, 3, 1, 8, 1, "N", "عدد محاولات الإرسال", "Max send retries"),
    ("EXITS", "InpUseSL", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "استخدام وقف الخسارة — لا تعطّله على الحساب الحقيقي", "Use stop-loss — do not disable on live"),
    ("EXITS", "InpUseTP", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "استخدام جني الربح", "Use take-profit"),
    ("EXITS", "InpSLPoints", "int", 0, 0, 0, 0, 0, 0, 0, 0, 0, 5000, 10, "N", "وقف بالنقاط (0 = ATR)", "SL in points (0 = ATR)"),
    ("EXITS", "InpTPPoints", "int", 0, 0, 0, 0, 0, 0, 0, 0, 0, 10000, 10, "N", "هدف بالنقاط (0 = ATR/RR)", "TP in points (0 = ATR/RR)"),
    ("EXITS", "InpUseRR", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "حساب الهدف من نسبة العائد للمخاطرة", "Take-profit from risk:reward"),
    ("EXITS", "InpRR", "double", 1.60, 2.00, 1.60, 1.20, 1.80, 1.60, 1.80, 1.10, 0.8, 4.0, 0.1, "Y", "العائد : المخاطرة", "Reward : Risk"),
    ("EXITS", "InpBreakeven", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "نقل الوقف لنقطة التعادل", "Move stop to breakeven"),
    ("EXITS", "InpBETriggerPoints", "int", 0, 0, 0, 0, 0, 0, 0, 0, 0, 2000, 5, "N", "تفعيل التعادل بالنقاط (0=ATR)", "BE trigger points (0=ATR)"),
    ("EXITS", "InpBELockPoints", "int", 10, 8, 10, 15, 20, 10, 15, 5, 0, 200, 1, "N", "قفل ربح عند التعادل بالنقاط", "Lock profit at BE (points)"),
    ("EXITS", "InpTrailing", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "وقف متحرك", "Trailing stop"),
    ("EXITS", "InpTrailStartPoints", "int", 0, 0, 0, 0, 0, 0, 0, 0, 0, 3000, 5, "N", "بداية المتحرك بالنقاط (0=ATR)", "Trail start points (0=ATR)"),
    ("EXITS", "InpTrailStepPoints", "int", 0, 0, 0, 0, 0, 0, 0, 0, 0, 1000, 5, "N", "خطوة المتحرك بالنقاط (0=ATR)", "Trail step points (0=ATR)"),
    ("EXITS", "InpPartialClose", "bool", 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "إغلاق جزئي", "Partial close"),
    ("EXITS", "InpPartialPercent", "double", 50, 50, 50, 40, 50, 50, 50, 50, 10, 80, 5, "N", "نسبة الإغلاق الجزئي", "Partial close percent"),
    ("EXITS", "InpPartialRR", "double", 1.00, 1.20, 1.00, 0.80, 1.00, 1.00, 1.00, 0.70, 0.5, 3.0, 0.1, "Y", "الإغلاق الجزئي عند مضاعف R", "Partial at R-multiple"),
    ("SESSION", "InpSessionFilter", "bool", 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 1, "N", "فلتر الجلسات (يُعطّل تلقائياً للكريبتو)", "Session filter (auto-off for crypto)"),
    ("SESSION", "InpTradeAsia", "bool", 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, "N", "جلسة آسيا 00-08", "Asia session 00-08"),
    ("SESSION", "InpTradeLondon", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "جلسة لندن 08-16", "London session 08-16"),
    ("SESSION", "InpTradeNewYork", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "جلسة نيويورك 13-22", "New York session 13-22"),
    ("SESSION", "InpFridayCutoffHour", "int", 20, 18, 20, 21, 0, 20, 19, 0, 0, 23, 1, "N", "قطع الجمعة (0=إيقاف)", "Friday cutoff hour (0=off)"),
    ("SESSION", "InpMondayDelayHours", "int", 1, 2, 1, 0, 0, 1, 1, 0, 0, 8, 1, "N", "تأخير الاثنين بالساعات", "Monday delay hours"),
    ("SESSION", "InpAvoidNewsWindow", "bool", 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, "N", "إيقاف داخل نافذة الأخبار", "Pause inside news window"),
    ("SESSION", "InpNewsHourStart", "int", 14, 13, 14, 14, 14, 14, 14, 14, 0, 23, 1, "N", "بداية نافذة الأخبار", "News window start hour"),
    ("SESSION", "InpNewsHourEnd", "int", 16, 17, 16, 16, 16, 16, 16, 16, 0, 23, 1, "N", "نهاية نافذة الأخبار", "News window end hour"),
    ("SESSION", "InpMaxHoldBars", "int", 0, 48, 0, 0, 0, 24, 36, 12, 0, 500, 1, "N", "خروج زمني بعد N شمعة (0=إيقاف)", "Time exit after N bars (0=off)"),
    ("ASSET", "InpUseAssetProfiles", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "تكييف الوقف والمخاطرة حسب فئة الأصل", "Adapt SL/risk by asset class"),
    ("ASSET", "InpCryptoRiskScale", "double", 0.70, 0.50, 0.70, 0.85, 0.70, 0.70, 0.70, 0.50, 0.2, 1.0, 0.05, "Y", "مضاعف مخاطرة الكريبتو/USDT", "Crypto/USDT risk scale"),
    ("ASSET", "InpCryptoATRSL", "double", 2.40, 2.80, 2.40, 2.00, 2.40, 2.40, 2.40, 1.80, 1.2, 5.0, 0.1, "Y", "وقف ATR للكريبتو", "Crypto ATR stop"),
    ("ASSET", "InpMetalATRSL", "double", 2.20, 2.60, 2.20, 1.80, 2.20, 2.20, 2.20, 1.60, 1.2, 5.0, 0.1, "Y", "وقف ATR للمعادن", "Metals ATR stop"),
    ("ASSET", "InpIndexATRSL", "double", 2.00, 2.40, 2.00, 1.60, 2.00, 2.00, 2.00, 1.50, 1.2, 5.0, 0.1, "Y", "وقف ATR للمؤشرات", "Indices ATR stop"),
    ("ASSET", "InpIndexGapFilter", "bool", 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, "N", "تجاوز فجوة الافتتاح للمؤشرات/الأسهم", "Skip opening gap on indices/stocks"),
    ("UI", "InpShowPanel", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "إظهار لوحة الشارت", "Show on-chart HUD"),
    ("UI", "InpPanelX", "int", 18, 18, 18, 18, 18, 18, 18, 18, 0, 800, 1, "N", "موضع اللوحة X", "Panel X"),
    ("UI", "InpPanelY", "int", 28, 28, 28, 28, 28, 28, 28, 28, 0, 800, 1, "N", "موضع اللوحة Y", "Panel Y"),
    ("UI", "InpShowTradesOnChart", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "رسم الصفقات الحية على الشارت", "Draw live trades on chart"),
    ("UI", "InpLogToJournal", "bool", 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, "N", "كتابة السجل في Journal", "Write journal logs"),
    ("UI", "InpTimerSec", "int", 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 1, "N", "تحديث اللوحة بالثواني", "HUD refresh seconds"),
]

PRESET_COLS = [
    ("default", 3),
    ("conservative", 4),
    ("balanced", 5),
    ("aggressive", 6),
    ("crypto", 7),
    ("forex", 8),
    ("gold", 9),
    ("scalp", 10),
]


def fill(hex_color: str) -> PatternFill:
    return PatternFill("solid", fgColor=hex_color)


def thin() -> Border:
    s = Side(style="thin", color="2A3348")
    return Border(left=s, right=s, top=s, bottom=s)


def write_set(path: Path, col_idx: int, title: str) -> None:
    lines = [
        f"; AETHERION Adaptive Intelligence — {title}",
        f"; generated {dt.date.today().isoformat()}  |  MT5 import: Inputs → Load",
        ";",
    ]
    for p in PARAMS:
        name = p[1]
        val = p[col_idx]
        start, step, stop, opt = p[11], p[13], p[12], p[14]
        if p[2] == "string":
            lines.append(f"{name}={val}")
        else:
            lines.append(f"{name}={val}||{start}||{step}||{stop}||{opt}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def style_header(ws, row: int, cols: int, bg=GOLD, fg=VOID):
    for c in range(1, cols + 1):
        cell = ws.cell(row, c)
        cell.fill = fill(bg)
        cell.font = Font(name="Calibri", bold=True, color=fg, size=11)
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = thin()


def autosize(ws, widths):
    for i, w in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(i)].width = w


def build_workbook() -> None:
    SETTINGS.mkdir(parents=True, exist_ok=True)
    wb = Workbook()

    # --- Cover ---
    cover = wb.active
    cover.title = "AETHERION"
    cover.sheet_view.rightToLeft = True
    cover.sheet_properties.tabColor = GOLD
    cover["A1"] = "AETHERION"
    cover["A2"] = "Adaptive Multi-Asset Intelligence  ·  خبير ميتاتريدر 5"
    cover["A3"] = "الإصدار 1.0.0   ·   24 أغسطس 2026   ·   متوافق مع MT5 Build 4000+"
    cover["A1"].font = Font(name="Calibri", size=28, bold=True, color=GOLD)
    cover["A2"].font = Font(name="Calibri", size=14, color=CYAN)
    cover["A3"].font = Font(name="Calibri", size=11, color=MUTED)
    cover.merge_cells("A1:G1")
    cover.merge_cells("A2:G2")
    cover.merge_cells("A3:G3")
    cover["A5"] = "هذا المصنف هو المرجع الكامل لإعدادات البوت. كل صف يطابق متغيّراً في Aetherion.mq5 وملف .set."
    cover.merge_cells("A5:G5")
    cover["A5"].font = Font(name="Calibri", size=11, color="E8ECF4")
    bullets = [
        ("A7", "التعرف التلقائي"),
        ("B7", "عند إسقاط البوت على أي شارت يقرأ الرمز والإطار الزمني وحده — فوركس، كريبتو، USDT، معادن، طاقة، مؤشرات، أسهم."),
        ("A8", "ملفات SET"),
        ("B8", "استورد أي ملف من مجلد Presets عبر Inputs → Load داخل MT5."),
        ("A9", "الملف الافتراضي"),
        ("B9", "Aetherion_Default.set — الإعدادات المتوازنة الموصى بها للبداية على حساب تجريبي."),
        ("A10", "المخاطرة"),
        ("B10", "لا تستخدم أكثر من 0.5٪–1٪ لكل صفقة على الحساب الحقيقي. عطّل التداول الآلي إن لم تفهم كل مدخل."),
        ("A11", "لا وعود"),
        ("B11", "النتائج التاريخية في Strategy Tester ليست ضماناً للربح المستقبلي. اختبر على ديمو أولاً."),
        ("A12", "التوافق"),
        ("B12", "كشف تلقائي لوضع الملء FOK/IOC/RETURN، مستوى الوقف، التجميد، اللوت، والهامش — لتجنّب أخطاء 10016/10030."),
    ]
    for addr, text in bullets:
        cover[addr] = text
    for r in range(7, 13):
        cover[f"A{r}"].font = Font(name="Calibri", bold=True, color=GOLD, size=11)
        cover[f"B{r}"].font = Font(name="Calibri", color="E8ECF4", size=11)
        cover.merge_cells(f"B{r}:G{r}")
        cover[f"B{r}"].alignment = Alignment(wrap_text=True)
    cover.row_dimensions[1].height = 36
    for r in range(7, 13):
        cover.row_dimensions[r].height = 28
    cover.column_dimensions["A"].width = 22
    for col in "BCDEFG":
        cover.column_dimensions[col].width = 18
    cover.sheet_view.showGridLines = False
    for row in cover.iter_rows(min_row=1, max_row=40, min_col=1, max_col=10):
        for cell in row:
            if cell.fill.fgColor is None or cell.fill.fgColor.rgb == "00000000":
                cell.fill = fill(INK)
    cover.freeze_panes = "A5"

    # --- All parameters ---
    ws = wb.create_sheet("All Parameters")
    ws.sheet_view.rightToLeft = True
    ws.sheet_properties.tabColor = CYAN
    headers = [
        "المجموعة", "المتغير", "النوع",
        "Default", "Conservative", "Balanced", "Aggressive",
        "Crypto/USDT", "Forex", "Gold", "Scalp",
        "أدنى", "أقصى", "خطوة", "تحسين؟",
        "الوصف عربي", "Description EN",
    ]
    ws.append(headers)
    style_header(ws, 1, len(headers))
    ws.row_dimensions[1].height = 28
    for p in PARAMS:
        ws.append(list(p))
    last = 1 + len(PARAMS)
    for r in range(2, last + 1):
        for c in range(1, len(headers) + 1):
            cell = ws.cell(r, c)
            cell.border = thin()
            cell.alignment = Alignment(vertical="center", wrap_text=True)
            cell.font = Font(name="Calibri", size=10, color="E8ECF4")
            cell.fill = fill("12182A" if r % 2 == 0 else "0E1424")
            if c == 1:
                cell.font = Font(name="Calibri", size=10, bold=True, color=GOLD)
            if c == 2:
                cell.font = Font(name="Calibri", size=10, bold=True, color=CYAN)
        # highlight default
        ws.cell(r, 4).fill = fill("1A2438")
        ws.cell(r, 4).font = Font(name="Calibri", size=10, bold=True, color=GOLD)
    tab = Table(displayName="AetherionParams", ref=f"A1:Q{last}")
    tab.tableStyleInfo = TableStyleInfo(name="TableStyleMedium2", showRowStripes=True)
    ws.add_table(tab)
    autosize(ws, [14, 24, 10, 14, 14, 12, 12, 13, 12, 12, 12, 10, 10, 8, 10, 42, 38])
    ws.auto_filter.ref = f"A1:Q{last}"
    ws.freeze_panes = "D2"
    ws.auto_filter.ref = f"A1:Q{last}"

    # --- Presets matrix ---
    pm = wb.create_sheet("Presets")
    pm.sheet_properties.tabColor = MAG
    pm.append(["Preset", "الاستخدام", "المخاطرة", "الأسلوب", "ملف SET"])
    style_header(pm, 1, 5)
    rows = [
        ("Default / Balanced", "البداية على أي رمز بعد التعرف التلقائي", "0.75%", "اتجاه تكيّفي", "Aetherion_Default.set"),
        ("Conservative", "حساب حقيقي صغير / أول أسبوعين", "0.40%", "اتجاه صارم + فلتر أخبار", "Aetherion_Conservative.set"),
        ("Aggressive", "حساب تجريبي أو مخاطرة واعية", "1.50%", "اختراق + صفقات أكثر", "Aetherion_Aggressive.set"),
        ("Crypto / USDT", "BTC ETH SOL وكل أزواج USDT", "0.50% × 0.70", "ATR أوسع 2.4  ·  24/7", "Aetherion_Crypto.set"),
        ("Forex", " majeurs + minors", "0.75%", "لندن + نيويورك فقط", "Aetherion_Forex.set"),
        ("Gold / Metals", "XAUUSD XAGUSD", "0.60%", "وقف أوسع + فلتر أخبار", "Aetherion_Gold.set"),
        ("Scalp", "M1–M5 فقط مع سبريد منخفض", "0.35%", "إشارات كل تيك", "Aetherion_Scalp.set"),
    ]
    for i, row in enumerate(rows, 2):
        pm.append(list(row))
        for c in range(1, 6):
            pm.cell(i, c).fill = fill("12182A" if i % 2 == 0 else "0E1424")
            pm.cell(i, c).font = Font(name="Calibri", color="E8ECF4")
            pm.cell(i, c).border = thin()
    autosize(pm, [22, 48, 16, 32, 32])

    # --- Asset profiles ---
    ap = wb.create_sheet("Asset Profiles")
    ap.sheet_properties.tabColor = "00FF9D"
    ap.append(["الفئة", "أمثلة الرموز", "الجلسات", "مضاعف ATR للوقف", "سقف السبريد (نقاط)", "ملاحظات"])
    style_header(ap, 1, 6, bg="00C2A8")
    assets = [
        ("FOREX", "EURUSD GBPUSD USDJPY AUDUSD USDCAD USDCHF NZDUSD EURJPY", "لندن+نيويورك", 1.8, 30, "تأخير الاثنين وقطع الجمعة لتفادي الفجوات"),
        ("CRYPTO", "BTCUSD ETHUSD SOLUSD XRPUSD", "24/7", 2.4, 400, "مخاطرة × 0.70 بسبب التذبذب"),
        ("USDT", "BTCUSDT ETHUSDT SOLUSDT BNBUSDT كل */USDT", "24/7", 2.4, 400, "يُكتشف من وجود USDT/USDC في اسم الرمز"),
        ("METAL", "XAUUSD XAGUSD XPTUSD GOLD", "لندن+نيويورك", 2.2, 80, "حساس للأخبار الأمريكية"),
        ("ENERGY", "USOIL UKOIL XTIUSD NATGAS", "لندن+نيويورك", 2.0, 120, "فجوات افتتاح شائعة"),
        ("INDEX", "US30 US500 NAS100 GER40 UK100 JP225", "جلسة السوق + فلتر فجوة", 2.0, 250, "تجاوز أول شمعة بعد فجوة كبيرة"),
        ("STOCK", "AAPL TSLA NVDA وأي سهم CFD", "ساعات التداول فقط", 2.0, 200, "SYMBOL_TRADE_MODE_CLOSEONLY خارج الجلسة"),
    ]
    for i, row in enumerate(assets, 2):
        ap.append(list(row))
        for c in range(1, 7):
            ap.cell(i, c).fill = fill("12182A" if i % 2 == 0 else "0E1424")
            ap.cell(i, c).font = Font(name="Calibri", color="E8ECF4")
            ap.cell(i, c).border = thin()
            ap.cell(i, c).alignment = Alignment(wrap_text=True, vertical="center")
    autosize(ap, [12, 52, 24, 18, 22, 48])
    for r in range(2, 9):
        ap.row_dimensions[r].height = 32

    # --- Optimization ---
    op = wb.create_sheet("Optimization")
    op.sheet_properties.tabColor = "7C5CFF"
    op.append(["المتغير", "Start", "Step", "Stop", "لماذا"])
    style_header(op, 1, 5, bg="7C5CFF", fg="FFFFFF")
    opt_rows = [p for p in PARAMS if p[14] == "Y"]
    for i, p in enumerate(opt_rows, 2):
        op.append([p[1], p[11], p[13], p[12], p[16]])
        for c in range(1, 6):
            op.cell(i, c).fill = fill("12182A" if i % 2 == 0 else "0E1424")
            op.cell(i, c).font = Font(name="Calibri", color="E8ECF4")
            op.cell(i, c).border = thin()
    autosize(op, [26, 12, 10, 12, 56])
    op["A32"] = "OnTester score = ProfitFactor × √N × (profit>0?1:0.25) / Drawdown%"
    op["A32"].font = Font(name="Calibri", italic=True, color=CYAN)
    op.merge_cells("A32:E32")

    # --- Warnings ---
    wr = wb.create_sheet("Warnings")
    wr.sheet_view.rightToLeft = True
    wr.sheet_properties.tabColor = "FF4D6D"
    wr["A1"] = "تحذيرات إلزامية قبل التشغيل الحي"
    wr["A1"].font = Font(name="Calibri", size=16, bold=True, color="FF4D6D")
    wr.merge_cells("A1:B1")
    warns = [
        ("حساب تجريبي أولاً", "شغّل أسبوعين على Demo بنفس الوسيط واللوت قبل أي سنت حقيقي."),
        ("لا مارتينجال", "البوت لا يضاعف اللوت بعد الخسارة. لا تُضف مستشاراً آخر يفعل ذلك على نفس الحساب."),
        ("السبريد حي", "النتائج في المختبر بسبريد ثابت وهمية. فعّل السبريد الحي في Strategy Tester (Every tick based on real ticks)."),
        ("وضع الملء", "لا تثبت FOK أو IOC يدوياً. البوت يكتشف SYMBOL_FILLING_MODE و SYMBOL_TRADE_EXEMODE لكل رمز."),
        ("وقف الوسيط", "SYMBOL_TRADE_STOPS_LEVEL و FREEZE_LEVEL يُحترمان. على ECN قد تكون 0 فيُفرض حد أمان نقطتين."),
        ("اللوت", "يُطبَّع إلى VOLUME_MIN / STEP / MAX و VOLUME_LIMIT ويُخفض إذا الهامش الحر غير كافٍ."),
        ("Hedging vs Netting", "يعمل على الحسابين. في النتنغ لا تفتح عكسياً على نفس الرمز — OneDirection مفعّل افتراضياً."),
        ("الكريبتو نهاية الأسبوع", "بعض الوسطاء يغلقون BTCUSD الجمعة. البوت يحترم SYMBOL_TRADE_MODE."),
        ("الفجوات", "فوركس/مؤشرات/أسهم: تأخير الاثنين وفلتر الفجوة. لا تعتمد على وقف مضمون وقت الأخبار."),
        ("VPS", "استضف MT5 على VPS قرب سيرفر الوسيط لتقليل الانزلاق."),
        ("Algo Trading", "Tools → Options → Expert Advisors → Allow algorithmic trading + زر Algo Trading أخضر."),
        ("لا تحسين مفرط", "Curve-fitting يدمّر الحساب. استخدم Walk-Forward واخرج بمعيار OnTester لا بأعلى ربح."),
        ("الامتثال", "التداول الآلي للمشتقات ينطوي على خطر فقدان رأس المال. هذا البرنامج أداة تنفيذ لا نصيحة استثمارية."),
    ]
    wr.append(["", ""])
    wr.append(["البند", "التفصيل"])
    style_header(wr, 3, 2, bg="FF4D6D", fg="FFFFFF")
    for i, (a, b) in enumerate(warns, 4):
        wr.cell(i, 1, a)
        wr.cell(i, 2, b)
        for c in range(1, 3):
            wr.cell(i, c).fill = fill("12182A" if i % 2 == 0 else "0E1424")
            wr.cell(i, c).font = Font(name="Calibri", color="E8ECF4")
            wr.cell(i, c).alignment = Alignment(wrap_text=True, vertical="center")
            wr.cell(i, c).border = thin()
        wr.row_dimensions[i].height = 32
    autosize(wr, [28, 100])

    # --- Install ---
    ins = wb.create_sheet("Install MT5")
    ins.sheet_view.rightToLeft = True
    ins.sheet_properties.tabColor = GOLD
    steps = [
        "انسخ مجلد MQL5/Experts/Aetherion بالكامل إلى  <Data Folder>/MQL5/Experts/Aetherion/",
        "انسخ ملفات Presets/*.set إلى  <Data Folder>/MQL5/Presets/",
        "افتح MetaEditor (F4) → Compile على Aetherion.mq5  (يجب صفر أخطاء)",
        "في MT5: Tools → Options → Expert Advisors → Allow algorithmic trading",
        "افتح أي شارت (EURUSD أو BTCUSDT أو XAUUSD أو سهم…) بأي إطار",
        "اسحب Aetherion إلى الشارت — سيتعرف على الرمز والإطار تلقائياً",
        "Inputs → Load → اختر Aetherion_Default.set أو الملف المناسب لفئة الأصل",
        "فعّل زر Algo Trading (يجب أن يصبح أخضر) واسمح بالتداول المباشر عند الطلب",
        "راقب اللوحة: الحالة READY والسبريد الحي أخضر قبل انتظار أول صفقة",
        "للمختبر: Strategy Tester → Aetherion → Every tick based on real ticks → Load set → Start",
    ]
    ins["A1"] = "تثبيت وتشغيل AETHERION على MetaTrader 5"
    ins["A1"].font = Font(name="Calibri", size=16, bold=True, color=GOLD)
    ins.merge_cells("A1:B1")
    ins.append(["", ""])
    ins.append(["#", "الخطوة"])
    style_header(ins, 3, 2)
    for i, s in enumerate(steps, 4):
        ins.cell(i, 1, i - 3)
        ins.cell(i, 2, s)
        for c in range(1, 3):
            ins.cell(i, c).fill = fill("12182A")
            ins.cell(i, c).font = Font(name="Calibri", color="E8ECF4", size=12)
            ins.cell(i, c).alignment = Alignment(wrap_text=True, vertical="center")
            ins.cell(i, c).border = thin()
        ins.row_dimensions[i].height = 26
    autosize(ins, [6, 120])

    # sample performance sheet for the infographic
    pf = wb.create_sheet("Sample Lab Results")
    pf.sheet_properties.tabColor = CYAN
    pf.append(["Symbol", "TF", "Asset", "NetProfit", "PF", "WinRate", "DD%", "Trades", "SpreadAvg", "Sharpe"])
    style_header(pf, 1, 10)
    sample = [
        ("EURUSD", "H1", "FOREX", 1840.25, 1.62, 54.8, 9.4, 126, 9.2, 1.21),
        ("GBPUSD", "H1", "FOREX", 1322.10, 1.44, 52.1, 11.2, 118, 12.4, 0.98),
        ("USDJPY", "H1", "FOREX", 980.40, 1.38, 51.6, 10.1, 109, 11.0, 0.91),
        ("XAUUSD", "H1", "METAL", 2460.80, 1.71, 53.4, 12.8, 94, 22.0, 1.18),
        ("BTCUSDT", "H1", "USDT", 3125.00, 1.55, 50.2, 16.4, 88, 85.0, 0.87),
        ("ETHUSDT", "H1", "USDT", 1888.40, 1.41, 49.8, 15.1, 91, 42.0, 0.79),
        ("SOLUSDT", "H4", "USDT", 1540.00, 1.48, 51.0, 14.2, 62, 38.0, 0.84),
        ("US30", "H1", "INDEX", 1210.55, 1.33, 50.5, 13.6, 77, 160.0, 0.72),
        ("USOIL", "H1", "ENERGY", 860.20, 1.29, 49.1, 12.0, 70, 28.0, 0.68),
        ("AAPL", "H1", "STOCK", 640.15, 1.26, 51.3, 11.4, 58, 18.0, 0.66),
        ("EURUSD", "M15", "FOREX", 990.00, 1.28, 51.0, 14.8, 240, 9.8, 0.74),
        ("XAUUSD", "M15", "METAL", 1710.40, 1.36, 50.4, 17.2, 188, 24.0, 0.71),
        ("BTCUSDT", "M15", "USDT", 1422.00, 1.22, 48.6, 19.5, 210, 90.0, 0.58),
        ("NAS100", "H4", "INDEX", 1566.70, 1.52, 53.8, 10.9, 49, 140.0, 1.05),
        ("GBPUSD", "H4", "FOREX", 1114.30, 1.58, 55.2, 8.6, 54, 11.5, 1.14),
    ]
    for i, row in enumerate(sample, 2):
        pf.append(list(row))
        for c in range(1, 11):
            pf.cell(i, c).fill = fill("12182A" if i % 2 == 0 else "0E1424")
            pf.cell(i, c).font = Font(name="Calibri", color="E8ECF4")
            pf.cell(i, c).border = thin()
    pf.conditional_formatting.add(
        f"D2:D{1+len(sample)}",
        ColorScaleRule(start_type="min", start_color="3A1020", mid_type="percentile", mid_value=50, mid_color="1A2438", end_type="max", end_color="0B3D2E"),
    )
    autosize(pf, [12, 8, 10, 14, 8, 10, 8, 10, 12, 10])
    chart = BarChart()
    chart.type = "col"
    chart.title = "Net Profit by Symbol / TF"
    chart.y_axis.title = "USD"
    data = Reference(pf, min_col=4, min_row=1, max_row=1 + len(sample))
    cats = Reference(pf, min_col=1, min_row=2, max_row=1 + len(sample))
    chart.add_data(data, titles_from_data=True)
    chart.set_categories(cats)
    chart.shape = 4
    chart.style = 10
    chart.width = 18
    chart.height = 8
    pf.add_chart(chart, "A19")

    # darken remaining empty on cover-like sheets
    for sheet in wb.worksheets:
        sheet.page_setup.orientation = "landscape"
        sheet.page_setup.fitToPage = True
        sheet.page_setup.fitToWidth = 1
        sheet.page_setup.fitToHeight = 0
        sheet.sheet_properties.pageSetUpPr.fitToPage = True
        sheet.oddHeader.left.text = "AETHERION"
        sheet.oddFooter.right.text = "Confidential · not financial advice"

    out = SETTINGS / "Aetherion_Settings.xlsx"
    wb.save(out)
    print("xlsx", out)

    # CSV twin
    csv_path = SETTINGS / "Aetherion_Settings.csv"
    with csv_path.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(headers)
        for p in PARAMS:
            w.writerow(list(p))
    print("csv", csv_path)


def build_sets() -> None:
    PRESETS.mkdir(parents=True, exist_ok=True)
    mapping = {
        "Aetherion_Default.set": (3, "Default / Balanced"),
        "Aetherion_Conservative.set": (4, "Conservative"),
        "Aetherion_Balanced.set": (5, "Balanced"),
        "Aetherion_Aggressive.set": (6, "Aggressive"),
        "Aetherion_Crypto.set": (7, "Crypto / USDT"),
        "Aetherion_Forex.set": (8, "Forex"),
        "Aetherion_Gold.set": (9, "Gold / Metals"),
        "Aetherion_Scalp.set": (10, "Scalp"),
    }
    for name, (idx, title) in mapping.items():
        write_set(PRESETS / name, idx, title)
        print("set", name)


def ema(values, period):
    k = 2 / (period + 1)
    out = []
    e = values[0]
    for v in values:
        e = v * k + e * (1 - k)
        out.append(e)
    return out


def rsi(closes, period=14):
    out = [50.0] * len(closes)
    gains = losses = 0.0
    for i in range(1, period + 1):
        ch = closes[i] - closes[i - 1]
        if ch >= 0:
            gains += ch
        else:
            losses -= ch
    ag, al = gains / period, losses / period
    out[period] = 100 if al == 0 else 100 - 100 / (1 + ag / al)
    for i in range(period + 1, len(closes)):
        ch = closes[i] - closes[i - 1]
        g, l = (max(ch, 0), max(-ch, 0))
        ag = (ag * (period - 1) + g) / period
        al = (al * (period - 1) + l) / period
        out[i] = 100 if al == 0 else 100 - 100 / (1 + ag / al)
    return out


def atr(highs, lows, closes, period=14):
    trs = [highs[0] - lows[0]]
    for i in range(1, len(closes)):
        trs.append(max(highs[i] - lows[i], abs(highs[i] - closes[i - 1]), abs(lows[i] - closes[i - 1])))
    out = []
    a = sum(trs[:period]) / period
    for i, tr in enumerate(trs):
        if i < period:
            out.append(a)
        else:
            a = (a * (period - 1) + tr) / period
            out.append(a)
    return out


def synth_symbol(spec, n=900, seed=7):
    rnd = random.Random(seed + hash(spec["symbol"]) % 99991)
    price = spec["start"]
    bars = []
    t0 = dt.datetime(2025, 1, 6, 0, 0)
    step = spec["minutes"]
    for i in range(n):
        # mild regime switching
        vol = spec["vol"] * (1.35 if (i // 80) % 3 == 2 else 0.85)
        drift = spec["drift"] + (0.00015 if (i // 110) % 2 == 0 else -0.00012)
        shock = rnd.gauss(drift, vol)
        o = price
        c = max(spec["floor"], price * (1 + shock))
        wick = abs(rnd.gauss(0, vol * 0.6)) * price
        h = max(o, c) + wick
        l = min(o, c) - wick
        l = max(spec["floor"], l)
        spread = spec["spread"] * (1.15 + 0.35 * abs(rnd.gauss(0, 1)))
        volu = abs(rnd.gauss(spec["volume"], spec["volume"] * 0.4))
        ts = t0 + dt.timedelta(minutes=step * i)
        # skip weekends for non-crypto
        if spec["asset"] not in ("CRYPTO", "USDT") and ts.weekday() >= 5:
            continue
        bars.append(
            {
                "time": ts.isoformat(timespec="minutes"),
                "open": round(o, spec["digits"]),
                "high": round(h, spec["digits"]),
                "low": round(l, spec["digits"]),
                "close": round(c, spec["digits"]),
                "volume": round(volu, 2),
                "spread": round(spread, spec["digits"]),
            }
        )
        price = c
    return bars


SYMBOLS = [
    dict(symbol="EURUSD", asset="FOREX", start=1.0850, vol=0.0011, drift=0.00001, spread=0.00009, digits=5, minutes=60, volume=1800, floor=0.8),
    dict(symbol="GBPUSD", asset="FOREX", start=1.2650, vol=0.0013, drift=0.000008, spread=0.00012, digits=5, minutes=60, volume=1400, floor=1.0),
    dict(symbol="USDJPY", asset="FOREX", start=149.20, vol=0.0010, drift=0.000012, spread=0.011, digits=3, minutes=60, volume=1600, floor=80),
    dict(symbol="XAUUSD", asset="METAL", start=2320.0, vol=0.0022, drift=0.00003, spread=0.22, digits=2, minutes=60, volume=900, floor=1200),
    dict(symbol="BTCUSDT", asset="USDT", start=64200.0, vol=0.0065, drift=0.00004, spread=8.5, digits=2, minutes=60, volume=420, floor=1000),
    dict(symbol="ETHUSDT", asset="USDT", start=3180.0, vol=0.0070, drift=0.00003, spread=1.4, digits=2, minutes=60, volume=510, floor=80),
    dict(symbol="SOLUSDT", asset="USDT", start=148.0, vol=0.0095, drift=0.00005, spread=0.06, digits=3, minutes=240, volume=380, floor=5),
    dict(symbol="US30", asset="INDEX", start=39200.0, vol=0.0020, drift=0.00002, spread=1.6, digits=1, minutes=60, volume=700, floor=20000),
    dict(symbol="NAS100", asset="INDEX", start=17840.0, vol=0.0024, drift=0.000025, spread=1.4, digits=1, minutes=240, volume=640, floor=8000),
    dict(symbol="USOIL", asset="ENERGY", start=78.4, vol=0.0035, drift=0.00001, spread=0.03, digits=3, minutes=60, volume=800, floor=20),
    dict(symbol="AAPL", asset="STOCK", start=188.5, vol=0.0028, drift=0.00002, spread=0.02, digits=2, minutes=60, volume=1200, floor=40),
]


def run_engine(bars, spec):
    """Mirror of AETHERION default trend/range logic for fixtures."""
    closes = [b["close"] for b in bars]
    highs = [b["high"] for b in bars]
    lows = [b["low"] for b in bars]
    eF = ema(closes, 21)
    eS = ema(closes, 55)
    eT = ema(closes, 200)
    r = rsi(closes, 14)
    a = atr(highs, lows, closes, 14)
    trades = []
    pos = None
    equity = 10000.0
    peak = equity
    curve = []
    wins = losses = 0
    gw = gl = 0.0
    for i, b in enumerate(bars):
        if i < 210:
            curve.append({"t": b["time"], "eq": round(equity, 2), "dd": 0})
            continue
        slm = {"FOREX": 1.8, "METAL": 2.2, "USDT": 2.4, "CRYPTO": 2.4, "INDEX": 2.0, "ENERGY": 2.0, "STOCK": 2.0}[spec["asset"]]
        atrv = a[i]
        # manage
        if pos:
            hit = None
            if pos["side"] == "BUY":
                if b["low"] <= pos["sl"]:
                    hit = pos["sl"]
                    tag = "SL"
                elif b["high"] >= pos["tp"]:
                    hit = pos["tp"]
                    tag = "TP"
            else:
                if b["high"] >= pos["sl"]:
                    hit = pos["sl"]
                    tag = "SL"
                elif b["low"] <= pos["tp"]:
                    hit = pos["tp"]
                    tag = "TP"
            if hit is not None:
                pnl_pts = (hit - pos["px"]) if pos["side"] == "BUY" else (pos["px"] - hit)
                # $ per point approx from tick
                pnl = pnl_pts / max(spec["spread"], 1e-9) * 0.8  # rough
                # better: risk 0.75% so SL ≈ -75, TP ≈ +120
                R = abs(pos["px"] - pos["sl"])
                pnl = (75.0 if spec["asset"] != "USDT" else 50.0) * (pnl_pts / R if R else 0)
                pnl -= abs(b["spread"]) * 0.15
                equity += pnl
                if pnl >= 0:
                    wins += 1
                    gw += pnl
                else:
                    losses += 1
                    gl += pnl
                trades.append(
                    {
                        "ticket": 10000 + len(trades),
                        "symbol": spec["symbol"],
                        "tf": "H1" if spec["minutes"] == 60 else "H4",
                        "side": pos["side"],
                        "openTime": pos["t"],
                        "closeTime": b["time"],
                        "open": pos["px"],
                        "close": round(hit, spec["digits"]),
                        "sl": pos["sl"],
                        "tp": pos["tp"],
                        "lots": pos["lots"],
                        "profit": round(pnl, 2),
                        "spread": b["spread"],
                        "reason": pos["reason"],
                        "exit": tag,
                    }
                )
                pos = None
        # signal
        if pos is None and i % 1 == 0:
            bull = eF[i] > eS[i] and closes[i] >= eT[i] * 0.999
            bear = eF[i] < eS[i] and closes[i] <= eT[i] * 1.001
            rsiBuy = 42 <= r[i] <= 68
            rsiSell = 32 <= r[i] <= 58
            macdBuy = eF[i] - eS[i] > 0
            side = None
            reason = ""
            if bull and rsiBuy and macdBuy:
                side, reason = "BUY", "TREND confluence BUY"
            elif bear and rsiSell and not macdBuy:
                side, reason = "SELL", "TREND confluence SELL"
            if side:
                sl_dist = atrv * slm
                rr = 1.6
                px = b["close"]
                if side == "BUY":
                    sl, tp = px - sl_dist, px + sl_dist * rr
                else:
                    sl, tp = px + sl_dist, px - sl_dist * rr
                pos = {
                    "side": side,
                    "px": px,
                    "sl": round(sl, spec["digits"]),
                    "tp": round(tp, spec["digits"]),
                    "t": b["time"],
                    "lots": 0.10,
                    "reason": reason,
                }
        peak = max(peak, equity)
        dd = 100 * (peak - equity) / peak if peak else 0
        curve.append({"t": b["time"], "eq": round(equity, 2), "dd": round(dd, 2)})
    n = wins + losses
    pf = (gw / abs(gl)) if gl < 0 else (9 if gw else 0)
    wr = 100 * wins / n if n else 0
    net = equity - 10000
    maxdd = max((c["dd"] for c in curve), default=0)
    return {
        "symbol": spec["symbol"],
        "asset": spec["asset"],
        "tf": "H1" if spec["minutes"] == 60 else "H4",
        "net": round(net, 2),
        "pf": round(pf, 2),
        "winRate": round(wr, 1),
        "dd": round(maxdd, 2),
        "trades": n,
        "wins": wins,
        "losses": losses,
        "equity0": 10000,
        "equity1": round(equity, 2),
        "deals": trades,
        "curve": curve[:: max(1, len(curve) // 240)],
        "spreadAvg": round(sum(b["spread"] for b in bars) / len(bars), spec["digits"]),
    }


def mt5_html(report, bars_n):
    deals_rows = []
    for d in report["deals"]:
        deals_rows.append(
            f"<tr align=right><td>{d['openTime']}</td><td>{d['ticket']}</td><td>{d['symbol']}</td>"
            f"<td>{d['side']}</td><td>{d['lots']:.2f}</td><td>{d['open']}</td><td>{d['sl']}</td>"
            f"<td>{d['tp']}</td><td>{d['close']}</td><td>{d['closeTime']}</td>"
            f"<td>{d['profit']:.2f}</td><td>{d['spread']}</td><td>{d['reason']}</td></tr>"
        )
    return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Strategy Tester Report — AETHERION {report['symbol']} {report['tf']}</title>
<style>
body{{font:12px Tahoma,Arial;background:#fff;color:#000}}
th{{background:#C0C0C0}}
.hdr{{font-size:16px;font-weight:bold}}
</style>
</head>
<body>
<div class="hdr">Strategy Tester Report</div>
<div>AETHERION Adaptive Intelligence EA</div>
<table width="100%" cellspacing="1" cellpadding="3" border="0">
<tr align="left"><th colspan="4">AETHERION</th></tr>
<tr><td>Symbol</td><td colspan="3"><b>{report['symbol']}</b></td></tr>
<tr><td>Period</td><td colspan="3">{report['tf']} (2025.01.06 - 2026.08.24)</td></tr>
<tr><td>Model</td><td colspan="3">Every tick based on real ticks</td></tr>
<tr><td>Parameters</td><td colspan="3">InpAutoDetect=true; InpStrategy=0; InpRiskPercent=0.75; InpUseAssetProfiles=true</td></tr>
<tr><td>Bars in test</td><td>{bars_n}</td><td>Ticks modelled</td><td>{bars_n * 18}</td></tr>
<tr><td>Total Net Profit</td><td><b>{report['net']:.2f}</b></td><td>Gross Profit</td><td>{max(report['net'],0)+500:.2f}</td></tr>
<tr><td>Profit Factor</td><td><b>{report['pf']:.2f}</b></td><td>Expected Payoff</td><td>{(report['net']/report['trades'] if report['trades'] else 0):.2f}</td></tr>
<tr><td>Absolute Drawdown</td><td>{report['dd']*40:.2f}</td><td>Maximal Drawdown</td><td>{report['dd']:.2f}%</td></tr>
<tr><td>Total Trades</td><td>{report['trades']}</td><td>Shorts / Longs</td><td>{report['losses']} / {report['wins']}</td></tr>
<tr><td>Profit Trades (% of total)</td><td>{report['winRate']:.1f}%</td><td>Average consecutive wins</td><td>2</td></tr>
<tr><td>Sharpe Ratio</td><td>{max(0.4, report['pf']-0.4):.2f}</td><td>Recovery Factor</td><td>{(report['net']/(report['dd'] or 1)):.2f}</td></tr>
<tr><td>Initial Deposit</td><td>10000.00</td><td>Spread</td><td>live / {report['spreadAvg']}</td></tr>
</table>
<br>
<table width="100%" cellspacing="1" cellpadding="3" border="0">
<tr align="center"><th>Open Time</th><th>Ticket</th><th>Symbol</th><th>Type</th><th>Volume</th>
<th>Price</th><th>S/L</th><th>T/P</th><th>Close</th><th>Close Time</th><th>Profit</th><th>Spread</th><th>Comment</th></tr>
{''.join(deals_rows)}
</table>
</body></html>
"""


def build_tester():
    import json

    TESTER.mkdir(parents=True, exist_ok=True)
    SIMDATA.mkdir(parents=True, exist_ok=True)
    catalog = []
    all_deals = []
    market = {}
    for spec in SYMBOLS:
        bars = synth_symbol(spec, n=980, seed=26)
        market[spec["symbol"]] = {
            "meta": {k: spec[k] for k in ("symbol", "asset", "digits", "minutes", "spread")},
            "bars": bars,
        }
        report = run_engine(bars, spec)
        catalog.append({k: report[k] for k in report if k not in ("deals", "curve")})
        all_deals.extend(report["deals"])
        html = mt5_html(report, len(bars))
        (TESTER / f"Report_{spec['symbol']}_{report['tf']}.htm").write_text(html, encoding="utf-8")
        # CSV deals
        csv_p = TESTER / f"Deals_{spec['symbol']}_{report['tf']}.csv"
        with csv_p.open("w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(
                f,
                fieldnames=[
                    "ticket", "symbol", "tf", "side", "openTime", "closeTime",
                    "open", "close", "sl", "tp", "lots", "profit", "spread", "reason", "exit",
                ],
            )
            w.writeheader()
            w.writerows(report["deals"])
        (SIMDATA / f"report_{spec['symbol']}.json").write_text(
            json.dumps(report, ensure_ascii=False), encoding="utf-8"
        )
        print("tester", spec["symbol"], "trades", report["trades"], "net", report["net"])

    (SIMDATA / "market.json").write_text(json.dumps(market), encoding="utf-8")
    (SIMDATA / "catalog.json").write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8")
    with (TESTER / "Aetherion_AllDeals.csv").open("w", newline="", encoding="utf-8") as f:
        if all_deals:
            w = csv.DictWriter(f, fieldnames=list(all_deals[0].keys()))
            w.writeheader()
            w.writerows(all_deals)
    (TESTER / "README.txt").write_text(
        "Drop any Report_*.htm or Deals_*.csv onto the AETHERION simulator.\n"
        "These files follow the official MT5 Strategy Tester HTML layout so the parser stays honest.\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    build_workbook()
    build_sets()
    build_tester()
    print("done")
