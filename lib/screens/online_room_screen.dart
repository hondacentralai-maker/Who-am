import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/character.dart';
import '../models/couples_card.dart';
import '../models/know_me_question.dart';
import '../models/partner_presence.dart';
import '../services/game_data_service.dart';
import '../services/preferences_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'partner_link_dialog.dart';
import 'party_games_hub_screen.dart';

class OnlineRoomScreen extends StatefulWidget {
  const OnlineRoomScreen({super.key});

  @override
  State<OnlineRoomScreen> createState() => _OnlineRoomScreenState();
}

class _OnlineRoomScreenState extends State<OnlineRoomScreen> {
  bool _isLoading = false;
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _checkAuthAndAct(VoidCallback onAuthorized) {
    if (!SupabaseService.isLoggedIn) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تسجيل الدخول مطلوب'),
          content: const Text(
            'يتطلب اللعب عن بعد تسجيل الدخول لحفظ أمان الغرفة والتواصل المباشر بين الشريكين.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
                if (res == true && mounted) {
                  onAuthorized();
                }
              },
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      );
    } else {
      onAuthorized();
    }
  }

  Future<void> _createRoom() async {
    setState(() => _isLoading = true);
    try {
      final room = await SupabaseService.createRoom();
      final profile = PreferencesService.getCouplesProfile();
      if (profile.isPartnerLinked) {
        SupabaseService.sendPartnerInvite(
          targetPartnerIdentifier: profile.linkedPartnerEmail!,
          roomId: room['id'],
          roomCode: room['room_code'],
          hostName: profile.partner1Name,
        );
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveOnlineRoomScreen(
              roomId: room['id'],
              roomCode: room['room_code'],
              isHost: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('تعذر إنشاء الغرفة: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز الغرفة يتكون من 6 أحرف')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final room = await SupabaseService.joinRoom(code);
      if (room == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text('الغرفة غير موجودة أو بدأت بالفعل.'),
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveOnlineRoomScreen(
              roomId: room['id'],
              roomCode: code,
              isHost: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('تعذر الانضمام: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اللعب عن بعد (غرف Supabase)')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text('🌐', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 10),
                    const Text(
                      'غرفة اللعب المباشر',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'العبوا معًا حتى لو كنتم في مدينتين مختلفتين عبر المزامنة المباشرة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Linked Partner Bar
              Builder(
                builder: (context) {
                  final profile = PreferencesService.getCouplesProfile();
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.palePurple,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded, color: AppColors.accentPink),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.isPartnerLinked
                                        ? 'الشريك المرتبط: ${profile.linkedPartnerEmail}'
                                        : 'لم يتم ربط شريك دائم بعد',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    profile.isPartnerLinked
                                        ? 'دعوة مباشرة ستُرسل فور إنشاء الغرفة بضغطة واحدة 📲'
                                        : 'اربط حساب شريكك لتسهيل الدخول دون الحاجة لرموز',
                                    style: const TextStyle(color: AppColors.muted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                PartnerLinkDialog.show(
                                  context,
                                  onLinked: () => setState(() {}),
                                );
                              },
                              child: Text(profile.isPartnerLinked ? 'تعديل' : 'ربط 🔗'),
                            ),
                          ],
                        ),
                        if (profile.isPartnerLinked) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.purple,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () => _checkAuthAndAct(_createRoom),
                              icon: const Icon(Icons.send_rounded),
                              label: const Text('دعوة الشريك والبدء فوراً 💌'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Create Room Option
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppDecorations.outlinedCard(),
                child: Column(
                  children: [
                    const Text(
                      'إنشاء غرفة جديدة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'أنشئ رمزًا وشاركه مع شريكك للبدء فورًا',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _checkAuthAndAct(_createRoom),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('إنشاء غرفة الآن'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Join Room Option
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppDecorations.outlinedCard(),
                child: Column(
                  children: [
                    const Text(
                      'الانضمام إلى غرفة موجودة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      maxLength: 6,
                      style: const TextStyle(
                        letterSpacing: 6,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.deepPurple,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'ABCD12',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _checkAuthAndAct(_joinRoom),
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('انضمام إلى الغرفة'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Party Games Hub Quick Access
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.palePurple.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('🥳', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ألعاب الجلسات والتجمعات',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'هل أنتم مجتمعون في نفس المكان؟ العبوا فوراً بدون إنترنت!',
                            style: TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PartyGamesHubScreen(),
                          ),
                        );
                      },
                      child: const Text('دخول'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Center(
                  child: Text(
                    SupabaseService.isLoggedIn
                        ? 'مسجل الدخول كـ: ${SupabaseService.currentUser?.email}'
                        : 'لم تسجل الدخول بعد',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Online Game Modes ───────────────────────────────────
enum OnlineGameMode { cards, knowMe, guessWho }

extension OnlineGameModeExt on OnlineGameMode {
  String get arabicTitle {
    switch (this) {
      case OnlineGameMode.cards:
        return 'بطاقات الحوار';
      case OnlineGameMode.knowMe:
        return 'قد إيش تعرفني؟';
      case OnlineGameMode.guessWho:
        return 'خمن الشخصية';
    }
  }

  String get emoji {
    switch (this) {
      case OnlineGameMode.cards:
        return '💬';
      case OnlineGameMode.knowMe:
        return '💜';
      case OnlineGameMode.guessWho:
        return '🎭';
    }
  }
}

// ─── Active Online Room Screen ───────────────────────────
class ActiveOnlineRoomScreen extends StatefulWidget {
  final String roomId;
  final String roomCode;
  final bool isHost;
  final List<CouplesCard>? initialCards;
  final List<KnowMeQuestion>? initialKnowMeQuestions;
  final List<Character>? initialCharacters;

  const ActiveOnlineRoomScreen({
    super.key,
    required this.roomId,
    required this.roomCode,
    required this.isHost,
    this.initialCards,
    this.initialKnowMeQuestions,
    this.initialCharacters,
  });

  @override
  State<ActiveOnlineRoomScreen> createState() =>
      _ActiveOnlineRoomScreenState();
}

class _ActiveOnlineRoomScreenState extends State<ActiveOnlineRoomScreen> {
  // Mode State
  OnlineGameMode _activeMode = OnlineGameMode.cards;

  // Realtime & Cards State
  RealtimeChannel? _channel;
  List<CouplesCard> _cards = [];
  CouplesCard? _currentCard;
  final Random _random = Random();

  // Presence & Connection State
  ConnectionStatus _myConnectionStatus = ConnectionStatus.reconnecting;
  ConnectionStatus _partnerPresenceStatus = ConnectionStatus.offline;
  String _partnerDisplayName = '';
  Timer? _gracePeriodTimer;

  // Floating Reactions State
  final List<_FloatingEmoji> _activeFloatingEmojis = [];

  // Know-Me Multiplayer State
  List<KnowMeQuestion> _knowMeQuestions = [];
  int _knowMeIndex = 0;
  int _knowMeStep = 0; // 0 = Secret Input, 1 = Guess Input, 2 = Comparison & Score
  String _knowMeAnsweringRole = 'host';
  String _knowMeSecretAnswer = '';
  String _knowMeGuessAnswer = '';
  int _knowMeScore = 0;
  final TextEditingController _knowMeSecretController = TextEditingController();
  final TextEditingController _knowMeGuessController = TextEditingController();

  // Guess-Who Multiplayer State
  List<Character> _guessWhoCharacters = [];
  Character? _mySecretCharacter;
  Character? _partnerSecretCharacter;
  bool _mySecretConfirmed = false;
  bool _partnerSecretConfirmed = false;
  final Set<String> _eliminatedCharacterIds = {};
  String _guessWhoTurnRole = 'host';
  String _lastQuestionText = '';
  String? _lastAnswerText;
  String? _winnerRole;

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  Future<void> _initRoom() async {
    if (widget.initialCards != null && widget.initialCards!.isNotEmpty) {
      _cards = List.from(widget.initialCards!);
      _currentCard = _cards.first;
    } else {
      _cards = await GameDataService.loadTypedCards();
      if (_cards.isNotEmpty) {
        _currentCard = _cards.first;
      }
    }

    if (widget.initialKnowMeQuestions != null &&
        widget.initialKnowMeQuestions!.isNotEmpty) {
      _knowMeQuestions = List.from(widget.initialKnowMeQuestions!);
    } else {
      _knowMeQuestions = await GameDataService.loadKnowMeQuestions();
    }

    if (widget.initialCharacters != null &&
        widget.initialCharacters!.isNotEmpty) {
      _guessWhoCharacters = List.from(widget.initialCharacters!);
    } else {
      _guessWhoCharacters = await GameDataService.loadCharacters();
    }

    // Subscribe to room with presence & connection tracking + all broadcast handlers
    _channel = SupabaseService.subscribeToRoomWithPresence(
      roomId: widget.roomId,
      isHost: widget.isHost,
      onEvent: (payload) {
        final eventType = payload['event_type'];
        if (eventType == 'card_revealed' && mounted) {
          PreferencesService.triggerHaptic(AppHapticType.light);
          final cardId = payload['card_id'];
          final found = _cards.firstWhere(
            (c) => c.id == cardId,
            orElse: () => _cards.first,
          );
          setState(() {
            _currentCard = found;
          });
        }
      },
      onReaction: (payload) {
        final emoji = payload['emoji'];
        if (emoji != null && emoji is String && mounted) {
          _triggerReaction(emoji, isLocal: false);
        }
      },
      onGameModeChange: (modeStr) {
        if (!mounted) return;
        OnlineGameMode? foundMode;
        for (final m in OnlineGameMode.values) {
          if (m.name == modeStr) {
            foundMode = m;
            break;
          }
        }
        if (foundMode != null && foundMode != _activeMode) {
          setState(() => _activeMode = foundMode!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('انتقل الشريك إلى: ${foundMode.arabicTitle} ${foundMode.emoji}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onKnowMeAction: (payload) {
        if (!mounted) return;
        final action = payload['action'];
        final data = payload['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          if (action == 'secret_submitted') {
            _knowMeSecretAnswer = data['secret']?.toString() ?? '';
            _knowMeStep = 1;
            PreferencesService.triggerHaptic(AppHapticType.selection);
          } else if (action == 'guess_submitted') {
            _knowMeGuessAnswer = data['guess']?.toString() ?? '';
            _knowMeStep = 2;
            PreferencesService.triggerHaptic(AppHapticType.selection);
          } else if (action == 'score_awarded') {
            final pts = data['points'] as int? ?? 10;
            _knowMeScore += pts;
            PreferencesService.triggerHaptic(AppHapticType.medium);
          } else if (action == 'next_question') {
            _knowMeStep = 0;
            _knowMeSecretAnswer = '';
            _knowMeGuessAnswer = '';
            _knowMeSecretController.clear();
            _knowMeGuessController.clear();
            _knowMeAnsweringRole =
                _knowMeAnsweringRole == 'host' ? 'guest' : 'host';
            _knowMeIndex++;
            PreferencesService.triggerHaptic(AppHapticType.light);
          }
        });
      },
      onGuessWhoAction: (payload) {
        if (!mounted) return;
        final action = payload['action'];
        final data = payload['data'] as Map<String, dynamic>? ?? {};
        final actorRole = payload['actor_role']?.toString();
        setState(() {
          if (action == 'secret_confirmed') {
            _partnerSecretConfirmed = true;
            final charId = data['character_id']?.toString();
            if (charId != null && _guessWhoCharacters.isNotEmpty) {
              _partnerSecretCharacter = _guessWhoCharacters.firstWhere(
                (c) => c.id == charId,
                orElse: () => _guessWhoCharacters.first,
              );
            }
            PreferencesService.triggerHaptic(AppHapticType.selection);
          } else if (action == 'ask_question') {
            _lastQuestionText = data['question']?.toString() ?? '';
            _lastAnswerText = null;
            PreferencesService.triggerHaptic(AppHapticType.light);
          } else if (action == 'answer_given') {
            _lastAnswerText = data['answer']?.toString();
            _guessWhoTurnRole =
                _guessWhoTurnRole == 'host' ? 'guest' : 'host';
            PreferencesService.triggerHaptic(AppHapticType.selection);
          } else if (action == 'final_guess') {
            final isWin = data['is_win'] == true;
            if (isWin) {
              _winnerRole = actorRole;
              PreferencesService.triggerHaptic(AppHapticType.medium);
            }
          } else if (action == 'restart_game') {
            _mySecretCharacter = null;
            _partnerSecretCharacter = null;
            _mySecretConfirmed = false;
            _partnerSecretConfirmed = false;
            _eliminatedCharacterIds.clear();
            _winnerRole = null;
            _lastQuestionText = '';
            _lastAnswerText = null;
            PreferencesService.triggerHaptic(AppHapticType.light);
          }
        });
      },
      onConnectionStatus: (status) {
        if (!mounted) return;
        setState(() {
          if (status == RealtimeSubscribeStatus.subscribed) {
            _myConnectionStatus = ConnectionStatus.online;
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            _myConnectionStatus = ConnectionStatus.reconnecting;
          } else if (status == RealtimeSubscribeStatus.closed) {
            _myConnectionStatus = ConnectionStatus.offline;
          }
        });
      },
      onPresenceChange: (presences) {
        if (!mounted) return;
        _updatePartnerPresence(presences);
      },
    );
  }

  void _triggerReaction(String emoji, {bool isLocal = false}) {
    if (isLocal) {
      PreferencesService.triggerHaptic(AppHapticType.light);
      if (_channel != null) {
        SupabaseService.sendReaction(
          channel: _channel!,
          emoji: emoji,
          actorRole: widget.isHost ? 'host' : 'guest',
        );
      }
    } else {
      PreferencesService.triggerHaptic(AppHapticType.selection);
    }

    final id = UniqueKey().toString();
    final randomOffset = (_random.nextDouble() - 0.5) * 160.0;
    final drift = (_random.nextDouble() - 0.5) * 80.0;

    if (mounted) {
      setState(() {
        _activeFloatingEmojis.add(
          _FloatingEmoji(
            id: id,
            emoji: emoji,
            startXOffset: randomOffset,
            driftX: drift,
            createdAt: DateTime.now(),
          ),
        );
      });

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() {
            _activeFloatingEmojis.removeWhere((e) => e.id == id);
          });
        }
      });
    }
  }

  void _updatePartnerPresence(List<PartnerPresence> presences) {
    final targetRole = widget.isHost ? 'guest' : 'host';
    PartnerPresence? partner;
    for (final p in presences) {
      if (p.role == targetRole) {
        partner = p;
        break;
      }
    }

    if (partner != null) {
      _gracePeriodTimer?.cancel();
      final wasNotOnline = _partnerPresenceStatus != ConnectionStatus.online;
      setState(() {
        _partnerPresenceStatus = ConnectionStatus.online;
        _partnerDisplayName = partner!.displayName.isNotEmpty
            ? partner.displayName
            : (widget.isHost ? 'الشريك' : 'المضيف');
      });
      if (wasNotOnline && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('انضم $_partnerDisplayName للغرفة وهو متصل الآن! 🟢'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } else {
      if (_partnerPresenceStatus == ConnectionStatus.online) {
        setState(() {
          _partnerPresenceStatus = ConnectionStatus.reconnecting;
        });
        _gracePeriodTimer?.cancel();
        _gracePeriodTimer = Timer(const Duration(seconds: 4), () {
          if (mounted &&
              _partnerPresenceStatus == ConnectionStatus.reconnecting) {
            setState(() {
              _partnerPresenceStatus = ConnectionStatus.offline;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('انقطع اتصال الشريك من الغرفة ⚪'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      } else if (_partnerPresenceStatus != ConnectionStatus.reconnecting) {
        setState(() {
          _partnerPresenceStatus = ConnectionStatus.offline;
        });
      }
    }
  }

  @override
  void dispose() {
    _gracePeriodTimer?.cancel();
    _knowMeSecretController.dispose();
    _knowMeGuessController.dispose();
    if (_channel != null) {
      SupabaseService.leaveRoom(
        channel: _channel!,
        roomId: widget.roomId,
        actorRole: widget.isHost ? 'host' : 'guest',
      );
    }
    super.dispose();
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('تم نسخ رمز الغرفة: ${widget.roomCode} 📋 شاركه مع شريكك!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendPartnerInvite() async {
    final profile = PreferencesService.getCouplesProfile();
    if (!profile.isPartnerLinked) {
      PartnerLinkDialog.show(context, onLinked: () => setState(() {}));
      return;
    }

    final target = profile.linkedPartnerEmail!;
    final success = await SupabaseService.sendPartnerInvite(
      targetPartnerIdentifier: target,
      roomId: widget.roomId,
      roomCode: widget.roomCode,
      hostName: profile.partner1Name,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            content: Text(
              'تم إرسال دعوة مباشرة لشريكك ($target)! 📲 ستظهر له نافذة الانضمام فوراً.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر إرسال الدعوة المباشرة، يمكنك مشاركة الرمز يدوياً 📋'),
          ),
        );
      }
    }
  }

  void _confirmLeaveRoom() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مغادرة الغرفة'),
        content: const Text('هل ترغب حقاً في مغادرة هذه الغرفة وإنهاء الجلسة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('البقاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );
  }

  void _setGameMode(OnlineGameMode mode) {
    if (mode == _activeMode) return;
    PreferencesService.triggerHaptic(AppHapticType.selection);
    setState(() => _activeMode = mode);
    if (_channel != null) {
      SupabaseService.sendGameModeChange(
        channel: _channel!,
        mode: mode.name,
        actorRole: widget.isHost ? 'host' : 'guest',
      );
    }
  }

  // ─── Mode 1: Cards Methods ──────────────────────────────
  void _nextCard() async {
    if (_cards.isEmpty) return;
    PreferencesService.triggerHaptic(AppHapticType.medium);
    final next = _cards[_random.nextInt(_cards.length)];
    setState(() => _currentCard = next);

    if (SupabaseService.isInitialized) {
      await SupabaseService.sendRoomEvent(
        roomId: widget.roomId,
        eventType: 'card_revealed',
        actorRole: widget.isHost ? 'host' : 'guest',
        cardId: next.id,
      );
    }
  }

  // ─── Mode 2: Know-Me Methods ────────────────────────────
  void _awardKnowMePoints(int pts) async {
    setState(() => _knowMeScore += pts);
    PreferencesService.triggerHaptic(AppHapticType.medium);
    await PreferencesService.recordGameFinished(
      isKnowMe: true,
      pointsEarned: pts,
    );
    if (_channel != null) {
      SupabaseService.sendKnowMeAction(
        channel: _channel!,
        action: 'score_awarded',
        actorRole: widget.isHost ? 'host' : 'guest',
        data: {'points': pts},
      );
    }
    _nextKnowMeQuestion();
  }

  void _nextKnowMeQuestion() {
    setState(() {
      _knowMeStep = 0;
      _knowMeSecretAnswer = '';
      _knowMeGuessAnswer = '';
      _knowMeSecretController.clear();
      _knowMeGuessController.clear();
      _knowMeAnsweringRole = _knowMeAnsweringRole == 'host' ? 'guest' : 'host';
      _knowMeIndex++;
    });
    PreferencesService.triggerHaptic(AppHapticType.light);
    if (_channel != null) {
      SupabaseService.sendKnowMeAction(
        channel: _channel!,
        action: 'next_question',
        actorRole: widget.isHost ? 'host' : 'guest',
      );
    }
  }

  // ─── Mode 3: Guess-Who Methods ──────────────────────────
  void _askGuessWhoQuestion(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _lastQuestionText = text.trim();
      _lastAnswerText = null;
    });
    PreferencesService.triggerHaptic(AppHapticType.light);
    if (_channel != null) {
      SupabaseService.sendGuessWhoAction(
        channel: _channel!,
        action: 'ask_question',
        actorRole: widget.isHost ? 'host' : 'guest',
        data: {'question': text.trim()},
      );
    }
  }

  void _answerGuessWho(String answer) {
    setState(() {
      _lastAnswerText = answer;
      _guessWhoTurnRole = _guessWhoTurnRole == 'host' ? 'guest' : 'host';
    });
    PreferencesService.triggerHaptic(AppHapticType.selection);
    if (_channel != null) {
      SupabaseService.sendGuessWhoAction(
        channel: _channel!,
        action: 'answer_given',
        actorRole: widget.isHost ? 'host' : 'guest',
        data: {'answer': answer},
      );
    }
  }

  void _restartGuessWhoGame() {
    setState(() {
      _mySecretCharacter = null;
      _partnerSecretCharacter = null;
      _mySecretConfirmed = false;
      _partnerSecretConfirmed = false;
      _eliminatedCharacterIds.clear();
      _winnerRole = null;
      _lastQuestionText = '';
      _lastAnswerText = null;
    });
    PreferencesService.triggerHaptic(AppHapticType.light);
    if (_channel != null) {
      SupabaseService.sendGuessWhoAction(
        channel: _channel!,
        action: 'restart_game',
        actorRole: widget.isHost ? 'host' : 'guest',
      );
    }
  }

  void _showFinalGuessDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تخمين الشخصية السرية للشريك 🎯'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.8,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: _guessWhoCharacters.length,
            itemBuilder: (cCtx, i) {
              final c = _guessWhoCharacters[i];
              return InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  final isWin = c.id == _partnerSecretCharacter?.id;
                  if (isWin) {
                    setState(
                        () => _winnerRole = widget.isHost ? 'host' : 'guest');
                    PreferencesService.triggerHaptic(AppHapticType.medium);
                    if (_channel != null) {
                      SupabaseService.sendGuessWhoAction(
                        channel: _channel!,
                        action: 'final_guess',
                        actorRole: widget.isHost ? 'host' : 'guest',
                        data: {'guessed_id': c.id, 'is_win': true},
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'للأسف ليست ${c.name}! استمر في طرح الأسئلة واستبعاد الشخصيات 🔍'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.palePurple),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 2),
                      Text(c.name,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── UI Builders ────────────────────────────────────────
  Widget _buildPresenceBadge({
    required String title,
    required ConnectionStatus status,
    required bool isMe,
  }) {
    Color bg;
    Color fg;
    IconData icon;
    String statusLabel;

    switch (status) {
      case ConnectionStatus.online:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = Icons.check_circle_rounded;
        statusLabel = 'متصل';
        break;
      case ConnectionStatus.reconnecting:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
        icon = Icons.wifi_protected_setup_rounded;
        statusLabel = 'يعيد الاتصال';
        break;
      case ConnectionStatus.offline:
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF757575);
        icon = Icons.cloud_off_rounded;
        statusLabel = 'غير متصل';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            '$title: $statusLabel',
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameModeSwitcher() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.palePurple),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: OnlineGameMode.values.map((mode) {
          final isSelected = mode == _activeMode;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _setGameMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${mode.emoji} ${mode.arabicTitle}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.ink,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCardsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppShadows.floatingShadow,
              ),
              child: _currentCard == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentCard!.category} • متزامن',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _currentCard!.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.6,
                          ),
                        ),
                        if (_currentCard!.purpose.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            _currentCard!.purpose,
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
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _nextCard,
          icon: const Icon(Icons.sync_rounded),
          label: const Text('سحب بطاقة جديدة متزامنة'),
        ),
      ],
    );
  }

  Widget _buildKnowMeView() {
    if (_knowMeQuestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final question = _knowMeQuestions[_knowMeIndex % _knowMeQuestions.length];
    final isMyTurn = (widget.isHost && _knowMeAnsweringRole == 'host') ||
        (!widget.isHost && _knowMeAnsweringRole == 'guest');
    final partnerName = _partnerDisplayName.isNotEmpty
        ? _partnerDisplayName
        : (widget.isHost ? 'الشريك' : 'المضيف');
    final answeringName = _knowMeAnsweringRole == 'host'
        ? (widget.isHost ? 'أنت' : partnerName)
        : (!widget.isHost ? 'أنت' : partnerName);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppShadows.cardShadow,
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'قد إيش تعرفني؟ • ${question.category} (النقاط: $_knowMeScore)',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  question.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'دور الإجابة السرية: $answeringName',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Step 0: Secret Input
          if (_knowMeStep == 0) ...[
            if (isMyTurn) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.outlinedCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            color: AppColors.purple, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'اكتب إجابتك السرية هنا:',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'شريكك لن يرى إجابتك، بل سيحاول تخمينها أولاً!',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _knowMeSecretController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'اكتب إجابتك الصادقة هنا...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        final text = _knowMeSecretController.text.trim();
                        if (text.isEmpty) return;
                        setState(() {
                          _knowMeSecretAnswer = text;
                          _knowMeStep = 1;
                        });
                        PreferencesService.triggerHaptic(AppHapticType.light);
                        if (_channel != null) {
                          SupabaseService.sendKnowMeAction(
                            channel: _channel!,
                            action: 'secret_submitted',
                            actorRole: widget.isHost ? 'host' : 'guest',
                            data: {'secret': text},
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('تأكيد وقفل الإجابة السرية 🔒'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: AppDecorations.outlinedCard(),
                child: Column(
                  children: [
                    const Text('✍️', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 10),
                    Text(
                      'بانتظار أن يكتب $answeringName إجابته السرية...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'استعد لتخمين إجابة شريكك فور تأكيدها 💭',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Step 1: Guessing Input
          if (_knowMeStep == 1) ...[
            if (!isMyTurn) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.outlinedCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.psychology_outlined,
                            color: AppColors.purple, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'خمن إجابة شريكك:',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'شريكك كتب إجابته وقفلها، ماذا تتوقع أن تكون إجابته؟',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _knowMeGuessController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'اكتب تخمينك هنا...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        final text = _knowMeGuessController.text.trim();
                        if (text.isEmpty) return;
                        setState(() {
                          _knowMeGuessAnswer = text;
                          _knowMeStep = 2;
                        });
                        PreferencesService.triggerHaptic(AppHapticType.light);
                        if (_channel != null) {
                          SupabaseService.sendKnowMeAction(
                            channel: _channel!,
                            action: 'guess_submitted',
                            actorRole: widget.isHost ? 'host' : 'guest',
                            data: {'guess': text},
                          );
                        }
                      },
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('إرسال التخمين والكشف 🚀'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: AppDecorations.outlinedCard(),
                child: const Column(
                  children: [
                    Text('💭', style: TextStyle(fontSize: 36)),
                    SizedBox(height: 10),
                    Text(
                      'تم قفل إجابتك السرية بنجاح 🔒',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.ink),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'شريكك يكتب تخمينه الآن... لحظات وسنكشف النتيجة معاً!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Step 2: Comparison & Reveal
          if (_knowMeStep == 2) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.outlinedCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'نتيجة المقارنة والكشف 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.deepPurple),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.palePurple,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🔒 إجابة الشريك السرية:',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.purple)),
                        const SizedBox(height: 4),
                        Text(_knowMeSecretAnswer,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💭 التخمين:',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: Color(0xFF2E7D32))),
                        const SizedBox(height: 4),
                        Text(_knowMeGuessAnswer,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32)),
                          onPressed: () => _awardKnowMePoints(15),
                          child: const Text('🎉 تطابق (+15)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _awardKnowMePoints(5),
                          child: const Text('💜 تقارب (+5)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _nextKnowMeQuestion,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('السؤال التالي'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuessWhoView() {
    if (_guessWhoCharacters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final isBothConfirmed = _mySecretConfirmed && _partnerSecretConfirmed;
    final isMyTurnToAsk = (widget.isHost && _guessWhoTurnRole == 'host') ||
        (!widget.isHost && _guessWhoTurnRole == 'guest');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selection Phase
        if (!isBothConfirmed) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Text(
                  'اختر شخصيتك السرية 🎭',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _mySecretConfirmed
                      ? 'تم تأكيد شخصيتك (${_mySecretCharacter?.name}). بانتظار الشريك... ⏳'
                      : 'انقر على شخصية لتختارها سراً، ثم اضغط تأكيد:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                ),
                if (_partnerSecretConfirmed) ...[
                  const SizedBox(height: 4),
                  const Text('الشريك جاهز واختار شخصيته! 🟢',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _guessWhoCharacters.length,
              itemBuilder: (ctx, i) {
                final char = _guessWhoCharacters[i];
                final isSelected = _mySecretCharacter?.id == char.id;
                return InkWell(
                  onTap: _mySecretConfirmed
                      ? null
                      : () {
                          setState(() => _mySecretCharacter = char);
                          PreferencesService.triggerHaptic(AppHapticType.light);
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.palePurple : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.purple : AppColors.palePurple,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(char.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          char.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: isSelected ? AppColors.purple : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (!_mySecretConfirmed)
            FilledButton.icon(
              onPressed: _mySecretCharacter == null
                  ? null
                  : () {
                      setState(() => _mySecretConfirmed = true);
                      PreferencesService.triggerHaptic(AppHapticType.medium);
                      if (_channel != null) {
                        SupabaseService.sendGuessWhoAction(
                          channel: _channel!,
                          action: 'secret_confirmed',
                          actorRole: widget.isHost ? 'host' : 'guest',
                          data: {'character_id': _mySecretCharacter!.id},
                        );
                      }
                    },
              icon: const Icon(Icons.lock_rounded),
              label: Text(_mySecretCharacter != null
                  ? 'تأكيد ${_mySecretCharacter!.name} كشخصية سرية 🔒'
                  : 'اختر شخصية أولاً'),
            ),
        ] else ...[
          // Playing Phase: Board + Q&A
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.palePurple),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('سرّك:',
                        style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(width: 4),
                    Text(
                      '${_mySecretCharacter?.emoji} ${_mySecretCharacter?.name}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepPurple,
                          fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isMyTurnToAsk
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isMyTurnToAsk ? 'دورك للسؤال 🗣️' : 'دور الشريك للسؤال ⏳',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isMyTurnToAsk
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFF57F17),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Q&A Banner
          if (_lastQuestionText.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.palePurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('السؤال: $_lastQuestionText',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.ink)),
                  if (_lastAnswerText != null) ...[
                    const SizedBox(height: 4),
                    Text('الإجابة: $_lastAnswerText',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.purple,
                            fontSize: 13)),
                  ] else if (!isMyTurnToAsk) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.tonal(
                          onPressed: () => _answerGuessWho('نعم ✅'),
                          child: const Text('نعم ✅'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.tonal(
                          onPressed: () => _answerGuessWho('لا ❌'),
                          child: const Text('لا ❌'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          // Quick Questions Chips
          if (isMyTurnToAsk &&
              (_lastAnswerText != null || _lastQuestionText.isEmpty))
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _quickQuestionChip('يلبس نظارة؟ 👓'),
                  _quickQuestionChip('له لحية؟ 🧔'),
                  _quickQuestionChip('يرتدي شماغاً؟ 👳'),
                  _quickQuestionChip('هي محجبة؟ 🧕'),
                  _quickQuestionChip('يرتدي ثوباً؟ 👔'),
                  _quickQuestionChip('بشرته فاتحة؟ ✨'),
                ],
              ),
            ),

          // 24 Character Board for Elimination
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 0.75,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: _guessWhoCharacters.length,
              itemBuilder: (ctx, i) {
                final char = _guessWhoCharacters[i];
                final isEliminated =
                    _eliminatedCharacterIds.contains(char.id);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isEliminated) {
                        _eliminatedCharacterIds.remove(char.id);
                      } else {
                        _eliminatedCharacterIds.add(char.id);
                      }
                    });
                    PreferencesService.triggerHaptic(AppHapticType.light);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: isEliminated ? 0.3 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isEliminated ? Colors.grey.shade300 : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isEliminated
                              ? Colors.grey.shade400
                              : AppColors.palePurple,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(char.emoji,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text(
                            char.name,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              decoration: isEliminated
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isEliminated
                                  ? Colors.grey.shade600
                                  : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Final Guess / Winner Celebration
          if (_winnerRole != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    _winnerRole == (widget.isHost ? 'host' : 'guest')
                        ? '🎉 مبروك! فزت بتخمين الشخصية السرية!'
                        : '🎉 فاز الشريك بتخمين الشخصية السرية!',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E7D32),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: _restartGuessWhoGame,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('جولة جديدة'),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _showFinalGuessDialog,
                    icon: const Icon(Icons.stars_rounded),
                    label: const Text('تخمين الشخصية النهائية 🎯'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'إعادة تعيين الجولة',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _restartGuessWhoGame,
                ),
              ],
            ),
        ],
      ],
    );
  }

  Widget _quickQuestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11)),
        onPressed: () => _askGuessWhoQuestion(text),
      ),
    );
  }

  Widget _buildReactionsBar() {
    const reactions = [
      {'emoji': '❤️', 'label': 'حب'},
      {'emoji': '😍', 'label': 'إعجاب'},
      {'emoji': '😂', 'label': 'ضحك'},
      {'emoji': '👏', 'label': 'تشجيع'},
      {'emoji': '☕', 'label': 'روقان'},
      {'emoji': '💬', 'label': 'حوار'},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.palePurple),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: reactions.map((r) {
          final emoji = r['emoji']!;
          final label = r['label']!;
          return Tooltip(
            message: label,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _triggerReaction(emoji, isLocal: true),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnerName = _partnerDisplayName.isNotEmpty
        ? _partnerDisplayName
        : (widget.isHost ? 'الشريك' : 'المضيف');

    return Scaffold(
      appBar: AppBar(
        title: Text('غرفة: ${widget.roomCode}'),
        actions: [
          IconButton(
            tooltip: 'دعوة مباشرة للشريك المرتبط 📲',
            icon: const Icon(Icons.send_to_mobile_rounded),
            onPressed: _sendPartnerInvite,
          ),
          IconButton(
            tooltip: 'نسخ رمز الغرفة',
            icon: const Icon(Icons.copy_rounded),
            onPressed: _copyRoomCode,
          ),
          IconButton(
            tooltip: 'مغادرة الغرفة',
            icon: const Icon(Icons.exit_to_app_rounded),
            onPressed: _confirmLeaveRoom,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dual-Presence Status Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.cardShadow,
                      border: Border.all(color: AppColors.palePurple),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildPresenceBadge(
                              title: 'أنت',
                              status: _myConnectionStatus,
                              isMe: true,
                            ),
                            _buildPresenceBadge(
                              title: partnerName,
                              status: _partnerPresenceStatus,
                              isMe: false,
                            ),
                          ],
                        ),
                        if (_partnerPresenceStatus !=
                            ConnectionStatus.online) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.palePurple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.hourglass_top_rounded,
                                  size: 14,
                                  color: AppColors.purple,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _partnerPresenceStatus ==
                                            ConnectionStatus.reconnecting
                                        ? 'الشريك يعيد الاتصال... ننتظر عودته ⏳'
                                        : 'بانتظار دخول الشريك... الرمز: ${widget.roomCode}',
                                    style: const TextStyle(
                                      color: AppColors.deepPurple,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (_partnerPresenceStatus ==
                                    ConnectionStatus.offline)
                                  TextButton.icon(
                                    onPressed: _copyRoomCode,
                                    icon: const Icon(Icons.copy_rounded,
                                        size: 14),
                                    label: const Text('نسخ الرمز',
                                        style: TextStyle(fontSize: 11)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Game Mode Switcher
                  _buildGameModeSwitcher(),

                  // Active Game Mode View
                  Expanded(
                    child: _activeMode == OnlineGameMode.cards
                        ? _buildCardsView()
                        : _activeMode == OnlineGameMode.knowMe
                            ? _buildKnowMeView()
                            : _buildGuessWhoView(),
                  ),
                  const SizedBox(height: 8),

                  // Realtime Emoji Reaction Bar
                  _buildReactionsBar(),
                ],
              ),
            ),

            // Floating Animated Reactions Overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: _activeFloatingEmojis.map((item) {
                    return _FloatingEmojiWidget(
                      key: ValueKey(item.id),
                      emoji: item.emoji,
                      startXOffset: item.startXOffset,
                      driftX: item.driftX,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Floating Emoji Model & Animation Widget ─────────────
class _FloatingEmoji {
  final String id;
  final String emoji;
  final double startXOffset;
  final double driftX;
  final DateTime createdAt;

  _FloatingEmoji({
    required this.id,
    required this.emoji,
    required this.startXOffset,
    required this.driftX,
    required this.createdAt,
  });
}

class _FloatingEmojiWidget extends StatefulWidget {
  final String emoji;
  final double startXOffset;
  final double driftX;

  const _FloatingEmojiWidget({
    super.key,
    required this.emoji,
    required this.startXOffset,
    required this.driftX,
  });

  @override
  State<_FloatingEmojiWidget> createState() => _FloatingEmojiWidgetState();
}

class _FloatingEmojiWidgetState extends State<_FloatingEmojiWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _translateY;
  late final Animation<double> _translateX;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    final isReducedMotion = PreferencesService.reducedMotion;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    if (isReducedMotion) {
      _translateY = Tween<double>(begin: 0, end: -30).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _translateX = const AlwaysStoppedAnimation(0);
      _scale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.8, end: 1.2)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.2, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 70,
        ),
      ]).animate(_controller);
    } else {
      _translateY = Tween<double>(begin: 0, end: -320).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
      );
      _translateX = Tween<double>(
        begin: widget.startXOffset,
        end: widget.startXOffset + widget.driftX,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _scale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.4, end: 1.4)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.4, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 70,
        ),
      ]).animate(_controller);
    }

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: Offset(_translateX.value, _translateY.value - 120),
            child: Transform.scale(
              scale: _scale.value,
              child: Opacity(
                opacity: _opacity.value.clamp(0.0, 1.0),
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 42),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
