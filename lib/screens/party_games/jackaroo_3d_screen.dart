import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../widgets/jackaroo_3d_board_view.dart';
import '../../widgets/unity/unity_player.dart';

/// Screen hosting the 3D Jackaroo experience.
/// Combines the realistic 3D tabletop board with Flutter HUD, cards hand, and interactive controls.
class Jackaroo3DScreen extends StatefulWidget {
  final List<String>? initialPlayers;
  final bool isOnline;
  final String? roomId;

  const Jackaroo3DScreen({
    super.key,
    this.initialPlayers,
    this.isOnline = false,
    this.roomId,
  });

  @override
  State<Jackaroo3DScreen> createState() => _Jackaroo3DScreenState();
}

class _Jackaroo3DScreenState extends State<Jackaroo3DScreen> {
  final GlobalKey<Jackaroo3DBoardViewState> _boardKey = GlobalKey<Jackaroo3DBoardViewState>();
  late final UnityPlayerController _unityController;
  final GameAudioService _audioService = GameAudioService();
  bool _isSoundEnabled = true;
  final String _activePlayer = 'أنت (الأزرق الملكي)';
  String _gameStatus = 'دورك للعب ورقة ثم تحريك حجر';
  bool _isTopDownView = true; // Defaults to exact photo view
  int _selectedCardIndex = 0; // Default selected card in hand
  String _lastPlayedCard = 'A♠';
  int _team1Score = 0;
  int _team2Score = 0;
  final List<String> _cardsHand = ['A♠', 'K♥', '7♦', '4♣', 'J♠'];
  final List<String> _deck = ['10♦', 'Q♣', '5♥', '2♠', '8♦', '6♠', '3♣', '9♥', 'K♦', 'A♣'];
  final List<String> _eventLog = [];

