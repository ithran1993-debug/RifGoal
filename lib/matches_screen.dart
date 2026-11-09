import 'dart:async';
import 'package:flutter/material.dart';

import 'date_selector.dart';
import 'competition_selector.dart';
import 'match_service.dart';
import 'match_model.dart';
import 'api_config.dart';
import 'match_details_screen.dart';
import 'football_translations.dart';

class MatchesScreen extends StatefulWidget {
const MatchesScreen({super.key});

@override
State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
final MatchService _matchService = MatchService();

DateTime selectedDate = DateTime.now();
String selectedCompetition = 'ALL';

List<FootballMatch> matches = [];

bool isLoading = true;
String? errorMessage;

Timer? _refreshTimer;
int _requestId = 0;

static const Map<String, String> competitionIds = {
  'CL': 'CL',
  'PL': 'PL',
  'PD': 'PD',
  'SA': 'SA',
  'BL1': 'BL1',
  'FL1': 'FL1',
};

static const Map<int, int> leaguePriority = {
2: 1,
39: 2,
140: 3,
135: 4,
78: 5,
61: 6,
};

static const Color navy = Color(0xFF202B3B);
static const Color orange = Color(0xFFFF9800);
static const Color pageBackground = Color(0xFFF1F3F7);
static const Color liveColor = Color(0xFFD32F2F);
static const Color secondaryText = Color(0xFF7B8492);

@override
void initState() {
super.initState();

_loadMatches();

_refreshTimer = Timer.periodic(
  const Duration(seconds: 60),
  (timer) {
    if (!mounted || isLoading) return;
    _loadMatches(showLoading: false);
  },
);

}

int _getLeaguePriority(FootballMatch match) {
return leaguePriority[match.leagueId] ?? 100;
}

List<FootballMatch> _sortMatches(List<FootballMatch> list) {
final sorted = List<FootballMatch>.from(list);

sorted.sort((a, b) {
  final priorityComparison =
      _getLeaguePriority(a).compareTo(_getLeaguePriority(b));

  if (priorityComparison != 0) {
    return priorityComparison;
  }

  return a.date.compareTo(b.date);
});

return sorted;

}

String _formatDate(DateTime date) {
final year = date.year.toString();
final month = date.month.toString().padLeft(2, '0');
final day = date.day.toString().padLeft(2, '0');

return '$year-$month-$day';

}

int _getSeason(DateTime date) {
return date.month >= 7 ? date.year : date.year - 1;
}

Future<void> _loadMatches({
bool showLoading = true,
}) async {
if (!mounted) return;

final currentRequestId = ++_requestId;

final requestedDate = selectedDate;
final requestedCompetition = selectedCompetition;

if (showLoading) {
  setState(() {
    isLoading = true;
    errorMessage = null;
  });
}

try {
  final parameters = <String, String>{
    'date': _formatDate(requestedDate),
  };

  if (requestedCompetition != 'ALL') {
    final leagueCode = competitionIds[requestedCompetition];

if (leagueCode == null) {
      throw Exception('رمز البطولة غير معروف.');
    }

    parameters['league'] = leagueCode;
    parameters['season'] = _getSeason(requestedDate).toString();
  }

  final endpoint = Uri.parse(
    '${ApiConfig.baseUrl}/api/fixtures',
  ).replace(
    queryParameters: parameters,
  );

  final result = await _matchService.fetchMatches(
    endpoint: endpoint,
  );

  if (!mounted || currentRequestId != _requestId) return;

  setState(() {
    matches = _sortMatches(result);
    isLoading = false;
    errorMessage = null;
  });
} catch (error) {
  if (!mounted || currentRequestId != _requestId) return;

  if (!showLoading && matches.isNotEmpty) {
    debugPrint('RIFGOAL AUTO REFRESH ERROR: $error');
    return;
  }

  setState(() {
    isLoading = false;
    errorMessage = error.toString().replaceFirst(
      'Exception: ',
      '',
    );
  });
}

}

void _openMatchDetails(FootballMatch match) {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => MatchDetailsScreen(match: match),
),
);
}

