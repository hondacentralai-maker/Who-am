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

// ─── 7. Feen El So2al («فين السؤال؟» - مستوحاة من فكرة Meego Studios) ───
class FeenElSo2alPrompt {
  final String id;
  final String answer; // الإجابة الظاهرة
  final String correctQuestion; // السؤال المخفي الحقيقي
  final List<String> wrongQuestions; // أسئلة تمويهية
  final String category;
  final String emoji;

  const FeenElSo2alPrompt({
    required this.id,
    required this.answer,
    required this.correctQuestion,
    required this.wrongQuestions,
    required this.category,
    this.emoji = '❓',
  });

  List<String> get allOptions {
    final list = [correctQuestion, ...wrongQuestions];
    list.shuffle();
    return list;
  }

  static List<FeenElSo2alPrompt> defaultPrompts() {
    return [
      const FeenElSo2alPrompt(
        id: 'fes_1',
        answer: '«عملت نفسي نايم عشان محدش يطلب مني أنزل أجيب عيش أو أرمي الزبالة!» 😴',
        correctQuestion: 'إيه أكبر حركة كسل عملتها في بيتك الأسبوع ده؟',
        wrongQuestions: [
          'إيه أكتر موقف نمت فيه بدون قصد في الشارع؟',
          'بتعمل إيه لما يدخل عليك حرامي في البيت؟',
          'إيه اللي بتعمله لما يجيلك ضيوف دمهم تقيل؟',
        ],
        category: 'كسل ومواقف',
        emoji: '🛌',
      ),
      const FeenElSo2alPrompt(
        id: 'fes_2',
        answer: '«صرفت كل الفلوس اللي كانت معايا على أكلة مكنتش مستاهلة ربع تمنها!» 💸',
        correctQuestion: 'إيه أكتر قرار مالي عشوائي ندمت عليه فوراً؟',
        wrongQuestions: [
          'إيه أحسن استثمار عملته في حياتك؟',
          'بتعمل إيه لو كسبت في مسابقة مليون جنيه؟',
          'إيه الحاجة اللي بتشتريها أول ما تقبض المرتب؟',
        ],
        category: 'فلوس وشوبينج',
        emoji: '🍔',
      ),
      const FeenElSo2alPrompt(
        id: 'fes_3',
        answer: '«اتصلت بماما واشتكيتلها وفضلت أعيط نص ساعة كأني طفل صغير!» 🥺',
        correctQuestion: 'بتعمل إيه لما تحس إن الدنيا قفلت في وشك ومحدش فاهمك؟',
        wrongQuestions: [
          'إيه أسوأ دراما عملتها عشان تتهرب من الشغل؟',
          'إزاي بتصالح أعز صديق ليك لما يزعل منك؟',
          'إيه الموقف اللي خلاك تضحك لحد ما عيونك دمعت؟',
        ],
        category: 'مشاعر وفضفضة',
        emoji: '📞',
      ),
      const FeenElSo2alPrompt(
        id: 'fes_4',
        answer: '«فتحت الموبايل وعملت نفسي بكلم حد مهم عشان مأسلمش على حد شفته في الشارع!» 📱',
        correctQuestion: 'إيه أكتر تصرف محرج عملته عشان تتفادى تقابل شخص تعرفه؟',
        wrongQuestions: [
          'إيه أكتر مكالمة غيرت مجرى حياتك؟',
          'إزاي بتتصرف لما موبايلك يرن في عز صلاة الجمعة؟',
          'بتعمل إيه لو نسيت باسورد موبايلك؟',
        ],
        category: 'مواقف محرجة',
        emoji: '🕶️',
      ),
      const FeenElSo2alPrompt(
        id: 'fes_5',
        answer: '«قلتله تحفة ولايق عليك جداً.. مع إنه كان كارثة حقيقية!» 👗',
        correctQuestion: 'إيه أكبر كذبة بيضا ومجاملة مجبر عليها قلتها لصاحبك؟',
        wrongQuestions: [
          'إيه أكتر نصيحة صادقة قلتها في وش حد وندمت؟',
          'رأيك إيه في الموضة والأزياء السنادي؟',
          'بتتصرف إزاي لو حد سرق منك فكرتك؟',
        ],
        category: 'صداقة ومجاملات',
        emoji: '💅',
      ),
      const FeenElSo2alPrompt(
        id: 'fes_6',
        answer: '«أكلت نص صينية البشاميل لوحدي بالليل ومسحت أثر الجريمة بالمنديل!» 😋',
        correctQuestion: 'إيه أكبر جريمة مطبخ نص الليل عملتها ومحدش عرفها؟',
        wrongQuestions: [
          'إيه الأكلة اللي لو اتعرضت عليك ترفضها فوراً؟',
          'إيه سر أحلى وصفة بتعرف تعملها؟',
          'إيه أكتر حاجة دايماً بتنساها في السوبرماركت؟',
        ],
        category: 'جرائم التلاجة',
        emoji: '🍲',
      ),
    ];
  }
}

