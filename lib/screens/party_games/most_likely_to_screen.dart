import 'package:flutter/material.dart';
import '../../models/party_game_models.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';

class MostLikelyToScreen extends StatefulWidget {
  final List<String>? initialPlayers;

  const MostLikelyToScreen({super.key, this.initialPlayers});

  @override
  State<MostLikelyToScreen> createState() => _MostLikelyToScreenState();
}

class _MostLikelyToScreenState extends State<MostLikelyToScreen> {
  late List<MostLikelyToPrompt> _prompts;
  int _currentIndex = 0;
  List<String> _players = ['سارة', 'نور', 'شهد', 'ريم'];
  
  // Votes map: PlayerName -> vote count
  final Map<String, int> _votes = {};
  bool _isRevealed = false;
  String? _selectedVote;

  @override
  void initState() {
    super.initState();
    _prompts = MostLikelyToPrompt.defaultPrompts()..shuffle();
    if (widget.initialPlayers != null && widget.initialPlayers!.isNotEmpty) {
      _players = List.from(widget.initialPlayers!);
    } else {
      final profile = PreferencesService.getCouplesProfile();
      _players = [profile.partner1Name, profile.partner2Name, 'صديقة 1', 'صديقة 2'];
    }
    _resetVotes();
  }

  void _resetVotes() {
    _votes.clear();
    for (final p in _players) {
      _votes[p] = 0;
    }
    _isRevealed = false;
    _selectedVote = null;
  }

  void _castVote(String player) {
    if (_isRevealed) return;
    PreferencesService.triggerHaptic(AppHapticType.selection);
    setState(() {
      _selectedVote = player;
      _votes[player] = (_votes[player] ?? 0) + 1;
    });
  }

  void _revealResults() {
    PreferencesService.triggerHaptic(AppHapticType.medium);
    setState(() {
      _isRevealed = true;
    });
  }

  void _nextQuestion() {
    PreferencesService.triggerHaptic(AppHapticType.light);
    setState(() {
      _currentIndex = (_currentIndex + 1) % _prompts.length;
      _resetVotes();
    });
  }

  void _showAddPlayerDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة لاعبة للجلسة 👧'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'اسم اللاعبة',
            hintText: 'مثال: دانة، ليلى، أسماء...',
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
                  _votes[name] = 0;
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

  @override
  Widget build(BuildContext context) {
    final prompt = _prompts[_currentIndex];
    final totalVotes = _votes.values.fold<int>(0, (a, b) => a + b);

    // Find player with max votes
    String? winnerPlayer;
    int maxV = 0;
    if (_isRevealed && totalVotes > 0) {
      _votes.forEach((p, v) {
        if (v > maxV) {
          maxV = v;
          winnerPlayer = p;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('مين فينا؟ 🎭'),
        actions: [
          IconButton(
            tooltip: 'إضافة لاعبة',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: _showAddPlayerDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Prompt Question Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5E2B97), Color(0xFF9C27B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppShadows.floatingShadow,
                ),
                child: Column(
                  children: [
                    Text(prompt.emoji, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      prompt.question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'تصنيف: ${prompt.category}',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'صوّتوا سراً: من هي الأكثر انطباقاً عليها هذا السؤال؟ 👇',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),

              // Players Grid / List
              Expanded(
                child: ListView.builder(
                  itemCount: _players.length,
                  itemBuilder: (context, idx) {
                    final player = _players[idx];
                    final isSelected = _selectedVote == player;
                    final voteCount = _votes[player] ?? 0;
                    final percent = totalVotes > 0 ? (voteCount / totalVotes) : 0.0;
                    final isWinner = _isRevealed && winnerPlayer == player;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isWinner
                            ? const Color(0xFFFFF9C4)
                            : (isSelected ? AppColors.palePurple : Colors.white),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isWinner
                              ? AppColors.accentGold
                              : (isSelected ? AppColors.purple : AppColors.cardBorder),
                          width: isWinner || isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: AppShadows.cardShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _castVote(player),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isWinner ? AppColors.accentGold : AppColors.purple,
                                      foregroundColor: Colors.white,
                                      radius: 18,
                                      child: Text(
                                        player.isNotEmpty ? player[0] : '؟',
                                        style: const TextStyle(fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        player,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isWinner ? AppColors.deepPurple : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    if (isWinner)
                                      const Row(
                                        children: [
                                          Icon(Icons.emoji_events_rounded, color: AppColors.accentGold),
                                          SizedBox(width: 4),
                                          Text(
                                            'الأغلبية! 👑',
                                            style: TextStyle(
                                              color: AppColors.deepPurple,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      )
                                    else if (_isRevealed)
                                      Text(
                                        '$voteCount أصوات (${(percent * 100).toInt()}%)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.muted,
                                          fontSize: 12,
                                        ),
                                      )
                                    else if (isSelected)
                                      const Icon(Icons.check_circle_rounded, color: AppColors.purple),
                                  ],
                                ),
                                if (_isRevealed && totalVotes > 0) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      minHeight: 6,
                                      backgroundColor: AppColors.cardBorder,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isWinner ? AppColors.accentGold : AppColors.purple,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Actions
              Row(
                children: [
                  if (!_isRevealed)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _selectedVote != null ? _revealResults : null,
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('كشف نتيجة التصويت! 👀'),
                      ),
                    )
                  else
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _nextQuestion,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('السؤال التالي ➡️'),
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
}
