import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'unity_message.dart';

/// Runtime statuses of the Unity Player.
enum UnityPlayerStatus {
  uninitialized,
  initializing,
  ready,
  paused,
  error,
  unloaded,
}

/// Controller managing lifecycle, commands, and bidirectional communication
/// between Flutter and the Unity 3D Player.
class UnityPlayerController extends ChangeNotifier {
  static const String _defaultChannelName = 'com.sawhaapp.game/unity_player';

  final MethodChannel _channel;
  UnityPlayerStatus _status = UnityPlayerStatus.uninitialized;
  String? _errorMessage;
  bool _isMock;

  final StreamController<UnityMessage> _messageStreamController = StreamController<UnityMessage>.broadcast();
  final StreamController<UnityPlayerStatus> _statusStreamController = StreamController<UnityPlayerStatus>.broadcast();
  final List<UnityMessage> _messageLog = [];

  UnityPlayerController({
    String channelName = _defaultChannelName,
    bool isMock = false,
  })  : _isMock = isMock,
        _channel = MethodChannel(channelName) {
    if (!_isMock) {
      _channel.setMethodCallHandler(_handleNativeMethodCall);
    }
  }

  /// Current status of the Unity player.
  UnityPlayerStatus get status => _status;

  /// Error message if status is [UnityPlayerStatus.error].
  String? get errorMessage => _errorMessage;

  /// Whether the controller is running in mock/simulation mode.
  bool get isMock => _isMock;

  /// Enables mock simulation mode manually.
  void enableMockMode() {
    _isMock = true;
    notifyListeners();
  }

  /// Whether the Unity player is ready to receive commands and render 3D scenes.
  bool get isReady => _status == UnityPlayerStatus.ready;

  /// Stream of all incoming messages and events from Unity.
  Stream<UnityMessage> get messageStream => _messageStreamController.stream;

  /// Stream of status transitions.
  Stream<UnityPlayerStatus> get statusStream => _statusStreamController.stream;

  /// Read-only history of recent messages exchanged.
  List<UnityMessage> get messageLog => List.unmodifiable(_messageLog);

  /// Initializes the player connection.
  Future<void> initialize() async {
    if (_status == UnityPlayerStatus.ready || _status == UnityPlayerStatus.initializing) {
      return;
    }

    _updateStatus(UnityPlayerStatus.initializing);

    if (_isMock) {
      // Simulate quick initialization in mock/test mode
      await Future<void>.delayed(const Duration(milliseconds: 20));
      _updateStatus(UnityPlayerStatus.ready);
      return;
    }

    try {
      final bool? success = await _channel.invokeMethod<bool>('init');
      if (success == true) {
        _updateStatus(UnityPlayerStatus.ready);
      } else {
        _handleError('Native Unity player failed to initialize.');
      }
    } on MissingPluginException {
      // In tests or environments without native unity binaries, gracefully fallback to mock
      _isMock = true;
      _updateStatus(UnityPlayerStatus.ready);
    } on PlatformException catch (e) {
      _handleError('Platform error initializing Unity: ${e.message}');
    } catch (e) {
      _handleError('Unexpected error initializing Unity: $e');
    }
  }

  /// Sends a message to a Unity GameObject's C# script method.
  Future<bool> postMessage(String gameObject, String methodName, String message) async {
    final msg = UnityMessage(
      gameObject: gameObject,
      methodName: methodName,
      payload: message,
    );
    _logMessage(msg);

    if (_isMock) {
      // In mock mode, acknowledge immediately
      return true;
    }

    try {
      final bool? result = await _channel.invokeMethod<bool>('postMessage', {
        'gameObject': gameObject,
        'methodName': methodName,
        'message': message,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('[UnityPlayerController] Error posting message: $e');
      return false;
    }
  }

  /// Convenience method to post a JSON map message to Unity.
  Future<bool> postJson(String gameObject, String methodName, Map<String, dynamic> data) {
    final msg = UnityMessage.json(
      gameObject: gameObject,
      methodName: methodName,
      data: data,
    );
    return postMessage(msg.gameObject, msg.methodName, msg.payload);
  }

  /// Request Unity to load a specific 3D scene by name.
  Future<bool> loadScene(String sceneName) {
    return postJson('SceneLoader', 'LoadScene', {'sceneName': sceneName});
  }

  /// Pauses the Unity 3D engine loop (stops rendering and physics).
  Future<void> pause() async {
    if (_status != UnityPlayerStatus.ready) return;

    if (!_isMock) {
      try {
        await _channel.invokeMethod('pause');
      } catch (e) {
        debugPrint('[UnityPlayerController] Error pausing Unity: $e');
      }
    }
    _updateStatus(UnityPlayerStatus.paused);
  }

  /// Resumes the Unity 3D engine loop.
  Future<void> resume() async {
    if (_status != UnityPlayerStatus.paused) return;

    if (!_isMock) {
      try {
        await _channel.invokeMethod('resume');
      } catch (e) {
        debugPrint('[UnityPlayerController] Error resuming Unity: $e');
      }
    }
    _updateStatus(UnityPlayerStatus.ready);
  }

  /// Unloads the Unity player from memory.
  Future<void> unload() async {
    if (_status == UnityPlayerStatus.unloaded) return;

    if (!_isMock) {
      try {
        await _channel.invokeMethod('unload');
      } catch (e) {
        debugPrint('[UnityPlayerController] Error unloading Unity: $e');
      }
    }
    _updateStatus(UnityPlayerStatus.unloaded);
  }

  /// Handles method calls originating from the native Android/iOS Unity player.
  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onUnityMessage':
        final raw = call.arguments?.toString() ?? '';
        final message = UnityMessage.fromRaw(raw);
        _logMessage(message);
        _messageStreamController.add(message);
        notifyListeners();
        return true;

      case 'onUnityReady':
        _updateStatus(UnityPlayerStatus.ready);
        return true;

      case 'onUnityUnloaded':
        _updateStatus(UnityPlayerStatus.unloaded);
        return true;

      default:
        debugPrint('[UnityPlayerController] Unhandled native call: ${call.method}');
        return null;
    }
  }

  /// Simulates an incoming message from Unity (for tests and mock views).
  void simulateIncomingMessage(UnityMessage message) {
    _logMessage(message);
    _messageStreamController.add(message);
    notifyListeners();
  }

  /// Simulates a status change (for tests).
  void simulateStatusChange(UnityPlayerStatus newStatus) {
    _updateStatus(newStatus);
  }

  void _updateStatus(UnityPlayerStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    _statusStreamController.add(newStatus);
    notifyListeners();
  }

  void _handleError(String message) {
    _errorMessage = message;
    _updateStatus(UnityPlayerStatus.error);
    debugPrint('[UnityPlayerController] $message');
  }

  void _logMessage(UnityMessage msg) {
    _messageLog.add(msg);
    if (_messageLog.length > 50) {
      _messageLog.removeAt(0);
    }
  }

  @override
  void dispose() {
    _messageStreamController.close();
    _statusStreamController.close();
    super.dispose();
  }
}