// ─── 8. Besaraha & Wal3a («بصراحة وتحديات ولعة») ────────────────
enum BesarahaWal3aType { saraha, dare, luck }

class BesarahaWal3aCard {
  final String id;
  final BesarahaWal3aType type;
  final String title;
  final String content;
  final String category;
  final int points;
  final String emoji;

  const BesarahaWal3aCard({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.category,
    required this.points,
    required this.emoji,
  });

  static List<BesarahaWal3aCard> defaultCards() {
    return [
      // بصراحة (Saraha)
      const BesarahaWal3aCard(
        id: 'bw_1',
        type: BesarahaWal3aType.saraha,
        title: 'بصراحة 💬',
        content: 'إيه الشيء اللي كل الناس بتمدحه فيك وأنت من جواك حاسس إنه مش حقيقي ومبالغ فيه؟',
        category: 'اعتراف',
        points: 10,
        emoji: '🎭',
      ),
      const BesarahaWal3aCard(
        id: 'bw_2',
        type: BesarahaWal3aType.saraha,
        title: 'بصراحة 💬',
        content: 'مين أكتر شخص في الجلسة دي بتحس إنك لو وقعت في مشكلة كبيرة هتتصل بيه أول واحد وليه؟',
        category: 'ثقة',
        points: 10,
        emoji: '🤝',
      ),
      const BesarahaWal3aCard(
        id: 'bw_3',
        type: BesarahaWal3aType.saraha,
        title: 'بصراحة 💬',
        content: 'إيه أكتر موقف حسيت فيه بالغيرة أو المقارنة من حد قريب منك بدون ما تصارحه؟',
        category: 'مشاعر',
        points: 15,
        emoji: '👀',
      ),

      // ولعة وأحكام (Dare)
      const BesarahaWal3aCard(
        id: 'bw_4',
        type: BesarahaWal3aType.dare,
        title: 'حكم ولعة 🔥',
        content: 'اتصل بحد عشوائي من جهات اتصالك وقوله «أنا آسف على اللي حصل زمان» واقفل الخط فوراً بدون تفسير!',
        category: 'جرأة وتحدي',
        points: 20,
        emoji: '🔥',
      ),
      const BesarahaWal3aCard(
        id: 'bw_5',
        type: BesarahaWal3aType.dare,
        title: 'حكم ولعة 🔥',
        content: 'تكلم بلهجة غريبة (خليجي أو شامي أو صعيدي) طول الدائرتين الجايين، وكل كلمة فصحى تخصم نقطة!',
        category: 'تمثيل ومرح',
        points: 15,
        emoji: '🎬',
      ),
      const BesarahaWal3aCard(
        id: 'bw_6',
        type: BesarahaWal3aType.dare,
        title: 'حكم ولعة 🔥',
        content: 'سلم موبايلك للشخص اللي على يمينك يختار صورة من معرض الصور ويعرضها على كل الجالسين!',
        category: 'مخاطرة كبرى',
        points: 25,
        emoji: '📸',
      ),

      // كروت الحظ (Luck)
      const BesarahaWal3aCard(
        id: 'bw_7',
        type: BesarahaWal3aType.luck,
        title: 'كرت حظ: إعفاء كامل! 🛡️',
        content: 'مبروك! كرت درع الحماية، احتفظ بيه واستخدمه للإعفاء من أي حكم قادم أو مرره لشخص تاني.',
        category: 'حظ ومفاجآت',
        points: 10,
        emoji: '🌟',
      ),
      const BesarahaWal3aCard(
        id: 'bw_8',
        type: BesarahaWal3aType.luck,
        title: 'كرت حظ: حكم مضاعف! ⚡',
        content: 'يا ويلك! اختار لاعب يشاركك الحكم القادم أو نفذ التحدي القادم بنقاط مضاعفة x2!',
        category: 'حظ ناري',
        points: 5,
        emoji: '⚡',
      ),
    ];
  }
}

