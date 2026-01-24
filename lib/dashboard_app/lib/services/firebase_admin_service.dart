import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../models/content.dart';
import '../models/notification_item.dart';
import '../models/audit_entry.dart';

class FirebaseAdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Dashboard Stats
  static Future<Map<String, int>> getDashboardStats() async {
    try {
      final martyrsCount = await _firestore.collection('martyrs').count().get();
      final stancesCount = await _firestore.collection('stances').count().get();
      final crimesCount = await _firestore.collection('crimes').count().get();
      final usersCount = await _firestore.collection('users').count().get();
      
      return {
        'martyrs': martyrsCount.count ?? 0,
        'stances': stancesCount.count ?? 0,
        'crimes': crimesCount.count ?? 0,
        'users': usersCount.count ?? 0,
      };
    } catch (e) {
      return {
        'martyrs': 0,
        'stances': 0,
        'crimes': 0,
        'users': 0,
      };
    }
  }

  // Users Management
  static Future<List<AppUser>> getUsers() async {
    try {
      final snapshot = await _firestore.collection('users')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppUser(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          isActive: data['isActive'] ?? true,
          role: data['role'] ?? 'user',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await _logActivity(
        'update_user_status',
        'تم ${isActive ? 'تفعيل' : 'إلغاء تفعيل'} المستخدم: $userId'
      );
    } catch (e) {
      throw Exception('فشل في تحديث حالة المستخدم');
    }
  }

  // Content Management
  static Future<List<Content>> getContent(String type) async {
    try {
      final snapshot = await _firestore.collection(type)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Content(
          id: doc.id,
          title: data['title'] ?? data['name'] ?? '',
          description: data['subtitle'] ?? data['bio'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          type: type,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> deleteContent(String type, String id) async {
    try {
      await _firestore.collection(type).doc(id).delete();
      
      await _logActivity(
        'delete_content',
        'تم حذف محتوى من $type: $id'
      );
    } catch (e) {
      throw Exception('فشل في حذف المحتوى');
    }
  }

  // Notifications Management
  static Future<List<NotificationItem>> getNotifications() async {
    try {
      final snapshot = await _firestore.collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return NotificationItem(
          id: doc.id,
          title: data['title'] ?? '',
          message: data['message'] ?? '',
          type: data['type'] ?? 'info',
          isRead: data['isRead'] ?? false,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      return [];
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
        'createdBy': _auth.currentUser?.uid ?? 'admin',
      });
      
      await _logActivity(
        'send_notification',
        'تم إرسال إشعار: $title'
      );
    } catch (e) {
      throw Exception('فشل في إرسال الإشعار');
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث الإشعار');
    }
  }

  // Activity Logs
  static Future<List<AuditEntry>> getActivityLogs() async {
    try {
      final snapshot = await _firestore.collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AuditEntry(
          id: doc.id,
          action: data['action'] ?? '',
          description: data['description'] ?? '',
          userId: data['userId'] ?? '',
          userEmail: data['userEmail'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _logActivity(String action, String description) async {
    try {
      await _firestore.collection('activity_logs').add({
        'action': action,
        'description': description,
        'userId': _auth.currentUser?.uid ?? 'admin',
        'userEmail': _auth.currentUser?.email ?? 'admin',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silent fail for logging
    }
  }

  // System Settings
  static Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('system').get();
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  static Future<void> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      await _firestore.collection('settings').doc('system').set(settings, SetOptions(merge: true));
      
      await _logActivity(
        'update_settings',
        'تم تحديث إعدادات النظام'
      );
    } catch (e) {
      throw Exception('فشل في تحديث الإعدادات');
    }
  }
}