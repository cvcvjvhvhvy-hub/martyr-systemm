import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/content.dart';
import '../models/notification_item.dart';
import '../models/complaint.dart';
import '../models/admin_account.dart';
import '../models/audit_entry.dart';
import '../models/complaint_event.dart';

class MockService {
  static final MockService _instance = MockService._internal();
  factory MockService() => _instance;
  MockService._internal() {
    // seed some data
    _users = [
      User(id: '1', name: 'Ali', email: 'ali@example.com', role: 'admin'),
      User(id: '2', name: 'Sara', email: 'sara@example.com', role: 'editor'),
    ];
    _contents = [
      ContentItem(id: 'c1', title: 'مرحباً', body: 'هذه مقالة تجريبية', published: true),
    ];
    _notifications = [
      NotificationItem(id: Uuid().v4(), message: 'نظام: تم إنشاء اللوحة التجريبية'),
    ];
    _complaints = [
      Complaint(id: 't1', title: 'مشكلة تسجيل', body: 'لا يمكنني تسجيل الدخول', reporterId: '2', priority: 'high'),
    ];
    _admins = [
      AdminAccount(id: 'a1', name: 'Super', email: 'super@admin.com', role: 'superadmin', permissions: ['all']),
    ];
    _audits = [];
  }

  late List<User> _users;
  late List<ContentItem> _contents;
  final Map<String, List<ContentItem>> _contentHistory = {};
  late List<NotificationItem> _notifications;
  late List<Complaint> _complaints;
  late List<AdminAccount> _admins;
  late List<AuditEntry> _audits;

  // simple current admin id (placeholder)
  String currentAdminId() => _admins.isNotEmpty ? _admins.first.id : 'a1';

  AdminAccount? getAdminById(String id) => _admins.firstWhere((a) => a.id == id, orElse: () => _admins.isNotEmpty ? _admins.first : AdminAccount(id: 'unknown', name: 'Unknown', email: '', permissions: []));

  bool hasPermission(String adminId, String permission) {
    final a = _admins.firstWhere((x) => x.id == adminId, orElse: () => AdminAccount(id: 'unknown', name: 'Unknown', email: '', permissions: []));
    if (a.permissions.contains('all')) return true;
    return a.permissions.contains(permission);
  }

  Future<List<User>> fetchUsers() async => Future.delayed(Duration(milliseconds: 200), () => List.from(_users));
  Future<void> addUser(User u) async => Future.delayed(Duration(milliseconds: 200), () => _users.add(u));
  Future<void> updateUser(User u) async => Future.delayed(Duration(milliseconds: 200), () {
        final idx = _users.indexWhere((x) => x.id == u.id);
        if (idx != -1) _users[idx] = u;
      });
  Future<void> deleteUser(String id) async => Future.delayed(Duration(milliseconds: 200), () => _users.removeWhere((u) => u.id == id));

  Future<List<ContentItem>> fetchContents() async => Future.delayed(Duration(milliseconds: 200), () => List.from(_contents));
  Future<void> addContent(ContentItem c) async => Future.delayed(Duration(milliseconds: 200), () => _contents.add(c));
  Future<void> updateContent(ContentItem c) async => Future.delayed(Duration(milliseconds: 200), () {
        final idx = _contents.indexWhere((x) => x.id == c.id);
        if (idx != -1) {
          // push previous version to history
          final prev = _contents[idx];
          _contentHistory.putIfAbsent(prev.id, () => []).insert(0, prev);
          _contents[idx] = c;
        }
      });
  Future<List<ContentItem>> fetchContentHistory(String id) async => Future.delayed(Duration(milliseconds: 200), () => List.from(_contentHistory[id] ?? []));
  Future<void> deleteContent(String id) async => Future.delayed(Duration(milliseconds: 200), () => _contents.removeWhere((c) => c.id == id));

    Future<List<NotificationItem>> fetchNotifications() async =>
      Future.delayed(Duration(milliseconds: 200), () => List.from(_notifications));
    Future<void> sendNotification(NotificationItem note) async =>
      Future.delayed(Duration(milliseconds: 200), () => _notifications.insert(0, note));
    Future<void> deleteNotification(String id) async =>
      Future.delayed(Duration(milliseconds: 200), () => _notifications.removeWhere((n) => n.id == id));

  Future<int> countUsers() async => (await fetchUsers()).length;
  Future<int> countContents() async => (await fetchContents()).length;
  Future<int> countNotifications() async => (await fetchNotifications()).length;

  // Complaints
  Future<List<Complaint>> fetchComplaints() async => Future.delayed(Duration(milliseconds: 200), () => List.from(_complaints));
  Future<void> addComplaint(Complaint c) async => Future.delayed(Duration(milliseconds: 200), () => _complaints.insert(0, c));
  Future<void> updateComplaint(Complaint c) async => Future.delayed(Duration(milliseconds: 200), () {
        final idx = _complaints.indexWhere((x) => x.id == c.id);
        if (idx != -1) _complaints[idx] = c;
      });
  Future<void> deleteComplaint(String id) async => Future.delayed(Duration(milliseconds: 200), () => _complaints.removeWhere((c) => c.id == id));

  Future<void> addAttachmentToComplaint(String complaintId, String dataUrl, {String? adminId}) async => Future.delayed(Duration(milliseconds: 200), () {
        final idx = _complaints.indexWhere((x) => x.id == complaintId);
        if (idx != -1) {
          _complaints[idx].attachments.add(dataUrl);
          _complaints[idx].updatedAt = DateTime.now();
        }
        final aid = adminId ?? currentAdminId();
        _audits.insert(0, AuditEntry(id: Uuid().v4(), adminId: aid, action: 'add_attachment', targetType: 'complaint', targetId: complaintId, details: dataUrl.length > 100 ? dataUrl.substring(0, 100) : dataUrl));
      });

  // Audit trail
  Future<void> recordAudit(AuditEntry e) async => Future.delayed(Duration(milliseconds: 100), () => _audits.insert(0, e));
  Future<List<AuditEntry>> fetchAudits() async => Future.delayed(Duration(milliseconds: 200), () => List.from(_audits));

  // Admins
  Future<List<AdminAccount>> fetchAdmins() async => Future.delayed(Duration(milliseconds: 200), () => List.from(_admins));
  Future<void> addAdmin(AdminAccount a) async => Future.delayed(Duration(milliseconds: 200), () => _admins.add(a));
  Future<void> updateAdmin(AdminAccount a) async => Future.delayed(Duration(milliseconds: 200), () {
        final idx = _admins.indexWhere((x) => x.id == a.id);
        if (idx != -1) _admins[idx] = a;
      });
  Future<void> deleteAdmin(String id) async => Future.delayed(Duration(milliseconds: 200), () => _admins.removeWhere((a) => a.id == id));
}