// ─── 9. Family Stories («حكاوي العيلة والذكريات») ───────────────
class FamilyStoriesPrompt {
  final String id;
  final String topic;
  final String question;
  final String subtext;
  final String category;
  final String emoji;

  const FamilyStoriesPrompt({
    required this.id,
    required this.topic,
    required this.question,
    required this.subtext,
    required this.category,
    this.emoji = '🏡',
  });

  static List<FamilyStoriesPrompt> defaultPrompts() {
    return [
      const FamilyStoriesPrompt(
        id: 'fam_1',
        topic: 'أيام الطفولة والشيطنة 🧒',
        question: 'مين أكتر واحد في العيلة كان بيعمل مصايب في طفولته ويلبسها في إخواته؟ احكوا أكبر مصيبة!',
        subtext: 'كل واحد من الكبار يقول شهادته على الواقعة الشهيرة.',
        category: 'ذكريات',
        emoji: '🏃‍♂️',
      ),
      const FamilyStoriesPrompt(
        id: 'fam_2',
        topic: 'أكلات ومطبخ زمان 🍲',
        question: 'إيه الأكلة أو الحلو اللي لما بيتعمل في بيت العيلة بتفتكروا بيه لِمة زمان وريحة الحبايب؟',
        subtext: 'شاركوا الوصفة أو الموقف المرتبط بيها.',
        category: 'بركة ولمة',
        emoji: '🥘',
      ),
      const FamilyStoriesPrompt(
        id: 'fam_3',
        topic: 'أول عربية وأول سفرية 🚗',
        question: 'احكوا حكاية أول مصيف أو سفرية عائلية بالعربية ومين اللي كان بيتخانق على الشباك!',
        subtext: 'مواقف المصايف الكوميدية على البحر ومحطات البنزين.',
        category: 'سفر عائلي',
        emoji: '🏖️',
      ),
      const FamilyStoriesPrompt(
        id: 'fam_4',
        topic: 'حكم ومواقف الأجداد 👴👵',
        question: 'إيه أكتر نصيحة أو مثل كان الجد أو الجدة دايماً بيكرروه ولسه بيرن في ودانكم لحد النهاردة؟',
        subtext: 'دعوة وترحم وذكرى طيبة لبركة العيلة.',
        category: 'أصول وحكمة',
        emoji: '🤍',
      ),
      const FamilyStoriesPrompt(
        id: 'fam_5',
        topic: 'سر محدش كان يعرفه! 🤫',
        question: 'إيه المقلب أو الكذبة الصغيرة اللي عملتوها زمان في البيت وأهاليكم لسه ميعرفوش حقيقتها لحد دلوقتي؟',
        subtext: 'حان وقت كشف المستور بما إن عدى عليها سنين!',
        category: 'اعترافات',
        emoji: '🔍',
      ),
    ];
  }
}

// ─── 10. Girls Lakin («جلسات البنات - Girls ولكن») ──────────────
class GirlsLakinPrompt {
  final String id;
  final String situation;
  final String challenge;
  final String category;
  final String emoji;

  const GirlsLakinPrompt({
    required this.id,
    required this.situation,
    required this.challenge,
    required this.category,
    this.emoji = '💅',
  });

