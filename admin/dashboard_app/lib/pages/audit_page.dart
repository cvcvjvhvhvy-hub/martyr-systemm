import 'package:flutter/material.dart';
import '../services/mock_service.dart';
import '../models/audit_entry.dart';

class AuditPage extends StatefulWidget {
  @override
  _AuditPageState createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  final MockService _svc = MockService();
  List<AuditEntry> _list = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _list = await _svc.fetchAudits();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final filtered = q.isEmpty ? _list : _list.where((a) => (a.action + (a.details ?? '') + a.adminId + a.targetId + a.targetType).toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: AppBar(title: Text('سجل التدقيق')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(children: [Expanded(child: TextField(controller: _search, decoration: InputDecoration(hintText: 'بحث في السجل'))), SizedBox(width: 8), ElevatedButton(onPressed: () => setState(() {}), child: Text('بحث'))]),
                  SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text('لا توجد مدخلات'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final it = filtered[i];
                              return Card(
                                child: ListTile(
                                  title: Text(it.action),
                                  subtitle: Text('${it.adminId} • ${it.targetType}:${it.targetId} • ${it.at.toLocal().toString().split('.').first}\n${it.details ?? ''}'),
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
