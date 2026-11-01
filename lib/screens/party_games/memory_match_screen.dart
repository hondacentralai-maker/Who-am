import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/interactive_3d_card.dart';

class _MemoryCardItem {
  final int id;
  final String symbol;
  final String label;
  bool isFlipped = false;
  bool isMatched = false;

  _MemoryCardItem({
    required this.id,
    required this.symbol,
    required this.label,
  });
}

enum MemoryGameMode { solo, twoPlayers }

class MemoryMatchScreen extends StatefulWidget {
  final List<String>? initialPlayers;

  const MemoryMatchScreen({
    super.key,
    this.initialPlayers,
  });

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  final GameAudioService _audio = GameAudioService();

  MemoryGameMode _mode = MemoryGameMode.solo;
  String _selectedTheme = 'محبة وذكريات';

  late List<_MemoryCardItem> _cards;
  int? _firstFlippedIndex;
  int? _secondFlippedIndex;
  bool _isProcessing = false;

  int _movesCount = 0;
  int _secondsElapsed = 0;
  Timer? _timer;

  // 2-player stats
  int _player1Score = 0;
  int _player2Score = 0;
  int _activePlayer = 0; // 0 or 1
  String _p1Name = 'اللاعب 1';
  String _p2Name = 'اللاعب 2';

  bool _isGameCompleted = false;

