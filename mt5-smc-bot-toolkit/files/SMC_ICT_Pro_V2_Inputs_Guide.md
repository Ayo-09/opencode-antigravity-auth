# 📝 SMC_ICT_Pro_V2 — جميع الإعدادات والدليل المرجعي (AI-SMC/ICT)

> ملف البوت: `SMC_ICT_Pro_V2.mq5` · ملف الجاهز للاستيراد: `SMC_ICT_Pro_V2.set`
> المرجع: **المرجع الشامل لاستراتيجية الهجينة المدعومة بالذكاء الاصطناعي — AI-SMC/ICT** (صفحتان).
> متوافق مع MT5. لا يعد بالربح — الاختبار التاريخي ليس ضماناً للأداء الحي.

---

## 1. التعرف التلقائي والتشغيل
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpEnableEA` | true | تفعيل البوت |
| `InpMagic` | 702001 | معرف فريد للصفقات |
| `InpAutoDetectAssetType` | true | كشف نوع الأصل تلقائياً |
| `InpOnlyTradeDetected` | false | التداول فقط عند التعرف على النوع |

### أنواع الأصول المكتشفة
🪙 **CRYPTO/USDT** · 💹 **FOREX** · 📊 **COMMODITY** · 📈 **INDEX** · 💰 **STOCK**

---

## 2. إدارة المخاطر (حسب الملف: 1–2% لكل صفقة)
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpEnableRiskBasedLot` | true | لوت من المخاطرة |
| `InpRiskPerTradePercent` | 1.00 | مخاطرة الصفقة (1%) |
| `InpMaxRiskPerTradeHardCap` | 2.00 | **سقف صلب 2%** (مطابق للملف) |
| `InpUseFixedLotForTesting` | false | لوت ثابت للاختبار |
| `InpFixedLot` | 0.01 | اللوت الثابت |
| `InpMaxLot` | 10.0 | أقصى لوت |
| `InpMaxOpenRiskPercent` | 2.00 | أقصى مخاطرة مفتوحة |
| `InpMaxOpenPositionsPerSymbol` | 1 | أقصى مراكز لكل رمز |
| `InpAllowHedge` | false | منع الهيدج |
| `InpDailyLossLimitPercent` | 2.00 | حد الخسارة اليومي (2%) |
| `InpWeeklyLossLimitPercent` | 4.00 | حد الخسارة الأسبوعي |
| `InpMaxEquityDrawdownPercent` | 10.00 | حد التراجع |
| `InpMaxConsecutiveLosses` | 3 | الخسائر المتتالية قبل التبريد |
| `InpCooldownMinutes` | 60 | مدة التبريد |
| `InpMaxTradesPerDay` / `InpMaxTradesPerSession` | 5 / 3 | حدود الصفقات |
| `InpCloseOnDrawdownLimit` | false | إغلاق المراكز عند حد التراجع (يتطلب تفعيلاً) |

---

## 3. فلاتر التنفيذ
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpEnableSpreadFilter` | true | فلتر السبريد |
| `InpMaxSpreadPoints` | 30 | أقصى سبريد بالنقاط |
| `InpMaxDeviationPoints` | 20 | الانحراف المسموح |
| `InpRequireValidTick` | true | اشتراط Tick صالح |
| `InpBlockBeforeWeekendMinutes` | 120 | منع جديد قبل نهاية الأسبوع |

---

## 4. الجلسات وافتتاح لندن
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpEnableSessionFilter` | true | فلتر الجلسات |
| `InpEnableLondonSession` / `InpLondonStartHour` / `InpLondonEndHour` | true / 8 / 17 | جلسة لندن |
| `InpEnableNewYorkSession` / `InpNewYorkStartHour` / `InpNewYorkEndHour` | true / 13 / 22 | جلسة نيويورك |
| `InpAllowOverlapSessions` | true | السماح بالتداخل |
| `InpFocusOnLondonOpening` | true | **التركيز على افتتاح جلسة لندن** (حسب الملف) |
| `InpLondonOpenStartHour` / `InpLondonOpenEndHour` | 7 / 11 | نافذة افتتاح لندن |

---

## 5. فلتر الأخبار
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpEnableNewsFilter` | true | فلتر الأخبار |
| `InpNewsDataMode` | NEWS_CALENDAR | معطّل / CSV / تقويم MT5 |
| `InpNewsCSVFileName` | news_events.csv | ملف CSV تاريخي |
| `InpNewsMinutesBefore` / `InpNewsMinutesAfter` | 30 / 30 | نافذة الحظر |
| `InpCloseBeforeHighImpactNews` | false | إغلاق قبل أخبار عالية الأثر (يتطلب تفعيلاً) |
| `InpFailSafeMode` | true | منع عند غياب البيانات |

---

## 6. إدارة المراكز
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpBreakEven` | true | نقل SL إلى التعادل |
| `InpBreakEvenTriggerPoints` / `InpBreakEvenLockPoints` | 20 / 2 | شروط ونقاط التثبيت |
| `InpTrailingStop` / `InpTrailingStartPoints` / `InpTrailingStepPoints` | true / 30 / 10 | مطاردة الوقف |
| `InpPartialClose` | false | إغلاق جزئي |
| `InpPartialClosePercent` / `InpPartialCloseTriggerPoints` | 50 / 40 | نسبة ونقاط الإغلاق الجزئي |
| `InpMaxBarsInTrade` | 0 | أقصى شموع للصفقة (0=بدون) |
| `InpUseStopLevelCheck` | true | التحقق من Stops/Freeze Level |

