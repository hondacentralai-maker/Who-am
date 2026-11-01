import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/game_audio_service.dart';
import '../services/preferences_service.dart';

/// Representation of a marble on the Jackaroo board.
enum MarbleLocationType { base, track, safety, finished }

class JackarooMarble {
  final int id;
  final int playerIndex; // 0: Blue (Player), 1: Yellow (Left), 2: Green (Teammate), 3: Red (Right)
  final Color color;
  MarbleLocationType locationType;
  int position; // slot index in base, track (0-63), or safety (0-3)

  JackarooMarble({
    required this.id,
    required this.playerIndex,
    required this.color,
    this.locationType = MarbleLocationType.base,
    required this.position,
  });

  bool get isInBase => locationType == MarbleLocationType.base;
  bool get isOnTrack => locationType == MarbleLocationType.track;
  bool get isInSafety => locationType == MarbleLocationType.safety;
  bool get isFinished => locationType == MarbleLocationType.finished;
}

/// A hyper-realistic, interactive 3D Jackaroo tabletop game board.
/// Features luxury mahogany wood finish, carved slots with inner depth,
/// glass spherical marbles with specular highlights, camera orbit tilt,
/// and complete playable turns against AI with authentic sounds and haptics.
class Jackaroo3DBoardView extends StatefulWidget {
  final String? activeCard;
  final ValueChanged<String>? onStatusMessage;
  final VoidCallback? onTurnFinished;
  final VoidCallback? onResetCameraTriggered;

  const Jackaroo3DBoardView({
    super.key,
    this.activeCard,
    this.onStatusMessage,
    this.onTurnFinished,
    this.onResetCameraTriggered,
  });

  @override
  State<Jackaroo3DBoardView> createState() => Jackaroo3DBoardViewState();
}

