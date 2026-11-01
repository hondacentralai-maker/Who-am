import 'package:flutter/material.dart';
import '../models/couples_card.dart';
import '../services/game_data_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../services/game_audio_service.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/interactive_3d_card.dart';
import 'pass_device_screen.dart';

class ExtraGamesScreen extends StatefulWidget {
  const ExtraGamesScreen({super.key});

  @override
  State<ExtraGamesScreen> createState() => _ExtraGamesScreenState();
}

class _ExtraGamesScreenState extends State<ExtraGamesScreen> {
  List<CouplesCard> _allCards = [];
  Set<String> _favorites = {};
  bool _loading = true;
  String _dailyQuestion = 'وش شيء بسيط يسعدك اليوم؟';

  final List<List<String>> _pairs = const [
    ['قهوة ☕', 'شاي 🍵'],
    ['البحر 🌊', 'الجبل ⛰️'],
    ['سهرة في البيت 🏠', 'طلعة عفوية 🚗'],
    ['تخطيط مسبق 📅', 'مفاجأة 🎁'],
    ['فيلم كوميدي 😂', 'فيلم مغامرات 🧭'],
    ['رسالة 💌', 'مكالمة 📞'],
    ['فطور متأخر 🥞', 'عشاء هادئ 🍽️'],
    ['سفر ✈️', 'استكشاف مكان قريب 🚶'],
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cards = await GameDataService.loadTypedCards();
    final customMaps = PreferencesService.getCustomCards();
    final customCards = customMaps.map((m) => CouplesCard.fromJson(m)).toList();
    _favorites = PreferencesService.getFavorites();

    final all = [...cards, ...customCards];
    final today = DateTime.now();
    final dayKey = '${today.year}-${today.month}-${today.day}';
    final pool = all.where((c) => c.type == 'سؤال' || c.type == 'تأمل').toList();
    final seed = dayKey.codeUnits.fold<int>(0, (a, b) => a + b);

    if (mounted) {
      setState(() {
        _allCards = all;
        _dailyQuestion = pool.isEmpty
            ? 'وش شيء بسيط يسعدك اليوم؟'
            : pool[seed % pool.length].text;
        _loading = false;
      });
    }
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.outlinedCard(),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.palePurple,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.purple, size: 26),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        trailing: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 14, color: AppColors.purple),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ألعاب وأسئلة إضافية')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppShadows.cardShadow,
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تجارب خفيفة وممتعة 💜',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'ألعاب سريعة تكشف التفضيلات وتصنع لحظات ضحك وتقارب.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTile(
                    icon: Icons.wb_sunny_rounded,
                    title: 'سؤال اليوم',
                    subtitle: 'سؤال متجدد يوميًا للمناقشة الهادئة',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyQuestionDetailScreen(
                          question: _dailyQuestion,
                        ),
                      ),
                    ),
                  ),
                  _buildTile(
                    icon: Icons.compare_arrows_rounded,
                    title: 'هذا أو ذاك',
                    subtitle: 'خيارات سريعة بدون تفكير طويل',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ThisOrThatScreen(pairs: _pairs),
                      ),
                    ),
                  ),
                  _buildTile(
                    icon: Icons.psychology_alt_rounded,
                    title: 'خمن إجابتي',
                    subtitle: 'اكتب إجابتك سرًا ودع الشريك يخمنها',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GuessMyAnswerScreen(),
                      ),
                    ),
                  ),
                  _buildTile(
                    icon: Icons.bookmark_rounded,
                    title: 'البطاقات المفضلة',
                    subtitle: 'البطاقات المحفوظة للرجوع إليها في أي وقت',
                    onTap: () {
                      final favCards = _allCards
                          .where((c) => _favorites.contains(c.id))
                          .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FavoritesListScreen(
                            cards: favCards,
                            favorites: _favorites,
                            onToggle: (id) async {
                              await PreferencesService.toggleFavorite(
                                  id, _favorites);
                              await _loadData();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  _buildTile(
                    icon: Icons.edit_note_rounded,
                    title: 'أسئلتنا الخاصة ✏️',
                    subtitle: 'إدارة وإضافة وتعديل وحذف أسئلتكم المشتركة',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageCustomCardsScreen(
                          onUpdated: _loadData,
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

// ─── 1. Daily Question Screen ────────────────────────────
class DailyQuestionDetailScreen extends StatelessWidget {
  final String question;
  const DailyQuestionDetailScreen({super.key, this.question = 'وش شيء بسيط يسعدك اليوم؟'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سؤال اليوم')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text('☀️', textAlign: TextAlign.center, style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              const Text(
                'سؤال اليوم 💜',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.deepPurple,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              Interactive3DCard(
                borderRadius: BorderRadius.circular(24),
                maxTiltAngle: 0.20,
                enableGlare: true,
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    gradient: AppColors.pinkRoseGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppShadows.floatingShadow,
                  ),
                  child: Text(
                    question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'كل واحد يجاوب براحته، وتذكروا أن الهدف هو الاستماع والمشاركة دون أحكام.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  PreferencesService.recordGamePlay();
                  Navigator.pop(context);
                },
                child: const Text('شاركنا الإجابة وتم!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 2. This or That Screen ──────────────────────────────
class ThisOrThatScreen extends StatefulWidget {
  final List<List<String>> pairs;
  const ThisOrThatScreen({super.key, this.pairs = const [
    ['قهوة ☕', 'شاي 🍵'],
    ['البحر 🌊', 'الجبل ⛰️'],
    ['سهرة في البيت 🏠', 'طلعة عفوية 🚗'],
    ['تخطيط مسبق 📅', 'مفاجأة 🎁'],
    ['فيلم كوميدي 😂', 'فيلم مغامرات 🧭'],
    ['رسالة 💌', 'مكالمة 📞'],
    ['فطور متأخر 🥞', 'عشاء هادئ 🍽️'],
    ['سفر ✈️', 'استكشاف مكان قريب 🚶'],
  ]});

  @override
  State<ThisOrThatScreen> createState() => _ThisOrThatScreenState();
}

class _ThisOrThatScreenState extends State<ThisOrThatScreen> {
  int _index = 0;

  void _next() {
    setState(() {
      _index = (_index + 1) % widget.pairs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pair = widget.pairs[_index % widget.pairs.length];
    return Scaffold(
      appBar: AppBar(title: const Text('هذا أو ذاك')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'الاختيار ${_index + 1} من ${widget.pairs.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'أنت وش تفضل؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 32),
              _buildChoiceButton(pair[0]),
              const SizedBox(height: 16),
              const Text(
                'أو',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.purple,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _buildChoiceButton(pair[1]),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _next,
                icon: const Icon(Icons.arrow_back),
                label: const Text('الاختيار التالي'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton(String text) {
    return Interactive3DCard(
      borderRadius: BorderRadius.circular(22),
      maxTiltAngle: 0.14,
      enableGlare: true,
      child: Container(
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.6), width: 2),
          boxShadow: AppShadows.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              PreferencesService.triggerHaptic(AppHapticType.selection);
              GameAudioService().playTap();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('اختيار رائع: $text 💖'),
                  duration: const Duration(milliseconds: 900),
                ),
              );
              Future.delayed(const Duration(milliseconds: 250), () {
                if (mounted) _next();
              });
            },
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.deepPurple,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 3. Guess My Answer Screen ───────────────────────────
class GuessMyAnswerScreen extends StatefulWidget {
  const GuessMyAnswerScreen({super.key});

  @override
  State<GuessMyAnswerScreen> createState() => _GuessMyAnswerScreenState();
}

class _GuessMyAnswerScreenState extends State<GuessMyAnswerScreen> {
  final TextEditingController _secretController = TextEditingController();
  final TextEditingController _guessController = TextEditingController();

  final List<String> _prompts = const [
    'وش أكثر شيء يرفع معنوياتك لما تكون متضايق؟',
    'وش البلد أو المكان اللي تتمنى نسافر له سوا؟',
    'وش أكلتك المفضلة في يوم مميز؟',
    'وش نشاط جديد تحب نجربه مع بعض؟',
    'وش أول شيء لفت انتباهك فيني لما تعرفنا؟',
  ];

  int _promptIndex = 0;
  int _step = 0; // 0: Player 1 secretly answers, 1: Player 2 guesses, 2: Reveal & compare

  @override
  void dispose() {
    _secretController.dispose();
    _guessController.dispose();
    super.dispose();
  }

  void _onPlayer1Submitted() {
    PassDeviceScreen.show(
      context,
      targetPlayer: 'اللاعب 2',
      instruction: 'اللاعب 1 قفل إجابته السرية. الدور عليك الآن لتخمين ماذا كتب!',
      onReady: () {
        setState(() => _step = 1);
      },
    );
  }

  void _onPlayer2Submitted() {
    PreferencesService.triggerHaptic(AppHapticType.heavy);
    GameAudioService().playSuccess();
    CelebrationOverlay.show(context);
    setState(() => _step = 2);
  }

  void _restart() {
    setState(() {
      _secretController.clear();
      _guessController.clear();
      _step = 0;
      _promptIndex = (_promptIndex + 1) % _prompts.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خمن إجابتي')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.palePurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 10),
                    Text(
                      _prompts[_promptIndex],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.deepPurple,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_step == 0) ...[
                const Text(
                  'اللاعب 1: اكتب إجابتك السرية هنا.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _secretController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'إجابتي هي...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _secretController.text.trim().isEmpty
                      ? null
                      : _onPlayer1Submitted,
                  child: const Text('قفل الإجابة وتسليم الجهاز'),
                ),
              ] else if (_step == 1) ...[
                const Text(
                  'اللاعب 2: خمّن ماذا كتب اللاعب 1؟',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _guessController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'تخميني هو...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _guessController.text.trim().isEmpty
                      ? null
                      : _onPlayer2Submitted,
                  child: const Text('كشف الإجابات ومقارنتها 🎉'),
                ),
              ] else ...[
                Interactive3DCard(
                  borderRadius: BorderRadius.circular(22),
                  maxTiltAngle: 0.16,
                  enableGlare: true,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppDecorations.outlinedCard(),
                    child: Column(
                      children: [
                        const Text(
                          'إجابة اللاعب 1 الأصلية:',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _secretController.text,
                        style: const TextStyle(
                          color: AppColors.deepPurple,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Divider(height: 28),
                      const Text(
                        'تخمين اللاعب 2:',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _guessController.text,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('سؤال جديد'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 4. Favorites List Screen ────────────────────────────
class FavoritesListScreen extends StatelessWidget {
  final List<CouplesCard> cards;
  final Set<String> favorites;
  final Function(String) onToggle;

  const FavoritesListScreen({
    super.key,
    required this.cards,
    required this.favorites,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البطاقات المفضلة')),
      body: cards.isEmpty
          ? const Center(
              child: Text(
                'لم تقم بحفظ أي بطاقات بالمفضلة بعد 💜',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cards.length,
              itemBuilder: (context, i) {
                final card = cards[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.palePurple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                card.category,
                                style: const TextStyle(
                                  color: AppColors.deepPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.bookmark_remove_rounded,
                                  color: Colors.redAccent),
                              onPressed: () => onToggle(card.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          card.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─── 5. Manage Custom Cards Screen (CRUD) ────────────────
class ManageCustomCardsScreen extends StatefulWidget {
  final VoidCallback onUpdated;

  const ManageCustomCardsScreen({super.key, required this.onUpdated});

  @override
  State<ManageCustomCardsScreen> createState() =>
      _ManageCustomCardsScreenState();
}

class _ManageCustomCardsScreenState extends State<ManageCustomCardsScreen> {
  List<Map<String, dynamic>> _customCards = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _customCards = PreferencesService.getCustomCards();
    });
  }

  void _editCard(Map<String, dynamic> card) {
    final controller =
        TextEditingController(text: card['text']?.toString() ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل السؤال الخاص'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                final updated = Map<String, dynamic>.from(card);
                updated['text'] = newText;
                Navigator.pop(ctx);
                await PreferencesService.updateCustomCard(card['id'], updated);
                _load();
                widget.onUpdated();
              }
            },
            child: const Text('حفظ التعديل'),
          ),
        ],
      ),
    );
  }

  void _deleteCard(String id) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل ترغب في حذف هذا السؤال من مجموعتكم الخاصة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await PreferencesService.deleteCustomCard(id);
              _load();
              widget.onUpdated();
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _addNewCard() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة سؤال جديد'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'اكتبوا سؤالكم هنا...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
                final newCustom = {
                  'id': id,
                  'category': 'أسئلتنا الخاصة',
                  'type': 'سؤال',
                  'level': 'خاص',
                  'text': text,
                  'purpose': 'سؤال أضفتموه بأنفسكم.',
                };
                Navigator.pop(ctx);
                await PreferencesService.addCustomCard(newCustom);
                _load();
                widget.onUpdated();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسئلتنا الخاصة ✏️'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'إضافة سؤال',
            onPressed: _addNewCard,
          ),
        ],
      ),
      body: _customCards.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✏️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text(
                    'لا توجد أسئلة خاصة حتى الآن',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'أضيفوا أسئلتكم المشتركة ولحظاتكم المميزة للعب بها',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _addNewCard,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إضافة أول سؤال خاص'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _customCards.length,
              itemBuilder: (ctx, i) {
                final card = _customCards[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.palePurple,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'سؤال خاص',
                                style: TextStyle(
                                  color: AppColors.deepPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.purple, size: 20),
                              tooltip: 'تعديل',
                              onPressed: () => _editCard(card),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent, size: 20),
                              tooltip: 'حذف',
                              onPressed: () =>
                                  _deleteCard(card['id'] as String),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card['text']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

