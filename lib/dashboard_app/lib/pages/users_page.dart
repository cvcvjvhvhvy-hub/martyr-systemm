import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/mock_service.dart';
import '../widgets/user_tile.dart';
import 'package:uuid/uuid.dart';
import '../utils/platform_utils.dart';
import '../models/notification_item.dart';

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final MockService _svc = MockService();
  List<User> _users = [];
  bool _loading = true;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _users = await _svc.fetchUsers();
    setState(() => _loading = false);
  }

  void _showEditor({User? user}) {
    final _formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final roleCtrl = TextEditingController(text: user?.role ?? 'user');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(user == null ? 'إضافة مستخدم' : 'تعديل مستخدم'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, decoration: InputDecoration(labelText: 'الاسم'), validator: (v) => (v==null||v.trim().isEmpty)? 'الاسم مطلوب' : null),
              TextFormField(controller: emailCtrl, decoration: InputDecoration(labelText: 'البريد الإلكتروني'), validator: (v) => (v==null||!v.contains('@'))? 'بريد إلكتروني صالح مطلوب' : null),
              TextFormField(controller: roleCtrl, decoration: InputDecoration(labelText: 'الدور')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final id = user?.id ?? Uuid().v4();
              final u = User(id: id, name: nameCtrl.text.trim(), email: emailCtrl.text.trim(), role: roleCtrl.text.trim());
              if (user == null) await _svc.addUser(u); else await _svc.updateUser(u);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحفظ')));
              await _load();
            },
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _delete(String id) async {
    await _svc.deleteUser(id);
    await _load();
  }

  Future<void> _exportCsv() async {
    final rows = <String>[];
    rows.add('id,name,email,role');
    for (final u in _users) {
      rows.add('${u.id},"${u.name}","${u.email}",${u.role}');
    }
    final csv = rows.join('\n');
    PlatformUtils.downloadCsv(csv, 'users.csv');
    ScaffoldMessenger.of(context).showSnackBar(ScaffoldMessenger.of(context).mounted ? SnackBar(content: Text('تم تنزيل/حفظ ملف users.csv')) : SnackBar(content: Text('تم إنشاء CSV')));
  }

  Future<void> _sendBulkMessage() async {
    final textCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('إرسال رسالة جماعية'),
        content: TextField(controller: textCtrl, decoration: InputDecoration(hintText: 'نص الرسالة')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('إرسال')),
        ],
      ),
    );
    if (ok != true) return;
    final text = textCtrl.text.trim();
    if (text.isEmpty) return;
    for (final id in _selected) {
      final note = NotificationItem(id: Uuid().v4(), message: '[رسالة جماعية] $text');
      await _svc.sendNotification(note);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الإرسال إلى ${_selected.length} مستخدم')));
    setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    final adminId = _svc.currentAdminId();
    final canManage = _svc.hasPermission(adminId, 'manage_users');
    return Scaffold(
      appBar: AppBar(actions: [
        if (canManage) IconButton(icon: Icon(Icons.copy), onPressed: _exportCsv, tooltip: 'تصدير CSV'),
        if (_selected.isNotEmpty)
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'ban') {
                for (final id in _selected) {
                  final u = _users.firstWhere((x) => x.id == id);
                  u.role = 'banned';
                  await _svc.updateUser(u);
                }
                await _load();
                setState(() => _selected.clear());
              } else if (v == 'suspend') {
                for (final id in _selected) {
                  final u = _users.firstWhere((x) => x.id == id);
                  u.role = 'suspended';
                  await _svc.updateUser(u);
                }
                await _load();
                setState(() => _selected.clear());
              } else if (v == 'message') {
                await _sendBulkMessage();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'ban', child: Text('حظر')), 
              PopupMenuItem(value: 'suspend', child: Text('توقيف مؤقت')),
              PopupMenuItem(value: 'message', child: Text('إرسال رسالة')),
            ],
          )
      ]),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text('إدارة المستخدمين', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (_, i) => UserTile(
                        user: _users[i],
                        selected: _selected.contains(_users[i].id),
                        onSelect: (s) => setState(() => s ? _selected.add(_users[i].id) : _selected.remove(_users[i].id)),
                        onEdit: canManage ? () => _showEditor(user: _users[i]) : null,
                        onDelete: canManage ? () => _delete(_users[i].id) : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: canManage ? FloatingActionButton(onPressed: () => _showEditor(), child: Icon(Icons.add)) : null,
    );
  }
}
