import 'dart:math';
import 'package:flutter/material.dart';
import '../services/game_audio_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';

/// نافذة رمي العملة الذهبية ثلاثية الأبعاد (Interactive 3D Coin Flipper)
/// مستوحاة من أفضل مشاريع 3D Physics & Coin Toss على GitHub
/// تدعم حركة دوران واقعية في الفضاء ثلاثي الأبعاد، ارتداد على السطح،
/// سمك جانبي معدني (Milled Rim Edge)، وظلال عمق ديناميكية.
class Coin3DDialog extends StatefulWidget {
  final ValueChanged<bool>? onResult; // true = ملك (Heads), false = كتابة (Tails)

  const Coin3DDialog({super.key, this.onResult});

  static Future<bool?> show(BuildContext context, {ValueChanged<bool>? onResult}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Coin3DDialog(onResult: onResult),
    );
  }

  @override
  State<Coin3DDialog> createState() => _Coin3DDialogState();
}

class _Coin3DDialogState extends State<Coin3DDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  final Random _random = Random();
  bool _isHeads = true; // true = ملك, false = كتابة
  bool _isFlipping = false;
  String? _chosenSide; // 'heads' أو 'tails' للتخمين قبل الرمي

  double _angle = 0.0;
  double _altitude = 0.0;

  @override
  void initState() {
    super.initState();
    _isHeads = _random.nextBool();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeOutCubic,
    );

    _flipController.addListener(_onFlipTick);
    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isFlipping = false;
        });
        GameAudioService().playSuccess();
        PreferencesService.triggerHaptic(AppHapticType.heavy);
        widget.onResult?.call(_isHeads);
      }
    });

    // رمية فورية ترحيبية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flipCoin();
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  int _lastTickStep = -1;

  void _onFlipTick() {
    final t = _flipAnimation.value;
    const totalRotations = 5; // 5 لفات كاملة في الهواء
    final targetEnd = _isHeads ? 0.0 : pi;

    setState(() {
      _angle = t * totalRotations * 2 * pi + targetEnd;
      // ارتفاع القفزة في الهواء (منحنى جيبي واقعي)
      _altitude = sin(t * pi) * 90.0;
    });

    final currentStep = (t * 16).floor();
    if (currentStep != _lastTickStep && _isFlipping) {
      _lastTickStep = currentStep;
      GameAudioService().playTick();
      PreferencesService.triggerHaptic(AppHapticType.light);
    }
  }

  void _flipCoin() {
    if (_isFlipping) return;

    PreferencesService.triggerHaptic(AppHapticType.medium);
    GameAudioService().playTap();

    setState(() {
      _isFlipping = true;
      _isHeads = _random.nextBool();
    });

    _flipController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // تحديد الوجه الظاهر حالياً بناءً على الزاوية
    final normalizedAngle = _angle % (2 * pi);
    final isFrontVisible = normalizedAngle < (pi / 2) || normalizedAngle > (3 * pi / 2);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x35E94B8A),
              blurRadius: 36,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('🪙', style: TextStyle(fontSize: 26)),
                    SizedBox(width: 8),
                    Text(
                      'قرعة العملة 3D',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.deepPurple,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, _isHeads),
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'حسم الخلافات والقرارات بقرعة معدنية ثلاثية الأبعاد ⚖️',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 18),

            // Guessing Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChoiceChip(label: '👑 مَلِك', value: 'heads'),
                const SizedBox(width: 12),
                _buildChoiceChip(label: '📜 كِتَابَة', value: 'tails'),
              ],
            ),
            const SizedBox(height: 24),

            // 3D Coin Toss Area
            SizedBox(
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ground Dynamic Shadow
                  Transform.translate(
                    offset: const Offset(0, 55),
                    child: Container(
                      width: max(40.0, 130.0 - (_altitude * 0.7)),
                      height: max(16.0, 36.0 - (_altitude * 0.2)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: (0.35 - (_altitude * 0.002)).clamp(0.08, 0.45),
                            ),
                            blurRadius: 16.0 + (_altitude * 0.2),
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // The 3D Flipping Coin
                  Transform.translate(
                    offset: Offset(0, -_altitude),
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0016)
                        ..rotateX(_angle)
                        ..rotateY(sin(_angle) * 0.2), // إمالة خفيفة ثلاثية الأبعاد
                      alignment: FractionalOffset.center,
                      child: GestureDetector(
                        onTap: _flipCoin,
                        child: _buildCoinFace(isFront: isFrontVisible),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Result Badge
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isFlipping ? 0.3 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                decoration: BoxDecoration(
                  gradient: _isHeads
                      ? const LinearGradient(
                          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
                        ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isHeads ? const Color(0xFFFFD54F) : const Color(0xFFB39DDB),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _isFlipping
                    ? 'العملة تدور في الهواء... 🪙'
                    : _chosenSide != null
                        ? ((_chosenSide == 'heads' && _isHeads) || (_chosenSide == 'tails' && !_isHeads)
                            ? 'مبروك! كسبتِ التخمين (${_isHeads ? "مَلِك 👑" : "كِتَابَة 📜"}) 🎉'
                            : 'حظ أوفر! النتيجة (${_isHeads ? "مَلِك 👑" : "كِتَابَة 📜"}) ✨')
                        : 'النتيجة: ${_isHeads ? "مَلِك 👑" : "كِتَابَة 📜"}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _isHeads ? const Color(0xFF8D6E63) : AppColors.deepPurple,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(context, _isHeads),
                    child: const Text('اعتماد النتيجة'),
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
                    onPressed: _isFlipping ? null : _flipCoin,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('رمية جديدة 🪙'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({required String label, required String value}) {
    final isSelected = _chosenSide == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _isFlipping
          ? null
          : () {
              PreferencesService.triggerHaptic(AppHapticType.selection);
              setState(() {
                _chosenSide = isSelected ? null : value;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple : AppColors.palePurple,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.deepPurple : AppColors.cardBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : AppColors.deepPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildCoinFace({required bool isFront}) {
    final title = isFront ? 'مَلِك' : 'كِتَابَة';
    final icon = isFront ? Icons.workspace_premium_rounded : Icons.menu_book_rounded;

    return Container(
      width: 124,
      height: 124,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.25, -0.3),
          radius: 0.85,
          colors: [
            Color(0xFFFFF9C4), // لمعة ذهبية فاتحة
            Color(0xFFFFD54F), // ذهبي نقي
            Color(0xFFFFB300), // ذهبي دافئ
            Color(0xFFFFA000), // برونز ذهبي
            Color(0xFFFF8F00), // حافة ذهبية عميقة
          ],
          stops: [0.0, 0.45, 0.72, 0.90, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFFFFECB3),
          width: 4.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55FFA000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 102,
          height: 102,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFA000).withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFF5D4037),
                size: 34,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4E342E),
                  fontFamily: 'Cairo',
                  shadows: [
                    Shadow(
                      color: Color(0x88FFFFFF),
                      offset: Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
