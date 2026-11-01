import 'package:flutter/material.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../widgets/unity/unity_player.dart';

/// Screen hosting the 3D Jackaroo experience powered by the Unity Player Widget.
/// Combines the 3D engine viewport with Flutter HUD, cards hand, and interactive controls.
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
  late final UnityPlayerController _unityController;
  final GameAudioService _audioService = GameAudioService();
  bool _isSoundEnabled = true;
  final String _activePlayer = 'أنت (الأزرق)';
  String _gameStatus = 'دورك للعب ورقة';
  int _selectedCardIndex = 2; // Selected card in hand
  final List<String> _cardsHand = ['A♠', 'K♥', '7♦', '4♣', 'J♠'];
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
      // On platforms without compiled Unity library, use simulation mode seamlessly
      isMock: true,
    );
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

    _addLog('تم بدء اتصال محرك Unity 3D بنجاح');
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
      _gameStatus = 'تم لعب $card.. جاري تحريك الرخام';
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Unity 3D Viewport
          UnityPlayerWidget(
            controller: _unityController,
            initialScene: 'Jackaroo3D',
            onUnityCreated: _onUnityCreated,
            onUnityMessage: _onUnityMessage,
            debugMode: false,
          ),

          // 2. HUD Overlay
          UnityViewOverlay(
            title: 'جاكارو 3D الواقعية',
            subtitle: widget.isOnline ? 'غرفة ${widget.roomId ?? "#101"}' : 'لعب محلي ضد الذكاء الاصطناعي',
            isSoundEnabled: _isSoundEnabled,
            onExit: () => Navigator.of(context).pop(),
            onToggleSound: _toggleSound,
            floatingWidgets: [
              // Status Pill
              Positioned(
                top: 72,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _goldColor.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
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
                        Text(
                          '$_activePlayer • $_gameStatus',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
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
          // Hand Title & Action Button
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
              InkWell(
                onTap: () {
                  _unityController.postJson('JackarooBoard', 'ResetCamera', {});
                  PreferencesService.triggerHaptic(AppHapticType.light);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.crop_rotate_rounded, color: Colors.white70, size: 14),
                      SizedBox(width: 4),
                      Text('إعادة زاوية 3D', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
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
