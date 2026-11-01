import 'dart:convert';

/// Represents a structured bidirectional message exchanged between
/// Flutter and Unity 3D runtime.
class UnityMessage {
  /// The name of the Unity GameObject in the active scene (e.g. "GameManager", "JackarooBoard").
  final String gameObject;

  /// The C# method name to invoke on the target GameObject (e.g. "OnFlutterMessage", "PlayCard").
  final String methodName;

  /// The raw string or JSON payload to pass to the C# method.
  final String payload;

  /// Optional timestamp for message tracking.
  final DateTime timestamp;

  UnityMessage({
    required this.gameObject,
    required this.methodName,
    required this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a [UnityMessage] with a structured Map data payload serialized to JSON.
  factory UnityMessage.json({
    required String gameObject,
    required String methodName,
    required Map<String, dynamic> data,
  }) {
    return UnityMessage(
      gameObject: gameObject,
      methodName: methodName,
      payload: jsonEncode(data),
    );
  }

  /// Parses a raw string received from Unity C# (expects either JSON or raw text).
  factory UnityMessage.fromRaw(String rawMessage, {String defaultGameObject = 'FlutterManager', String defaultMethod = 'OnMessage'}) {
    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is Map<String, dynamic>) {
        return UnityMessage(
          gameObject: decoded['gameObject']?.toString() ?? defaultGameObject,
          methodName: decoded['methodName']?.toString() ?? defaultMethod,
          payload: decoded['payload']?.toString() ?? (decoded['data'] != null ? jsonEncode(decoded['data']) : rawMessage),
        );
      }
    } catch (_) {
      // Not a JSON map, treat as raw payload string
    }

    return UnityMessage(
      gameObject: defaultGameObject,
      methodName: defaultMethod,
      payload: rawMessage,
    );
  }

  /// Attempts to decode the payload as a JSON map. Returns empty map if invalid.
  Map<String, dynamic> get payloadJson {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return <String, dynamic>{'raw': payload};
  }

  /// Serializes the entire message to a JSON string for cross-process transport.
  String toJsonString() {
    return jsonEncode({
      'gameObject': gameObject,
      'methodName': methodName,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  @override
  String toString() => 'UnityMessage(target: $gameObject.$methodName, payload: $payload)';
}

/// Standard game events communicated between Flutter and Unity 3D.
enum UnityGameEvent {
  sceneLoaded,
  gameStarted,
  turnChanged,
  cardPlayed,
  marbleMoved,
  diceRolled,
  gameOver,
  soundTriggered,
  cameraChanged,
  custom,
}

