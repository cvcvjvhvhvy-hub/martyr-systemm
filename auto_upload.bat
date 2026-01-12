@echo off
title رفع نظام الشهداء على GitHub
color 0A

echo ========================================
echo        رفع المشروع تلقائياً
echo ========================================
echo.

echo جاري محاولة الرفع...
git push -u origin main

if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo فشل الرفع التلقائي - جرب الحلول البديلة:
    echo.
    echo 1. GitHub Desktop:
    echo    - حمل من: https://desktop.github.com
    echo    - Add Local Repository
    echo    - اختر هذا المجلد
    echo    - Publish repository
    echo.
    echo 2. VS Code:
    echo    - افتح المشروع في VS Code
    echo    - اضغط Ctrl+Shift+P
    echo    - اكتب: Git Push
    echo.
    echo 3. رفع يدوي:
    echo    - اذهب إلى: github.com/sbshsvvswhhh-crypto/martyr-system
    echo    - اضغط "upload files"
    echo    - اسحب جميع الملفات
    echo ========================================
) else (
    echo.
    echo ========================================
    echo تم الرفع بنجاح! ✅
    echo رابط المشروع:
    echo https://github.com/sbshsvvswhhh-crypto/martyr-system
    echo ========================================
)

pause