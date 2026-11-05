import 'package:flutter/material.dart';

import 'app_constants.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'matches_screen.dart';
import 'leagues_screen.dart';
import 'standings_screen.dart';
import 'news_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

final ThemeController themeController = ThemeController();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.loadTheme();
  runApp(const RifGoalApp());
}

class RifGoalApp extends StatelessWidget {
  const RifGoalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,
          locale: const Locale('ar'),
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<String> titles = [
    'الرئيسية',
    'المباريات',
    'البطولات',
    'الترتيب',
    'الأخبار',
    'المفضلة',
  ];

  late final List<Widget> pages = [
    HomeOverview(onNavigate: _navigateTo),
    const MatchesScreen(),
    const LeaguesScreen(),
    const StandingsScreen(),
    const NewsScreen(),
    const FavoritesScreen(),
  ];

  void _navigateTo(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.sports_soccer_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 9),
            Text(
              selectedIndex == 0
                  ? 'RIF GOAL'
                  : titles[selectedIndex],
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 19,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    controller: themeController,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _navigateTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'المباريات',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'البطولات',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'الترتيب',
          ),
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'الأخبار',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'المفضلة',
          ),
        ],
      ),
    );
  }
}

// الصفحة الرئيسية
class HomeOverview extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const HomeOverview({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 25),
      children: [
        // الواجهة الرئيسية
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                primary,
                primary.withOpacity(0.72),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'RIF GOAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.sports_soccer_rounded,
                    size: 48,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              const Text(
                'عالم كرة القدم بين يديك',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'تابع المباريات والنتائج والبطولات وأخبار فريقك المفضل.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 43,
                child: ElevatedButton.icon(
                  onPressed: () => onNavigate(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.sports_soccer),
                  label: const Text(
                    'تابع المباريات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        // عنوان الاختصارات
        const Row(
          children: [
            Icon(Icons.dashboard_rounded, size: 21),
            SizedBox(width: 8),
            Text(
              'اكتشف ريف جول',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // اختصارات الصفحات
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _HomeShortcut(
              icon: Icons.sports_soccer_rounded,
              title: 'المباريات',
              subtitle: 'النتائج والمواعيد',
              color: const Color(0xFF2196F3),
              onTap: () => onNavigate(1),
            ),
            _HomeShortcut(
              icon: Icons.emoji_events_rounded,
              title: 'البطولات',
              subtitle: 'أهم المسابقات',
              color: const Color(0xFFFFA000),
              onTap: () => onNavigate(2),
            ),
            _HomeShortcut(
              icon: Icons.leaderboard_rounded,
              title: 'الترتيب',
              subtitle: 'ترتيب الأندية',
              color: const Color(0xFF4CAF50),
              onTap: () => onNavigate(3),
            ),
            _HomeShortcut(
              icon: Icons.newspaper_rounded,
              title: 'الأخبار',
              subtitle: 'أخبار كرة القدم',
              color: const Color(0xFF9C27B0),
              onTap: () => onNavigate(4),
            ),
            _HomeShortcut(
              icon: Icons.star_rounded,
              title: 'المفضلة',
              subtitle: 'فرقك وبطولاتك',
              color: const Color(0xFFFF9800),
              onTap: () => onNavigate(5),
            ),
            _HomeShortcut(
              icon: Icons.settings_rounded,
              title: 'الإعدادات',
              subtitle: 'تخصيص التطبيق',
              color: const Color(0xFF607D8B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      controller: themeController,
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 25),

        // معلومات التطبيق
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: primary,
                size: 27,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rif Goal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'كل ما تحتاجه لمتابعة كرة القدم في تطبيق واحد.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// بطاقة اختصار
class _HomeShortcut extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HomeShortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 29,
              ),
              const SizedBox(height: 9),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
