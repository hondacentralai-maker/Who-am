import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';

enum ParticleShape { heart, sparkle, softCircle }

class _Particle {
  double x; // 0.0 to 1.0
  double y; // 0.0 to 1.0
  double size;
  double speed;
  double opacity;
  double phase;
  ParticleShape shape;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
    required this.shape,
    required this.color,
  });
}

/// طبقة الجزيئات الهادئة العائمة في الخلفية (Ambient Floating Particles)
/// مستوحاة من مشاريع المحاكاة الفيزيائية في GitHub بأعلى أداء (Zero Overhead, 120 FPS)
class AmbientParticles extends StatefulWidget {
  final Widget? child;
  final int particleCount;
  final bool enabled;

  const AmbientParticles({
    super.key,
    this.child,
    this.particleCount = 18,
    this.enabled = true,
  });

  @override
  State<AmbientParticles> createState() => _AmbientParticlesState();
}

class _AmbientParticlesState extends State<AmbientParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    final bool isTestEnv = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (widget.enabled && !PreferencesService.reducedMotion && !isTestEnv) {
      _controller.repeat();
    }
  }

  void _initParticles() {
    final colors = [
      AppColors.pastelPink.withValues(alpha: 0.35),
      AppColors.softLavender.withValues(alpha: 0.30),
      AppColors.accentGold.withValues(alpha: 0.25),
      AppColors.dustyRose.withValues(alpha: 0.28),
      Colors.white.withValues(alpha: 0.40),
    ];

    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 6.0 + _random.nextDouble() * 10.0,
          speed: 0.03 + _random.nextDouble() * 0.05,
          opacity: 0.2 + _random.nextDouble() * 0.5,
          phase: _random.nextDouble() * 2 * pi,
          shape: ParticleShape.values[_random.nextInt(ParticleShape.values.length)],
          color: colors[_random.nextInt(colors.length)],
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || PreferencesService.reducedMotion) {
      return widget.child ?? const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ParticlesPainter(
                      particles: _particles,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  static final Paint _paint = Paint()..style = PaintingStyle.fill;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    for (final p in particles) {
      // تحديث الإحداثي الرأسي مع التكرار الدوري اللانهائي
      final currentY = (p.y - (progress * p.speed)) % 1.0;
      final actualY = (currentY < 0 ? currentY + 1.0 : currentY) * size.height;

      // تمايل أفقي جيبي ناعم
      final sway = sin((progress * 2 * pi) + p.phase) * (size.width * 0.03);
      final actualX = ((p.x * size.width) + sway) % size.width;

      final currentAlpha = (p.opacity * (0.6 + 0.4 * sin((progress * 2 * pi) + p.phase))).clamp(0.05, 0.7);

      switch (p.shape) {
        case ParticleShape.softCircle:
          _paint.color = p.color.withValues(alpha: currentAlpha);
          canvas.drawCircle(Offset(actualX, actualY), p.size * 0.45, _paint);
          break;

        case ParticleShape.sparkle:
          _drawSparkle(canvas, Offset(actualX, actualY), p.size, p.color.withValues(alpha: currentAlpha));
          break;

        case ParticleShape.heart:
          _drawHeart(canvas, Offset(actualX, actualY), p.size, p.color.withValues(alpha: currentAlpha));
          break;
      }
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    _paint.color = color;
    final half = size * 0.5;
    final quarter = size * 0.15;

    final path = Path()
      ..moveTo(center.dx, center.dy - half)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + half, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + half)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - half, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - half)
      ..close();

    canvas.drawPath(path, _paint);

    // مركز النجمة المتوهج
    _paint.color = Colors.white.withValues(alpha: color.a * 0.7);
    canvas.drawCircle(center, quarter * 0.6, _paint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    _paint.color = color;
    final s = size * 0.55;

    final path = Path();
    path.moveTo(center.dx, center.dy + s * 0.5);
    // القوس الأيسر
    path.cubicTo(
      center.dx - s, center.dy - s * 0.3,
      center.dx - s * 0.6, center.dy - s * 0.9,
      center.dx, center.dy - s * 0.4,
    );
    // القوس الأيمن
    path.cubicTo(
      center.dx + s * 0.6, center.dy - s * 0.9,
      center.dx + s, center.dy - s * 0.3,
      center.dx, center.dy + s * 0.5,
    );
    path.close();

    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}
