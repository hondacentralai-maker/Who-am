import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/jackaroo_board_layout.dart';
import '../services/game_audio_service.dart';

enum JackarooMarbleLocation { home, track, safeZone, finished }

class JackarooBoardMarble {
  final int id;
  final int ownerId;
  final int indexInOwner;
  final Color primaryColor;
  final Color secondaryColor;
  JackarooMarbleLocation location;
  int positionIndex;

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

/// Interactive overlay on the approved photograph. Printed geometry and numbers
/// are never repainted. All hit testing uses the same image-space coordinates.
class Jackaroo3DBoardView extends StatefulWidget {
  final String? activeCard;
  final String? lastPlayedCard;
  final ValueChanged<String>? onStatusMessage;
  final VoidCallback? onTurnFinished;
  final void Function(int team1Safe, int team2Safe)? onScoresUpdated;
  final ValueChanged<String>? onGameWon;
  final ValueChanged<bool>? onBusyChanged;
  final bool isTopDownView;

  const Jackaroo3DBoardView({
    super.key,
    this.activeCard,
    this.lastPlayedCard,
    this.onStatusMessage,
    this.onTurnFinished,
    this.onScoresUpdated,
    this.onGameWon,
    this.onBusyChanged,
    this.isTopDownView = true,
  });

  @override
  State<Jackaroo3DBoardView> createState() => Jackaroo3DBoardViewState();
}

class Jackaroo3DBoardViewState extends State<Jackaroo3DBoardView>
    with TickerProviderStateMixin {
  final GameAudioService _audio = GameAudioService();
  final _random = math.Random();
  late final AnimationController _cameraController;
  late final AnimationController _stepController;
  ui.Image? _reference;
  Object? _imageError;
  late List<JackarooBoardMarble> _marbles;
  JackarooBoardMarble? _selected;
  int? _movingId;
  Offset? _moveFrom;
  Offset? _moveTo;
  double _pitch = 0;
  double _pitchFrom = 0;
  double _pitchTo = 0;
  double _yaw = 0;
  bool _isTopDown = true;
  bool _busy = false;
  bool _gameWon = false;
  int _generation = 0;
  String? _centerCard;

  static const _botCards = [
    'A♠',
    'K♥',
    '2♣',
    '3♦',
    '4♣',
    '5♥',
    '6♠',
    '7♦',
    '8♣',
    '9♥',
    '10♦',
    'J♠',
    'Q♣',
  ];
  static const _colors = [
    Color(0xFF102EFF),
    Color(0xFF08DC20),
    Color(0xFF15191F),
    Color(0xFF8CE5FF),
  ];

  bool get isBusy => _busy;
  bool get isImageLoaded => _reference != null;
  List<JackarooBoardMarble> get marbles => List.unmodifiable(_marbles);
  Map<int, Offset> get trackCoordinates =>
      Map.unmodifiable(JackarooBoardLayout.track.asMap());
  Map<String, Offset> get homeCoordinates => Map.unmodifiable({
        for (var p = 0; p < 4; p++)
          for (var h = 0; h < 4; h++)
            'p${p}_h$h': JackarooBoardLayout.home[p][h],
      });
  Map<String, Offset> get safeZoneCoordinates => Map.unmodifiable({
        for (var p = 0; p < 4; p++)
          for (var s = 0; s < 4; s++)
            'p${p}_s$s': JackarooBoardLayout.safe[p][s],
      });

  @override
  void initState() {
    super.initState();
    _isTopDown = widget.isTopDownView;
    _pitch = _isTopDown ? 0 : 0.38;
    _centerCard = widget.lastPlayedCard;
    _initMarbles();
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(() {
        setState(() {
          _pitch = ui.lerpDouble(
            _pitchFrom,
            _pitchTo,
            Curves.easeOutCubic.transform(_cameraController.value),
          )!;
        });
      });
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addListener(() => setState(() {}));
    _loadReference();
  }

  Future<void> _loadReference() async {
    try {
      final data = await rootBundle.load(JackarooBoardLayout.asset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _reference = frame.image);
    } catch (error) {
      if (mounted) setState(() => _imageError = error);
    }
  }

  @override
  void didUpdateWidget(covariant Jackaroo3DBoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTopDownView != widget.isTopDownView) {
      setViewMode(widget.isTopDownView);
    }
    if (oldWidget.lastPlayedCard != widget.lastPlayedCard) {
      _centerCard = widget.lastPlayedCard;
    }
    if (oldWidget.activeCard != widget.activeCard && !_busy) _selected = null;
  }

