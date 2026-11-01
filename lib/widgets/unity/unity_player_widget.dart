import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'unity_message.dart';
import 'unity_player_controller.dart';

/// The core Flutter widget that hosts the Unity 3D view.
///
/// On supported mobile platforms (Android/iOS) with the native Unity build linked,
/// it renders the native UnityPlayer via PlatformView.
/// On other platforms or in test environments, it provides an interactive
/// high-fidelity simulation placeholder with bidirectional debugging support.
class UnityPlayerWidget extends StatefulWidget {
  /// The controller managing communication with the Unity player.
  final UnityPlayerController? controller;

  /// Invoked when the Unity player is created and attached to Flutter.
  final void Function(UnityPlayerController controller)? onUnityCreated;

  /// Invoked whenever Unity sends a message to Flutter.
  final void Function(UnityMessage message)? onUnityMessage;

  /// Optional widget displayed while Unity is loading or initializing.
  final Widget? placeholder;

  /// Optional overlay placed on top of the Unity view (e.g. HUD, buttons).
  final Widget? overlay;

  /// Explicitly force mock simulation mode (useful for testing and previews).
  final bool? isMock;

  /// Whether to automatically use the mock simulation player when
  /// running on platforms or environments without native Unity binaries.
  final bool enableMockInUnsupported;

  /// When true, renders an in-app debug panel to test messages and game states.
  final bool debugMode;

  /// Scene name to request upon initialization.
  final String? initialScene;

  const UnityPlayerWidget({
    super.key,
    this.controller,
    this.onUnityCreated,
    this.onUnityMessage,
    this.placeholder,
    this.overlay,
    this.isMock,
    this.enableMockInUnsupported = true,
    this.debugMode = false,
    this.initialScene,
  });

  @override
  State<UnityPlayerWidget> createState() => _UnityPlayerWidgetState();
}

class _UnityPlayerWidgetState extends State<UnityPlayerWidget> {
  late UnityPlayerController _controller;
  bool _internalController = false;
  bool _hasCalledOnCreated = false;

  @override
  void initState() {
    super.initState();
    final bool useMock = widget.isMock ?? (widget.enableMockInUnsupported && !_isNativeSupported);

    if (widget.controller != null) {
      _controller = widget.controller!;
      if (widget.isMock == true) {
        _controller.enableMockMode();
      }
    } else {
      _internalController = true;
      _controller = UnityPlayerController(isMock: useMock);
    }

    _controller.messageStream.listen((msg) {
      widget.onUnityMessage?.call(msg);
    });

    _initPlayer();
  }

  bool get _isNativeSupported {
    return !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  }

  Future<void> _initPlayer() async {
    await _controller.initialize();
    if (widget.initialScene != null && _controller.isReady) {
      await _controller.loadScene(widget.initialScene!);
    }
    if (mounted && !_hasCalledOnCreated) {
      _hasCalledOnCreated = true;
      widget.onUnityCreated?.call(_controller);
    }
  }

  @override
  void dispose() {
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final status = _controller.status;

        Widget unityView;

        if (status == UnityPlayerStatus.error) {
          unityView = _buildErrorView();
        } else if (status == UnityPlayerStatus.uninitialized || status == UnityPlayerStatus.initializing) {
          unityView = widget.placeholder ?? _buildDefaultLoadingView();
        } else if (_isNativeSupported && !_controller.isMock) {
          unityView = _buildNativePlatformView();
        } else {
          unityView = _buildSimulationView();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // The Unity Viewport
            unityView,

            // Developer Debug Overlay (if enabled)
            if (widget.debugMode) _buildDebugInspector(),

            // Top-level Flutter HUD Overlay
            if (widget.overlay != null) widget.overlay!,
          ],
        );
      },
    );
  }

  Widget _buildNativePlatformView() {
    const String viewType = 'com.sawhaapp.game/unity_view';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const AndroidView(
        viewType: viewType,
        creationParams: <String, dynamic>{},
        creationParamsCodec: StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const UiKitView(
        viewType: viewType,
        creationParams: <String, dynamic>{},
        creationParamsCodec: StandardMessageCodec(),
      );
    }
    return _buildSimulationView();
  }

  Widget _buildDefaultLoadingView() {
    return Container(
      color: const Color(0xFF0D1117),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'جاري تحميل محرك Unity 3D...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'تهيئة البيئة ثلاثية الأبعاد والأصول...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: const Color(0xFF111827),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            const Text(
              'تعذر تشغيل محرك Unity',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage ?? 'حدث خطأ غير متوقع أثناء تهيئة UnityPlayer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _controller.initialize(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E1B4B),
            Color(0xFF030712),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Unity 3D Cube / Engine Badge
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.view_in_ar_rounded,
                color: Color(0xFF818CF8),
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unity 3D Engine Viewport',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Unity Player Active & Ready',
                    style: TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (widget.initialScene != null) ...[
              const SizedBox(height: 8),
              Text(
                'Active Scene: ${widget.initialScene}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInspector() {
    return Positioned(
      bottom: 80,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(10),
          width: 200,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Unity DevTools',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Status: ${_controller.status.name}',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              Text(
                'Msgs: ${_controller.messageLog.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  _controller.simulateIncomingMessage(
                    UnityMessage.json(
                      gameObject: 'JackarooBoard',
                      methodName: 'OnTurnEnded',
                      data: {'player': 1, 'card': 'King', 'marbleMoved': 10},
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text('Simulate Unity Event', style: TextStyle(color: Colors.white, fontSize: 9)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
