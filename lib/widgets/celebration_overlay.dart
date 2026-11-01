import 'dart:math';
import 'package:flutter/material.dart';

/// Lightweight custom celebration particle effect without external dependencies.
class CelebrationOverlay {
  static void show(BuildContext context) {
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _CelebrationParticleEffect(
        onFinished: () => entry.remove(),
      ),
    );

    overlayState.insert(entry);
  }
}

class _CelebrationParticleEffect extends StatefulWidget {
  final VoidCallback onFinished;

  const _CelebrationParticleEffect({required this.onFinished});

  @override
  State<_CelebrationParticleEffect> createState() => _CelebrationParticleEffectState();
}

class _CelebrationParticleEffectState extends State<_CelebrationParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    final colors = [
      const Color(0xFFE94B8A), // Pastel Pink
      const Color(0xFFBA68C8), // Soft Lavender
      const Color(0xFFFFD54F), // Metallic Gold
      const Color(0xFFF06292), // Baby Pink
      const Color(0xFF4DD0E1), // Soft Cyan
      const Color(0xFFFF80AB), // Rose Glaze
      const Color(0xFFFFF176), // Star Yellow
    ];

    for (int i = 0; i < 50; i++) {
      _particles.add(
        _Particle(
          x: _rnd.nextDouble(),
          startY: -0.1 - (_rnd.nextDouble() * 0.35),
          color: colors[_rnd.nextInt(colors.length)],
          size: 7.0 + _rnd.nextDouble() * 9.0,
          speed: 0.75 + _rnd.nextDouble() * 0.85,
          drift: (_rnd.nextDouble() - 0.5) * 0.45,
          rotation: _rnd.nextDouble() * 2 * pi,
          rotationSpeed: (_rnd.nextDouble() - 0.5) * 9.0,
          isStar: i % 4 == 0,
        ),
      );
    }

    _controller.forward().then((_) {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x;
  final double startY;
  final Color color;
  final double size;
  final double speed;
  final double drift;
  final double rotation;
  final double rotationSpeed;
  final bool isStar;

  _Particle({
    required this.x,
    required this.startY,
    required this.color,
    required this.size,
    required this.speed,
    required this.drift,
    required this.rotation,
    required this.rotationSpeed,
    this.isStar = false,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final currentY = (p.startY + (progress * 1.4 * p.speed)) * size.height;
      final currentX = (p.x + (sin(progress * 6 + p.x * 10) * p.drift)) * size.width;
      final currentRot = p.rotation + (progress * p.rotationSpeed);

      if (currentY > size.height) continue;

      paint.color = p.color.withValues(alpha: (1.0 - progress * 0.6).clamp(0.0, 1.0));

      // فيزياء الدوران والتقلب ثلاثي الأبعاد (3D Tumbling Paper Ribbon)
      final flipScale = cos(currentRot * 2.2).abs().clamp(0.15, 1.0);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRot);

      if (p.isStar) {
        // رسم نجمة رباعية لامعة
        final starPath = Path();
        final s = p.size * 0.7 * flipScale;
        starPath.moveTo(0, -s);
        starPath.quadraticBezierTo(0, 0, s, 0);
        starPath.quadraticBezierTo(0, 0, 0, s);
        starPath.quadraticBezierTo(0, 0, -s, 0);
        starPath.quadraticBezierTo(0, 0, 0, -s);
        starPath.close();
        canvas.drawPath(starPath, paint);
      } else {
        // شريحة احتفالية تتقلب في الفضاء ثلاثي الأبعاد
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * flipScale,
              height: p.size * 0.55,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
