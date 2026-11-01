import 'dart:math';
import 'package:flutter/material.dart';
import '../models/decision_wheel_item.dart';
import '../services/game_audio_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';

class DecisionWheelScreen extends StatefulWidget {
  const DecisionWheelScreen({super.key});

  @override
  State<DecisionWheelScreen> createState() => _DecisionWheelScreenState();
}

class _DecisionWheelScreenState extends State<DecisionWheelScreen>
    with SingleTickerProviderStateMixin {
  late List<DecisionWheelItem> _allItems;
  String _selectedCategory = 'عشاء الليلة؟ 🍕';
  late AnimationController _animCtrl;
  late Animation<double> _animation;
  double _currentAngle = 0.0;
  bool _isSpinning = false;
  final Random _random = Random();

  final List<String> _categories = [
    'عشاء الليلة؟ 🍕',
    'سهرة الليلة؟ 🎬',
    'تحدي الدلع 💆',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
  }

  void _loadItems() {
    final defaults = DecisionWheelItem.defaultItems();
    final custom = PreferencesService.getCustomWheelItems();
    _allItems = [...defaults, ...custom];
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  List<DecisionWheelItem> get _activeSectorItems {
    final filtered = _allItems.where((i) => i.category == _selectedCategory).toList();
    return filtered.isEmpty ? DecisionWheelItem.defaultItems().take(6).toList() : filtered;
  }

  void _spinWheel() {
    if (_isSpinning) return;
    PreferencesService.triggerHaptic(AppHapticType.medium);
    GameAudioService().playTap();

    final items = _activeSectorItems;
    final sectorCount = items.length;
    final sectorAngle = (2 * pi) / sectorCount;

    // Pick random target sector
    final targetIndex = _random.nextInt(sectorCount);
    // Align target sector under top pointer (at angle 3*pi/2 or 0)
    final extraSpins = (5 + _random.nextInt(4)) * 2 * pi;
    final targetSectorCenter = (targetIndex * sectorAngle) + (sectorAngle / 2);
    final finalAngle = _currentAngle + extraSpins + (2 * pi - targetSectorCenter);

    int lastSectorTick = -1;
    _animation = Tween<double>(
      begin: _currentAngle,
      end: finalAngle,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    ))..addListener(() {
        final currentSector = (_animation.value / sectorAngle).floor();
        if (currentSector != lastSectorTick) {
          lastSectorTick = currentSector;
          GameAudioService().playTick();
          PreferencesService.triggerHaptic(AppHapticType.selection);
        }
        setState(() {});
      });

    setState(() {
      _isSpinning = true;
    });

    _animCtrl.forward(from: 0).then((_) async {
      _currentAngle = finalAngle % (2 * pi);
      final winningSector = items[targetIndex];
      setState(() {
        _isSpinning = false;
      });
      PreferencesService.triggerHaptic(AppHapticType.heavy);
      GameAudioService().playWin();
      await PreferencesService.recordWheelSpin(pointsEarned: 10);
      if (mounted) {
        CelebrationOverlay.show(context);
      }
      _showWinnerDialog(winningSector);
    });
  }

  void _showWinnerDialog(DecisionWheelItem winner) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              winner.emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 12),
            const Text(
              'حسمت العجلة القرار! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.palePurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                winner.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'لا مجال للتراجع الآن، القرار محسوم وعليكما تنفيذه بحب! ❤️',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('موافقون تماماً!'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    final textCtrl = TextEditingController();
    final emojiCtrl = TextEditingController(text: '✨');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة خيار للعجلة 🎯'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم الخيار / النشاط',
                hintText: 'مثال: طلعة بحر، مساج، دونات...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emojiCtrl,
              decoration: const InputDecoration(
                labelText: 'الإيموجي',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final label = textCtrl.text.trim();
              if (label.isNotEmpty) {
                final newItem = DecisionWheelItem(
                  id: 'custom_wheel_${DateTime.now().millisecondsSinceEpoch}',
                  label: label,
                  category: _selectedCategory,
                  emoji: emojiCtrl.text.trim().isEmpty ? '✨' : emojiCtrl.text.trim(),
                  colorValue: 0xFF7047D7,
                );
                await PreferencesService.addCustomWheelItem(newItem);
                setState(() {
                  _allItems.add(newItem);
                });
                if (ctx.mounted) Navigator.pop(ctx);
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
    final items = _activeSectorItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عجلة القرارات اللطيفة 🎡'),
        actions: [
          IconButton(
            tooltip: 'إضافة خيار',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _showAddItemDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Category Switcher Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSel = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(
                          cat,
                          style: TextStyle(
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? Colors.white : AppColors.ink,
                          ),
                        ),
                        selected: isSel,
                        selectedColor: AppColors.purple,
                        onSelected: (val) {
                          if (val && !_isSpinning) {
                            setState(() => _selectedCategory = cat);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'محتارين في القرار؟ اتركوا الاختيار للعجلة الدوارة!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const Spacer(),

              // The Wheel Stack
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 36,
                        offset: const Offset(0, 22),
                      ),
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0013)
                      ..rotateX(0.24),
                    alignment: FractionalOffset.center,
                    child: SizedBox(
                      width: 320,
                      height: 320,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Spinning Wheel Canvas
                          Transform.rotate(
                            angle: _isSpinning ? _animation.value : _currentAngle,
                            child: CustomPaint(
                              size: const Size(310, 310),
                              painter: _WheelPainter(items: items),
                            ),
                          ),

                          // Top Pointer Indicator (Arrow pointing down at 12 o'clock)
                          Positioned(
                            top: -4,
                            child: Container(
                              decoration: const BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 52,
                                color: AppColors.accentGold,
                              ),
                            ),
                          ),

                          // Center Hub Button
                          GestureDetector(
                            onTap: _spinWheel,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  center: Alignment(-0.3, -0.3),
                                  colors: [
                                    Colors.white,
                                    Color(0xFFFFF8E1),
                                    Color(0xFFFFECB3),
                                  ],
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 12,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                                border: Border.all(
                                  color: AppColors.accentGold,
                                  width: 4.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _isSpinning ? '...' : 'تدوير! 🎡',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: AppColors.deepPurple,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Spin Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSpinning ? null : _spinWheel,
                  icon: const Icon(Icons.sync_rounded),
                  label: Text(_isSpinning ? 'جاري تدوير العجلة...' : 'دوّر العجلة الآن!'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<DecisionWheelItem> items;

  _WheelPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8.0;
    final sectorAngle = (2 * pi) / items.length;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 1. رسم قطاعات العجلة
    for (int i = 0; i < items.length; i++) {
      paint.color = Color(items[i].colorValue);
      final startAngle = i * sectorAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sectorAngle,
        true,
        paint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sectorAngle,
        true,
        borderPaint,
      );

      // رسم النص والأيقونة
      canvas.save();
      final textAngle = startAngle + (sectorAngle / 2);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(textAngle);

      final label = '${items[i].emoji} ${items[i].label}';
      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          fontFamily: 'Cairo',
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.rtl,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: radius * 0.62);

      textPainter.paint(
        canvas,
        Offset(radius * 0.26, -textPainter.height / 2),
      );

      canvas.restore();
    }

    // 2. إطار ذهبي ميتاليك ثلاثي الأبعاد (3D Metallic Gold Outer Rim)
    final goldRimPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFFD54F),
          Color(0xFFFFA000),
          Color(0xFFFFE082),
          Color(0xFFFFB300),
          Color(0xFFFFD54F),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius + 7))
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius + 3.5, goldRimPaint);

    final goldBevel = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius + 7.0, goldBevel);

    // 3. مسامير ذهبية ثلاثية الأبعاد عند كل حد فاصل (3D Golden Studs/Pegs)
    for (int i = 0; i < items.length; i++) {
      final pegAngle = i * sectorAngle;
      final pegPos = center + Offset(cos(pegAngle), sin(pegAngle)) * (radius + 3.5);

      final pegShadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(pegPos + const Offset(1, 1), 3.2, pegShadow);

      final pegPaint = Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFE65100)],
        ).createShader(Rect.fromCircle(center: pegPos, radius: 3.2));
      canvas.drawCircle(pegPos, 3.2, pegPaint);

      final pegGlint = Paint()..color = Colors.white;
      canvas.drawCircle(pegPos + const Offset(-1, -1), 0.9, pegGlint);
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => true;
}
