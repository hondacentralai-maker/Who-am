import 'package:flutter/material.dart';

// ─── Brand Colors ───────────────────────────────────────
class AppColors {
  AppColors._();

  // Primary palette (purple / white)
  static const purple = Color(0xFF7047D7);
  static const deepPurple = Color(0xFF45218D);
  static const palePurple = Color(0xFFF2EDFF);
  static const lightPurple = Color(0xFFE6DFFF);
  static const ultraLightPurple = Color(0xFFFBFAFF);

  // Accent
  static const accentPink = Color(0xFFD94FA0);
  static const accentGold = Color(0xFFF5C842);

  // Midnight Romance Luxury Dark Mode Tokens
  static const midnightSurface = Color(0xFF0D0A1A);
  static const midnightCard = Color(0xFF17122A);
  static const midnightCardBorder = Color(0xFF2E2452);
  static const midnightText = Color(0xFFF1EEFF);
  static const midnightMuted = Color(0xFFA197C7);
  static const neonPurple = Color(0xFF9D65FF);
  static const neonPink = Color(0xFFFF52A8);
  static const neonGold = Color(0xFFFFD15C);

  // Text
  static const ink = Color(0xFF25213A);
  static const muted = Color(0xFF77728C);
  static const subtle = Color(0xFFAEA8C1);

  // Surface
  static const surface = Color(0xFFFBFAFF);
  static const card = Colors.white;
  static const cardBorder = Color(0xFFE6DFFF);
  static const disabledBg = Color(0xFFE8E6ED);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [deepPurple, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const auroraGradient = LinearGradient(
    colors: [Color(0xFF45218D), Color(0xFF7047D7), Color(0xFFD94FA0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const midnightAurora = LinearGradient(
    colors: [Color(0xFF1B0F38), Color(0xFF2C1656), Color(0xFF4A1852)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const softGradient = LinearGradient(
    colors: [Color(0xFF5B30B0), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const shimmerGradient = LinearGradient(
    colors: [Color(0xFF9B7FE6), Color(0xFF7047D7), Color(0xFF5530A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Shadows ────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static const cardShadow = [
    BoxShadow(
      color: Color(0x0F7047D7),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const elevatedShadow = [
    BoxShadow(
      color: Color(0x227047D7),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const floatingShadow = [
    BoxShadow(
      color: Color(0x337047D7),
      blurRadius: 32,
      offset: Offset(0, 14),
    ),
  ];

  static List<BoxShadow> glow(
    Color color, {
    double blur = 20,
    double alpha = 0.28,
    Offset offset = const Offset(0, 8),
  }) =>
      [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: blur,
          offset: offset,
        ),
      ];
}

// ─── Border Radii ───────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const small = 12.0;
  static const medium = 18.0;
  static const large = 24.0;
  static const xl = 30.0;
  static const card = 22.0;
}

// ─── Spacing ────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const xxl = 36.0;
}

// ─── Durations ──────────────────────────────────────────
class AppDurations {
  AppDurations._();

  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
  static const pageTransition = Duration(milliseconds: 350);
}

// ─── Common Decorations ─────────────────────────────────
class AppDecorations {
  AppDecorations._();

  static BoxDecoration gradientCard({double radius = AppRadius.large}) =>
      BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.elevatedShadow,
      );

  static BoxDecoration outlinedCard({double radius = AppRadius.card}) =>
      BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.cardShadow,
      );

  static BoxDecoration glassCard({double radius = AppRadius.large}) =>
      BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: AppShadows.cardShadow,
      );

  static BoxDecoration frostedGlass({
    required BuildContext context,
    double radius = AppRadius.large,
    Color? accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? const Color(0xCC17122A)
          : Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: accentColor != null
            ? accentColor.withValues(alpha: isDark ? 0.4 : 0.25)
            : (isDark
                ? AppColors.midnightCardBorder
                : Colors.white.withValues(alpha: 0.6)),
        width: 1.5,
      ),
      boxShadow: isDark
          ? [
              BoxShadow(
                color: (accentColor ?? AppColors.neonPurple)
                    .withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
          : [
              BoxShadow(
                color: (accentColor ?? AppColors.purple).withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
    );
  }

  static BoxDecoration paleBox({double radius = AppRadius.medium}) =>
      BoxDecoration(
        color: AppColors.palePurple,
        borderRadius: BorderRadius.circular(radius),
      );
}

// ─── Theme Data ─────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.purple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.ink,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.deepPurple,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            side: const BorderSide(color: AppColors.purple, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.palePurple,
          selectedColor: AppColors.purple,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.ink,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          backgroundColor: AppColors.deepPurple,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.neonPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.midnightSurface,
        cardColor: AppColors.midnightCard,
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.midnightSurface,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.neonPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            side: const BorderSide(color: AppColors.neonPurple, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.midnightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(color: AppColors.midnightCardBorder),
          ),
        ),
      );
}
