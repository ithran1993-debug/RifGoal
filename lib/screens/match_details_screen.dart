import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';

class MatchDetailsScreen extends StatelessWidget {
  final Match match;

  const MatchDetailsScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: AppColors.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(match.leagueName, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // الفرق والنتيجة
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _teamColumn(match.home),
                  Column(
                    children: [
                      Text(
                        match.score,
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        match.statusClass == 'live' ? "${match.minute}' جارية" : match.status,
                        style: TextStyle(
                          color: (match.statusClass == 'live' || match.statusClass == 'half')
                              ? AppColors.live
                              : AppColors.muted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _teamColumn(match.away),
                ],
              ),
            ),

            // معلومات المباراة
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

  Widget _teamColumn(Team team) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF21262D),
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: team.logo,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 30, color: AppColors.muted),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(team.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF21262D))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
