class ApiConfig {
  static const String baseUrl =
      'https://ithran1993-debug.github.io/rifkoora';

  // الرابط الحي الموحد عبر Cloudflare Worker
  static const String matchesEndpoint =
      'https://rifgoal-proxy.ithran1993.workers.dev';

  // رابط النسخة الاحتياطية على GitHub
  static const String fallbackEndpoint = '$baseUrl/app_data.json';

  static const Duration timeout =
      Duration(seconds: 30);
}