  @override
  void dispose() {
    _generation++;
    _cameraController.dispose();
    _stepController.dispose();
    _reference?.dispose();
    super.dispose();
  }

  void _initMarbles() {
    _marbles = [
      for (var p = 0; p < 4; p++)
        for (var m = 0; m < 4; m++)
          JackarooBoardMarble(
            id: p * 4 + m,
            ownerId: p,
            indexInOwner: m,
            primaryColor: _colors[p],
            secondaryColor: _colors[p],
            positionIndex: m,
          ),
    ];
  }

  void resetGame() {
    _generation++;
    _stepController.stop(canceled: true);
    setState(() {
      _initMarbles();
      _selected = null;
      _movingId = null;
      _centerCard = null;
      _gameWon = false;
      _busy = false;
    });
    widget.onBusyChanged?.call(false);
    _notifyScores();
    _status('جولة جديدة! اختر ورقة ثم المس إحدى كراتك الزرقاء.');
  }

  void toggleViewMode() => setViewMode(!_isTopDown);
  void resetCamera() {
    _yaw = 0;
    setViewMode(_isTopDown);
  }

  void setViewMode(bool topDown) {
    _isTopDown = topDown;
    _pitchFrom = _pitch;
    _pitchTo = topDown ? 0 : 0.38;
    _yaw = 0;
    _cameraController.forward(from: 0);
  }

  void _status(String text) => widget.onStatusMessage?.call(text);
  bool _alive(int generation) => mounted && generation == _generation;
  bool _finished(int owner) =>
      _marbles.where((m) => m.ownerId == owner && m.isInSafeZone).length == 4;
  int _controlledOwner(int owner) => _finished(owner) ? (owner + 2) % 4 : owner;
  bool _protected(JackarooBoardMarble m) =>
      m.isOnTrack &&
      m.positionIndex == JackarooBoardLayout.spawnSlots[m.ownerId];

  int _steps(String card) {
    final rank = card.substring(0, card.length - 1);
    return switch (rank) {
      'A' => 1,
      'K' => 13,
      'Q' => 12,
      'J' => 0,
      '4' => -4,
      _ => int.tryParse(rank) ?? 1,
    };
  }

  List<JackarooPathStep>? _path(JackarooBoardMarble m, String card) {
    if (card.startsWith('J')) return null;
    List<JackarooPathStep>? path;
    if (m.isHome) {
      if (!card.startsWith('A') && !card.startsWith('K')) return null;
      path = [JackarooPathStep(JackarooBoardLayout.spawnSlots[m.ownerId])];
    } else {
      path = JackarooBoardLayout.route(
        owner: m.ownerId,
        position: m.positionIndex,
        steps: _steps(card),
        inSafe: m.isInSafeZone,
      );
    }
    if (path == null) return null;
    for (final point in path) {
      for (final other in _marbles) {
        if (other.id == m.id) continue;
        if (point.inSafe) {
          if (other.ownerId == m.ownerId &&
              other.isInSafeZone &&
              other.positionIndex == point.index) {
            return null;
          }
        } else if (other.isOnTrack &&
            other.positionIndex == point.index &&
            (other.ownerId == m.ownerId || _protected(other))) {
          return null;
        }
      }
    }
    return path;
  }

  List<JackarooBoardMarble> _swapTargets(JackarooBoardMarble m) => _marbles
      .where(
        (o) =>
            o.isOnTrack &&
            o.ownerId % 2 != m.ownerId % 2 &&
            !_protected(o) &&
            !_protected(m),
      )
      .toList();