class Jackaroo3DBoardViewState extends State<Jackaroo3DBoardView>
    with SingleTickerProviderStateMixin {
  final GameAudioService _audio = GameAudioService();

  // 3D Perspective Angles
  double _pitch = 0.42; // Tilt down
  double _yaw = 0.0;    // Rotation

  // Camera Animation
  late AnimationController _cameraAnimController;
  late Animation<double> _pitchAnim;
  late Animation<double> _yawAnim;

  // Selected marble
  int? _selectedMarbleId;

  // Game Marbles (4 players × 4 marbles = 16 marbles)
  late List<JackarooMarble> _marbles;

  // Turn status
  int _currentTurn = 0; // 0: Blue (Player), 1: Yellow, 2: Green, 3: Red
  bool _isAnimatingMove = false;

  // Constants for board layout
  static const int _trackSlotsCount = 64;
  static const Color _goldBezel = Color(0xFFD4AF37);

  // Player Start Slots on the 64-slot track
  // Blue: 0 (Bottom), Yellow: 16 (Left), Green: 32 (Top), Red: 48 (Right)
  static const List<int> _playerStartSlots = [0, 16, 32, 48];

  @override
  void initState() {
    super.initState();
    _initMarbles();

    _cameraAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        setState(() {
          _pitch = _pitchAnim.value;
          _yaw = _yawAnim.value;
        });
      });
  }

  @override
  void dispose() {
    _cameraAnimController.dispose();
    super.dispose();
  }

  void _initMarbles() {
    _marbles = [];
    final colors = [
      const Color(0xFF2563EB), // Blue
      const Color(0xFFEAB308), // Yellow
      const Color(0xFF10B981), // Green
      const Color(0xFFEF4444), // Red
    ];

    for (int p = 0; p < 4; p++) {
      for (int m = 0; m < 4; m++) {
        _marbles.add(
          JackarooMarble(
            id: p * 4 + m,
            playerIndex: p,
            color: colors[p],
            locationType: MarbleLocationType.base,
            position: m,
          ),
        );
      }
    }
  }

  /// Resets the 3D camera smoothly to the default isometric view.
  void resetCamera() {
    _pitchAnim = Tween<double>(begin: _pitch, end: 0.42).animate(
      CurvedAnimation(parent: _cameraAnimController, curve: Curves.easeOutCubic),
    );
    _yawAnim = Tween<double>(begin: _yaw, end: 0.0).animate(
      CurvedAnimation(parent: _cameraAnimController, curve: Curves.easeOutCubic),
    );
    _cameraAnimController.forward(from: 0.0);
    PreferencesService.triggerHaptic(AppHapticType.light);
  }

  int _getCardStepValue(String card) {
    if (card.startsWith('A')) return 1;
    if (card.startsWith('K')) return 13;
    if (card.startsWith('Q')) return 12;
    if (card.startsWith('J')) return 11;
    if (card.startsWith('10')) return 10;
    if (card.startsWith('9')) return 9;
    if (card.startsWith('8')) return 8;
    if (card.startsWith('7')) return 7;
    if (card.startsWith('6')) return 6;
    if (card.startsWith('5')) return 5;
    if (card.startsWith('4')) return -4;
    if (card.startsWith('3')) return 3;
    if (card.startsWith('2')) return 2;
    return 1;
  }

  /// Checks if a blue marble can be played with current active card.
  bool _canPlayMarble(JackarooMarble marble) {
    if (_isAnimatingMove || _currentTurn != 0) return false;
    final card = widget.activeCard ?? 'A♠';
    final isKingOrAce = card.startsWith('K') || card.startsWith('A');

    if (marble.isInBase) {
      return isKingOrAce;
    }

    if (marble.isOnTrack || marble.isInSafety) {
      return true;
    }

    return false;
  }

  /// Handles user tapping on a marble.
  Future<void> _handleMarbleTap(JackarooMarble marble) async {
    if (!_canPlayMarble(marble)) {
      PreferencesService.triggerHaptic(AppHapticType.light);
      return;
    }

    setState(() {
      _selectedMarbleId = marble.id;
      _isAnimatingMove = true;
    });

    final card = widget.activeCard ?? 'A♠';
    final isKingOrAce = card.startsWith('K') || card.startsWith('A');

    if (marble.isInBase && isKingOrAce) {
      // Move from Base to Start slot
      _audio.playCardPlace();
      PreferencesService.triggerHaptic(AppHapticType.selection);
      await Future<void>.delayed(const Duration(milliseconds: 250));

      final startSlot = _playerStartSlots[marble.playerIndex];

      // Check if another marble is at start slot
      _checkAndCaptureAtSlot(startSlot, marble.playerIndex);

      setState(() {
        marble.locationType = MarbleLocationType.track;
        marble.position = startSlot;
      });

      _audio.playStep();
      widget.onStatusMessage?.call('أخرجت حجراً من القاعدة إلى خط البداية! 🚀');
    } else if (marble.isOnTrack) {
      // Advance on track
      final steps = _getCardStepValue(card);
      int targetPos = (marble.position + steps) % _trackSlotsCount;
      if (targetPos < 0) targetPos += _trackSlotsCount;

      // Animate steps sound
      _audio.playStep();
      PreferencesService.triggerHaptic(AppHapticType.selection);

      await Future<void>.delayed(const Duration(milliseconds: 300));
      _checkAndCaptureAtSlot(targetPos, marble.playerIndex);

      setState(() {
        marble.position = targetPos;
      });

      _audio.playStep();
      widget.onStatusMessage?.call('تقدم حجر الأزرق $steps خطوات على المسار! 🎯');
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));

    setState(() {
      _selectedMarbleId = null;
      _isAnimatingMove = false;
    });

    widget.onTurnFinished?.call();

    // Trigger AI turns for Yellow, Green, Red
    _playAiTurns();
  }

  /// Checks if any opponent marble is at target slot and sends it to base.
  void _checkAndCaptureAtSlot(int slot, int capturingPlayer) {
    for (final other in _marbles) {
      if (other.playerIndex != capturingPlayer &&
          other.isOnTrack &&
          other.position == slot) {
        // Capture!
        setState(() {
          other.locationType = MarbleLocationType.base;
        });
        _audio.playEat();
        PreferencesService.triggerHaptic(AppHapticType.heavy);
        widget.onStatusMessage?.call('أكلت حجر المنافس وأرجعته للقاعدة! 💥');
        break;
      }
    }
  }

  /// Simulates turns for bots with authentic delays.
  Future<void> _playAiTurns() async {
    final botNames = ['خالد (أصفر)', 'سارة (أخضر • شريكتك)', 'فهد (أحمر)'];

    for (int b = 1; b <= 3; b++) {
      if (!mounted) return;
      setState(() => _currentTurn = b);
      widget.onStatusMessage?.call('دور ${botNames[b - 1]} يفكّر...');

      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      // Find a marble to move for bot
      final botMarbles = _marbles.where((m) => m.playerIndex == b).toList();
      final baseMarble = botMarbles.where((m) => m.isInBase).firstOrNull;
      final trackMarble = botMarbles.where((m) => m.isOnTrack).firstOrNull;

      if (baseMarble != null && math.Random().nextBool()) {
        final start = _playerStartSlots[b];
        _checkAndCaptureAtSlot(start, b);
        setState(() {
          baseMarble.locationType = MarbleLocationType.track;
          baseMarble.position = start;
        });
        _audio.playCardPlace();
        widget.onStatusMessage?.call('${botNames[b - 1]} أخرج حجراً جديداً إلى البداية');
      } else if (trackMarble != null) {
        final moveSteps = (math.Random().nextInt(6) + 1);
        final target = (trackMarble.position + moveSteps) % _trackSlotsCount;
        _checkAndCaptureAtSlot(target, b);
        setState(() {
          trackMarble.position = target;
        });
        _audio.playStep();
        widget.onStatusMessage?.call('${botNames[b - 1]} تحرك $moveSteps خطوات');
      } else if (baseMarble != null) {
        final start = _playerStartSlots[b];
        setState(() {
          baseMarble.locationType = MarbleLocationType.track;
          baseMarble.position = start;
        });
        _audio.playCardPlace();
      }

      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    if (!mounted) return;
    setState(() => _currentTurn = 0);
    widget.onStatusMessage?.call('دورك الآن! اختر ورقة ثم المس حجراً للتحريك 🌟');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight) * 0.92;

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _yaw += details.delta.dx * 0.006;
              _pitch = (_pitch - details.delta.dy * 0.005).clamp(0.15, 0.75);
            });
          },
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0016) // 3D Perspective depth
                  ..rotateX(_pitch)
                  ..rotateZ(_yaw),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: _JackarooBoardPainter(
                      marbles: _marbles,
                      selectedMarbleId: _selectedMarbleId,
                      activeCard: widget.activeCard,
                      isPlayerTurn: _currentTurn == 0,
                    ),
                    child: _buildMarbleHitAreas(size),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Hit test areas layered over marble positions so player can tap them directly.
  Widget _buildMarbleHitAreas(double boardSize) {
    final center = Offset(boardSize / 2, boardSize / 2);
    final radius = boardSize * 0.40;

    return Stack(
      children: _marbles.where((m) => m.playerIndex == 0).map((m) {
        final pos = _getMarbleCenter(m, center, radius);
        final isPlayable = _canPlayMarble(m);

        return Positioned(
          left: pos.dx - 18,
          top: pos.dy - 18,
          width: 36,
          height: 36,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _handleMarbleTap(m),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isPlayable
                    ? Border.all(color: _goldBezel.withValues(alpha: 0.8), width: 2)
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static Offset _getMarbleCenter(JackarooMarble marble, Offset center, double trackRadius) {
    if (marble.isOnTrack) {
      final angle = (marble.position * 2 * math.pi / _trackSlotsCount) - (math.pi / 2);
      return Offset(
        center.dx + trackRadius * math.cos(angle),
        center.dy + trackRadius * math.sin(angle),
      );
    } else if (marble.isInBase) {
      // 4 Base positions around each quadrant
      final baseAngles = [math.pi / 2, math.pi, 3 * math.pi / 2, 0.0];
      final baseAngle = baseAngles[marble.playerIndex] - 0.28;
      final baseDist = trackRadius * 0.68;

      // 2x2 offset for each marble inside base
      final ox = ((marble.position % 2) - 0.5) * 22;
      final oy = ((marble.position ~/ 2) - 0.5) * 22;

      return Offset(
        center.dx + baseDist * math.cos(baseAngle) + ox,
        center.dy + baseDist * math.sin(baseAngle) + oy,
      );
    } else {
      // Safety track leading to center
      final safetyAngles = [math.pi / 2, math.pi, 3 * math.pi / 2, 0.0];
      final safetyAngle = safetyAngles[marble.playerIndex];
      final dist = trackRadius * (0.82 - (marble.position * 0.16));

      return Offset(
        center.dx + dist * math.cos(safetyAngle),
        center.dy + dist * math.sin(safetyAngle),
      );
    }
  }
}

/// Custom painter for the luxury wooden board, carved slots, and shiny 3D glass marbles.
class _JackarooBoardPainter extends CustomPainter {
  final List<JackarooMarble> marbles;
  final int? selectedMarbleId;
  final String? activeCard;
  final bool isPlayerTurn;

  _JackarooBoardPainter({
    required this.marbles,
    required this.selectedMarbleId,
    required this.activeCard,
    required this.isPlayerTurn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final boardRadius = size.width * 0.49;
    final trackRadius = size.width * 0.40;

    _drawWoodenBoard(canvas, center, boardRadius);
    _drawTrackSlots(canvas, center, trackRadius);
    _drawBasesAndSafety(canvas, center, trackRadius);
    _drawCenterCompass(canvas, center, trackRadius * 0.28);
    _drawMarbles(canvas, center, trackRadius);
  }

  void _drawWoodenBoard(Canvas canvas, Offset center, double radius) {
    // 1. Cast shadow of the table surface
    canvas.drawCircle(
      center + const Offset(0, 14),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // 2. Outer Beveled Mahogany Rim
    final rimPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF3E1E11),
          Color(0xFF24140D),
          Color(0xFF140A06),
        ],
        stops: [0.75, 0.94, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, rimPaint);

    // 3. Gold Inlaid Outer Border
    final goldBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFD4AF37),
          Color(0xFFFFF2B2),
          Color(0xFFAA8012),
          Color(0xFFFFF2B2),
          Color(0xFFD4AF37),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 2, goldBorderPaint);

    // 4. Main Walnut Playing Surface
    final surfaceRadius = radius - 8;
    final surfacePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        colors: [
          Color(0xFF5D331D),
          Color(0xFF452211),
          Color(0xFF2B1309),
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: surfaceRadius));
    canvas.drawCircle(center, surfaceRadius, surfacePaint);

    // 5. Concentric subtle wood rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.black.withValues(alpha: 0.18);
    canvas.drawCircle(center, surfaceRadius * 0.85, ringPaint);
    canvas.drawCircle(center, surfaceRadius * 0.55, ringPaint);
    canvas.drawCircle(center, surfaceRadius * 0.32, ringPaint);
  }

  void _drawTrackSlots(Canvas canvas, Offset center, double trackRadius) {
    const slotCount = 64;
    const slotRadius = 6.8;

    for (int i = 0; i < slotCount; i++) {
      final angle = (i * 2 * math.pi / slotCount) - (math.pi / 2);
      final slotCenter = Offset(
        center.dx + trackRadius * math.cos(angle),
        center.dy + trackRadius * math.sin(angle),
      );

      final isStartSlot = i % 16 == 0;
      _drawCarvedHole(canvas, slotCenter, slotRadius, isSpecial: isStartSlot);
    }
  }

  void _drawBasesAndSafety(Canvas canvas, Offset center, double trackRadius) {
    const slotRadius = 6.5;
    final quadrantColors = [
      const Color(0xFF2563EB), // Blue
      const Color(0xFFEAB308), // Yellow
      const Color(0xFF10B981), // Green
      const Color(0xFFEF4444), // Red
    ];

    for (int p = 0; p < 4; p++) {
      final baseAngles = [math.pi / 2, math.pi, 3 * math.pi / 2, 0.0];
      final baseAngle = baseAngles[p] - 0.28;
      final baseDist = trackRadius * 0.68;
      final qColor = quadrantColors[p];

      // Draw Base Ring
      final baseCenter = Offset(
        center.dx + baseDist * math.cos(baseAngle),
        center.dy + baseDist * math.sin(baseAngle),
      );

      final basePlaquePaint = Paint()
        ..color = qColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(baseCenter, 24, basePlaquePaint);

      final baseBorderPaint = Paint()
        ..color = qColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(baseCenter, 24, baseBorderPaint);

      // 4 Base Slots
      for (int m = 0; m < 4; m++) {
        final ox = ((m % 2) - 0.5) * 22;
        final oy = ((m ~/ 2) - 0.5) * 22;
        _drawCarvedHole(canvas, baseCenter + Offset(ox, oy), slotRadius, accentColor: qColor);
      }

      // Safety Track (4 slots leading to center)
      final safetyAngle = baseAngles[p];
      for (int s = 0; s < 4; s++) {
        final dist = trackRadius * (0.82 - (s * 0.16));
        final sPos = Offset(
          center.dx + dist * math.cos(safetyAngle),
          center.dy + dist * math.sin(safetyAngle),
        );
        _drawCarvedHole(canvas, sPos, slotRadius, accentColor: qColor);
      }
    }
  }

  void _drawCarvedHole(Canvas canvas, Offset holeCenter, double radius,
      {bool isSpecial = false, Color? accentColor}) {
    // Inner shadow (concave hole depth)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.85);
    canvas.drawCircle(holeCenter, radius, shadowPaint);

    // Bottom-right inner highlight (beveled carved wood rim)
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = (accentColor ?? const Color(0xFFD4AF37)).withValues(alpha: isSpecial ? 0.9 : 0.35);
    canvas.drawCircle(holeCenter, radius, highlightPaint);
  }

  void _drawCenterCompass(Canvas canvas, Offset center, double radius) {
    // Golden central medallion
    final medallionPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFD4AF37).withValues(alpha: 0.4),
          const Color(0xFF8C6D1F).withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, medallionPaint);

    final goldLinePaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius, goldLinePaint);

    // 8-pointed star in the center
    final path = Path();
    const points = 8;
    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? radius * 0.82 : radius * 0.35;
      final angle = (i * math.pi / points) - (math.pi / 2);
      final pt = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();

    final starFill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE8C86A), Color(0xFFA57D18)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.82));
    canvas.drawPath(path, starFill);
  }

  void _drawMarbles(Canvas canvas, Offset center, double trackRadius) {
    const marbleRadius = 8.5;

    for (final marble in marbles) {
      final mCenter = Jackaroo3DBoardViewState._getMarbleCenter(marble, center, trackRadius);
      final isSelected = marble.id == selectedMarbleId;

      _drawRealisticGlassMarble(canvas, mCenter, marbleRadius, marble.color, isSelected: isSelected);
    }
  }

  void _drawRealisticGlassMarble(
    Canvas canvas,
    Offset center,
    double radius,
    Color baseColor, {
    bool isSelected = false,
  }) {
    // 1. Contact ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: center + const Offset(1.5, 4.0),
        width: radius * 2.1,
        height: radius * 1.3,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );

    // 2. Selection aura glow (pulsing)
    if (isSelected) {
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // 3. Spherical 3D Glass Body (Deep gradient)
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 0.85,
        colors: [
          Color.lerp(baseColor, Colors.white, 0.45)!,
          baseColor,
          Color.lerp(baseColor, Colors.black, 0.65)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bodyPaint);

    // 4. Secondary bounce reflection at bottom-right
    final bouncePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.45, 0.55),
        radius: 0.5,
        colors: [
          Color.lerp(baseColor, Colors.white, 0.5)!.withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bouncePaint);

    // 5. Specular highlight (bright glassy pin glint at 10 o'clock)
    final glintCenter = center + Offset(-radius * 0.32, -radius * 0.35);
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawOval(
      Rect.fromCenter(
        center: glintCenter,
        width: radius * 0.65,
        height: radius * 0.42,
      ),
      glintPaint,
    );

    // Secondary tiny pin dot
    canvas.drawCircle(
      center + Offset(radius * 0.35, radius * 0.35),
      radius * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _JackarooBoardPainter oldDelegate) {
    return true;
  }
}
