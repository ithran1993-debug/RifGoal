class FootballTranslations {
static const Map<String, String> teams = {
// إسبانيا
'Real Madrid': 'ريال مدريد',
'FC Barcelona': 'برشلونة',
'Barcelona': 'برشلونة',
'Atletico Madrid': 'أتلتيكو مدريد',
'Sevilla': 'إشبيلية',
'Valencia': 'فالنسيا',
'Real Sociedad': 'ريال سوسيداد',
'Athletic Club': 'أتلتيك بلباو',
'Villarreal': 'فياريال',
'Real Betis': 'ريال بيتيس',
'Girona': 'جيرونا',

// إنجلترا
'Manchester City': 'مانشستر سيتي',
'Manchester United': 'مانشستر يونايتد',
'Liverpool': 'ليفربول',
'Arsenal': 'أرسنال',
'Chelsea': 'تشيلسي',
'Tottenham Hotspur': 'توتنهام',
'Newcastle United': 'نيوكاسل يونايتد',
'Aston Villa': 'أستون فيلا',
'West Ham United': 'وست هام',
'Everton': 'إيفرتون',
'Leicester City': 'ليستر سيتي',
'Brighton': 'برايتون',
'Wolverhampton Wanderers': 'ولفرهامبتون',
'Crystal Palace': 'كريستال بالاس',
'Nottingham Forest': 'نوتنغهام فورست',
'Fulham': 'فولهام',
'Brentford': 'برينتفورد',
'Bournemouth': 'بورنموث',

// إيطاليا
'Inter': 'إنتر ميلان',
'Inter Milan': 'إنتر ميلان',
'AC Milan': 'ميلان',
'Juventus': 'يوفنتوس',
'Napoli': 'نابولي',
'Roma': 'روما',
'Lazio': 'لاتسيو',
'Atalanta': 'أتالانتا',
'Fiorentina': 'فيورنتينا',
'Torino': 'تورينو',

// ألمانيا
'Bayern Munich': 'بايرن ميونخ',
'Borussia Dortmund': 'بوروسيا دورتموند',
'Bayer Leverkusen': 'باير ليفركوزن',
'RB Leipzig': 'لايبزيغ',
'Eintracht Frankfurt': 'آينتراخت فرانكفورت',
'VfB Stuttgart': 'شتوتغارت',
'Wolfsburg': 'فولفسبورغ',

// فرنسا
'Paris Saint Germain': 'باريس سان جيرمان',
'Paris Saint-Germain': 'باريس سان جيرمان',
'PSG': 'باريس سان جيرمان',
'Marseille': 'مارسيليا',
'Lyon': 'ليون',
'Monaco': 'موناكو',
'Lille': 'ليل',
'Nice': 'نيس',
'Rennes': 'رين',
'Lens': 'لانس',

// المغرب
'Raja Casablanca': 'الرجاء الرياضي',
'Raja Club Athletic': 'الرجاء الرياضي',
'Wydad Casablanca': 'الوداد الرياضي',
'Wydad Athletic Club': 'الوداد الرياضي',
'FAR Rabat': 'الجيش الملكي',
'AS FAR': 'الجيش الملكي',
'Renaissance Berkane': 'نهضة بركان',
'RS Berkane': 'نهضة بركان',
'FUS Rabat': 'الفتح الرياضي',
'Maghreb Fes': 'المغرب الفاسي',
'Moghreb Tetouan': 'المغرب التطواني',
'Ittihad Tanger': 'اتحاد طنجة',
'Hassania Agadir': 'حسنية أكادير',

};

static const Map<String, String> leagues = {
'UEFA Champions League': 'دوري أبطال أوروبا',
'Champions League': 'دوري أبطال أوروبا',
'Premier League': 'الدوري الإنجليزي الممتاز',
'La Liga': 'الدوري الإسباني',
'Primera Division': 'الدوري الإسباني',
'Serie A': 'الدوري الإيطالي',
'Bundesliga': 'الدوري الألماني',
'Ligue 1': 'الدوري الفرنسي',
'Botola Pro': 'البطولة الاحترافية المغربية',
'Botola Pro 1': 'البطولة الاحترافية المغربية',
'CAF Champions League': 'دوري أبطال إفريقيا',
'Europa League': 'الدوري الأوروبي',
'UEFA Europa League': 'الدوري الأوروبي',
'FA Cup': 'كأس الاتحاد الإنجليزي',
'Copa del Rey': 'كأس ملك إسبانيا',
'Coppa Italia': 'كأس إيطاليا',
'DFB Pokal': 'كأس ألمانيا',
'Coupe de France': 'كأس فرنسا',
};

static String team(String? name) {
if (name == null || name.trim().isEmpty) return '';
return teams[name.trim()] ?? name;
}

static String league(String? name) {
if (name == null || name.trim().isEmpty) return '';
return leagues[name.trim()] ?? name;
}
}
