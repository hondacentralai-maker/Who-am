class CouplesCard {
  final String id;
  final String deck;
  final String category;
  final String type;
  final String level;
  final String text;
  final String purpose;
  final String followUp;

  const CouplesCard({
    required this.id,
    this.deck = 'classic',
    required this.category,
    required this.type,
    required this.level,
    required this.text,
    required this.purpose,
    this.followUp = '',
  });

  factory CouplesCard.fromJson(Map<String, dynamic> json) => CouplesCard(
        id: json['id']?.toString() ?? '',
        deck: json['deck']?.toString() ?? 'classic',
        category: json['category']?.toString() ?? 'عام',
        type: json['type']?.toString() ?? 'سؤال',
        level: json['level']?.toString() ?? 'خفيف',
        text: json['text']?.toString() ?? '',
        purpose: json['purpose']?.toString() ?? '',
        followUp: json['follow_up']?.toString() ?? json['followUp']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'deck': deck,
        'category': category,
        'type': type,
        'level': level,
        'text': text,
        'purpose': purpose,
        'follow_up': followUp,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CouplesCard &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
