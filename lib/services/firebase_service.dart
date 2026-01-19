import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/models.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // متغيرات لحفظ بيانات التحقق
  static String? _verificationId;
  static int? _resendToken;
  static String? _pendingName;
  static String? _pendingPassword;
  static String? _pendingPhoneNumber;

  // ========== Phone Authentication ==========

  /// إرسال OTP للتسجيل
  static Future<bool> signUp(
    String phoneNumber,
    String name,
    String password, {
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      // حفظ البيانات مؤقتاً
      _pendingName = name;
      _pendingPassword = password;
      _pendingPhoneNumber = phoneNumber;

      debugPrint('🔵 إرسال OTP إلى: $phoneNumber');

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ فشل التحقق: ${e.code} - ${e.message}');

          if (e.code == 'invalid-phone-number') {
            debugPrint('رقم الهاتف غير صحيح');
          } else if (e.code == 'too-many-requests') {
            debugPrint('تم تجاوز عدد المحاولات');
          }
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ تم إرسال الكود بنجاح');
          debugPrint('Verification ID: $verificationId');

          _verificationId = verificationId;
          _resendToken = resendToken;

          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ انتهى وقت القراءة التلقائية');
          _verificationId = verificationId;

          onCodeAutoRetrievalTimeout(verificationId);
        },
      );

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في signUp: $e');
      return false;
    }
  }

  /// التحقق من OTP
  static Future<bool> verifyOtp(String otp) async {
    try {
      if (_verificationId == null) {
        debugPrint('❌ لا يوجد verification ID');
        return false;
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      debugPrint('✅ تم التحقق من OTP بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ فشل التحقق من OTP: $e');
      return false;
    }
  }

  /// إكمال عملية التسجيل بعد التحقق
  static Future<bool> _completeSignUp(
    PhoneAuthCredential credential,
    String name,
    String password,
    String phoneNumber,
  ) async {
    try {
      // تسجيل الدخول بالـ credential
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        debugPrint('✅ تم تسجيل الدخول بنجاح');

        // حفظ بيانات المستخدم في Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'phoneNumber': phoneNumber,
          'password': password, // ملاحظة: من الأفضل تشفير كلمة المرور
          'createdAt': FieldValue.serverTimestamp(),
        });

        // تحديث اسم المستخدم
        await userCredential.user!.updateDisplayName(name);

        debugPrint('✅ تم حفظ بيانات المستخدم في Firestore');

        // مسح البيانات المؤقتة
        _clearPendingData();

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ خطأ في _completeSignUp: $e');
      return false;
    }
  }

  /// إعادة إرسال OTP
  static Future<bool> resendOtp({
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      if (_pendingPhoneNumber == null) {
        debugPrint('❌ لا يوجد رقم هاتف محفوظ');
        return false;
      }

      debugPrint('🔵 إعادة إرسال OTP إلى: $_pendingPhoneNumber');

      await _auth.verifyPhoneNumber(
        phoneNumber: _pendingPhoneNumber!,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken, // استخدام الـ token لإعادة الإرسال

        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      );

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في إعادة الإرسال: $e');
      return false;
    }
  }

  /// تسجيل الدخول
  static Future<bool> signIn(String phoneNumber, String password) async {
    try {
      debugPrint('🔵 محاولة تسجيل الدخول: $phoneNumber');

      // البحث عن المستخدم في Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .where('password', isEqualTo: password)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        debugPrint('✅ تم العثور على المستخدم');
        return true;
      } else {
        debugPrint('❌ رقم الهاتف أو كلمة المرور غير صحيحة');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل الدخول: $e');
      return false;
    }
  }

  /// تسجيل الخروج
  static Future<void> signOut() async {
    await _auth.signOut();
    _clearPendingData();
  }

  /// الحصول على المستخدم الحالي
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// مسح البيانات المؤقتة
  static void _clearPendingData() {
    _verificationId = null;
    _resendToken = null;
    _pendingName = null;
    _pendingPassword = null;
    _pendingPhoneNumber = null;
  }

  // ========== Image Upload ==========

  static Future<String> uploadImage(String base64Image, String path) async {
    try {
      if (!base64Image.startsWith('data:image')) {
        return base64Image;
      }

      final base64String =
          base64Image.contains(',') ? base64Image.split(',').last : base64Image;
      final bytes = base64Decode(base64String);

      if (bytes.isEmpty) {
        throw Exception('صورة فارغة');
      }

      final ref = _storage
          .ref()
          .child('images/$path/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask =
          ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('فشل رفع الصورة: $e');
      return base64Image;
    }
  }

  // ========== Martyrs ==========

  static Future<List<Martyr>> getMartyrs() async {
    try {
      final snapshot = await _firestore
          .collection('martyrs')
          .orderBy('id', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Martyr.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('فشل تحميل الشهداء: $e');
      return [];
    }
  }

  static Future<void> addMartyr(Martyr martyr) async {
    try {
      String imageUrl = martyr.imageUrl;
      if (martyr.imageUrl.startsWith('data:image')) {
        imageUrl = await uploadImage(martyr.imageUrl, 'martyrs');
      }

      final martyrData = martyr.toMap();
      martyrData['imageUrl'] = imageUrl;
      martyrData['createdAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('martyrs').doc(martyr.id).set(martyrData);
      debugPrint('تم إضافة الشهيد بنجاح: ${martyr.name}');
    } catch (e) {
      debugPrint('فشل في إضافة الشهيد: $e');
      throw Exception('فشل في إضافة الشهيد: ${e.toString()}');
    }
  }

  static Future<void> updateMartyr(Martyr martyr) async {
    try {
      String imageUrl = martyr.imageUrl;
      if (martyr.imageUrl.startsWith('data:image')) {
        imageUrl = await uploadImage(martyr.imageUrl, 'martyrs');
      }

      final martyrData = martyr.toMap();
      martyrData['imageUrl'] = imageUrl;

      await _firestore.collection('martyrs').doc(martyr.id).update(martyrData);
    } catch (e) {
      throw Exception('فشل في تحديث الشهيد');
    }
  }

  static Future<void> deleteMartyr(String id) async {
    try {
      await _firestore.collection('martyrs').doc(id).delete();
    } catch (e) {
      throw Exception('فشل في حذف الشهيد');
    }
  }

  // ========== Stances ==========

  static Future<List<Stance>> getStances() async {
    try {
      final snapshot = await _firestore
          .collection('stances')
          .orderBy('id', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Stance.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('فشل تحميل المواقف: $e');
      return [];
    }
  }

  static Future<void> addStance(Stance stance) async {
    try {
      String imageUrl = stance.imageUrl;
      if (stance.imageUrl.startsWith('data:image')) {
        imageUrl = await uploadImage(stance.imageUrl, 'stances');
      }

      final stanceData = stance.toMap();
      stanceData['imageUrl'] = imageUrl;

      await _firestore.collection('stances').doc(stance.id).set(stanceData);
    } catch (e) {
      throw Exception('فشل في إضافة الموقف');
    }
  }

  static Future<void> updateStance(Stance stance) async {
    try {
      String imageUrl = stance.imageUrl;
      if (stance.imageUrl.startsWith('data:image')) {
        imageUrl = await uploadImage(stance.imageUrl, 'stances');
      }

      final stanceData = stance.toMap();
      stanceData['imageUrl'] = imageUrl;

      await _firestore.collection('stances').doc(stance.id).update(stanceData);
    } catch (e) {
      throw Exception('فشل في تحديث الموقف');
    }
  }

  static Future<void> deleteStance(String id) async {
    try {
      await _firestore.collection('stances').doc(id).delete();
    } catch (e) {
      throw Exception('فشل في حذف الموقف');
    }
  }

  // ========== Crimes ==========

  static Future<List<Stance>> getCrimes() async {
    try {
      final snapshot = await _firestore
          .collection('crimes')
          .orderBy('id', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Stance.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('فشل تحميل الجرائم: $e');
      return [];
    }
  }

  static Future<void> addCrime(Stance crime) async {
    try {
      String imageUrl = crime.imageUrl;
      if (crime.imageUrl.startsWith('data:image')) {
        imageUrl = await uploadImage(crime.imageUrl, 'crimes');
      }

      final crimeData = crime.toMap();
      crimeData['imageUrl'] = imageUrl;

      await _firestore.collection('crimes').doc(crime.id).set(crimeData);
    } catch (e) {
      throw Exception('فشل في إضافة الجريمة');
    }
  }

  static Future<void> updateCrime(Stance crime) async {
    try {
      String imageUrl = crime.imageUrl;
      if (crime.imageUrl.startsWith('data:image')) {
        imageUrl = await uploadImage(crime.imageUrl, 'crimes');
      }

      final crimeData = crime.toMap();
      crimeData['imageUrl'] = imageUrl;

      await _firestore.collection('crimes').doc(crime.id).update(crimeData);
    } catch (e) {
      throw Exception('فشل في تحديث الجريمة');
    }
  }

  static Future<void> deleteCrime(String id) async {
    try {
      await _firestore.collection('crimes').doc(id).delete();
    } catch (e) {
      throw Exception('فشل في حذف الجريمة');
    }
  }
}
