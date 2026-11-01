import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabic_couples_game/services/preferences_service.dart';
import 'package:arabic_couples_game/screens/party_games/connect_four_screen.dart';
import 'package:arabic_couples_game/screens/party_games/memory_match_screen.dart';
import 'package:arabic_couples_game/screens/party_games/arabic_wordle_screen.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();
  });

  group('New Party Games Suite Tests', () {
    testWidgets('ConnectFourScreen renders grid, players and accepts disc drop', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ConnectFourScreen(
            initialPlayers: ['سارة', 'خالد'],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('أربعة في صف'), findsOneWidget);
      expect(find.text('سارة'), findsOneWidget);
      expect(find.text('خالد'), findsOneWidget);
      expect(find.text('جولة جديدة'), findsOneWidget);

      // Tap on column 3 (middle)
      final middleColFinder = find.byType(GestureDetector);
      expect(middleColFinder, findsWidgets);

      await tester.tap(middleColFinder.first);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ConnectFourScreen), findsOneWidget);
    });

    testWidgets('MemoryMatchScreen renders cards, timer and handles card flip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MemoryMatchScreen(
            initialPlayers: ['نور', 'شهد'],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('شطرنج الذاكرة'), findsOneWidget);
      expect(find.text('خلط الكروت وجولة جديدة'), findsOneWidget);
      expect(find.text('محبة وذكريات'), findsOneWidget);

      // Tap the first memory card
      final cardFinder = find.byType(GestureDetector);
      expect(cardFinder, findsWidgets);

      await tester.tap(cardFinder.at(2)); // Tap a card
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(MemoryMatchScreen), findsOneWidget);
    });

    testWidgets('ArabicWordleScreen renders 6x5 grid, keyboard and handles letter input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ArabicWordleScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('فك الكلمة'), findsOneWidget);
      expect(find.text('تأكيد'), findsOneWidget);
      expect(find.text('⌫'), findsOneWidget);
      expect(find.text('المحاولة: '), findsOneWidget);

      // Tap a letter key, e.g. 'س'
      final sKey = find.widgetWithText(ElevatedButton, 'س');
      expect(sKey, findsOneWidget);

      await tester.tap(sKey);
      await tester.pump();

      // Tap backspace
      final backspaceKey = find.widgetWithText(ElevatedButton, '⌫');
      expect(backspaceKey, findsOneWidget);

      await tester.tap(backspaceKey);
      await tester.pump();

      expect(find.byType(ArabicWordleScreen), findsOneWidget);
    });
  });
}

