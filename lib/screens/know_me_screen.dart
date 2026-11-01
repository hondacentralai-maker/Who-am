import 'package:flutter/material.dart';
import '../models/know_me_question.dart';
import '../services/game_audio_service.dart';
import '../services/game_data_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/interactive_3d_card.dart';
import 'online_room_screen.dart';
import 'pass_device_screen.dart';

class KnowMeScreen extends StatefulWidget {
  const KnowMeScreen({super.key});

  @override
  State<KnowMeScreen> createState() => _KnowMeScreenState();
}

class _KnowMeScreenState extends State<KnowMeScreen> {
  List<KnowMeQuestion> _questions = [];
  int _currentIndex = 0;
  bool _loading = true;

  // Round State
  int _roundPoints = 0;
  int _questionsCompleted = 0;
  int _turnPlayer = 1; // 1 is answering secretly, 2 is guessing (or vice-versa)

  // Step: 0 = Player writes secret answer, 1 = Partner guesses, 2 = Comparison & Score
  int _step = 0;
  final TextEditingController _secretAnswerController = TextEditingController();
  final TextEditingController _guessAnswerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final list = await GameDataService.loadKnowMeQuestions();
    final customMaps = PreferencesService.getCustomKnowMeQuestions();
    final customQuestions =
        customMaps.map((m) => KnowMeQuestion.fromJson(m)).toList();
    final combined = [...customQuestions, ...list];
    if (mounted) {
      setState(() {
        _questions = combined..shuffle();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _secretAnswerController.dispose();
    _guessAnswerController.dispose();
    super.dispose();
  }

  KnowMeQuestion? get _currentQuestion =>
      _questions.isEmpty ? null : _questions[_currentIndex % _questions.length];

  void _onSecretAnswerSubmitted() {
    final answeringName = 'اللاعب $_turnPlayer';
    final guessingPlayerNum = _turnPlayer == 1 ? 2 : 1;
    final guessingName = 'اللاعب $guessingPlayerNum';

    PassDeviceScreen.show(
      context,
      targetPlayer: guessingName,
      instruction:
          '$answeringName قفل إجابته السرية. سلّم الهاتف لـ $guessingName ليخمّن ماذا كتب دون أن يرى الإجابة!',
      onReady: () {
        setState(() => _step = 1);
      },
    );
  }

  void _onGuessSubmitted() {
    setState(() {
      _step = 2;
      _questionsCompleted++;
    });
  }

  void _awardScore(bool isMatch) async {
    final points = isMatch ? 15 : 5;
    setState(() {
      _roundPoints += points;
    });

    PreferencesService.triggerHaptic(isMatch ? AppHapticType.heavy : AppHapticType.medium);
    if (isMatch) {
      GameAudioService().playSuccess();
    } else {
      GameAudioService().playCardPlace();
    }

    await PreferencesService.recordGameFinished(
      isKnowMe: true,
      pointsEarned: points,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMatch
              ? '🎉 إجابة مطابقة! (+15 نقطة)'
              : '💜 تقارب رائع ونقاش جميل! (+5 نقاط)',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      _nextQuestion();
    }
  }

  void _nextQuestion() {
    setState(() {
      _step = 0;
      _secretAnswerController.clear();
      _guessAnswerController.clear();
      _turnPlayer = _turnPlayer == 1 ? 2 : 1;
      _currentIndex++;
    });
  }

  void _skipQuestion() {
    setState(() {
      _step = 0;
      _secretAnswerController.clear();
      _guessAnswerController.clear();
      _currentIndex++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تخطي السؤال والانتقال لسؤال آخر بدون عقوبة 💜'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showAddQuestionDialog() {
    final questionCtrl = TextEditingController();
    final hintCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة سؤال جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: questionCtrl,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'السؤال',
                hintText: 'مثال: وش عطري المفضل في المناسبات؟',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hintCtrl,
              decoration: const InputDecoration(
                labelText: 'تلميح لطيف (اختياري)',
                hintText: 'عطر زهري، خشبي، إلخ',
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
            onPressed: () async {
              final q = questionCtrl.text.trim();
              if (q.isNotEmpty) {
                final newQ = KnowMeQuestion(
                  id: 'km_custom_${DateTime.now().millisecondsSinceEpoch}',
                  category: 'أسئلتنا الخاصة',
                  question: q,
                  hint: hintCtrl.text.trim(),
                );
                await PreferencesService.addCustomKnowMeQuestion(newQ.toJson());
                if (mounted) {
                  setState(() {
                    _questions.insert(0, newQ);
                    _currentIndex = 0;
                    _step = 0;
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت إضافة السؤال وحفظه بنجاح! 💜')),
                  );
                }
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
    final guessingPlayerNum = _turnPlayer == 1 ? 2 : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('قد إيش تعرفني؟ 💜'),
        actions: [
          IconButton(
            tooltip: 'اللعب عن بُعد بين هاتفين',
            icon: const Icon(Icons.cloud_sync_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OnlineRoomScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'إضافة سؤال',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _showAddQuestionDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _currentQuestion == null
                ? const Center(child: Text('لا توجد أسئلة متاحة'))
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Score Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.palePurple,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars_rounded,
                                      color: AppColors.accentGold, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    'نقاط الجولة: $_roundPoints',
                                    style: const TextStyle(
                                      color: AppColors.deepPurple,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'أجبتما على: $_questionsCompleted أسئلة',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Question Card
                        Interactive3DCard(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppShadows.cardShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    _currentQuestion!.category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _currentQuestion!.question,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    height: 1.5,
                                  ),
                                ),
                                if (_currentQuestion!.hint.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    '💡 تلميح: ${_currentQuestion!.hint}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Step-specific interaction area
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildInteractiveArea(guessingPlayerNum),
                          ),
                        ),

                        // Always-visible skip button
                        if (_step != 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: OutlinedButton.icon(
                              onPressed: _skipQuestion,
                              icon: const Icon(Icons.skip_next_rounded),
                              label: const Text('تخطي هذا السؤال'),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildInteractiveArea(int guessingPlayerNum) {
    if (_step == 0) {
      // Step 0: Player answers secretly
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.palePurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, color: AppColors.purple),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'اللاعب $_turnPlayer: اكتب إجابتك الصادقة سرًا. لن يراها الشريك إلا بعد أن يخمنها.',
                    style: const TextStyle(
                      color: AppColors.deepPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _secretAnswerController,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'اكتب إجابتك الصادقة هنا...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _secretAnswerController.text.trim().isEmpty
                ? null
                : _onSecretAnswerSubmitted,
            icon: const Icon(Icons.lock_outline_rounded),
            label: Text('قفل الإجابة وتسليم الهاتف للاعب $guessingPlayerNum'),
          ),
        ],
      );
    } else if (_step == 1) {
      // Step 1: Partner guesses
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.palePurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded, color: AppColors.purple),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'اللاعب $guessingPlayerNum: ما هو تخمينك لإجابة اللاعب $_turnPlayer؟',
                    style: const TextStyle(
                      color: AppColors.deepPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _guessAnswerController,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'تخميني هو...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _guessAnswerController.text.trim().isEmpty
                ? null
                : _onGuessSubmitted,
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('كشف الإجابتين والمقارنة 🎉'),
          ),
        ],
      );
    } else {
      // Step 2: Side-by-side comparison & score assignment
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppDecorations.outlinedCard(),
            child: Column(
              children: [
                Text(
                  'إجابة اللاعب $_turnPlayer الأصلية:',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _secretAnswerController.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.deepPurple,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Divider(height: 30),
                Text(
                  'تخمين اللاعب $guessingPlayerNum:',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _guessAnswerController.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'كيف تقيّمون التخمين معًا؟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _awardScore(true),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('تخمين متطابق! (+15)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _awardScore(false),
                  icon: const Icon(Icons.favorite_rounded),
                  label: const Text('قريب ونقاش حلو (+5)'),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }
}
