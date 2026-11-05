import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'standing_model.dart';

class StandingsService {
  StandingsService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Standing>> fetchStandings({
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
        'تعذر جلب الترتيب. رمز الاستجابة: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    if (decoded is! Map<String, dynamic>) {
      throw Exception('صيغة بيانات الترتيب غير صحيحة.');
    }

    final errors = decoded['errors'];
    if (errors is Map && errors.isNotEmpty) {
      throw Exception('أعاد السيرفر خطأ في طلب الترتيب.');
    }

    final responseData = decoded['response'];

    if (responseData is! List || responseData.isEmpty) {
      return [];
    }

    final firstLeague = responseData.first;

    if (firstLeague is! Map) {
      return [];
    }

    final league = firstLeague['league'];

    if (league is! Map) {
      return [];
    }

    final groups = league['standings'];

    if (groups is! List) {
      return [];
    }

    final result = <Standing>[];

    for (final group in groups) {
      if (group is! List) continue;

      for (final item in group) {
        if (item is Map) {
          result.add(
            Standing.fromApiSports(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return result;
  }

  void dispose() {
    _client.close();
  }
}
