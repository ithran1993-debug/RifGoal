import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'news_model.dart';

class NewsService {
  NewsService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<FootballNews>> fetchNews({
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
        'تعذر جلب الأخبار. رمز الاستجابة: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    if (decoded is List) {
      return _convertList(decoded);
    }

    if (decoded is! Map) {
      throw Exception('صيغة بيانات الأخبار غير صحيحة.');
    }

    final data = Map<String, dynamic>.from(decoded);

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      throw Exception('أعاد السيرفر خطأ في طلب الأخبار.');
    }

    dynamic items;

    for (final key in [
      'news',
      'data',
      'items',
      'results',
      'articles',
    ]) {
      if (data[key] is List) {
        items = data[key];
        break;
      }
    }

    if (items == null) {
      throw Exception('لم يتم العثور على قائمة الأخبار.');
    }

    return _convertList(items as List);
  }

  List<FootballNews> _convertList(List items) {
    return items
        .whereType<Map>()
        .map(
          (item) => FootballNews.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((news) => news.title.isNotEmpty)
        .toList();
  }

  void dispose() {
    _client.close();
  }
}
