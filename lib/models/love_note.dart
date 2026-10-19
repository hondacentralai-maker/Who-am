/// Represents a romantic note or time capsule entry for couples.
class LoveNote {
  final String id;
  final String authorName;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? unlockDate;
  final bool isOpened;
  final String emoji;

  const LoveNote({
    required this.id,
    required this.authorName,
    required this.title,
    required this.content,
    required this.createdAt,
    this.unlockDate,
    this.isOpened = false,
    this.emoji = '💌',
  });

  /// Indicates if this note is currently locked as a time capsule.
  bool get isLocked {
    if (unlockDate == null) return false;
    return DateTime.now().isBefore(unlockDate!);
  }

  /// Calculates the remaining days until this capsule unlocks.
  int get daysUntilUnlock {
    if (unlockDate == null) return 0;
    final diff = unlockDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  LoveNote copyWith({
    String? id,
    String? authorName,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? unlockDate,
    bool? isOpened,
    String? emoji,
  }) {
    return LoveNote(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      unlockDate: unlockDate ?? this.unlockDate,
      isOpened: isOpened ?? this.isOpened,
      emoji: emoji ?? this.emoji,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_name': authorName,
        'title': title,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'unlock_date': unlockDate?.toIso8601String(),
        'is_opened': isOpened,
        'emoji': emoji,
      };

  factory LoveNote.fromJson(Map<String, dynamic> json) {
    return LoveNote(
      id: json['id']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? 'شريكي',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      unlockDate: json['unlock_date'] != null
          ? DateTime.tryParse(json['unlock_date'].toString())
          : null,
      isOpened: json['is_opened'] == true,
      emoji: json['emoji']?.toString() ?? '💌',
    );
  }
}
