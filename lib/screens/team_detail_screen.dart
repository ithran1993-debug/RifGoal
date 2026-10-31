import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamName;

  const TeamDetailScreen({super.key, required this.teamName});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  bool _isLoading = true;
  List<dynamic> _teamMatches = [];

  static const String _apiKey = '60380bdc41e945a2c17619bdcc6944bf';
  static const String _baseUrl = 'https://v3.football.api-sports.io';

  // معرّفات الأندية الرسمية في API-Sports
  final Map<String, int> teamIds = const {
    'ريال مدريد': 541,
    'برشلونة': 529,
    'أتلتيكو مدريد': 530,
    'إشبيلية': 536,
    'مانشستر سيتي': 50,
    'ليفربول': 40,
    'أرسنال': 42,
    'آرسنال': 42,
    'تشيلسي': 49,
    'مانشستر يونايتد': 33,
    'توتنهام': 47,
    'بايرن ميونخ': 157,
    'بوروسيا دورتموند': 165,
    'دورتموند': 165,
    'باريس سان جيرمان': 85,
    'يوفنتوس': 496,
    'إنتر ميلان': 505,
    'إنتر': 505,
    'ميلان': 489,
    'نابولي': 492,
    'الوداد': 968,
    'الرجاء': 967,
    'الجيش الملكي': 969,
    'الفتح': 970,
    'حسنية أكادير': 971,
    'المغرب الفاسي': 973,
  };

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    final teamId = teamIds[widget.teamName];
    if (teamId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/fixtures?team=$teamId&last=10'),
        headers: {'x-apisports-key': _apiKey},
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (mounted) {
          setState(() {
            _teamMatches = data['response'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeUrl = AppConstants.teamBadges[widget.teamName];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        title: Text(widget.teamName, style: const TextStyle(
