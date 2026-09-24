@echo off
rem ============================================================
rem  عرش الهاوية: شظايا النور - امر تشغيل مباشر (Windows)
rem  الاستخدام:  run.bat   ثم افتح http://localhost:8080
rem  الايقاف: Ctrl+C
rem ============================================================
cd /d "%~dp0"
start "" http://localhost:8080
python -m http.server 8080
