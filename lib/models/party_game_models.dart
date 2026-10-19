// Models and rich datasets for Group & Multiplayer Party Games.

// ─── 1. Stop Game («إنسان، حيوان، نبات، جماد، بلاد») ─────────────
class StopGameCategory {
  final String key;
  final String label;
  final String emoji;

  const StopGameCategory({
    required this.key,
    required this.label,
    required this.emoji,
  });
}

class StopGameData {
  static const List<String> arabicLetters = [
    'أ', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ',
    'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص',
    'ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق',
    'ك', 'ل', 'م', 'ن', 'هـ', 'و', 'ي'
  ];

  static const List<StopGameCategory> defaultCategories = [
    StopGameCategory(key: 'boy', label: 'اسم ولد', emoji: '👦'),
    StopGameCategory(key: 'girl', label: 'اسم بنت', emoji: '👧'),
    StopGameCategory(key: 'animal', label: 'حيوان', emoji: '🦁'),
    StopGameCategory(key: 'plant', label: 'نبات / أكل', emoji: '🌿'),
    StopGameCategory(key: 'inanimate', label: 'جماد', emoji: '📦'),
    StopGameCategory(key: 'country', label: 'بلد / مدينة', emoji: '🌍'),
    StopGameCategory(key: 'profession', label: 'مهنة / صفة', emoji: '💼'),
  ];
}

// ─── 2. Most Likely To («مين فينا؟ / مين أكثر واحدة؟») ──────────
class MostLikelyToPrompt {
  final String id;
  final String question;
  final String category;
  final String emoji;

  const MostLikelyToPrompt({
    required this.id,
    required this.question,
    required this.category,
    this.emoji = '🎭',
  });

  static List<MostLikelyToPrompt> defaultPrompts() {
    return [
      const MostLikelyToPrompt(id: 'ml_1', question: 'مين أكثر واحدة تتأخر في التجهيز للطلعات والمناسبات؟ 💄', category: 'عفوي', emoji: '💅'),
      const MostLikelyToPrompt(id: 'ml_2', question: 'مين أكثر واحدة تطلب أكل وتأكل من صحن غيرها؟ 🍟', category: 'مضحك', emoji: '🍔'),
      const MostLikelyToPrompt(id: 'ml_3', question: 'مين لو ربحت مليون تسافر فوراً وتنسى الجميع؟ ✈️', category: 'سفر', emoji: '🏖️'),
      const MostLikelyToPrompt(id: 'ml_4', question: 'مين أكثر واحدة تضيع جوالها أو مفاتيحها 3 مرات باليوم؟ 📱', category: 'عفوي', emoji: '🔍'),
      const MostLikelyToPrompt(id: 'ml_5', question: 'مين أكثر واحدة تضحك في أوقات غير مناسبة تماماً؟ 😂', category: 'مضحك', emoji: '🤭'),
      const MostLikelyToPrompt(id: 'ml_6', question: 'مين أكثر واحدة ترسل فويسات مدتها 5 دقائق متواصلة؟ 🎙️', category: 'سوشيال', emoji: '💬'),
      const MostLikelyToPrompt(id: 'ml_7', question: 'مين أكثر واحدة تبكي مع لقطات المسلسلات والأفلام؟ 🥺', category: 'مشاعر', emoji: '🎬'),
      const MostLikelyToPrompt(id: 'ml_8', question: 'مين أكثر واحدة تسوي شوبينج لأشياء ما تحتاجها أبداً؟ 🛍️', category: 'شوبينج', emoji: '💳'),
      const MostLikelyToPrompt(id: 'ml_9', question: 'مين أكثر واحدة تسهر للفجر وتصحى العصر؟ 🦉', category: 'روتين', emoji: '🌙'),
      const MostLikelyToPrompt(id: 'ml_10', question: 'مين أكثر واحدة تحفظ أسرار الجميع بدون ما تفشي كلمة؟ 🤫', category: 'وفاء', emoji: '🔐'),
      const MostLikelyToPrompt(id: 'ml_11', question: 'مين أكثر واحدة تنام بأي مكان وفي أي وضعية؟ 😴', category: 'مضحك', emoji: '🛌'),
      const MostLikelyToPrompt(id: 'ml_12', question: 'مين أكثر واحدة تسوي نفسها فاهمة بالسالفة وهي مضيعة؟ 🤷‍♀️', category: 'مضحك', emoji: '😎'),
      const MostLikelyToPrompt(id: 'ml_13', question: 'مين أكثر واحدة تصدق الشائعات بسرعة؟ 🫢', category: 'عفوي', emoji: '👀'),
      const MostLikelyToPrompt(id: 'ml_14', question: 'مين أكثر واحدة تطبخ أكل لذيذ وتبدع بالمطبخ؟ 👩‍🍳', category: 'طبخ', emoji: '🍲'),
      const MostLikelyToPrompt(id: 'ml_15', question: 'مين أكثر واحدة تسوي خطط وترتب الطلعات للجماعة؟ 📅', category: 'قيادة', emoji: '👑'),
    ];
  }
}

