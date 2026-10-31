import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../models/match_model.dart';
import '../services/favorites_service.dart';
import '../services/match_service.dart';
import '../theme/app_theme.dart';
import '../widgets/match_minute_circle.dart';

class MatchDetailsScreen extends StatefulWidget {
  final Match match;

  const MatchDetailsScreen({super.key, required this.match});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  bool isFav = false;
  List<dynamic> _events = [];
  List<int> _goalMinutes = [];
  bool _loadingEvents = true;

  static const String _apiKey = '60380bdc41e945a2c17619bdcc6944bf';
  static const String _baseUrl = 'https://v3.football.api-sports.io';

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    _fetchMatchEvents();
  }

  Future<void> _checkFavorite() async {
    await FavoritesService.instance.load();
    if (mounted) {
      setState(() {
        isFav = FavoritesService.instance.isFavorite(widget.match.id);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.instance.toggle(widget.match);
    if (!mounted) return;
    setState(() {
      isFav = FavoritesService.instance.isFavorite(widget.match.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFav ? 'تمت الإضافة للمفضلة' : 'تمت الإزالة من المفضلة'),
        backgroundColor: AppColors.card,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _fetchMatchEvents() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/fixtures/events?fixture=${widget.match.id}'),
        headers: {'x-apisports-key': _apiKey},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final list = data['response'] as List? ?? [];
        final List<int> goals = [];

        for (var ev in list) {
          if (ev['type'] == 'Goal') {
            final m = int.tryParse(ev['time']?['elapsed']?.toString() ?? '');
            if (m != null) goals.add(m);
          }
        }

        if (mounted) {
          setState(() {
            _events = list;
            _goalMinutes = goals;
            _loadingEvents = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _loadingEvents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final bool isLive = match.statusClass == 'live';
    final int currentMinute = int.tryParse(match.minute?.replaceAll("'", "") ?? '1') ?? 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          match.leagueName,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? AppColors.gold : AppColors.muted,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // بطاقة النتيجة والفريقين
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _teamColumn(match.home)),
                  Column(
                    children: [
                      Text(
                        match.score,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (isLive)
                        MatchMinuteCircle(
                          minute: currentMinute,
                          goalMinutes: _goalMinutes,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            match.status,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Expanded(child: _teamColumn(match.away)),
                ],
              ),
            ),

            // قائمة أحداث اللقاء (أهداف، إنذارات، تبديلات)
            if (_events.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timeline, color: AppColors.gold, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'أحداث المباراة',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF21262D), height: 20),
                    ..._events.map((ev) => _buildEventItem(ev)),
                  ],
                ),
              ),

            // تفاصيل الملعب والحكم والجولة
            Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _infoRow('الملعب', match.stadium),
                  _infoRow('الحكم', match.referee),
                  _infoRow('الجولة', match.round, isLast: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(dynamic ev) {
    final type = (ev['type'] ?? '').toString();
    final minute = ev['time']?['elapsed']?.toString() ?? '';
    final player = ev['player']?['name'] ?? '';
    final detail = ev['detail'] ?? '';

    IconData iconData = Icons.sports_soccer;
    Color iconColor = Colors.white;

    if (type == 'Goal') {
      iconData = Icons.sports_soccer;
      iconColor = const Color(0xFF00E676);
    } else if (type == 'Card') {
      iconData = Icons.style;
      iconColor = detail.toString().contains('Yellow') ? Colors.amber : Colors.redAccent;
    } else if (type == 'subst') {
      iconData = Icons.swap_horiz;
      iconColor = Colors.lightBlueAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "'$minute",
              style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Icon(iconData, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.isNotEmpty ? '$player ($detail)' : detail.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamColumn(Team team) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF21262D),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: ClipOval(
            child: team.logo.isEmpty
                ? const Icon(Icons.sports_soccer, size: 30, color: AppColors.muted)
                : CachedNetworkImage(
                    imageUrl: team.logo,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.sports_soccer, size: 30, color: AppColors.muted),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          team.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool
