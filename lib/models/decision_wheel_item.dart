/// Represents an option/sector on the Couples Decision Wheel.
class DecisionWheelItem {
  final String id;
  final String label;
  final String category;
  final String emoji;
  final int colorValue;

  const DecisionWheelItem({
    required this.id,
    required this.label,
    required this.category,
    required this.emoji,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'category': category,
        'emoji': emoji,
        'color_value': colorValue,
      };

  factory DecisionWheelItem.fromJson(Map<String, dynamic> json) {
    return DecisionWheelItem(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      category: json['category']?.toString() ?? 'عام',
      emoji: json['emoji']?.toString() ?? '🎯',
      colorValue: json['color_value'] as int? ?? 0xFF7047D7,
    );
  }

  /// Default preset categories for couples.
  static List<DecisionWheelItem> defaultItems() {
    return [
      // 1. Food Category (وش نتعشى الليلة؟)
      const DecisionWheelItem(
        id: 'food_1',
        label: 'بيتزا نابولية',
        category: 'عشاء الليلة؟ 🍕',
        emoji: '🍕',
        colorValue: 0xFFE53935,
      ),
      const DecisionWheelItem(
        id: 'food_2',
        label: 'شاورما عربي',
        category: 'عشاء الليلة؟ 🍕',
        emoji: '🌯',
        colorValue: 0xFFFB8C00,
      ),
      const DecisionWheelItem(
        id: 'food_3',
        label: 'برجر وسماش',
        category: 'عشاء الليلة؟ 🍕',
        emoji: '🍔',
        colorValue: 0xFFFDD835,
      ),
      const DecisionWheelItem(
        id: 'food_4',
        label: 'طبخ بيت دافئ',
        category: 'عشاء الليلة؟ 🍕',
        emoji: '🍲',
        colorValue: 0xFF43A047,
      ),
      const DecisionWheelItem(
        id: 'food_5',
        label: 'سوشي رومانسي',
        category: 'عشاء الليلة؟ 🍕',
        emoji: '🍣',
        colorValue: 0xFF00ACC1,
      ),
      const DecisionWheelItem(
        id: 'food_6',
        label: 'مشاوي وكباب',
        category: 'عشاء الليلة؟ 🍕',
        emoji: '🍢',
        colorValue: 0xFF8E24AA,
      ),

      // 2. Evening Activity (سهرة الليلة؟ 🎬)
      const DecisionWheelItem(
        id: 'activity_1',
        label: 'فيلم كوميدي وضحك',
        category: 'سهرة الليلة؟ 🎬',
        emoji: '😂',
        colorValue: 0xFFE91E63,
      ),
      const DecisionWheelItem(
        id: 'activity_2',
        label: 'طلعة بالسيارة وقهوة',
        category: 'سهرة الليلة؟ 🎬',
        emoji: '🚗',
        colorValue: 0xFF3949AB,
      ),
      const DecisionWheelItem(
        id: 'activity_3',
        label: 'جلسة حوار وشاي',
        category: 'سهرة الليلة؟ 🎬',
        emoji: '🍵',
        colorValue: 0xFF00897B,
      ),
      const DecisionWheelItem(
        id: 'activity_4',
        label: 'مساج وتدليك 10 دقائق',
        category: 'سهرة الليلة؟ 🎬',
        emoji: '💆',
        colorValue: 0xFF7CB342,
      ),
      const DecisionWheelItem(
        id: 'activity_5',
        label: 'مسلسل جديد',
        category: 'سهرة الليلة؟ 🎬',
        emoji: '📺',
        colorValue: 0xFFFFB300,
      ),
      const DecisionWheelItem(
        id: 'activity_6',
        label: 'لعبة خمن الشخصية',
        category: 'سهرة الليلة؟ 🎬',
        emoji: '🎭',
        colorValue: 0xFF5E35B1,
      ),

      // 3. Pampering Challenge (تحدي الدلع اللحظي 💆)
      const DecisionWheelItem(
        id: 'treat_1',
        label: 'تدليك أكتاف 5 دقائق',
        category: 'تحدي الدلع 💆',
        emoji: '💆‍♂️',
        colorValue: 0xFFD81B60,
      ),
      const DecisionWheelItem(
        id: 'treat_2',
        label: 'فنجان قهوة بمزاج',
        category: 'تحدي الدلع 💆',
        emoji: '☕',
        colorValue: 0xFF6D4C41,
      ),
      const DecisionWheelItem(
        id: 'treat_3',
        label: '3 كلمات غزل صادقة',
        category: 'تحدي الدلع 💆',
        emoji: '💌',
        colorValue: 0xFF8E24AA,
      ),
      const DecisionWheelItem(
        id: 'treat_4',
        label: 'إعفاء من غسيل الصحون',
        category: 'تحدي الدلع 💆',
        emoji: '🍽️',
        colorValue: 0xFF1E88E5,
      ),
      const DecisionWheelItem(
        id: 'treat_5',
        label: 'حضن دافئ دقيقة كاملة',
        category: 'تحدي الدلع 💆',
        emoji: '🤗',
        colorValue: 0xFFFB8C00,
      ),
      const DecisionWheelItem(
        id: 'treat_6',
        label: 'حلى وشوكولاتة الليلة',
        category: 'تحدي الدلع 💆',
        emoji: '🍫',
        colorValue: 0xFF43A047,
      ),
    ];
  }
}
