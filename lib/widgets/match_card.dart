import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;

  const MatchCard({super.key, required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF21262D))),
        ),
        child: Row(
          children: [
            // الفريق المضيف
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      match.home.name,
                      style: const TextStyle(fontSize: 13, color: AppColors.text),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _teamLogo(match.home.logo),
                ],
              ),
            ),

            // النتيجة / الحالة
            SizedBox(
              width: 70,
              child: _buildScoreBox(),
            ),

            // الفريق الضيف
            Expanded(
              child: Row(
                children: [
                  _teamLogo(match.away.logo),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      match.away.name,
                      style: const TextStyle(fontSize: 13, color: AppColors.text),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamLogo(String url) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF21262D),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipOval(
        child: url.isEmpty
            ? const Icon(Icons.sports_soccer, size: 16, color: AppColors.muted)
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Icon(Icons.sports_soccer, size: 16, color: AppColors.muted),
                errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 16, color: AppColors.muted),
              ),
      ),
    );
  }

  Widget _buildScoreBox() {
    if (match.statusClass == 'live') {
      return Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.live, width: 2.5),
            color: AppColors.live.withOpacity(0.1),
          ),
          child: Center(
            child: Text(
              match.minute != null ? "${match.minute}'" : 'مباشر',
              style: const TextStyle(
                color: AppColors.live,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
      );
    }

    if (match.statusClass == 'half') {
      return Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD29922), width: 2.5),
          ),
          child: const Center(
            child: Text(
              'شوط',
              style: TextStyle(
                color: Color(0xFFD29922),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
      );
    }

    if (match.statusClass == 'finished') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            match.score,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const Text(
            'انتهى',
            style: TextStyle(fontSize: 10, color: AppColors.green),
          ),
        ],
      );
    }

    // مباراة قادمة
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          match.status,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
          ),
        ),
        const Text(
          'vs',
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}
