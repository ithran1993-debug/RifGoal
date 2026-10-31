import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

class LeagueDetailScreen extends StatefulWidget {
  final String leagueName;
  final String leagueCode;

  const LeagueDetailScreen({
    super.key,
    required this.leagueName,
    required this.leagueCode,
  });

  @override
  State<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _matches = [];
  List<dynamic> _standings = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const String _apiKey = '60380bdc41e945a2c17619bdcc6944bf';
  static const String _baseUrl = 'https://v3.football.api-sports.io';

  // تحويل معرف الدوري النصي القديم إلى رقم بطولة معتمد لدى api-sports
  String _resolveLeagueId(String code) {
    final clean = code.trim().toUpperCase();
    switch (clean) {
      case 'PL':
      case 'PREMIER':
        return '39'; // الدوري الإنجليزي
      case 'PD':
      case 'LALIGA':
        return '140'; // الدوري الإسباني
      case 'SA':
      case 'SERIE_A':
        return '135'; // الدوري الإيطالي
      case 'BL1':
      case 'BUNDESLIGA':
        return '78'; // الدوري الألماني
      case 'FL1':
      case 'L
