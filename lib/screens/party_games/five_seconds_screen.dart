import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/party_game_models.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';

class FiveSecondsScreen extends StatefulWidget {
  final List<String>? initialPlayers;

  const FiveSecondsScreen({super.key, this.initialPlayers});

  @override
  State<FiveSecondsScreen> createState() => _FiveSecondsScreenState();
}

class _FiveSecondsScreenState extends State<FiveSecondsScreen>
    with SingleTickerProviderStateMixin {
  late List<FiveSecondPrompt> _prompts;
  int _currentPromptIndex = 0;
  List<String> _players = ['سارة', 'نور', 'شهد'];
  final Map<String, int> _scores = {};
  int _currentPlayerIndex = 0;

  // Timer state
  static const int _totalDuration = 5;
  int _remainingSeconds = _totalDuration;
  Timer? _timer;
  bool _isRunning = false;
  bool _hasFinished = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _prompts = FiveSecondPrompt.defaultPrompts()..shuffle();

    if (widget.initialPlayers != null && widget.initialPlayers!.isNotEmpty) {
      _players = List.from(widget.initialPlayers!);
    } else {
      final profile = PreferencesService.getCouplesProfile();
      _players = [
        profile.partner1Name,
        profile.partner2Name,
        'صديقة 1',
      ];
    }

    for (final p in _players) {
      _scores[p] = 0;
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalDuration;
      _isRunning = true;
      _hasFinished = false;
    });

    PreferencesService.triggerHaptic(AppHapticType.heavy);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
        _animController.forward(from: 0.0);
        PreferencesService.triggerHaptic(AppHapticType.medium);
      } else {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
          _hasFinished = true;
        });
        _animController.forward(from: 0.0);
        PreferencesService.triggerHaptic(AppHapticType.heavy);
      }
    });
  }

  void _recordResult({required bool success}) {
    _timer?.cancel();
    final currentPlayer = _players[_currentPlayerIndex];

    if (success) {
      _scores[currentPlayer] = (_scores[currentPlayer] ?? 0) + 1;
      PreferencesService.triggerHaptic(AppHapticType.medium);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1200),
          backgroundColor: const Color(0xFF2E7D32),
          content: Text('أحسنتِ يا $currentPlayer! 🎉 +1 نقطة'),
        ),
      );
    } else {
      PreferencesService.triggerHaptic(AppHapticType.light);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1200),
          backgroundColor: Colors.redAccent,
          content: Text('حظ أوفر في الجولة القادمة يا $currentPlayer! ⌛'),
        ),
      );
    }

    setState(() {
      _isRunning = false;
      _hasFinished = false;
      _remainingSeconds = _totalDuration;
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
      _currentPromptIndex = (_currentPromptIndex + 1) % _prompts.length;
    });
  }

  void _nextPrompt() {
    _timer?.cancel();
    PreferencesService.triggerHaptic(AppHapticType.selection);
    setState(() {
      _isRunning = false;
      _hasFinished = false;
      _remainingSeconds = _totalDuration;
      _currentPromptIndex = (_currentPromptIndex + 1) % _prompts.length;
    });
  }

  void _showAddPlayerDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة متسابقة ⏱️'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'اسم المتسابقة',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _players.add(name);
                  _scores[name] = 0;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Color _getTimerColor() {
    if (_remainingSeconds > 3) return const Color(0xFF2E7D32);
    if (_remainingSeconds > 1) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _prompts[_currentPromptIndex];
    final activePlayer = _players[_currentPlayerIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تحدي الـ 5 ثواني ⏱️'),
        actions: [
          IconButton(
            tooltip: 'إضافة متسابقة',
            icon: const Icon(Icons.person_add_rounded),
            onPressed: _showAddPlayerDialog,
          ),
          IconButton(
            tooltip: 'تخطي السؤال',
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: _nextPrompt,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active Player & Scoreboard Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.palePurple.withValues(alpha: 0.5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'دور: $activePlayer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _players.map((p) {
                          final isCurrent = p == activePlayer;
                          final score = _scores[p] ?? 0;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCurrent ? AppColors.purple : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '$p: $score',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent ? AppColors.deepPurple : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Challenge Card
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.palePurple,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${prompt.emoji} تصنيف: ${prompt.category}',
                              style: const TextStyle(
                                color: AppColors.deepPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            prompt.question,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.4,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Animated 5s Countdown Circle
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getTimerColor().withValues(alpha: 0.12),
                                border: Border.all(
                                  color: _getTimerColor(),
                                  width: 5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$_remainingSeconds',
                                  style: TextStyle(
                                    fontSize: 46,
                                    fontWeight: FontWeight.w900,
                                    color: _getTimerColor(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isRunning
                                ? 'السرعة هي سر الفوز! 🚀'
                                : _hasFinished
                                    ? 'انتهت الـ 5 ثواني! ⏰'
                                    : 'اضغطي "ابدأ" واستعدي للإجابة السريعة!',
                            style: TextStyle(
                              fontSize: 13,
                              color: _hasFinished ? Colors.redAccent : AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (!_isRunning && !_hasFinished) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _startTimer,
                        icon: const Icon(Icons.play_arrow_rounded, size: 28),
                        label: const Text(
                          'ابدأ الـ 5 ثواني الآن! ⚡',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => _recordResult(success: false),
                              icon: const Icon(Icons.close_rounded),
                              label: const Text(
                                'لم تجب / تعثرت',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => _recordResult(success: true),
                              icon: const Icon(Icons.check_rounded),
                              label: const Text(
                                'أجابت بنجاح! (+1)',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
