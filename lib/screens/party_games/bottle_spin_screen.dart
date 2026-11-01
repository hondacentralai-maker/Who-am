import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/party_game_models.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/interactive_3d_card.dart';

/// شاشة لعبة لف الزجاجة ثلاثية الأبعاد (Interactive 3D Spin The Bottle)
/// مستوحاة من محاكاة فيزياء الدوران ثلاثية الأبعاد على GitHub
/// تدعم حركة عطالة دورانية واقعية، انعكاسات زجاجية ولمعان، وتحديد تلقائي للاعبة المستهدفة.
class BottleSpinScreen extends StatefulWidget {
  final List<String>? initialPlayers;

  const BottleSpinScreen({super.key, this.initialPlayers});

  @override
  State<BottleSpinScreen> createState() => _BottleSpinScreenState();
}

class _BottleSpinScreenState extends State<BottleSpinScreen>
    with SingleTickerProviderStateMixin {
  late List<String> _players;
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  final Random _random = Random();
  double _currentAngle = 0.0;
  double _startAngle = 0.0;
  double _targetAngle = 0.0;
  bool _isSpinning = false;
  int _selectedPlayerIndex = -1;
  String? _currentChallenge;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlayers != null && widget.initialPlayers!.isNotEmpty) {
      _players = List.from(widget.initialPlayers!);
    } else {
      final profile = PreferencesService.getCouplesProfile();
      _players = [profile.partner1Name, profile.partner2Name, 'شهد', 'ريم'];
    }

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    );

    _spinController.addListener(_onSpinTick);
    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSpinFinished();
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  int _lastTickSector = -1;

  void _onSpinTick() {
    final t = _spinAnimation.value;
    final angle = _startAngle + (_targetAngle - _startAngle) * t;

    setState(() {
      _currentAngle = angle;
    });

    if (_players.isNotEmpty) {
      final normalized = (_currentAngle % (2 * pi));
      final sector = (normalized / (2 * pi / _players.length)).floor();
      if (sector != _lastTickSector && _isSpinning) {
        _lastTickSector = sector;
        GameAudioService().playTick();
        PreferencesService.triggerHaptic(AppHapticType.light);
      }
    }
  }

  void _spinBottle() {
    if (_isSpinning || _players.isEmpty) return;

    PreferencesService.setLastPlayedGame(title: 'لف الزجاجة 3D 🍾', route: 'bottle_spin');
    PreferencesService.triggerHaptic(AppHapticType.medium);
    GameAudioService().playTap();

    _startAngle = _currentAngle % (2 * pi);
    // دوران عشوائي بين 4 إلى 8 دورات كاملة + زاوية استقرار
    final extraRotations = 4 + _random.nextInt(4);
    final randomStopAngle = _random.nextDouble() * 2 * pi;
    _targetAngle = _startAngle + (extraRotations * 2 * pi) + randomStopAngle;

    setState(() {
      _isSpinning = true;
      _selectedPlayerIndex = -1;
      _currentChallenge = null;
    });

    _spinController.forward(from: 0.0);
  }

  void _onSpinFinished() async {
    setState(() {
      _isSpinning = false;
      _currentAngle = _targetAngle % (2 * pi);
      _selectedPlayerIndex = _calculateTargetPlayerIndex(_currentAngle);
    });

    GameAudioService().playWin();
    PreferencesService.triggerHaptic(AppHapticType.heavy);
    await PreferencesService.recordPartyGameFinished(pointsEarned: 10);

    if (mounted) {
      CelebrationOverlay.show(context);
      _showResultBottomSheet();
    }
  }

  int _calculateTargetPlayerIndex(double angle) {
    if (_players.isEmpty) return 0;
    // زاوية مقدمة الزجاجة (رأس الزجاجة موجه للأعلى عند الزاوية 0)
    // حساب أقرب لاعبة لمقدمة الزجاجة
    final step = (2 * pi) / _players.length;
    final pointerAngle = (angle - (pi / 2)) % (2 * pi);
    final normalized = (pointerAngle < 0 ? pointerAngle + 2 * pi : pointerAngle);
    final index = ((normalized + (step / 2)) / step).floor() % _players.length;
    return index;
  }

  void _showResultBottomSheet() {
    final targetName = _players[_selectedPlayerIndex];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: const [
              BoxShadow(color: Color(0x30E94B8A), blurRadius: 30, offset: Offset(0, -6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              const Text('🍾 اختارت الزجاجة:', style: TextStyle(fontSize: 14, color: AppColors.muted)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  targetName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'ماذا ستختارين يا $targetName؟',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepPurple),
              ),
              const SizedBox(height: 18),

              if (_currentChallenge != null) ...[
                Interactive3DCard(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.palePurple,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      _currentChallenge!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        PreferencesService.triggerHaptic(AppHapticType.selection);
                        GameAudioService().playCardPlace();
                        final prompt = MostLikelyToPrompt.defaultPrompts()..shuffle();
                        setModalState(() {
                          _currentChallenge = 'سؤال صراحة 💬:\n${prompt.first.question}';
                        });
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('سؤال صراحة'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        PreferencesService.triggerHaptic(AppHapticType.medium);
                        GameAudioService().playCardDeal();
                        final dare = BesarahaWal3aCard.defaultCards()
                            .where((c) => c.type == BesarahaWal3aType.dare)
                            .toList()..shuffle();
                        final dareText = dare.isNotEmpty ? dare.first.content : 'تحدي: قلد صوت قطة أو ارقص لمدة 10 ثواني!';
                        setModalState(() {
                          _currentChallenge = 'حكم وتحدي جريء 🔥:\n$dareText';
                        });
                      },
                      icon: const Icon(Icons.flash_on_rounded),
                      label: const Text('حكم وتحدي 🔥'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _spinBottle();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('لِف الزجاجة مرة ثانية 🍾'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPlayerDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة لاعبة للجلسة 👧'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'اسم اللاعبة',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _players.add(name);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لف الزجاجة 3D 🍾'),
        actions: [
          IconButton(
            tooltip: 'إضافة متسابقة',
            icon: const Icon(Icons.person_add_rounded),
            onPressed: _showAddPlayerDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppColors.palePurple.withValues(alpha: 0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'اللاعبات حول الطاولة (${_players.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.deepPurple,
                    ),
                  ),
                  Text(
                    _isSpinning
                        ? 'الزجاجة تدور بسرعة... 🌀'
                        : _selectedPlayerIndex >= 0
                            ? 'الدور على: ${_players[_selectedPlayerIndex]} 👑'
                            : 'المسي الزجاجة أو اضغطي "لِف الآن"',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _isSpinning ? AppColors.purple : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),

            // Main 3D Bottle Table Arena
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = min(constraints.maxWidth, constraints.maxHeight);
                  final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
                  final radius = (size / 2) * 0.78;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Table Surface Ring
                      Container(
                        width: size * 0.92,
                        height: size * 0.92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [
                              Colors.white,
                              Color(0xFFFFF0F5),
                              Color(0xFFFDE8E9),
                            ],
                          ),
                          border: Border.all(color: AppColors.cardBorder, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1CE94B8A),
                              blurRadius: 28,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                      ),

                      // Player Seats arranged in a circle
                      ...List.generate(_players.length, (i) {
                        final angle = (i * (2 * pi / _players.length)) - (pi / 2);
                        final x = center.dx + radius * cos(angle);
                        final y = center.dy + radius * sin(angle);
                        final isSelected = _selectedPlayerIndex == i;

                        return Positioned(
                          left: x - 42,
                          top: y - 24,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.purple : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.deepPurple : AppColors.cardBorder,
                                width: isSelected ? 2.5 : 1.2,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  const BoxShadow(
                                    color: Color(0x66E94B8A),
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isSelected ? '👑' : '👧',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _players[i],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      // The 3D Glass Bottle (Rotates with Physics)
                      GestureDetector(
                        onTap: _spinBottle,
                        onPanEnd: (_) => _spinBottle(),
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
                            ..rotateZ(_currentAngle),
                          alignment: FractionalOffset.center,
                          child: CustomPaint(
                            size: Size(size * 0.44, size * 0.44),
                            painter: _Bottle3DPainter(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Bottom Spin Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                  ),
                  onPressed: _isSpinning ? null : _spinBottle,
                  icon: const Icon(Icons.rotate_right_rounded, size: 28),
                  label: Text(
                    _isSpinning ? 'الزجاجة تدور في الفضاء... 🍾' : 'لِف الزجاجة الآن 🍾',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// رسام الزجاجة ثلاثية الأبعاد (3D Glass Bottle Custom Painter)
/// يرسم مجسم زجاجي بلوري مع عنق الزجاجة، الكتف، الجسم، وانعكاسات الإضاءة والظلال.
class _Bottle3DPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    // 1. ظل الزجاجة الساقط على الطاولة
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(6, 12), width: w * 0.32, height: h * 0.72),
      shadowPaint,
    );

    // 2. مسار جسم الزجاجة (Bottle Contour Path)
    final bottlePath = Path();
    final halfBody = w * 0.16;
    final halfNeck = w * 0.055;
    final top = center.dy - (h * 0.42);
    final bottom = center.dy + (h * 0.40);
    final shoulderY = center.dy - (h * 0.12);

    // البداية من غطاء الفوهة
    bottlePath.moveTo(center.dx - halfNeck, top);
    bottlePath.lineTo(center.dx + halfNeck, top);
    // عنق الزجاجة
    bottlePath.lineTo(center.dx + halfNeck, shoulderY);
    // كتف الزجاجة المنحني
    bottlePath.quadraticBezierTo(
      center.dx + halfBody,
      shoulderY + (h * 0.08),
      center.dx + halfBody,
      shoulderY + (h * 0.15),
    );
    // جسم الزجاجة الأسطواني
    bottlePath.lineTo(center.dx + halfBody, bottom - 10);
    // قاع الزجاجة المنحني
    bottlePath.quadraticBezierTo(
      center.dx + halfBody,
      bottom,
      center.dx,
      bottom,
    );
    bottlePath.quadraticBezierTo(
      center.dx - halfBody,
      bottom,
      center.dx - halfBody,
      bottom - 10,
    );
    // الجانب الآخر للجسم والكتف
    bottlePath.lineTo(center.dx - halfBody, shoulderY + (h * 0.15));
    bottlePath.quadraticBezierTo(
      center.dx - halfBody,
      shoulderY + (h * 0.08),
      center.dx - halfNeck,
      shoulderY,
    );
    bottlePath.close();

    // 3. تلوين الزجاج البلوري الوردي/الزمردي بتدرج ناعم
    final glassGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFFF06292).withValues(alpha: 0.85),
        const Color(0xFFE91E63).withValues(alpha: 0.90),
        const Color(0xFF880E4F).withValues(alpha: 0.95),
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    final glassPaint = Paint()
      ..shader = glassGradient.createShader(bottlePath.getBounds())
      ..style = PaintingStyle.fill;
    canvas.drawPath(bottlePath, glassPaint);

    // 4. لمعان زجاجي ثلاثي الأبعاد على طول الزجاجة (Specular Highlight Streak)
    final highlightPath = Path();
    highlightPath.moveTo(center.dx - (halfNeck * 0.65), top + 4);
    highlightPath.lineTo(center.dx - (halfNeck * 0.3), top + 4);
    highlightPath.lineTo(center.dx - (halfBody * 0.4), bottom - 14);
    highlightPath.lineTo(center.dx - (halfBody * 0.7), bottom - 14);
    highlightPath.close();

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.48)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(highlightPath, highlightPaint);

    // 5. غطاء الزجاجة الذهبي (Cork / Cap Stopper)
    final capRect = Rect.fromCenter(
      center: Offset(center.dx, top - 3),
      width: halfNeck * 2.3,
      height: 10,
    );
    final capPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFECB3), Color(0xFFFFD54F), Color(0xFFFFA000)],
      ).createShader(capRect);
    canvas.drawRRect(RRect.fromRectAndRadius(capRect, const Radius.circular(3)), capPaint);

    // 6. حلقة معدنية أسفل العنق
    final ringRect = Rect.fromCenter(
      center: Offset(center.dx, shoulderY - 2),
      width: halfNeck * 2.2,
      height: 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(ringRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