  static const Map<String, List<Map<String, String>>> _themes = {
    'محبة وذكريات': [
      {'symbol': '💍', 'label': 'خاتم'},
      {'symbol': '🌹', 'label': 'وردة'},
      {'symbol': '💌', 'label': 'رسالة'},
      {'symbol': '☕', 'label': 'قهوة'},
      {'symbol': '🌙', 'label': 'قمر'},
      {'symbol': '🕯️', 'label': 'شمعة'},
      {'symbol': '✈️', 'label': 'سفر'},
      {'symbol': '💖', 'label': 'قلب'},
    ],
    'ضحك ومرح الشلة': [
      {'symbol': '🍿', 'label': 'فشار'},
      {'symbol': '🔥', 'label': 'ولعة'},
      {'symbol': '😎', 'label': 'روقان'},
      {'symbol': '🍕', 'label': 'بيتزا'},
      {'symbol': '🦆', 'label': 'بطوط'},
      {'symbol': '🚀', 'label': 'صاروخ'},
      {'symbol': '👑', 'label': 'الملك'},
      {'symbol': '⭐', 'label': 'نجم'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _initPlayers();
    _startNewGame();
    PreferencesService.recordPartyGamePlayed('memory_match');
  }

  void _initPlayers() {
    if (widget.initialPlayers != null && widget.initialPlayers!.length >= 2) {
      _p1Name = widget.initialPlayers![0];
      _p2Name = widget.initialPlayers![1];
    } else {
      final profile = PreferencesService.getCouplesProfile();
      _p1Name = profile.partner1Name;
      _p2Name = profile.partner2Name;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isGameCompleted && mounted) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  void _startNewGame() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _movesCount = 0;
    _player1Score = 0;
    _player2Score = 0;
    _activePlayer = 0;
    _isGameCompleted = false;
    _firstFlippedIndex = null;
    _secondFlippedIndex = null;
    _isProcessing = false;

    final baseItems = _themes[_selectedTheme] ?? _themes['محبة وذكريات']!;
    final cardPairs = <_MemoryCardItem>[];

    for (int i = 0; i < baseItems.length; i++) {
      final item = baseItems[i];
      // 2 cards for each symbol
      cardPairs.add(
        _MemoryCardItem(
          id: i * 2,
          symbol: item['symbol']!,
          label: item['label']!,
        ),
      );
      cardPairs.add(
        _MemoryCardItem(
          id: i * 2 + 1,
          symbol: item['symbol']!,
          label: item['label']!,
        ),
      );
    }

    cardPairs.shuffle(math.Random());
    setState(() {
      _cards = cardPairs;
    });

    _startTimer();
  }

  Future<void> _onCardTap(int index) async {
    if (_isProcessing) return;
    if (_cards[index].isFlipped || _cards[index].isMatched) return;

    _audio.playCardPlace();
    PreferencesService.triggerHaptic(AppHapticType.light);

    setState(() {
      _cards[index].isFlipped = true;
    });

    if (_firstFlippedIndex == null) {
      _firstFlippedIndex = index;
    } else {
      _secondFlippedIndex = index;
      _movesCount++;
      _isProcessing = true;

      final firstCard = _cards[_firstFlippedIndex!];
      final secondCard = _cards[_secondFlippedIndex!];

      if (firstCard.symbol == secondCard.symbol) {
        // MATCH!
        await Future<void>.delayed(const Duration(milliseconds: 320));
        if (!mounted) return;

        setState(() {
          firstCard.isMatched = true;
          secondCard.isMatched = true;
          _firstFlippedIndex = null;
          _secondFlippedIndex = null;
          _isProcessing = false;

          if (_mode == MemoryGameMode.twoPlayers) {
            if (_activePlayer == 0) {
              _player1Score++;
            } else {
              _player2Score++;
            }
          }
        });

        _audio.playMatchSuccess();
        PreferencesService.triggerHaptic(AppHapticType.heavy);

        // Check if all matched
        if (_cards.every((c) => c.isMatched)) {
          _timer?.cancel();
          setState(() {
            _isGameCompleted = true;
          });
          _audio.playVictory();
          PreferencesService.triggerHaptic(AppHapticType.heavy);
          CelebrationOverlay.show(context);
        }
      } else {
        // NO MATCH -> Flip back
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;

        setState(() {
          firstCard.isFlipped = false;
          secondCard.isFlipped = false;
          _firstFlippedIndex = null;
          _secondFlippedIndex = null;
          _isProcessing = false;

          if (_mode == MemoryGameMode.twoPlayers) {
            _activePlayer = (_activePlayer == 0) ? 1 : 0;
          }
        });

        _audio.playMarbleStep();
        PreferencesService.triggerHaptic(AppHapticType.selection);
      }
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF10141D) : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'شطرنج الذاكرة والمطابقة 🎴🧠',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'إعادة البدء',
            onPressed: _startNewGame,
          ),
          IconButton(
            icon: Icon(_mode == MemoryGameMode.solo ? Icons.person_rounded : Icons.people_alt_rounded),
            tooltip: _mode == MemoryGameMode.solo ? 'الوضع: فردي' : 'الوضع: ثنائي',
            onPressed: () {
              setState(() {
                _mode = _mode == MemoryGameMode.solo ? MemoryGameMode.twoPlayers : MemoryGameMode.solo;
                _startNewGame();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _mode == MemoryGameMode.solo
                        ? 'تم التبديل إلى التحدي الفردي ضد الوقت ⏱️'
                        : 'تم التبديل إلى التحدي الثنائي بالتناوب 👥',
                    textAlign: TextAlign.right,
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildStatsHeader(isDark),
                _buildThemeSelector(isDark),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCardsGrid(isDark),
                  ),
                ),
                _buildBottomBar(isDark),
              ],
            ),
          ),
          if (_isGameCompleted)
            Positioned(
              top: 12,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7E57C2), Color(0xFFE91E63)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  _mode == MemoryGameMode.solo
                      ? 'رائع! أكملت المطابقة في $_movesCount حركة خلال ${_formatTime(_secondsElapsed)}! 🌟🏆'
                      : (_player1Score > _player2Score
                          ? 'مبروك! فاز $_p1Name بـ $_player1Score نقاط! 🏆🎉'
                          : (_player2Score > _player1Score
                              ? 'مبروك! فاز $_p2Name بـ $_player2Score نقاط! 🏆🎉'
                              : 'تعادل تاريخي بين الشريكين بـ $_player1Score نقاط لكل منهما! 🤝')),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A212D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _mode == MemoryGameMode.solo
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill(Icons.timer_outlined, 'الوقت', _formatTime(_secondsElapsed), Colors.orange),
                _buildStatPill(Icons.touch_app_outlined, 'الحركات', '$_movesCount', Colors.purple),
                _buildStatPill(
                  Icons.check_circle_outline,
                  'المطابقة',
                  '${_cards.where((c) => c.isMatched).length ~/ 2} / ${_cards.length ~/ 2}',
                  Colors.green,
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPlayerDuelPill(_p1Name, _player1Score, _activePlayer == 0, const Color(0xFFE91E63)),
                Text(
                  _formatTime(_secondsElapsed),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey),
                ),
                _buildPlayerDuelPill(_p2Name, _player2Score, _activePlayer == 1, const Color(0xFF2196F3)),
              ],
            ),
    );
  }

  Widget _buildStatPill(IconData icon, String title, String val, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerDuelPill(String name, int score, bool isActive, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? color : Colors.transparent, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: Text(
              name.characters.first,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isActive ? color : null)),
              Text('$score أزواج', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _themes.keys.map((themeName) {
          final isSelected = _selectedTheme == themeName;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(themeName),
              selected: isSelected,
              onSelected: (val) {
                if (val && _selectedTheme != themeName) {
                  setState(() {
                    _selectedTheme = themeName;
                    _startNewGame();
                  });
                }
              },
              selectedColor: AppColors.purple.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.deepPurple : null,
                fontWeight: isSelected ? FontWeight.bold : null,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardsGrid(bool isDark) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: _cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final card = _cards[index];
        return _buildMemoryCard(card, index, isDark);
      },
    );
  }

  Widget _buildMemoryCard(_MemoryCardItem card, int index, bool isDark) {
    final showFace = card.isFlipped || card.isMatched;

    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: Interactive3DCard(
        borderRadius: BorderRadius.circular(16),
        maxTiltAngle: 0.15,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: card.isMatched
                ? (isDark ? const Color(0xFF163828) : const Color(0xFFE8F5E9))
                : (showFace
                    ? (isDark ? const Color(0xFF222B38) : Colors.white)
                    : (isDark ? const Color(0xFF2D1B36) : const Color(0xFF7E57C2))),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: card.isMatched
                  ? const Color(0xFF4CAF50)
                  : (showFace ? const Color(0xFFBA68C8) : const Color(0xFF9575CD)),
              width: card.isMatched ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: showFace ? 0.08 : 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: showFace
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card.symbol,
                        style: const TextStyle(fontSize: 34),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: card.isMatched ? const Color(0xFF2E7D32) : Colors.grey,
                        ),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '✨',
                        style: TextStyle(fontSize: 26),
                      ),
                      SizedBox(height: 4),
                      Icon(
                        Icons.touch_app_outlined,
                        size: 16,
                        color: Colors.white70,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startNewGame,
              icon: const Icon(Icons.shuffle_rounded),
              label: const Text('خلط الكروت وجولة جديدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

