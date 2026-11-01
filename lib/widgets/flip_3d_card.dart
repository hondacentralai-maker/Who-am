import 'dart:math';
import 'package:flutter/material.dart';
import '../services/game_audio_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';

/// بطاقة ثلاثية الأبعاد تفاعلية ذات وجهين قابلة للقلب بفيزياء المنظور (3D Double-Sided Flip Card)
/// مستوحاة من مشاريع بطاقات اللعب ثلاثية الأبعاد التفاعلية في GitHub
class Flip3DCard extends StatefulWidget {
  final Widget front;
  final Widget? back;
  final bool initialFlipped;
  final Duration duration;
  final VoidCallback? onFlipped;
  final BorderRadius? borderRadius;
  final double perspective;

  const Flip3DCard({
    super.key,
    required this.front,
    this.back,
    this.initialFlipped = false,
    this.duration = const Duration(milliseconds: 650),
    this.onFlipped,
    this.borderRadius,
    this.perspective = 0.0016,
  });

  @override
  State<Flip3DCard> createState() => _Flip3DCardState();
}

class _Flip3DCardState extends State<Flip3DCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _isFront = !widget.initialFlipped;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.initialFlipped ? 1.0 : 0.0,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    );
  }

  @override
  void didUpdateWidget(covariant Flip3DCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFlipped != oldWidget.initialFlipped) {
      if (widget.initialFlipped && _controller.value == 0.0) {
        _flip(toBack: true);
      } else if (!widget.initialFlipped && _controller.value == 1.0) {
        _flip(toBack: false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip({bool? toBack}) {
    PreferencesService.triggerHaptic(AppHapticType.medium);
    GameAudioService().playCardDeal();

    final target = toBack ?? !_isFront;
    if (target) {
      _controller.forward().then((_) {
        setState(() => _isFront = false);
        widget.onFlipped?.call();
      });
    } else {
      _controller.reverse().then((_) {
        setState(() => _isFront = true);
        widget.onFlipped?.call();
      });
    }
  }


  void _onHorizontalDragEnd(DragEndDetails details) {
    final delta = details.velocity.pixelsPerSecond.dx;
    if (delta.abs() > 250) {
      if (delta > 0 && !_isFront) {
        _flip(toBack: false);
      } else if (delta < 0 && _isFront) {
        _flip(toBack: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backWidget = widget.back ?? const FlipCardDefaultBack();

    return GestureDetector(
      onTap: () => _flip(),
      
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isUnderHalf = angle <= (pi / 2);

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, widget.perspective)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(24),
              child: isUnderHalf
                  ? widget.front
                  : Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: backWidget,
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// الواجهة الخلفية الافتراضية للبطاقة بهوية بناتي ناعمة ومترفة (Girly Decorative Card Back)
class FlipCardDefaultBack extends StatelessWidget {
  final String? label;
  final String? emoji;

  const FlipCardDefaultBack({
    super.key,
    this.label,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.pinkRoseGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35E94B8A),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // زخارف القلوب في الزوايا
          Positioned(
            top: 4,
            left: 4,
            child: Text('♡', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 24)),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Text('♡', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 24)),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Text('♡', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 24)),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Text('♡', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 24)),
          ),

          // دائرة الشعار المركزية المذهبة
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.22),
              border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.7), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji ?? '✨', style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  label ?? 'المسي للقلب 💖',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
