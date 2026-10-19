import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/party_game_models.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';

class StopGameScreen extends StatefulWidget {
  final String? initialLetter;
  final bool isOnline;
  final Function(String letter, Map<String, String> answers)? onStopSubmitted;

  const StopGameScreen({
    super.key,
    this.initialLetter,
    this.isOnline = false,
    this.onStopSubmitted,
  });

  @override
  State<StopGameScreen> createState() => _StopGameScreenState();
}

class _StopGameScreenState extends State<StopGameScreen> {
  late String _currentLetter;
  final Map<String, TextEditingController> _controllers = {};
  Timer? _timer;
  int _secondsRemaining = 90;
  bool _isRoundActive = false;
  final Random _random = Random();

  // Scoring review map: key -> score (0, 5, 10)
  final Map<String, int> _scores = {};

  @override
  void initState() {
    super.initState();
    for (final cat in StopGameData.defaultCategories) {
      _controllers[cat.key] = TextEditingController();
      _scores[cat.key] = 10;
    }
    _currentLetter = widget.initialLetter ?? StopGameData.arabicLetters[_random.nextInt(StopGameData.arabicLetters.length)];
    _startRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _startRound() {
    _timer?.cancel();
    for (final c in _controllers.values) {
      c.clear();
    }
    setState(() {
      _secondsRemaining = 90;
      _isRoundActive = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _triggerStop(isAutoTimeOut: true);
      }
    });
  }

  void _spinNewLetter() {
    PreferencesService.triggerHaptic(AppHapticType.medium);
    final newLetter = StopGameData.arabicLetters[_random.nextInt(StopGameData.arabicLetters.length)];
    setState(() {
      _currentLetter = newLetter;
    });
    _startRound();
  }

  void _triggerStop({bool isAutoTimeOut = false}) {
    _timer?.cancel();
    PreferencesService.triggerHaptic(AppHapticType.medium);

    // Initial default scoring: filled fields starting with letter get 10, empty get 0
    for (final cat in StopGameData.defaultCategories) {
      final text = _controllers[cat.key]?.text.trim() ?? '';
      if (text.isEmpty) {
        _scores[cat.key] = 0;
      } else {
        _scores[cat.key] = 10;
      }
    }

    setState(() {
      _isRoundActive = false;
    });

    if (widget.onStopSubmitted != null) {
      final answers = {
        for (final entry in _controllers.entries) entry.key: entry.value.text.trim()
      };
      widget.onStopSubmitted!(_currentLetter, answers);
    }

    _showScoringDialog(isAutoTimeOut: isAutoTimeOut);
  }

  int get _totalRoundScore {
    return _scores.values.fold<int>(0, (a, b) => a + b);
  }

  void _showScoringDialog({bool isAutoTimeOut = false}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final total = _totalRoundScore;

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAutoTimeOut ? '⏰ انتهى الوقت!' : '🛑 STOP! كومبليت!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'مراجعة إجابات حرف ($_currentLetter) واحتساب النقاط',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Category Rows with Score Selectors
                  ...StopGameData.defaultCategories.map((cat) {
                    final text = _controllers[cat.key]?.text.trim() ?? '';
                    final currentScore = _scores[cat.key] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.palePurple,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  text.isEmpty ? '— (فارغ)' : text,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: text.isEmpty ? Colors.redAccent : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Score buttons: 0, 5, 10
                          Row(
                            children: [0, 5, 10].map((pts) {
                              final isSel = currentScore == pts;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: ChoiceChip(
                                  label: Text('$pts'),
                                  selected: isSel,
                                  selectedColor: AppColors.purple,
                                  onSelected: (val) {
                                    if (val) {
                                      setModalState(() {
                                        _scores[cat.key] = pts;
                                      });
                                      setState(() {});
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Total Score Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'مجموع نقاط الجولة:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$total نقطة 🌟',
                          style: const TextStyle(
                            color: AppColors.accentGold,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _spinNewLetter();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('جولة جديدة مع حرف آخر 🎲'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنسان • حيوان • جماد 🛑'),
        actions: [
          IconButton(
            tooltip: 'تغيير الحرف',
            icon: const Icon(Icons.shuffle_rounded),
            onPressed: _spinNewLetter,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Letter & Timer Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF532488), Color(0xFF7E39D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppShadows.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentLetter,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.deepPurple,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الحرف المطلوب',
                            style: TextStyle(color: Color(0xFFE6DFFF), fontSize: 11),
                          ),
                          Text(
                            'حرف ($_currentLetter)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Timer Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _secondsRemaining <= 15
                          ? Colors.redAccent.withValues(alpha: 0.9)
                          : Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '$_secondsRemaining ث',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Input Fields List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: StopGameData.defaultCategories.length,
                itemBuilder: (context, idx) {
                  final cat = StopGameData.defaultCategories[idx];
                  final ctrl = _controllers[cat.key];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: AppDecorations.outlinedCard(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: TextField(
                        controller: ctrl,
                        enabled: _isRoundActive,
                        decoration: InputDecoration(
                          prefixIcon: Text(
                            cat.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 42),
                          labelText: cat.label,
                          hintText: 'يبدأ بحرف ($_currentLetter)...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Giant Red STOP Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _isRoundActive ? () => _triggerStop() : null,
                  icon: const Icon(Icons.pan_tool_rounded, size: 24),
                  label: const Text(
                    'STOP! أوتوبيس كومبليت! 🛑',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
