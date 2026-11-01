import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabic_couples_game/models/jackaroo_board_layout.dart';
import 'package:arabic_couples_game/services/preferences_service.dart';
import 'package:arabic_couples_game/widgets/jackaroo_3d_board_view.dart';
import 'package:arabic_couples_game/screens/party_games/jackaroo_3d_screen.dart';

Future<void> loadBoard(
  WidgetTester tester,
  GlobalKey<Jackaroo3DBoardViewState> key,
) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 100 && !key.currentState!.isImageLoaded; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  });
  await tester.pump();
  expect(key.currentState!.isImageLoaded, isTrue);
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final channel in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events'
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (_) async => 1);
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'),
            (call) async {
      if (call.method == 'create') {
        final id = (call.arguments as Map)['playerId'];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
                MethodChannel('xyz.luan/audioplayers/events/$id'),
                (_) async => null);
      }
      return 1;
    });
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_enabled': false});
    await PreferencesService.init();
    await PreferencesService.setSoundEnabled(false);
  });

  testWidgets(
    'initial board pixels are the approved image, including every number',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1232, 1277);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final key = GlobalKey<Jackaroo3DBoardViewState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Jackaroo3DBoardView(key: key)),
        ),
      );
      await loadBoard(tester, key);
      expect(key.currentState!.trackCoordinates.length, 76);
      expect(key.currentState!.safeZoneCoordinates.length, 16);
      expect(key.currentState!.homeCoordinates.length, 16);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('jackaroo-reference-paint')),
      );
      final equal = await tester.runAsync(() async {
        final captured = await boundary.toImage(pixelRatio: 1);
        final bytes = await rootBundle.load(JackarooBoardLayout.asset);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final source = (await codec.getNextFrame()).image;
        final actual = await captured.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final expected = await source.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final same = captured.width == source.width &&
            captured.height == source.height &&
            listEquals(
              actual!.buffer.asUint8List(),
              expected!.buffer.asUint8List(),
            );
        if (!same) {
          final png = await captured.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/jackaroo-screenshots/initial-actual.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
          debugPrint(
              'Reference: ${source.width}x${source.height}; rendered: ${captured.width}x${captured.height}; boundary: ${boundary.size}');
        }
        captured.dispose();
        source.dispose();
        codec.dispose();
        return same;
      });
      expect(
        equal,
        isTrue,
        reason: 'The default surface must preserve every reference pixel.',
      );
    },
  );

  testWidgets('first tap is aligned before any camera or repaint interaction', (
    tester,
  ) async {
    final key = GlobalKey<Jackaroo3DBoardViewState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Jackaroo3DBoardView(key: key, activeCard: 'A♠'),
        ),
      ),
    );
    await loadBoard(tester, key);
    final rect = tester.getRect(
      find.byKey(const ValueKey('jackaroo-reference-surface')),
    );
    final source = JackarooBoardLayout.home[0][0];
    await tester.tapAt(rect.topLeft + source * (rect.width / 1232));
    await tester.pump();
    expect(key.currentState!.isBusy, isTrue);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    final marble = key.currentState!.marbles.first;
    expect(marble.location, JackarooMarbleLocation.track);
    expect(marble.positionIndex, 0);
    expect(key.currentState!.isBusy, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restart cancels a move and restores the actual home positions', (
    tester,
  ) async {
    final key = GlobalKey<Jackaroo3DBoardViewState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Jackaroo3DBoardView(key: key)),
      ),
    );
    await loadBoard(tester, key);
    final rect = tester.getRect(
      find.byKey(const ValueKey('jackaroo-reference-surface')),
    );
    await tester.tapAt(
      rect.topLeft + JackarooBoardLayout.home[0][0] * (rect.width / 1232),
    );
    await tester.pump(const Duration(milliseconds: 30));
    key.currentState!.resetGame();
    await tester.pump(const Duration(seconds: 3));
    expect(key.currentState!.marbles.every((m) => m.isHome), isTrue);
    expect(key.currentState!.isBusy, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(1024, 600),
  ]) {
    testWidgets('screen keeps controls outside board at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final captureKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: const MaterialApp(home: Jackaroo3DScreen()),
        ),
      );
      final widget = tester.widget<Jackaroo3DBoardView>(
        find.byType(Jackaroo3DBoardView),
      );
      await loadBoard(
        tester,
        widget.key! as GlobalKey<Jackaroo3DBoardViewState>,
      );
      final board = tester.getRect(
        find.byKey(const ValueKey('jackaroo-reference-surface')),
      );
      for (var i = 0; i < 5; i++) {
        final card = tester.getRect(find.byKey(ValueKey('jackaroo-card-$i')));
        expect(board.overlaps(card), isFalse);
      }
      expect(board.width / board.height, closeTo(1232 / 1277, 0.00001));
      expect(find.text('مظهر الصورة'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (Platform.environment['JACKAROO_SCREENSHOTS'] == '1') {
        await tester.runAsync(() async {
          final boundary = captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'build/jackaroo-screenshots/${size.width.toInt()}x${size.height.toInt()}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    });
  }
}
