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

  // Authentication
  static Future<bool> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      debugPrint('خطأ في تسجيل الدخول: $e');
      return false;
    }
  }

  static Future<bool> signUp(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await credential.user?.updateDisplayName(name);
      
      // Add user to users collection for admin dashboard
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'id': credential.user!.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'role': 'user',
      });
      
      return true;
    } catch (e) {
      debugPrint('خطأ في إنشاء الحساب: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Upload Image
  static Future<String> uploadImage(String base64Image, String path) async {
    try {
      if (!base64Image.startsWith('data:image')) {
        return base64Image;
      }
      
      final base64String = base64Image.contains(',') ? base64Image.split(',').last : base64Image;
      final bytes = base64Decode(base64String);
      
      if (bytes.isEmpty) {
        throw Exception('صورة فارغة');
      }
      
      final ref = _storage.ref().child('images/$path/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('فشل رفع الصورة: $e');
      return base64Image;
    }
  }

  // Martyrs
  static Future<List<Martyr>> getMartyrs() async {
    try {
      final snapshot = await _firestore.collection('martyrs').orderBy('createdAt', descending: true).get();
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
      martyrData['createdBy'] = getCurrentUser()?.uid ?? 'system';
      
      await _firestore.collection('martyrs').doc(martyr.id).set(martyrData);
      
      // Log for admin dashboard
      await _logActivity('add_martyr', 'تم إضافة شهيد جديد: ${martyr.name}');
      
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
      martyrData['updatedAt'] = FieldValue.serverTimestamp();
      martyrData['updatedBy'] = getCurrentUser()?.uid ?? 'system';
      
      await _firestore.collection('martyrs').doc(martyr.id).update(martyrData);
      
      await _logActivity('update_martyr', 'تم تحديث الشهيد: ${martyr.name}');
    } catch (e) {
      debugPrint('فشل في تحديث الشهيد: $e');
      throw Exception('فشل في تحديث الشهيد: ${e.toString()}');
    }
  }

  static Future<void> deleteMartyr(String id) async {
    try {
      final doc = await _firestore.collection('martyrs').doc(id).get();
      final name = doc.data()?['name'] ?? 'غير معروف';
      
      await _firestore.collection('martyrs').doc(id).delete();
      
      await _logActivity('delete_martyr', 'تم حذف الشهيد: $name');
    } catch (e) {
      debugPrint('فشل في حذف الشهيد: $e');
      throw Exception('فشل في حذف الشهيد: ${e.toString()}');
    }
  }

  // Stances
  static Future<List<Stance>> getStances() async {
    try {
      final snapshot = await _firestore.collection('stances').orderBy('createdAt', descending: true).get();
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
      stanceData['createdAt'] = FieldValue.serverTimestamp();
      stanceData['createdBy'] = getCurrentUser()?.uid ?? 'system';
      
      await _firestore.collection('stances').doc(stance.id).set(stanceData);
      
      await _logActivity('add_stance', 'تم إضافة موقف جديد: ${stance.title}');
    } catch (e) {
      debugPrint('فشل في إضافة الموقف: $e');
      throw Exception('فشل في إضافة الموقف: ${e.toString()}');
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
      stanceData['updatedAt'] = FieldValue.serverTimestamp();
      stanceData['updatedBy'] = getCurrentUser()?.uid ?? 'system';
      
      await _firestore.collection('stances').doc(stance.id).update(stanceData);
      
      await _logActivity('update_stance', 'تم تحديث الموقف: ${stance.title}');
    } catch (e) {
      debugPrint('فشل في تحديث الموقف: $e');
      throw Exception('فشل في تحديث الموقف: ${e.toString()}');
    }
  }

  static Future<void> deleteStance(String id) async {
    try {
      final doc = await _firestore.collection('stances').doc(id).get();
      final title = doc.data()?['title'] ?? 'غير معروف';
      
      await _firestore.collection('stances').doc(id).delete();
      
      await _logActivity('delete_stance', 'تم حذف الموقف: $title');
    } catch (e) {
      debugPrint('فشل في حذف الموقف: $e');
      throw Exception('فشل في حذف الموقف: ${e.toString()}');
    }
  }

  // Crimes
  static Future<List<Stance>> getCrimes() async {
    try {
      final snapshot = await _firestore.collection('crimes').orderBy('createdAt', descending: true).get();
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
      crimeData['createdAt'] = FieldValue.serverTimestamp();
      crimeData['createdBy'] = getCurrentUser()?.uid ?? 'system';
      
      await _firestore.collection('crimes').doc(crime.id).set(crimeData);
      
      await _logActivity('add_crime', 'تم إضافة جريمة جديدة: ${crime.title}');
    } catch (e) {
      debugPrint('فشل في إضافة الجريمة: $e');
      throw Exception('فشل في إضافة الجريمة: ${e.toString()}');
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
      crimeData['updatedAt'] = FieldValue.serverTimestamp();
      crimeData['updatedBy'] = getCurrentUser()?.uid ?? 'system';
      
      await _firestore.collection('crimes').doc(crime.id).update(crimeData);
      
      await _logActivity('update_crime', 'تم تحديث الجريمة: ${crime.title}');
    } catch (e) {
      debugPrint('فشل في تحديث الجريمة: $e');
      throw Exception('فشل في تحديث الجريمة: ${e.toString()}');
    }
  }

  static Future<void> deleteCrime(String id) async {
    try {
      final doc = await _firestore.collection('crimes').doc(id).get();
      final title = doc.data()?['title'] ?? 'غير معروف';
      
      await _firestore.collection('crimes').doc(id).delete();
      
      await _logActivity('delete_crime', 'تم حذف الجريمة: $title');
    } catch (e) {
      debugPrint('فشل في حذف الجريمة: $e');
      throw Exception('فشل في حذف الجريمة: ${e.toString()}');
    }
  }

  // Admin Dashboard Functions
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final martyrsCount = await _firestore.collection('martyrs').count().get();
      final stancesCount = await _firestore.collection('stances').count().get();
      final crimesCount = await _firestore.collection('crimes').count().get();
      final usersCount = await _firestore.collection('users').count().get();
      
      return {
        'martyrs': martyrsCount.count,
        'stances': stancesCount.count,
        'crimes': crimesCount.count,
        'users': usersCount.count,
      };
    } catch (e) {
      debugPrint('فشل في تحميل إحصائيات لوحة التحكم: $e');
      return {
        'martyrs': 0,
        'stances': 0,
        'crimes': 0,
        'users': 0,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final snapshot = await _firestore.collection('users').orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('فشل في تحميل المستخدمين: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getActivityLogs() async {
    try {
      final snapshot = await _firestore.collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('فشل في تحميل سجل الأنشطة: $e');
      return [];
    }
  }

  static Future<void> _logActivity(String action, String description) async {
    try {
      await _firestore.collection('activity_logs').add({
        'action': action,
        'description': description,
        'userId': getCurrentUser()?.uid ?? 'system',
        'userEmail': getCurrentUser()?.email ?? 'system',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('فشل في تسجيل النشاط: $e');
    }
  }

  static Future<void> sendNotification(String title, String message, String type) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': getCurrentUser()?.uid ?? 'system',
      });
    } catch (e) {
      debugPrint('فشل في إرسال الإشعار: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final snapshot = await _firestore.collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('فشل في تحميل الإشعارات: $e');
      return [];
    }
  }
}