class FootballNews {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String source;
  final String articleUrl;
  final String publishedAt;

  const FootballNews({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.source,
    required this.articleUrl,
    required this.publishedAt,
  });

  factory FootballNews.fromJson(Map<String, dynamic> json) {
    return FootballNews(
      id: _read(json, ['id', 'news_id']),
      title: _read(json, ['title', 'name']),
      description: _read(json, ['description', 'content', 'summary']),
      imageUrl: _read(json, ['image', 'image_url', 'thumbnail']),
      source: _read(json, ['source', 'author']),
      articleUrl: _read(json, ['url', 'link', 'article_url']),
      publishedAt: _read(json, ['published_at', 'date', 'created_at']),
    );
  }

  static String _read(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return '';
  }
}
