import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_constants.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'matches_screen.dart';
import 'leagues_screen.dart';
import 'standings_screen.dart';
import 'news_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'onboarding_screen.dart';

final ThemeController themeController = ThemeController();

const String onboardingDoneKey = 'rifgoal_onboarding_done';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

await themeController.loadTheme();

runApp(const RifGoalApp());
}

class RifGoalApp extends StatefulWidget {
const RifGoalApp({super.key});

@override
State<RifGoalApp> createState() => _RifGoalAppState();
}

class _RifGoalAppState extends State<RifGoalApp> {
bool? onboardingDone;

@override
void initState() {
super.initState();
_checkOnboarding();
}

Future<void> _checkOnboarding() async {
final prefs = await SharedPreferences.getInstance();
final completed = prefs.getBool(onboardingDoneKey) ?? false;

if (!mounted) return;

setState(() {
  onboardingDone = completed;
});

}

Future<void> _finishOnboarding() async {
if (!mounted) return;

setState(() {
  onboardingDone = true;
});

}

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
home: onboardingDone == null
? const Scaffold(
body: Center(
child: CircularProgressIndicator(),
),
)
: onboardingDone!
? const HomeScreen()
: OnboardingScreen(
onFinished: _finishOnboarding,
),
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
'المباريات',
'البطولات',
'الترتيب',
'الأخبار',
'المفضلة',
];

late final List<Widget> pages = [
const MatchesScreen(),
const LeaguesScreen(),
const StandingsScreen(),
const NewsScreen(),
const FavoritesScreen(),
];

void _navigateTo(int index) {
if (index == 4) {
pages[4] = FavoritesScreen(key: UniqueKey());
}

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
selectedIndex == 0 ? 'RIF GOAL' : titles[selectedIndex],
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