// ─── 3. Five-Second Rule («تحدي الـ 5 ثواني») ───────────────────
class FiveSecondPrompt {
  final String id;
  final String question;
  final String category;
  final String emoji;

  const FiveSecondPrompt({
    required this.id,
    required this.question,
    required this.category,
    this.emoji = '⏱️',
  });

  static List<FiveSecondPrompt> defaultPrompts() {
    return [
      const FiveSecondPrompt(id: 'fs_1', question: 'اذكري 3 ماركات مكياج أو عطور!', category: 'جمال', emoji: '💄'),
      const FiveSecondPrompt(id: 'fs_2', question: 'اذكري 3 أكلات شعبية خليجية!', category: 'طبخ', emoji: '🍲'),
      const FiveSecondPrompt(id: 'fs_3', question: 'اذكري 3 مسلسلات رمضانية مشهورة!', category: 'فن', emoji: '📺'),
      const FiveSecondPrompt(id: 'fs_4', question: 'اذكري 3 أشياء موجودة في حقيبة يدك!', category: 'يومي', emoji: '👜'),
      const FiveSecondPrompt(id: 'fs_5', question: 'اذكري 3 مدن سياحية تبدأ بحرف الـ د!', category: 'جغرافيا', emoji: '🌍'),
      const FiveSecondPrompt(id: 'fs_6', question: 'اذكري 3 مشروبات ساخنة غير القهوة والشاي!', category: 'كافيه', emoji: '☕'),
      const FiveSecondPrompt(id: 'fs_7', question: 'اذكري 3 حيوانات تبدأ بحرف الـ ك!', category: 'حيوانات', emoji: '🦁'),
      const FiveSecondPrompt(id: 'fs_8', question: 'اذكري 3 ألوان تبدأ بحرف الـ ف أو الـ ب!', category: 'ألوان', emoji: '🎨'),
      const FiveSecondPrompt(id: 'fs_9', question: 'اذكري 3 أنواع فواكه صيفية!', category: 'أكل', emoji: '🍉'),
      const FiveSecondPrompt(id: 'fs_10', question: 'اذكري 3 صفات تحبينها في الصديقة الوفية!', category: 'مشاعر', emoji: '💜'),
      const FiveSecondPrompt(id: 'fs_11', question: 'اذكري 3 تطبيقات تفتحينها يومياً أول ما تصحين!', category: 'تكنولوجيا', emoji: '📱'),
      const FiveSecondPrompt(id: 'fs_12', question: 'اذكري 3 أشياء لونها أحمر في غرفتك!', category: 'ملاحظة', emoji: '🔴'),
      const FiveSecondPrompt(id: 'fs_13', question: 'اذكري 3 دول أوربية لا تحتاج فيزا صعبة!', category: 'سفر', emoji: '✈️'),
      const FiveSecondPrompt(id: 'fs_14', question: 'اذكري 3 حلويات مشهورة بالعسل أو الشيرة!', category: 'حلى', emoji: '🍯'),
      const FiveSecondPrompt(id: 'fs_15', question: 'اذكري 3 أشياء تفعلينها لو انقطع الإنترنت!', category: 'عفوي', emoji: '🕯️'),
    ];
  }
}