  bool _playable(JackarooBoardMarble m, String card) => card.startsWith('J')
      ? m.isOnTrack && _swapTargets(m).isNotEmpty
      : _path(m, card) != null;

  bool get hasLegalMove {
    final owner = _controlledOwner(0);
    return _marbles.any(
      (m) => m.ownerId == owner && _playable(m, widget.activeCard ?? 'A♠'),
    );
  }

  void passTurn() {
    if (_busy || _gameWon) return;
    if (hasLegalMove) {
      _status('توجد حركة متاحة بهذه الورقة. المس الكرة التي تريد تحريكها.');
      return;
    }
    _busy = true;
    widget.onBusyChanged?.call(true);
    _selected = null;
    widget.onTurnFinished?.call();
    unawaited(_playBots(_generation));
  }

  Offset _position(JackarooBoardMarble m) {
    if (m.isHome) return JackarooBoardLayout.home[m.ownerId][m.indexInOwner];
    if (m.isInSafeZone) {
      return JackarooBoardLayout.safe[m.ownerId][m.positionIndex];
    }
    return JackarooBoardLayout.track[m.positionIndex];
  }

  void _onBoardTap(Offset point, double scale) {
    if (_busy || _gameWon || _reference == null) return;
    final card = widget.activeCard ?? 'A♠';
    final targets = _selected != null && card.startsWith('J')
        ? [..._swapTargets(_selected!), _selected!]
        : _marbles.where((m) => m.ownerId == _controlledOwner(0)).toList();
    targets.sort(
      (a, b) => (_position(a) - point).distanceSquared.compareTo(
            (_position(b) - point).distanceSquared,
          ),
    );
    if (targets.isEmpty ||
        (_position(targets.first) - point).distance * scale > 28) {
      return;
    }
    final m = targets.first;
    if (_selected != null && card.startsWith('J') && m.id != _selected!.id) {
      final selected = _selected!;
      _busy = true;
      widget.onBusyChanged?.call(true);
      unawaited(_playPlayerSwap(selected, m, card));
      return;
    }
    if (!_playable(m, card)) {
      _status('هذه الكرة لا تملك حركة متاحة بالورقة المختارة. جرّب ورقة أخرى.');
      return;
    }
    if (card.startsWith('J')) {
      setState(() => _selected = m);
      _status('اختر كرة منافس على المسار لتبديلها؛ نقاط البداية محمية.');
      return;
    }
    _busy = true;
    widget.onBusyChanged?.call(true);
    unawaited(_playPlayerMove(m, card));
  }

  Future<bool> _animateTo(
    JackarooBoardMarble m,
    Offset target,
    int generation,
  ) async {
    if (!_alive(generation)) return false;
    _moveFrom = _position(m);
    _moveTo = target;
    _movingId = m.id;
    try {
      await _stepController.forward(from: 0).orCancel;
    } on TickerCanceled {
      return false;
    }
    return _alive(generation);
  }

  Future<bool> _move(JackarooBoardMarble m, String card, int generation) async {
    final path = _path(m, card);
    if (path == null) return false;
    for (final point in path) {
      if (!await _animateTo(m, point.pointFor(m.ownerId), generation)) {
        return false;
      }
      setState(() {
        m.location = point.inSafe
            ? JackarooMarbleLocation.safeZone
            : JackarooMarbleLocation.track;
        m.positionIndex = point.index;
        _movingId = null;
      });
    }
    // Capture only at the final destination. Own pieces and protected starts
    // have already been rejected by _path, before animation begins.
    if (m.isOnTrack) {
      for (final other in _marbles) {
        if (other.id != m.id &&
            other.isOnTrack &&
            other.positionIndex == m.positionIndex) {
          other.location = JackarooMarbleLocation.home;
          other.positionIndex = other.indexInOwner;
          unawaited(_audio.playMarbleEat());
        }
      }
    }
    _centerCard = card;
    unawaited(_audio.playMarbleStep());
    _notifyScores();
    _checkVictory();
    return true;
  }