> لا يحرّك البوت SL بعيداً عن السعر أبداً.

---

## 7. التسجيل واللوحة
| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpWriteJournalCSV` / `InpJournalCSVName` | true / `SMC_ICT_Pro_V2_Journal.csv` | سجل CSV |
| `InpLogLevel` | INFO | مستوى التسجيل |
| `InpShowDashboard` | true | لوحة المراقبة |
| `InpDashboardCorner` | 1 | ركن اللوحة |

---

## 8. معمارية AI-SMC/ICT (المطابقة للملف المرجعي)

| المرحلة | الإطار | ما يُنفَّذ |
|---|---|---|
| **1. التوجه اليومي (Daily Bias)** | `InpDailyBiasTF` = D1 | إغلاق الشمعة اليومية + الإزاحة الشمعية (Desplazamiento) |
| **2. قوة الثلاثة (PO3)** | `InpPO3StructureTF` = H4 و`InpPO3AccumTF` = M30 | تراكم (Accumulation) → تلاعب (Manipulation) → كنس السيولة |
| **3. تأكيد SMC** | `InpSMCConfirmTF` = H1 | انتظار إغلاق الشمعة + CHoCH/MSS + منطقة Bullish/Bearish FVG |
| **4. محرك الدخول (Sniper Entry)** | `InpEntryTF` = M1 | تأكيد CISD على M1 داخل منطقة FVG |

| الإعداد | الافتراضي | الوظيفة |
|---|---|---|
| `InpDailyBiasTF` | D1 | إطار التوجه اليومي |
| `InpPO3StructureTF` | H4 | إطار هيكل PO3 |
| `InpPO3AccumTF` | M30 | إطار مراقبة التراكم/التلاعب |
| `InpSMCConfirmTF` | H1 | إطار تأكيد SMC |
| `InpEntryTF` | M1 | إطار محرك الدخول |
| `InpPO3AccumBars` | 12 | عدد شموع نطاق التراكم |
| `InpPO3RangeATRFactor` | 1.6 | أقصى اتساع نطاق التراكم |
| `InpSwingLookback` | 3 | شموع حول القمم/القيعان (CHoCH/MSS) |
| `InpSwingScanBars` | 45 | مسح بنية H1 |
| `InpEqualTolerancePercent` | 0.05 | تسامح السيولة المتساوية |
| `InpTargetRR` | 2 | **R:R المستهدفة (1:2 / 1:3 / 1:4 كحد أقصى)** |
| `InpRequireBullishFVG` | true | اشتراط FVG على H1 |

### نقاط الدخول والخروج بدقة (حسب الملف)
- **دخول شراء:** DailyBias صاعد → PO3: كنس قيعان (Manipulation) → H1: CHoCH/MSS + Bullish FVG → M1: CISD، مع السعر داخل منطقة FVG.
- **دخول بيع:** DailyBias هابط → PO3: كنس قمم → H1: CHoCH/MSS + Bearish FVG → M1: CISD داخل FVG.
- **Stop Loss:** أسفل **السيولة الحقيقية** (أسفل نطاق الكنس/منطقة FVG).
- **Take Profit:** عند **السيولة التالية** أو نطاق العائد R:R — أقصى 1:4.
- **Anti-Trap Filter:** لا دخول إلا إذا مسح التلاعب سيولة حقيقية ثم تأكد الانعكاس.

---

## 9. Comment و Magic (مهم جداً)
- MT5 **لا يحفظ اسم ملف البوت** في الصفقة؛ يحفظ فقط **Magic** و**Comment ≤ 31 حرفاً**.
- البوت يستخدم `MQLInfoString(MQL_PROGRAM_NAME)` ثم يزيل `.ex5` ويقصّ إلى 31 حرفاً ويضعها في تعليق كل صفقة جديدة.

---

## 10. قائمة تحقق قبل الحساب الحقيقي
- [ ] Baseline: `Every tick based on real ticks`
- [ ] عمولة + سبريد + سواب + انزلاق واقعية
- [ ] صافي الربح موجب بعد التكاليف
- [ ] Max Drawdown ضمن الحد المخطط
- [ ] لا Martingale ولا Grid غير محدود
- [ ] حدود يومية/أسبوعية/سلسلة خسائر مفعّلة
- [ ] Stress Test لم ينهار
- [ ] Forward Test سليم
- [ ] Demo 4–8 أسابيع ومقارنة
- [ ] حجم بداية محافظ (0.01 لوت أو 0.5–1%)
