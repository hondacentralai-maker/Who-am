import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'preferences_service.dart';

/// خدمة الصوتيات التخليقية بدون أي ملفات خارجية (Zero External Assets)
class GameAudioService {
  static final GameAudioService _instance = GameAudioService._internal();
  factory GameAudioService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  bool _localSoundEnabled = true;

  bool get isSoundEnabled {
    try {
      return PreferencesService.soundEnabled;
    } catch (_) {
      return _localSoundEnabled;
    }
  }

  set isSoundEnabled(bool value) {
    _localSoundEnabled = value;
    try {
      PreferencesService.setSoundEnabled(value);
    } catch (_) {}
  }

  Uint8List? _cachedDealWav;
  Uint8List? _cachedPlaceWav;
  Uint8List? _cachedStepWav;
  Uint8List? _cachedEatWav;
  Uint8List? _cachedBuzzerWav;
  Uint8List? _cachedWinWav;
  Uint8List? _cachedTapWav;
  Uint8List? _cachedSuccessWav;
  Uint8List? _cachedTickWav;

  GameAudioService._internal() {
    _initPrecomputedWavs();
  }

  void _initPrecomputedWavs() {
    _cachedDealWav = _generateWhiteNoiseSnap(
      durationMs: 70,
      startFreq: 800,
      decayRate: 35.0,
      volume: 0.25,
    );
    _cachedPlaceWav = _generateToneWav(
      freq: 320,
      durationMs: 90,
      decayRate: 25.0,
      volume: 0.45,
    );
    _cachedStepWav = _generateToneWav(
      freq: 640,
      durationMs: 45,
      decayRate: 40.0,
      volume: 0.35,
    );
    _cachedEatWav = _generateTwoToneImpactWav(
      freq1: 480,
      freq2: 160,
      durationMs: 140,
      volume: 0.55,
    );
    _cachedBuzzerWav = _generateToneWav(
      freq: 110,
      durationMs: 200,
      decayRate: 6.0,
      volume: 0.40,
    );
    _cachedWinWav = _generateMajorFanfareWav();
    _cachedTapWav = _generateToneWav(
      freq: 1100,
      durationMs: 30,
      decayRate: 50.0,
      volume: 0.22,
    );
    _cachedSuccessWav = _generateHarmonicChimeWav();
    _cachedTickWav = _generateToneWav(
      freq: 880,
      durationMs: 24,
      decayRate: 45.0,
      volume: 0.28,
    );
  }

