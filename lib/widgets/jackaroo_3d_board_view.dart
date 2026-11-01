import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/game_audio_service.dart';
import '../services/preferences_service.dart';

/// Representation of a marble on the authentic Jackaroo board.
enum JackarooMarbleLocation { home, track, safeZone, finished }

class JackarooBoardMarble {
  final int id;
  final int ownerId; // 0: Royal Blue (Player), 1: Emerald Green, 2: Jet Black, 3: Sky Blue
  final int indexInOwner; // 0..3
  final Color primaryColor;
  final Color secondaryColor;
  JackarooMarbleLocation location;
  int positionIndex; // 0..3 in home, 0..79 on track, 0..3 in safeZone

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

/// A hyper-realistic Jackaroo board exactly matching the physical board photograph:
/// - 76 track holes (19 per quadrant with 5 complete curve holes per corner, and BOTH arm corners filled)
/// - 16 safe zone runway holes (4 per arm)
/// - Total: 92 laser-carved holes on the board surface
/// - 4 corner sunken circular dishes ("البيت") holding 4 glass marbles each (2x2)
/// - Slate-blue/grey circular board with beveled chrome rim
/// - Large circular center well in warm birch wood with inlaid golden/brass bezel
/// - Royal Blue, Emerald Green, Jet Black, and Sky Blue glass marbles with specular gleam
/// - Authentic Persian/Oriental red carpet background
/// - Complete Jackaroo rules: Safe zone runway entry, Jack (J) swap, 4 backwards, King & Ace exit, capturing
/// - Face-up card resting inside the center birch wood tray
class Jackaroo3DBoardView extends StatefulWidget {
  final String? activeCard;
  final String? lastPlayedCard;
  final ValueChanged<String>? onStatusMessage;
  final VoidCallback? onTurnFinished;
  final void Function(int team1Safe, int team2Safe)? onScoresUpdated;
  final ValueChanged<String>? onGameWon;
  final bool isTopDownView;

  const Jackaroo3DBoardView({
    super.key,
    this.activeCard,
    this.lastPlayedCard,
    this.onStatusMessage,
    this.onTurnFinished,
    this.onScoresUpdated,
    this.onGameWon,
    this.isTopDownView = false,
  });

