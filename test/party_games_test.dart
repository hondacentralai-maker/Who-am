import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:arabic_couples_game/screens/party_games/feen_el_so2al_screen.dart';
import 'package:arabic_couples_game/screens/party_games/besaraha_wal3a_screen.dart';
import 'package:arabic_couples_game/screens/party_games/family_stories_screen.dart';
import 'package:arabic_couples_game/screens/party_games/girls_lakin_screen.dart';
import 'package:arabic_couples_game/screens/party_games/hatrick_screen.dart';
import 'package:arabic_couples_game/screens/party_games/bottle_spin_screen.dart';
import 'package:arabic_couples_game/services/preferences_service.dart';
import 'package:arabic_couples_game/services/game_audio_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
  });

  setUp(() async {
    GameAudioService().isSoundEnabled = false;
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

    test('Feen El So2al prompts contain answers, real questions and wrong options', () {
      final prompts = FeenElSo2alPrompt.defaultPrompts();
      expect(prompts.length, greaterThanOrEqualTo(6));
      for (final p in prompts) {
        expect(p.id.isNotEmpty, isTrue);
        expect(p.answer.isNotEmpty, isTrue);
        expect(p.correctQuestion.isNotEmpty, isTrue);
        expect(p.wrongQuestions.length, greaterThanOrEqualTo(2));
        expect(p.allOptions.length, equals(p.wrongQuestions.length + 1));
      }
    });

    test('Besaraha and Wal3a cards span saraha, dare, and luck types', () {
      final cards = BesarahaWal3aCard.defaultCards();
      expect(cards.length, greaterThanOrEqualTo(8));
      expect(cards.any((c) => c.type == BesarahaWal3aType.saraha), isTrue);
      expect(cards.any((c) => c.type == BesarahaWal3aType.dare), isTrue);
      expect(cards.any((c) => c.type == BesarahaWal3aType.luck), isTrue);
      for (final c in cards) {
        expect(c.points, greaterThan(0));
        expect(c.title.isNotEmpty, isTrue);
        expect(c.content.isNotEmpty, isTrue);
      }
    });

    test('Family Stories prompts contain nostalgic family themes', () {
      final prompts = FamilyStoriesPrompt.defaultPrompts();
      expect(prompts.length, greaterThanOrEqualTo(5));
      for (final p in prompts) {
        expect(p.id.isNotEmpty, isTrue);
        expect(p.topic.isNotEmpty, isTrue);
        expect(p.question.isNotEmpty, isTrue);
      }
    });

    test('Girls Lakin prompts contain authentic situations and challenges', () {
      final prompts = GirlsLakinPrompt.defaultPrompts();
      expect(prompts.length, greaterThanOrEqualTo(5));
      for (final p in prompts) {
        expect(p.id.isNotEmpty, isTrue);
        expect(p.situation.isNotEmpty, isTrue);
        expect(p.challenge.isNotEmpty, isTrue);
      }
    });

    test('Hatrick prompts contain authentic football trivia questions and answers', () {
      final prompts = HatrickPrompt.defaultPrompts();
      expect(prompts.length, greaterThanOrEqualTo(5));
      for (final p in prompts) {
        expect(p.id.isNotEmpty, isTrue);
        expect(p.question.isNotEmpty, isTrue);
        expect(p.answer.isNotEmpty, isTrue);
        expect(p.category.isNotEmpty, isTrue);
      }
    });
  });

  group('Party Games Screens Widget Tests', () {
    testWidgets('PartyGamesHubScreen renders festival banner and all 10 games',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
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
      expect(find.text('فين السؤال؟ (خمن السؤال المخفي)'), findsOneWidget);
      expect(find.text('بصراحة وتحديات ولعة'), findsOneWidget);
      expect(find.text('حكاوي العيلة والذكريات'), findsOneWidget);
      expect(find.text('جلسات البنات (Girls ولكن)'), findsOneWidget);
      expect(find.text('هاتريك: تحدي وأسئلة كرة القدم ⚽'), findsOneWidget);
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

    testWidgets('FeenElSo2alScreen renders answer card and options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FeenElSo2alScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('فين السؤال؟ ❓'), findsOneWidget);
      expect(find.text('الإجابة أو الموقف المكشوف:'), findsOneWidget);
      expect(find.text('اختر السؤال المخفي الأقرب للواقع:'), findsOneWidget);
    });

    testWidgets('BesarahaWal3aScreen renders active player and action buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BesarahaWal3aScreen(initialPlayers: ['كريم', 'هدى']),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('بصراحة وتحديات ولعة 🔥'), findsOneWidget);
      expect(find.text('الدور الآن على: '), findsOneWidget);
      expect(find.text('تمرير / اعتذار'), findsOneWidget);
    });

    testWidgets('FamilyStoriesScreen renders family memories card and buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FamilyStoriesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('حكاوي العيلة والذكريات 🏡'), findsOneWidget);
      expect(find.text('حكاية جديدة ☕'), findsOneWidget);
      expect(find.text('الحكاية السابقة'), findsOneWidget);
    });

    testWidgets('GirlsLakinScreen renders situation card and challenge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GirlsLakinScreen(initialPlayers: ['سارة', 'نور']),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('جلسات البنات (Girls ولكن) 💅'), findsOneWidget);
      expect(find.text('الموقف المشترك: 👯‍♀️'), findsOneWidget);
      expect(find.text('ولكن.. التحدي والسؤال: 👇'), findsOneWidget);
      expect(find.text('الموقف التالي 💅'), findsOneWidget);
    });

    testWidgets('HatrickScreen renders question, reveal button, and action triggers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HatrickScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('هاتريك: تحدي كرة القدم ⚽'), findsOneWidget);
      expect(find.text('تحدي هاتريك الرياضي ⚽🔥'), findsOneWidget);
      expect(find.text('كشف الإجابة ⚽'), findsOneWidget);
      expect(find.text('جول! (+10)'), findsOneWidget);
      expect(find.text('أوت / تخطي'), findsOneWidget);
    });

    testWidgets('BottleSpinScreen renders 3D bottle arena, players, and triggers spin',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BottleSpinScreen(initialPlayers: ['سارة', 'نور', 'شهد', 'ريم']),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('لف الزجاجة 3D 🍾'), findsOneWidget);
      expect(find.text('سارة'), findsOneWidget);
      expect(find.text('نور'), findsOneWidget);
      expect(find.text('شهد'), findsOneWidget);
      expect(find.text('ريم'), findsOneWidget);
      expect(find.text('لِف الزجاجة الآن 🍾'), findsOneWidget);

      // Tap spin button
      await tester.tap(find.text('لِف الزجاجة الآن 🍾'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('الزجاجة تدور في الفضاء... 🍾'), findsOneWidget);
      expect(find.text('الزجاجة تدور بسرعة... 🌀'), findsOneWidget);

      // Fast-forward animation to completion
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // After settling, Truth or Dare modal should appear
      expect(find.text('🍾 اختارت الزجاجة:'), findsOneWidget);
      expect(find.text('سؤال صراحة'), findsOneWidget);
      expect(find.text('حكم وتحدي 🔥'), findsOneWidget);

      // Pick truth card
      await tester.tap(find.text('سؤال صراحة'));
      await tester.pumpAndSettle();
      expect(find.textContaining('سؤال صراحة 💬:'), findsOneWidget);

      // Pick dare card
      await tester.tap(find.text('حكم وتحدي 🔥'));
      await tester.pumpAndSettle();
      expect(find.textContaining('حكم وتحدي جريء 🔥:'), findsOneWidget);

      // Spin again from dialog
      await tester.tap(find.text('لِف الزجاجة مرة ثانية 🍾'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('الزجاجة تدور في الفضاء... 🍾'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });
}
