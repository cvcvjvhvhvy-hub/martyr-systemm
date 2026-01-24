import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/mock_service.dart';
import '../models/notification_item.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final MockService _svc = MockService();
  List<NotificationItem> _notes = [];
  bool _loading = true;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _notes = await _svc.fetchNotifications();
    setState(() => _loading = false);
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أدخل نص الإشعار')));
      return;
    }
    final note = NotificationItem(id: Uuid().v4(), message: text);
    await _svc.sendNotification(note);
    _ctrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الإرسال')));
    await _load();
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل تريد حذف هذا الإشعار؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    await _svc.deleteNotification(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحذف')));
    await _load();
  }

  String _fmt(DateTime dt) => '${dt.toLocal().year}/${dt.toLocal().month.toString().padLeft(2,'0')}/${dt.toLocal().day.toString().padLeft(2,'0')} ${dt.toLocal().hour.toString().padLeft(2,'0')}:${dt.toLocal().minute.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text('الإشعارات', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _ctrl, decoration: InputDecoration(hintText: 'نص الإشعار'))),
                    SizedBox(width: 8),
                    ElevatedButton(onPressed: _send, child: Text('إرسال'))
                  ]),
                  SizedBox(height: 12),
                  Expanded(
                    child: _notes.isEmpty
                        ? Center(child: Text('لا توجد إشعارات'))
                        : ListView.builder(
                            itemCount: _notes.length,
                            itemBuilder: (_, i) {
                              final n = _notes[i];
                              return Card(
                                child: ListTile(
                                  title: Text(n.message),
                                  subtitle: Text(_fmt(n.createdAt)),
                                  trailing: IconButton(icon: Icon(Icons.delete), onPressed: () => _delete(n.id)),
                                ),
                              );
                            },
                          ),
                  )
                ],
              ),
            ),
    );
  }
}
