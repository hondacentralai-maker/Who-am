/// Represents the shared profile and identity of the couple.
class CouplesProfile {
  final String partner1Name;
  final String partner2Name;
  final DateTime startDate;
  final String specialTitle;
  final String partnerCode;
  final String? linkedPartnerEmail;
  final String? linkedPartnerId;

  const CouplesProfile({
    this.partner1Name = 'أنا',
    this.partner2Name = 'شريكي',
    required this.startDate,
    this.specialTitle = 'ذكرى ارتباطنا',
    required this.partnerCode,
    this.linkedPartnerEmail,
    this.linkedPartnerId,
  });

  /// Total days together since [startDate].
  int get daysTogether {
    final now = DateTime.now();
    final cleanStart = DateTime(startDate.year, startDate.month, startDate.day);
    final cleanNow = DateTime(now.year, now.month, now.day);
    final diff = cleanNow.difference(cleanStart).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Days remaining until the next anniversary.
  int get daysUntilNextAnniversary {
    final now = DateTime.now();
    var next = DateTime(now.year, startDate.month, startDate.day);
    if (next.isBefore(DateTime(now.year, now.month, now.day))) {
      next = DateTime(now.year + 1, startDate.month, startDate.day);
    }
    return next.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  bool get isPartnerLinked =>
      (linkedPartnerEmail != null && linkedPartnerEmail!.isNotEmpty) ||
      (linkedPartnerId != null && linkedPartnerId!.isNotEmpty);

  CouplesProfile copyWith({
    String? partner1Name,
    String? partner2Name,
    DateTime? startDate,
    String? specialTitle,
    String? partnerCode,
    String? linkedPartnerEmail,
    String? linkedPartnerId,
    bool clearLinkedPartner = false,
  }) {
    return CouplesProfile(
      partner1Name: partner1Name ?? this.partner1Name,
      partner2Name: partner2Name ?? this.partner2Name,
      startDate: startDate ?? this.startDate,
      specialTitle: specialTitle ?? this.specialTitle,
      partnerCode: partnerCode ?? this.partnerCode,
      linkedPartnerEmail: clearLinkedPartner
          ? null
          : (linkedPartnerEmail ?? this.linkedPartnerEmail),
      linkedPartnerId: clearLinkedPartner
          ? null
          : (linkedPartnerId ?? this.linkedPartnerId),
    );
  }

  Map<String, dynamic> toJson() => {
        'partner1_name': partner1Name,
        'partner2_name': partner2Name,
        'start_date': startDate.toIso8601String(),
        'special_title': specialTitle,
        'partner_code': partnerCode,
        'linked_partner_email': linkedPartnerEmail,
        'linked_partner_id': linkedPartnerId,
      };

  factory CouplesProfile.fromJson(Map<String, dynamic> json) {
    return CouplesProfile(
      partner1Name: json['partner1_name']?.toString() ?? 'أنا',
      partner2Name: json['partner2_name']?.toString() ?? 'شريكي',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString()) ??
              DateTime(2024, 1, 1)
          : DateTime(2024, 1, 1),
      specialTitle: json['special_title']?.toString() ?? 'ذكرى ارتباطنا',
      partnerCode: json['partner_code']?.toString() ?? 'LOVE-7777',
      linkedPartnerEmail: json['linked_partner_email']?.toString(),
      linkedPartnerId: json['linked_partner_id']?.toString(),
    );
  }
}
