import 'dart:convert';

import 'package:flutter/material.dart';
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
    debugPrint('RIFGOAL REQUEST: $endpoint');

    final response = await _client
        .get(
          endpoint,
          headers: {
            'Accept': 'application/json',
          },
        )
        .timeout(ApiConfig.timeout);

    debugPrint('RIFGOAL STATUS: ${response.statusCode}');

    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode != 200) {
      debugPrint('RIFGOAL SERVER ERROR: $body');

      throw Exception(
        'خطأ من السيرفر (${response.statusCode}): $body',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw Exception('السيرفر أعاد بيانات غير صالحة.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('صيغة بيانات المباريات غير صحيحة.');
    }

    final errors = decoded['errors'];

    if (errors is Map && errors.isNotEmpty) {
      debugPrint('RIFGOAL API ERRORS: $errors');

      throw Exception(
        'خطأ API: ${errors.values.join(' - ')}',
      );
    }

    final data = decoded['response'];

    if (data is! List) {
      debugPrint('RIFGOAL INVALID RESPONSE: $decoded');

      throw Exception(
        'السيرفر لم يُرجع قائمة المباريات بشكل صحيح.',
      );
    }

    debugPrint('RIFGOAL MATCHES COUNT: ${data.length}');

    if (data.isEmpty) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) => FootballMatch.fromApiSports(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  void dispose() {
    _client.close();
  }
}
