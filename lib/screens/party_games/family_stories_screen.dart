import 'package:flutter/material.dart';
import '../../models/party_game_models.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_3d_card.dart';
import '../../widgets/arcade_3d_buzzer.dart';

class FamilyStoriesScreen extends StatefulWidget {
  const FamilyStoriesScreen({super.key});

  @override
  State<FamilyStoriesScreen> createState() => _FamilyStoriesScreenState();
}

class _FamilyStoriesScreenState extends State<FamilyStoriesScreen> {
  late List<FamilyStoriesPrompt> _prompts;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _prompts = FamilyStoriesPrompt.defaultPrompts()..shuffle();
  }

  void _nextPrompt() async {
    PreferencesService.triggerHaptic(AppHapticType.selection);
    GameAudioService().playCardPlace();
    await PreferencesService.recordPartyGameFinished(pointsEarned: 5);
    setState(() {
      _currentIndex = (_currentIndex + 1) % _prompts.length;
    });
  }

  void _prevPrompt() {
    PreferencesService.triggerHaptic(AppHapticType.selection);
    GameAudioService().playCardPlace();
    setState(() {
      _currentIndex = (_currentIndex - 1 + _prompts.length) % _prompts.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _prompts[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('حكاوي العيلة والذكريات 🏡'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Tag
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
                    'حكاية ${_currentIndex + 1} من ${_prompts.length}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // The Family Card
              Expanded(
                child: Center(
                  child: Interactive3DCard(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              current.topic,
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            current.question,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              current.subtext,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'دور على صاحب الحكاية وخليه يحكي من قلبه! 🗣️',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Nav Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _prevPrompt,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('الحكاية السابقة'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Arcade3DBuzzer(
                      label: 'حكاية جديدة ☕',
                      icon: Icons.coffee_rounded,
                      color: const Color(0xFF2E7D32),
                      height: 50,
                      onPressed: _nextPrompt,
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
