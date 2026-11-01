import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/game_audio_service.dart';
import '../services/preferences_service.dart';

/// Representation of a marble on the authentic 76-hole Jackaroo board.
enum JackarooMarbleLocation { home, track, safeZone, finished }

class JackarooBoardMarble {
  final int id;
  final int ownerId; // 0: Blue (Player), 1: Yellow (Left), 2: Green (Teammate), 3: Red (Right)
  final int indexInOwner; // 0..3
  final Color primaryColor;
  final Color secondaryColor;
  JackarooMarbleLocation location;
  int positionIndex; // 0..3 in home, 0..75 on track, 0..3 in safeZone

  JackarooBoardMarble({
    required this.id,
    required this.ownerId,
    required this.indexInOwner,
    required this.primaryColor,
    required this.secondaryColor,
    this.location = JackarooMarbleLocation.home,
    required this.positionIndex,
  });

  bool get isHome => location == JackarooMarbleLocation.home;
  bool get isOnTrack => location == JackarooMarbleLocation.track;
  bool get isInSafeZone => location == JackarooMarbleLocation.safeZone;
  bool get isFinished => location == JackarooMarbleLocation.finished;
}

/// A hyper-realistic, 100% authentic 76-hole Jackaroo tabletop board.
/// Features slate-grey marble wood finish, birch wood center well,
/// 76 laser-engraved track holes, 4 corner home dishes ("البيت"),
/// safe zone runways, diagonal folding seam with chrome hinges,
/// realistic glass marbles with specular reflections, and interactive play.
class Jackaroo3DBoardView extends StatefulWidget {
  final String? activeCard;
  final ValueChanged<String>? onStatusMessage;
  final VoidCallback? onTurnFinished;

  const Jackaroo3DBoardView({
    super.key,
    this.activeCard,
    this.onStatusMessage,
    this.onTurnFinished,
  });

  @override
  State<Jackaroo3DBoardView> createState() => Jackaroo3DBoardViewState();
}