  Future<void> playTap() async {
    if (!isSoundEnabled || _cachedTapWav == null) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(_cachedTapWav!));
    } catch (_) {}
  }

  Future<void> playSuccess() async {
    if (!isSoundEnabled || _cachedSuccessWav == null) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(_cachedSuccessWav!));
    } catch (_) {}
  }

  Future<void> playTick() async {
    if (!isSoundEnabled || _cachedTickWav == null) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(_cachedTickWav!));
    } catch (_) {}
  }

  Future<void> playCardDeal() async {
    if (!isSoundEnabled || _cachedDealWav == null) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(_cachedDealWav!));
    } catch (_) {}
  }

  Future<void> playCardSnap() => playCardDeal();

  Future<void> playCardPlace() async {
    if (!isSoundEnabled || _cachedPlaceWav == null) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(_cachedPlaceWav!));
    } catch (_) {}
  }

  Future<void> playMarbleStep() async {
    if (!isSoundEnabled || _cachedStepWav == null) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(_cachedStepWav!));
    } catch (_) {}
  }

  Future<void> playMarbleMove() => playMarbleStep();

  Future<void> playMarbleEat() async {
    if (!isSoundEnabled || _cachedEatWav == null) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(_cachedEatWav!));
    } catch (_) {}
  }

  Future<void> playBuzzer() async {
    if (!isSoundEnabled || _cachedBuzzerWav == null) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(_cachedBuzzerWav!));
    } catch (_) {}
  }

  Future<void> playWin() async {
    if (!isSoundEnabled || _cachedWinWav == null) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(_cachedWinWav!));
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  توليد موجات الصوت الرقمية PCM WAV 16-Bit في الذاكرة
  // ════════════════════════════════════════════════════════════════════════════

  static Uint8List _generateToneWav({
    required double freq,
    required int durationMs,
    required double decayRate,
    double volume = 0.5,
  }) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * (durationMs / 1000.0)).toInt();
    final pcmBytes = Int16List(totalSamples);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final envelope = exp(-decayRate * t);
      final sample = sin(2 * pi * freq * t) * envelope * volume;
      pcmBytes[i] = (sample * 32767).toInt().clamp(-32768, 32767);
    }

    return _buildWavHeader(sampleRate: sampleRate, pcmData: pcmBytes);
  }

  static Uint8List _generateTwoToneImpactWav({
    required double freq1,
    required double freq2,
    required int durationMs,
    double volume = 0.5,
  }) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * (durationMs / 1000.0)).toInt();
    final pcmBytes = Int16List(totalSamples);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env1 = exp(-28.0 * t);
      final env2 = exp(-14.0 * t);
      final s1 = sin(2 * pi * freq1 * t) * env1 * 0.6;
      final s2 = sin(2 * pi * freq2 * t) * env2 * 0.4;
      final sample = (s1 + s2) * volume;
      pcmBytes[i] = (sample * 32767).toInt().clamp(-32768, 32767);
    }

    return _buildWavHeader(sampleRate: sampleRate, pcmData: pcmBytes);
  }

  static Uint8List _generateWhiteNoiseSnap({
    required int durationMs,
    required double startFreq,
    required double decayRate,
    double volume = 0.5,
  }) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * (durationMs / 1000.0)).toInt();
    final pcmBytes = Int16List(totalSamples);
    final rng = Random();

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final envelope = exp(-decayRate * t);
      final whiteNoise = (rng.nextDouble() * 2.0 - 1.0);
      final sample = whiteNoise * envelope * volume;
      pcmBytes[i] = (sample * 32767).toInt().clamp(-32768, 32767);
    }

    return _buildWavHeader(sampleRate: sampleRate, pcmData: pcmBytes);
  }

  static Uint8List _generateHarmonicChimeWav() {
    const sampleRate = 22050;
    const durationMs = 280;
    final totalSamples = (sampleRate * (durationMs / 1000.0)).toInt();
    final pcmBytes = Int16List(totalSamples);
    const freq1 = 659.25;
    const freq2 = 987.77;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final envelope = exp(-11.0 * t);
      final s1 = sin(2 * pi * freq1 * t) * 0.5;
      final s2 = sin(2 * pi * freq2 * t) * 0.35;
      final sample = (s1 + s2) * envelope * 0.45;
      pcmBytes[i] = (sample * 32767).toInt().clamp(-32768, 32767);
    }

    return _buildWavHeader(sampleRate: sampleRate, pcmData: pcmBytes);
  }

  static Uint8List _generateMajorFanfareWav() {
    const sampleRate = 22050;
    final notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
    const noteDurationMs = 110;
    const totalDurationMs = 700;
    final totalSamples = (sampleRate * (totalDurationMs / 1000.0)).toInt();
    final pcmBytes = Int16List(totalSamples);

    for (int n = 0; n < notes.length; n++) {
      final freq = notes[n];
      final startSample = (sampleRate * (n * noteDurationMs / 1000.0)).toInt();
      final endSample = totalSamples;

      for (int i = startSample; i < endSample; i++) {
        final t = (i - startSample) / sampleRate;
        final envelope = exp(-5.0 * t);
        final sample = sin(2 * pi * freq * t) * envelope * 0.22;
        final existing = pcmBytes[i] / 32767.0;
        final combined = existing + sample;
        pcmBytes[i] = (combined * 32767).toInt().clamp(-32768, 32767);
      }
    }

    return _buildWavHeader(sampleRate: sampleRate, pcmData: pcmBytes);
  }

  static Uint8List _buildWavHeader({
    required int sampleRate,
    required Int16List pcmData,
  }) {
    final byteData = ByteData(44 + pcmData.lengthInBytes);
    final dataSize = pcmData.lengthInBytes;
    final fileSize = 36 + dataSize;

    // RIFF
    byteData.setUint8(0, 0x52); // R
    byteData.setUint8(1, 0x49); // I
    byteData.setUint8(2, 0x46); // F
    byteData.setUint8(3, 0x46); // F
    byteData.setUint32(4, fileSize, Endian.little);
    byteData.setUint8(8, 0x57);  // W
    byteData.setUint8(9, 0x41);  // A
    byteData.setUint8(10, 0x56); // V
    byteData.setUint8(11, 0x45); // E

    // fmt chunk
    byteData.setUint8(12, 0x66); // f
    byteData.setUint8(13, 0x6D); // m
    byteData.setUint8(14, 0x74); // t
    byteData.setUint8(15, 0x20); // space
    byteData.setUint32(16, 16, Endian.little); // chunk size
    byteData.setUint16(20, 1, Endian.little);  // PCM format
    byteData.setUint16(22, 1, Endian.little);  // Mono
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little); // Byte rate
    byteData.setUint16(32, 2, Endian.little);  // Block align
    byteData.setUint16(34, 16, Endian.little); // Bits per sample

    // data chunk
    byteData.setUint8(36, 0x64); // d
    byteData.setUint8(37, 0x61); // a
    byteData.setUint8(38, 0x74); // t
    byteData.setUint8(39, 0x61); // a
    byteData.setUint32(40, dataSize, Endian.little);

    // Copy PCM bytes
    final rawBuffer = byteData.buffer.asUint8List();
    rawBuffer.setRange(44, 44 + dataSize, pcmData.buffer.asUint8List());

    return rawBuffer;
  }
}
