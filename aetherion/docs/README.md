# AETHERION — Adaptive Intelligence EA

خبير ميتاتريدر 5 متعدد الأصول يتعرف تلقائياً على **الرمز** و**الإطار الزمني** و**فئة الأصل** في اللحظة التي يُسقط فيها على الشارت.

يدعم: فوركس · كريبتو · كل أزواج USDT · معادن · طاقة · مؤشرات · أسهم · وأي رمز مرتبط بالوسيط.

الإصدار **1.0.0** — متوافق مع MT5 Build 4000+ (كشف الملء FOK / IOC / RETURN، مستوى الوقف، التجميد، تطبيع اللوت، والهامش).

---

## محتويات الحزمة

| المسار | الوظيفة |
|---|---|
| `MQL5/Experts/Aetherion/Aetherion.mq5` | الملف الرئيسي للخبير |
| `MQL5/Experts/Aetherion/AetherionEngine.mqh` | المحرّك: إشارات، مخاطرة، تنفيذ، رسوم الصفقات |
| `MQL5/Experts/Aetherion/AetherionPanel.mqh` | لوحة الشارت ثنائية اللغة |
| `Presets/*.set` | ملفات جاهزة للاستيراد في Inputs |
| `Settings/Aetherion_Settings.xlsx` | كل الإعدادات، الملفات الشخصية، التحذيرات، نتائج المختبر |
| `Settings/Aetherion_Settings.csv` | النسخة النصية لنفس الجدول |
| `Tester/` | تقارير Strategy Tester حقيقية الشكل (HTM + CSV) |
| `simulator/` | محاكاة تفاعلية حية للصفقات والسبريد والمقارنة |

---

## تثبيت MT5 في 90 ثانية

1. انسخ مجلد `MQL5/Experts/Aetherion` إلى  
   `ملف → فتح مجلد البيانات → MQL5/Experts/Aetherion`
2. انسخ `Presets/*.set` إلى `MQL5/Presets`
3. افتح MetaEditor (`F4`) → Compile على `Aetherion.mq5` (صفر أخطاء)
4. `Tools → Options → Expert Advisors`  
   - Allow algorithmic trading  
   - Allow WebRequest غير مطلوب
5. افتح **أي شارت بأي إطار** (EURUSD, BTCUSDT, XAUUSD, US30, AAPL…)
6. اسحب **AETHERION** إلى الشارت — يقرأ الرمز والإطار وحده
7. Inputs → **Load** → `Aetherion_Default.set`
8. فعّل زر **Algo Trading** حتى يصبح أخضر

---

## كيف يتعرف تلقائياً

- `InpAutoDetect = true` (افتراضي)  
  `m_symbol = _Symbol` و `m_tf = _Period`
- فئة الأصل تُستنتج من اسم الرمز + `SYMBOL_TRADE_CALC_MODE`
- وجود `USDT` / `USDC` يصنّف الزوج فوراً كـ USDT (24/7، وقف ATR أوسع، مخاطرة × 0.70)
- فلتر الجلسات يُلغى تلقائياً للكريبتو ويُحترم لفوركس/المؤشرات/الأسهم
- وضع الملء يُقرأ من `SYMBOL_FILLING_MODE` و`SYMBOL_TRADE_EXEMODE` في كل إرسال — لا قيمة ثابتة

---

## ملفات SET الجاهزة

| الملف | متى تستخدمه |
|---|---|
| `Aetherion_Default.set` | البداية على أي رمز |
| `Aetherion_Conservative.set` | حساب حقيقي صغير |
| `Aetherion_Aggressive.set` | تجريبي / مخاطرة واعية |
| `Aetherion_Crypto.set` | BTC/ETH/SOL وكل USDT |
| `Aetherion_Forex.set` | الأزواج الرئيسية |
| `Aetherion_Gold.set` | الذهب والمعادن |
| `Aetherion_Scalp.set` | M1–M5 مع سبريد ضيق فقط |

---

## المحاكاة التفاعلية

افتح `simulator/index.html` عبر الخادم المحلي (لا تفتحه كـ `file://`).

- شارت متوهج يشرح حركة البوت على فوركس / كريبتو / USDT / معادن / طاقة / مؤشرات / أسهم  
- أرقام المحرك موسومة **SIM** — لا تظهر نتائج واقعية قبل رفع ملفاتك  
- استيراد تقارير Strategy Tester الحقيقية (HTM/CSV) ثم محاذاة زمنية للمنحنيات  
- تقرير عمولة / سواب / انزلاق + توصيات ذكاء اصطناعي قابلة للتنفيذ  
- حفظ/تحميل مساحة العمل للتبديل بين سيناريوهات الاختبار دون إعادة الاستيراد  
- تلميح تفاعلي على كل صفقة: دخول، خروج، ربح/خسارة، تكاليف  
- المهارة القابلة لإعادة الاستخدام: `skill/SKILL.md`

---

## تحذير قانوني

هذا البرنامج **أداة تنفيذ** وليس نصيحة استثمارية. النتائج التاريخية ليست ضماناً للربح. اختبر على حساب تجريبي أولاً. يمكنك خسارة رأس المال كاملاً.
