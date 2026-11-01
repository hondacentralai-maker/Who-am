import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/game_audio_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';

class GlassNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const GlassNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xDD28182D)
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? AppColors.midnightCardBorder
                    : AppColors.cardBorder,
                width: 1.5,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppColors.neonPurple.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Color(0x1AE94B8A),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == currentIndex;

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      PreferencesService.triggerHaptic(AppHapticType.selection);
                      GameAudioService().playTap();
                      onTap(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSelected ? 16 : 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? (isDark
                                      ? AppColors.midnightAurora
                                      : AppColors.primaryGradient)
                                  : null,
                              color: isSelected && !isDark
                                  ? null
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (isDark
                                                ? AppColors.neonPurple
                                                : AppColors.purple)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.midnightMuted
                                      : AppColors.muted),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.neonPurple
                                      : AppColors.deepPurple)
                                  : (isDark
                                      ? AppColors.midnightMuted
                                      : AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
