import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/mock_service.dart';
import '../models/complaint.dart';
import '../models/audit_entry.dart';
import '../utils/platform_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ComplaintsPage extends StatefulWidget {
  @override
  _ComplaintsPageState createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  final MockService _svc = MockService();
  List<Complaint> _items = [];
  bool _loading = true;
  String _filter = 'all';
  final Map<String, DateTime> _runningTimers = {};
  // use MockService.currentAdminId() when needed

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await _svc.fetchComplaints();
    setState(() => _loading = false);
  }

  void _showDetails(Complaint c) async {
    final status = c.status;
    final priority = c.priority;
    final noteCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('تفاصيل البلاغ'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('العنوان: ${c.title}'),
              SizedBox(height: 8),
              Text('البلاغ: ${c.body}'),
              SizedBox(height: 8),
              Text('الأولوية: $priority'),
              SizedBox(height: 8),
              Text('الحالة: $status'),
              SizedBox(height: 8),
              Text('الوقت المستغرق: ${_formatDuration(Duration(seconds: c.timeSpentSeconds))}'),
              SizedBox(height: 8),
              if (c.attachments.isNotEmpty) ...[
                Text('المرفقات:'),
                SizedBox(height: 6),
                Wrap(spacing: 8, children: c.attachments.map((u) => GestureDetector(onTap: () => _openUrl(u), child: Chip(label: Text(u, overflow: TextOverflow.ellipsis)))).toList()),
                SizedBox(height: 8),
              ],
              Row(children: [
                if (_svc.hasPermission(_svc.currentAdminId(), 'manage_complaints')) ...[
                  ElevatedButton(onPressed: () => _addAttachmentDialog(c), child: Text('أضف مرفق')),
                  SizedBox(width: 8),
                  ElevatedButton(onPressed: () => _toggleTimer(c), child: Text(_runningTimers.containsKey(c.id) ? 'إيقاف المؤقت' : 'بدء التتبع')),
                ] else ...[
                  Text('ليس لديك صلاحية لإدارة البلاغات')
                ]
              ]),
              SizedBox(height: 12),
              TextField(controller: noteCtrl, decoration: InputDecoration(hintText: 'رد سريع أو ملاحظة')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إغلاق')),
          TextButton(
              onPressed: () {
                final wa = 'https://wa.me/?text=${Uri.encodeComponent('${c.title} - ${c.body}') }';
                Clipboard.setData(ClipboardData(text: wa));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ رابط واتساب (افتحه في المتصفح)')));
              },
              child: Text('رد عبر واتساب')),
          ElevatedButton(
              onPressed: () async {
                c.status = 'in_progress';
                c.updatedAt = DateTime.now();
                await _svc.updateComplaint(c);
                await _svc.recordAudit(AuditEntry(id: Uuid().v4(), adminId: _svc.currentAdminId(), action: 'start_processing', targetType: 'complaint', targetId: c.id, details: 'وضع البلاغ قيد المعالجة'));
                Navigator.pop(context);
                await _load();
              },
              child: Text('بدء المعالجة')),
        ],
      ),
    );
  }

  void _openUrl(String u) {
    if (kIsWeb) {
      PlatformUtils.openUrl(u);
    }
  }

  Future<void> _addAttachmentDialog(Complaint c) async {
    if (kIsWeb) {
      final result = await PlatformUtils.pickFileAsDataUrl();
      if (result == null) return;
      await _svc.addAttachmentToComplaint(c.id, result, adminId: _svc.currentAdminId());
      await _load();
    } else {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text('إضافة رابط مرفق'), content: TextField(controller: ctrl, decoration: InputDecoration(hintText: 'https://...')), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('إضافة'))]));
      if (ok != true) return;
      final url = ctrl.text.trim();
      if (url.isEmpty) return;
      // for non-web platforms we store the URL string as-is
      await _svc.addAttachmentToComplaint(c.id, url, adminId: _svc.currentAdminId());
      await _load();
    }
  }

  Future<void> _toggleTimer(Complaint c) async {
    if (_runningTimers.containsKey(c.id)) {
      final start = _runningTimers.remove(c.id)!;
      final dur = DateTime.now().difference(start).inSeconds;
      c.timeSpentSeconds += dur;
      c.updatedAt = DateTime.now();
      await _svc.updateComplaint(c);
      await _svc.recordAudit(AuditEntry(id: Uuid().v4(), adminId: _svc.currentAdminId(), action: 'stop_timer', targetType: 'complaint', targetId: c.id, details: 'seconds:$dur'));
      setState(() {});
    } else {
      _runningTimers[c.id] = DateTime.now();
      await _svc.recordAudit(AuditEntry(id: Uuid().v4(), adminId: _svc.currentAdminId(), action: 'start_timer', targetType: 'complaint', targetId: c.id, details: null));
      setState(() {});
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Future<void> _generateReport() async {
    final byPriority = <String, int>{};
    final byStatus = <String, int>{};
    int totalSeconds = 0;
    for (final c in _items) {
      byPriority[c.priority] = (byPriority[c.priority] ?? 0) + 1;
      byStatus[c.status] = (byStatus[c.status] ?? 0) + 1;
      totalSeconds += c.timeSpentSeconds;
    }
    final rows = <String>[];
    rows.add('metric,value');
    byPriority.forEach((k, v) => rows.add('priority_$k,$v'));
    byStatus.forEach((k, v) => rows.add('status_$k,$v'));
    rows.add('total_time_seconds,$totalSeconds');
    final csv = rows.join('\n');
    if (kIsWeb) {
      await PlatformUtils.downloadCsv(csv, 'complaints_report.csv');
    } else {
      await Clipboard.setData(ClipboardData(text: csv));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ تقرير الشكاوى إلى الحافظة')));
    }
    await _svc.recordAudit(AuditEntry(id: Uuid().v4(), adminId: _svc.currentAdminId(), action: 'generate_report', targetType: 'complaint', targetId: 'all', details: null));
  }

  Future<void> _addNew() async {
    final title = TextEditingController();
    final body = TextEditingController();
    final pr = ValueNotifier<String>('medium');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('إنشاء بلاغ جديد'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: InputDecoration(hintText: 'العنوان')),
          TextField(controller: body, decoration: InputDecoration(hintText: 'نص البلاغ')),
          ValueListenableBuilder<String>(valueListenable: pr, builder: (_, v, __) => DropdownButton<String>(value: v, items: ['high', 'medium', 'low'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (s) => pr.value = s ?? 'medium')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('إنشاء'))],
      ),
    );
    if (ok != true) return;
    final c = Complaint(id: Uuid().v4(), title: title.text.trim(), body: body.text.trim(), reporterId: 'unknown', priority: pr.value);
    await _svc.addComplaint(c);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filter == 'all' ? _items : _items.where((x) => x.status == _filter).toList();
    return Scaffold(
      appBar: AppBar(actions: [
        PopupMenuButton<String>(onSelected: (v) => setState(() => _filter = v), itemBuilder: (_) => [
          PopupMenuItem(value: 'all', child: Text('الكل')),
          PopupMenuItem(value: 'new', child: Text('جديدة')),
          PopupMenuItem(value: 'in_progress', child: Text('قيد المعالجة')),
          PopupMenuItem(value: 'done', child: Text('منجزة')),
        ])
      ]),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الشكاوى والدعم', style: Theme.of(context).textTheme.headline6),
                SizedBox(height: 8),
                Expanded(
                    child: list.isEmpty
                        ? Center(child: Text('لا توجد شكاوى'))
                        : ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final it = list[i];
                              return Card(
                                child: ListTile(
                                  title: Text(it.title),
                                  subtitle: Text('${it.priority} • ${it.status} • ${it.createdAt.toLocal().toString().split('.').first}'),
                                  trailing: IconButton(icon: Icon(Icons.open_in_new), onPressed: () => _showDetails(it)),
                                ),
                              );
                            },
                          ))
              ]),
            ),
      floatingActionButton: FloatingActionButton(onPressed: _addNew, child: Icon(Icons.add)),
    );
  }
}
