# 📝 SMC_ICT_Pro_V2 — جميع الإعدادات والدليل المرجعي

> ملف البوت: `SMC_ICT_Pro_V2.mq5` · ملف الجاهز للاستيراد: `SMC_ICT_Pro_V2.set`
> متوافق مع MT5. لا يعد بالربح. الاختبار التاريخي ليس ضماناً للأداء الحي.

---

## 1. التعرف التلقائي والتشغيل
| الإعداد | القيمة الافتراضية | الوظيفة | الملاحظات |
|---|---|---|---|
| `InpEnableEA` | true | تفعيل البوت | عند false لا يفتح أي صفقة |
| `InpMagic` | 702001 | معرف فريد للصفقات | MT5 يحفظ Magic في السجل ولا يحفظ اسم الملف |
| `InpSignalTF` | PERIOD_CURRENT | إطار الإشارة للـ SMC | استخدم CURRENT لاستخدام إطار الشارت تلقائياً |
| `InpBiasTF` | H1 | إطار الاتجاه (HTF Bias) | يُستخدم لتحديد الانحياز العام |
| `InpAutoDetectAssetType` | true | كشف نوع الأصل تلقائياً | كريبتو/فوركس/سلع/أسهم/مؤشرات/أخرى |
| `InpUseChartTF` | true | استخدام إطار الشارت | يسمح بالعمل على أي إطار زمني |
| `InpOnlyTradeDetected` | false | التداول فقط عند التعرف على النوع | فعّله إذا أردت منع الرموز غير المعروفة |

### كيف يحدد نوع الأصل؟ (`DetectAssetType`)
- 🪙 **CRYPTO**: أي رمز يحوي USDT/USDC/BUSD… أو أسماء عملات معروفة (BTC, ETH, XRP…).
- 💹 **FOREX**: أزواج من 6 أحرف من عملات رئيسية (EURUSD, GBPUSD, USDJPY…).
- 📊 **COMMODITY**: XAU/XAG/XPT/XPD/XCU/OIL/WTI/BRENT/NGAS….
- 📈 **INDEX**: US30, US500, NAS…, SPX, DJI, DAX, GER, DE30, CAC, F40, FTSE, UK100, SMI, NIKKEI, JPN, AXI, HK50, HKG, VIX.
- 💰 **STOCK**: أي رمز يحتوي نقطة سوق (مثل `TSLA.US`, `SAP.DE`) أو لواحق سوق `.US/.DE/.FR/.UK/.JP/.HK`.

---

## 2. إدارة المخاطر
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpEnableRiskBasedLot` | true | حساب اللوت من المخاطرة المالية لا بالتخمين |
| `InpRiskPerTradePercent` | 0.50 | نسبة المخاطرة لكل صفقة |
| `InpUseFixedLotForTesting` | false | لوت ثابت (للاختبار فقط) |
| `InpFixedLot` | 0.01 | اللوت الثابت |
| `InpMaxLot` | 10.0 | أقصى لوت |
| `InpMaxOpenRiskPercent` | 1.00 | أقصى مخاطرة إجمالية للصفقات المفتوحة |
| `InpMaxOpenPositionsPerSymbol` | 1 | أقصى عدد مراكز لكل رمز |
| `InpAllowHedge` | false | منع الهيدج |
| `InpDailyLossLimitPercent` | 2.00 | حد الخسارة اليومي |
| `InpWeeklyLossLimitPercent` | 4.00 | حد الخسارة الأسبوعي |
| `InpMaxEquityDrawdownPercent` | 10.00 | حد التراجع عن القمة |
| `InpMaxConsecutiveLosses` | 3 | عدد الخسائر المتتالية قبل التبريد |
| `InpCooldownMinutes` | 60 | مدة التبريد |
| `InpMaxTradesPerDay` | 5 | أقصى صفقات يومياً |
| `InpMaxTradesPerSession` | 3 | أقصى صفقات بالجلسة |
| `InpCloseOnDrawdownLimit` | false | إغلاق المراكز عند حد التراجع (يتطلب تفعيلاً صريحاً) |

> التوجه: اللوت يُحسب من `RiskMoney = Equity × Risk%/100` ثم يُطبَّع حسب `VolumeMin/VolumeMax/VolumeStep/TickValue`.

---

## 3. فلاتر التنفيذ
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpEnableSpreadFilter` | true | منع الدخول عند سبريد أعلى من الحد |
| `InpMaxSpreadPoints` | 30 | أقصى سبريد بالنقاط |
| `InpMaxDeviationPoints` | 20 | الانحراف المسموح |
| `InpRequireValidTick` | true | منع التداول بدون Bid/Ask صالح |
| `InpEnableNewBarOnly` | true | إشارة واحدة لكل شمعة جديدة |
| `InpBlockBeforeWeekendMinutes` | 120 | منع جديد قبل نهاية الأسبوع |
| `InpBlockMondayMorning` | false | منع الاثنين الصباحي |

---

