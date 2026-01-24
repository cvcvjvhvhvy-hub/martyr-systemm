import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/mock_service.dart';
import '../models/admin_account.dart';
import '../models/audit_entry.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import '../utils/platform_utils.dart';
import 'audit_page.dart';

class AdminsPage extends StatefulWidget {
  @override
  _AdminsPageState createState() => _AdminsPageState();
}

class _AdminsPageState extends State<AdminsPage> {
  final MockService _svc = MockService();
  List<AdminAccount> _admins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _admins = await _svc.fetchAdmins();
    setState(() => _loading = false);
  }

  Future<void> _showEditor({AdminAccount? a}) async {
    final name = TextEditingController(text: a?.name ?? '');
    final email = TextEditingController(text: a?.email ?? '');
    final roleCtrl = TextEditingController(text: a?.role ?? 'admin');
    final perms = TextEditingController(text: a != null ? (a.permissions.join(',')) : '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(a == null ? 'إضافة أدمن' : 'تعديل أدمن'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: InputDecoration(hintText: 'الاسم')),
          TextField(controller: email, decoration: InputDecoration(hintText: 'البريد')),
          TextField(controller: roleCtrl, decoration: InputDecoration(hintText: 'الدور')),
          TextField(controller: perms, decoration: InputDecoration(hintText: 'الصلاحيات (مفصولة بفاصلة)')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('حفظ'))],
      ),
    );
    if (ok != true) return;
    if (a == null) {
      final na = AdminAccount(id: Uuid().v4(), name: name.text.trim(), email: email.text.trim(), role: roleCtrl.text.trim(), permissions: perms.text.trim().isEmpty ? [] : perms.text.split(',').map((s) => s.trim()).toList());
      await _svc.addAdmin(na);
      await _svc.recordAudit(AuditEntry(id: Uuid().v4(), adminId: _svc.currentAdminId(), action: 'create_admin', targetType: 'admin', targetId: na.id, details: na.role));
    } else {
      a.name = name.text.trim();
      a.email = email.text.trim();
      a.role = roleCtrl.text.trim();
      a.permissions = perms.text.trim().isEmpty ? [] : perms.text.split(',').map((s) => s.trim()).toList();
      await _svc.updateAdmin(a);
      await _svc.recordAudit(AuditEntry(id: Uuid().v4(), adminId: _svc.currentAdminId(), action: 'update_admin', targetType: 'admin', targetId: a.id, details: a.role));
    }
    await _load();
  }

  Future<void> _delete(String id) async {
    await _svc.deleteAdmin(id);
    await _svc.recordAudit(AuditEntry(id: Uuid().v4(), adminId: _svc.currentAdminId(), action: 'delete_admin', targetType: 'admin', targetId: id, details: null));
    await _load();
  }

  Future<void> _showAudit() async {
    final list = await _svc.fetchAudits();
    await showDialog(context: context, builder: (_) => AlertDialog(title: Text('سجل التدقيق'), content: Container(width: double.maxFinite, child: list.isEmpty ? Text('لا توجد مدخلات') : ListView.builder(itemCount: list.length, itemBuilder: (_, i) { final it = list[i]; return ListTile(title: Text(it.action), subtitle: Text('${it.adminId} • ${it.targetType}:${it.targetId} • ${it.at.toLocal()}'),); } )), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('إغلاق')), ElevatedButton(onPressed: () { Navigator.pop(context); _exportAudit(list); }, child: Text('تصدير'))]);
  }

  Future<void> _exportAudit(List<AuditEntry> list) async {
    final rows = <String>[];
    rows.add('id,adminId,action,targetType,targetId,at,details');
    for (final a in list) rows.add('${a.id},${a.adminId},${a.action},${a.targetType},${a.targetId},"${a.at.toIso8601String()}","${a.details ?? ''}"');
    final csv = rows.join('\n');
    await PlatformUtils.downloadCsv(csv, 'audit.csv');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تنزيل/حفظ سجل التدقيق')));
  }

  @override
  Widget build(BuildContext context) {
    final adminId = _svc.currentAdminId();
    final canManage = _svc.hasPermission(adminId, 'manage_admins');
    final canViewAudit = _svc.hasPermission(adminId, 'view_audit');
    return Scaffold(
      appBar: AppBar(title: Text('حسابات الأدمن'), actions: [if (canViewAudit) IconButton(icon: Icon(Icons.history), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AuditPage())))]),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(children: [
                Text('حسابات الأدمن', style: Theme.of(context).textTheme.headline6),
                SizedBox(height: 8),
                Expanded(
                    child: ListView.builder(
                  itemCount: _admins.length,
                  itemBuilder: (_, i) {
                    final it = _admins[i];
                    return Card(
                      child: ListTile(
                        title: Text(it.name),
                        subtitle: Text('${it.email} • ${it.role}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (canManage) IconButton(icon: Icon(Icons.edit), onPressed: () => _showEditor(a: it)) else SizedBox.shrink(),
                          if (canManage) IconButton(icon: Icon(Icons.delete), onPressed: () => _delete(it.id)) else SizedBox.shrink(),
                        ]),
                      ),
                    );
                  },
                ))
              ]),
            ),
      floatingActionButton: canManage ? FloatingActionButton(onPressed: () => _showEditor(), child: Icon(Icons.add)) : null,
    );
  }
}
