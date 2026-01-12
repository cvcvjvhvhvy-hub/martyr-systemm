# قاعدة البيانات - نظام الشهداء

## نظرة عامة
يستخدم التطبيق قاعدة بيانات SQLite محلية لتخزين جميع البيانات على الجهاز مباشرة دون الحاجة لاتصال بالإنترنت.

## معلومات قاعدة البيانات
- **اسم قاعدة البيانات:** `martyr_system.db`
- **الإصدار:** `1`
- **النوع:** SQLite
- **الموقع:** مجلد التطبيق المحلي

## الجداول (Tables)

### 1. جدول الشهداء (martyrs)

```sql
CREATE TABLE martyrs(
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  title TEXT NOT NULL,
  birthDate TEXT NOT NULL,
  martyrdomDate TEXT NOT NULL,
  cause TEXT NOT NULL,
  rank TEXT NOT NULL,
  job TEXT NOT NULL,
  battles TEXT NOT NULL,
  bio TEXT NOT NULL,
  imageUrl TEXT NOT NULL
)
```

#### الحقول:
| الحقل | النوع | الوصف | مطلوب |
|-------|-------|-------|--------|
| `id` | TEXT | المعرف الفريد للشهيد | ✅ |
| `name` | TEXT | اسم الشهيد الكامل | ✅ |
| `title` | TEXT | اللقب أو المنصب | ✅ |
| `birthDate` | TEXT | تاريخ الميلاد | ✅ |
| `martyrdomDate` | TEXT | تاريخ الاستشهاد | ✅ |
| `cause` | TEXT | سبب الاستشهاد | ✅ |
| `rank` | TEXT | الرتبة العسكرية | ✅ |
| `job` | TEXT | المهنة أو التخصص | ✅ |
| `battles` | TEXT | المعارك (مفصولة بفواصل) | ✅ |
| `bio` | TEXT | السيرة الذاتية | ✅ |
| `imageUrl` | TEXT | رابط أو Base64 للصورة | ✅ |

#### مثال على البيانات:
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
  "imageUrl": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ..."
}
```

### 2. جدول المواقف (stances)

```sql
CREATE TABLE stances(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  subtitle TEXT NOT NULL,
  imageUrl TEXT NOT NULL
)
```

#### الحقول:
| الحقل | النوع | الوصف | مطلوب |
|-------|-------|-------|--------|
| `id` | TEXT | المعرف الفريد للموقف | ✅ |
| `title` | TEXT | عنوان الموقف | ✅ |
| `subtitle` | TEXT | وصف مختصر للموقف | ✅ |
| `imageUrl` | TEXT | صورة توضيحية | ✅ |

#### مثال على البيانات:
```json
{
  "id": "1640995300000",
  "title": "موقف تاريخي خالد",
  "subtitle": "وصف تفصيلي للموقف التاريخي المهم",
  "imageUrl": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ..."
}
```

### 3. جدول الجرائم (crimes)

```sql
CREATE TABLE crimes(
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  subtitle TEXT NOT NULL,
  imageUrl TEXT NOT NULL
)
```

#### الحقول:
| الحقل | النوع | الوصف | مطلوب |
|-------|-------|-------|--------|
| `id` | TEXT | المعرف الفريد للجريمة | ✅ |
| `title` | TEXT | عنوان الجريمة | ✅ |
| `subtitle` | TEXT | وصف تفصيلي للجريمة | ✅ |
| `imageUrl` | TEXT | صورة توثيقية | ✅ |

#### مثال على البيانات:
```json
{
  "id": "1640995400000",
  "title": "جريمة لا تُنسى",
  "subtitle": "توثيق تفصيلي للجريمة وتأثيرها",
  "imageUrl": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ..."
}
```

## العمليات الأساسية

### إنشاء قاعدة البيانات
```dart
static Future<Database> _initDB() async {
  String path = join(await getDatabasesPath(), _dbName);
  return await openDatabase(
    path,
    version: _version,
    onCreate: _createDB,
  );
}
```

### استعلامات القراءة
```dart
// جلب جميع الشهداء
static Future<List<Martyr>> getMartyrs() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query('martyrs');
  return List.generate(maps.length, (i) => Martyr.fromMap(maps[i]));
}
```

### عمليات الإدراج
```dart
// إضافة شهيد جديد
static Future<void> insertMartyr(Martyr martyr) async {
  final db = await database;
  await db.insert('martyrs', martyr.toMap(), 
    conflictAlgorithm: ConflictAlgorithm.replace);
}
```

### عمليات الحذف
```dart
// حذف شهيد
static Future<void> deleteMartyr(String id) async {
  final db = await database;
  await db.delete('martyrs', where: 'id = ?', whereArgs: [id]);
}
```

## إدارة الصور

### تخزين الصور
- **النوع:** Base64 encoded strings
- **التنسيق:** `data:image/jpeg;base64,{base64_data}`
- **الحد الأقصى:** 800KB لكل صورة
- **المصادر:** معرض الصور، الكاميرا

### مثال على تحويل الصورة:
```dart
final bytes = await image.readAsBytes();
final base64String = base64Encode(bytes);
final imageUrl = 'data:image/jpeg;base64,$base64String';
```

## الفهرسة والأداء

### المفاتيح الأساسية
- جميع الجداول تستخدم `id` كمفتاح أساسي
- المعرفات تُولد باستخدام timestamp: `DateTime.now().millisecondsSinceEpoch.toString()`

### الترتيب
- البيانات تُرتب حسب المعرف تنازلياً (الأحدث أولاً)
- يتم الترتيب في طبقة التطبيق وليس في قاعدة البيانات

## النسخ الاحتياطي والاستعادة

### موقع قاعدة البيانات
```dart
String path = join(await getDatabasesPath(), 'martyr_system.db');
```

### النسخ الاحتياطي
- يمكن نسخ ملف `martyr_system.db` من مجلد التطبيق
- البيانات محفوظة محلياً ولا تحتاج اتصال إنترنت

## الأمان والخصوصية

### الحماية
- البيانات محفوظة محلياً على الجهاز
- لا يتم إرسال البيانات لخوادم خارجية
- الصور مشفرة بـ Base64

### الصلاحيات المطلوبة
- `READ_EXTERNAL_STORAGE`: لقراءة الصور
- `CAMERA`: لالتقاط الصور (اختياري)

## استكشاف الأخطاء

### الأخطاء الشائعة
1. **Database not initialized**: تأكد من استدعاء `DatabaseService.database` قبل العمليات
2. **Image too large**: تحقق من حجم الصورة (أقل من 800KB)
3. **Invalid Base64**: تأكد من صحة تنسيق البيانات

### التشخيص
```dart
try {
  await DatabaseService.insertMartyr(martyr);
} catch (e) {
  debugPrint('خطأ في قاعدة البيانات: $e');
}
```

## الترقية والصيانة

### ترقية قاعدة البيانات
```dart
onUpgrade: (db, oldVersion, newVersion) async {
  // إضافة حقول جديدة أو تعديل الهيكل
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE martyrs ADD COLUMN newField TEXT');
  }
}
```

### تنظيف البيانات
- حذف الصور غير المستخدمة
- ضغط قاعدة البيانات دورياً
- تنظيف البيانات المؤقتة