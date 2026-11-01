import 'package:flutter/material.dart';
import '../../models/party_game_models.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_3d_card.dart';
import '../../widgets/arcade_3d_buzzer.dart';

class FeenElSo2alScreen extends StatefulWidget {
  const FeenElSo2alScreen({super.key});

  @override
  State<FeenElSo2alScreen> createState() => _FeenElSo2alScreenState();
}

class _FeenElSo2alScreenState extends State<FeenElSo2alScreen> {
  late List<FeenElSo2alPrompt> _prompts;
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedQuestion;
  bool _revealed = false;
  late List<String> _shuffledOptions;

  @override
  void initState() {
    super.initState();
    _prompts = FeenElSo2alPrompt.defaultPrompts()..shuffle();
    _loadCurrentQuestion();
  }

  void _loadCurrentQuestion() {
    _revealed = false;
    _selectedQuestion = null;
    final current = _prompts[_currentIndex];
    _shuffledOptions = [current.correctQuestion, ...current.wrongQuestions]..shuffle();
  }

  void _chooseOption(String option) {
    if (_revealed) return;
    final current = _prompts[_currentIndex];
    final isCorrect = option == current.correctQuestion;

    PreferencesService.triggerHaptic(isCorrect ? AppHapticType.heavy : AppHapticType.selection);
    if (isCorrect) {
      GameAudioService().playSuccess();
    } else {
      GameAudioService().playBuzzer();
    }

    setState(() {
      _selectedQuestion = option;
      _revealed = true;
      if (isCorrect) {
        _score += 10;
        PreferencesService.recordPartyGameFinished(pointsEarned: 10);
      }
    });
  }

  void _nextRound() {
    PreferencesService.triggerHaptic(AppHapticType.light);
    GameAudioService().playCardPlace();
    setState(() {
      _currentIndex = (_currentIndex + 1) % _prompts.length;
      _loadCurrentQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _prompts[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('فين السؤال؟ ❓'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.accentGold, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$_score نقطة',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Round info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'جولة ${_currentIndex + 1} من ${_prompts.length}',
                    style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.palePurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${current.emoji} ${current.category}',
                      style: const TextStyle(color: AppColors.deepPurple, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // The Answer Card
              Interactive3DCard(
                borderRadius: BorderRadius.circular(24),
                maxTiltAngle: 0.20,
                enableGlare: true,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x30E94B8A),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'الإجابة أو الموقف المكشوف:',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        current.answer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'خمنوا: إيه كان السؤال الحقيقي ورا الإجابة دي؟ 🤔',
                          style: TextStyle(color: AppColors.neonGold, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'اختر السؤال المخفي الأقرب للواقع:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),

              // Question Options
              ..._shuffledOptions.map((opt) {
                final isSelected = _selectedQuestion == opt;
                final isCorrect = opt == current.correctQuestion;

                Color borderColor = Colors.grey.withValues(alpha: 0.25);
                Color bgColor = Colors.white;
                Color textColor = AppColors.ink;
                Widget? trailingIcon;

                if (_revealed) {
                  if (isCorrect) {
                    borderColor = const Color(0xFF2E7D32);
                    bgColor = const Color(0xFFE8F5E9);
                    textColor = const Color(0xFF1B5E20);
                    trailingIcon = const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32));
                  } else if (isSelected) {
                    borderColor = const Color(0xFFC62828);
                    bgColor = const Color(0xFFFFEBEE);
                    textColor = const Color(0xFFB71C1C);
                    trailingIcon = const Icon(Icons.cancel_rounded, color: Color(0xFFC62828));
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: _revealed ? null : () => _chooseOption(opt),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: (isSelected || (_revealed && isCorrect))
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (trailingIcon != null) trailingIcon,
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Action button (3D Arcade Buzzer)
              if (_revealed)
                Arcade3DBuzzer(
                  label: 'الجولة التالية 🎯',
                  icon: Icons.arrow_forward_rounded,
                  color: AppColors.purple,
                  height: 52,
                  onPressed: _nextRound,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