// ─── 4. Spyfall («الجاسوس والمندَسّ») ─────────────────────────
class SpyfallLocation {
  final String id;
  final String name;
  final String emoji;
  final List<String> typicalRoles;

  const SpyfallLocation({
    required this.id,
    required this.name,
    required this.emoji,
    required this.typicalRoles,
  });

  static List<SpyfallLocation> defaultLocations() {
    return [
      const SpyfallLocation(
        id: 'loc_1',
        name: 'صالون تجميل وسبا',
        emoji: '💅',
        typicalRoles: ['أخصائية بشرة', 'زبونة', 'مصففة شعر', 'موظفة استقبال', 'خبيرة أظافر'],
      ),
      const SpyfallLocation(
        id: 'loc_2',
        name: 'مطار دولي',
        emoji: '✈️',
        typicalRoles: ['مضيفة طيران', 'مسافرة متأخرة', 'ضابط جوازات', 'طيار', 'سائحة'],
      ),
      const SpyfallLocation(
        id: 'loc_3',
        name: 'حفل زفاف فاخر',
        emoji: '👰',
        typicalRoles: ['العروس', 'أم العريس', 'المصورة', 'المطربة / الدي جي', 'ضيفة أنيقة'],
      ),
      const SpyfallLocation(
        id: 'loc_4',
        name: 'مخيم وكشتة في البر',
        emoji: '⛺',
        typicalRoles: ['طاهية الشواء', 'مسؤولة الشاي على الحطب', 'عازفة عود', 'النائمة في الخيمة'],
      ),
      const SpyfallLocation(
        id: 'loc_5',
        name: 'مستشفى وعيادة طوارئ',
        emoji: '🏥',
        typicalRoles: ['طبيبة جراحة', 'ممرضة', 'مريضة تتألم', 'زائرة قلقة', 'صيدلانية'],
      ),
      const SpyfallLocation(
        id: 'loc_6',
        name: 'مطعم سوشي فاخر',
        emoji: '🍣',
        typicalRoles: ['شيف ياباني', 'نادلة لبقة', 'زبونة تجرب لأول مرة', 'ناقدة طعام'],
      ),
      const SpyfallLocation(
        id: 'loc_7',
        name: 'مجمع تجاري (مول) وقت التخفيضات',
        emoji: '🛍️',
        typicalRoles: ['متسوقة متحمسة', 'حارس أمن', 'بائعة عطور', 'طفل تائه', 'كاشيرة'],
      ),
      const SpyfallLocation(
        id: 'loc_8',
        name: 'كافيه هادئ ومكتبة',
        emoji: '☕',
        typicalRoles: ['باريستا محترف', 'قارئة روايات', 'طالبة تذاكر', 'كاتبة خواطر'],
      ),
    ];
  }
}

// ─── 5. Taboo («قول بس لا تقول / المحظورات») ──────────────────
class TabooCard {
  final String id;
  final String targetWord;
  final List<String> forbiddenWords;
  final String category;
  final String emoji;

  const TabooCard({
    required this.id,
    required this.targetWord,
    required this.forbiddenWords,
    required this.category,
    this.emoji = '🤐',
  });