  Future<bool> _swap(
    JackarooBoardMarble a,
    JackarooBoardMarble b,
    String card,
    int generation,
  ) async {
    if (!_swapTargets(a).contains(b)) return false;
    if (!await _animateTo(a, _position(b), generation)) return false;
    setState(() {
      final previous = a.positionIndex;
      a.positionIndex = b.positionIndex;
      b.positionIndex = previous;
      _movingId = null;
      _selected = null;
      _centerCard = card;
    });
    unawaited(_audio.playCardPlace());
    return true;
  }

  Future<void> _playPlayerMove(JackarooBoardMarble m, String card) async {
    final generation = _generation;
    if (!await _move(m, card, generation) || !_alive(generation)) return;
    widget.onTurnFinished?.call();
    await _playBots(generation);
  }

  Future<void> _playPlayerSwap(
    JackarooBoardMarble a,
    JackarooBoardMarble b,
    String card,
  ) async {
    final generation = _generation;
    if (!await _swap(a, b, card, generation) || !_alive(generation)) return;
    widget.onTurnFinished?.call();
    await _playBots(generation);
  }

  Future<void> _playBots(int generation) async {
    for (final owner in [3, 2, 1]) {
      if (!_alive(generation) || _gameWon) break;
      _status('دور ${JackarooBoardLayout.playerNames[owner]}…');
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!_alive(generation)) return;
      final card = _botCards[_random.nextInt(_botCards.length)];
      final candidates = _marbles
          .where(
            (m) => m.ownerId == _controlledOwner(owner) && _playable(m, card),
          )
          .toList();
      if (candidates.isNotEmpty) {
        final m = candidates[_random.nextInt(candidates.length)];
        if (card.startsWith('J')) {
          final targets = _swapTargets(m);
          await _swap(
            m,
            targets[_random.nextInt(targets.length)],
            card,
            generation,
          );
        } else {
          await _move(m, card, generation);
        }
      }
    }
    if (!_alive(generation)) return;
    setState(() {
      _busy = false;
      _selected = null;
      _movingId = null;
    });
    widget.onBusyChanged?.call(false);
    if (!_gameWon) _status('دورك! اختر ورقة ثم المس كرة زرقاء.');
  }

  void _notifyScores() {
    int score(int team) =>
        _marbles.where((m) => m.ownerId % 2 == team && m.isInSafeZone).length;
    widget.onScoresUpdated?.call(score(0), score(1));
  }

  void _checkVictory() {
    if (_gameWon) return;
    for (var team = 0; team < 2; team++) {
      if (_marbles
              .where((m) => m.ownerId % 2 == team && m.isInSafeZone)
              .length ==
          8) {
        _gameWon = true;
        widget.onGameWon?.call(
          team == 0 ? 'فاز فريق الأزرق والأسود!' : 'فاز فريق الأخضر والسماوي!',
        );
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageError != null) {
      return const Center(
        child: Text(
          'تعذّر تحميل صورة اللوحة',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rect = JackarooBoardLayout.fittedRect(constraints.biggest);
          final scale = rect.width / JackarooBoardLayout.referenceSize.width;
          final animatedPoint = _movingId == null
              ? null
              : Offset.lerp(
                  _moveFrom,
                  _moveTo,
                  Curves.easeInOut.transform(_stepController.value),
                );
          return Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(_pitch)
                ..rotateZ(_yaw),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    _onBoardTap(details.localPosition / scale, scale),
                onPanUpdate: _isTopDown
                    ? null
                    : (details) => setState(() {
                          _yaw += details.delta.dx * 0.004;
                        }),
                child: Semantics(
                  label:
                      'لوحة جاكارو: أربعة أجزاء، كل جزء من 1 إلى 18، و16 كرة',
                  child: SizedBox(
                    key: const ValueKey('jackaroo-reference-surface'),
                    width: rect.width,
                    height: rect.height,
                    child: _reference == null
                        ? const Center(child: CircularProgressIndicator())
                        : RepaintBoundary(
                            key: const ValueKey('jackaroo-reference-paint'),
                            child: CustomPaint(
                              painter: _ReferenceBoardPainter(
                                reference: _reference!,
                                marbles: _marbles,
                                selectedId: _selected?.id,
                                movingId: _movingId,
                                animatedPoint: animatedPoint,
                                centerCard: _centerCard,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReferenceBoardPainter extends CustomPainter {
  final ui.Image reference;
  final List<JackarooBoardMarble> marbles;
  final int? selectedId;
  final int? movingId;
  final Offset? animatedPoint;
  final String? centerCard;

  _ReferenceBoardPainter({
    required this.reference,
    required this.marbles,
    this.selectedId,
    this.movingId,
    this.animatedPoint,
    this.centerCard,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / JackarooBoardLayout.referenceSize.width);
    // Bilinear sampling is exact at native resolution; bicubic filtering would
    // alter the photographed text edges even with a one-to-one image mapping.
    canvas.drawImage(
        reference, Offset.zero, Paint()..filterQuality = FilterQuality.low);

    for (var owner = 0; owner < 4; owner++) {
      final pieces = marbles.where((m) => m.ownerId == owner);
      final dishChanged = pieces.any((m) => !m.isHome || m.id == movingId);
      if (!dishChanged) continue;
      // Leave the photographed rim intact. Only the newly exposed, previously
      // occluded interior is rendered; original printed holes remain untouched.
      final dish = JackarooBoardLayout.dishes[owner];
      final radius = JackarooBoardLayout.dishRadii[owner];
      canvas.drawCircle(
        dish,
        radius,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.25, -0.3),
            colors: [Color(0xFF849DB4), Color(0xFF657F98), Color(0xFF334A60)],
          ).createShader(Rect.fromCircle(center: dish, radius: radius)),
      );
      for (final m in pieces.where((m) => m.isHome && m.id != movingId)) {
        _drawMarble(canvas, m, JackarooBoardLayout.home[owner][m.indexInOwner]);
      }
    }
    for (final m in marbles) {
      if (m.id == movingId && animatedPoint != null) {
        _drawMarble(canvas, m, animatedPoint!);
      } else if (m.isOnTrack) {
        _drawMarble(canvas, m, JackarooBoardLayout.track[m.positionIndex]);
      } else if (m.isInSafeZone) {
        _drawMarble(
          canvas,
          m,
          JackarooBoardLayout.safe[m.ownerId][m.positionIndex],
        );
      }
      if (m.id == selectedId) {
        final point = m.isOnTrack
            ? JackarooBoardLayout.track[m.positionIndex]
            : JackarooBoardLayout.home[m.ownerId][m.indexInOwner];
        canvas.drawCircle(
          point,
          27,
          Paint()
            ..color = const Color(0xFFFFD54F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }
    if (centerCard != null) _drawCard(canvas, centerCard!);
    canvas.restore();
  }

  void _drawMarble(Canvas canvas, JackarooBoardMarble m, Offset point) {
    final radius = JackarooBoardLayout.marbleRadii[m.ownerId];
    final source = JackarooBoardLayout.home[m.ownerId][m.indexInOwner];
    final rect = Rect.fromCircle(center: point, radius: radius);
    canvas.drawCircle(
      point + const Offset(1, 4),
      radius,
      Paint()
        ..color = Colors.black54
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawImageRect(
      reference,
      Rect.fromCircle(center: source, radius: radius),
      rect,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  void _drawCard(Canvas canvas, String card) {
    const center = Offset(623, 600);
    final rect = Rect.fromCenter(center: center, width: 80, height: 112);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(2, 4)),
        const Radius.circular(7),
      ),
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(7)),
      Paint()..color = const Color(0xFFFFFEFA),
    );
    final painter = TextPainter(
      text: TextSpan(
        text: card,
        style: TextStyle(
          color: card.contains('♥') || card.contains('♦')
              ? Colors.red.shade800
              : Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _ReferenceBoardPainter oldDelegate) => true;
}