  @override
  State<Jackaroo3DBoardView> createState() => Jackaroo3DBoardViewState();
}

class Jackaroo3DBoardViewState extends State<Jackaroo3DBoardView>
    with SingleTickerProviderStateMixin {
  final GameAudioService _audio = GameAudioService();

  // 3D Perspective Angles
  double _pitch = 0.0; // 0.0 for top-down (exact photo), ~0.38 for 3D tilt
  double _yaw = 0.0;   // Horizontal orbit rotation

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

  // Turn status: 0: Player (Royal Blue), 1: Emerald Green, 2: Jet Black (Partner), 3: Sky Blue
  int _currentTurn = 0;
  bool _isMoving = false;
  bool _isTopDown = true;
  String? _displayedCenterCard;

  // Track length on the authentic board: 76 track holes
  static const int _trackLength = 76;

  // Base spawn track slots for the 4 players (19 holes per quadrant)
  // Player 0 (Bottom): 0
  // Player 1 (Right): 57
  // Player 2 (Top): 38
  // Player 3 (Left): 19
  static const List<int> _playerSpawnSlots = [0, 57, 38, 19];

  // Coordinates calculated by the painter in 1000x1000 virtual space
  final Map<int, Offset> _trackCoordinates = {};
  final Map<String, Offset> _homeCoordinates = {};
  final Map<String, Offset> _safeZoneCoordinates = {};

  Map<int, Offset> get trackCoordinates => _trackCoordinates;
  Map<String, Offset> get homeCoordinates => _homeCoordinates;
  Map<String, Offset> get safeZoneCoordinates => _safeZoneCoordinates;

  @override
  void initState() {
    super.initState();
    _isTopDown = widget.isTopDownView;
    _pitch = _isTopDown ? 0.0 : 0.38;
    _displayedCenterCard = widget.lastPlayedCard ?? 'A♠';
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
  void didUpdateWidget(covariant Jackaroo3DBoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTopDownView != widget.isTopDownView) {
      setViewMode(widget.isTopDownView);
    }
    if (widget.lastPlayedCard != null && widget.lastPlayedCard != _displayedCenterCard) {
      setState(() {
        _displayedCenterCard = widget.lastPlayedCard;
      });
    }
  }

  @override
  void dispose() {
    _cameraAnimController.dispose();
    super.dispose();
  }

  void _initMarbles() {
    _marbles = [];
    final playerColors = [
      const Color(0xFF1565C0), // 0: Royal Blue (Player)
      const Color(0xFF2E7D32), // 1: Emerald Green (Opponent 1)
      const Color(0xFF1E2124), // 2: Jet Black Obsidian (Teammate)
      const Color(0xFF4FC3F7), // 3: Sky Blue (Opponent 2)
    ];
    final secondaryColors = [
      const Color(0xFF64B5F6), // Royal Blue highlight
      const Color(0xFF81C784), // Green highlight
      const Color(0xFF616161), // Black specular reflection
      const Color(0xFFE1F5FE), // Sky blue light highlight
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

  void toggleViewMode() {
    setViewMode(!_isTopDown);
  }

  void setViewMode(bool topDown) {
    _isTopDown = topDown;
    final targetPitch = topDown ? 0.0 : 0.38;
    _pitchAnim = Tween<double>(begin: _pitch, end: targetPitch).animate(
      CurvedAnimation(parent: _cameraAnimController, curve: Curves.easeOutCubic),
    );
    _yawAnim = Tween<double>(begin: _yaw, end: 0.0).animate(
      CurvedAnimation(parent: _cameraAnimController, curve: Curves.easeOutCubic),
    );
    _cameraAnimController.forward(from: 0.0);
    PreferencesService.triggerHaptic(AppHapticType.light);
  }

  void resetCamera() {
    setViewMode(_isTopDown);
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
    if (card.startsWith('4')) return -4; // Reverse 4 steps
    if (card.startsWith('3')) return 3;
    if (card.startsWith('2')) return 2;
    return 1;
  }

  bool _isPlayerFinished(int playerId) {
    return _marbles.where((m) => m.ownerId == playerId && m.isInSafeZone).length == 4;
  }

  bool _canSelectMarble(JackarooBoardMarble marble) {
    if (_isMoving || _currentTurn != 0) return false;

    // Player 0 can move their own marbles, OR partner's (Player 2) if Player 0 finished
    final canControl = marble.ownerId == 0 || (_isPlayerFinished(0) && marble.ownerId == 2);
    if (!canControl) return false;

    final card = widget.activeCard ?? 'A♠';
    final isKingOrAce = card.startsWith('K') || card.startsWith('A');

    if (marble.isHome) {
      return isKingOrAce;
    }

    if (marble.isInSafeZone) {
      final step = _getCardStepValue(card);
      if (step <= 0) return false;
      final targetSafe = marble.positionIndex + step;
      if (targetSafe < 4) {
        final occupied = _marbles.any((m) =>
            m.ownerId == marble.ownerId &&
            m.isInSafeZone &&
            m.positionIndex == targetSafe);
        return !occupied;
      }
      return false;
    }

    if (marble.isOnTrack) {
      return true;
    }

    return false;
  }

  void _onMarbleClicked(JackarooBoardMarble marble) {
    final card = widget.activeCard ?? 'A♠';
    final isJack = card.startsWith('J');

    // Jack Swap Handling
    if (isJack && _selectedMarble != null && _selectedMarble!.isOnTrack) {
      if (marble.isOnTrack && marble.ownerId != _selectedMarble!.ownerId) {
        _executeJackSwap(_selectedMarble!, marble);
        return;
      }
    }

    if (!_canSelectMarble(marble)) {
      PreferencesService.triggerHaptic(AppHapticType.light);
      return;
    }

    final isKingOrAce = card.startsWith('K') || card.startsWith('A');

    setState(() {
      _selectedMarble = marble;

      if (marble.isHome && isKingOrAce) {
        _previewTargetTrack = _playerSpawnSlots[marble.ownerId];
        _previewTargetSafe = null;
      } else if (marble.isInSafeZone) {
        final step = _getCardStepValue(card);
        final targetSafe = marble.positionIndex + step;
        if (targetSafe < 4) {
          _previewTargetSafe = targetSafe;
          _previewTargetTrack = null;
        }
      } else if (marble.isOnTrack) {
        if (isJack) {
          _previewTargetTrack = null;
          _previewTargetSafe = null;
          widget.onStatusMessage?.call('اختر حجر أحد المنافسين لتبديل الأماكن بالولد (J) 🔄');
          PreferencesService.triggerHaptic(AppHapticType.selection);
          return;
        }

        final step = _getCardStepValue(card);
        final spawn = _playerSpawnSlots[marble.ownerId];

        // Check 4 backwards
        if (step == -4) {
          final nextPos = (marble.positionIndex - 4 + _trackLength) % _trackLength;
          _previewTargetTrack = nextPos;
          _previewTargetSafe = null;
        } else {
          // Check safe zone entry (distance 74 to gate)
          final stepsFromSpawn = (marble.positionIndex - spawn + _trackLength) % _trackLength;
          if (stepsFromSpawn + step >= 74) {
            final safeSlot = (stepsFromSpawn + step) - 74;
            if (safeSlot >= 0 && safeSlot < 4) {
              _previewTargetSafe = safeSlot;
              _previewTargetTrack = null;
            } else {
              _previewTargetTrack = (marble.positionIndex + step + _trackLength) % _trackLength;
              _previewTargetSafe = null;
            }
          } else {
            _previewTargetTrack = (marble.positionIndex + step + _trackLength) % _trackLength;
            _previewTargetSafe = null;
          }
        }
      }
    });

    PreferencesService.triggerHaptic(AppHapticType.selection);
    _executeMove(marble);
  }

  Future<void> _executeJackSwap(JackarooBoardMarble myMarble, JackarooBoardMarble oppMarble) async {
    setState(() => _isMoving = true);
    _audio.playCardPlace();

    await Future<void>.delayed(const Duration(milliseconds: 250));

    final tempPos = myMarble.positionIndex;
    setState(() {
      myMarble.positionIndex = oppMarble.positionIndex;
      oppMarble.positionIndex = tempPos;
      _selectedMarble = null;
      _previewTargetTrack = null;
      _previewTargetSafe = null;
      _isMoving = false;
      _displayedCenterCard = widget.activeCard;
    });

    _audio.playMarbleEat();
    PreferencesService.triggerHaptic(AppHapticType.heavy);
    widget.onStatusMessage?.call('تم تبديل حجرين بالولد (J) بنجاح! 🔄');

    widget.onTurnFinished?.call();
    _checkVictory();
    _playBotsTurns();
  }

  Future<void> _executeMove(JackarooBoardMarble marble) async {
    final card = widget.activeCard ?? 'A♠';
    final isKingOrAce = card.startsWith('K') || card.startsWith('A');

    if (card.startsWith('J')) {
      return; // Handled by swap selection
    }

    setState(() => _isMoving = true);

    if (marble.isHome && isKingOrAce) {
      _audio.playCardPlace();
      await Future<void>.delayed(const Duration(milliseconds: 260));

      final spawn = _playerSpawnSlots[marble.ownerId];
      _checkAndCapture(spawn, marble.ownerId);

      setState(() {
        marble.location = JackarooMarbleLocation.track;
        marble.positionIndex = spawn;
        _displayedCenterCard = card;
      });

      _audio.playMarbleStep();
      widget.onStatusMessage?.call('أخرجت حجراً إلى خط البداية! 🚀');
    } else if (marble.isInSafeZone) {
      final step = _getCardStepValue(card);
      final nextSafe = marble.positionIndex + step;
      if (nextSafe < 4) {
        _audio.playMarbleStep();
        await Future<void>.delayed(const Duration(milliseconds: 300));

        setState(() {
          marble.positionIndex = nextSafe;
          _displayedCenterCard = card;
        });

        _audio.playMarbleStep();
        widget.onStatusMessage?.call('تقدم الحجر داخل مسار الأمان إلى الحفرة ${nextSafe + 1}! 🛡️');
      }
    } else if (marble.isOnTrack) {
      final step = _getCardStepValue(card);
      final spawn = _playerSpawnSlots[marble.ownerId];

      _audio.playMarbleStep();
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // 4 backwards
      if (step == -4) {
        final nextPos = (marble.positionIndex - 4 + _trackLength) % _trackLength;
        _checkAndCapture(nextPos, marble.ownerId);

        setState(() {
          marble.positionIndex = nextPos;
          _displayedCenterCard = card;
        });
        _audio.playMarbleStep();
        widget.onStatusMessage?.call('رجوع 4 خطوات للخلف نحو بوابة الأمان! ⏪');
      } else {
        // Safe Zone Entry
        final stepsFromSpawn = (marble.positionIndex - spawn + _trackLength) % _trackLength;
        if (stepsFromSpawn + step >= 74) {
          final safeSlot = (stepsFromSpawn + step) - 74;
          if (safeSlot >= 0 && safeSlot < 4) {
            final occupied = _marbles.any((m) =>
                m.ownerId == marble.ownerId &&
                m.isInSafeZone &&
                m.positionIndex == safeSlot);

            if (!occupied) {
              setState(() {
                marble.location = JackarooMarbleLocation.safeZone;
                marble.positionIndex = safeSlot;
                _displayedCenterCard = card;
              });
              _audio.playCardPlace();
              PreferencesService.triggerHaptic(AppHapticType.heavy);
              widget.onStatusMessage?.call('دخل الحجر مسار الأمان والقلعة بأمان! 🏰');
            } else {
              final nextPos = (marble.positionIndex + step + _trackLength) % _trackLength;
              _checkAndCapture(nextPos, marble.ownerId);
              setState(() {
                marble.positionIndex = nextPos;
                _displayedCenterCard = card;
              });
            }
          } else {
            final nextPos = (marble.positionIndex + step + _trackLength) % _trackLength;
            _checkAndCapture(nextPos, marble.ownerId);
            setState(() {
              marble.positionIndex = nextPos;
              _displayedCenterCard = card;
            });
          }
        } else {
          final nextPos = (marble.positionIndex + step + _trackLength) % _trackLength;
          _checkAndCapture(nextPos, marble.ownerId);

          setState(() {
            marble.positionIndex = nextPos;
            _displayedCenterCard = card;
          });
          _audio.playMarbleStep();
          widget.onStatusMessage?.call('تحرك الحجر $step خطوات على الرقعة! 🎯');
        }
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 320));

    setState(() {
      _selectedMarble = null;
      _previewTargetTrack = null;
      _previewTargetSafe = null;
      _isMoving = false;
    });

    _notifyScores();
    _checkVictory();
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

  void _notifyScores() {
    final team1Safe = _marbles.where((m) => (m.ownerId == 0 || m.ownerId == 2) && m.isInSafeZone).length;
    final team2Safe = _marbles.where((m) => (m.ownerId == 1 || m.ownerId == 3) && m.isInSafeZone).length;
    widget.onScoresUpdated?.call(team1Safe, team2Safe);
  }

  void _checkVictory() {
    final team1Safe = _marbles.where((m) => (m.ownerId == 0 || m.ownerId == 2) && m.isInSafeZone).length;
    final team2Safe = _marbles.where((m) => (m.ownerId == 1 || m.ownerId == 3) && m.isInSafeZone).length;

    if (team1Safe == 8) {
      widget.onGameWon?.call('فريقك (الأزرق والأسود) حقق الفوز الكبير بالجاكارو! 🏆');
    } else if (team2Safe == 8) {
      widget.onGameWon?.call('فاز الفريق المنافس (الأخضر والسماوي)! حظاً أوفر في الجولة القادمة');
    }
  }

  Future<void> _playBotsTurns() async {
    final botNames = [
      'سارة (أخضر • شريكتك)',
      'فهد (أسود • منافس)',
      'خالد (سماوي • منافس)',
    ];
    final botIds = [1, 2, 3];

    for (int i = 0; i < botIds.length; i++) {
      final b = botIds[i];
      if (!mounted) return;
      setState(() => _currentTurn = b);
      widget.onStatusMessage?.call('دور ${botNames[i]} يفكّر...');

      await Future<void>.delayed(const Duration(milliseconds: 800));
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
        widget.onStatusMessage?.call('${botNames[i]} أخرج حجراً جديداً');
      } else if (trackMarble != null) {
        final steps = (math.Random().nextInt(7) + 1);
        final target = (trackMarble.positionIndex + steps) % _trackLength;
        _checkAndCapture(target, b);
        setState(() {
          trackMarble.positionIndex = target;
        });
        _audio.playMarbleStep();
        widget.onStatusMessage?.call('${botNames[i]} تحرك $steps خطوات');
      } else if (homeMarble != null) {
        final spawn = _playerSpawnSlots[b];
        setState(() {
          homeMarble.location = JackarooMarbleLocation.track;
          homeMarble.positionIndex = spawn;
        });
        _audio.playCardPlace();
      }

      _notifyScores();
      _checkVictory();
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
        final side = math.min(constraints.maxWidth, constraints.maxHeight) * 0.98;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Rich Persian / Oriental Carpet Background matching photo
            const Positioned.fill(
              child: CustomPaint(
                painter: _OrientalCarpetPainter(),
              ),
            ),

            // 2. Interactive Tabletop Board
            GestureDetector(
              onPanUpdate: (details) {
                if (_isTopDown) return;
                setState(() {
                  _yaw += details.delta.dx * 0.005;
                  _pitch = (_pitch - details.delta.dy * 0.004).clamp(0.0, 0.70);
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0014)
                      ..rotateX(_pitch)
                      ..rotateZ(_yaw),
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: CustomPaint(
                        painter: _Jackaroo92ExactPainter(
                          marbles: _marbles,
                          selectedMarble: _selectedMarble,
                          previewTargetTrack: _previewTargetTrack,
                          previewTargetSafe: _previewTargetSafe,
                          centerCard: _displayedCenterCard,
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildTapTargetOverlay(double side) {
    final scale = side / 1000.0;
    final card = widget.activeCard ?? 'A♠';
    final isJack = card.startsWith('J');

    final targets = (_selectedMarble != null && isJack)
        ? _marbles
        : _marbles.where((m) => m.ownerId == 0 || (_isPlayerFinished(0) && m.ownerId == 2));

    return Stack(
      children: targets.map((m) {
        Offset? pos;
        if (m.isHome) {
          pos = _homeCoordinates['p${m.ownerId}_h${m.indexInOwner}'];
        } else if (m.isOnTrack) {
          pos = _trackCoordinates[m.positionIndex];
        } else if (m.isInSafeZone) {
          pos = _safeZoneCoordinates['p${m.ownerId}_s${m.positionIndex}'];
        }

        if (pos == null) return const SizedBox.shrink();

        final screenPos = pos * scale;
        final isPlayable = _canSelectMarble(m) || (_selectedMarble != null && isJack && m.isOnTrack && m.ownerId != 0);

        return Positioned(
          left: screenPos.dx - 24,
          top: screenPos.dy - 24,
          width: 48,
          height: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onMarbleClicked(m),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isPlayable
                    ? Border.all(
                        color: (isJack && m.ownerId != 0) ? const Color(0xFFFF5252) : const Color(0xFFFFD54F),
                        width: 2.8,
                      )
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Paints the authentic Persian / Oriental crimson rug underneath the board.
class _OrientalCarpetPainter extends CustomPainter {
  const _OrientalCarpetPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final carpetPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF9E182B),
          Color(0xFF881022),
          Color(0xFF6B0B19),
          Color(0xFF480610),
        ],
        stops: [0.0, 0.45, 0.8, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, carpetPaint);

    final motifPaintCream = Paint()
      ..color = const Color(0xFFF7EED9).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final motifPaintGold = Paint()
      ..color = const Color(0xFFDFB86C).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final motifPaintDark = Paint()
      ..color = const Color(0xFF1B2232).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    const pad = 12.0;
    canvas.drawRect(rect.deflate(pad), motifPaintGold);
    canvas.drawRect(rect.deflate(pad + 6), motifPaintCream);

    const cornerSize = 75.0;
    _drawCarpetCorner(canvas, const Offset(pad, pad), cornerSize, motifPaintGold, motifPaintCream);
    _drawCarpetCorner(canvas, Offset(size.width - pad, pad), cornerSize, motifPaintGold, motifPaintCream, flipX: true);
    _drawCarpetCorner(canvas, Offset(pad, size.height - pad), cornerSize, motifPaintGold, motifPaintCream, flipY: true);
    _drawCarpetCorner(canvas, Offset(size.width - pad, size.height - pad), cornerSize, motifPaintGold, motifPaintCream, flipX: true, flipY: true);

    final step = math.max(36.0, size.width / 24);
    for (double x = pad + 20; x < size.width - pad; x += step) {
      for (double y = pad + 20; y < size.height - pad; y += step) {
        final distToCenter = (Offset(x, y) - rect.center).distance;
        if (distToCenter > size.shortestSide * 0.40) {
          canvas.drawCircle(Offset(x, y), 2.2, motifPaintDark);
          canvas.drawCircle(Offset(x, y), 1.4, motifPaintCream);
        }
      }
    }
  }

  void _drawCarpetCorner(
    Canvas canvas,
    Offset origin,
    double size,
    Paint pGold,
    Paint pCream, {
    bool flipX = false,
    bool flipY = false,
  }) {
    final sx = flipX ? -1.0 : 1.0;
    final sy = flipY ? -1.0 : 1.0;

    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(origin.dx + size * sx, origin.dy)
      ..cubicTo(
        origin.dx + size * 0.7 * sx,
        origin.dy + size * 0.3 * sy,
        origin.dx + size * 0.3 * sx,
        origin.dy + size * 0.7 * sy,
        origin.dx,
        origin.dy + size * sy,
      )
      ..close();

    canvas.drawPath(path, pGold);
    canvas.drawPath(path, pCream);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The exact Jackaroo board painter mirroring the user's photograph:
/// - 76 track holes (19 per player with 5 complete curve holes per corner and BOTH arm corners filled)
/// - 16 safe zone runway holes (4 per arm)
/// - Total: 92 laser-carved holes on the board surface!
/// - 4 corner sunken dishes ("البيت") with 4 marbles each (2x2 cluster)
/// - Slate-blue composite stone finish with realistic carved birch wood holes
/// - Lying playing card rendered face-up inside the center birch wood tray
class _Jackaroo92ExactPainter extends CustomPainter {
  final List<JackarooBoardMarble> marbles;
  final JackarooBoardMarble? selectedMarble;
  final int? previewTargetTrack;
  final int? previewTargetSafe;
  final String? centerCard;
  final void Function(
    Map<int, Offset> track,
    Map<String, Offset> home,
    Map<String, Offset> safe,
  )? onCoordinatesComputed;

  final Map<int, Offset> _trackCoords = {};
  final Map<String, Offset> _homeCoords = {};
  final Map<String, Offset> _safeCoords = {};

  _Jackaroo92ExactPainter({
    required this.marbles,
    this.selectedMarble,
    this.previewTargetTrack,
    this.previewTargetSafe,
    this.centerCard,
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
    const boardRadius = 472.0;
    const cardWellRadius = 138.0;

    _drawSlateCircularBoard(canvas, center, boardRadius);
    _drawBirchCenterWell(canvas, center, cardWellRadius);
    _drawCenterCard(canvas, center);
    _computeHolePositions(center);
    _drawAllHoles(canvas);
    _drawMovePreviews(canvas);
    _drawGlassMarbles(canvas);

    canvas.restore();

    onCoordinatesComputed?.call(_trackCoords, _homeCoords, _safeCoords);
  }

  void _drawSlateCircularBoard(Canvas canvas, Offset center, double radius) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center + const Offset(0, 14), radius, shadowPaint);

    const slateGradient = RadialGradient(
      center: Alignment(-0.15, -0.20),
      colors: [
        Color(0xFF677788),
        Color(0xFF5A697A),
        Color(0xFF4C5969),
        Color(0xFF3F4B59),
      ],
      stops: [0.0, 0.45, 0.80, 1.0],
    );
    final boardPaint = Paint()
      ..shader = slateGradient.createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, boardPaint);

    final grainPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center + const Offset(-70, -50), radius * 0.70, grainPaint);
    canvas.drawCircle(center + const Offset(60, 55), radius * 0.78, grainPaint);

    final rimShadow = Paint()
      ..color = const Color(0xFF20262E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6;
    canvas.drawCircle(center, radius - 1.0, rimShadow);

    final rimHighlight = Paint()
      ..color = const Color(0xFFD3DBE2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(center, radius - 2.5, rimHighlight);
  }

  void _drawBirchCenterWell(Canvas canvas, Offset center, double wellRadius) {
    final wellShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, wellRadius, wellShadow);

    final wellPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        colors: [
          Color(0xFFF3E7CF),
          Color(0xFFE5D3AF),
          Color(0xFFD2BD93),
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: wellRadius));
    canvas.drawCircle(center, wellRadius, wellPaint);

    final goldBezel = Paint()
      ..color = const Color(0xFFC8A858)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;
    canvas.drawCircle(center, wellRadius, goldBezel);

    final goldHighlight = Paint()
      ..color = const Color(0xFFF2DCA5).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, wellRadius - 1.2, goldHighlight);
  }

  void _drawCenterCard(Canvas canvas, Offset center) {
    if (centerCard == null || centerCard!.isEmpty) return;

    final cardStr = centerCard!;
    final isRed = cardStr.contains('♥') || cardStr.contains('♦');

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.08);

    const cardW = 54.0;
    const cardH = 78.0;
    final cardRect = Rect.fromCenter(center: Offset.zero, width: cardW, height: cardH);

    final cShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(RRect.fromRectAndRadius(cardRect.shift(const Offset(2, 3)), const Radius.circular(5)), cShadow);

    final cFace = Paint()..color = const Color(0xFFFCFCFC);
    canvas.drawRRect(RRect.fromRectAndRadius(cardRect, const Radius.circular(5)), cFace);

    final cBorder = Paint()
      ..color = const Color(0xFFD6D6D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(RRect.fromRectAndRadius(cardRect, const Radius.circular(5)), cBorder);

    final textColor = isRed ? const Color(0xFFC62828) : const Color(0xFF212121);

    final tpTop = TextPainter(
      text: TextSpan(
        text: cardStr,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpTop.paint(canvas, const Offset(-23, -36));

    final suitChar = cardStr.characters.last;
    final tpSuit = TextPainter(
      text: TextSpan(
        text: suitChar,
        style: TextStyle(
          color: textColor,
          fontSize: 22,
          fontFamily: 'Cairo',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpSuit.paint(canvas, Offset(-tpSuit.width / 2, -tpSuit.height / 2));

    canvas.restore();
  }

  void _computeHolePositions(Offset center) {
    _trackCoords.clear();
    _homeCoords.clear();
    _safeCoords.clear();

    const double w = 72.0;
    const double tipY = 422.0;
    const double colStep = 35.5;

    // 19 track holes per quadrant template (including 5 curve holes and BOTH arm corners)
    final quarterTemplate = <Offset>[
      const Offset(-w, tipY),                // 0: Spawn & Arm Corner 1 (golden bezel)
      const Offset(-w, tipY - colStep * 1),   // 1
      const Offset(-w, tipY - colStep * 2),   // 2
      const Offset(-w, tipY - colStep * 3),   // 3
      const Offset(-w, tipY - colStep * 4),   // 4
      const Offset(-w, tipY - colStep * 5),   // 5
      const Offset(-111.5, 229.2),           // 6: Curve 1
      const Offset(-147.9, 207.6),           // 7: Curve 2
      const Offset(-180.2, 180.2),           // 8: Curve 3 (Corner apex hole!)
      const Offset(-207.6, 147.9),           // 9: Curve 4
      const Offset(-229.2, 111.5),           // 10: Curve 5
      const Offset(-244.5, w),               // 11
      const Offset(-280.0, w),               // 12
      const Offset(-315.5, w),               // 13
      const Offset(-351.0, w),               // 14
      const Offset(-386.5, w),               // 15
      const Offset(-tipY, w),                // 16: Arm Corner 2 (Squarely in the corner!)
      const Offset(-tipY, w / 3.0),          // 17: Arm Tip Hole 1
      const Offset(-tipY, -w / 3.0),         // 18: Arm Tip Hole 2
    ];

    final angles = [0.0, 3 * math.pi / 2, math.pi, math.pi / 2];
    final baseOffsets = [0, 57, 38, 19];

    for (int p = 0; p < 4; p++) {
      final angle = angles[p];
      final baseGlobalIdx = baseOffsets[p];

      Offset rotate(Offset pt) => center +
          Offset(
            pt.dx * math.cos(angle) - pt.dy * math.sin(angle),
            pt.dx * math.sin(angle) + pt.dy * math.cos(angle),
          );

      // Track holes (19 × 4 = 76 unique holes, 0 duplicate, perfectly fills both corners)
      for (int i = 0; i < quarterTemplate.length; i++) {
        final globalIdx = (baseGlobalIdx + i) % 76;
        _trackCoords[globalIdx] = rotate(quarterTemplate[i]);
      }

      // Safe Zone Runway (4 holes in centerline pointing toward center well: 4 × 4 = 16 holes)
      // Total holes on board surface: 76 + 16 = 92 holes exactly!
      for (int s = 0; s < 4; s++) {
        final sY = tipY - colStep * (s + 1);
        _safeCoords['p${p}_s$s'] = rotate(Offset(0, sY));
      }

      // 4 Corner Home Dishes ("البيت")
      const dishAngles = [
        3 * math.pi / 4,
        math.pi / 4,
        7 * math.pi / 4,
        5 * math.pi / 4,
      ];
      final dishAngle = dishAngles[p];
      const dishDist = 332.0;
      final dishCenter =
          center + Offset(math.cos(dishAngle) * dishDist, math.sin(dishAngle) * dishDist);

      const hGap = 17.5;
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

  void _drawAllHoles(Canvas canvas) {
    const holeRadius = 12.0;

    const dishAngles = [
      3 * math.pi / 4,
      math.pi / 4,
      7 * math.pi / 4,
      5 * math.pi / 4,
    ];
    for (int p = 0; p < 4; p++) {
      final angle = dishAngles[p];
      final dishCenter =
          const Offset(500, 500) + Offset(math.cos(angle) * 332, math.sin(angle) * 332);

      final dishShadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(dishCenter, 54, dishShadow);

      final dishPaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF47515C), Color(0xFF38404A), Color(0xFF282E35)],
          stops: [0.0, 0.70, 1.0],
        ).createShader(Rect.fromCircle(center: dishCenter, radius: 54));
      canvas.drawCircle(dishCenter, 54, dishPaint);

      final dishRim = Paint()
        ..color = const Color(0xFFC0CAD5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawCircle(dishCenter, 54, dishRim);
    }

    _homeCoords.forEach((key, pos) {
      _drawCarvedWoodHole(canvas, pos, holeRadius * 0.95);
    });

    _safeCoords.forEach((key, pos) {
      _drawCarvedWoodHole(canvas, pos, holeRadius);
    });

    _trackCoords.forEach((idx, pos) {
      final isSpawn = (idx == 0 || idx == 19 || idx == 38 || idx == 57);
      _drawCarvedWoodHole(canvas, pos, holeRadius, isSpawnPoint: isSpawn);
    });
  }

  void _drawCarvedWoodHole(
    Canvas canvas,
    Offset pos,
    double radius, {
    bool isSpawnPoint = false,
  }) {
    final woodBasePaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        colors: [
          Color(0xFFF0E3CA),
          Color(0xFFE2CDA6),
          Color(0xFFCEB68B),
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: pos, radius: radius));
    canvas.drawCircle(pos, radius, woodBasePaint);

    final innerShadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.45, -0.45),
        colors: [
          Colors.black.withValues(alpha: 0.62),
          Colors.black.withValues(alpha: 0.28),
          Colors.transparent,
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(Rect.fromCircle(center: pos, radius: radius));
    canvas.drawCircle(pos, radius, innerShadowPaint);

    final holeBorder = Paint()
      ..color = const Color(0xFF262B32).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(pos, radius, holeBorder);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawArc(
      Rect.fromCircle(center: pos, radius: radius - 0.5),
      0.15 * math.pi,
      0.70 * math.pi,
      false,
      highlightPaint,
    );

    if (isSpawnPoint) {
      final spawnAura = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(pos, radius + 2.0, spawnAura);
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
      final previewPaint = Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8;
      canvas.drawCircle(targetPos, 16.5, previewPaint);

      final startPos = _getMarblePixelPosition(selectedMarble!);
      if (startPos != null) {
        final path = Path();
        path.moveTo(startPos.dx, startPos.dy);
        final mid = (startPos + targetPos) / 2 + const Offset(0, -26);
        path.quadraticBezierTo(mid.dx, mid.dy, targetPos.dx, targetPos.dy);

        final linePaint = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2;
        canvas.drawPath(path, linePaint);
      }
    }
  }

  void _drawGlassMarbles(Canvas canvas) {
    const marbleRadius = 13.5;

    for (final marble in marbles) {
      final pos = _getMarblePixelPosition(marble);
      if (pos == null) continue;

      final isSelected = selectedMarble?.id == marble.id;

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.58)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.2);
      canvas.drawCircle(pos + const Offset(2.2, 3.2), marbleRadius, shadowPaint);

      final marblePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: [
            marble.secondaryColor,
            marble.primaryColor,
            marble.primaryColor.withValues(alpha: 0.85),
            Colors.black87,
          ],
          stops: const [0.0, 0.40, 0.80, 1.0],
        ).createShader(Rect.fromCircle(center: pos, radius: marbleRadius));
      canvas.drawCircle(pos, marbleRadius, marblePaint);

      final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.92);
      canvas.drawCircle(pos + const Offset(-4.5, -4.5), 3.2, glintPaint);

      final rimGlint = Paint()..color = Colors.white.withValues(alpha: 0.28);
      canvas.drawCircle(pos + const Offset(4.0, 4.0), 1.6, rimGlint);

      if (isSelected) {
        final selectBorder = Paint()
          ..color = const Color(0xFFFFD54F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8;
        canvas.drawCircle(pos, marbleRadius + 3.5, selectBorder);
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
  bool shouldRepaint(covariant _Jackaroo92ExactPainter oldDelegate) => true;
}
