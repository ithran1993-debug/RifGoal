class AppConstants {
  // ترجمة أسماء الدوريات
  static const Map<String, String> leagueTranslations = {
    'Championship': 'دوري البطولة الإنجليزية (تشامبيونشيب)',
    'Premier League': 'الدوري الإنجليزي الممتاز',
    'La Liga': 'الدوري الإسباني',
    'Serie A': 'الدوري الإيطالي',
    'Bundesliga': 'الدوري الألماني',
    'Ligue 1': 'الدوري الفرنسي',
    'UEFA Champions League': 'دوري أبطال أوروبا',
    'UEFA Europa League': 'الدوري الأوروبي',
    'Botola Pro': 'البطولة المغربية الاحترافية',
  };

  // ترجمة أسماء الفرق
  static const Map<String, String> teamTranslations = {
    'Real Madrid CF': 'ريال مدريد',
    'Real Madrid': 'ريال مدريد',
    'FC Barcelona': 'برشلونة',
    'Barcelona': 'برشلونة',
    'Manchester City FC': 'مانشستر سيتي',
    'Manchester City': 'مانشستر سيتي',
    'Paris Saint-Germain FC': 'باريس سان جيرمان',
    'Paris SG': 'باريس سان جيرمان',
    'Liverpool FC': 'ليفربول',
    'Arsenal FC': 'أرسنال',
    'Chelsea FC': 'تشيلسي',
    'Manchester United FC': 'مانشستر يونايتد',
    'Bayern München': 'بايرن ميونخ',
    'Borussia Dortmund': 'بوروسيا دورتموند',
    'Juventus FC': 'يوفنتوس',
    'FC Internazionale Milano': 'إنتر ميلان',
    'AC Milan': 'ميلان',
    'Atlético de Madrid': 'أتلتيكو مدريد',
    'Birmingham City FC': 'برمنغهام سيتي',
    'Lincoln City FC': 'لينكولن سيتي',
    'Preston North End FC': 'بريستون نورث إند',
    'Stoke City FC': 'ستوك سيتي',
    'Watford FC': 'واتفورد',
    'Norwich City FC': 'نورويتش سيتي',
    'Derby County FC': 'ديربي كاونتي',
    'Millwall FC': 'ميلوول',
    'Bristol City FC': 'بريستول سيتي',
    'Bolton Wanderers FC': 'بولتون واندررز',
    'Cardiff City FC': 'كارديف سيتي',
    'Wolverhampton Wanderers FC': 'ولفرهامبتون',
    'Charlton Athletic FC': 'تشارلتون أثليتيك',
    'Middlesbrough FC': 'ميدلزبروه',
    'Blackburn Rovers FC': 'بلاكبيرن روفرز',
    'Swansea City AFC': 'سوانزي سيتي',
    'Queens Park Rangers FC': 'كوينز بارك رينجرز',
    'Southampton FC': 'ساوثهامبتون',
  };

  // شعارات الفرق الأكثر شهرة للمفضلة
  static const Map<String, String> teamBadges = {
    'ريال مدريد': 'https://crests.football-data.org/86.png',
    'مانشستر سيتي': 'https://crests.football-data.org/65.png',
    'باريس سان جيرمان': 'https://crests.football-data.org/524.png',
    'برشلونة': 'https://crests.football-data.org/81.png',
    'ليفربول': 'https://crests.football-data.org/64.png',
    'أرسنال': 'https://crests.football-data.org/57.png',
    'بايرن ميونخ': 'https://crests.football-data.org/5.png',
  };

  // شعارات الدوريات
  static const Map<String, String> leagueBadges = {
    'CL': 'https://crests.football-data.org/CL.png',
    'PL': 'https://crests.football-data.org/PL.png',
    'PD': 'https://crests.football-data.org/PD.png',
    'SA': 'https://crests.football-data.org/SA.png',
    'BL1': 'https://crests.football-data.org/BL1.png',
    'FL1': 'https://crests.football-data.org/FL1.png',
    'EL': 'https://crests.football-data.org/EL.png',
  };

  static String translateTeam(String? name) {
    if (name == null || name.isEmpty) return '';
    return teamTranslations[name] ?? name;
  }

  static String translateLeague(String? name) {
    if (name == null || name.isEmpty) return '';
    return leagueTranslations[name] ?? name;
  }
}
