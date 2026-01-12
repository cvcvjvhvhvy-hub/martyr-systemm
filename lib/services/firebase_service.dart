import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
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
      
      // Update display name
      await credential.user?.updateDisplayName(name);
      
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
      final bytes = base64Decode(base64Image.split(',').last);
      final ref = _storage.ref().child('images/$path/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch (e) {
      return base64Image; // fallback to base64
    }
  }

  // Martyrs
  static Future<List<Martyr>> getMartyrs() async {
    try {
      final snapshot = await _firestore.collection('martyrs').orderBy('id', descending: true).get();
      return snapshot.docs.map((doc) => Martyr.fromMap({...doc.data(), 'id': doc.id})).toList();
    } catch (e) {
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
      
      await _firestore.collection('martyrs').doc(martyr.id).set(martyrData);
    } catch (e) {
      throw Exception('فشل في إضافة الشهيد');
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

  // Stances
  static Future<List<Stance>> getStances() async {
    try {
      final snapshot = await _firestore.collection('stances').orderBy('id', descending: true).get();
      return snapshot.docs.map((doc) => Stance.fromMap({...doc.data(), 'id': doc.id})).toList();
    } catch (e) {
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

  // Crimes
  static Future<List<Stance>> getCrimes() async {
    try {
      final snapshot = await _firestore.collection('crimes').orderBy('id', descending: true).get();
      return snapshot.docs.map((doc) => Stance.fromMap({...doc.data(), 'id': doc.id})).toList();
    } catch (e) {
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