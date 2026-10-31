class AppConstants {
  // ترجمة أسماء الدوريات والبطولات
  static const Map<String, String> leagueTranslations = {
    'championship': 'دوري البطولة الإنجليزية',
    'premier league': 'الدوري الإنجليزي الممتاز',
    'primera division': 'الدوري الإسباني (لا ليغا)',
    'la liga': 'الدوري الإسباني',
    'laliga': 'الدوري الإسباني',
    'serie a': 'الدوري الإيطالي',
    'bundesliga': 'الدوري الألماني',
    'ligue 1': 'الدوري الفرنسي',
    'uefa champions league': 'دوري أبطال أوروبا',
    'uefa europa league': 'الدوري الأوروبي',
    'botola pro': 'البطولة المغربية الاحترافية',
    'botola': 'البطولة المغربية',
  };

  // ترجمة أسماء الفرق والنوادي
  static const Map<String, String> teamTranslations = {
    // إسبانيا
    'atleti': 'أتلتيكو مدريد',
    'atlético de madrid': 'أتلتيكو مدريد',
    'atletico madrid': 'أتلتيكو مدريد',
    'levante': 'ليفانتي',
    'levante ud': 'ليفانتي',
    'real madrid': 'ريال مدريد',
    'real madrid cf': 'ريال مدريد',
    'barcelona': 'برشلونة',
    'fc barcelona': 'برشلونة',
    'barça': 'برشلونة',
    'celta': 'سلتا فيغو',
    'celta de vigo': 'سلتا فيغو',
    'celta vigo': 'سلتا فيغو',
    'rayo vallecano': 'رايو فاليكانو',
    'rayo vallec': 'رايو فاليكانو',
    'málaga': 'مالقة',
    'malaga': 'مالقة',
    'real betis': 'ريال بيتيس',
    'betis': 'ريال بيتيس',
    'alavés': 'ألافيس',
    'alaves': 'ألافيس',
    'deportivo alavés': 'ديبورتيفو ألافيس',
    'sevilla': 'إشبيلية',
    'sevilla fc': 'إشبيلية',
    'valencia': 'فالنسيا',
    'valencia cf': 'فالنسيا',
    'villarreal': 'فياريال',
    'athletic club': 'أتلتيك بيلباو',
    'athletic bilbao': 'أتلتيك بيلباو',
    'real sociedad': 'ريال سوسيداد',

    // إنجلترا
    'crystal palace': 'كريستال بالاس',
    'crystal pala': 'كريستال بالاس',
    'tottenham': 'توتنهام',
    'tottenham hotspur': 'توتنهام',
    'fulham': 'فولهام',
    'fulham fc': 'فولهام',
    'aston villa': 'أستون فيلا',
    'ipswich town': 'إيبسويتش تاون',
    'ipswich': 'إيبسويتش تاون',
    'hull city': 'هال سيتي',
    'hull': 'هال سيتي',
    'sunderland': 'سندرلاند',
    'coventry city': 'كوفنتري سيتي',
    'coventry': 'كوفنتري سيتي',
    'manchester city': 'مانشستر سيتي',
    'man city': 'مانشستر سيتي',
    'manchester united': 'مانشستر يونايتد',
    'man united': 'مانشستر يونايتد',
    'liverpool': 'ليفربول',
    'arsenal': 'أرسنال',
    'chelsea': 'تشيلسي',
    'newcastle united': 'نيوكاسل',
    'newcastle': 'نيوكاسل',
    'birmingham': 'برمنغهام سيتي',
    'birmingham city': 'برمنغهام سيتي',
    'lincoln city': 'لينكولن سيتي',
    'preston north end': 'بريستون نورث إند',
    'preston ne': 'بريستون نورث إند',
    'stoke': 'ستوك سيتي',
    'stoke city': 'ستوك سيتي',
    'watford': 'واتفورد',
    'norwich': 'نورويتش سيتي',
    'norwich city': 'نورويتش سيتي',
    'derby county': 'ديربي كاونتي',
    'millwall': 'ميلوول',
    'bristol city': 'بريستول سيتي',
    'bolton': 'بولتون',
    'cardiff': 'كارديف سيتي',
    'wolverhampton': 'ولفرهامبتون',
    'wolves': 'ولفرهامبتون',
    'charlton': 'تشارلتون',
    'middlesbrough': 'ميدلزبروه',
    'blackburn': 'بلاكبيرن',
    'swansea': 'سوانزي سيتي',
    'qpr': 'كوينز بارك رينجرز',
    'queens park rangers': 'كوينز بارك رينجرز',
    'southampton': 'ساوثهامبتون',

    // باقي الأندية الكبرى
    'bayern münchen': 'بايرن ميونخ',
    'bayern munich': 'بايرن ميونخ',
    'borussia dortmund': 'بوروسيا دورتموند',
    'bvb': 'بوروسيا دورتموند',
    'paris saint-germain': 'باريس سان جيرمان',
    'paris sg': 'باريس سان جيرمان',
    'juventus': 'يوفنتوس',
    'inter': 'إنتر ميلان',
    'inter milan': 'إنتر ميلان',
    'milan': 'ميلان',
    'ac milan': 'ميلان',
    'roma': 'روما',
    'as roma': 'روما',
    'napoli': 'نابولي',
  };

  // شعارات الفرق للمفضلة
  static const Map<String, String> teamBadges = {
    'ريال مدريد': 'https://crests.football-data.org/86.png',
    'مانشستر سيتي': 'https://crests.football-data.org/65.png',
    'باريس سان جيرمان': 'https://crests.football-data.org/524.png',
    'برشلونة': 'https://crests.football-data.org/81.png',
    'ليفربول': 'https://crests.football-data.org/64.png',
    'أرسنال': 'https://crests.football-data.org/57.png',
    'أتلتيكو مدريد': 'https://crests.football-data.org/78.png',
    'بايرن ميونخ': 'https://crests.football-data.org/5.png',
  };

  // شعارات الدوريات للمفضلة
  static const Map<String, String> leagueBadges = {
    'CL': 'https://crests.football-data.org/CL.png',
    'PL': 'https://crests.football-data.org/PL.png',
    'PD': 'https://crests.football-data.org/PD.png',
    'SA': 'https://crests.football-data.org/SA.png',
    'BL1': 'https://crests.football-data.org/BL1.png',
    'FL1': 'https://crests.football-data.org/FL1.png',
    'EL': 'https://crests.football-data.org/EL.png',
  };

  // دالة ذكية تبحث عن تطابق الاسم بصيغة case-insensitive أو بالكلمات المفتاحية
  static String translateTeam(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final clean = name.trim().toLowerCase();

    // 1. فحص التطابق المباشر
    if (teamTranslations.containsKey(clean)) {
      return teamTranslations[clean]!;
    }

    // 2. فحص إذا كان الاسم يحتوي على الكلمة الأساسية
    for (final entry in teamTranslations.entries) {
      if (clean.contains(entry.key) || entry.key.contains(clean)) {
        return entry.value;
      }
    }

    return name;
  }

  // دالة ذكية لترجمة الدوريات
  static String translateLeague(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    final clean = name.trim().toLowerCase();

    if (leagueTranslations.containsKey(clean)) {
      return leagueTranslations[clean]!;
    }

    for (final entry in leagueTranslations.entries) {
      if (clean.contains(entry.key) || entry.key.contains(clean)) {
        return entry.value;
      }
    }

    return name;
  }
}
