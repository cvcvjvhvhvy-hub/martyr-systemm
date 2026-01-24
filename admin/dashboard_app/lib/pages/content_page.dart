import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/mock_service.dart';
import 'package:uuid/uuid.dart';

class ContentPage extends StatefulWidget {
  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  final MockService _svc = MockService();
  List<ContentItem> _items = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await _svc.fetchContents();
    setState(() => _loading = false);
  }

  void _showEditor({ContentItem? item}) {
    final _formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final bodyCtrl = TextEditingController(text: item?.body ?? '');
    bool published = item?.published ?? false;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'إضافة محتوى' : 'تعديل محتوى'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: titleCtrl, decoration: InputDecoration(labelText: 'العنوان'), validator: (v) => (v==null||v.trim().isEmpty)? 'العنوان مطلوب' : null),
                TextFormField(controller: bodyCtrl, decoration: InputDecoration(labelText: 'المحتوى'), maxLines: 4, validator: (v) => (v==null||v.trim().isEmpty)? 'المحتوى مطلوب' : null),
                Row(
                  children: [
                    StatefulBuilder(builder: (c, setS) => Checkbox(value: published, onChanged: (v) => setS(() => published = v ?? false))),
                    Text('منشور')
                  ],
                )
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final id = item?.id ?? Uuid().v4();
              final c = ContentItem(id: id, title: titleCtrl.text.trim(), body: bodyCtrl.text.trim(), published: published);
              if (item == null) await _svc.addContent(c); else await _svc.updateContent(c);
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
    await _svc.deleteContent(id);
    await _load();
  }

  Future<void> _showHistory(ContentItem it) async {
    final hist = await _svc.fetchContentHistory(it.id);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('سجل التعديلات'),
        content: Container(
          width: double.maxFinite,
          child: hist.isEmpty
              ? Text('لا توجد نسخ سابقة')
              : ListView.builder(itemCount: hist.length, itemBuilder: (_, i) {
                  final h = hist[i];
                  return ListTile(title: Text(h.title), subtitle: Text(h.body, maxLines: 2, overflow: TextOverflow.ellipsis));
                }),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('إغلاق'))],
      ),
    );
  }

  Future<void> _schedule(ContentItem it) async {
    final date = await showDatePicker(context: context, initialDate: it.scheduledAt ?? DateTime.now(), firstDate: DateTime.now().subtract(Duration(days: 365)), lastDate: DateTime.now().add(Duration(days: 365 * 5)));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(it.scheduledAt ?? DateTime.now()));
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final updated = it.copyWith(scheduledAt: dt);
    await _svc.updateContent(updated);
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم جدولة النشر: ${dt.toLocal()}')));
  }

  @override
  Widget build(BuildContext context) {
    final adminId = _svc.currentAdminId();
    final canManage = _svc.hasPermission(adminId, 'manage_content');
    return Scaffold(
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text('إدارة المحتوى', style: Theme.of(context).textTheme.headline6),
                  SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: _searchCtrl, decoration: InputDecoration(hintText: 'بحث بالكلمة المفتحية'))),
                    SizedBox(width: 8),
                    ElevatedButton(onPressed: () => setState(() {}), child: Text('فلتر'))
                  ]),
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _items.where((it) {
                        final k = _searchCtrl.text.trim();
                        if (k.isEmpty) return true;
                        return it.title.contains(k) || it.body.contains(k);
                      }).length,
                      itemBuilder: (_, i) {
                        final filtered = _items.where((it) {
                          final k = _searchCtrl.text.trim();
                          if (k.isEmpty) return true;
                          return it.title.contains(k) || it.body.contains(k);
                        }).toList();
                        final it = filtered[i];
                        return Card(
                          child: ListTile(
                            title: Text(it.title),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(it.body, maxLines: 2, overflow: TextOverflow.ellipsis), if (it.scheduledAt != null) Text('مجدول للنشر: ${it.scheduledAt!.toLocal()}')]),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: Icon(Icons.history), tooltip: 'سجل التعديلات', onPressed: () => _showHistory(it)),
                              if (canManage) IconButton(icon: Icon(Icons.schedule), tooltip: 'جدولة', onPressed: () => _schedule(it)) else SizedBox.shrink(),
                              if (canManage) IconButton(icon: Icon(Icons.edit), onPressed: () => _showEditor(item: it)) else SizedBox.shrink(),
                              if (canManage) IconButton(icon: Icon(Icons.delete), onPressed: () => _delete(it.id)) else SizedBox.shrink(),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: canManage ? FloatingActionButton(onPressed: () => _showEditor(), child: Icon(Icons.add)) : null,
    );
  }
}