@override
void dispose() {
_refreshTimer?.cancel();
_requestId++;
_matchService.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Container(
color: pageBackground,
child: Column(
children: [
DateSelector(
selectedDate: selectedDate,
onDateSelected: (date) {
if (date.year == selectedDate.year &&
date.month == selectedDate.month &&
date.day == selectedDate.day) {
return;
}

          setState(() {
            selectedDate = date;
          });

          _loadMatches();
        },
      ),

      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: CompetitionSelector(
          selectedCompetition: selectedCompetition,
          onSelected: (competition) {
            if (competition == selectedCompetition) return;

            setState(() {
              selectedCompetition = competition;
            });

            _loadMatches();
          },
        ),
      ),

      Expanded(
        child: _buildMatchesContent(),
      ),
    ],
  ),
);

}

Widget _buildMatchesContent() {
if (isLoading) {
return const Center(
child: CircularProgressIndicator(
color: orange,
),
);
}

if (errorMessage != null) {
  return _buildMessage(
    icon: Icons.wifi_off,
    title: 'تعذر تحميل المباريات',
    subtitle: errorMessage!,
    showRetry: true,
  );
}

if (matches.isEmpty) {
  return RefreshIndicator(
    color: orange,
    onRefresh: _loadMatches,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 100),
        Icon(
          Icons.sports_soccer_outlined,
          size: 65,
          color: secondaryText,
        ),
        SizedBox(height: 16),
        Center(
          child: Text(
            'لا توجد مباريات في هذا اليوم',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            'اسحب للأسفل لتحديث النتائج',
            style: TextStyle(
              color: secondaryText,
            ),
          ),
        ),
      ],
    ),
  );
}

final groupedMatches = <String, List<FootballMatch>>{};

for (final match in matches) {
  final key = '${match.leagueId}_${match.leagueName}';
  groupedMatches.putIfAbsent(key, () => []);
  groupedMatches[key]!.add(match);
}

final groups = groupedMatches.values.toList();

return RefreshIndicator(
  color: orange,
  onRefresh: _loadMatches,
  child: ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
    itemCount: groups.length,
    itemBuilder: (context, index) {
      return _buildLeagueCard(groups[index]);
    },
  ),
);

}

Widget _buildMessage({
required IconData icon,
required String title,
required String subtitle,
bool showRetry = false,
}) {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 55,
color: orange,
),
const SizedBox(height: 16),
Text(
title,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: navy,
),
),
const SizedBox(height: 8),
Text(
subtitle,
textAlign: TextAlign.center,
style: const TextStyle(
color: secondaryText,
fontSize: 13,
),
),
if (showRetry) ...[
const SizedBox(height: 18),
ElevatedButton.icon(
style: ElevatedButton.styleFrom(
backgroundColor: navy,
foregroundColor: Colors.white,
),
onPressed: _loadMatches,
icon: const Icon(Icons.refresh),
label: const Text('إعادة المحاولة'),
),
],
],
),
),
);
}

Widget _buildLeagueCard(List<FootballMatch> leagueMatches) {
if (leagueMatches.isEmpty) {
return const SizedBox.shrink();
}

final leagueName = FootballTranslations.league(
  leagueMatches.first.leagueName,
);

return Container(
  margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
      color: const Color(0xFFE5E8ED),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.035),
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFC),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(10),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: orange,
              size: 19,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                leagueName,
                style: const TextStyle(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${leagueMatches.length} مباريات',
              style: const TextStyle(
                color: secondaryText,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.keyboard_arrow_down,
              color: secondaryText,
              size: 20,
            ),
          ],
        ),
      ),
      const Divider(
        height: 1,
        color: Color(0xFFECEFF3),
      ),
      for (int i = 0; i < leagueMatches.length; i++) ...[
        _buildMatchRow(leagueMatches[i]),
        if (i != leagueMatches.length - 1)
          const Divider(
            height: 1,
            indent: 12,
            endIndent: 12,
            color: Color(0xFFECEFF3),
          ),
      ],
    ],
  ),
);

}