  static List<GirlsLakinPrompt> defaultPrompts() {
    return [
      const GirlsLakinPrompt(
        id: 'gl_1',
        situation: 'لقيتي صديقتك خارجة بلبس ألوانه مش راكبة على بعض ومتحمسة جداً..',
        challenge: 'هتصدميها بالحقيقة في ساعتها عشان تلحق تغير ولا هتمدحيها عشان متكسفيهاش؟',
        category: 'ستايل وصراحة',
        emoji: '👗',
      ),
      const GirlsLakinPrompt(
        id: 'gl_2',
        situation: 'جلسة سهرانين وطلبتوا دايت بس جه الكريب بالنوتيلا والببلز قدامكم..',
        challenge: 'مين أول واحدة هتقول «الدايت بيبدأ من السبت الجاي» وتهجم على الأكل؟',
        category: 'أكل ومزاج',
        emoji: '🍫',
      ),
      const GirlsLakinPrompt(
        id: 'gl_3',
        situation: 'فويس نوت مدته 8 دقائق من واحدة صاحبتكم فيها حوار كبير..',
        challenge: 'مين اللي بتسمعه على سرعة 2x ومين اللي بتعمل نفسها سمعته وتكتب «يا لهوي بجد؟»!',
        category: 'سوشيال ورغي',
        emoji: '🎙️',
      ),
      const GirlsLakinPrompt(
        id: 'gl_4',
        situation: 'تحدي حقيبة اليد: طلعي أغرب حاجة موجودة في شنطتك دلوقتي حالاً!',
        challenge: 'صاحبة أغرب أو أقدم حاجة (روج قديم، فاتورة من 2022، بنسة شعر ضايعة) تكسب!',
        category: 'تحدي لحظي',
        emoji: '👜',
      ),
      const GirlsLakinPrompt(
        id: 'gl_5',
        situation: 'مين أكتر واحدة لو اتعصبت بتقلب المحادثة لتحقيق بوليسي وتجيب تواريخ وسكرين شوتس؟',
        challenge: 'تصويت سريع من الصديقات مع ذكر مثال شهير!',
        category: 'تحريات بنات',
        emoji: '🕵️‍♀️',
      ),
    ];
  }
}

// ─── 11. Hatrick («هاتريك - تحدي وأسئلة كروية») ─────────────────
class HatrickPrompt {
  final String id;
  final String question;
  final String answer;
  final String category;
  final String emoji;

  const HatrickPrompt({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.emoji = '⚽',
  });

  static List<HatrickPrompt> defaultPrompts() {
    return [
      const HatrickPrompt(
        id: 'ht_1',
        question: 'مين اللاعب المصري الوحيد اللي فاز بجائزة أفضل لاعب في إفريقيا مرتين متتاليتين في العصر الحديث؟',
        answer: 'محمد صلاح (2017 و 2018) 👑',
        category: 'نجوم مصر',
        emoji: '🇪🇬',
      ),
      const HatrickPrompt(
        id: 'ht_2',
        question: 'مين الفريق صاحب الرقم القياسي في الفوز بلقب دوري أبطال إفريقيا عبر التاريخ؟',
        answer: 'النادي الأهلي المصري 🦅 (12 لقب)',
        category: 'بطولات إفريقية',
        emoji: '🏆',
      ),
      const HatrickPrompt(
        id: 'ht_3',
        question: 'في أي دولة أقيمت بطولة كأس العالم 2022، ومين كان بطل تلك النسخة؟',
        answer: 'قطر 🇶🇦، والبطل الأرجنتين 🇦🇷 بقيادة ميسي',
        category: 'كأس العالم',
        emoji: '🌍',
      ),
      const HatrickPrompt(
        id: 'ht_4',
        question: 'مين هو الهداف التاريخي لبطولة دوري أبطال أوروبا على مر العصور؟',
        answer: 'كريستيانو رونالدو (140 هدفاً) 🐐',
        category: 'دوري الأبطال',
        emoji: '⭐',
      ),
      const HatrickPrompt(
        id: 'ht_5',
        question: 'مين النادي الإسباني صاحب أكبر عدد ألقاب في الدوري الإسباني (الليغا)؟',
        answer: 'ريال مدريد 👑',
        category: 'الدوريات الأوروبية',
        emoji: '🇪🇸',
      ),
      const HatrickPrompt(
        id: 'ht_6',
        question: 'تحدي هاتريك سريع: اذكر 3 لاعبين مصريين احترفوا في الدوري الإنجليزي الممتاز (البريميرليج)!',
        answer: 'أمثلة: محمد صلاح، أحمد حسام ميدو، محمد النني، عمرو زكي، حسام غالي...',
        category: 'تحدي سرعة',
        emoji: '⚡',
      ),
    ];
  }
}


