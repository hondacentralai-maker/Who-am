import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/party_game_models.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/interactive_3d_card.dart';
import '../../widgets/arcade_3d_buzzer.dart';

enum SpyfallGameState { setup, passDevice, discussion, gameOver }

class SpyfallScreen extends StatefulWidget {
  final List<String>? initialPlayers;

  const SpyfallScreen({super.key, this.initialPlayers});

  @override
  State<SpyfallScreen> createState() => _SpyfallScreenState();
}

class _SpyfallScreenState extends State<SpyfallScreen> {
  SpyfallGameState _gameState = SpyfallGameState.setup;

  List<String> _players = ['سارة', 'نور', 'شهد', 'ريم'];
  final int _spiesCount = 1;
  int _discussionMinutes = 6;

  // Active game assignments
  late SpyfallLocation _selectedLocation;
  final Set<String> _spyPlayers = {};
  final Map<String, String> _playerRoles = {};
  int _currentPassIndex = 0;
  bool _isSecretRevealed = false;

  // Discussion timer
  Timer? _discussionTimer;
  int _remainingSeconds = 360; // 6 mins default
  String? _gameResultTitle;
  String? _gameResultDetail;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlayers != null && widget.initialPlayers!.isNotEmpty) {
      _players = List.from(widget.initialPlayers!);
    } else {
      final profile = PreferencesService.getCouplesProfile();
      _players = [profile.partner1Name, profile.partner2Name, 'صديقة 1', 'صديقة 2'];
    }
  }

  @override
  void dispose() {
    _discussionTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    if (_players.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن يكون عدد اللاعبات 3 على الأقل!')),
      );
      return;
    }

    PreferencesService.triggerHaptic(AppHapticType.heavy);

    // Pick random location
    final locations = SpyfallLocation.defaultLocations()..shuffle();
    _selectedLocation = locations.first;

    // Pick random spy/spies
    final shuffledPlayers = List<String>.from(_players)..shuffle();
    _spyPlayers.clear();
    for (int i = 0; i < _spiesCount && i < shuffledPlayers.length; i++) {
      _spyPlayers.add(shuffledPlayers[i]);
    }

    // Assign roles to innocents
    _playerRoles.clear();
    final roles = List<String>.from(_selectedLocation.typicalRoles)..shuffle();
    int roleIdx = 0;
    for (final p in _players) {
      if (_spyPlayers.contains(p)) {
        _playerRoles[p] = 'الجاسوسة المندَسّة 🕵️‍♀️';
      } else {
        _playerRoles[p] = roles[roleIdx % roles.length];
        roleIdx++;
      }
    }

    setState(() {
      _gameState = SpyfallGameState.passDevice;
      _currentPassIndex = 0;
      _isSecretRevealed = false;
      _remainingSeconds = _discussionMinutes * 60;
    });
  }

  void _nextPlayerPass() {
    PreferencesService.triggerHaptic(AppHapticType.selection);
    if (_currentPassIndex < _players.length - 1) {
      setState(() {
        _currentPassIndex++;
        _isSecretRevealed = false;
      });
    } else {
      // All players know their secret -> start discussion
      setState(() {
        _gameState = SpyfallGameState.discussion;
        _isSecretRevealed = false;
      });
      _startDiscussionTimer();
    }
  }

  void _startDiscussionTimer() {
    _discussionTimer?.cancel();
    _discussionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _endGame(
          title: 'انتهى وقت النقاش! ⏰',
          detail: 'حان وقت التصويت النهائي للكشف عن الجاسوسة أو تخمين الموقع.',
        );
      }
    });
  }

  void _endGame({required String title, required String detail}) async {
    _discussionTimer?.cancel();
    PreferencesService.triggerHaptic(AppHapticType.heavy);
    GameAudioService().playWin();
    await PreferencesService.recordPartyGameFinished(pointsEarned: 20);
    setState(() {
      _gameState = SpyfallGameState.gameOver;
      _gameResultTitle = title;
      _gameResultDetail = detail;
    });
    if (mounted) {
      CelebrationOverlay.show(context);
    }
  }

  void _showSpyGuessDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final allLocations = SpyfallLocation.defaultLocations();
        return AlertDialog(
          title: const Text('تخمين الجاسوسة للموقع 🎯'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allLocations.length,
              itemBuilder: (ctx, i) {
                final loc = allLocations[i];
                return ListTile(
                  leading: Text(loc.emoji, style: const TextStyle(fontSize: 22)),
                  title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (loc.id == _selectedLocation.id) {
                      _endGame(
                        title: 'فازت الجاسوسة! 🕵️‍♀️🏆',
                        detail: 'خمّنت الجاسوسة المكان الصحيح (${loc.name} ${loc.emoji}) بنجاح داهية!',
                      );
                    } else {
                      _endGame(
                        title: 'فاز المواطنون! 👥🎉',
                        detail: 'أخطأت الجاسوسة في التخمين! المكان الحقيقي كان (${_selectedLocation.name} ${_selectedLocation.emoji}).',
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  void _showVoteAccuseDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('اتّهام وتصويت 🫵'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _players.map((p) {
              return ListTile(
                leading: const Icon(Icons.person_pin_rounded, color: AppColors.purple),
                title: Text(p, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  if (_spyPlayers.contains(p)) {
                    _endGame(
                      title: 'تم القبض على الجاسوسة! 🕵️‍♀️🚫',
                      detail: 'أحسنتم جميعاً! تم كشف الجاسوسة ($p) والمكان هو (${_selectedLocation.name} ${_selectedLocation.emoji}).',
                    );
                  } else {
                    _endGame(
                      title: 'اتّهام خاطئ! فازت الجاسوسة 🕵️‍♀️🎉',
                      detail: 'المتّهمة ($p) كانت مواطنة بريئة! الجاسوسة الحقيقية كانت (${_spyPlayers.join('، ')}).',
                    );
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPlayerDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة لاعبة 👧'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'اسم اللاعبة',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _players.add(name);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الجاسوسة والمندَسّة 🕵️‍♀️'),
        actions: [
          if (_gameState == SpyfallGameState.setup)
            IconButton(
              tooltip: 'إضافة لاعبة',
              icon: const Icon(Icons.person_add_rounded),
              onPressed: _showAddPlayerDialog,
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentStateView(),
        ),
      ),
    );
  }

  Widget _buildCurrentStateView() {
    switch (_gameState) {
      case SpyfallGameState.setup:
        return _buildSetupView();
      case SpyfallGameState.passDevice:
        return _buildPassDeviceView();
      case SpyfallGameState.discussion:
        return _buildDiscussionView();
      case SpyfallGameState.gameOver:
        return _buildGameOverView();
    }
  }

  // 1. Setup View
  Widget _buildSetupView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.palePurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Text('🕵️‍♀️', style: TextStyle(fontSize: 32)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لعبة الخداع والذكاء الاجتماعي',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'الجميع في مكان سري واحد، عدا الجاسوسة! اطرحوا أسئلة ذكية لاكتشافها.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'اللاعبات (${_players.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton.icon(
                onPressed: _showAddPlayerDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _players.map((p) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: AppColors.purple,
                  child: Text(
                    p.characters.first,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                label: Text(p, style: const TextStyle(fontWeight: FontWeight.bold)),
                onDeleted: _players.length > 3
                    ? () {
                        setState(() {
                          _players.remove(p);
                        });
                      }
                    : null,
              );
            }).toList(),
          ),
          const Divider(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('مدة النقاش:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<int>(
                value: _discussionMinutes,
                items: [4, 6, 8, 10].map((m) {
                  return DropdownMenuItem<int>(
                    value: m,
                    child: Text('$m دقائق'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _discussionMinutes = val);
                },
              ),
            ],
          ),
          const Spacer(),
          Arcade3DBuzzer(
            label: 'بدء توزيع الأدوار السرية 🎭',
            icon: Icons.play_arrow_rounded,
            color: AppColors.purple,
            height: 54,
            onPressed: _startGame,
          ),
        ],
      ),
    );
  }

  // 2. Pass Device View
  Widget _buildPassDeviceView() {
    final currentPlayer = _players[_currentPassIndex];
    final isSpy = _spyPlayers.contains(currentPlayer);
    final role = _playerRoles[currentPlayer] ?? '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'اللاعبة رقم ${_currentPassIndex + 1} من ${_players.length}',
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'مرري الجوال لـ: $currentPlayer 📱',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.deepPurple,
              ),
            ),
            const SizedBox(height: 28),
            Interactive3DCard(
              borderRadius: BorderRadius.circular(24),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                    if (!_isSecretRevealed) ...[
                      const Icon(Icons.visibility_off_rounded, size: 64, color: AppColors.purple),
                      const SizedBox(height: 16),
                      const Text(
                        'لا تدعي أحداً ينظر إلى الشاشة!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          PreferencesService.triggerHaptic(AppHapticType.heavy);
                          setState(() {
                            _isSecretRevealed = true;
                          });
                        },
                        icon: const Icon(Icons.remove_red_eye_rounded),
                        label: const Text('اكشفي سري الآن 👁️'),
                      ),
                    ] else ...[
                      if (isSpy) ...[
                        const Text('🕵️‍♀️', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 12),
                        const Text(
                          'أنتِ الجاسوسة المندَسّة!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'المكان مجهول بالنسبة لكِ! استمعي للأسئلة جيداً وتظاهري بأنكِ تعرفين المكان.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, height: 1.4),
                        ),
                      ] else ...[
                        Text(_selectedLocation.emoji, style: const TextStyle(fontSize: 56)),
                        const SizedBox(height: 8),
                        Text(
                          _selectedLocation.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.palePurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'دورك: $role',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _nextPlayerPass,
                        child: Text(
                          _currentPassIndex < _players.length - 1
                              ? 'فهمت، إخفاء وتمرير لمن بعدي ➡️'
                              : 'الجميع جاهز! بدء النقاش 🚀',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // 3. Discussion View
  Widget _buildDiscussionView() {
    final allLocations = SpyfallLocation.defaultLocations();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Timer Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.palePurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('وقت النقاش المتبقي:', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    Text('اطرحوا أسئلة متبادلة بالدور 💬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'قائمة الأماكن المحتملة في اللعبة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 8),

          // Reference Locations List
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: allLocations.length,
              itemBuilder: (ctx, i) {
                final loc = allLocations[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Text(loc.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepPurple,
                      side: const BorderSide(color: AppColors.purple, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _showSpyGuessDialog,
                    icon: const Icon(Icons.lightbulb_outline_rounded),
                    label: const Text('تخمين الجاسوسة 🎯', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _showVoteAccuseDialog,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('اتّهام وتصويت 🫵', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Game Over View
  Widget _buildGameOverView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _gameResultTitle ?? 'نهاية الجولة!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _gameResultDetail ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.ink),
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_selectedLocation.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: 8),
                      Text(
                        'الموقع الحقيقي: ${_selectedLocation.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الجاسوسة كانت: ${_spyPlayers.join('، ')} 🕵️‍♀️',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  setState(() {
                    _gameState = SpyfallGameState.setup;
                  });
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('جولة جديدة 🔄', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
