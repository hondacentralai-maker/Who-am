import 'package:flutter/material.dart';
import '../../models/party_game_models.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_3d_card.dart';
import '../../widgets/arcade_3d_buzzer.dart';

class GirlsLakinScreen extends StatefulWidget {
  final List<String>? initialPlayers;

  const GirlsLakinScreen({super.key, this.initialPlayers});

  @override
  State<GirlsLakinScreen> createState() => _GirlsLakinScreenState();
}

class _GirlsLakinScreenState extends State<GirlsLakinScreen> {
  late List<GirlsLakinPrompt> _prompts;
  int _currentIndex = 0;
  List<String> _players = ['سارة', 'نور', 'شهد', 'ريم'];

  @override
  void initState() {
    super.initState();
    _prompts = GirlsLakinPrompt.defaultPrompts()..shuffle();
    if (widget.initialPlayers != null && widget.initialPlayers!.isNotEmpty) {
      _players = List.from(widget.initialPlayers!);
    }
  }

  void _nextPrompt() async {
    PreferencesService.triggerHaptic(AppHapticType.selection);
    GameAudioService().playCardPlace();
    await PreferencesService.recordPartyGameFinished(pointsEarned: 5);
    setState(() {
      _currentIndex = (_currentIndex + 1) % _prompts.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _prompts[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('جلسات البنات (Girls ولكن) 💅'),
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
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF48FB1)),
                    ),
                    child: Text(
                      '${current.emoji} ${current.category}',
                      style: const TextStyle(
                        color: Color(0xFFC2185B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    'موقف ${_currentIndex + 1} من ${_prompts.length}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // The Card
              Expanded(
                child: Center(
                  child: Interactive3DCard(
                    borderRadius: BorderRadius.circular(28),
                    maxTiltAngle: 0.22,
                    enableGlare: true,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        gradient: AppColors.pinkRoseGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadowColor,
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'الموقف المشترك: 👯‍♀️',
                            style: TextStyle(
                              color: Color(0xFFFFD180),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            current.situation,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'ولكن.. التحدي والسؤال: 👇',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  current.challenge,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFFFEB3B),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'صديقات الجلسة: ${_players.join(" • ")}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Next Button (3D Arcade Buzzer)
              Arcade3DBuzzer(
                label: 'الموقف التالي 💅',
                icon: Icons.arrow_forward_rounded,
                color: AppColors.purple,
                height: 52,
                onPressed: _nextPrompt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
