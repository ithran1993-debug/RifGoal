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
    debugPrint('========== RIFGOAL DEBUG ==========');
    debugPrint('REQUEST URL: $endpoint');

    try {
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

      debugPrint('RESPONSE LENGTH: ${body.length}');

      if (response.statusCode != 200) {
        debugPrint('SERVER ERROR BODY: $body');

        throw Exception(
          'خطأ السيرفر: ${response.statusCode}',
        );
      }

      dynamic decoded;

      try {
        decoded = jsonDecode(body);
      } catch (e) {
        debugPrint('JSON DECODE ERROR: $e');
        debugPrint('RAW RESPONSE: $body');

        throw Exception('السيرفر أعاد بيانات JSON غير صالحة.');
      }

      if (decoded is! Map) {
        debugPrint('INVALID JSON FORMAT: $decoded');

        throw Exception('صيغة بيانات السيرفر غير صحيحة.');
      }

      final Map<String, dynamic> json =
          Map<String, dynamic>.from(decoded);

      debugPrint('RESPONSE KEYS: ${json.keys.toList()}');

      // فحص أخطاء API
      final errors = json['errors'];

      if (errors != null) {
        if (errors is Map && errors.isNotEmpty) {
          debugPrint('API ERRORS: $errors');

          throw Exception('خطأ API: $errors');
        }

        if (errors is List && errors.isNotEmpty) {
          debugPrint('API ERRORS: $errors');

          throw Exception('خطأ API: $errors');
        }
      }

      // قراءة قائمة المباريات من صيغ متعددة
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
        debugPrint('MATCH LIST NOT FOUND');
        debugPrint('FULL RESPONSE: $json');

        throw Exception(
          'لم يتم العثور على قائمة المباريات في استجابة السيرفر.',
        );
      }

      if (data.isEmpty) {
        debugPrint('MATCHES COUNT: 0');
        debugPrint('السيرفر لم يُرجع مباريات لهذا الطلب.');

        return [];
      }

      debugPrint('MATCHES RECEIVED: ${data.length}');

      final List<FootballMatch> matches = [];

      // تحليل كل مباراة بشكل مستقل
      for (int i = 0; i < data.length; i++) {
        final item = data[i];

        if (item is! Map) {
          debugPrint('SKIPPED MATCH $i: البيانات ليست Map');
          continue;
        }

        try {
          final matchJson = Map<String, dynamic>.from(item);

          final match = FootballMatch.fromApiSports(matchJson);

          matches.add(match);
        } catch (e, stackTrace) {
          debugPrint('MATCH PARSING ERROR AT INDEX $i');
          debugPrint('ERROR: $e');
          debugPrint('MATCH JSON: $item');
          debugPrint('STACK TRACE: $stackTrace');

          // لا نسمح لخطأ مباراة واحدة بإسقاط القائمة كلها.
          continue;
        }
      }

      debugPrint('SUCCESSFULLY PARSED: ${matches.length}');
      debugPrint('FAILED TO PARSE: ${data.length - matches.length}');
      debugPrint('===================================');

      return matches;
    } catch (e) {
      debugPrint('RIFGOAL FETCH ERROR: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
