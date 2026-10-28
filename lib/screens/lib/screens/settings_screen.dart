import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = true;
  String selectedLanguage = 'العربية';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // العنوان
        const Text(
          'الإعدادات',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.gold),
        ),
        const SizedBox(height: 20),

        // قسم المظهر
        _sectionTitle('المظهر'),
        _settingCard(
          children: [
            SwitchListTile(
              title: const Text('الوضع الداكن', style: TextStyle(color: AppColors.text)),
              subtitle: const Text('مفعل حالياً', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              value: isDarkMode,
              activeColor: AppColors.gold,
              onChanged: (value) {
                setState(() => isDarkMode = value);
                // يمكن لاحقاً ربطه بتغيير الثيم الحقيقي
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // قسم اللغة
        _sectionTitle('اللغة'),
        _settingCard(
          children: [
            ListTile(
              title: const Text('لغة التطبيق', style: TextStyle(color: AppColors.text)),
              subtitle: Text(selectedLanguage, style: const TextStyle(color: AppColors.gold, fontSize: 13)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.muted),
              onTap: () {
                _showLanguageDialog();
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // قسم عن التطبيق
        _sectionTitle('عن التطبيق'),
        _settingCard(
          children: [
            const ListTile(
              title: Text('اسم التطبيق', style: TextStyle(color: AppColors.text)),
              trailing: Text('ريف جول', style: TextStyle(color: AppColors.gold)),
            ),
            const Divider(color: AppColors.border, height: 1),
            const ListTile(
              title: Text('الإصدار', style: TextStyle(color: AppColors.text)),
              trailing: Text('1.0.0', style: TextStyle(color: AppColors.muted)),
            ),
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              title: const Text('الشعار', style: TextStyle(color: AppColors.text)),
              subtitle: const Text('الرياضة من قلب الريف', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              trailing: const Icon(Icons.sports_soccer, color: AppColors.gold),
            ),
          ],
        ),

        const SizedBox(height: 30),

        // زر إعادة تحميل البيانات
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديث البيانات')),
            );
          },
          icon: const Icon(Icons.refresh),
          label: const Text('تحديث البيانات'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.background,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _settingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('اختر اللغة', style: TextStyle(color: AppColors.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('العربية', style: TextStyle(color: AppColors.text)),
                trailing: selectedLanguage == 'العربية'
                    ? const Icon(Icons.check, color: AppColors.gold)
                    : null,
                onTap: () {
                  setState(() => selectedLanguage = 'العربية');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('English', style: TextStyle(color: AppColors.text)),
                trailing: selectedLanguage == 'English'
                    ? const Icon(Icons.check, color: AppColors.gold)
                    : null,
                onTap: () {
                  setState(() => selectedLanguage = 'English');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
