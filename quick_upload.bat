@echo off
echo ========================================
echo رفع نظام الشهداء على GitHub
echo ========================================
echo.

echo أدخل اسم المستخدم على GitHub:
set /p username="Username: "

echo أدخل اسم الـ Repository (اتركه فارغ للاستخدام الافتراضي: martyr-system):
set /p reponame="Repository name: "

if "%reponame%"=="" set reponame=martyr-system

echo.
echo جاري الربط والرفع...
git remote add origin https://github.com/%username%/%reponame%.git
git push -u origin main

echo.
echo ========================================
echo تم الرفع بنجاح!
echo رابط المشروع: https://github.com/%username%/%reponame%
echo ========================================
pause