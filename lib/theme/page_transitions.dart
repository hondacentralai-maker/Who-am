import 'package:flutter/material.dart';

/// انتقال صفحات ناعم ومترف بانسيابية نابضة (Pastel Fluid Spring Page Route)
/// مستوحى من أحدث حركات الانتقال في GitHub مع تقليل زمن الاستجابة ودعم Impeller
class PastelPageRoute<T> extends PageRouteBuilder<T> {
  final Widget? page;
  final WidgetBuilder? builder;

  PastelPageRoute({
    this.page,
    this.builder,
    super.settings,
  }) : assert(page != null || builder != null, 'Either page or builder must be provided'),
       super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              page ?? builder!(context),
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            // انزلاق رأسي طفيف مع تكبير تدريجي ناعم
            final slideTween = Tween<Offset>(
              begin: const Offset(0.0, 0.06),
              end: Offset.zero,
            ).animate(curvedAnimation);

            final scaleTween = Tween<double>(
              begin: 0.96,
              end: 1.0,
            ).animate(curvedAnimation);

            final fadeTween = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation);

            return SlideTransition(
              position: slideTween,
              child: ScaleTransition(
                scale: scaleTween,
                child: FadeTransition(
                  opacity: fadeTween,
                  child: child,
                ),
              ),
            );
          },
        );
}

/// انتقال صفحات ثلاثي الأبعاد بانعطاف منظوري سينمائي (Cinematic 3D Perspective Route)
/// يمنح الشاشات عمقاً حقيقياً ثلاثي الأبعاد أثناء الدخول والخروج.
class Perspective3DPageRoute<T> extends PageRouteBuilder<T> {
  final Widget? page;
  final WidgetBuilder? builder;

  Perspective3DPageRoute({
    this.page,
    this.builder,
    super.settings,
  }) : assert(page != null || builder != null, 'Either page or builder must be provided'),
       super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              page ?? builder!(context),
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            );

            return AnimatedBuilder(
              animation: curvedAnimation,
              builder: (context, child) {
                final progress = curvedAnimation.value;
                final angle = (1.0 - progress) * 0.35; // زاوية دوران منظورية ثلاثية الأبعاد

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(-angle)
                    ..setTranslationRaw((1.0 - progress) * 60, 0.0, (1.0 - progress) * -80),
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: progress.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
        );
}
