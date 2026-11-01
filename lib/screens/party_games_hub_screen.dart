import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../theme/page_transitions.dart';
import '../widgets/ambient_particles.dart';
import '../widgets/interactive_3d_card.dart';
import 'online_room_screen.dart';
import 'party_games/five_seconds_screen.dart';
import 'party_games/most_likely_to_screen.dart';
import 'party_games/spyfall_screen.dart';
import 'party_games/stop_game_screen.dart';
import 'party_games/taboo_screen.dart';
import 'party_games/would_you_rather_screen.dart';
import 'party_games/feen_el_so2al_screen.dart';
import 'party_games/besaraha_wal3a_screen.dart';
import 'party_games/family_stories_screen.dart';
import 'party_games/girls_lakin_screen.dart';
import 'party_games/hatrick_screen.dart';
import 'party_games/bottle_spin_screen.dart';
import 'party_games/jackaroo_3d_screen.dart';
import 'party_games/connect_four_screen.dart';
import 'party_games/memory_match_screen.dart';
import 'party_games/arabic_wordle_screen.dart';

class _PartyGameDef {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final String tag;
  final Color color;
  final Color borderColor;
  final List<String> categories;
  final Widget Function(BuildContext context, List<String> players) builder;

  const _PartyGameDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.tag,
    required this.color,
    required this.borderColor,
    required this.categories,
    required this.builder,
  });
}

class PartyGamesHubScreen extends StatefulWidget {
  const PartyGamesHubScreen({super.key});

  @override
  State<PartyGamesHubScreen> createState() => _PartyGamesHubScreenState();
}

class _PartyGamesHubScreenState extends State<PartyGamesHubScreen> {
  List<String> _groupPlayers = ['سارة', 'نور', 'شهد', 'ريم'];
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<String> _categories = [
    'الكل',
    '2 لاعبين',
    '3+ لاعبات',
    'سرعة وضحك',
    'تكتيك وذكاء',
  ];

