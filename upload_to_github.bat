@echo off
echo ========================================
echo    رفع نظام الشهداء على GitHub
echo ========================================
echo.

echo 1. تهيئة Git...
git init

echo 2. إضافة جميع الملفات...
git add .

echo 3. إنشاء أول commit...
git commit -m "🎉 Initial commit: نظام الشهداء - Flutter App"

echo 4. إعداد الفرع الرئيسي...
git branch -M main

echo.
echo ========================================
echo تم الإعداد بنجاح!
echo.
echo الخطوة التالية:
echo 1. أنشئ repository جديد على GitHub
echo 2. انسخ رابط الـ repository
echo 3. شغل الأمر التالي:
echo    git remote add origin [REPOSITORY_URL]
echo    git push -u origin main
echo ========================================
pause