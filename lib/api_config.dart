class ApiConfig {
  // رابط الـ Worker المحمي الخاص ببيانات لوحة التحكم (المستودع الخاص)
  static const String secureApiUrl =
      'https://rifkoora-api.ithran1993.workers.dev';

  // مفتاح تصريح مرور التطبيق
  static const String appKey = 'RIFKOORA_APP_2026_SECURE';

  // الرابط الحي الموحد عبر Cloudflare Worker
  static const String matchesEndpoint =
      'https://rifgoal-proxy.ithran1993.workers.dev';

  // رابط النسخة الاحتياطية الآمنة (يسحب من قاعدة RIFKOORA_DB المحمية)
  static const String fallbackEndpoint = secureApiUrl;

  static const Duration timeout =
      Duration(seconds: 30);
}
