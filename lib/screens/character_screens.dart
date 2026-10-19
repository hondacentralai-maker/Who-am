import 'package:flutter/material.dart';
import '../models/character.dart';
import '../services/game_data_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import 'online_room_screen.dart';
import 'pass_device_screen.dart';

// ─── 1. Character Intro Screen ───────────────────────────
class CharacterIntroScreen extends StatelessWidget {
  const CharacterIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خمن الشخصية')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              const Text('🎭', textAlign: TextAlign.center, style: TextStyle(fontSize: 70)),
              const SizedBox(height: 8),
              const Text(
                'مين الشخصية اللي في بالك؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'كل لاعب يختار شخصية سرية، وبعدها يسأل أسئلة إجابتها «نعم» أو «لا» ويستبعد الشخصيات التي لا تنطبق عليها الصفات حتى يخمن الشخصية الصحيحة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  height: 1.8,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              const _FeatureRow(icon: Icons.face_retouching_natural, text: '24 شخصية بملامح وأزياء عربية متنوعة ومحددة'),
              const _FeatureRow(icon: Icons.help_outline_rounded, text: 'صفات دقيقة: لحية، نظارة، شماغ، حجاب، ثوب...'),
              const _FeatureRow(icon: Icons.history_rounded, text: 'سجل كامل للأسئلة والإجابات لمتابعة الاستدلال'),
              const _FeatureRow(icon: Icons.restore_rounded, text: 'إمكانية استعادة أي شخصية تم استبعادها بالخطأ'),
              const _FeatureRow(icon: Icons.shield_rounded, text: 'شاشة حماية عند تسليم الجهاز لمنع كشف السر'),
              const Spacer(),
              FilledButton.icon(
                onPressed: () async {
                  final chars = await GameDataService.loadCharacters();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CharacterSelectionScreen(characters: chars),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('ابدأ على هذا الجهاز (أوفلاين)'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OnlineRoomScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_sync_rounded),
                label: const Text('اللعب عن بُعد بين هاتفين 🌐'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.palePurple,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.purple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 2. Character Selection Screen ───────────────────────
class CharacterSelectionScreen extends StatefulWidget {
  final List<Character> characters;
  final int startingPlayer;

  const CharacterSelectionScreen({
    super.key,
    required this.characters,
    this.startingPlayer = 1,
  });

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  late int selectingPlayer;
  Character? selected;
  Character? secret1;
  Character? secret2;

  @override
  void initState() {
    super.initState();
    selectingPlayer = widget.startingPlayer;
  }

  void _onConfirm() {
    if (selected == null) return;

    final otherPlayer = selectingPlayer == 1 ? 2 : 1;

    if (secret1 == null && selectingPlayer == 1) {
      secret1 = selected;
      selected = null;
      PassDeviceScreen.show(
        context,
        targetPlayer: 'اللاعب $otherPlayer',
        instruction: 'سلّم الجهاز للاعب الثاني ليختار شخصيته السرية بهدوء.',
        onReady: () {
          setState(() {
            selectingPlayer = 2;
          });
        },
      );
    } else if (secret2 == null && selectingPlayer == 2) {
      secret2 = selected;
      selected = null;
      if (secret1 == null) {
        // Player 2 selected first, now Player 1 selects
        PassDeviceScreen.show(
          context,
          targetPlayer: 'اللاعب 1',
          instruction: 'سلّم الجهاز للاعب الأول ليختار شخصيته السرية بهدوء.',
          onReady: () {
            setState(() {
              selectingPlayer = 1;
            });
          },
        );
      } else {
        _startBattle();
      }
    } else {
      secret1 ??= selected;
      secret2 ??= selected;
      _startBattle();
    }
  }

  void _startBattle() {
    final firstPlayer = widget.startingPlayer;
    PassDeviceScreen.show(
      context,
      targetPlayer: 'اللاعب $firstPlayer',
      instruction:
          'تم اختيار الشخصيتين السريتين بنجاح! يبدأ اللاعب $firstPlayer بطرح السؤال الأول.',
      onReady: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GuessGameScreen(
              characters: widget.characters,
              secret1: secret1!,
              secret2: secret2!,
              startingPlayer: widget.startingPlayer,
            ),
          ),
        );
      },
    );
  }

  void _showCharacterDetails(Character c) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: c.image != null
                      ? Image.asset(
                          c.image!,
                          width: 70,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Text(c.emoji, style: const TextStyle(fontSize: 48)),
                        )
                      : Text(c.emoji, style: const TextStyle(fontSize: 48)),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '${c.gender} • ${c.older ? "كبير/ة بالسن" : "شاب/ة"}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _traitChip('نظارة', c.glasses),
                _traitChip('لحية أو شارب', c.beard),
                _traitChip('غطاء رأس/شماغ', c.headwear),
                _traitChip('حجاب', c.hijab),
                _traitChip('ثوب', c.thobe),
                _traitChip('بشرة فاتحة', c.skin == 'فاتحة'),
                _traitChip('شعر داكن', c.hair == 'داكن'),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => selected = c);
              },
              child: const Text('اختيار هذه الشخصية'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _traitChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.palePurple : const Color(0xFFF0EDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.purple : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.cancel_outlined,
            size: 14,
            color: active ? AppColors.purple : AppColors.muted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.deepPurple : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختيار الشخصية • اللاعب $selectingPlayer'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.palePurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_off_rounded, color: AppColors.purple),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'اللاعب $selectingPlayer: اختر شخصيتك السرية. اضغط مطولاً لرؤية التفاصيل.',
                        style: const TextStyle(
                          color: AppColors.deepPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: widget.characters.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, i) {
                  final c = widget.characters[i];
                  final isSelected = selected?.id == c.id;
                  return InkWell(
                    onTap: () => setState(() => selected = c),
                    onLongPress: () => _showCharacterDetails(c),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.palePurple : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.purple : const Color(0xFFEAE6F4),
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected ? AppShadows.cardShadow : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: c.image != null
                                ? Image.asset(
                                    c.image!,
                                    width: 52,
                                    height: 66,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Text(c.emoji, style: const TextStyle(fontSize: 32)),
                                  )
                                : Text(c.emoji, style: const TextStyle(fontSize: 32)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppColors.purple : AppColors.ink,
                            ),
                          ),
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.check_circle, size: 16, color: AppColors.purple),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selected == null ? null : _onConfirm,
                  child: Text(
                    secret1 == null || secret2 == null
                        ? 'تثبيت وتسليم الهاتف للطرف الآخر'
                        : 'تثبيت وبدء التحدي',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

// ─── 3. Guess Game Screen ────────────────────────────────
class GuessGameScreen extends StatefulWidget {
  final List<Character> characters;
  final Character secret1;
  final Character secret2;
  final int startingPlayer;

  const GuessGameScreen({
    super.key,
    required this.characters,
    required this.secret1,
    required this.secret2,
    this.startingPlayer = 1,
  });

  @override
  State<GuessGameScreen> createState() => _GuessGameScreenState();
}

class _GuessGameScreenState extends State<GuessGameScreen> {
  late int player;
  String? pendingTrait;
  String? pendingQuestion;
  bool answering = false;
  String? winner;
  final Set<String> eliminated1 = {};
  final Set<String> eliminated2 = {};
  final List<Map<String, dynamic>> questionHistory = [];

  static const traits = <Map<String, String>>[
    {'key': 'gender_male', 'label': 'هل الشخصية رجل؟', 'short': 'رجل'},
    {'key': 'gender_female', 'label': 'هل الشخصية امرأة؟', 'short': 'امرأة'},
    {'key': 'older', 'label': 'هل الشخصية كبيرة في السن؟', 'short': 'كبيرة بالسن'},
    {'key': 'glasses', 'label': 'هل تلبس نظارة؟', 'short': 'نظارة'},
    {'key': 'beard', 'label': 'هل لديه لحية أو شارب؟', 'short': 'لحية/شارب'},
    {'key': 'headwear', 'label': 'هل يرتدي غطاء رأس أو شماغ؟', 'short': 'شماغ/طاقية'},
    {'key': 'hijab', 'label': 'هل ترتدي حجابًا؟', 'short': 'حجاب'},
    {'key': 'thobe', 'label': 'هل يرتدي ثوبًا؟', 'short': 'ثوب'},
    {'key': 'light_skin', 'label': 'هل بشرتها فاتحة؟', 'short': 'بشرة فاتحة'},
    {'key': 'dark_hair', 'label': 'هل شعرها داكن/أسود؟', 'short': 'شعر داكن'},
  ];

  @override
  void initState() {
    super.initState();
    player = widget.startingPlayer;
  }

  Set<String> get currentEliminated => player == 1 ? eliminated1 : eliminated2;
  List<Character> get available =>
      widget.characters.where((c) => !currentEliminated.contains(c.id)).toList();

  void _ask(Map<String, String> t) {
    setState(() {
      pendingTrait = t['key'];
      pendingQuestion = t['label'];
      answering = true;
    });

    PassDeviceScreen.show(
      context,
      targetPlayer: 'اللاعب ${player == 1 ? 2 : 1}',
      instruction: 'أجب على السؤال بصدق بناءً على شخصيتك السرية دون كشفها.',
      onReady: () {},
    );
  }

  void _answer(bool yes) {
    final key = pendingTrait!;
    final questionText = pendingQuestion!;
    final askingPlayer = player;

    // Record question in history
    questionHistory.insert(0, {
      'asker': askingPlayer,
      'question': questionText,
      'answer': yes,
    });

    // Automatically eliminate candidates that don't match the answer
    for (final c in widget.characters) {
      if (c.trait(key) != yes) {
        currentEliminated.add(c.id);
      }
    }

    final nextPlayer = player == 1 ? 2 : 1;

    PassDeviceScreen.show(
      context,
      targetPlayer: 'اللاعب $nextPlayer',
      instruction: 'تم تسجيل الإجابة وتحديث قائمة الشخصيات المتبقية. الدور الآن لك!',
      onReady: () {
        setState(() {
          answering = false;
          pendingTrait = null;
          pendingQuestion = null;
          player = nextPlayer;
        });
      },
    );
  }

  void _handleCharacterTap(Character c) {
    if (currentEliminated.contains(c.id)) {
      // Re-include character dialog (P0 requirement: إتاحة استبعاد وإعادة إظهار)
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('استعادة الشخصية'),
          content: Text('الشخصية «${c.name}» مستبعدة حاليًا. هل ترغب في إعادتها إلى اللوحة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  currentEliminated.remove(c.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تمت استعادة «${c.name}» إلى لوحتك بنجاح.')),
                );
              },
              child: const Text('إعادة إظهار'),
            ),
          ],
        ),
      );
    } else {
      _confirmGuess(c);
    }
  }

  void _confirmGuess(Character c) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد التخمين النهائي'),
        content: Text('هل أنت متأكد أن شخصية الشريك السرية هي «${c.name}»؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _makeGuess(c);
            },
            child: const Text('نعم، أخمن هذه الشخصية!'),
          ),
        ],
      ),
    );
  }

  void _makeGuess(Character c) async {
    final target = player == 1 ? widget.secret2 : widget.secret1;
    if (c.id == target.id) {
      await PreferencesService.recordGameFinished(
        isGuessWin: true,
        pointsEarned: 30,
      );
      setState(() => winner = 'اللاعب $player');
    } else {
      currentEliminated.add(c.id);
      final nextPlayer = player == 1 ? 2 : 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ليست «${c.name}»! تم استبعادها، وانتقل الدور للاعب $nextPlayer.'),
        ),
      );
      PassDeviceScreen.show(
        context,
        targetPlayer: 'اللاعب $nextPlayer',
        instruction: 'التخمين لم يكن صحيحًا. انتقل الدور إليك الآن!',
        onReady: () {
          setState(() {
            player = nextPlayer;
          });
        },
      );
    }
  }

  void _skipTurn() {
    final nextPlayer = player == 1 ? 2 : 1;
    PassDeviceScreen.show(
      context,
      targetPlayer: 'اللاعب $nextPlayer',
      instruction: 'تم تخطي الدور. الدور لك الآن!',
      onReady: () {
        setState(() => player = nextPlayer);
      },
    );
  }

  void _showHistorySheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.purple),
                const SizedBox(width: 8),
                const Text(
                  'سجل الأسئلة والإجابات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  '${questionHistory.length} أسئلة',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: questionHistory.isEmpty
                  ? const Center(
                      child: Text(
                        'لم يتم طرح أي أسئلة بعد في هذه الجولة',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: questionHistory.length,
                      itemBuilder: (context, i) {
                        final item = questionHistory[i];
                        final isYes = item['answer'] == true;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: AppDecorations.outlinedCard(radius: 14),
                          child: Row(
                            children: [
                              Text(
                                isYes ? '✅' : '❌',
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['question'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      'اللاعب ${item["asker"]} • الإجابة: ${isYes ? "نعم" : "لا"}',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _restart() {
    // Swap starting player for the next round
    final nextStarter = widget.startingPlayer == 1 ? 2 : 1;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterSelectionScreen(
          characters: widget.characters,
          startingPlayer: nextStarter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خمن الشخصية'),
        actions: [
          IconButton(
            tooltip: 'سجل الأسئلة',
            onPressed: _showHistorySheet,
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'إعادة اللعب',
            onPressed: _restart,
            icon: const Icon(Icons.replay_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: winner != null
            ? _buildWinnerView()
            : answering
                ? _buildAnswerView()
                : _buildGameView(),
      ),
    );
  }

  Widget _buildGameView() {
    return Column(
      children: [
        // Header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  player == 1 ? '1️⃣' : '2️⃣',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دور اللاعب $player',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'اختر سؤالاً من الأسئلة أو اضغط شخصية لتخمينها',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Traits bar
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: traits.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final t = traits[i];
              return ActionChip(
                backgroundColor: AppColors.palePurple,
                side: BorderSide.none,
                label: Text(
                  t['short']!,
                  style: const TextStyle(
                    color: AppColors.deepPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => _ask(t),
              );
            },
          ),
        ),

        // Stats row
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
          child: Row(
            children: [
              Text(
                'الشخصيات المتبقية: ${available.length}',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                'مستبعدة: ${currentEliminated.length} (اضغط لاستعادتها)',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),

        // Characters Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: widget.characters.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, i) {
              final c = widget.characters[i];
              final out = currentEliminated.contains(c.id);
              return InkWell(
                onTap: () => _handleCharacterTap(c),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: out ? AppColors.disabledBg : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: out ? Colors.transparent : AppColors.cardBorder,
                    ),
                  ),
                  child: Opacity(
                    opacity: out ? 0.28 : 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: c.image != null
                              ? Image.asset(
                                  c.image!,
                                  width: 48,
                                  height: 62,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Text(c.emoji, style: const TextStyle(fontSize: 30)),
                                )
                              : Text(c.emoji, style: const TextStyle(fontSize: 30)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        if (out)
                          const Text(
                            'مستبعدة ↩',
                            style: TextStyle(fontSize: 9, color: AppColors.muted),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom skip bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _skipTurn,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('تخطي الدور للطرف الآخر'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerView() {
    final answeringPlayer = player == 1 ? 2 : 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.purple,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'دور اللاعب $answeringPlayer بالإجابة',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'أجب بصدق عن شخصيتك السرية، ولا تظهرها للشريك.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.palePurple, width: 2),
              boxShadow: AppShadows.cardShadow,
            ),
            child: Text(
              pendingQuestion ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _answer(true),
              icon: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
              label: const Text('نعم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDDD7EE), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _answer(false),
              icon: const Icon(Icons.close_rounded, color: AppColors.ink, size: 22),
              label: const Text('لا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.palePurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'عدد الشخصيات المتبقية: ${available.length}',
                style: const TextStyle(
                  color: AppColors.deepPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildWinnerView() {
    final target = player == 1 ? widget.secret2 : widget.secret1;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.palePurple,
                  ),
                ),
                if (target.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      target.image!,
                      width: 90,
                      height: 115,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Text(target.emoji, style: const TextStyle(fontSize: 64)),
                    ),
                  )
                else
                  Text(target.emoji, style: const TextStyle(fontSize: 64)),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'لقد خمنت الشخصية بنجاح! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.palePurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'إنها شخصية: ${target.name}',
                style: const TextStyle(
                  fontSize: 20,
                  color: AppColors.purple,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$winner فاز بالجولة (+30 نقطة) 💜',
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _restart,
                child: const Text('العب مرة أخرى'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('العودة إلى القائمة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
