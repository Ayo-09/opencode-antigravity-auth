# دليل التركيب — AETHERION على MetaTrader 5

## أ) نسخ الملفات

من مجلد الحزمة:

```
aetherion/MQL5/Experts/Aetherion/   →   <Data Folder>/MQL5/Experts/Aetherion/
aetherion/Presets/*.set             →   <Data Folder>/MQL5/Presets/
```

افتح مجلد البيانات من MT5: **ملف → فتح مجلد البيانات**.

## ب) الترجمة

1. افتح `Aetherion.mq5` في MetaEditor (`F4`).
2. اضغط `F7`.
3. يجب أن تظهر: `0 error(s)`.  
   إن ظهر `include not found` تأكد أن الملفات الثلاثة في نفس المجلد.

## ج) صلاحيات التداول الآلي

1. أدوات → خيارات → المستشارون الخبراء  
2. علّم: السماح بالتداول الآلي  
3. لا حاجة لاستيراد DLL  
4. أغلق النافذة ثم اضغط زر **Algo Trading** حتى يصبح أخضر

## د) التشغيل على أي شارت

البوت لا يحتاج اختيار رمز مسبقاً:

- افتح BTCUSDT M15 أو XAUUSD H1 أو EURUSD M5 أو US30 H4 أو سهم AAPL  
- اسحب AETHERION  
- في التبويب **المدخلات** اضغط **تحميل** واختر الملف المناسب  
- اضغط موافق  

ستظهر لوحة AETHERION في الزاوية وتعرض:

`الرمز · الإطار · فئة الأصل · السبريد الحي · READY`

## هـ) المختبر

Strategy Tester → الخبير `Aetherion`  
النموذج: **Every tick based on real ticks**  
الإيداع: 10 000  
التحميل: `Aetherion_Default.set`  
بعد الانتهاء: تقرير → حفظ HTML ثم اسحبه إلى محاكي `simulator/` لقراءته على الرسم.

## و) المحاكاة الفنية

من جذر الحزمة:

```
python3 simulator/server.py
```

ثم افتح العنوان الذي يطبعه الخادم.
