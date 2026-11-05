import 'package:flutter/material.dart';
import 'theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
final ThemeController controller;

const SettingsScreen({
super.key,
required this.controller,
});

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
ListTile(
leading: const Icon(Icons.palette_outlined),
title: const Text('المظهر'),
subtitle: const Text('اختر مظهر التطبيق'),
trailing: DropdownButton<ThemeMode>(
value: controller.themeMode,
underline: const SizedBox(),
items: const [
DropdownMenuItem(
value: ThemeMode.system,
child: Text('تلقائي'),
),
DropdownMenuItem(
value: ThemeMode.light,
child: Text('فاتح'),
),
DropdownMenuItem(
value: ThemeMode.dark,
child: Text('داكن'),
),
],
onChanged: (mode) {
if (mode != null) {
controller.setThemeMode(mode);
}
},
),
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