Widget _buildMatchRow(FootballMatch match) {
return Material(
color: Colors.transparent,
child: InkWell(
onTap: () => _openMatchDetails(match),
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 9,
vertical: 13,
),
child: Row(
children: [
Expanded(
child: _buildTeamCell(
name: match.homeTeam,
logo: match.homeLogo,
isHome: true,
),
),

          SizedBox(
            width: 82,
            child: _buildMatchCenter(match),
          ),

          Expanded(
            child: _buildTeamCell(
              name: match.awayTeam,
              logo: match.awayLogo,
              isHome: false,
            ),
          ),
        ],
      ),
    ),
  ),
);

}

Widget _buildTeamCell({
required String name,
required String logo,
required bool isHome,
}) {
final translatedName = FootballTranslations.team(name);
final displayName = translatedName.isEmpty
? 'غير معروف'
: translatedName;

final logoWidget = SizedBox(
  width: 29,
  height: 29,
  child: logo.isEmpty
      ? const Icon(
          Icons.shield_outlined,
          size: 25,
          color: secondaryText,
        )
      : Image.network(
          logo,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.shield_outlined,
              size: 25,
              color: secondaryText,
            );
          },
        ),
);

final nameWidget = Flexible(
  child: Text(
    displayName,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textAlign: isHome ? TextAlign.right : TextAlign.left,
    style: const TextStyle(
      color: Color(0xFF252D38),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  ),
);

return Row(
  mainAxisAlignment: isHome
      ? MainAxisAlignment.start
      : MainAxisAlignment.end,
  children: isHome
      ? [
          logoWidget,
          const SizedBox(width: 5),
          nameWidget,
        ]
      : [
          nameWidget,
          const SizedBox(width: 5),
          logoWidget,
        ],
);

}

Widget _buildMatchCenter(FootballMatch match) {
final score =
'${match.homeScore ?? '-'} : ${match.awayScore ?? '-'}';

if (match.status == 'HT') {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        score,
        style: const TextStyle(
          color: navy,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      const Text(
        'استراحة',
        style: TextStyle(
          color: liveColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}

if (match.isLive) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        score,
        style: const TextStyle(
          color: navy,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: liveColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            match.elapsed != null
                ? "${match.elapsed}'"
                : 'مباشر',
            style: const TextStyle(
              color: liveColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ],
  );
}

if (match.isFinished) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        score,
        style: const TextStyle(
          color: navy,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      const Text(
        'انتهت',
        style: TextStyle(
          color: secondaryText,
          fontSize: 10,
        ),
      ),
    ],
  );
}

if (match.status == 'PST' ||
    match.status == 'CANC' ||
    match.status == 'SUSP') {
  return Text(
    _statusText(match),
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: liveColor,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    ),
  );
}

return Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      _matchTime(match.date),
      style: const TextStyle(
        color: navy,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        'لم تبدأ',
        style: TextStyle(
          color: secondaryText,
          fontSize: 9,
        ),
      ),
    ),
  ],
);

}

String _matchTime(DateTime date) {

String _matchTime(DateTime date) {
  final localDate = date.toLocal();
  final hour = localDate.hour.toString().padLeft(2, '0');
  final minute = localDate.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

final localDate = date.toLocal();

final hour = localDate.hour.toString().padLeft(2, '0');
final minute = localDate.minute.toString().padLeft(2, '0');

return '$hour:$minute';

}

String _statusText(FootballMatch match) {
if (match.status == 'HT') return 'استراحة';

if (match.isLive) {
  return match.elapsed != null
      ? "مباشر ${match.elapsed}'"
      : 'مباشر';
}

if (match.isFinished) return 'انتهت';

switch (match.status) {
  case 'NS':
    return 'لم تبدأ';
  case 'PST':
    return 'مؤجلة';
  case 'CANC':
    return 'ألغيت';
  case 'SUSP':
    return 'متوقفة';
  case 'TBD':
    return 'لم يحدد الموعد';
  default:
    return match.statusLong.isEmpty
        ? 'موعد المباراة'
        : match.statusLong;
}

}
}
