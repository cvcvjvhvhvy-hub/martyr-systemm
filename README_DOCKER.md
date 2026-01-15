دليل بناء APK باستخدام Docker
===============================

ملخص
- هذا الملف يشرح كيفية استخدام `docker_single_file.sh` و`docker_build.sh` داخل مجلد المشروع `flutter_app` لبناء ملف `app-release.apk` داخل حاوية Docker.

متطلبات
- Docker مُثبت على الجهاز (Docker Desktop على Windows/Mac أو Docker Engine على Linux).
- اتصال إنترنت لتحميل صورة Docker وحزم Flutter.
- مساحة قرص كافية (20+ جيجابايت ينصح به).

استخدام (سكريبت ملف واحد)
1. انتقل إلى مجلد `flutter_app`.
2. اجعل السكربت قابلًا للتنفيذ ثم شغّله:

```bash
chmod +x docker_single_file.sh
./docker_single_file.sh
```

- عند النجاح سيُنتج ملف `app-release.apk` في نفس المجلد `flutter_app/app-release.apk`.

استخدام (Dockerfile + helper)
1. بدلاً من السكربت أحادي الملف يمكنك استخدام `docker_build.sh`:

```bash
chmod +x docker_build.sh
./docker_build.sh
```

ملاحظات حول `local.properties` و Android SDK
- ملفات `local.properties` مستبعدة من صورة Docker. السكربت يستخدم صورة تحتوي Flutter + Android SDK (`ghcr.io/cirrusci/flutter:stable`).
- السكربت يحاول قبول تراخيص Android تلقائيًا (`sdkmanager --licenses`) لكنه قد يفشل بالاعتماد على الصورة. في حالة فشل البناء، شغّل الحاوية تفاعليًا لتثبيت مكونات Android المطلوبة أو استخدم صورة مخصصة.

توقيع الـ APK (Release signing)
- السكربت يبني APK بصيغة release لكن يستخدم إعدادات التوقيع الموجودة في المشروع. حالياً `android/app/build.gradle` يستخدم `signingConfigs.debug` للاختبار.
- لنشر التطبيق على متجر Google Play تحتاج إلى keystore خاص:
  - ضع ملف `keystore` داخل `android/app` أو مُمكن تزود السكربت بمفتاح عبر متغيرات بيئية/CI.
  - عدّل `android/key.properties` و `android/app/build.gradle` لقراءة معلومات keystore.
- أستطيع إضافة دعم تمرير keystore إلى Docker عند الطلب.

نصائح CI (Codemagic أو GitHub Actions)
- أبسط خيار: استخدم نفس سكربت Docker داخل CI (تشغيل السكربت سيبني APK داخل الحاوية).
- بدلاً من ذلك، في Codemagic ضُمّن Flutter وAndroid SDK في إعدادات الـ workflow أو استعمل صورة Docker مُسبقًا مع SDK.

استكشاف الأخطاء
- إذا لم يتم العثور على `app-release.apk`:
  - افتح سجلات البناء داخل الحاوية: شغّل الحاوية تفاعليًا (`docker run -it --entrypoint /bin/bash <image>`) ثم افحص `/app/build`.
  - تحقق من أن `flutter build apk` لم يفشل بسبب تراخيص أو مكونات مفقودة.

أمن وخصوصية
- تأكد من إزالة أو تغيير بيانات الدخول التجريبية (`admin/123456`) قبل نشر التطبيق.
- لا تضع مفاتيح Keystore أو أسرار Firebase مباشرة في المستودع العام.

هل تريدني:
- إضافة دعم توقيع الـ APK داخل السكربت (تمرير keystore عبر متغيرات)؟
- أو إنشاء مثال إعداد CI (Codemagic/ GitHub Actions) يبني باستخدام هذا السكربت؟
