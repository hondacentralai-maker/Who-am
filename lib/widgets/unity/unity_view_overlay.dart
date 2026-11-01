import 'package:flutter/material.dart';

/// Overlay widget placed on top of the Unity 3D view.
/// Allows displaying Flutter HUD components (scores, turns, menus, chat)
/// while passing touch events in empty areas through to the Unity 3D camera.
class UnityViewOverlay extends StatelessWidget {
  /// Header title for the active game/scene.
  final String title;

  /// Optional subtitle or room status.
  final String? subtitle;

  /// Callback when user taps back/exit.
  final VoidCallback? onExit;

  /// Callback when user toggles sound.
  final VoidCallback? onToggleSound;

  /// Whether sound is currently enabled.
  final bool isSoundEnabled;

  /// Custom bottom HUD widget (e.g. cards hand, action buttons).
  final Widget? bottomHud;

  /// Custom floating widgets (e.g. turn timer, score banners).
  final List<Widget>? floatingWidgets;

  /// Custom actions in top bar.
  final List<Widget>? actions;

  const UnityViewOverlay({
    super.key,
    required this.title,
    this.subtitle,
    this.onExit,
    this.onToggleSound,
    this.isSoundEnabled = true,
    this.bottomHud,
    this.floatingWidgets,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top HUD Bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Back / Exit Button
                  if (onExit != null)
                    _CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: onExit!,
                      tooltip: 'خروج',
                    ),
                  const SizedBox(width: 12),

                  // Title and Subtitle Pill
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subtitle != null)
                                  Text(
                                    subtitle!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Sound Toggle Button
                  if (onToggleSound != null)
                    _CircleIconButton(
                      icon: isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      onPressed: onToggleSound!,
                      tooltip: isSoundEnabled ? 'كتم الصوت' : 'تشغيل الصوت',
                      iconColor: isSoundEnabled ? const Color(0xFFFBBF24) : Colors.white70,
                    ),

                  // Optional Extra Actions
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),

        // Floating Widgets
        if (floatingWidgets != null) ...floatingWidgets!,

        // Bottom HUD
        if (bottomHud != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: bottomHud!,
            ),
          ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

