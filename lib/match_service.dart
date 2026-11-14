import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'match_model.dart';
import 'api_config.dart';

class MatchService {
  MatchService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<FootballMatch>> fetchMatches({
    required Uri endpoint,
  }) async {
    try {
      return await _fetchFromUrl(endpoint);
    } catch (primaryError) {
      debugPrint('PRIMARY WORKER FAILED, TRYING FALLBACK: $primaryError');
      final fallbackUri = Uri.parse(ApiConfig.fallbackEndpoint).replace(
        queryParameters: {
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      return await _fetchFromUrl(fallbackUri);
    }
  }

  Future<List<FootballMatch>> _fetchFromUrl(Uri endpoint) async {
    debugPrint('========== RIFGOAL DEBUG ==========');
    debugPrint('REQUEST URL: $endpoint');

    final response = await _client
        .get(
          endpoint,
          headers: {
            'Accept': 'application/json',
          },
        )
        .timeout(ApiConfig.timeout);

    debugPrint('HTTP STATUS: ${response.statusCode}');

    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode != 200) {
      throw Exception('خطأ السيرفر: ${response.statusCode}');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw Exception('صيغة بيانات السيرفر غير صحيحة.');
    }

    final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);

    dynamic data;
    if (json['response'] is List) {
      data = json['response'];
    } else if (json['matches'] is List) {
      data = json['matches'];
    } else if (json['data'] is List) {
      data = json['data'];
    } else if (json['items'] is List) {
      data = json['items'];
    }

    if (data == null) {
      throw Exception('لم يتم العثور على قائمة المباريات في استجابة السيرفر.');
    }

    final List<FootballMatch> matches = [];

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      if (item is! Map) continue;

      try {
        final matchJson = Map<String, dynamic>.from(item);

        // التمييز الذكي بين صيغة Cloudflare Worker وصيغة API-Sports
        final match = matchJson.containsKey('fixture')
            ? FootballMatch.fromApiSports(matchJson)
            : FootballMatch.fromWorkerJson(matchJson);

        matches.add(match);
      } catch (e) {
        debugPrint('MATCH PARSING ERROR AT INDEX $i: $e');
        continue;
      }
    }

    debugPrint('SUCCESSFULLY PARSED: ${matches.length}');
    return matches;
  }

  void dispose() {
    _client.close();
  }
}
