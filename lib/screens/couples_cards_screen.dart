import 'dart:math';
import 'package:flutter/material.dart';
import '../models/couples_card.dart';
import '../services/game_data_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import 'structured_session_screen.dart';

class CouplesCardsScreen extends StatefulWidget {
  const CouplesCardsScreen({super.key});

  @override
  State<CouplesCardsScreen> createState() => _CouplesCardsScreenState();
}

class _CouplesCardsScreenState extends State<CouplesCardsScreen> {
  List<CouplesCard> _allCards = [];
  Set<String> _favorites = {};
  CouplesCard? _currentCard;
  String _selectedCategory = 'الكل';
  bool _loading = true;
  final Random _random = Random();

  final List<String> _categories = [
    'الكل',
    'التقارب',
    'الامتنان',
    'تحديات لطيفة',
    'التخمين',
    'اختاروا سوا',
    'تأمل ومراجعة',
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

    if (mounted) {
      setState(() {
        _allCards = [...cards, ...customCards];
        _loading = false;
        _drawNextCard();
      });
    }
  }

  final Set<String> _seenInCurrentSession = {};

  List<CouplesCard> get _filteredCards {
    if (_selectedCategory == 'الكل') return _allCards;
    return _allCards
        .where((c) => c.category == _selectedCategory)
        .toList();
  }

  void _drawNextCard() {
    final pool = _filteredCards;
    if (pool.isEmpty) {
      setState(() => _currentCard = null);
      return;
    }

    // Filter cards not yet seen in current session
    final unseen = pool.where((c) => !_seenInCurrentSession.contains(c.id)).toList();
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

    setState(() => _currentCard = next);
  }

  void _toggleFavorite() async {
    if (_currentCard == null) return;
    await PreferencesService.toggleFavorite(_currentCard!.id, _favorites);
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

  @override
  Widget build(BuildContext context) {
    final isFav =
        _currentCard != null && _favorites.contains(_currentCard!.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('أسئلة وتحديات للأزواج'),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category selector chips
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final cat = _categories[i];
                          final isSelected = _selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedCategory = cat;
                                  _drawNextCard();
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Session Banner
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StructuredSessionScreen(),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.palePurple,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.lightPurple),
                        ),
                        child: const Row(
                          children: [
                            Text('✨', style: TextStyle(fontSize: 22)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'جلسة سريعة هادفة (10 دقائق)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.deepPurple,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '4 خطوات متسلسلة للتقارب والامتنان',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_back_ios_new_rounded,
                                size: 14, color: AppColors.purple),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

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
                                    'لا توجد بطاقات في هذا التصنيف',
                                    style: TextStyle(color: AppColors.muted),
                                  ),
                                )
                              : Container(
                                  key: ValueKey(_currentCard!.id),
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(26),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: AppShadows.floatingShadow,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${_currentCard!.category} • ${_currentCard!.type}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              isFav
                                                  ? Icons.bookmark
                                                  : Icons.bookmark_border,
                                              color: isFav
                                                  ? AppColors.accentGold
                                                  : Colors.white,
                                            ),
                                            onPressed: _toggleFavorite,
                                            tooltip: 'حفظ بالمفضلة',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        _currentCard!.text,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          height: 1.6,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (_currentCard!.purpose.isNotEmpty) ...[
                                        const SizedBox(height: 18),
                                        Text(
                                          _currentCard!.purpose,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.85),
                                            fontSize: 13,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Always-visible Skip & Next Buttons (P0 requirement)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _drawNextCard,
                            icon: const Icon(Icons.skip_next_rounded),
                            label: const Text('تخطي السؤال'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _drawNextCard,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('بطاقة ثانية'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '${_filteredCards.length} بطاقة متاحة',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