  static const Color _goldColor = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    try {
      _isSoundEnabled = PreferencesService.soundEnabled;
    } catch (_) {
      _isSoundEnabled = true;
    }
    _unityController = UnityPlayerController(
      isMock: true,
    );
    _unityController.messageStream.listen(_onUnityMessage);
    _onUnityCreated(_unityController);
  }

  @override
  void dispose() {
    _unityController.dispose();
    super.dispose();
  }

  void _onUnityCreated(UnityPlayerController controller) {
    controller.postJson('GameManager', 'InitJackaroo', {
      'isOnline': widget.isOnline,
      'roomId': widget.roomId ?? 'offline_room',
      'players': widget.initialPlayers ?? ['أنت', 'خالد', 'سارة', 'فهد'],
    });

    _addLog('تم بدء اتصال محرك 3D بنجاح');
  }

  void _onUnityMessage(UnityMessage message) {
    setState(() {
      _addLog('${message.gameObject}: ${message.methodName}');
      final payload = message.payloadJson;
      if (payload['statusText'] != null) {
        _gameStatus = payload['statusText'].toString();
      }
    });

    if (_isSoundEnabled) {
      PreferencesService.triggerHaptic(AppHapticType.light);
    }
  }

  void _addLog(String entry) {
    _eventLog.insert(0, entry);
    if (_eventLog.length > 10) _eventLog.removeLast();
  }

  void _playCard(int index) {
    if (index < 0 || index >= _cardsHand.length) return;
    final card = _cardsHand[index];

    setState(() {
      _selectedCardIndex = index;
      _lastPlayedCard = card;
      _gameStatus = 'تم لعب $card.. المس حجراً من أحجارك لتحريكه';
    });

    if (_isSoundEnabled) {
      _audioService.playCardDeal();
      PreferencesService.triggerHaptic(AppHapticType.selection);
    }

    _unityController.postJson('JackarooBoard', 'PlayCard', {
      'card': card,
      'player': 1,
      'targetMarbleIndex': 0,
    });

    _addLog('لعبت الورقة: $card');
  }

  void _onTurnFinished() {
    // Draw a new card from deck to replenish hand
    if (_cardsHand.isNotEmpty && _selectedCardIndex < _cardsHand.length) {
      final nextCard = _deck[math.Random().nextInt(_deck.length)];
      setState(() {
        _cardsHand[_selectedCardIndex] = nextCard;
      });
    }
  }

  void _sendEmojiReaction(String emoji) {
    _unityController.postJson('ChatManager', 'SpawnFloatingEmoji', {
      'emoji': emoji,
      'playerIndex': 1,
    });

    if (_isSoundEnabled) {
      _audioService.playTap();
      PreferencesService.triggerHaptic(AppHapticType.light);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('أرسلت تفاعل: $emoji', style: const TextStyle(fontFamily: 'Cairo')),
        duration: const Duration(milliseconds: 700),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }

  void _showVictoryDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2232),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _goldColor, width: 2),
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_rounded, color: _goldColor, size: 28),
            SizedBox(width: 8),
            Text(
              'مبروك الفوز!',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontFamily: 'Cairo', fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _goldColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _boardKey.currentState?.resetCamera();
            },
            child: const Text('جولة جديدة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2232),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _goldColor.withValues(alpha: 0.6)),
        ),
        title: const Text(
          'قوانين أوراق الجاكارو 92 حفرة',
          textAlign: TextAlign.center,
          style: TextStyle(color: _goldColor, fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RuleItem(card: 'الشيخ (K)', desc: 'خروج من البيت للبداية أو تحريك 13 خطوة وأكل أي حجر في الطريق.'),
              _RuleItem(card: 'الواحد (A)', desc: 'خروج من البيت للبداية أو تحريك خطوة واحدة أو 11 خطوة.'),
              _RuleItem(card: 'الأربعة (4)', desc: 'رجوع 4 خطوات للخلف (للاقتراب الفوري من بوابة الأمان!).'),
              _RuleItem(card: 'الولد (J)', desc: 'تبديل مكان حجرك مع أي حجر منافس على المسار العام.'),
              _RuleItem(card: 'السبعة (7)', desc: 'تحريك 7 خطوات، أو تقسيمها بين حجرين (مثلاً 4 + 3).'),
              _RuleItem(card: 'الخمسة (5)', desc: 'تحريك أي حجر 5 خطوات (حجرك، حجر شريكك، أو حجر منافس).'),
              _RuleItem(card: 'البنت (Q)', desc: 'تحريك 12 خطوة للأمام.'),
              _RuleItem(card: 'العشرة (10)', desc: 'تحريك 10 خطوات للأمام.'),
              _RuleItem(card: 'الشراكة', desc: 'الأزرق مع الأسود ضد الأخضر مع السماوي. عند إكمال 4 أحجار تساعد شريكك!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('فهمت', style: TextStyle(color: _goldColor, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _toggleSound() {
    setState(() {
      _isSoundEnabled = !_isSoundEnabled;
    });
    PreferencesService.setSoundEnabled(_isSoundEnabled);
    _audioService.isSoundEnabled = _isSoundEnabled;
    _unityController.postJson('AudioManager', 'SetMuted', {'muted': !_isSoundEnabled});
  }

  @override
  Widget build(BuildContext context) {
    final String currentCard = (_cardsHand.isNotEmpty && _selectedCardIndex < _cardsHand.length)
        ? _cardsHand[_selectedCardIndex]
        : 'A♠';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Realistic 92-Hole Jackaroo Board Viewport
          Positioned.fill(
            child: Jackaroo3DBoardView(
              key: _boardKey,
              activeCard: currentCard,
              lastPlayedCard: _lastPlayedCard,
              isTopDownView: _isTopDownView,
              onStatusMessage: (msg) {
                setState(() => _gameStatus = msg);
              },
              onScoresUpdated: (t1, t2) {
                setState(() {
                  _team1Score = t1;
                  _team2Score = t2;
                });
              },
              onGameWon: _showVictoryDialog,
              onTurnFinished: _onTurnFinished,
            ),
          ),

          // 2. HUD Overlay
          UnityViewOverlay(
            title: 'جاكارو 92 حفرة الواقعية',
            subtitle: widget.isOnline ? 'غرفة ${widget.roomId ?? "#101"}' : 'لوحة 92 حفرة • أزرق وأخضر وأسود وسماوي',
            isSoundEnabled: _isSoundEnabled,
            onExit: () => Navigator.of(context).pop(),
            onToggleSound: _toggleSound,
            floatingWidgets: [
              // Status Pill & Team Scores Pill
              Positioned(
                top: 70,
                left: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _goldColor.withValues(alpha: 0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, color: _goldColor, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '$_activePlayer • $_gameStatus',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Partnership Score Pill
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161C26).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('فريقك 🔵⚫: ', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            Text('$_team1Score/8', style: const TextStyle(color: _goldColor, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            Container(width: 1, height: 12, color: Colors.white24),
                            const SizedBox(width: 12),
                            const Text('المنافس 🟢🌐: ', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            Text('$_team2Score/8', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Reactions Palette (Right Side)
              Positioned(
                right: 12,
                top: 130,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ReactionButton(emoji: '🔥', onTap: () => _sendEmojiReaction('🔥')),
                      _ReactionButton(emoji: '😂', onTap: () => _sendEmojiReaction('😂')),
                      _ReactionButton(emoji: '🎯', onTap: () => _sendEmojiReaction('🎯')),
                      _ReactionButton(emoji: '💔', onTap: () => _sendEmojiReaction('💔')),
                    ],
                  ),
                ),
              ),
            ],
            bottomHud: _buildBottomCardsTray(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCardsTray() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.95),
            Colors.black.withValues(alpha: 0.75),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hand Title & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'أوراقك في اليد (اختر ورقة للعب):',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // View Toggle Button (Top-down Photo vs 3D Perspective)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isTopDownView = !_isTopDownView;
                      });
                      _boardKey.currentState?.setViewMode(_isTopDownView);
                      PreferencesService.triggerHaptic(AppHapticType.selection);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: _isTopDownView
                            ? _goldColor.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isTopDownView ? _goldColor : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isTopDownView ? Icons.camera_alt_rounded : Icons.view_in_ar_rounded,
                            color: _isTopDownView ? _goldColor : Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isTopDownView ? 'مظهر الصورة' : 'منظور 3D',
                            style: TextStyle(
                              color: _isTopDownView ? _goldColor : Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Rules Button
                  InkWell(
                    onTap: _showRulesDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.help_outline_rounded, color: _goldColor, size: 14),
                          SizedBox(width: 2),
                          Text('القوانين', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),

                  // Reset Camera
                  InkWell(
                    onTap: () {
                      _boardKey.currentState?.resetCamera();
                      _unityController.postJson('JackarooBoard', 'ResetCamera', {});
                      PreferencesService.triggerHaptic(AppHapticType.light);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, color: Colors.white70, size: 14),
                          SizedBox(width: 2),
                          Text('ضبط', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fanned Cards Hand
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_cardsHand.length, (idx) {
                final isSelected = _selectedCardIndex == idx;
                final cardValue = _cardsHand[idx];
                final isRed = cardValue.contains('♥') || cardValue.contains('♦');

                return GestureDetector(
                  onTap: () => _playCard(idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 56 : 50,
                    height: isSelected ? 84 : 76,
                    transform: Matrix4.translationValues(0, isSelected ? -8 : 0, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? _goldColor : Colors.grey.shade400,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? _goldColor.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.4),
                          blurRadius: isSelected ? 12 : 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            cardValue,
                            style: TextStyle(
                              color: isRed ? Colors.red.shade700 : Colors.black87,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          cardValue.characters.last,
                          style: TextStyle(
                            color: isRed ? Colors.red.shade700 : Colors.black87,
                            fontSize: 20,
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            cardValue.characters.first,
                            style: TextStyle(
                              color: isRed ? Colors.red.shade700 : Colors.black87,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _ReactionButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String card;
  final String desc;

  const _RuleItem({required this.card, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $card: ',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'Cairo',
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
