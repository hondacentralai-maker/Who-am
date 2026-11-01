import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_couples_game/widgets/jackaroo_3d_board_view.dart';
import 'package:arabic_couples_game/screens/party_games/jackaroo_3d_screen.dart';

void main() {
  group('Jackaroo 92-Hole Authentic Board Tests', () {
    testWidgets('Jackaroo3DBoardView initializes 92 holes and 16 glass marbles', (tester) async {
      final GlobalKey<Jackaroo3DBoardViewState> boardKey = GlobalKey<Jackaroo3DBoardViewState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Jackaroo3DBoardView(
              key: boardKey,
              isTopDownView: true,
              activeCard: 'A♠',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Jackaroo3DBoardView), findsOneWidget);

      final state = boardKey.currentState;
      expect(state, isNotNull);

      // Verify exact 76 track holes + 16 safe zone holes = 92 holes on the board surface
      final track = state!.trackCoordinates;
      final safe = state.safeZoneCoordinates;
      final home = state.homeCoordinates;

      expect(track.length, equals(76), reason: 'Track must have 76 holes (19 per quadrant)');
      expect(safe.length, equals(16), reason: 'Safe zone must have 16 holes (4 per arm)');
      expect(track.length + safe.length, equals(92), reason: 'Total board holes must be exactly 92');
      expect(home.length, equals(16), reason: '4 corner dishes must hold 16 home slots');

      // Verify the corner holes on the South arm tip (y = 500 + 422 = 922)
      // Left corner: x = 500 - 72 = 428, y = 922
      // Right corner: x = 500 + 72 = 572, y = 922
      final southLeftCorner = track[0]!;
      expect(southLeftCorner.dx, closeTo(428.0, 1.0));
      expect(southLeftCorner.dy, closeTo(922.0, 1.0));

      final southRightCorner = track[73]!; // Quad 3 idx 16
      expect(southRightCorner.dx, closeTo(572.0, 1.0));
      expect(southRightCorner.dy, closeTo(922.0, 1.0));
    });

    testWidgets('Jackaroo3DScreen renders with 92-hole board and view toggles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Jackaroo3DScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Jackaroo3DBoardView), findsOneWidget);
      expect(find.text('جاكارو 92 حفرة الواقعية'), findsOneWidget);
      expect(find.text('مظهر الصورة'), findsOneWidget);
    });
  });
}
