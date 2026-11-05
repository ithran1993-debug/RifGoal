import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('حساب المستخدم'),
            subtitle: Text('إعدادات الحساب'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('الإشعارات'),
            subtitle: Text('إعدادات تنبيهات المباريات والأخبار'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.language_outlined),
            title: Text('اللغة'),
            subtitle: Text('العربية'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('المظهر'),
            subtitle: Text('الوضع الفاتح أو الداكن حسب إعداد الجهاز'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('حول التطبيق'),
            subtitle: Text('Rif Goal'),
          ),
        ],
      ),
    );
  }
}
