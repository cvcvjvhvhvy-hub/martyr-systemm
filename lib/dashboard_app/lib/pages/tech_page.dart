import 'package:flutter/material.dart';
import '../services/mock_service.dart';

class TechPage extends StatefulWidget {
  @override
  _TechPageState createState() => _TechPageState();
}

class _TechPageState extends State<TechPage> {
  final MockService _svc = MockService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.delayed(Duration(milliseconds: 300));
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('المدير التقني', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 12),
                Card(child: ListTile(title: Text('المحتوى الثابت (من نحن، الخصوصية، الشروط)'), subtitle: Text('تحرير وحفظ النصوص الثابتة للتطبيق'))),
                Card(child: ListTile(title: Text('مراقبة الأداء'), subtitle: Text('عرض أخطاء تجريبية ومؤشرات'))),
                Card(
                  child: ListTile(
                    title: Text('Backup / Restore'),
                    subtitle: Text('إدارة النسخ الاحتياطية واستعادتها (محاكاة)'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(Icons.save), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء نسخة احتياطية (محاكاة)')))), IconButton(icon: Icon(Icons.restore), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم استعادة بيانات (محاكاة)'))))]),
                  ),
                ),
                Card(child: ListTile(title: Text('Sandbox Mode'), subtitle: Text('تفعيل بيئة اختبار للميزات الجديدة'), trailing: Switch(value: false, onChanged: (_) {}))),
              ]),
            ),
    );
  }
}
