import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/party_game_models.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';

class TabooScreen extends StatefulWidget {
  const TabooScreen({super.key});

  @override
  State<TabooScreen> createState() => _TabooScreenState();
}

class _TabooScreenState extends State<TabooScreen> {
  late List<TabooCard> _cards;
  int _cardIndex = 0;

  // Teams & Scores
  int _teamAScore = 0;
  int _teamBScore = 0;
  int _activeTeam = 1; // 1 for Team A, 2 for Team B
  final String _teamAName = 'فريق الورد 🌸';
  final String _teamBName = 'فريق الياسمين 🌼';

  // Timer
  static const int _roundDuration = 60;
  int _remainingSeconds = _roundDuration;
  Timer? _timer;
  bool _isPlaying = false;
  bool _isRoundOver = false;

  @override
  void initState() {
    super.initState();
    _cards = TabooCard.defaultCards()..shuffle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _roundDuration;
      _isPlaying = true;
      _isRoundOver = false;
    });

    PreferencesService.triggerHaptic(AppHapticType.heavy);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
        PreferencesService.triggerHaptic(AppHapticType.heavy);
        setState(() {
          _isPlaying = false;
          _isRoundOver = true;
        });
      }
    });
  }

  void _onCorrect() {
    if (!_isPlaying) return;
    PreferencesService.triggerHaptic(AppHapticType.medium);
    setState(() {
      if (_activeTeam == 1) {
        _teamAScore++;
      } else {
        _teamBScore++;
      }
      _nextCard();
    });
  }

  void _onTabooPenalty() {
    if (!_isPlaying) return;
    PreferencesService.triggerHaptic(AppHapticType.heavy);
    setState(() {
      if (_activeTeam == 1) {
        if (_teamAScore > 0) _teamAScore--;
      } else {
        if (_teamBScore > 0) _teamBScore--;
      }
      _nextCard();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(milliseconds: 1000),
        backgroundColor: Colors.redAccent,
        content: Text('تم نطق كلمة محظورة! 🚫 -1 نقطة'),
      ),
    );
  }

  void _onSkip() {
    if (!_isPlaying) return;
    PreferencesService.triggerHaptic(AppHapticType.light);
    setState(() {
      _nextCard();
    });
  }

  void _nextCard() {
    _cardIndex = (_cardIndex + 1) % _cards.length;
  }

  void _switchTeam() {
    setState(() {
      _activeTeam = _activeTeam == 1 ? 2 : 1;
      _isPlaying = false;
      _isRoundOver = false;
      _remainingSeconds = _roundDuration;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = _cards[_cardIndex];
    final activeTeamName = _activeTeam == 1 ? _teamAName : _teamBName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('قول بس لا تقول 🤐'),
        actions: [
          IconButton(
            tooltip: 'إعادة تصفير النقاط',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _teamAScore = 0;
                _teamBScore = 0;
                _isPlaying = false;
                _isRoundOver = false;
                _remainingSeconds = _roundDuration;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scoreboard Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.palePurple.withValues(alpha: 0.5),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _activeTeam == 1 ? Colors.white : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _activeTeam == 1 ? AppColors.purple : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _teamAName,
                            style: TextStyle(
                              fontWeight: _activeTeam == 1 ? FontWeight.w900 : FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_teamAScore نقطة',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Live Timer Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _remainingSeconds <= 10 ? Colors.redAccent : AppColors.purple,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_remainingSeconds}s ⏱️',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _activeTeam == 2 ? Colors.white : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _activeTeam == 2 ? AppColors.purple : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _teamBName,
                            style: TextStyle(
                              fontWeight: _activeTeam == 2 ? FontWeight.w900 : FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_teamBScore نقطة',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _isRoundOver
                      ? _buildRoundOverCard(activeTeamName)
                      : !_isPlaying
                          ? _buildReadyCard(activeTeamName)
                          : _buildCardView(currentCard),
                ),
              ),
            ),

            // Bottom Action Controls
            if (_isPlaying) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Taboo penalty button
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _onTabooPenalty,
                          icon: const Icon(Icons.block_rounded),
                          label: const Text('محظور! (-1)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Skip button
                    IconButton.filledTonal(
                      tooltip: 'تخطي البطاقة',
                      icon: const Icon(Icons.skip_next_rounded),
                      onPressed: _onSkip,
                    ),
                    const SizedBox(width: 8),
                    // Correct button
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _onCorrect,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('صح! (+1)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardView(TabooCard card) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Target Word Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(card.emoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 6),
                  Text(
                    card.targetWord,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Forbidden Words Banner
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                SizedBox(width: 6),
                Text(
                  'الكلمات المحظور نطقها تماماً:',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Forbidden Words List
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: card.forbiddenWords.length,
                separatorBuilder: (ctx, i) => const Divider(height: 12),
                itemBuilder: (ctx, i) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        card.forbiddenWords[i],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC62828),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyCard(String activeTeamName) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤐', style: TextStyle(fontSize: 54)),
            const SizedBox(height: 12),
            Text(
              'دور: $activeTeamName',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.deepPurple),
            ),
            const SizedBox(height: 12),
            const Text(
              'اشرحي الكلمة الرئيسية لفريقكِ بدون نطق أي من الكلمات المحظورة في البطاقة! لديكم 60 ثانية.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.5),
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
                onPressed: _startRound,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('ابدأ الجولة (60 ثانية) ⚡', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundOverCard(String activeTeamName) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏰', style: TextStyle(fontSize: 54)),
            const SizedBox(height: 12),
            const Text(
              'انتهت الجولة!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.deepPurple),
            ),
            const SizedBox(height: 12),
            const Text(
              'أحسنتم! والآن حان دور الفريق المنافس لبدء التحدي.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.5),
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
                onPressed: _switchTeam,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('تسليم الجوال للفريق الآخر 🔄', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
