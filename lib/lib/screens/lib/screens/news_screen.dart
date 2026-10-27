import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Map<String, dynamic>>> _newsFuture;

  static const String _apiKey = '14bd27c011fd48eea58e807496398e34';

  @override
  void initState() {
    super.initState();
    _newsFuture = _fetchNews();
  }

  Future<List<Map<String, dynamic>>> _fetchNews() async {
    try {
      final url = Uri.parse(
        'https://newsapi.org/v2/everything?q=football OR soccer OR "دوري الأبطال" OR "Premier League"&language=en&sortBy=publishedAt&pageSize=20&apiKey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List articles = data['articles'] ?? [];

        return articles.map((a) {
          return {
            'title': a['title'] ?? 'بدون عنوان',
            'source': a['source']?['name'] ?? 'مصدر',
            'time': a['publishedAt'] != null
                ? a['publishedAt'].toString().substring(0, 10)
                : '',
            'description': a['description'] ?? '',
            'url': a['url'] ?? '',
            'image': a['urlToImage'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('خطأ في جلب الأخبار: $e');
      return [];
    }
  }

  void _refresh() {
    setState(() {
      _newsFuture = _fetchNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        }

        if (snapshot.hasError || (snapshot.data?.isEmpty ?? true)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('لا توجد أخبار حالياً', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final news = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          color: AppColors.gold,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: news.length,
            itemBuilder: (context, index) {
              final item = news[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (item['description'] != null && item['description'].toString().isNotEmpty)
                      Text(
                        item['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          item['source'],
                          style: const TextStyle(color: AppColors.gold, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${item['time']}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
