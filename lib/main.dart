import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'services/preferences_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline local storage
  await PreferencesService.init();

  // Initialize Supabase (with offline-safe fallback)
  try {
    await SupabaseService.init();
  } catch (e) {
    debugPrint('Supabase init notice: $e (App will function in offline mode)');
  }

  runApp(const ArabicCouplesGame());
}

class ArabicCouplesGame extends StatefulWidget {
  const ArabicCouplesGame({super.key});

  @override
  State<ArabicCouplesGame> createState() => _ArabicCouplesGameState();
}

class _ArabicCouplesGameState extends State<ArabicCouplesGame> {
  void _refreshTheme() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PreferencesService.isDarkMode;

    return MaterialApp(
      title: 'من أنا؟',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('ar', ''),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
      ],
      builder: (context, child) {
        final fontScale = PreferencesService.fontScale;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(fontScale),
            ),
            child: child ?? const SizedBox(),
          ),
        );
      },
      home: HomeScreen(onThemeChanged: _refreshTheme),
    );
  }
}