## 4. الجلسات
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpEnableSessionFilter` | true | تفعيل فلتر الجلسات |
| `InpEnableLondonSession` | true | جلسة لندن |
| `InpLondonStartHour` / `InpLondonEndHour` | 8 / 17 | ساعات الجلسة (توقيت السيرفر) |
| `InpEnableNewYorkSession` | true | جلسة نيويورك |
| `InpNewYorkStartHour` / `InpNewYorkEndHour` | 13 / 22 | ساعات الجلسة |
| `InpAllowOverlapSessions` | true | السماح بالتداخل |

---

## 5. فلتر الأخبار
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpEnableNewsFilter` | true | تفعيل فلتر الأخبار |
| `InpNewsDataMode` | NEWS_CALENDAR | مصدر الأخبار: معطّل / CSV / تقويم MT5 |
| `InpNewsCSVFileName` | news_events.csv | ملف CSV للاختبار التاريخي |
| `InpNewsMinutesBefore` / `InpNewsMinutesAfter` | 30 / 30 | نافذة الحظر |
| `InpCloseBeforeHighImpactNews` | false | إغلاق قبل الأخبار عالية الأثر (يتطلب تفعيلاً) |
| `InpFailSafeMode` | true | منع الدخول عند غياب بيانات الأخبار |

> تنسيق CSV المطلوب: `datetime,currency,impact,event` — مثال:
> `1767225600,EUR,HIGH,CPI y/y`
> أو: `2025-01-01 08:30,EUR,MEDIUM,German Retail Sales`

---

## 6. إدارة المراكز
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpBreakEven` | true | نقل SL إلى التعادل بعد ربح محدد |
| `InpBreakEvenTriggerPoints` | 20 | نقاط تفعيل Break-even |
| `InpBreakEvenLockPoints` | 2 | نقاط تثبيت ربح |
| `InpTrailingStop` | true | تتبع الوقف |
| `InpTrailingStartPoints` | 30 | بداية التتبع |
| `InpTrailingStepPoints` | 10 | خطوة التتبع |
| `InpPartialClose` | false | إغلاق جزئي |
| `InpPartialClosePercent` | 50.0 | نسبة الإغلاق الجزئي |
| `InpPartialCloseTriggerPoints` | 40 | نقاط تفعيل الإغلاق الجزئي |
| `InpMaxBarsInTrade` | 0 | أقصى شموع للصفقة (0=بدون) |
| `InpUseStopLevelCheck` | true | التحقق من Stops/Freeze Level |

> لا يحرك البوت أبداً SL بعيداً عن السعر (حماية إلزامية).

---

## 7. التسجيل واللوحة
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpWriteJournalCSV` | true | كتابة سجل CSV في `MQL5\Files` |
| `InpJournalCSVName` | `SMC_ICT_Pro_V2_Journal.csv` | اسم ملف السجل |
| `InpLogLevel` | INFO | مستوى التسجيل (ERROR/WARNING/INFO/DEBUG) |
| `InpShowDashboard` | true | لوحة المراقبة على الشارت |
| `InpDashboardCorner` | 1 | ركن اللوحة |

---

## 8. منطق SMC/ICT
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpSMCSwingLookback` | 3 | عدد الشموع حول القمة/القاع |
| `InpSMCZigZagLimit` | 15 | عدد الكسور للتحليل |
| `InpSMCEqualTolerancePercent` | 0.15 | تسامح السيولة المتساوية |
| `InpSMCOTELow` / `InpSMCOTEHigh` | 61.8 / 79.0 | نطاق OTE |
| `InpSMCRequireFVG` | true | اشتراط فجوة القيمة العادلة |
| `InpSMCRequireSweep` | true | اشتراط كنس سيولة |
| `InpSMCRequireCHoCH` | true | اشتراط انعكاس الهيكل |
| `InpSMCUseHTFBias` | true | مصادقة اتجاه HTF |

---

## 9. Comment و Magic (مهم جداً)
- MT5 **لا يحفظ اسم ملف البوت** في الصفقة. يحفظ فقط **Magic** و**Comment ≤ 31 حرفاً**.
- البوت يستخدم `MQLInfoString(MQL_PROGRAM_NAME)` ثم يزيل `.ex5` ويقصّ اسمه إلى 31 حرفاً ويضعه في Comment:
  ```
  string eaName = MQLInfoString(MQL_PROGRAM_NAME);
  int dot = StringFind(eaName, ".");
  if(dot >= 0) eaName = StringSubstr(eaName, 0, dot);
  if(StringLen(eaName) > 31) eaName = StringSubstr(eaName, 0, 31);
  trade.SetComment(eaName);
  ```
- 🚨 التعديل ينطبق فقط على الصفقات **الجديدة**. لا يوجد في MT5 طريقة لتعديل Comment صفقة موجودة.

---

## 10. قائمة تحقق قبل الحساب الحقيقي
- [ ] Baseline: `Every tick based on real ticks`
- [ ] الرمز والوسيط ونوع الحساب مطابقة للحقيقي
- [ ] عمولة + سبريد + سواب + انزلاق واقعية
- [ ] صافي الربح موجب بعد التكاليف (وليس Gross فقط)
- [ ] Max Drawdown ضمن الحد المخطط
- [ ] لا Martingale ولا Grid غير محدود
- [ ] حدود يومية/أسبوعية/سلسلة خسائر مفعّلة
- [ ] Stress Test لم ينهار
- [ ] Forward Test سليم
- [ ] Demo 4–8 أسابيع ومقارنة
- [ ] حجم بداية محافظ (0.01 لوت أو 0.25–0.5%)
