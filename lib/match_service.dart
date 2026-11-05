import 'dart:convert';

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
    final response = await _client
        .get(
          endpoint,
          headers: {
            'Accept': 'application/json',
          },
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'تعذر جلب المباريات. رمز الاستجابة: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    if (decoded is! Map<String, dynamic>) {
      throw Exception('صيغة بيانات المباريات غير صحيحة.');
    }

    if (decoded['errors'] is Map &&
        (decoded['errors'] as Map).isNotEmpty) {
      throw Exception('أعاد السيرفر خطأ في طلب المباريات.');
    }

    final data = decoded['response'];

    if (data is! List) {
      throw Exception('لم يتم العثور على قائمة المباريات.');
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