  static List<TabooCard> defaultCards() {
    return [
      const TabooCard(
        id: 'tb_1',
        targetWord: 'شاورما',
        forbiddenWords: ['دجاج', 'لحم', 'ثوم', 'مطعم'],
        category: 'طعام',
        emoji: '🌯',
      ),
      const TabooCard(
        id: 'tb_2',
        targetWord: 'كحل',
        forbiddenWords: ['عين', 'مكياج', 'أسود', 'رسمة'],
        category: 'جمال',
        emoji: '👁️',
      ),
      const TabooCard(
        id: 'tb_3',
        targetWord: 'طائرة',
        forbiddenWords: ['سفر', 'مطار', 'تطير', 'جواز'],
        category: 'سفر',
        emoji: '✈️',
      ),
      const TabooCard(
        id: 'tb_4',
        targetWord: 'قهوة عربي',
        forbiddenWords: ['هيل', 'دلة', 'فنجان', 'تمر'],
        category: 'تراث',
        emoji: '☕',
      ),
      const TabooCard(
        id: 'tb_5',
        targetWord: 'عرس',
        forbiddenWords: ['فستان', 'عروس', 'زواج', 'كوشة'],
        category: 'مناسبات',
        emoji: '💍',
      ),
      const TabooCard(
        id: 'tb_6',
        targetWord: 'سيلفي',
        forbiddenWords: ['صورة', 'جوال', 'كاميرا', 'إنستغرام'],
        category: 'سوشيال',
        emoji: '📸',
      ),
      const TabooCard(
        id: 'tb_7',
        targetWord: 'بحر',
        forbiddenWords: ['سمك', 'سباحة', 'شاطئ', 'رمل'],
        category: 'طبيعة',
        emoji: '🌊',
      ),
      const TabooCard(
        id: 'tb_8',
        targetWord: 'عطر',
        forbiddenWords: ['ريحة', 'بخور', 'رش', 'زجاجة'],
        category: 'جمال',
        emoji: '🌸',
      ),
    ];
  }
}

// ─── 6. Would You Rather («لو خيروك الجماعي») ────────────────
class WouldYouRatherPrompt {
  final String id;
  final String optionA;
  final String optionB;
  final String category;

  const WouldYouRatherPrompt({
    required this.id,
    required this.optionA,
    required this.optionB,
    required this.category,
  });

  static List<WouldYouRatherPrompt> defaultPrompts() {
    return [
      const WouldYouRatherPrompt(
        id: 'wyr_1',
        optionA: 'حياة بدون قهوة نهائياً ☕',
        optionB: 'حياة بدون إنترنت وسوشيال ميديا 📵',
        category: 'تحدي',
      ),
      const WouldYouRatherPrompt(
        id: 'wyr_2',
        optionA: 'شوبينج مجاني مفتوح لساعة واحدة 🛍️',
        optionB: 'سفرة سياحية لشهر كامل مدفوعة التكاليف ✈️',
        category: 'مكافأة',
      ),
      const WouldYouRatherPrompt(
        id: 'wyr_3',
        optionA: 'تقرأين أفكار الناس من حولك 🧠',
        optionB: 'تختفين في أي وقت تشائين 👻',
        category: 'خيال',
      ),
      const WouldYouRatherPrompt(
        id: 'wyr_4',
        optionA: 'تنامين 4 ساعات وتصحين بكامل نشاطك ⚡',
        optionB: 'تأكلين كل ما تشتهين بدون أي زيادة بالوزن 🍰',
        category: 'أمنيات',
      ),
      const WouldYouRatherPrompt(
        id: 'wyr_5',
        optionA: 'سهرة هادئة في البيت مع فيلم وحلى 🏠',
        optionB: 'طلعة كافيه ومطعم راقي ومزدحم 🍽️',
        category: 'أجواء',
      ),
      const WouldYouRatherPrompt(
        id: 'wyr_6',
        optionA: 'تعيشين في الماضي بعصر الأميرات 👑',
        optionB: 'تعيشين في المستقبل بعد 100 سنة 🚀',
        category: 'زمن',
      ),
    ];
  }
}
