# إعداد Firebase مطلوب

## خطوات إعداد Firebase

1. **إنشاء مشروع Firebase**:
   - اذهب إلى [Firebase Console](https://console.firebase.google.com/)
   - أنشئ مشروع جديد باسم "martyr-system"

2. **إضافة تطبيق Android**:
   - اضغط على "Add app" واختر Android
   - أدخل package name: `com.example.martyr_system`
   - حمل ملف `google-services.json`

3. **استبدال الملف**:
   - احذف الملف الحالي: `android/app/google-services.json`
   - ضع الملف الجديد في نفس المكان

4. **تفعيل الخدمات**:
   - Authentication (Email/Password)
   - Firestore Database
   - Storage

## ملاحظة مهمة
الملف الحالي `google-services.json` يحتوي على بيانات تجريبية ولن يعمل مع Firebase الحقيقي.