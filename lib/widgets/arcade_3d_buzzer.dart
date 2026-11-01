import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

/// A hyper-realistic 3D arcade/game-show buzzer button with tactile depth,
/// mechanical depression upon pressing, specular glare, and haptic feedback.
class Arcade3DBuzzer extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool enabled;
  final double height;

  const Arcade3DBuzzer({
    super.key,
    required this.label,
    this.icon,
    this.color = const Color(0xFFD32F2F),
    this.onPressed,
    this.enabled = true,
    this.height = 64,
  });

  @override
  State<Arcade3DBuzzer> createState() => _Arcade3DBuzzerState();
}

class _Arcade3DBuzzerState extends State<Arcade3DBuzzer> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled || widget.onPressed == null) return;
    setState(() => _isPressed = true);
    _animCtrl.forward();
    PreferencesService.triggerHaptic(AppHapticType.heavy);
  }

  void _onTapUp(TapUpDetails _) {
    if (!widget.enabled || widget.onPressed == null) return;
    setState(() => _isPressed = false);
    _animCtrl.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
    _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final double depth = widget.enabled ? 8.0 : 3.0;
    final Color buttonColor = widget.enabled ? widget.color : Colors.grey.shade600;
    final HSLColor hsl = HSLColor.fromColor(buttonColor);
    final Color darkerShade = hsl.withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0)).toColor();
    final Color lighterShade = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (context, _) {
          final double currentPressOffset = _isPressed ? depth * 0.75 : 0.0;

          return SizedBox(
            height: widget.height + depth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Bottom Shadow & Extruded 3D Base
                Positioned(
                  top: depth,
                  left: 0,
                  right: 0,
                  height: widget.height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: darkerShade,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: darkerShade.withValues(alpha: widget.enabled ? 0.55 : 0.2),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Depressible Plunger Top
                Positioned(
                  top: currentPressOffset,
                  left: 0,
                  right: 0,
                  height: widget.height,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lighterShade,
                          buttonColor,
                          darkerShade,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Specular Top Glare
                        Positioned(
                          top: 2,
                          left: 12,
                          right: 12,
                          height: widget.height * 0.35,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.45),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Center Label and Icon
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  color: Colors.white,
                                  size: 26,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                              ],
                              Flexible(
                                child: Text(
                                  widget.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

