import 'package:flutter/material.dart';
import '../services/mock_service.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final MockService _svc = MockService();
  int _users = 0;
  int _contents = 0;
  int _notifications = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _users = await _svc.countUsers();
    _contents = await _svc.countContents();
    _notifications = await _svc.countNotifications();
    setState(() => _loading = false);
  }

  Widget _card(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(fontSize: 18)),
            ])
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('لوحة المعلومات', style: Theme.of(context).textTheme.headline5),
                  SizedBox(height: 12),
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    SizedBox(width: 300, child: _card('المستخدمون', '$_users', Icons.people, Colors.indigo)),
                    SizedBox(width: 300, child: _card('المحتويات', '$_contents', Icons.article, Colors.green)),
                    SizedBox(width: 300, child: _card('الإشعارات', '$_notifications', Icons.notifications, Colors.orange)),
                  ]),
                ],
              ),
            ),
    );
  }
}
