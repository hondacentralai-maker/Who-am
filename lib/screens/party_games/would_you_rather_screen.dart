import 'package:flutter/material.dart';
import '../../models/party_game_models.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_3d_card.dart';
import '../../widgets/arcade_3d_buzzer.dart';

class WouldYouRatherScreen extends StatefulWidget {
  const WouldYouRatherScreen({super.key});

  @override
  State<WouldYouRatherScreen> createState() => _WouldYouRatherScreenState();
}

class _WouldYouRatherScreenState extends State<WouldYouRatherScreen> {
  late List<WouldYouRatherPrompt> _prompts;
  int _currentIndex = 0;

  int _votesA = 0;
  int _votesB = 0;
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    _prompts = WouldYouRatherPrompt.defaultPrompts()..shuffle();
  }

  void _voteA() {
    if (_isRevealed) return;
    PreferencesService.triggerHaptic(AppHapticType.selection);
    GameAudioService().playTap();
    setState(() {
      _votesA++;
    });
  }

  void _voteB() {
    if (_isRevealed) return;
    PreferencesService.triggerHaptic(AppHapticType.selection);
    GameAudioService().playTap();
    setState(() {
      _votesB++;
    });
  }

  void _revealResults() async {
    PreferencesService.triggerHaptic(AppHapticType.medium);
    GameAudioService().playSuccess();
    await PreferencesService.recordPartyGameFinished(pointsEarned: 10);
    setState(() {
      _isRevealed = true;
    });
  }

  void _nextDilemma() {
    PreferencesService.triggerHaptic(AppHapticType.light);
    GameAudioService().playCardPlace();
    setState(() {
      _currentIndex = (_currentIndex + 1) % _prompts.length;
      _votesA = 0;
      _votesB = 0;
      _isRevealed = false;
    });
  }

  void _showAddCustomDilemmaDialog() {
    final ctrlA = TextEditingController();
    final ctrlB = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة خيارك الخاص ✍️'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrlA,
              decoration: const InputDecoration(
                labelText: 'الخيار الأول (أ)',
                hintText: 'مثال: تسافرين القمر 🌙',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrlB,
              decoration: const InputDecoration(
                labelText: 'الخيار الثاني (ب)',
                hintText: 'مثال: تعيشين في قصر أعماق البحار 🌊',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final textA = ctrlA.text.trim();
              final textB = ctrlB.text.trim();
              if (textA.isNotEmpty && textB.isNotEmpty) {
                PreferencesService.unlockAchievement('custom_creator');
                GameAudioService().playSuccess();
                setState(() {
                  _prompts.insert(
                    _currentIndex + 1,
                    WouldYouRatherPrompt(
                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      optionA: textA,
                      optionB: textB,
                      category: 'تحدي خاص',
                    ),
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إضافة السؤال للجولة القادمة! 🌟')),
                );
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _prompts[_currentIndex];
    final totalVotes = _votesA + _votesB;
    final percentA = totalVotes > 0 ? ((_votesA / totalVotes) * 100).round() : 50;
    final percentB = totalVotes > 0 ? 100 - percentA : 50;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لو خيروك الجماعي 🤔'),
        actions: [
          IconButton(
            tooltip: 'إضافة سؤال خاص',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _showAddCustomDilemmaDialog,
          ),
          IconButton(
            tooltip: 'التالي',
            icon: const Icon(Icons.skip_next_rounded),
            onPressed: _nextDilemma,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.palePurple.withValues(alpha: 0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سؤال ${_currentIndex + 1} من ${_prompts.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.deepPurple),
                  ),
                  Text(
                    'إجمالي الأصوات: $totalVotes',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.muted),
                  ),
                ],
              ),
            ),

            // Dilemma Cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Option A Card
                    Expanded(
                      child: Interactive3DCard(
                        borderRadius: BorderRadius.circular(24),
                        maxTiltAngle: 0.18,
                        enableGlare: true,
                        onTap: _voteA,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.purple,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.purple,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'الخيار الأول (أ)',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                prompt.optionA,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.deepPurple,
                                  height: 1.4,
                                ),
                              ),
                              if (_isRevealed) ...[
                                const SizedBox(height: 14),
                                Text(
                                  '$percentA% ($votesA صوت)',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 10),
                                Text(
                                  'الأصوات الحالية: $_votesA 👆 اضغطي للتصويت',
                                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                    // Middle "OR / أم" Badge
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.deepPurple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'أو ⚡',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // Option B Card
                    Expanded(
                      child: Interactive3DCard(
                        borderRadius: BorderRadius.circular(24),
                        maxTiltAngle: 0.18,
                        enableGlare: true,
                        onTap: _voteB,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF2E7D32),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'الخيار الثاني (ب)',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                prompt.optionB,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1B5E20),
                                  height: 1.4,
                                ),
                              ),
                              if (_isRevealed) ...[
                                const SizedBox(height: 14),
                                Text(
                                  '$percentB% ($votesB صوت)',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 10),
                                Text(
                                  'الأصوات الحالية: $_votesB 👆 اضغطي للتصويت',
                                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                  ],
                ),
              ),
            ),

            // Bottom Reveal / Next Controls
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
              child: !_isRevealed
                  ? Arcade3DBuzzer(
                      label: 'كشف نسبة الاتفاق 📊',
                      icon: Icons.pie_chart_rounded,
                      color: AppColors.purple,
                      height: 52,
                      enabled: totalVotes > 0,
                      onPressed: totalVotes > 0 ? _revealResults : null,
                    )
                  : Arcade3DBuzzer(
                      label: 'السؤال التالي ➡️',
                      icon: Icons.arrow_forward_rounded,
                      color: AppColors.purple,
                      height: 52,
                      onPressed: _nextDilemma,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  int get votesA => _votesA;
  int get votesB => _votesB;
}
