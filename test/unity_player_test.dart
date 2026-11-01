import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arabic_couples_game/services/game_audio_service.dart';
import 'package:arabic_couples_game/services/preferences_service.dart';
import 'package:arabic_couples_game/widgets/unity/unity_player.dart';
import 'package:arabic_couples_game/screens/party_games/jackaroo_3d_screen.dart';

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
    SharedPreferences.setMockInitialValues({'sound_enabled': false});
    await PreferencesService.init();
  });

  group('UnityMessage Tests', () {
    test('creates and serializes message correctly', () {
      final msg = UnityMessage.json(
        gameObject: 'JackarooBoard',
        methodName: 'PlayCard',
        data: {'card': 'King', 'targetPlayer': 2},
      );

      expect(msg.gameObject, 'JackarooBoard');
      expect(msg.methodName, 'PlayCard');
      expect(msg.payloadJson['card'], 'King');
      expect(msg.payloadJson['targetPlayer'], 2);
      expect(msg.toJsonString(), contains('JackarooBoard'));
    });

    test('parses raw text and json gracefully', () {
      const rawJson = '{"gameObject": "Camera", "methodName": "SetFov", "payload": "60"}';
      final parsed = UnityMessage.fromRaw(rawJson);
      expect(parsed.gameObject, 'Camera');
      expect(parsed.methodName, 'SetFov');
      expect(parsed.payload, '60');

      const rawPlain = 'plain string from unity';
      final plainMsg = UnityMessage.fromRaw(rawPlain);
      expect(plainMsg.payload, 'plain string from unity');
      expect(plainMsg.gameObject, 'FlutterManager');
    });
  });

  group('UnityPlayerController Tests', () {
    late UnityPlayerController controller;

    setUp(() {
      controller = UnityPlayerController(isMock: true);
    });

    tearDown(() {
      controller.dispose();
    });

    test('initializes into ready status in mock mode', () async {
      expect(controller.status, UnityPlayerStatus.uninitialized);
      await controller.initialize();
      expect(controller.status, UnityPlayerStatus.ready);
      expect(controller.isReady, isTrue);
    });

    test('posts message and logs history', () async {
      await controller.initialize();
      final success = await controller.postJson('GameManager', 'StartGame', {'players': 4});

      expect(success, isTrue);
      expect(controller.messageLog.length, 1);
      expect(controller.messageLog.first.gameObject, 'GameManager');
    });

    test('handles pause, resume, and unload transitions', () async {
      await controller.initialize();

      await controller.pause();
      expect(controller.status, UnityPlayerStatus.paused);

      await controller.resume();
      expect(controller.status, UnityPlayerStatus.ready);

      await controller.unload();
      expect(controller.status, UnityPlayerStatus.unloaded);
    });

    test('dispatches simulated incoming messages', () async {
      await controller.initialize();

      UnityMessage? received;
      controller.messageStream.listen((msg) {
        received = msg;
      });

      final testMsg = UnityMessage(
        gameObject: 'JackarooBoard',
        methodName: 'OnMarbleReachedBase',
        payload: '{"marbleId": 3}',
      );

      controller.simulateIncomingMessage(testMsg);
      await Future<void>.delayed(Duration.zero);

      expect(received, isNotNull);
      expect(received?.gameObject, 'JackarooBoard');
      expect(received?.methodName, 'OnMarbleReachedBase');
    });
  });

  group('UnityPlayerWidget Widget Tests', () {
    testWidgets('renders simulation view and triggers onUnityCreated', (tester) async {
      bool createdCalled = false;
      UnityPlayerController? capturedController;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnityPlayerWidget(
              isMock: true,
              enableMockInUnsupported: true,
              initialScene: 'Jackaroo3D',
              onUnityCreated: (ctrl) {
                createdCalled = true;
                capturedController = ctrl;
              },
            ),
          ),
        ),
      );

      // Wait for initialization timer
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Unity 3D Engine Viewport'), findsOneWidget);
      expect(find.text('Active Scene: Jackaroo3D'), findsOneWidget);
      expect(createdCalled, isTrue);
      expect(capturedController, isNotNull);
      expect(capturedController?.isReady, isTrue);
    });

    testWidgets('renders UnityViewOverlay with title and triggers exit and sound', (tester) async {
      bool exitTapped = false;
      bool soundToggled = false;
      bool soundState = true;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: UnityViewOverlay(
                  title: 'جاكارو 3D الاحترافية',
                  subtitle: 'غرفة #408',
                  isSoundEnabled: soundState,
                  onExit: () => exitTapped = true,
                  onToggleSound: () {
                    soundToggled = true;
                    setState(() => soundState = !soundState);
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('جاكارو 3D الاحترافية'), findsOneWidget);
      expect(find.text('غرفة #408'), findsOneWidget);

      // Tap exit button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      expect(exitTapped, isTrue);

      // Tap sound button
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      expect(soundToggled, isTrue);

      await tester.pump();
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    });

    testWidgets('Jackaroo3DScreen renders 3D viewport, hand cards, and reacts to card tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Jackaroo3DScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('جاكارو'), findsOneWidget);
      expect(find.text('أوراقك في اليد (اختر ورقة للعب):'), findsOneWidget);
      expect(find.text('A♠'), findsOneWidget);
      expect(find.text('K♥'), findsOneWidget);

      // Tap card A♠
      await tester.tap(find.text('A♠'));
      await tester.pump();

      expect(find.textContaining('تم اختيار A♠'), findsOneWidget);
    });
  });
}
