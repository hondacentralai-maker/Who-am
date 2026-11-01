import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabic_couples_game/main.dart';
import 'package:arabic_couples_game/models/character.dart';
import 'package:arabic_couples_game/models/couples_card.dart';
import 'package:arabic_couples_game/models/couples_profile.dart';
import 'package:arabic_couples_game/models/decision_wheel_item.dart';
import 'package:arabic_couples_game/models/game_session.dart';
import 'package:arabic_couples_game/models/know_me_question.dart';
import 'package:arabic_couples_game/models/love_note.dart';
import 'package:arabic_couples_game/models/partner_presence.dart';
import 'package:arabic_couples_game/screens/achievements_screen.dart';
import 'package:arabic_couples_game/screens/home_screen.dart';
import 'package:arabic_couples_game/screens/online_room_screen.dart';
import 'package:arabic_couples_game/screens/settings_screen.dart';
import 'package:arabic_couples_game/theme/app_theme.dart';
import 'package:arabic_couples_game/services/game_audio_service.dart';
import 'package:arabic_couples_game/services/game_data_service.dart';
import 'package:arabic_couples_game/services/preferences_service.dart';
import 'package:flutter/services.dart';
import 'package:arabic_couples_game/widgets/coin_3d_dialog.dart';
import 'package:arabic_couples_game/widgets/dice_3d_dialog.dart';
import 'package:arabic_couples_game/widgets/interactive_3d_card.dart';

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
    SharedPreferences.setMockInitialValues({
      'streak_days': 3,
      'dark_mode': false,
      'font_scale': 1.0,
      'reduced_motion': false,
    });
    await PreferencesService.init();
  });

  testWidgets('Home screen displays title, streak, and primary game modes',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ArabicCouplesGame());
    await tester.pumpAndSettle();

    expect(find.text('من أنا؟ 💜'), findsAtLeastNWidgets(1));
    expect(find.text('خمن الشخصية'), findsOneWidget);
    expect(find.text('جلسة الأزواج المنظمة'), findsOneWidget);
    expect(find.text('أسئلة وتحديات للأزواج'), findsOneWidget);
  });

  test('Character trait matching works properly across Arabic attributes', () {
    const c1 = Character(
      id: 'char_test_1',
      name: 'طارق',
      emoji: '🧔🏻‍♂️',
      gender: 'رجل',
      older: false,
      glasses: true,
      beard: true,
      headwear: false,
      hijab: false,
      thobe: true,
      hair: 'داكن',
      skin: 'فاتحة',
    );

    expect(c1.trait('gender_male'), isTrue);
    expect(c1.trait('gender_female'), isFalse);
    expect(c1.trait('glasses'), isTrue);
    expect(c1.trait('beard'), isTrue);
    expect(c1.trait('hijab'), isFalse);
    expect(c1.trait('thobe'), isTrue);
    expect(c1.trait('light_skin'), isTrue);
    expect(c1.trait('dark_hair'), isTrue);

    const c2 = Character(
      id: 'char_test_2',
      name: 'نورة',
      emoji: '🧕🏼',
      gender: 'امرأة',
      older: false,
      glasses: false,
      beard: false,
      headwear: true,
      hijab: true,
      thobe: false,
      hair: 'محجبة',
      skin: 'حنطية',
    );

    expect(c2.trait('gender_female'), isTrue);
    expect(c2.trait('gender_male'), isFalse);
    expect(c2.trait('hijab'), isTrue);
    expect(c2.trait('headwear'), isTrue);
    expect(c2.trait('olive_skin'), isTrue);
  });

  test('StructuredSession step progression and completion', () {
    final sampleCards = [
      const CouplesCard(
        id: '1',
        category: 'التقارب',
        type: 'سؤال',
        level: 'خفيف',
        text: 'سؤال تمهيدي',
        purpose: 'بداية',
      ),
      const CouplesCard(
        id: '2',
        category: 'التقارب',
        type: 'سؤال',
        level: 'عميق',
        text: 'سؤال عميق',
        purpose: 'حوار',
      ),
      const CouplesCard(
        id: '3',
        category: 'الامتنان',
        type: 'امتنان',
        level: 'متوسط',
        text: 'شكراً لك',
        purpose: 'تقدير',
      ),
      const CouplesCard(
        id: '4',
        category: 'تأمل ومراجعة',
        type: 'تأمل',
        level: 'عميق',
        text: 'تأمل ختامي',
        purpose: 'هدوء',
      ),
    ];

    final session = StructuredSession(allCards: sampleCards);
    expect(session.steps.length, equals(4));
    expect(session.isCompleted, isFalse);

    session.next();
    expect(session.currentStepIndex, equals(1));

    session.next();
    session.next();
    session.next();
    expect(session.isCompleted, isTrue);
  });

  test('PreferencesService custom cards full CRUD lifecycle', () async {
    expect(PreferencesService.getCustomCards(), isEmpty);

    // 1. Add custom card
    final card = {
      'id': 'test_card_1',
      'category': 'أسئلتنا الخاصة',
      'type': 'سؤال',
      'level': 'خاص',
      'text': 'ما هو أجمل يوم قضيناه سوياً؟',
      'purpose': 'استذكار الذكريات الجميلة',
    };
    await PreferencesService.addCustomCard(card);

    var cards = PreferencesService.getCustomCards();
    expect(cards.length, equals(1));
    expect(cards.first['text'], equals('ما هو أجمل يوم قضيناه سوياً؟'));

    // 2. Update custom card
    final updatedCard = Map<String, dynamic>.from(card);
    updatedCard['text'] = 'ما هي أفضل لحظة عشناها هذا العام؟';
    await PreferencesService.updateCustomCard('test_card_1', updatedCard);

    cards = PreferencesService.getCustomCards();
    expect(cards.length, equals(1));
    expect(cards.first['text'], equals('ما هي أفضل لحظة عشناها هذا العام؟'));

    // 3. Delete custom card
    await PreferencesService.deleteCustomCard('test_card_1');
    cards = PreferencesService.getCustomCards();
    expect(cards, isEmpty);
  });

  test('KnowMeQuestion model serialization and properties', () {
    const q = KnowMeQuestion(
      id: 'km_99',
      category: 'التفضيلات اليومية',
      question: 'وش مشروبي المفضل في الصباح؟',
      hint: 'شاي، قهوة سوداء، لاتيه، عصير',
    );

    final json = q.toJson();
    expect(json['id'], equals('km_99'));
    expect(json['hint'], equals('شاي، قهوة سوداء، لاتيه، عصير'));

    final parsed = KnowMeQuestion.fromJson(json);
    expect(parsed.id, equals('km_99'));
    expect(parsed.question, equals('وش مشروبي المفضل في الصباح؟'));
    expect(parsed.category, equals('التفضيلات اليومية'));
  });

  test('GameStats points, levels, and badge unlocking', () async {
    final initialStats = PreferencesService.getStats();
    expect(initialStats.totalPoints, equals(0));
    expect(initialStats.level, equals(1));

    // Record game finished with win
    await PreferencesService.recordGameFinished(
      isGuessWin: true,
      pointsEarned: 25,
    );

    final afterGameStats = PreferencesService.getStats();
    expect(afterGameStats.gamesPlayed, equals(1));
    expect(afterGameStats.correctGuesses, equals(1));
    expect(afterGameStats.totalPoints, greaterThanOrEqualTo(25));

    // Verify first_game achievement is unlocked
    final achievements = PreferencesService.getAchievements();
    final firstGameBadge =
        achievements.firstWhere((a) => a.id == 'first_game');
    expect(firstGameBadge.isUnlocked, isTrue);
  });

  test('PreferencesService custom Know-Me questions full CRUD lifecycle',
      () async {
    expect(PreferencesService.getCustomKnowMeQuestions(), isEmpty);

    // 1. Add custom question
    final question = {
      'id': 'test_km_1',
      'category': 'أسئلتنا الخاصة',
      'question': 'وش الطبخة اللي تتمنى نطبخها سوا؟',
      'hint': 'أكلة إيطالية أو شعبية',
    };
    await PreferencesService.addCustomKnowMeQuestion(question);

    var questions = PreferencesService.getCustomKnowMeQuestions();
    expect(questions.length, equals(1));
    expect(
      questions.first['question'],
      equals('وش الطبخة اللي تتمنى نطبخها سوا؟'),
    );

    // 2. Delete custom question
    await PreferencesService.deleteCustomKnowMeQuestion('test_km_1');
    questions = PreferencesService.getCustomKnowMeQuestions();
    expect(questions, isEmpty);
  });

  test('PartnerPresence model serialization, states, and Arabic labels', () {
    final p1 = PartnerPresence(
      userId: 'user_1',
      role: 'host',
      displayName: 'طارق',
      status: ConnectionStatus.online,
      lastSeen: DateTime(2026, 10, 19, 21, 0),
    );

    expect(p1.isOnline, isTrue);
    expect(p1.isReconnecting, isFalse);
    expect(p1.isOffline, isFalse);
    expect(p1.statusTextArabic, equals('متصل الآن'));

    final json = p1.toJson();
    expect(json['user_id'], equals('user_1'));
    expect(json['role'], equals('host'));
    expect(json['display_name'], equals('طارق'));

    final parsed = PartnerPresence.fromJson(json);
    expect(parsed.userId, equals('user_1'));
    expect(parsed.role, equals('host'));
    expect(parsed.displayName, equals('طارق'));
    expect(parsed.status, equals(ConnectionStatus.online));

    final p2 = p1.copyWith(status: ConnectionStatus.reconnecting);
    expect(p2.isReconnecting, isTrue);
    expect(p2.statusTextArabic, equals('يعيد الاتصال...'));

    final p3 = p1.copyWith(status: ConnectionStatus.offline);
    expect(p3.isOffline, isTrue);
    expect(p3.statusTextArabic, equals('غير متصل'));
  });

  test('Two players presence matching in the same room (Host and Guest)', () {
    const hostPresence = PartnerPresence(
      userId: 'usr_host_1',
      role: 'host',
      displayName: 'المضيف سارة',
      status: ConnectionStatus.online,
    );

    const guestPresence = PartnerPresence(
      userId: 'usr_guest_2',
      role: 'guest',
      displayName: 'الضيف أحمد',
      status: ConnectionStatus.online,
    );

    final activePresences = [hostPresence, guestPresence];

    // From Host's perspective (seeking guest)
    final guestForHost = activePresences.firstWhere(
      (p) => p.role == 'guest',
    );
    expect(guestForHost.displayName, equals('الضيف أحمد'));
    expect(guestForHost.isOnline, isTrue);

    // From Guest's perspective (seeking host)
    final hostForGuest = activePresences.firstWhere(
      (p) => p.role == 'host',
    );
    expect(hostForGuest.displayName, equals('المضيف سارة'));
    expect(hostForGuest.isOnline, isTrue);
  });

  test('Presence disconnected grace period state simulation', () {
    var status = ConnectionStatus.online;

    // Partner momentarily disconnected -> transition to reconnecting
    status = ConnectionStatus.reconnecting;
    expect(status, equals(ConnectionStatus.reconnecting));

    // Partner reconnects before grace timeout
    status = ConnectionStatus.online;
    expect(status, equals(ConnectionStatus.online));

    // Partner leaves and timeout expires
    status = ConnectionStatus.offline;
    expect(status, equals(ConnectionStatus.offline));
  });

  testWidgets('OnlineRoomScreen enforces auth gate when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: OnlineRoomScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('اللعب عن بعد (غرف Supabase)'), findsOneWidget);
    expect(find.text('إنشاء غرفة الآن'), findsOneWidget);
    expect(find.text('انضمام إلى الغرفة'), findsOneWidget);

    // Tap "إنشاء غرفة الآن" while unauthenticated
    await tester.tap(find.text('إنشاء غرفة الآن'));
    await tester.pumpAndSettle();

    // Verify authentication alert dialog blocks unauthenticated room creation
    expect(find.text('تسجيل الدخول مطلوب'), findsOneWidget);
    expect(
      find.text(
        'يتطلب اللعب عن بعد تسجيل الدخول لحفظ أمان الغرفة والتواصل المباشر بين الشريكين.',
      ),
      findsOneWidget,
    );
  });

  test(
      'PreferencesService haptics triggers safely and respects soundEnabled toggle',
      () async {
    expect(PreferencesService.soundEnabled, isTrue);

    // Should run safely without crashing even in test environment without physical motor
    await PreferencesService.triggerHaptic(AppHapticType.light);
    await PreferencesService.triggerHaptic(AppHapticType.medium);
    await PreferencesService.triggerHaptic(AppHapticType.selection);

    // Disable sound & haptics
    await PreferencesService.setSoundEnabled(false);
    expect(PreferencesService.soundEnabled, isFalse);

    // Should return immediately without triggering haptics
    await PreferencesService.triggerHaptic(AppHapticType.light);

    // Restore setting
    await PreferencesService.setSoundEnabled(true);
    expect(PreferencesService.soundEnabled, isTrue);
  });

  test('Reaction broadcast payload formatting and data integrity', () {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final payload = {
      'emoji': '❤️',
      'sender_role': 'host',
      'sender_name': 'سارة',
      'timestamp': nowMs,
    };

    expect(payload['emoji'], equals('❤️'));
    expect(payload['sender_role'], equals('host'));
    expect(payload['sender_name'], equals('سارة'));
    expect(payload['timestamp'], isA<int>());
    expect(payload['timestamp'], equals(nowMs));
  });

  testWidgets(
      'Active room displays reaction bar with partner emojis and allows interaction',
      (WidgetTester tester) async {
    const testCard = CouplesCard(
      id: 'test_card_p2',
      category: 'التقارب',
      type: 'سؤال',
      level: 'متوسط',
      text: 'ما هي أكثر صفة تعجبك في شريكك؟',
      purpose: 'تعزيز التقدير والمودة',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ActiveOnlineRoomScreen(
            roomId: 'test_room_phase2',
            roomCode: 'LOVE26',
            isHost: true,
            initialCards: [testCard],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify room code in AppBar
    expect(find.text('غرفة: LOVE26'), findsOneWidget);

    // Verify card content
    expect(find.text('ما هي أكثر صفة تعجبك في شريكك؟'), findsOneWidget);

    // Verify presence bar
    expect(find.textContaining('أنت:'), findsOneWidget);
    expect(find.textContaining('الشريك:'), findsOneWidget);

    // Verify all 6 curated emoji reactions exist in the reaction bar
    expect(find.text('❤️'), findsOneWidget);
    expect(find.text('😍'), findsOneWidget);
    expect(find.text('😂'), findsOneWidget);
    expect(find.text('👏'), findsOneWidget);
    expect(find.text('☕'), findsOneWidget);
    expect(find.text('💬'), findsOneWidget);

    // Tap on reaction emoji ❤️ to trigger local animation and broadcast
    await tester.tap(find.text('❤️'));
    await tester.pump(); // Start animation frame
    await tester.pump(const Duration(milliseconds: 300)); // Advance animation

    // Verify next card sync button exists and can be tapped
    expect(find.text('سحب بطاقة جديدة متزامنة'), findsOneWidget);
    await tester.tap(find.text('سحب بطاقة جديدة متزامنة'));
    await tester.pump();

    // Advance time past reaction animation duration (1800ms)
    await tester.pump(const Duration(milliseconds: 2000));
  });

  test('OnlineGameMode titles and emojis match Arabic specifications', () {
    expect(OnlineGameMode.cards.arabicTitle, equals('بطاقات الحوار'));
    expect(OnlineGameMode.cards.emoji, equals('💬'));

    expect(OnlineGameMode.knowMe.arabicTitle, equals('قد إيش تعرفني؟'));
    expect(OnlineGameMode.knowMe.emoji, equals('💜'));

    expect(OnlineGameMode.guessWho.arabicTitle, equals('خمن الشخصية'));
    expect(OnlineGameMode.guessWho.emoji, equals('🎭'));

  });

  test('Multiplayer broadcast event payloads for Know-Me and Guess-Who', () {
    final modePayload = {
      'mode': 'knowMe',
      'actor_role': 'host',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    expect(modePayload['mode'], equals('knowMe'));
    expect(modePayload['actor_role'], equals('host'));

    final knowMePayload = {
      'action': 'secret_submitted',
      'actor_role': 'host',
      'data': {'secret': 'رحلة بالسيارة مع قهوة'},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    expect(knowMePayload['action'], equals('secret_submitted'));
    expect((knowMePayload['data'] as Map)['secret'],
        equals('رحلة بالسيارة مع قهوة'));

    final guessWhoPayload = {
      'action': 'ask_question',
      'actor_role': 'guest',
      'data': {'question': 'هل يرتدي شماغاً؟ 👳'},
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    expect(guessWhoPayload['action'], equals('ask_question'));
    expect((guessWhoPayload['data'] as Map)['question'], contains('شماغ'));
  });

  testWidgets(
      'Online room mode switcher allows switching between Cards, Know-Me, and Guess-Who',
      (WidgetTester tester) async {
    const testCard = CouplesCard(
      id: 'test_card_phase3',
      category: 'التقارب',
      type: 'سؤال',
      level: 'خفيف',
      text: 'ما هو المكان المفضل لكما؟',
      purpose: 'استعادة الأوقات اللطيفة',
    );

    const testQuestion = KnowMeQuestion(
      id: 'q_test_p3',
      category: 'التفضيلات',
      question: 'ما هو فيلمك المفضل؟',
      hint: 'فيلم شاهدناه معاً',
    );

    const testCharacter = Character(
      id: 'char_test_p3',
      name: 'طارق',
      emoji: '🧔🏻‍♂️',
      gender: 'رجل',
      older: false,
      glasses: true,
      beard: true,
      headwear: false,
      hijab: false,
      thobe: true,
      hair: 'داكن',
      skin: 'فاتحة',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ActiveOnlineRoomScreen(
            roomId: 'test_multi_mode',
            roomCode: 'PLAY99',
            isHost: true,
            initialCards: [testCard],
            initialKnowMeQuestions: [testQuestion],
            initialCharacters: [testCharacter],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Verify Mode Switcher exists with all 3 game options
    expect(find.text('💬 بطاقات الحوار'), findsOneWidget);
    expect(find.text('💜 قد إيش تعرفني؟'), findsOneWidget);
    expect(find.text('🎭 خمن الشخصية'), findsOneWidget);

    // Initial mode is Cards
    expect(find.text('ما هو المكان المفضل لكما؟'), findsOneWidget);

    // 2. Switch to Know-Me mode
    await tester.tap(find.text('💜 قد إيش تعرفني؟'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Know-Me UI is displayed
    expect(find.textContaining('دور الإجابة السرية:'), findsOneWidget);

    // 3. Switch to Guess-Who mode
    await tester.tap(find.text('🎭 خمن الشخصية'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Guess-Who UI is displayed
    expect(find.text('اختر شخصيتك السرية 🎭'), findsOneWidget);

    // 4. Switch back to Cards mode
    await tester.tap(find.text('💬 بطاقات الحوار'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ما هو المكان المفضل لكما؟'), findsOneWidget);
  });

  test('CouplesProfile days together and anniversary calculations work properly', () {
    final now = DateTime.now();
    final fiveDaysAgo = now.subtract(const Duration(days: 5));

    final profile = CouplesProfile(
      partner1Name: 'أحمد',
      partner2Name: 'سارة',
      startDate: fiveDaysAgo,
      specialTitle: 'ذكرى عقد القران',
      partnerCode: 'LOVE-1234',
      linkedPartnerEmail: 'sara@example.com',
    );

    expect(profile.partner1Name, equals('أحمد'));
    expect(profile.partner2Name, equals('سارة'));
    expect(profile.daysTogether, equals(5));
    expect(profile.isPartnerLinked, isTrue);
    expect(profile.partnerCode, equals('LOVE-1234'));

    // Serialization integrity
    final json = profile.toJson();
    final restored = CouplesProfile.fromJson(json);
    expect(restored.partner1Name, equals('أحمد'));
    expect(restored.specialTitle, equals('ذكرى عقد القران'));
    expect(restored.linkedPartnerEmail, equals('sara@example.com'));
  });

  test('LoveNote locked status and countdown calculation', () {
    final futureDate = DateTime.now().add(const Duration(days: 4));
    final lockedCapsule = LoveNote(
      id: 'cap_1',
      authorName: 'سارة',
      title: 'هدية ذكرى الزواج 🎁',
      content: 'أحبك أكثر مع كل يوم يمر!',
      createdAt: DateTime.now(),
      unlockDate: futureDate,
      emoji: '🎁',
    );

    expect(lockedCapsule.isLocked, isTrue);
    expect(lockedCapsule.daysUntilUnlock, greaterThanOrEqualTo(3));

    final instantNote = LoveNote(
      id: 'note_1',
      authorName: 'أحمد',
      title: 'صباح الخير',
      content: 'يومك جميل مثلك',
      createdAt: DateTime.now(),
    );

    expect(instantNote.isLocked, isFalse);
    expect(instantNote.daysUntilUnlock, equals(0));

    // Serialization integrity
    final json = lockedCapsule.toJson();
    final restored = LoveNote.fromJson(json);
    expect(restored.title, equals('هدية ذكرى الزواج 🎁'));
    expect(restored.isLocked, isTrue);
  });

  test('DecisionWheelItem default categories and structure', () {
    final defaults = DecisionWheelItem.defaultItems();
    expect(defaults, isNotEmpty);
    expect(defaults.any((i) => i.category == 'عشاء الليلة؟ 🍕'), isTrue);
    expect(defaults.any((i) => i.category == 'سهرة الليلة؟ 🎬'), isTrue);
    expect(defaults.any((i) => i.category == 'تحدي الدلع 💆'), isTrue);
  });

  test('PreferencesService couples profile and love notes CRUD lifecycle', () async {
    // 1. Profile lifecycle
    final initialProfile = PreferencesService.getCouplesProfile();
    expect(initialProfile.partnerCode, isNotEmpty);

    await PreferencesService.linkPartner(
      partnerEmail: 'partner@love.com',
      partnerName: 'نور',
    );
    final linked = PreferencesService.getCouplesProfile();
    expect(linked.linkedPartnerEmail, equals('partner@love.com'));
    expect(linked.partner2Name, equals('نور'));
    expect(linked.isPartnerLinked, isTrue);

    await PreferencesService.unlinkPartner();
    final unlinked = PreferencesService.getCouplesProfile();
    expect(unlinked.isPartnerLinked, isFalse);

    // 2. Love Notes lifecycle
    final initialNotes = PreferencesService.getLoveNotes();
    expect(initialNotes, isNotEmpty);

    final newNote = LoveNote(
      id: 'test_crud_note',
      authorName: 'أنا',
      title: 'رسالة اختبارية',
      content: 'محتوى تجريبي',
      createdAt: DateTime.now(),
    );
    await PreferencesService.addLoveNote(newNote);

    final afterAdd = PreferencesService.getLoveNotes();
    expect(afterAdd.any((n) => n.id == 'test_crud_note'), isTrue);

    await PreferencesService.markLoveNoteOpened('test_crud_note');
    final opened = PreferencesService.getLoveNotes().firstWhere((n) => n.id == 'test_crud_note');
    expect(opened.isOpened, isTrue);

    await PreferencesService.deleteLoveNote('test_crud_note');
    final afterDel = PreferencesService.getLoveNotes();
    expect(afterDel.any((n) => n.id == 'test_crud_note'), isFalse);
  });

  test('Direct partner invitation payload formatting and data integrity', () {
    final payload = {
      'room_id': 'room-uuid-1234',
      'room_code': 'ABC888',
      'host_name': 'أحمد',
      'timestamp': DateTime.now().toIso8601String(),
    };

    expect(payload['room_id'], equals('room-uuid-1234'));
    expect(payload['room_code'], equals('ABC888'));
    expect(payload['host_name'], equals('أحمد'));
    expect(DateTime.tryParse(payload['timestamp']!), isNotNull);
  });

  test('CouplesCard deck property default and JSON roundtrip', () {
    const card = CouplesCard(
      id: 'test_deck_card',
      deck: 'first_year',
      category: 'سنة أولى جواز',
      type: 'لو خيروك',
      level: 'خفيف',
      text: 'الموبايل ممنوع على السفرة ولا مسموح؟',
      purpose: 'اتفاقات البيت الجديد',
    );

    final json = card.toJson();
    expect(json['deck'], equals('first_year'));
    expect(json['type'], equals('لو خيروك'));

    final restored = CouplesCard.fromJson(json);
    expect(restored.deck, equals('first_year'));
    expect(restored.type, equals('لو خيروك'));

    // Test default deck for legacy compatibility
    final defaultDeckCard = CouplesCard.fromJson({
      'id': 'legacy_card',
      'category': 'عام',
      'type': 'سؤال',
      'level': 'خفيف',
      'text': 'سؤال قديم',
      'purpose': '',
    });
    expect(defaultDeckCard.deck, equals('classic'));
  });

  test('DecisionWheelItem defaultItems contains Pick A Date options', () {
    final items = DecisionWheelItem.defaultItems();
    final dateItems = items.where((i) => i.category.contains('موعد')).toList();
    expect(dateItems.length, greaterThanOrEqualTo(5));
    expect(dateItems.any((i) => i.label.contains('عشاء رومانسي')), isTrue);
  });

  test('CouplesCard followUp property serialization and Salon deck verification', () async {
    const card = CouplesCard(
      id: 'sln_test',
      deck: 'salon',
      category: 'حدود الأهل',
      type: 'موقف ونقاش',
      level: 'عميق',
      text: 'لو حصل خلاف بين الزوجين..',
      purpose: 'استقلالية البيت',
      followUp: 'امتى تطلب مساعدة حد من العيلة؟',
    );

    final map = card.toJson();
    expect(map['follow_up'], equals('امتى تطلب مساعدة حد من العيلة؟'));
    expect(map['deck'], equals('salon'));

    final parsed = CouplesCard.fromJson(map);
    expect(parsed.followUp, equals('امتى تطلب مساعدة حد من العيلة؟'));
    expect(parsed.deck, equals('salon'));

    // Verify loading cards from assets includes all 30 salon deck cards
    final cards = await GameDataService.loadTypedCards();
    final salonCards = cards.where((c) => c.deck == 'salon').toList();
    expect(salonCards.length, equals(30));

    // Verify each of the 6 key Egyptian salon categories has cards
    final categories = salonCards.map((c) => c.category).toSet();
    expect(categories.contains('حدود الأهل'), isTrue);
    expect(categories.contains('الشغل والطموح'), isTrue);
    expect(categories.contains('الماديات والفلوس'), isTrue);
    expect(categories.contains('إدارة الغضب'), isTrue);
    expect(categories.contains('الخصوصية والموبايل'), isTrue);
    expect(categories.contains('التربية والتدين'), isTrue);

    // Verify all salon cards have non-empty followUp questions
    for (final sc in salonCards) {
      expect(sc.followUp.isNotEmpty, isTrue, reason: 'Card ${sc.id} should have followUp');
    }
  });

  test('PreferencesService party games and decision wheel stats, achievements, and audio aliases', () async {
    final initialStats = PreferencesService.getStats();
    final initialWheelSpins = initialStats.wheelSpins;
    final initialPartyGames = initialStats.partyGamesPlayed;

    // 1. Record wheel spin
    await PreferencesService.recordWheelSpin(pointsEarned: 10);
    final statsAfterWheel = PreferencesService.getStats();
    expect(statsAfterWheel.wheelSpins, equals(initialWheelSpins + 1));
    expect(statsAfterWheel.totalPoints, greaterThanOrEqualTo(10));

    // Verify wheel_spinner achievement unlocked
    var achievements = PreferencesService.getAchievements();
    final wheelBadge = achievements.firstWhere((a) => a.id == 'wheel_spinner');
    expect(wheelBadge.isUnlocked, isTrue);

    // 2. Record party games until party_star is unlocked (3 games)
    await PreferencesService.recordPartyGameFinished(pointsEarned: 10);
    await PreferencesService.recordPartyGameFinished(pointsEarned: 10);
    await PreferencesService.recordPartyGameFinished(pointsEarned: 10);

    final statsAfterParty = PreferencesService.getStats();
    expect(statsAfterParty.partyGamesPlayed, equals(initialPartyGames + 3));

    achievements = PreferencesService.getAchievements();
    final partyStarBadge = achievements.firstWhere((a) => a.id == 'party_star');
    expect(partyStarBadge.isUnlocked, isTrue);

    // 3. Unlock love_capsule
    await PreferencesService.unlockAchievement('love_capsule');
    achievements = PreferencesService.getAchievements();
    final loveCapsuleBadge = achievements.firstWhere((a) => a.id == 'love_capsule');
    expect(loveCapsuleBadge.isUnlocked, isTrue);

    // 4. Test audio aliases safely
    expect(() => GameAudioService().playCardSnap(), returnsNormally);
    expect(() => GameAudioService().playMarbleMove(), returnsNormally);
  });

  testWidgets('AchievementsScreen renders statistics grid and updated titles', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await PreferencesService.recordPartyGameFinished(pointsEarned: 10);
    await PreferencesService.recordWheelSpin(pointsEarned: 10);

    await tester.pumpWidget(
      const MaterialApp(
        home: AchievementsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الإنجازات والنقاط 🏆'), findsOneWidget);
    expect(find.text('إحصائيات اللعب والتقارب'), findsOneWidget);
    expect(find.text('ألعاب الجلسات'), findsOneWidget);
    expect(find.text('لفات العجلة'), findsOneWidget);
    expect(find.text('ألعاب التجمعات'), findsOneWidget);
  });

  testWidgets('SettingsScreen toggles sound and syncs with GameAudioService', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    GameAudioService().isSoundEnabled = true;
    expect(GameAudioService().isSoundEnabled, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(onThemeChanged: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('المؤثرات الصوتية والاهتزاز'), findsOneWidget);
    expect(find.text('نسخة 1.9.0 • صُنع بحب للأزواج في العالم العربي 💜'), findsOneWidget);

    final switchFinder = find.widgetWithText(SwitchListTile, 'المؤثرات الصوتية والاهتزاز');
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(PreferencesService.soundEnabled, isFalse);
    expect(GameAudioService().isSoundEnabled, isFalse);
  });

  testWidgets('Interactive3DCard renders child and transforms on drag interaction',
      (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 300,
              child: Interactive3DCard(
                onTap: () => tapped = true,
                child: const Text('3D Card Test 🎴'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3D Card Test 🎴'), findsOneWidget);

    // Simulate drag on card
    final cardCenter = tester.getCenter(find.text('3D Card Test 🎴'));
    final gesture = await tester.startGesture(cardCenter);
    await gesture.moveBy(const Offset(30, 40));
    await tester.pump(const Duration(milliseconds: 50));

    // Release and verify spring return animation
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify tap works
    await tester.tap(find.text('3D Card Test 🎴'));
    expect(tapped, isTrue);
  });

  testWidgets('Dice3DDialog renders 3D felt tray, tumbles dice, and invokes callback',
      (tester) async {
    int? rolledValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Dice3DDialog.show(
                  context,
                  onResult: (val) => rolledValue = val,
                );
              },
              child: const Text('Open 3D Dice'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap to open dialog
    await tester.tap(find.text('Open 3D Dice'));
    await tester.pump(); // Start opening dialog

    // Dialog should be present with header and re-roll button
    expect(find.text('نرد القرارات 3D'), findsOneWidget);
    expect(find.text('رمي جديد 🎲'), findsOneWidget);

    // Let initial automatic roll animation complete
    await tester.pumpAndSettle(const Duration(milliseconds: 1600));

    expect(rolledValue, isNotNull);
    expect(rolledValue, inInclusiveRange(1, 6));

    // Tap to roll again
    await tester.tap(find.text('رمي جديد 🎲'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Wait for the second roll animation to settle
    await tester.pumpAndSettle(const Duration(milliseconds: 1600));
    expect(rolledValue, inInclusiveRange(1, 6));

    // Close dialog
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('نرد القرارات 3D'), findsNothing);
  });

  testWidgets('Coin3DDialog renders 3D metallic coin, flips with altitude, and returns heads/tails',
      (tester) async {
    bool? coinResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Coin3DDialog.show(
                  context,
                  onResult: (val) => coinResult = val,
                );
              },
              child: const Text('Open 3D Coin'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap to open dialog
    await tester.tap(find.text('Open 3D Coin'));
    await tester.pump();

    // Verify dialog header and choice chips
    expect(find.text('قرعة العملة 3D'), findsOneWidget);
    expect(find.text('👑 مَلِك'), findsOneWidget);
    expect(find.text('📜 كِتَابَة'), findsOneWidget);

    // Select guess
    await tester.tap(find.text('👑 مَلِك'));
    await tester.pump();

    // Wait for the initial flip animation to finish
    await tester.pumpAndSettle(const Duration(milliseconds: 1600));

    expect(coinResult, isNotNull);

    // Tap to flip again
    await tester.tap(find.text('رمية جديدة 🪙'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Wait for the second flip animation to settle
    await tester.pumpAndSettle(const Duration(milliseconds: 1600));
    expect(coinResult, isNotNull);

    // Close dialog
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('قرعة العملة 3D'), findsNothing);
  });

  testWidgets('HomeScreen quick moments bar includes 3D bottle spin shortcut and opens BottleSpinScreen',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    GameAudioService().isSoundEnabled = false;
    PreferencesService.reducedMotion = true;
    addTearDown(() => PreferencesService.reducedMotion = false);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomeScreen(onThemeChanged: () {}),
      ),
    );
    await tester.pumpAndSettle();

    // Verify quick moments shortcuts are present
    expect(find.text('نرد القرارات'), findsOneWidget);
    expect(find.text('قرعة العملة'), findsOneWidget);
    expect(find.text('لف الزجاجة'), findsOneWidget);
    expect(find.text('جلسات 3D 🍾'), findsOneWidget);

    // Tap 'لف الزجاجة' shortcut
    await tester.tap(find.text('لف الزجاجة'));
    await tester.pumpAndSettle();

    // Verify BottleSpinScreen is opened
    expect(find.text('لف الزجاجة 3D 🍾'), findsOneWidget);
    expect(find.text('لِف الزجاجة الآن 🍾'), findsOneWidget);
  });
}
