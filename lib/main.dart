import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/leagues_screen.dart';
import 'screens/standings_screen.dart';
import 'screens/news_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/onboarding_leagues_screen.dart';
import 'services/favorites_service.dart';
import 'services/onboarding_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FavoritesService.instance.load();
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
      home: const AppStarter(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}

class AppStarter extends StatefulWidget {
  const AppStarter({super.key});

  @override
  State<AppStarter> createState() => _AppStarterState();
}

class _AppStarterState extends State<AppStarter> {
  bool? _done;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final done = await OnboardingService.instance.isDone();
    setState(() => _done = done);
  }

  @override
  Widget build(BuildContext context) {
    if (_done == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (_done == false) {
      return const OnboardingLeaguesScreen();
    }

    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    FavoritesScreen(),
    LeaguesScreen(),
    StandingsScreen(),
    NewsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.sports_soccer,
                  color: AppColors.gold,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ريف جول',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                Text(
                  'متابعة حية ومباشرة',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.muted,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'المفضلة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'الدوريات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_numbered),
            activeIcon: Icon(Icons.format_list_numbered_rounded),
            label: 'الترتيب',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_outlined),
            activeIcon: Icon(Icons.newspaper),
            label: 'الأخبار',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
