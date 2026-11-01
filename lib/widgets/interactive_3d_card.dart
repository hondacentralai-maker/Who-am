import 'package:flutter/material.dart';

/// ويدجت تفاعلي ثلاثي الأبعاد (Interactive 3D Tilt Card)
/// مستوحى من أفضل مشاريع GitHub (flutter_tilt و 3D Parallax Matrix)
/// يمنح البطاقات تفاعلاً حسياً واقعياً: إمالة ثلاثية الأبعاد مع لمس الإصبع،
/// انعكاسات إضاءة هولوجرامية حية، وظلال عمق ديناميكية وفيزياء ارتداد زنبركية.
class Interactive3DCard extends StatefulWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final double maxTiltAngle;
  final double perspective;
  final bool enableGlare;
  final Color? glareColor;
  final double maxGlareOpacity;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? baseShadows;

  const Interactive3DCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.maxTiltAngle = 0.22, // ~12.5 درجات إمالة واقعية
    this.perspective = 0.0016,
    this.enableGlare = true,
    this.glareColor,
    this.maxGlareOpacity = 0.35,
    this.onTap,
    this.margin,
    this.baseShadows,
  });

  @override
  State<Interactive3DCard> createState() => _Interactive3DCardState();
}

class _Interactive3DCardState extends State<Interactive3DCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<Offset> _springAnimation;

  Offset _tiltOffset = Offset.zero;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _springAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.elasticOut,
    ))..addListener(() {
        setState(() {
          _tiltOffset = _springAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final localPos = details.localPosition;
    final normalizedX = ((localPos.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
    final normalizedY = ((localPos.dy / size.height) * 2 - 1).clamp(-1.0, 1.0);

    setState(() {
      _tiltOffset = Offset(normalizedX, normalizedY);
      _isInteracting = true;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _isInteracting = false;
    _springAnimation = Tween<Offset>(
      begin: _tiltOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.elasticOut,
    ));
    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(24);

    return Container(
      margin: widget.margin,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          // حساب مصفوفة التحول ثلاثية الأبعاد (Matrix4 Perspective Transformation)
          final transform = Matrix4.identity()
            ..setEntry(3, 2, widget.perspective)
            ..rotateX(-_tiltOffset.dy * widget.maxTiltAngle)
            ..rotateY(_tiltOffset.dx * widget.maxTiltAngle);

          // ظل ديناميكي يتحرك عكس زاوية الميلان لإبراز العمق
          final shadowOffset = Offset(
            -_tiltOffset.dx * 12.0,
            -_tiltOffset.dy * 12.0 + 6.0,
          );
          final shadowBlur = 16.0 + (_tiltOffset.dx.abs() + _tiltOffset.dy.abs()) * 14.0;

          return GestureDetector(
            onTap: widget.onTap,
            onPanDown: (d) => _springController.stop(),
            onPanUpdate: (d) => _onPanUpdate(d, size),
            onPanEnd: _onPanEnd,
            onPanCancel: () => _onPanEnd(DragEndDetails()),
            child: Transform(
              transform: transform,
              alignment: FractionalOffset.center,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: br,
                  boxShadow: [
                    if (widget.baseShadows != null) ...widget.baseShadows!,
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isInteracting ? 0.22 : 0.12,
                      ),
                      blurRadius: shadowBlur,
                      offset: shadowOffset,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: br,
                  child: Stack(
                    children: [
                      // المحتوى الأصلي للبطاقة
                      widget.child,

                      // طبقة الوهج والانعكاس السطحي الحي (Holographic Glare Layer)
                      if (widget.enableGlare && _tiltOffset != Offset.zero)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: br,
                                gradient: RadialGradient(
                                  center: Alignment(
                                    _tiltOffset.dx * 1.3,
                                    _tiltOffset.dy * 1.3,
                                  ),
                                  radius: 1.15,
                                  colors: [
                                    (widget.glareColor ?? Colors.white).withValues(
                                      alpha: (_tiltOffset.distance * widget.maxGlareOpacity)
                                          .clamp(0.0, widget.maxGlareOpacity),
                                    ),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 1.0],
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
          );
        },
      ),
    );
  }
}
