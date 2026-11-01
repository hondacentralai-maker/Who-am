import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/party_game_models.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_3d_card.dart';
import '../../widgets/arcade_3d_buzzer.dart';

class BesarahaWal3aScreen extends StatefulWidget {
  final List<String>? initialPlayers;

  const BesarahaWal3aScreen({super.key, this.initialPlayers});

  @override
  State<BesarahaWal3aScreen> createState() => _BesarahaWal3aScreenState();
}

class _BesarahaWal3aScreenState extends State<BesarahaWal3aScreen> {
  late List<BesarahaWal3aCard> _allCards;
  BesarahaWal3aCard? _currentCard;
  String _selectedFilter = 'الكل';
  int _score = 0;
  int _playerIndex = 0;
  List<String> _players = ['أحمد', 'سارة', 'كريم', 'نور'];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _allCards = BesarahaWal3aCard.defaultCards();
    if (widget.initialPlayers != null && widget.initialPlayers!.isNotEmpty) {
      _players = List.from(widget.initialPlayers!);
    }
    _drawNextCard();
  }

  List<BesarahaWal3aCard> get _filteredCards {
    if (_selectedFilter == 'بصراحة') {
      return _allCards.where((c) => c.type == BesarahaWal3aType.saraha).toList();
    } else if (_selectedFilter == 'أحكام ولعة') {
      return _allCards.where((c) => c.type == BesarahaWal3aType.dare).toList();
    } else if (_selectedFilter == 'كروت الحظ') {
      return _allCards.where((c) => c.type == BesarahaWal3aType.luck).toList();
    }
    return _allCards;
  }

  void _drawNextCard({bool completed = false}) {
    PreferencesService.triggerHaptic(AppHapticType.medium);
    if (completed) {
      GameAudioService().playSuccess();
    } else {
      GameAudioService().playCardPlace();
    }
    final pool = _filteredCards;
    if (pool.isEmpty) return;

    setState(() {
      if (completed && _currentCard != null) {
        _score += _currentCard!.points;
        PreferencesService.recordPartyGameFinished(pointsEarned: _currentCard!.points);
      }
      _currentCard = pool[_random.nextInt(pool.length)];
      if (_players.isNotEmpty) {
        _playerIndex = (_playerIndex + 1) % _players.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activePlayer = _players.isNotEmpty ? _players[_playerIndex] : 'اللاعب الحالي';

    return Scaffold(
      appBar: AppBar(
        title: const Text('بصراحة وتحديات ولعة 🔥'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5722).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF5722), size: 18),
                const SizedBox(width: 4),
                Text(
                  '$_score نقطة',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD84315)),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Player Turn Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.palePurple,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightPurple),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin_rounded, color: AppColors.purple, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'الدور الآن على: ',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    Text(
                      activePlayer,
                      style: const TextStyle(
                        color: AppColors.deepPurple,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip('الكل', '🃏'),
                    const SizedBox(width: 8),
                    _buildFilterChip('بصراحة', '💬'),
                    const SizedBox(width: 8),
                    _buildFilterChip('أحكام ولعة', '🔥'),
                    const SizedBox(width: 8),
                    _buildFilterChip('كروت الحظ', '🌟'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card Display
              Expanded(
                child: Center(
                  child: _currentCard == null
                      ? const Text('لا توجد بطاقات')
                      : _buildCardView(_currentCard!),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _drawNextCard(completed: false),
                      icon: const Icon(Icons.skip_next_rounded),
                      label: const Text('تمرير / اعتذار'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Arcade3DBuzzer(
                      label: 'نفذت! (+${_currentCard?.points ?? 10})',
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFFF5722),
                      height: 50,
                      onPressed: () => _drawNextCard(completed: true),
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

  Widget _buildFilterChip(String label, String emoji) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedFilter = label;
            _drawNextCard(completed: false);
          });
        }
      },
    );
  }

  Widget _buildCardView(BesarahaWal3aCard card) {
    LinearGradient gradient;
    Color badgeColor;

    if (card.type == BesarahaWal3aType.saraha) {
      gradient = AppColors.primaryGradient;
      badgeColor = AppColors.babyPink;
    } else if (card.type == BesarahaWal3aType.dare) {
      gradient = AppColors.pinkRoseGradient;
      badgeColor = const Color(0xFFFFE0E6);
    } else {
      gradient = AppColors.lavenderGradient;
      badgeColor = AppColors.paleLavender;
    }

    return Interactive3DCard(
      borderRadius: BorderRadius.circular(28),
      maxTiltAngle: 0.22,
      enableGlare: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadowColor,
              blurRadius: 18,
              offset: Offset(0, 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    card.title,
                    style: const TextStyle(
                      color: AppColors.deepPurple,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+${card.points} نقطة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              card.content,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${card.emoji} ${card.category}',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
