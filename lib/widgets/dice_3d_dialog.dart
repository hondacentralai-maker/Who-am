import 'dart:math';
import 'package:flutter/material.dart';
import '../services/game_audio_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';

/// نافذة رمي النرد ثلاثي الأبعاد الواقعي (Interactive 3D Dice Roller)
/// مستوحاة من مشاريع فيزياء النرد ثلاثية الأبعاد على GitHub (RollHippo و 3D Rigid-Body Physics)
/// تدعم حركة دوران حرة في الفضاء ثلاثي الأبعاد، ارتداد على صينية اللعب، ونقاط محفورة واقعية.
class Dice3DDialog extends StatefulWidget {
  final ValueChanged<int>? onResult;

  const Dice3DDialog({super.key, this.onResult});

  static Future<int?> show(BuildContext context, {ValueChanged<int>? onResult}) {
    return showDialog<int>(
      context: context,
      builder: (ctx) => Dice3DDialog(onResult: onResult),
    );
  }

  @override
  State<Dice3DDialog> createState() => _Dice3DDialogState();
}

class _Dice3DDialogState extends State<Dice3DDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _rollController;
  late Animation<double> _rollAnimation;

  final Random _random = Random();
  int _targetValue = 6;
  bool _isRolling = false;

  // زوايا الدوران اللحظية
  double _rotX = 0.0;
  double _rotY = 0.0;
  double _rotZ = 0.0;
  double _bounceY = 0.0;

  @override
  void initState() {
    super.initState();
    _targetValue = 1 + _random.nextInt(6);

    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _rollAnimation = CurvedAnimation(
      parent: _rollController,
      curve: Curves.bounceOut,
    );

    _rollController.addListener(_onAnimationTick);
    _rollController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isRolling = false;
        });
        GameAudioService().playSuccess();
        PreferencesService.triggerHaptic(AppHapticType.heavy);
        widget.onResult?.call(_targetValue);
      }
    });

    // رمية تلقائية فور فتح النافذة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rollDice();
    });
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  int _lastTickStep = -1;

  void _onAnimationTick() {
    final t = _rollAnimation.value;
    final remaining = 1.0 - t;

    setState(() {
      _rotX = t * 6 * pi + (_targetValue * 0.4);
      _rotY = t * 8 * pi + (_targetValue * 0.6);
      _rotZ = t * 4 * pi;
      _bounceY = -sin(t * pi * 4).abs() * 45.0 * remaining;
    });

    final currentStep = (t * 12).floor();
    if (currentStep != _lastTickStep && _isRolling) {
      _lastTickStep = currentStep;
      GameAudioService().playTick();
      PreferencesService.triggerHaptic(AppHapticType.light);
    }
  }

  void _rollDice() {
    if (_isRolling) return;

    PreferencesService.triggerHaptic(AppHapticType.medium);
    GameAudioService().playTap();

    setState(() {
      _isRolling = true;
      _targetValue = 1 + _random.nextInt(6);
    });

    _rollController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
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
                    Text('🎲', style: TextStyle(fontSize: 26)),
                    SizedBox(width: 8),
                    Text(
                      'نرد القرارات 3D',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.deepPurple,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, _targetValue),
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'ارمِ النرد لحسم الأدوار، التحديات، أو عدد الرشفات!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // 3D Dice Felt Tray
            Container(
              width: 250,
              height: 220,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment(0, -0.2),
                  colors: [
                    Color(0xFFFFF0F5),
                    Color(0xFFFCE4EC),
                    Color(0xFFF8BBD0),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF48FB1), width: 3.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 14,
                    offset: Offset(0, 6),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Tray Inner Felt Shadow
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color(0xFFC2185B).withValues(alpha: 0.15),
                          width: 4,
                        ),
                      ),
                    ),
                  ),

                  // Shadow on Tray Surface
                  Transform.translate(
                    offset: Offset(0, 48 - _bounceY * 0.3),
                    child: Container(
                      width: 88,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: (0.35 - (_bounceY.abs() / 150)).clamp(0.08, 0.35),
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),

                  // 3D Animated Tumbling Dice Cube
                  Transform.translate(
                    offset: Offset(0, _bounceY),
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0016)
                        ..rotateX(_rotX)
                        ..rotateY(_rotY)
                        ..rotateZ(_rotZ),
                      alignment: FractionalOffset.center,
                      child: GestureDetector(
                        onTap: _rollDice,
                        child: _buildDiceFace(_isRolling ? (1 + (_rotX.abs().toInt() % 6)) : _targetValue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rolled Value Badge
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _isRolling ? 0.3 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.palePurple,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  _isRolling ? 'النرد يتدحرج... 🎲' : 'النتيجة: رقم $_targetValue! 🎉',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.deepPurple,
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
                    onPressed: () => Navigator.pop(context, _targetValue),
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
                    onPressed: _isRolling ? null : _rollDice,
                    icon: const Icon(Icons.casino_rounded),
                    label: const Text('رمي جديد 🎲'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an ivory luxury 3D dice face with engraved pips
  Widget _buildDiceFace(int value) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFFF9FA),
            Color(0xFFFCE4EC),
          ],
        ),
        border: Border.all(color: const Color(0xFFF48FB1), width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35E94B8A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: _buildPips(value),
      ),
    );
  }

  Widget _buildPips(int count) {
    final clamped = count.clamp(1, 6);

    Widget dot() => Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.3, -0.3),
              colors: [
                Color(0xFFF06292),
                Color(0xFFE91E63),
                Color(0xFF880E4F),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 3,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
        );

    switch (clamped) {
      case 1:
        return dot();
      case 2:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(alignment: Alignment.topRight, child: dot()),
              Align(alignment: Alignment.bottomLeft, child: dot()),
            ],
          ),
        );
      case 3:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(alignment: Alignment.topRight, child: dot()),
              dot(),
              Align(alignment: Alignment.bottomLeft, child: dot()),
            ],
          ),
        );
      case 4:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot(), dot()]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot(), dot()]),
            ],
          ),
        );
      case 5:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot(), dot()]),
              dot(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot(), dot()]),
            ],
          ),
        );
      case 6:
      default:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot(), dot()]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot(), dot()]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [dot(), dot()]),
            ],
          ),
        );
    }
  }
}
