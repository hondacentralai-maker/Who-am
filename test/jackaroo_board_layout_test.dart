import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_couples_game/models/jackaroo_board_layout.dart';

void main() {
  test(
    '76 unique outer holes, 16 inner holes and four complete 1–18 sections',
    () {
      expect(JackarooBoardLayout.track.length, 76);
      final all = [
        ...JackarooBoardLayout.track,
        ...JackarooBoardLayout.safe.expand((lane) => lane),
      ];
      expect(all.toSet().length, 92);
      for (var section = 0; section < 4; section++) {
        final start = section * 19;
        expect(JackarooBoardLayout.numberAt(start), isNull);
        expect([
          for (var i = 1; i <= 18; i++) JackarooBoardLayout.numberAt(start + i),
        ], List.generate(18, (i) => i + 1));
      }
      // The four photographed diagonal 9s, not a symmetric approximation.
      expect(
        [
          for (final index in [9, 28, 47, 66]) JackarooBoardLayout.track[index],
        ],
        [
          const Offset(405, 709),
          const Offset(517, 384),
          const Offset(845, 479),
          const Offset(749, 809),
        ],
      );
    },
  );

  test('all coordinates lie inside the source image', () {
    final bounds = Offset.zero & JackarooBoardLayout.referenceSize;
    final points = [
      ...JackarooBoardLayout.track,
      ...JackarooBoardLayout.home.expand((lane) => lane),
      ...JackarooBoardLayout.safe.expand((lane) => lane),
    ];
    expect(points.every(bounds.contains), isTrue);
  });

  test('contain uses photograph aspect ratio and centers letterboxing', () {
    for (final viewport in [
      const Size(320, 568),
      const Size(1024, 600),
      const Size(800, 800),
    ]) {
      final rect = JackarooBoardLayout.fittedRect(viewport);
      expect(rect.width / rect.height, closeTo(1232 / 1277, 0.00001));
      expect(rect.center.dx, closeTo(viewport.width / 2, 0.00001));
      expect(rect.center.dy, closeTo(viewport.height / 2, 0.00001));
      expect(rect.width <= viewport.width, isTrue);
      expect(rect.height <= viewport.height + 0.00001, isTrue);
      final scale = rect.width / 1232;
      for (final point in JackarooBoardLayout.track) {
        final rendered = rect.topLeft + point * scale;
        expect(
          ((rendered - rect.topLeft) / scale - point).distance,
          lessThan(0.0001),
        );
      }
    }
  });

  test(
    'each home lane branches from the aligned gate, after landing on it',
    () {
      for (var owner = 0; owner < 4; owner++) {
        final gate = JackarooBoardLayout.gateFor(owner);
        final path = JackarooBoardLayout.route(
          owner: owner,
          position: (gate - 1) % 76,
          steps: 2,
        )!;
        expect(path[0].index, gate);
        expect(path[0].inSafe, isFalse);
        expect(path[1].index, 0);
        expect(path[1].inSafe, isTrue);
        expect(path[1].pointFor(owner), JackarooBoardLayout.safe[owner][0]);
      }
    },
  );

  test('route follows every hole through corner and into safety', () {
    final path = JackarooBoardLayout.route(owner: 0, position: 72, steps: 6)!;
    expect(path.map((s) => s.index), [73, 74, 0, 1, 2, 3]);
    expect(path.map((s) => s.inSafe), [false, false, true, true, true, true]);
    expect(JackarooBoardLayout.route(owner: 0, position: 72, steps: 7), isNull);
    expect(
      JackarooBoardLayout.route(owner: 0, position: 3, steps: 1, inSafe: true),
      isNull,
    );
    expect(
      JackarooBoardLayout.route(owner: 0, position: 2, steps: -4, inSafe: true),
      isNull,
    );
  });

  test('backward four wraps the outer track without entering a home lane', () {
    final path = JackarooBoardLayout.route(owner: 0, position: 0, steps: -4)!;
    expect(path.map((s) => s.index), [75, 74, 73, 72]);
    expect(path.any((s) => s.inSafe), isFalse);
  });
}
