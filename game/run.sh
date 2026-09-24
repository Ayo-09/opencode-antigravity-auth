#!/usr/bin/env bash
# ============================================================
#  عرش الهاوية: شظايا النور — أمر تشغيل مباشر
#  الاستخدام:  ./run.sh      (أو من جذر المشروع: ./game/run.sh)
#  ينشئ خادمًا محليًا ويفتح اللعبة في المتصفح تلقائيًا.
#  الإيقاف: Ctrl+C
# ============================================================
set -u
cd "$(dirname "$0")"

if ! command -v python3 >/dev/null 2>&1; then
  echo "⚠️  اللعبة تتطلب python3 لتشغيل الخادم المحلي." >&2
  echo "   أو افتح ملف index.html مباشرة في المتصفح." >&2
  exit 1
fi

# اختر أول منفذ حر (يبدأ من 8080 أو قيمة المتغير PORT)
START="${PORT:-8080}"
PORT=""
for p in "$START" 8081 8082 8083 8084; do
  if (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then
    exec 3>&- 2>/dev/null || true
  else
    PORT="$p"
    break
  fi
done
if [ -z "$PORT" ]; then echo "⚠️  كل المنافذ ${START}-8084 مشغولة." >&2; exit 1; fi

URL="http://localhost:$PORT"
echo ""
echo "  🔥 عرش الهاوية: شظايا النور — الفصل الأول"
echo "  ─────────────────────────────────────────"
echo "  اللعبة تعمل الآن على:  $URL"
echo "  (أوقف الخادم في أي وقت بـ Ctrl+C)"
echo ""

python3 -m http.server "$PORT" --bind 0.0.0.0 >/dev/null 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null' EXIT INT TERM

sleep 1
# افتح المتصفح تلقائيًا حسب النظام
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL" >/dev/null 2>&1 || true
elif command -v open >/dev/null 2>&1; then
  open "$URL" || true
fi

wait "$SERVER_PID"
