enum ConnectionStatus {
  online,
  reconnecting,
  offline,
}

/// Represents real-time presence and connection status of a partner in a room.
class PartnerPresence {
  final String userId;
  final String role; // 'host' or 'guest'
  final String displayName;
  final ConnectionStatus status;
  final DateTime? lastSeen;

  const PartnerPresence({
    required this.userId,
    required this.role,
    this.displayName = '',
    this.status = ConnectionStatus.offline,
    this.lastSeen,
  });

  bool get isOnline => status == ConnectionStatus.online;
  bool get isReconnecting => status == ConnectionStatus.reconnecting;
  bool get isOffline => status == ConnectionStatus.offline;

  String get statusTextArabic {
    switch (status) {
      case ConnectionStatus.online:
        return 'متصل الآن';
      case ConnectionStatus.reconnecting:
        return 'يعيد الاتصال...';
      case ConnectionStatus.offline:
        return 'غير متصل';
    }
  }

  String get roleArabic => role == 'host' ? 'المضيف' : 'الضيف';

  PartnerPresence copyWith({
    String? userId,
    String? role,
    String? displayName,
    ConnectionStatus? status,
    DateTime? lastSeen,
  }) {
    return PartnerPresence(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'role': role,
        'display_name': displayName,
        'last_seen': lastSeen?.toIso8601String(),
      };

  factory PartnerPresence.fromJson(Map<String, dynamic> json) {
    return PartnerPresence(
      userId: json['user_id'] as String? ?? '',
      role: json['role'] as String? ?? 'guest',
      displayName: json['display_name'] as String? ?? '',
      status: ConnectionStatus.online,
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'] as String)
          : null,
    );
  }
}
