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
const HomeOverview(),
const MatchesScreen(),
const LeaguesScreen(),
const StandingsScreen(),
const NewsScreen(),
const FavoritesScreen(),
];

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text(
selectedIndex == 0 ? 'RIF GOAL' : titles[selectedIndex],
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 20,
),
),
actions: [
IconButton(
tooltip: 'الإعدادات',
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const SettingsScreen(),
),
);
},
icon: const Icon(Icons.settings_outlined),
),
const SizedBox(width: 8),
],
),
body: IndexedStack(
index: selectedIndex,
children: pages,
),
bottomNavigationBar: NavigationBar(
selectedIndex: selectedIndex,
onDestinationSelected: (index) {
setState(() {
selectedIndex = index;
});
},
destinations: const [
NavigationDestination(
icon: Icon(Icons.home_outlined),
selectedIcon: Icon(Icons.home),
label: 'الرئيسية',
),
NavigationDestination(
icon: Icon(Icons.sports_soccer_outlined),
selectedIcon: Icon(Icons.sports_soccer),
label: 'المباريات',
),
NavigationDestination(
icon: Icon(Icons.emoji_events_outlined),
label: 'البطولات',
),
NavigationDestination(
icon: Icon(Icons.leaderboard_outlined),
label: 'الترتيب',
),
NavigationDestination(
icon: Icon(Icons.newspaper_outlined),
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

class HomeOverview extends StatelessWidget {
const HomeOverview({super.key});

@override
Widget build(BuildContext context) {
final primary = Theme.of(context).colorScheme.primary;

return ListView(
  padding: const EdgeInsets.all(16),
  children: [
    Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مرحباً بك في ريف جول',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'كل أخبار ونتائج كرة القدم في مكان واحد',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    const Text(
      'تابع كرة القدم',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    const SizedBox(height: 12),
    _HomeItem(
      icon: Icons.sports_soccer,
      title: 'المباريات والنتائج',
      subtitle: 'تابع المباريات ومواعيد انطلاقها',
    ),
    _HomeItem(
      icon: Icons.emoji_events_outlined,
      title: 'البطولات',
      subtitle: 'اكتشف أهم البطولات الأوروبية والعربية',
    ),
    _HomeItem(
      icon: Icons.leaderboard_outlined,
      title: 'ترتيب الفرق',
      subtitle: 'تابع ترتيب الأندية في البطولات',
    ),
    _HomeItem(
      icon: Icons.newspaper_outlined,
      title: 'آخر الأخبار',
      subtitle: 'تابع أخبار كرة القدم',
    ),
  ],
);

}
}

class _HomeItem extends StatelessWidget {
final IconData icon;
final String title;
final String subtitle;

const _HomeItem({
required this.icon,
required this.title,
required this.subtitle,
});

@override
Widget build(BuildContext context) {
return Card(
margin: const EdgeInsets.only(bottom: 10),
child: ListTile(
leading: Icon(
icon,
color: Theme.of(context).colorScheme.primary,
size: 28,
),
title: Text(
title,
style: const TextStyle(fontWeight: FontWeight.bold),
),
subtitle: Text(subtitle),
),
);
}
}
