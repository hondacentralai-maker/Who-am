import 'dart:math';
import 'package:flutter/material.dart';
import '../models/couples_card.dart';
import '../services/game_audio_service.dart';
import '../services/game_data_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/interactive_3d_card.dart';
import '../widgets/flip_3d_card.dart';
import 'structured_session_screen.dart';

class DeckOption {
  final String id;
  final String title;
  final String emoji;
  final Color primaryColor;
  final String description;

  const DeckOption({
    required this.id,
    required this.title,
    required this.emoji,
    required this.primaryColor,
    required this.description,
  });
}

class CouplesCardsScreen extends StatefulWidget {
  final String? initialDeckId;

  const CouplesCardsScreen({super.key, this.initialDeckId});

  @override
  State<CouplesCardsScreen> createState() => _CouplesCardsScreenState();
}

class _CouplesCardsScreenState extends State<CouplesCardsScreen> {
  List<CouplesCard> _allCards = [];
  Set<String> _favorites = {};
  CouplesCard? _currentCard;
  String _selectedDeck = 'all';
  String _selectedFilter = 'الكل';
  bool _loading = true;
  bool _showFollowUp = false;
  final Random _random = Random();

  static const List<DeckOption> _decks = [
    DeckOption(
      id: 'all',
      title: 'جميع الباقات',
      emoji: '🃏',
      primaryColor: AppColors.purple,
      description: 'تشكيلة عشوائية من كل ألعاب الكروت',
    ),
    DeckOption(
      id: 'salon',
      title: 'خطوبة صالونات',
      emoji: '☕',
      primaryColor: Color(0xFF5D4037),
      description: 'أسئلة ومواقف التوافق والتعارف للمقبلين على الزواج',
    ),
    DeckOption(
      id: 'first_year',
      title: 'سنة أولى جواز',
      emoji: '💍',
      primaryColor: Color(0xFFE65100),
      description: 'مواقف، لو خيروك، ومصارحة للعرسان الجدد',
    ),
    DeckOption(
      id: 'mawada',
      title: 'مودة ورحمة',
      emoji: '🌿',
      primaryColor: Color(0xFF1B5E20),
      description: 'أول لعبة كروت إسلامية للزواج والسكينة',
    ),
    DeckOption(
      id: 'deep_talk',
      title: 'كلام من القلب',
      emoji: '💬',
      primaryColor: Color(0xFF311B92),
      description: 'Deep Couples لكسر روتين الموبايل والعمق',
    ),
    DeckOption(
      id: 'lakin',
      title: 'Couples ولكن',
      emoji: '🔥',
      primaryColor: Color(0xFFC2185B),
      description: 'تحديات وخروجات وجرأة لكسر الملل',
    ),
    DeckOption(
      id: 'memes',
      title: 'Couples Memes',
      emoji: '😂',
      primaryColor: Color(0xFFD97706),
      description: 'مواقف مضحكة وميمز واقعية للزوجين',
    ),
    DeckOption(
      id: 'classic',
      title: 'سواها الأصلية',
      emoji: '✨',
      primaryColor: AppColors.purple,
      description: 'التقارب، الامتنان، وتأمل المشاعر',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDeckId != null) {
      _selectedDeck = widget.initialDeckId!;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final cards = await GameDataService.loadTypedCards();
    final customMaps = PreferencesService.getCustomCards();
    final customCards = customMaps.map((m) => CouplesCard.fromJson(m)).toList();
    _favorites = PreferencesService.getFavorites();

    if (mounted) {
      setState(() {
        _allCards = [...cards, ...customCards];
        _loading = false;
        _drawNextCard();
      });
    }
  }

  final Set<String> _seenInCurrentSession = {};

  List<String> get _currentFilterOptions {
    if (_selectedDeck == 'salon') {
      return [
        'الكل',
        'حدود الأهل',
        'الشغل والطموح',
        'الماديات والفلوس',
        'إدارة الغضب',
        'الخصوصية والموبايل',
        'التربية والتدين',
      ];
    } else if (_selectedDeck == 'first_year') {
      return ['الكل', 'لو خيروك', 'موقف', 'مصارحة'];
    } else if (_selectedDeck == 'mawada') {
      return ['الكل', 'تعارف', 'مودة', 'رحمة', 'قرب', 'سكينة'];
    } else if (_selectedDeck == 'deep_talk') {
      return [
        'الكل',
        'عشوائي وكسر جليد',
        'ذكريات وفضفضة',
        'عميق ومهم',
        'رؤيتنا والمستقبل'
      ];
    } else if (_selectedDeck == 'classic') {
      return [
        'الكل',
        'التقارب',
        'الامتنان',
        'تحديات لطيفة',
        'التخمين',
        'اختاروا سوا',
        'تأمل ومراجعة'
      ];
    }
    return ['الكل', 'سؤال', 'تحدي', 'موقف', 'مصارحة'];
  }

  List<CouplesCard> get _filteredCards {
    var pool = _allCards;

    // Filter by Deck
    if (_selectedDeck != 'all') {
      pool = pool.where((c) => c.deck == _selectedDeck).toList();
    }

    // Filter by Subcategory or Type
    if (_selectedFilter != 'الكل') {
      pool = pool.where((c) {
        if (_selectedDeck == 'salon') {
          return c.category == _selectedFilter;
        } else if (_selectedDeck == 'first_year') {
          return c.type == _selectedFilter;
        } else if (_selectedDeck == 'mawada' || _selectedDeck == 'deep_talk') {
          return c.category == _selectedFilter;
        } else if (_selectedDeck == 'classic') {
          return c.category == _selectedFilter;
        }
        return c.type == _selectedFilter || c.category == _selectedFilter;
      }).toList();
    }

    return pool;
  }

  void _drawNextCard() {
    final pool = _filteredCards;
    if (pool.isEmpty) {
      setState(() {
        _currentCard = null;
        _showFollowUp = false;
      });
      return;
    }

    final unseen =
        pool.where((c) => !_seenInCurrentSession.contains(c.id)).toList();
    final effectivePool = unseen.isNotEmpty ? unseen : pool;

    if (unseen.isEmpty) {
      _seenInCurrentSession.clear();
    }

    CouplesCard next;
    if (effectivePool.length == 1) {
      next = effectivePool.first;
    } else {
      do {
        next = effectivePool[_random.nextInt(effectivePool.length)];
      } while (next.id == _currentCard?.id && effectivePool.length > 1);
    }

    _seenInCurrentSession.add(next.id);
    PreferencesService.recordGameFinished(isCard: true, pointsEarned: 2);
    PreferencesService.setLastPlayedGame(title: 'كروت الأزواج: ${_activeDeckInfo.title}', route: 'couples_cards');
    PreferencesService.triggerHaptic(AppHapticType.selection);
    GameAudioService().playCardPlace();

    setState(() {
      _currentCard = next;
      _showFollowUp = false;
    });
  }

  void _toggleFavorite() async {
    if (_currentCard == null) return;
    await PreferencesService.toggleFavorite(_currentCard!.id, _favorites);
    PreferencesService.triggerHaptic(AppHapticType.medium);
    GameAudioService().playSuccess();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _favorites.contains(_currentCard!.id)
                ? 'تم حفظ البطاقة بالمفضلة 💜'
                : 'تمت إزالة البطاقة من المفضلة',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  DeckOption get _activeDeckInfo {
    return _decks.firstWhere(
      (d) => d.id == _selectedDeck,
      orElse: () => _decks.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFav =
        _currentCard != null && _favorites.contains(_currentCard!.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_activeDeckInfo.emoji} ${_activeDeckInfo.title}'),
        actions: [
          IconButton(
            tooltip: 'جلسة منظمة (10 دقائق)',
            icon: const Icon(Icons.timer_outlined, color: AppColors.purple),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StructuredSessionScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Decks Selector Bar
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _decks.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final deck = _decks[i];
                          final isSelected = _selectedDeck == deck.id;
                          return ChoiceChip(
                            avatar: Text(deck.emoji, style: const TextStyle(fontSize: 14)),
                            label: Text(
                              deck.title,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: deck.primaryColor.withValues(alpha: 0.15),
                            side: BorderSide(
                              color: isSelected ? deck.primaryColor : Colors.grey.withValues(alpha: 0.3),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedDeck = deck.id;
                                  _selectedFilter = 'الكل';
                                  _seenInCurrentSession.clear();
                                  _drawNextCard();
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subcategory Filter Chips
                    if (_currentFilterOptions.length > 1)
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _currentFilterOptions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, i) {
                            final filter = _currentFilterOptions[i];
                            final isSelected = _selectedFilter == filter;
                            return FilterChip(
                              label: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              onSelected: (val) {
                                setState(() {
                                  _selectedFilter = filter;
                                  _seenInCurrentSession.clear();
                                  _drawNextCard();
                                });
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Card Display Area
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _currentCard == null
                              ? Container(
                                  key: const ValueKey('empty'),
                                  padding: const EdgeInsets.all(24),
                                  decoration: AppDecorations.outlinedCard(),
                                  child: const Text(
                                    'لا توجد بطاقات في هذا التصنيف حالياً',
                                    style: TextStyle(color: AppColors.muted),
                                  ),
                                )
                              : Flip3DCard(
                                  key: ValueKey(_currentCard!.id),
                                  borderRadius: BorderRadius.circular(28),
                                  front: Interactive3DCard(
                                    borderRadius: BorderRadius.circular(28),
                                    maxTiltAngle: 0.16,
                                    enableGlare: true,
                                    child: _buildThematicCard(_currentCard!, isFav),
                                  ),
                                  back: FlipCardDefaultBack(
                                    emoji: _activeDeckInfo.emoji,
                                    label: _activeDeckInfo.title,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Always-visible Skip & Next Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _drawNextCard,
                            icon: const Icon(Icons.skip_next_rounded),
                            label: const Text('تخطي السؤال'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _activeDeckInfo.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _drawNextCard,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('بطاقة ثانية 🎲'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '${_filteredCards.length} بطاقة في هذه الباقة',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Builds a customized thematic card reflecting the real Egyptian game design:
  Widget _buildThematicCard(CouplesCard card, bool isFav) {
    final deck = card.deck;

    // 0. خطوبة صالونات (Salon): Warm Espresso, Mocha & Antique Cream
    if (deck == 'salon') {
      return Container(
        key: ValueKey(card.id),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C1E1A), Color(0xFF3E2723), Color(0xFF4E342E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFD7CCC8).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E120F).withValues(alpha: 0.45),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7CCC8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '☕ ${card.category}',
                    style: const TextStyle(
                      color: Color(0xFF3E2723),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.bookmark : Icons.bookmark_border,
                    color: isFav ? const Color(0xFFFFD54F) : Colors.white70,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: 'حفظ بالمفضلة',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'الموقف للنقاش والصراحة:',
                style: TextStyle(
                  color: Color(0xFFFFCC80),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              card.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFFDF8),
                fontSize: 19,
                height: 1.6,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (card.followUp.isNotEmpty) ...[
              const SizedBox(height: 16),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _showFollowUp
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFE082),
                      side: const BorderSide(color: Color(0xFFFFE082), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.psychology_alt_outlined, size: 18),
                    label: const Text(
                      'سؤال المتابعة والعمق 🤔 (اضغط للكشف)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => setState(() => _showFollowUp = true),
                  ),
                ),
                secondChild: InkWell(
                  onTap: () => setState(() => _showFollowUp = false),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF241512),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFCA28), width: 1.2),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.quiz_outlined, color: Color(0xFFFFCA28), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'سؤال متابعة إضافي (اضغط للإخفاء):',
                              style: TextStyle(
                                color: Color(0xFFFFCA28),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.followUp,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFFF9C4),
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (card.purpose.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '💡 الهدف: ${card.purpose}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFD7CCC8),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              'خطوبة صالونات ☕ • صراحة وتوافق من أول قعدة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8D6E63),
                fontSize: 10,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    // 1. سنة أولى جواز (First Year): Warm Terracotta & Cream style
    if (deck == 'first_year') {
      return Container(
        key: ValueKey(card.id),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFFD8BE), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE65100).withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    card.type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.bookmark : Icons.bookmark_border,
                    color: isFav ? const Color(0xFFE65100) : const Color(0xFF8D6E63),
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: 'حفظ بالمفضلة',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              card.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF261D1A),
                fontSize: 21,
                height: 1.6,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (card.purpose.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  card.purpose,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6D4C41),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'سنة أولى جواز 💍',
              style: TextStyle(
                color: Color(0xFFBF360C),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    // 2. مودة ورحمة (Mawada): Royal Emerald & Gold Islamic style
    if (deck == 'mawada') {
      return Container(
        key: ValueKey(card.id),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F3822), Color(0xFF1E5E3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFC5A059), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F3822).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A059),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${card.category} • ${card.type}',
                    style: const TextStyle(
                      color: Color(0xFF0F3822),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.bookmark : Icons.bookmark_border,
                    color: isFav ? const Color(0xFFFFD54F) : Colors.white70,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: 'حفظ بالمفضلة',
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              card.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                height: 1.6,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (card.purpose.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  card.purpose,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFECB3),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              '«وَمِنْ آيَاتِهِ أَنْ خَلَقَ لَكُم مِّنْ أَنفُسِكُمْ أَزْوَاجًا لِّتَسْكُنُوا إِلَيْهَا»',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFC5A059),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // 3. كلام من القلب (Deep Talk): Midnight Luxury & Cyan/Lavender style
    if (deck == 'deep_talk') {
      return Container(
        key: ValueKey(card.id),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          color: const Color(0xFF110D24),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF3B2B70), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.5),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4D8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    card.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.bookmark : Icons.bookmark_border,
                    color: isFav ? const Color(0xFFFFD15C) : Colors.white60,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: 'حفظ بالمفضلة',
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              card.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF1EEFF),
                fontSize: 21,
                height: 1.6,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (card.purpose.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                card.purpose,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9D65FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Deep Couples • كلام حقيقي من القلب 💬',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    // 4. Couples ولكن & Extreme (lakin): Radiant Fuchsia & Flame
    if (deck == 'lakin') {
      return Container(
        key: ValueKey(card.id),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC2185B), Color(0xFFE91E63), Color(0xFFFF5722)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC2185B).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${card.category} • ${card.type}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.bookmark : Icons.bookmark_border,
                    color: isFav ? AppColors.accentGold : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: 'حفظ بالمفضلة',
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              card.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                height: 1.6,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (card.purpose.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                card.purpose,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // 5. Couples Memes: Sunny Cheerful Amber
    if (deck == 'memes') {
      return Container(
        key: ValueKey(card.id),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97706).withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Couples Memes 😂',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.bookmark : Icons.bookmark_border,
                    color: isFav ? const Color(0xFFD97706) : Colors.brown,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: 'حفظ بالمفضلة',
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              card.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF451A03),
                fontSize: 21,
                height: 1.6,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (card.purpose.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                card.purpose,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Default / Classic: Sawha Primary Gradient
    return Container(
      key: ValueKey(card.id),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.floatingShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${card.category} • ${card.type}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.bookmark : Icons.bookmark_border,
                  color: isFav ? AppColors.accentGold : Colors.white,
                ),
                onPressed: _toggleFavorite,
                tooltip: 'حفظ بالمفضلة',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            card.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              height: 1.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (card.purpose.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              card.purpose,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
