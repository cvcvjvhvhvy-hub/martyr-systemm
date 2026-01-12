# إعداد Firebase لتطبيق نظام الشهداء

## خطوات الإعداد

### 1. إنشاء مشروع Firebase
1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. انقر على "إنشاء مشروع" أو "Add project"
3. أدخل اسم المشروع: `martyr-system-app`
4. اختر الإعدادات المناسبة وأكمل الإعداد

### 2. إضافة تطبيق Android
1. في لوحة تحكم Firebase، انقر على أيقونة Android
2. أدخل package name: `com.example.martyr_system`
3. أدخل اسم التطبيق: `نظام الشهداء`
4. حمل ملف `google-services.json`
5. ضع الملف في مجلد `android/app/`

### 3. تفعيل الخدمات المطلوبة

#### Authentication
1. اذهب إلى Authentication > Sign-in method
2. فعل Email/Password
3. أضف مستخدم تجريبي:
   - Email: `admin@martyrsystem.com`
   - Password: `123456`

#### Firestore Database
1. اذهب إلى Firestore Database
2. انقر على "Create database"
3. اختر "Start in test mode" للبداية
4. اختر الموقع الجغرافي المناسب

#### Storage
1. اذهب إلى Storage
2. انقر على "Get started"
3. اختر "Start in test mode"
4. اختر الموقع الجغرافي المناسب

### 4. قواعد الأمان (Security Rules)

#### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // السماح للمستخدمين المصادق عليهم فقط
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. هيكل قاعدة البيانات

#### Collections المطلوبة:
- `martyrs` - بيانات الشهداء
- `stances` - المواقف التاريخية  
- `crimes` - الجرائم الموثقة

#### مثال على وثيقة في martyrs:
```json
{
  "id": "1640995200000",
  "name": "أحمد محمد علي",
  "title": "البطل الشهيد",
  "birthDate": "1990-05-15",
  "martyrdomDate": "2021-12-31",
  "cause": "في سبيل الوطن",
  "rank": "نقيب",
  "job": "ضابط مشاة",
  "battles": "معركة الكرامة,عملية السلام",
  "bio": "شهيد بطل ضحى بحياته من أجل الوطن...",
  "imageUrl": "https://firebasestorage.googleapis.com/..."
}
```

### 6. تشغيل التطبيق

```bash
# تثبيت المكتبات
flutter pub get

# تشغيل التطبيق
flutter run
```

### 7. بيانات الدخول

#### Firebase Authentication:
- Email: `admin@martyrsystem.com`
- Password: `123456`

#### Local Fallback:
- Username: `admin`
- Password: `123456`

## ملاحظات مهمة

1. **استبدل ملف google-services.json** بالملف الحقيقي من مشروعك
2. **غير package name** في `android/app/build.gradle` إذا لزم الأمر
3. **فعل الخدمات المطلوبة** في Firebase Console
4. **اضبط قواعد الأمان** حسب احتياجاتك
5. **أضف مستخدمين** في Authentication

## استكشاف الأخطاء

### خطأ في التهيئة:
- تأكد من وجود `google-services.json` في المكان الصحيح
- تأكد من تطابق package name

### خطأ في المصادقة:
- تأكد من تفعيل Email/Password في Firebase
- تأكد من إضافة المستخدم التجريبي

### خطأ في قاعدة البيانات:
- تأكد من إنشاء Firestore Database
- تأكد من قواعد الأمان

## الدعم الفني

للمساعدة في إعداد Firebase:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)