import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const RifGoalApp());
}

class RifGoalApp extends StatelessWidget {
  const RifGoalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ريف جول',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const Center(child: Text('الدوريات', style: TextStyle(color: Colors.grey))),
    const Center(child: Text('الترتيب', style: TextStyle(color: Colors.grey))),
    const Center(child: Text('الأخبار', style: TextStyle(color: Colors.grey))),
    const Center(child: Text('المزيد', style: TextStyle(color: Colors.grey))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ريف جول',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.gold),
            ),
            Text(
              'الرياضة من قلب الريف',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'المباريات'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'الدوريات'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'الترتيب'),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'أخبار'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'المزيد'),
        ],
      ),
    );
  }
}