  late final List<_PartyGameDef> _allGames = [
    _PartyGameDef(
      id: 'stop_game',
      title: 'إنسان، حيوان، نبات (أوتوبيس كومبليت)',
      subtitle: 'لعبة الكلمات التنافسية الكلاسيكية مع عجلة الحروف وزر STOP الحاسم!',
      emoji: '🚌',
      tag: '2 - 8 لاعبين • سرعة وتحدي',
      color: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFF81C784),
      categories: const ['سرعة وضحك'],
      builder: (ctx, players) => const StopGameScreen(),
    ),
    _PartyGameDef(
      id: 'most_likely_to',
      title: 'مين فينا؟ / مين أكثر واحدة؟',
      subtitle: 'تصويت جماعي سري يكشف أكثر واحدة تنطبق عليها المواقف الطريفة!',
      emoji: '🎭',
      tag: '3 - 10 لاعبين • كشف وفضائح عفوية',
      color: const Color(0xFFF3E5F5),
      borderColor: AppColors.purple,
      categories: const ['3+ لاعبات', 'سرعة وضحك'],
      builder: (ctx, players) => MostLikelyToScreen(initialPlayers: players),
    ),
    _PartyGameDef(
      id: 'five_seconds',
      title: 'تحدي الـ 5 ثواني',
      subtitle: 'اذكري 3 أشياء قبل انتهاء الـ 5 ثواني مع المؤقت الحماسي والنبضات!',
      emoji: '⏱️',
      tag: '2 - 6 لاعبين • سرعة بديهة فائقة',
      color: const Color(0xFFFFF3E0),
      borderColor: Colors.orangeAccent,
      categories: const ['3+ لاعبات', 'سرعة وضحك'],
      builder: (ctx, players) => FiveSecondsScreen(initialPlayers: players),
    ),
    _PartyGameDef(
      id: 'spyfall',
      title: 'الجاسوسة والمندَسّة (Spyfall)',
      subtitle: 'الجميع في مكان سري واحد عدا الجاسوسة! اطرحوا أسئلة لكشفها قبل فوات الأوان.',
      emoji: '🕵️‍♀️',
      tag: '3 - 8 لاعبين • ذكاء اجتماعي وتمويه',
      color: const Color(0xFFFFEBEE),
      borderColor: Colors.redAccent,
      categories: const ['3+ لاعبات', 'تكتيك وذكاء'],
      builder: (ctx, players) => SpyfallScreen(initialPlayers: players),
    ),
    _PartyGameDef(
      id: 'taboo',
      title: 'قول بس لا تقول (المحظورات)',
      subtitle: 'اشرحي الكلمة الرئيسية لفريقك بدون نطق الكلمات المحظورة في البطاقة!',
      emoji: '🤐',
      tag: 'فريقين (4+ لاعبين) • تنافس كلامي',
      color: const Color(0xFFE1F5FE),
      borderColor: Colors.blueAccent,
      categories: const ['3+ لاعبات', 'سرعة وضحك'],
      builder: (ctx, players) => const TabooScreen(),
    ),
    _PartyGameDef(
      id: 'would_you_rather',
      title: 'لو خيروك الجماعي',
      subtitle: 'معضلات طريفة وخيارات صعبة وتصويت جماعي لمعرفة مدى انسجام الجلسة!',
      emoji: '🤔',
      tag: 'الجميع • نقاش وضحك',
      color: const Color(0xFFFBE9E7),
      borderColor: Colors.deepOrangeAccent,
      categories: const ['2 لاعبين', '3+ لاعبات'],
      builder: (ctx, players) => const WouldYouRatherScreen(),
    ),
    _PartyGameDef(
      id: 'feen_el_so2al',
      title: 'فين السؤال؟ (خمن السؤال المخفي)',
      subtitle: 'إجابة مكشوفة أو موقف غريب.. والتحدي هو تخمين السؤال الحقيقي المستخبي وراه!',
      emoji: '❓',
      tag: 'شلة وأزواج • ذكاء وتخمين',
      color: const Color(0xFFEDE7F6),
      borderColor: const Color(0xFF7E57C2),
      categories: const ['سرعة وضحك', 'تكتيك وذكاء'],
      builder: (ctx, players) => const FeenElSo2alScreen(),
    ),
    _PartyGameDef(
      id: 'besaraha_wal3a',
      title: 'بصراحة وتحديات ولعة',
      subtitle: 'كروت صراحة عميقة للشلة، أحكام فورية نارية، وكروت حظ ومفاجآت!',
      emoji: '🔥',
      tag: 'الجميع • صراحة وأحكام حماسية',
      color: const Color(0xFFFBE9E7),
      borderColor: const Color(0xFFFF5722),
      categories: const ['2 لاعبين', '3+ لاعبات'],
      builder: (ctx, players) => BesarahaWal3aScreen(initialPlayers: players),
    ),
    _PartyGameDef(
      id: 'family_stories',
      title: 'حكاوي العيلة والذكريات',
      subtitle: 'كروت مخصصة للمة العيلة.. ذكريات الطفولة والشيطنة، ومواقف الأجداد زمان',
      emoji: '🏡',
      tag: 'جلسات عائلية • نوستالجيا ودفء',
      color: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFF4CAF50),
      categories: const ['3+ لاعبات'],
      builder: (ctx, players) => const FamilyStoriesScreen(),
    ),
    _PartyGameDef(
      id: 'girls_lakin',
      title: 'جلسات البنات (Girls ولكن)',
      subtitle: 'مواقف خاصة بجمعات الصديقات، فضفضة، ستايل وخروجات، وتحديات عفوية',
      emoji: '💅',
      tag: 'جمعات البنات • أسرار وضحك',
      color: const Color(0xFFFCE4EC),
      borderColor: const Color(0xFFE91E63),
      categories: const ['3+ لاعبات'],
      builder: (ctx, players) => GirlsLakinScreen(initialPlayers: players),
    ),
    _PartyGameDef(
      id: 'hatrick',
      title: 'هاتريك: تحدي وأسئلة كرة القدم ⚽',
      subtitle: 'معلومات كروية مشتعلة، بطولات، أساطير المستديرة، وتحديات كروية سريعة للشلة',
      emoji: '⚽',
      tag: 'عشاق الكرة • معلومات وتحدي حماسي',
      color: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFF2E7D32),
      categories: const ['2 لاعبين', 'تكتيك وذكاء'],
      builder: (ctx, players) => const HatrickScreen(),
    ),
    _PartyGameDef(
      id: 'bottle_spin',
      title: 'لف الزجاجة 3D (Spin the Bottle) 🍾',
      subtitle: 'حلقة الجلسة التفاعلية مع زجاجة بلورية ثلاثية الأبعاد بفيزياء احتكاك واقعية وتحديات صراحة أو جرأة!',
      emoji: '🍾',
      tag: '2 - 8 لاعبات • فيزياء 3D وتحديات صراحة وجرأة',
      color: const Color(0xFFFDE8E9),
      borderColor: const Color(0xFFE94B8A),
      categories: const ['3+ لاعبات', 'سرعة وضحك'],
      builder: (ctx, players) => BottleSpinScreen(initialPlayers: players),
    ),
    _PartyGameDef(
      id: 'jackaroo_3d',
      title: 'جاكارو • اللوحة المعتمدة 🎲',
      subtitle: 'اللوحة الزرقاء بنفس الصورة المرجعية، بكرات تفاعلية وترقيم من 1 إلى 18 لكل جزء.',
      emoji: '🎲',
      tag: 'لاعب ضد ثلاثة لاعبين تلقائيين • شراكة وأوراق',
      color: const Color(0xFFEDE7F6),
      borderColor: const Color(0xFF673AB7),
      categories: const ['2 لاعبين', 'تكتيك وذكاء'],
      builder: (ctx, players) => Jackaroo3DScreen(initialPlayers: players),
    ),
    _PartyGameDef(
      id: 'connect_four',
      title: 'أربعة في صف (Connect 4) 🔴🟡',
      subtitle: 'التحدي الكلاسيكي لإسقاط الأقراص الملونة وربط 4 على التوالي قبل المنافس أو الذكاء الاصطناعي!',
      emoji: '🔴',
      tag: '2 لاعبين • ذكاء وتكتيك واستراتيجية',
      color: const Color(0xFFE3F2FD),
      borderColor: const Color(0xFF2196F3),
      categories: const ['2 لاعبين', 'تكتيك وذكاء'],
      builder: (ctx, players) => ConnectFourScreen(initialPlayers: players),
    ),
    _PartyGameDef(
      id: 'memory_match',
      title: 'شطرنج الذاكرة والمطابقة 🎴🧠',
      subtitle: 'تحدي كروت الذاكرة المقلوبة ثلاثية الأبعاد لاكتشاف الأزواج المتطابقة للأزواج والشلة!',
      emoji: '🎴',
      tag: '1 - 2 لاعبين • قوة ملاحظة وسرعة بديهة',
      color: const Color(0xFFF3E5F5),
      borderColor: const Color(0xFFAB47BC),
      categories: const ['2 لاعبين', 'سرعة وضحك'],
      builder: (ctx, players) => MemoryMatchScreen(initialPlayers: players),
    ),
    _PartyGameDef(
      id: 'arabic_wordle',
      title: 'فك الكلمة (Arabic Wordle) 🔤',
      subtitle: 'خمن الكلمة العربية السرية المكونة من 5 حروف في 6 محاولات مع لوحة مفاتيح تفاعلية وتلميحات!',
      emoji: '🔤',
      tag: 'فردي وجماعي • ثراء لغوي وتحدي ذهني',
      color: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFF43A047),
      categories: const ['2 لاعبين', 'تكتيك وذكاء'],
      builder: (ctx, players) => const ArabicWordleScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final profile = PreferencesService.getCouplesProfile();
    _groupPlayers = [profile.partner1Name, profile.partner2Name, 'صديقة 1', 'صديقة 2'];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showManagePlayersDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('قائمة لاعبات الجلسة 👧'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'أضيفي أسماء الحاضرات لتسجيل النقاط وتمرير الأدوار تلقائياً:',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          decoration: const InputDecoration(
                            labelText: 'اسم لاعبة جديدة',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final name = ctrl.text.trim();
                          if (name.isNotEmpty) {
                            setState(() {
                              _groupPlayers.add(name);
                            });
                            setDialogState(() {
                              ctrl.clear();
                            });
                          }
                        },
                        child: const Text('إضافة'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _groupPlayers.map((p) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: AppColors.purple,
                          child: Text(
                            p.characters.first,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                        label: Text(p, style: const TextStyle(fontWeight: FontWeight.bold)),
                        onDeleted: _groupPlayers.length > 2
                            ? () {
                                setState(() {
                                  _groupPlayers.remove(p);
                                });
                                setDialogState(() {});
                              }
                            : null,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('تم وحفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_PartyGameDef> get _filteredGames {
    return _allGames.where((g) {
      if (_selectedCategory != 'الكل' && !g.categories.contains(_selectedCategory)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = g.title.toLowerCase().contains(q) ||
            g.subtitle.toLowerCase().contains(q) ||
            g.tag.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredGames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ألعاب الجلسات والتجمعات 🥳'),
        actions: [
          IconButton(
            tooltip: 'إدارة لاعبات الجلسة',
            icon: const Icon(Icons.group_add_rounded),
            onPressed: _showManagePlayersDialog,
          ),
        ],
      ),
      body: AmbientParticles(
        particleCount: 14,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Hero Banner
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                decoration: BoxDecoration(
                  gradient: AppColors.pinkRoseGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x35E94B8A),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      top: 0,
                      left: 0,
                      child: Opacity(
                        opacity: 0.8,
                        child: Row(
                          children: [
                            Text('♡', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300)),
                            SizedBox(width: 4),
                            Text('♡', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w300)),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('🎉', style: TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مهرجان الألعاب الجماعية',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 19,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'ألعاب حماسية للبنات والجلسات والأصدقاء',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'اللاعبات الحاضرات: ${_groupPlayers.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                            InkWell(
                              onTap: _showManagePlayersDialog,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.24),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'تعديل الأسماء',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF48FB1).withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF48FB1).withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحثي عن لعبة أو فكرة سهرة... 🔍',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE91E63)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : AppColors.deepPurple,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12,
                        ),
                        selectedColor: const Color(0xFFE91E63),
                        backgroundColor: const Color(0xFFFFF0F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSel ? const Color(0xFFE91E63) : const Color(0xFFF8BBD0),
                            width: 1.0,
                          ),
                        ),
                        onSelected: (val) {
                          if (val) {
                            PreferencesService.triggerHaptic(AppHapticType.selection);
                            setState(() => _selectedCategory = cat);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Game Cards
              ...filtered.map((game) {
                return _buildPartyCard(
                  title: game.title,
                  subtitle: game.subtitle,
                  emoji: game.emoji,
                  tag: game.tag,
                  color: game.color,
                  borderColor: game.borderColor,
                  onTap: () {
                    PreferencesService.setLastPlayedGame(title: game.title, route: game.id);
                    final is3DGame = game.id == 'jackaroo_3d' || game.id == 'bottle_spin';
                    Navigator.push(
                      context,
                      is3DGame
                          ? Perspective3DPageRoute(page: game.builder(context, _groupPlayers))
                          : PastelPageRoute(page: game.builder(context, _groupPlayers)),
                    );
                  },
                );
              }),

              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Text('🔍', style: TextStyle(fontSize: 42)),
                      SizedBox(height: 10),
                      Text(
                        'لا توجد ألعاب مطابقة لبحثك',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Remote Play Online Banner
              Interactive3DCard(
                borderRadius: BorderRadius.circular(20),
                maxTiltAngle: 0.1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_tethering_rounded, color: AppColors.purple, size: 36),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ترغبون باللعب من جهازين مختلفين؟',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'افتحوا غرفة اللعب عن بعد للاتصال المباشر واللعب في وقت واحد!',
                              style: TextStyle(fontSize: 11, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PastelPageRoute(page: const OnlineRoomScreen()),
                          );
                        },
                        child: const Text('الغرفة 🌐'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartyCard({
    required String title,
    required String subtitle,
    required String emoji,
    required String tag,
    required Color color,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Interactive3DCard(
      borderRadius: BorderRadius.circular(22),
      maxTiltAngle: 0.12,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withValues(alpha: 0.16),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: borderColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10E94B8A),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              PreferencesService.triggerHaptic(AppHapticType.light);
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 27)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.palePurple,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.lightPurple,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deepPurple.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: Color(0xFFD0658E),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
