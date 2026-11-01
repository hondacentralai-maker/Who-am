import 'package:flutter/material.dart';

// ─── Brand Colors ───────────────────────────────────────
class AppColors {
  AppColors._();

  // ─── Girly Pastel Pink & Soft Lavender Core Palette ───
  static const pastelPink = Color(0xFFF06292);      // Vibrant sweet pastel rose/pink
  static const softPink = Color(0xFFFF7E9E);        // Soft bright pink
  static const babyPink = Color(0xFFFCE4EC);        // Delicate milky blush pink
  static const dustyRose = Color(0xFFD87D9A);       // Elegant warm dusty rose
  static const softLavender = Color(0xFFBA68C8);    // Dreamy soft lavender
  static const lightLavender = Color(0xFFE1BEE7);   // Pastel lilac lavender
  static const paleLavender = Color(0xFFF3E5F5);    // Softest lavender tint
  static const lightMauve = Color(0xFFE8D7F1);      // Whispering light mauve
  static const deepMauve = Color(0xFF6D3862);       // Medium deep mauve
  static const plumPurple = Color(0xFF4A154B);      // Deep rich plum (primary header/brand text)
  static const darkMauve = Color(0xFF7A4B6E);       // Subdued dark mauve (secondary text)

  // ─── Semantic & Backward-Compatible Aliases ───────────
  static const purple = Color(0xFFE94B8A);          // Primary vibrant Girly Pastel Rose
  static const deepPurple = Color(0xFF4A154B);      // Deep Plum Purple
  static const palePurple = Color(0xFFFCEBF2);      // Baby Pink / Soft Blush Tint
  static const lightPurple = Color(0xFFF7D6E4);     // Light Pastel Blush
  static const ultraLightPurple = Color(0xFFFFF7FA);// Soft Blush White (as in reference image)

  // Accent
  static const accentPink = Color(0xFFFF4081);      // Sparkle Bright Accent Pink
  static const accentGold = Color(0xFFFFB74D);      // Warm Pastel Gold

  // Midnight Plum & Lavender Romance Dark Mode Tokens
  static const midnightSurface = Color(0xFF1C101F);
  static const midnightCard = Color(0xFF28182D);
  static const midnightCardBorder = Color(0xFF44284B);
  static const midnightText = Color(0xFFFFF0F6);
  static const midnightMuted = Color(0xFFBFA0BC);
  static const neonPurple = Color(0xFFE0407B);
  static const neonPink = Color(0xFFFF5E9E);
  static const neonGold = Color(0xFFFFC766);

  // Text
  static const ink = Color(0xFF3E163B);             // Deep Plum Purple instead of harsh black
  static const muted = Color(0xFF7A4B6E);           // Elegant Dark Mauve
  static const subtle = Color(0xFFA87D9E);          // Soft Dusty Mauve

  // Surface
  static const surface = Color(0xFFFFF7FA);         // Soft Blush White
  static const card = Colors.white;
  static const cardBorder = Color(0xFFF7D2E2);      // Subtle pastel blush border
  static const cardShadowColor = Color(0x1CE94B8A); // Delicate pastel pink shadow tint
  static const disabledBg = Color(0xFFF5E8EE);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFE94B8A), Color(0xFFCE93D8)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const pinkRoseGradient = LinearGradient(
    colors: [Color(0xFFE94B8A), Color(0xFFF48FB1)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const lavenderGradient = LinearGradient(
    colors: [Color(0xFFBA68C8), Color(0xFFE1BEE7)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const auroraGradient = LinearGradient(
    colors: [Color(0xFFE94B8A), Color(0xFFBA68C8), Color(0xFFF8BBD0)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const softPastelCardGradient = LinearGradient(
    colors: [Color(0xFFFFF9FA), Color(0xFFFFF0F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const midnightAurora = LinearGradient(
    colors: [Color(0xFF2A122E), Color(0xFF3F1946), Color(0xFF561A54)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const softGradient = LinearGradient(
    colors: [Color(0xFFE94B8A), Color(0xFFCE93D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const shimmerGradient = LinearGradient(
    colors: [Color(0xFFF48FB1), Color(0xFFE94B8A), Color(0xFFCE93D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Shadows ────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static const cardShadow = [
    BoxShadow(
      color: Color(0x12E94B8A),
      blurRadius: 16,
      offset: Offset(0, 5),
    ),
  ];

  static const elevatedShadow = [
    BoxShadow(
      color: Color(0x22E94B8A),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const floatingShadow = [
    BoxShadow(
      color: Color(0x30E94B8A),
      blurRadius: 32,
      offset: Offset(0, 12),
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

  static const small = 14.0;
  static const medium = 18.0;
  static const large = 24.0;
  static const xl = 32.0;
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

  static BoxDecoration pinkHeroBanner({double radius = AppRadius.large}) =>
      BoxDecoration(
        gradient: AppColors.pinkRoseGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.elevatedShadow,
      );

  static BoxDecoration outlinedCard({double radius = AppRadius.card}) =>
      BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: AppShadows.cardShadow,
      );

  static BoxDecoration pastelCard({double radius = AppRadius.card}) =>
      BoxDecoration(
        gradient: AppColors.softPastelCardGradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: AppShadows.cardShadow,
      );

  static BoxDecoration glassCard({double radius = AppRadius.large}) =>
      BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.7)),
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
          ? const Color(0xCC28182D)
          : Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: accentColor != null
            ? accentColor.withValues(alpha: isDark ? 0.4 : 0.3)
            : (isDark
                ? AppColors.midnightCardBorder
                : AppColors.cardBorder),
        width: 1.5,
      ),
      boxShadow: isDark
          ? [
              BoxShadow(
                color: (accentColor ?? AppColors.neonPurple)
                    .withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
          : [
              BoxShadow(
                color: (accentColor ?? AppColors.purple).withValues(alpha: 0.12),
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
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
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
          primary: AppColors.purple,
          secondary: AppColors.softLavender,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.deepPurple,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.deepPurple,
          ),
          iconTheme: IconThemeData(color: AppColors.deepPurple),
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
            elevation: 2,
            shadowColor: AppColors.purple.withValues(alpha: 0.35),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.purple,
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
            color: AppColors.deepPurple,
          ),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFFFFF9FB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
            side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.deepPurple,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          backgroundColor: AppColors.deepPurple,
          contentTextStyle: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: const BorderSide(color: AppColors.purple, width: 1.8),
          ),
          labelStyle: const TextStyle(color: AppColors.muted),
          prefixIconColor: AppColors.purple,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.neonPurple,
          brightness: Brightness.dark,
          surface: AppColors.midnightSurface,
        ),
        scaffoldBackgroundColor: AppColors.midnightSurface,
        cardColor: AppColors.midnightCard,
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.midnightSurface,
          foregroundColor: AppColors.midnightText,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.midnightText,
          ),
          iconTheme: IconThemeData(color: AppColors.midnightText),
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
            elevation: 3,
            shadowColor: AppColors.neonPurple.withValues(alpha: 0.35),
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
            side: const BorderSide(color: AppColors.midnightCardBorder, width: 1.2),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.midnightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
            side: const BorderSide(color: AppColors.midnightCardBorder, width: 1.2),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.midnightText,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          backgroundColor: AppColors.midnightCard,
          contentTextStyle: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
