import 'package:flutter/material.dart';
import '../../models/party_game_models.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/interactive_3d_card.dart';
import '../../widgets/arcade_3d_buzzer.dart';

class HatrickScreen extends StatefulWidget {
  const HatrickScreen({super.key});

  @override
  State<HatrickScreen> createState() => _HatrickScreenState();
}

class _HatrickScreenState extends State<HatrickScreen> {
  late List<HatrickPrompt> _prompts;
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswerRevealed = false;

  @override
  void initState() {
    super.initState();
    _prompts = HatrickPrompt.defaultPrompts()..shuffle();
  }

  void _revealAnswer() {
    PreferencesService.triggerHaptic(AppHapticType.medium);
    setState(() {
      _isAnswerRevealed = true;
    });
  }

  void _nextQuestion({bool isGoal = false}) async {
    PreferencesService.triggerHaptic(isGoal ? AppHapticType.heavy : AppHapticType.light);
    if (isGoal) {
      GameAudioService().playWin();
    } else {
      GameAudioService().playCardPlace();
    }
    if (isGoal) {
      _score += 10;
      await PreferencesService.recordPartyGameFinished(pointsEarned: 10);
      if (_score % 30 == 0 && mounted) {
        CelebrationOverlay.show(context);
      }
    }
    setState(() {
      _isAnswerRevealed = false;
      _currentIndex = (_currentIndex + 1) % _prompts.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _prompts[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('هاتريك: تحدي كرة القدم ⚽'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_soccer_rounded, color: Color(0xFF2E7D32), size: 18),
                const SizedBox(width: 4),
                Text(
                  '$_score هدف',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20)),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Text(
                      '${current.emoji} ${current.category}',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    'سؤال ${_currentIndex + 1} من ${_prompts.length}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // The Hatrick Stadium Card
              Expanded(
                child: Center(
                  child: Interactive3DCard(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D3B18), Color(0xFF1B5E20), Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFF81C784), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B5E20).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'تحدي هاتريك الرياضي ⚽🔥',
                            style: TextStyle(
                              color: Color(0xFFFFD54F),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            current.question,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Answer Box
                          if (_isAnswerRevealed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'الإجابة الصحيحة: 🎯',
                                    style: TextStyle(
                                      color: Color(0xFF1B5E20),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    current.answer,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF0D3B18),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _revealAnswer,
                              icon: const Icon(Icons.visibility_rounded),
                              label: const Text('كشف الإجابة ⚽'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _nextQuestion(isGoal: false),
                      icon: const Icon(Icons.skip_next_rounded),
                      label: const Text('أوت / تخطي'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Arcade3DBuzzer(
                      label: 'جول! (+10)',
                      icon: Icons.sports_soccer_rounded,
                      color: const Color(0xFF1B5E20),
                      height: 50,
                      onPressed: () => _nextQuestion(isGoal: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
