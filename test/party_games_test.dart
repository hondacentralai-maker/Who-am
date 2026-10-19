import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabic_couples_game/models/party_game_models.dart';
import 'package:arabic_couples_game/screens/party_games_hub_screen.dart';
import 'package:arabic_couples_game/screens/party_games/five_seconds_screen.dart';
import 'package:arabic_couples_game/screens/party_games/most_likely_to_screen.dart';
import 'package:arabic_couples_game/screens/party_games/spyfall_screen.dart';
import 'package:arabic_couples_game/screens/party_games/stop_game_screen.dart';
import 'package:arabic_couples_game/screens/party_games/taboo_screen.dart';
import 'package:arabic_couples_game/screens/party_games/would_you_rather_screen.dart';
import 'package:arabic_couples_game/services/preferences_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'streak_days': 5,
      'partner1_name': 'سارة',
      'partner2_name': 'نور',
    });
    await PreferencesService.init();
  });

  group('Party Game Models & Decks Integrity', () {
    test('Stop Game (أوتوبيس كومبليت) contains 28 letters and 7 categories', () {
      expect(StopGameData.arabicLetters.length, equals(28));
      expect(StopGameData.arabicLetters.contains('أ'), isTrue);
      expect(StopGameData.arabicLetters.contains('ي'), isTrue);

      expect(StopGameData.defaultCategories.length, equals(7));
      for (final cat in StopGameData.defaultCategories) {
        expect(cat.key.isNotEmpty, isTrue);
        expect(cat.label.isNotEmpty, isTrue);
        expect(cat.emoji.isNotEmpty, isTrue);
      }
    });

    test('Most Likely To (مين فينا) prompts contain authentic questions and emojis', () {
      final prompts = MostLikelyToPrompt.defaultPrompts();
      expect(prompts.length, greaterThanOrEqualTo(15));
      for (final p in prompts) {
        expect(p.id.isNotEmpty, isTrue);
        expect(p.question.isNotEmpty, isTrue);
        expect(p.category.isNotEmpty, isTrue);
        expect(p.emoji.isNotEmpty, isTrue);
      }
    });

    test('Five Seconds prompts contain swift challenging questions', () {
      final prompts = FiveSecondPrompt.defaultPrompts();
      expect(prompts.length, greaterThanOrEqualTo(15));
      for (final p in prompts) {
        expect(p.id.isNotEmpty, isTrue);
        expect(p.question.contains('3'), isTrue);
        expect(p.category.isNotEmpty, isTrue);
      }
    });

    test('Spyfall locations contain culturally authentic locations and roles', () {
      final locations = SpyfallLocation.defaultLocations();
      expect(locations.length, greaterThanOrEqualTo(8));
      for (final loc in locations) {
        expect(loc.id.isNotEmpty, isTrue);
        expect(loc.name.isNotEmpty, isTrue);
        expect(loc.emoji.isNotEmpty, isTrue);
        expect(loc.typicalRoles.length, greaterThanOrEqualTo(3));
      }
    });

    test('Taboo cards contain target words and 4 forbidden words each', () {
      final cards = TabooCard.defaultCards();
      expect(cards.length, greaterThanOrEqualTo(8));
      for (final card in cards) {
        expect(card.id.isNotEmpty, isTrue);
        expect(card.targetWord.isNotEmpty, isTrue);
        expect(card.forbiddenWords.length, equals(4));
        expect(card.category.isNotEmpty, isTrue);
      }
    });

    test('Would You Rather dilemmas contain distinct options', () {
      final dilemmas = WouldYouRatherPrompt.defaultPrompts();
      expect(dilemmas.length, greaterThanOrEqualTo(6));
      for (final d in dilemmas) {
        expect(d.id.isNotEmpty, isTrue);
        expect(d.optionA.isNotEmpty, isTrue);
        expect(d.optionB.isNotEmpty, isTrue);
        expect(d.optionA, isNot(equals(d.optionB)));
      }
    });
  });

  group('Party Games Screens Widget Tests', () {
    testWidgets('PartyGamesHubScreen renders festival banner and all 6 games',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PartyGamesHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ألعاب الجلسات والتجمعات 🥳'), findsOneWidget);
      expect(find.text('مهرجان الألعاب الجماعية'), findsOneWidget);
      expect(find.text('إنسان، حيوان، نبات (أوتوبيس كومبليت)'), findsOneWidget);
      expect(find.text('مين فينا؟ / مين أكثر واحدة؟'), findsOneWidget);
      expect(find.text('تحدي الـ 5 ثواني'), findsOneWidget);
      expect(find.text('الجاسوسة والمندَسّة (Spyfall)'), findsOneWidget);
      expect(find.text('قول بس لا تقول (المحظورات)'), findsOneWidget);
      expect(find.text('لو خيروك الجماعي'), findsOneWidget);
    });

    testWidgets('StopGameScreen renders letter picker and stop button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StopGameScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STOP! أوتوبيس كومبليت! 🛑'), findsOneWidget);
      expect(find.text('اسم ولد'), findsOneWidget);
      expect(find.text('اسم بنت'), findsOneWidget);
      expect(find.text('حيوان'), findsOneWidget);
    });

    testWidgets('MostLikelyToScreen renders question and players list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MostLikelyToScreen(initialPlayers: ['سارة', 'نور', 'شهد']),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مين فينا؟ 🎭'), findsOneWidget);
      expect(find.text('سارة'), findsWidgets);
      expect(find.text('نور'), findsWidgets);
      expect(find.text('شهد'), findsWidgets);
    });

    testWidgets('FiveSecondsScreen renders challenge card and start button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FiveSecondsScreen(initialPlayers: ['سارة', 'نور']),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تحدي الـ 5 ثواني ⏱️'), findsOneWidget);
      expect(find.text('ابدأ الـ 5 ثواني الآن! ⚡'), findsOneWidget);
    });

    testWidgets('SpyfallScreen renders setup view and start button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SpyfallScreen(initialPlayers: ['سارة', 'نور', 'شهد', 'ريم']),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الجاسوسة والمندَسّة 🕵️‍♀️'), findsOneWidget);
      expect(find.text('بدء توزيع الأدوار السرية 🎭'), findsOneWidget);
    });

    testWidgets('TabooScreen renders teams and round start card',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TabooScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('قول بس لا تقول 🤐'), findsOneWidget);
      expect(find.text('فريق الورد 🌸'), findsWidgets);
      expect(find.text('فريق الياسمين 🌼'), findsWidgets);
      expect(find.text('ابدأ الجولة (60 ثانية) ⚡'), findsOneWidget);
    });

    testWidgets('WouldYouRatherScreen renders option cards and vote triggers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WouldYouRatherScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('لو خيروك الجماعي 🤔'), findsOneWidget);
      expect(find.text('الخيار الأول (أ)'), findsOneWidget);
      expect(find.text('الخيار الثاني (ب)'), findsOneWidget);
      expect(find.text('أو ⚡'), findsOneWidget);
    });
  });
}