class Jackaroo3DBoardViewState extends State<Jackaroo3DBoardView>
    with SingleTickerProviderStateMixin {
  final GameAudioService _audio = GameAudioService();

  // 3D Perspective Angles
  double _pitch = 0.38; // Initial gentle perspective tilt
  double _yaw = 0.0;    // Horizontal rotation

  // Camera Animation Controller
  late AnimationController _cameraAnimController;
  late Animation<double> _pitchAnim;
  late Animation<double> _yawAnim;

  // Game Marbles (4 players × 4 marbles = 16 marbles)
  late List<JackarooBoardMarble> _marbles;

  // Selected Marble & Move Target Preview
  JackarooBoardMarble? _selectedMarble;
  int? _previewTargetTrack;
  int? _previewTargetSafe;

  // Turn status: 0: Player (Blue), 1: Yellow, 2: Green, 3: Red
  int _currentTurn = 0;
  bool _isMoving = false;

  // Base spawn track slots for the 4 players (19 holes per quadrant)
  static const List<int> _playerSpawnSlots = [0, 19, 38, 57];

  // Coordinates calculated by the painter in 1000x1000 virtual space
  final Map<int, Offset> _trackCoordinates = {};
  final Map<String, Offset> _homeCoordinates = {};
  final Map<String, Offset> _safeZoneCoordinates = {};

  @override
  void initState() {
    super.initState();
    _initMarbles();

    _cameraAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
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
    final playerColors = [
      const Color(0xFF2979FF), // Blue (Player)
      const Color(0xFFFBC02D), // Yellow (Opponent 1)
      const Color(0xFF2E7D32), // Green (Teammate)
      const Color(0xFFD32F2F), // Red (Opponent 2)
    ];
    final secondaryColors = [
      const Color(0xFF0D47A1),
      const Color(0xFFE65100),
      const Color(0xFF1B5E20),
      const Color(0xFFB71C1C),
    ];

    for (int p = 0; p < 4; p++) {
      for (int m = 0; m < 4; m++) {
        _marbles.add(
          JackarooBoardMarble(
            id: p * 4 + m,
            ownerId: p,
            indexInOwner: m,
            primaryColor: playerColors[p],
            secondaryColor: secondaryColors[p],
            location: JackarooMarbleLocation.home,
            positionIndex: m,
          ),
        );
      }
    }
  }

  /// Resets 3D perspective camera smoothly back to default tabletop angle.
  void resetCamera() {
    _pitchAnim = Tween<double>(begin: _pitch, end: 0.38).animate(
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

  bool _canSelectMarble(JackarooBoardMarble marble) {
    if (_isMoving || _currentTurn != 0) return false;
    if (marble.ownerId != 0) return false;

    final card = widget.activeCard ?? 'A♠';
    final isKingOrAce = card.startsWith('K') || card.startsWith('A');

    if (marble.isHome) {
      return isKingOrAce;
    }

    if (marble.isOnTrack || marble.isInSafeZone) {
      return true;
    }

    return false;
  }

  void _onMarbleClicked(JackarooBoardMarble marble) {
    if (!_canSelectMarble(marble)) {
      PreferencesService.triggerHaptic(AppHapticType.light);
      return;
    }

    final card = widget.activeCard ?? 'A♠';
    final isKingOrAce = card.startsWith('K') || card.startsWith('A');

    setState(() {
      _selectedMarble = marble;

      if (marble.isHome && isKingOrAce) {
        _previewTargetTrack = _playerSpawnSlots[marble.ownerId];
        _previewTargetSafe = null;
      } else if (marble.isOnTrack) {
        final step = _getCardStepValue(card);
        final nextPos = (marble.positionIndex + step + 76) % 76;
        _previewTargetTrack = nextPos;
        _previewTargetSafe = null;
      }
    });

    PreferencesService.triggerHaptic(AppHapticType.selection);
    _executeMove(marble);
  }

  Future<void> _executeMove(JackarooBoardMarble marble) async {
    setState(() => _isMoving = true);
    final card = widget.activeCard ?? 'A♠';
    final isKingOrAce = card.startsWith('K') || card.startsWith('A');

    if (marble.isHome && isKingOrAce) {
      // Exit from home to spawn point
      _audio.playCardPlace();
      await Future<void>.delayed(const Duration(milliseconds: 250));

      final spawn = _playerSpawnSlots[marble.ownerId];
      _checkAndCapture(spawn, marble.ownerId);

      setState(() {
        marble.location = JackarooMarbleLocation.track;
        marble.positionIndex = spawn;
      });

      _audio.playMarbleStep();
      widget.onStatusMessage?.call('أخرجت حجراً من البيت إلى خط البداية! 🚀');
    } else if (marble.isOnTrack) {
      final step = _getCardStepValue(card);
      final nextPos = (marble.positionIndex + step + 76) % 76;

      _audio.playMarbleStep();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _checkAndCapture(nextPos, marble.ownerId);

      setState(() {
        marble.positionIndex = nextPos;
      });

      _audio.playMarbleStep();
      widget.onStatusMessage?.call('تقدم حجر الأزرق $step خطوات على الرقعة! 🎯');
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));

    setState(() {
      _selectedMarble = null;
      _previewTargetTrack = null;
      _previewTargetSafe = null;
      _isMoving = false;
    });

    widget.onTurnFinished?.call();
    _playBotsTurns();
  }

  void _checkAndCapture(int trackIndex, int capturingPlayer) {
    for (final other in _marbles) {
      if (other.ownerId != capturingPlayer &&
          other.isOnTrack &&
          other.positionIndex == trackIndex) {
        setState(() {
          other.location = JackarooMarbleLocation.home;
        });
        _audio.playMarbleEat();
        PreferencesService.triggerHaptic(AppHapticType.heavy);
        widget.onStatusMessage?.call('أكلت حجر المنافس وأرجعته للبيت! 💥');
        break;
      }
    }
  }

  Future<void> _playBotsTurns() async {
    final botNames = ['خالد (أصفر)', 'سارة (أخضر • شريكتك)', 'فهد (أحمر)'];

    for (int b = 1; b <= 3; b++) {
      if (!mounted) return;
      setState(() => _currentTurn = b);
      widget.onStatusMessage?.call('دور ${botNames[b - 1]} يفكّر...');

      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;

      final botMarbles = _marbles.where((m) => m.ownerId == b).toList();
      final homeMarble = botMarbles.where((m) => m.isHome).firstOrNull;
      final trackMarble = botMarbles.where((m) => m.isOnTrack).firstOrNull;

      if (homeMarble != null && math.Random().nextBool()) {
        final spawn = _playerSpawnSlots[b];
        _checkAndCapture(spawn, b);
        setState(() {
          homeMarble.location = JackarooMarbleLocation.track;
          homeMarble.positionIndex = spawn;
        });
        _audio.playCardPlace();
        widget.onStatusMessage?.call('${botNames[b - 1]} أخرج حجراً جديداً');
      } else if (trackMarble != null) {
        final steps = (math.Random().nextInt(7) + 1);
        final target = (trackMarble.positionIndex + steps) % 76;
        _checkAndCapture(target, b);
        setState(() {
          trackMarble.positionIndex = target;
        });
        _audio.playMarbleStep();
        widget.onStatusMessage?.call('${botNames[b - 1]} تحرك $steps خطوات');
      } else if (homeMarble != null) {
        final spawn = _playerSpawnSlots[b];
        setState(() {
          homeMarble.location = JackarooMarbleLocation.track;
          homeMarble.positionIndex = spawn;
        });
        _audio.playCardPlace();
      }

      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;
    setState(() => _currentTurn = 0);
    widget.onStatusMessage?.call('دورك الآن! اختر ورقة ثم المس حجرك للتحريك 🌟');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight) * 0.95;

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _yaw += details.delta.dx * 0.005;
              _pitch = (_pitch - details.delta.dy * 0.004).clamp(0.12, 0.70);
            });
          },
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015) // Authentic 3D perspective depth
                  ..rotateX(_pitch)
                  ..rotateZ(_yaw),
                child: SizedBox(
                  width: side,
                  height: side,
                  child: CustomPaint(
                    painter: _Authentic76JackarooPainter(
                      marbles: _marbles,
                      selectedMarble: _selectedMarble,
                      previewTargetTrack: _previewTargetTrack,
                      previewTargetSafe: _previewTargetSafe,
                      onCoordinatesComputed: (track, home, safe) {
                        _trackCoordinates.addAll(track);
                        _homeCoordinates.addAll(home);
                        _safeZoneCoordinates.addAll(safe);
                      },
                    ),
                    child: _buildTapTargetOverlay(side),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTapTargetOverlay(double side) {
    final scale = side / 1000.0;

    return Stack(
      children: _marbles.where((m) => m.ownerId == 0).map((m) {
        Offset? pos;
        if (m.isHome) {
          pos = _homeCoordinates['p0_h${m.indexInOwner}'];
        } else if (m.isOnTrack) {
          pos = _trackCoordinates[m.positionIndex];
        } else if (m.isInSafeZone) {
          pos = _safeZoneCoordinates['p0_s${m.positionIndex}'];
        }

        if (pos == null) return const SizedBox.shrink();

        final screenPos = pos * scale;
        final isPlayable = _canSelectMarble(m);

        return Positioned(
          left: screenPos.dx - 22,
          top: screenPos.dy - 22,
          width: 44,
          height: 44,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onMarbleClicked(m),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isPlayable
                    ? Border.all(color: const Color(0xFFFFD54F), width: 2.5)
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// The authentic 76-hole Jackaroo board painter mirroring physical real-world boards.
class _Authentic76JackarooPainter extends CustomPainter {
  final List<JackarooBoardMarble> marbles;
  final JackarooBoardMarble? selectedMarble;
  final int? previewTargetTrack;
  final int? previewTargetSafe;
  final void Function(
    Map<int, Offset> track,
    Map<String, Offset> home,
    Map<String, Offset> safe,
  )? onCoordinatesComputed;

  final Map<int, Offset> _trackCoords = {};
  final Map<String, Offset> _homeCoords = {};
  final Map<String, Offset> _safeCoords = {};

  _Authentic76JackarooPainter({
    required this.marbles,
    this.selectedMarble,
    this.previewTargetTrack,
    this.previewTargetSafe,
    this.onCoordinatesComputed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final scale = side / 1000.0;
    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);

    const center = Offset(500, 500);
    const boardRadius = 475.0;
    const cardWellRadius = 135.0;

    _drawWoodenBoard(canvas, center, boardRadius);
    _drawCenterCardWell(canvas, center, cardWellRadius);
    _compute76HolePositions(center);
    _drawDecorativeShellDots(canvas, center);
    _drawBoardWoodNumbers(canvas, center);
    _drawAllHoles(canvas);
    _drawMovePreviews(canvas);
    _drawMarbles(canvas);

    canvas.restore();

    onCoordinatesComputed?.call(_trackCoords, _homeCoords, _safeCoords);
  }

  void _drawWoodenBoard(Canvas canvas, Offset center, double radius) {
    // 1. Ambient drop shadow under the board
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(center + const Offset(0, 14), radius, shadowPaint);

    // 2. Slate-Grey Marble Wood (الرمادي الرخامي المطابق للوحة الحقيقية)
    const boardGradient = RadialGradient(
      colors: [
        Color(0xFF828A94),
        Color(0xFF727A84),
        Color(0xFF626973),
        Color(0xFF4E545D),
      ],
      stops: [0.0, 0.6, 0.85, 1.0],
    );
    final boardPaint = Paint()
      ..shader = boardGradient.createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, boardPaint);

    // 3. Subtle natural marble veins
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center + const Offset(-60, -40), radius * 0.68, veinPaint);
    canvas.drawCircle(center + const Offset(55, 45), radius * 0.75, veinPaint);

    // 4. Diagonal folding seam line (-45 degrees) with chrome hinges
    const foldAngle = -math.pi / 4;
    final p1 = center + Offset(math.cos(foldAngle), math.sin(foldAngle)) * (radius - 4);
    final p2 = center - Offset(math.cos(foldAngle), math.sin(foldAngle)) * (radius - 4);
    final seamPaint = Paint()
      ..color = const Color(0xFF2A2E33)
      ..strokeWidth = 2.2;
    canvas.drawLine(p1, p2, seamPaint);

    // 5. Aluminum metal hinges on the fold line
    final hingeDistance = radius * 0.62;
    for (final sign in [-1, 1]) {
      final hingeCenter =
          center + Offset(math.cos(foldAngle), math.sin(foldAngle)) * (hingeDistance * sign);
      final hingePaint = Paint()..color = const Color(0xFF9E9E9E);
      final hingeBorder = Paint()
        ..color = const Color(0xFF424242)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.save();
      canvas.translate(hingeCenter.dx, hingeCenter.dy);
      canvas.rotate(foldAngle);
      final hRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 30, height: 10),
        const Radius.circular(3),
      );
      canvas.drawRRect(hRect, hingePaint);
      canvas.drawRRect(hRect, hingeBorder);
      // Hinge screws
      final pinPaint = Paint()..color = const Color(0xFFE0E0E0);
      canvas.drawCircle(const Offset(-8, 0), 1.8, pinPaint);
      canvas.drawCircle(const Offset(8, 0), 1.8, pinPaint);
      canvas.restore();
    }

    // 6. Beveled outer wooden rim
    final rimPaint = Paint()
      ..color = const Color(0xFF9FA8B3).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;
    canvas.drawCircle(center, radius - 2, rimPaint);
  }

  void _drawCenterCardWell(Canvas canvas, Offset center, double wellRadius) {
    // Deep carved well shadow
    final wellShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, wellRadius, wellShadow);

    // Natural light Birch Wood (خشب البتولا الطبيعي الفاتح)
    final wellPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFF0E3CA),
          Color(0xFFE2CDA6),
          Color(0xFFC7AF83),
        ],
        stops: [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: wellRadius));
    canvas.drawCircle(center, wellRadius, wellPaint);

    // Carved well border
    final wellBorder = Paint()
      ..color = const Color(0xFF4A341E).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(center, wellRadius, wellBorder);

    // Fold line across well
    const foldAngle = -math.pi / 4;
    final p1 = center + Offset(math.cos(foldAngle), math.sin(foldAngle)) * wellRadius;
    final p2 = center - Offset(math.cos(foldAngle), math.sin(foldAngle)) * wellRadius;
    final seamPaint = Paint()
      ..color = const Color(0xFF6B4E2E).withValues(alpha: 0.8)
      ..strokeWidth = 2.0;
    canvas.drawLine(p1, p2, seamPaint);
  }

  void _compute76HolePositions(Offset center) {
    _trackCoords.clear();
    _homeCoords.clear();
    _safeCoords.clear();

    const double w = 68.0;
    const double tipY = 412.0;
    const double colStep = 64.0;

    // 19-hole quarter template
    final quarterTemplate = <Offset>[
      const Offset(-w, tipY),                     // 0: Spawn point
      const Offset(-w, tipY - colStep * 1),        // 1..4: Inward column
      const Offset(-w, tipY - colStep * 2),
      const Offset(-w, tipY - colStep * 3),
      const Offset(-w, tipY - colStep * 4),
      const Offset(-86.8, 146.2),                 // 5..10: Inner arc around card well
      const Offset(-100.9, 136.8),
      const Offset(-114.1, 126.1),
      const Offset(-126.1, 114.1),
      const Offset(-136.8, 100.9),
      const Offset(-146.2, 86.8),
      const Offset(-(tipY - colStep * 3), w),     // 11..14: Outward column
      const Offset(-(tipY - colStep * 2), w),
      const Offset(-(tipY - colStep * 1), w),
      const Offset(-(tipY - colStep * 0.5), w),
      const Offset(-tipY, w),                     // 15..18: Outer edge tip
      const Offset(-tipY, w * 0.5),
      const Offset(-tipY, 0),                     // 17: Safe zone entry gate
      const Offset(-tipY, -w * 0.5),
    ];

    final angles = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];
    final baseOffsets = [0, 19, 38, 57];

    for (int p = 0; p < 4; p++) {
      final angle = angles[p];
      final baseGlobalIdx = baseOffsets[p];

      Offset rotate(Offset pt) => center +
          Offset(
            pt.dx * math.cos(angle) - pt.dy * math.sin(angle),
            pt.dx * math.sin(angle) + pt.dy * math.cos(angle),
          );

      // Track holes
      for (int i = 0; i < quarterTemplate.length; i++) {
        final globalIdx = (baseGlobalIdx + i) % 76;
        _trackCoords[globalIdx] = rotate(quarterTemplate[i]);
      }

      // Safe zone (4 holes on middle line)
      for (int s = 0; s < 4; s++) {
        final sY = tipY - colStep * (s + 1);
        _safeCoords['p${p}_s$s'] = rotate(Offset(0, sY));
      }

      // Home dishes ("البيت") at 45 degree corners
      final dishAngle = angle + 3 * math.pi / 4;
      const dishDist = 328.0;
      final dishCenter =
          center + Offset(math.cos(dishAngle) * dishDist, math.sin(dishAngle) * dishDist);

      const hGap = 21.0;
      const hOffsets = [
        Offset(-hGap, -hGap),
        Offset(hGap, -hGap),
        Offset(-hGap, hGap),
        Offset(hGap, hGap),
      ];
      for (int h = 0; h < 4; h++) {
        _homeCoords['p${p}_h$h'] = dishCenter + hOffsets[h];
      }
    }
  }

  void _drawDecorativeShellDots(Canvas canvas, Offset center) {
    const double w = 68.0;
    const double tipY = 412.0;
    const double colStep = 64.0;
    final angles = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];

    final shellPaint = Paint()..color = const Color(0xFFF8F5EE);
    final shellBorder = Paint()
      ..color = const Color(0xFF424242).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final angle in angles) {
      Offset rotate(Offset pt) => center +
          Offset(
            pt.dx * math.cos(angle) - pt.dy * math.sin(angle),
            pt.dx * math.sin(angle) + pt.dy * math.cos(angle),
          );

      for (int d = 0; d < 4; d++) {
        final dY = tipY - colStep * (d + 1);
        for (final sign in [-1, 1]) {
          final pos = rotate(Offset(sign * w * 0.5, dY));
          canvas.drawCircle(pos, 5.0, shellPaint);
          canvas.drawCircle(pos, 5.0, shellBorder);
        }
      }
    }
  }

  void _drawBoardWoodNumbers(Canvas canvas, Offset center) {
    const double w = 68.0;
    const double tipY = 412.0;
    const double colStep = 64.0;
    final angles = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];
    final playerColors = [
      const Color(0xFF2979FF),
      const Color(0xFFFBC02D),
      const Color(0xFF2E7D32),
      const Color(0xFFD32F2F),
    ];

    for (int p = 0; p < 4; p++) {
      final angle = angles[p];
      final pColor = playerColors[p];

      Offset rotate(Offset pt) => center +
          Offset(
            pt.dx * math.cos(angle) - pt.dy * math.sin(angle),
            pt.dx * math.sin(angle) + pt.dy * math.cos(angle),
          );

      // Edge tip row numbers
      _drawEngravedText(canvas, 'قاعدة', rotate(const Offset(-w, tipY + 22)),
          fontSize: 11, color: const Color(0xFFFFD54F));
      _drawEngravedText(canvas, '18', rotate(const Offset(-w * 0.5, tipY + 22)));
      _drawEngravedText(canvas, '17', rotate(const Offset(0, tipY + 22)), color: pColor);
      _drawEngravedText(canvas, '16', rotate(const Offset(w * 0.5, tipY + 22)));
      _drawEngravedText(canvas, '15', rotate(const Offset(w, tipY + 22)));

      // Inward column (1..4)
      _drawEngravedText(canvas, '1', rotate(const Offset(-w - 20, tipY - colStep * 1)));
      _drawEngravedText(canvas, '2', rotate(const Offset(-w - 20, tipY - colStep * 2)));
      _drawEngravedText(canvas, '3', rotate(const Offset(-w - 20, tipY - colStep * 3)));
      _drawEngravedText(canvas, '4', rotate(const Offset(-w - 20, tipY - colStep * 4)));

      // Safe zone numbers (1..4)
      _drawEngravedText(canvas, '1', rotate(const Offset(20, tipY - colStep * 1)), color: pColor);
      _drawEngravedText(canvas, '2', rotate(const Offset(20, tipY - colStep * 2)), color: pColor);
      _drawEngravedText(canvas, '3', rotate(const Offset(20, tipY - colStep * 3)), color: pColor);
      _drawEngravedText(canvas, '4', rotate(const Offset(20, tipY - colStep * 4)), color: pColor);

      // Home Dish label ("البيت")
      final dishAngle = angle + 3 * math.pi / 4;
      final dishCenter =
          center + Offset(math.cos(dishAngle) * 328, math.sin(dishAngle) * 328);
      final labelPos = dishCenter + Offset(math.cos(dishAngle) * 60, math.sin(dishAngle) * 60);
      _drawEngravedText(canvas, 'البيت', labelPos,
          fontSize: 12, color: const Color(0xFFDCC8AA));
    }
  }

  void _drawEngravedText(
    Canvas canvas,
    String text,
    Offset pos, {
    double fontSize = 11,
    Color color = const Color(0xFFE2D1B8),
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          shadows: const [
            Shadow(color: Color(0xFF1B1E22), offset: Offset(1, 1), blurRadius: 1),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawAllHoles(Canvas canvas) {
    const holeRadius = 12.5;
    final playerColors = [
      const Color(0xFF2979FF),
      const Color(0xFFFBC02D),
      const Color(0xFF2E7D32),
      const Color(0xFFD32F2F),
    ];

    // 4 Corner Home Dishes ("البيت")
    for (int p = 0; p < 4; p++) {
      final angle = p * math.pi / 2 + 3 * math.pi / 4;
      final dishCenter =
          const Offset(500, 500) + Offset(math.cos(angle) * 328, math.sin(angle) * 328);

      final dishShadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(dishCenter, 56, dishShadow);

      final dishPaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF555B63), Color(0xFF42474E), Color(0xFF2C3035)],
          stops: [0.0, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: dishCenter, radius: 56));
      canvas.drawCircle(dishCenter, 56, dishPaint);

      final dishRim = Paint()
        ..color = const Color(0xFF8A939E).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(dishCenter, 56, dishRim);
    }

    // Home holes
    _homeCoords.forEach((key, pos) {
      final pIdx = int.parse(key.substring(1, 2));
      _drawCarvedWoodHole(
        canvas,
        pos,
        holeRadius,
        innerEnamelColor: playerColors[pIdx].withValues(alpha: 0.35),
      );
    });

    // Safe zone holes
    _safeCoords.forEach((key, pos) {
      final pIdx = int.parse(key.substring(1, 2));
      _drawCarvedWoodHole(
        canvas,
        pos,
        holeRadius,
        innerEnamelColor: playerColors[pIdx],
      );
    });

    // 76 Track holes
    _trackCoords.forEach((idx, pos) {
      final isSpawn = (idx == 0 || idx == 19 || idx == 38 || idx == 57);
      if (isSpawn) {
        final pIdx = idx ~/ 19;
        _drawCarvedWoodHole(
          canvas,
          pos,
          holeRadius,
          innerEnamelColor: playerColors[pIdx],
          isSpawnPoint: true,
        );
      } else {
        _drawCarvedWoodHole(canvas, pos, holeRadius);
      }
    });
  }

  void _drawCarvedWoodHole(
    Canvas canvas,
    Offset pos,
    double radius, {
    Color? innerEnamelColor,
    bool isSpawnPoint = false,
  }) {
    // 1. Hole cavity inner depth
    final cavityPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.35),
        colors: [
          Color(0xFF1A1C1F),
          Color(0xFF272B30),
          Color(0xFF3B4047),
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: pos, radius: radius));
    canvas.drawCircle(pos, radius, cavityPaint);

    // 2. Inner enamel color for safe zone or spawn
    if (innerEnamelColor != null) {
      final enamelRadius = radius * 0.72;
      final enamelPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.25),
          colors: [
            innerEnamelColor.withValues(alpha: 0.95),
            innerEnamelColor.withValues(alpha: 0.65),
            innerEnamelColor.withValues(alpha: 0.35),
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: pos, radius: enamelRadius));
      canvas.drawCircle(pos, enamelRadius, enamelPaint);
    }

    // 3. Beveled rim highlight
    final bevelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: radius),
      0.1 * math.pi,
      0.8 * math.pi,
      false,
      bevelPaint,
    );

    // 4. Golden spawn ring
    if (isSpawnPoint) {
      final ringPaint = Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(pos, radius + 2.5, ringPaint);
    }
  }

  void _drawMovePreviews(Canvas canvas) {
    if (selectedMarble == null) return;

    Offset? targetPos;
    if (previewTargetTrack != null) {
      targetPos = _trackCoords[previewTargetTrack!];
    } else if (previewTargetSafe != null) {
      targetPos = _safeCoords['p${selectedMarble!.ownerId}_s$previewTargetSafe'];
    }

    if (targetPos != null) {
      // Golden pulsing halo at destination
      final previewPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6;
      canvas.drawCircle(targetPos, 16, previewPaint);

      // Fluid trajectory curve connecting marble to destination
      final startPos = _getMarblePixelPosition(selectedMarble!);
      if (startPos != null) {
        final path = Path();
        path.moveTo(startPos.dx, startPos.dy);
        final mid = (startPos + targetPos) / 2 + const Offset(0, -25);
        path.quadraticBezierTo(mid.dx, mid.dy, targetPos.dx, targetPos.dy);

        final linePaint = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawPath(path, linePaint);
      }
    }
  }

  void _drawMarbles(Canvas canvas) {
    const marbleRadius = 13.5;

    for (final marble in marbles) {
      final pos = _getMarblePixelPosition(marble);
      if (pos == null) continue;

      final isSelected = selectedMarble?.id == marble.id;

      // Drop shadow on wood
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(pos + const Offset(2.5, 3.5), marbleRadius, shadowPaint);

      // Spherical glass gradient
      final marblePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: [
            marble.secondaryColor,
            marble.primaryColor,
            marble.primaryColor.withValues(alpha: 0.8),
            Colors.black87,
          ],
          stops: const [0.0, 0.45, 0.8, 1.0],
        ).createShader(Rect.fromCircle(center: pos, radius: marbleRadius));
      canvas.drawCircle(pos, marbleRadius, marblePaint);

      // Bright white specular glint (اللمعة الزجاجية عند زاوية 10)
      final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.88);
      canvas.drawCircle(pos + const Offset(-4.725, -4.725), 3.2, glintPaint);

      // Selection golden border
      if (isSelected) {
        final selectBorder = Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8;
        canvas.drawCircle(pos, marbleRadius + 3.0, selectBorder);
      }
    }
  }

  Offset? _getMarblePixelPosition(JackarooBoardMarble marble) {
    if (marble.isHome) {
      return _homeCoords['p${marble.ownerId}_h${marble.indexInOwner}'];
    } else if (marble.isInSafeZone) {
      return _safeCoords['p${marble.ownerId}_s${marble.positionIndex}'];
    } else if (marble.isOnTrack) {
      return _trackCoords[marble.positionIndex];
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant _Authentic76JackarooPainter oldDelegate) => true;
}
