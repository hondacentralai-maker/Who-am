import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/celebration_overlay.dart';

enum LetterStatus { initial, notInWord, wrongPosition, correctPosition }

class ArabicWordleScreen extends StatefulWidget {
  const ArabicWordleScreen({super.key});

  @override
  State<ArabicWordleScreen> createState() => _ArabicWordleScreenState();
}

class _ArabicWordleScreenState extends State<ArabicWordleScreen> {
  final GameAudioService _audio = GameAudioService();

  static const int wordLength = 5;
  static const int maxAttempts = 6;

  // Curated 5-letter authentic Arabic words
  static const List<Map<String, String>> _wordsDatabase = [
    {'word': 'ابتسام', 'hint': 'تعبير جميل على الوجه يزرع الفرح'},
    {'word': 'سعادة', 'hint': 'شعور داخلي عميق بالرضا والبهجة'},
    {'word': 'تفاؤل', 'hint': 'نظرة إيجابية ومشرقة نحو المستقبل'},
    {'word': 'عاشقان', 'hint': 'شريكان يجمعهما المودة والوفاء'},
    {'word': 'ذكريات', 'hint': 'لحظات ماضية جميلة لا تُنسى'},
    {'word': 'حكايات', 'hint': 'قصص وأحاديث تجمع الأحبة حولها'},
    {'word': 'أمنيات', 'hint': 'أحلام ورغبات نرجو تحقيقها'},
    {'word': 'أصدقاء', 'hint': 'سند الروح ورفاق الدرب والضحكات'},
    {'word': 'مشاعر', 'hint': 'أحاسيس نبيلة تسكن القلب'},
    {'word': 'تواصل', 'hint': 'حوار ممتد يقرب القلوب والأفكار'},
    {'word': 'أسرار', 'hint': 'أشياء خاصة لا تُقال إلا للغاليين'},
    {'word': 'سلامات', 'hint': 'تحية وأمنية بالسلامة وراحة البال'},
    {'word': 'ضحكات', 'hint': 'أصوات الفرح والسرور في الجلسة'},
    {'word': 'رياحين', 'hint': 'أزهار عطرية فواحة وطبيعة غناء'},
    {'word': 'ألحان', 'hint': 'نغمات موسيقية تعزف مشاعر الروح'},
    {'word': 'هدايا', 'hint': 'مفاجآت لطيفة تعبر عن الاهتمام'},
    {'word': 'إخلاص', 'hint': 'وفاء وصدق لا يتغير مع الأيام'},
    {'word': 'بشاير', 'hint': 'مقدمات الخير والأخبار السارة'},
    {'word': 'رحلات', 'hint': 'سفر واستكشاف لأماكن جديدة وممتعة'},
    {'word': 'أيامنا', 'hint': 'أوقاتنا الحلوة مع من نحب'},
  ];

  late String _targetWord;
  late String _targetHint;
  int _currentAttempt = 0;
  String _currentInput = '';

  late List<List<String>> _guesses;
  late List<List<LetterStatus>> _statuses;
  final Map<String, LetterStatus> _keyboardStatus = {};

  bool _isGameOver = false;
  bool _isVictory = false;
  bool _showHint = false;

  int _winsStreak = 0;

  // Arabic keyboard layout
  static const List<List<String>> _keyboardRows = [
    ['ض', 'ص', 'ث', 'ق', 'ف', 'غ', 'ع', 'ه', 'خ', 'ح', 'ج', 'د'],
    ['ش', 'س', 'ي', 'ب', 'ل', 'ا', 'ت', 'ن', 'م', 'ك', 'ط', 'ذ'],
    ['تأكيد', 'ئ', 'ء', 'ؤ', 'ر', 'لا', 'ى', 'ة', 'و', 'ز', 'ظ', '⌫'],
  ];

  @override
  void initState() {
    super.initState();
    _winsStreak = PreferencesService.getWordleCurrentStreak();
    _startNewGame();
    PreferencesService.recordPartyGamePlayed('arabic_wordle');
  }

  void _startNewGame() {
    final randomItem = _wordsDatabase[math.Random().nextInt(_wordsDatabase.length)];
    _targetWord = _cleanArabic(randomItem['word']!);
    _targetHint = randomItem['hint']!;

    _currentAttempt = 0;
    _currentInput = '';
    _isGameOver = false;
    _isVictory = false;
    _showHint = false;

    _guesses = List.generate(maxAttempts, (_) => List.generate(wordLength, (_) => ''));
    _statuses = List.generate(
      maxAttempts,
      (_) => List.generate(wordLength, (_) => LetterStatus.initial),
    );
    _keyboardStatus.clear();

    setState(() {});
  }

  String _cleanArabic(String input) {
    return input
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .trim();
  }

  void _onKeyPress(String key) {
    if (_isGameOver) return;

    if (key == '⌫') {
      if (_currentInput.isNotEmpty) {
        _audio.playCardSwipe();
        PreferencesService.triggerHaptic(AppHapticType.selection);
        setState(() {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
          _guesses[_currentAttempt][_currentInput.length] = '';
        });
      }
    } else if (key == 'تأكيد') {
      if (_currentInput.length == wordLength) {
        _submitGuess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الكلمة يجب أن تتكون من 5 حروف! ✍️', textAlign: TextAlign.right),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      if (_currentInput.length < wordLength) {
        _audio.playCardPlace();
        PreferencesService.triggerHaptic(AppHapticType.light);
        setState(() {
          _guesses[_currentAttempt][_currentInput.length] = key;
          _currentInput += key;
        });
      }
    }
  }

  void _submitGuess() {
    final guess = _cleanArabic(_currentInput);
    final target = _cleanArabic(_targetWord);

    final rowStatus = List.generate(wordLength, (_) => LetterStatus.notInWord);
    final targetChars = target.split('');
    final guessChars = guess.split('');

    // First pass: exact matches (Green)
    final matchedIndices = <int>{};
    for (int i = 0; i < wordLength; i++) {
      if (guessChars[i] == targetChars[i]) {
        rowStatus[i] = LetterStatus.correctPosition;
        matchedIndices.add(i);
        _keyboardStatus[guessChars[i]] = LetterStatus.correctPosition;
      }
    }

    // Second pass: wrong positions (Yellow)
    for (int i = 0; i < wordLength; i++) {
      if (rowStatus[i] == LetterStatus.correctPosition) continue;

      final char = guessChars[i];
      int foundIndex = -1;
      for (int j = 0; j < wordLength; j++) {
        if (!matchedIndices.contains(j) && targetChars[j] == char) {
          foundIndex = j;
          break;
        }
      }

      if (foundIndex != -1) {
        rowStatus[i] = LetterStatus.wrongPosition;
        matchedIndices.add(foundIndex);
        if (_keyboardStatus[char] != LetterStatus.correctPosition) {
          _keyboardStatus[char] = LetterStatus.wrongPosition;
        }
      } else {
        rowStatus[i] = LetterStatus.notInWord;
        if (!_keyboardStatus.containsKey(char)) {
          _keyboardStatus[char] = LetterStatus.notInWord;
        }
      }
    }

    setState(() {
      _statuses[_currentAttempt] = rowStatus;
    });

    if (guess == target) {
      // VICTORY!
      final attemptsUsed = _currentAttempt + 1;
      PreferencesService.recordWordleResult(won: true, attempts: attemptsUsed);
      setState(() {
        _isGameOver = true;
        _isVictory = true;
        _winsStreak = PreferencesService.getWordleCurrentStreak();
      });
      _audio.playVictory();
      PreferencesService.triggerHaptic(AppHapticType.heavy);
      CelebrationOverlay.show(context);
    } else {
      if (_currentAttempt + 1 >= maxAttempts) {
        // GAME OVER
        PreferencesService.recordWordleResult(won: false, attempts: maxAttempts);
        setState(() {
          _isGameOver = true;
          _isVictory = false;
          _winsStreak = 0;
        });
        _audio.playMarbleEat();
        PreferencesService.triggerHaptic(AppHapticType.medium);
      } else {
        setState(() {
          _currentAttempt++;
          _currentInput = '';
        });
        _audio.playMarbleStep();
        PreferencesService.triggerHaptic(AppHapticType.selection);
      }
    }
  }

  void _showStatsDialog() {
    final played = PreferencesService.getWordlePlayed();
    final wins = PreferencesService.getWordleWins();
    final currentStreak = PreferencesService.getWordleCurrentStreak();
    final maxStreak = PreferencesService.getWordleMaxStreak();
    final winPercent = played > 0 ? ((wins / played) * 100).round() : 0;

    int maxCount = 1;
    final guessCounts = <int, int>{};
    for (int i = 1; i <= maxAttempts; i++) {
      final count = PreferencesService.getWordleGuessCount(i);
      guessCounts[i] = count;
      if (count > maxCount) maxCount = count;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.leaderboard_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('إحصائيات الكلمات 📊', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('$played', 'اللعب'),
                    _buildStatCol('$winPercent%', 'الفوز'),
                    _buildStatCol('$currentStreak', 'السلسلة'),
                    _buildStatCol('$maxStreak', 'أطول سلسلة'),
                  ],
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'توزيع المحاولات الناجحة 🎯',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                for (int i = 1; i <= maxAttempts; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text('$i', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2C3440) : const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: (guessCounts[i]! / maxCount).clamp(0.08, 1.0),
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: (i == _currentAttempt + 1 && _isVictory)
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFF5E35B1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Text(
                                    '${guessCounts[i]}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCol(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F131A) : const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'فك الكلمة • Arabic Wordle 🔤',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'الإحصائيات',
            onPressed: _showStatsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline_rounded),
            tooltip: 'تلميح',
            onPressed: () {
              setState(() => _showHint = !_showHint);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'كلمة جديدة',
            onPressed: _startNewGame,
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                if (_showHint) _buildHintBanner(isDark),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: _buildGrid(isDark),
                      ),
                    ),
                  ),
                ),
                _buildKeyboard(isDark),
              ],
            ),
          ),
          if (_isGameOver)
            Positioned(
              top: 12,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isVictory
                        ? const [Color(0xFF2E7D32), Color(0xFF66BB6A)]
                        : const [Color(0xFFC62828), Color(0xFFE57373)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_isVictory ? Colors.green : Colors.red).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  _isVictory
                      ? 'ما شاء الله! خمنت الكلمة بنجاح: ($_targetWord) 🎉🏆'
                      : 'حظاً أوفر! الكلمة السرية كانت: ($_targetWord) 💡',
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

  Widget _buildHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF19202B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('🔥 سلسلة الفوز: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text(
                '$_winsStreak',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 16),
              ),
            ],
          ),
          Row(
            children: [
              const Text('المحاولة: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text(
                '${math.min(_currentAttempt + 1, maxAttempts)} / $maxAttempts',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHintBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تلميح الكلمة: $_targetHint',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxAttempts, (r) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(wordLength, (c) {
              final letter = _guesses[r][c];
              final status = _statuses[r][c];
              return _buildTile(letter, status, isDark);
            }),
          ),
        );
      }),
    );
  }

  Widget _buildTile(String letter, LetterStatus status, bool isDark) {
    Color bg;
    Color border;
    Color textColor = isDark ? Colors.white : Colors.black87;

    switch (status) {
      case LetterStatus.correctPosition:
        bg = const Color(0xFF2E7D32); // Green
        border = const Color(0xFF43A047);
        textColor = Colors.white;
        break;
      case LetterStatus.wrongPosition:
        bg = const Color(0xFFF9A825); // Yellow
        border = const Color(0xFFFBC02D);
        textColor = Colors.white;
        break;
      case LetterStatus.notInWord:
        bg = isDark ? const Color(0xFF37474F) : const Color(0xFF78909C);
        border = Colors.transparent;
        textColor = Colors.white;
        break;
      case LetterStatus.initial:
        bg = isDark ? const Color(0xFF1E2633) : Colors.white;
        border = letter.isNotEmpty ? AppColors.purple : (isDark ? const Color(0xFF2E3846) : const Color(0xFFCFD8DC));
        break;
    }

    return Container(
      width: 52,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: letter.isNotEmpty ? 2.0 : 1.5),
        boxShadow: [
          if (status != LetterStatus.initial)
            BoxShadow(
              color: bg.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141923) : const Color(0xFFECEFF1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _keyboardRows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                return _buildKeyButton(key, isDark);
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyButton(String key, bool isDark) {
    final status = _keyboardStatus[key] ?? LetterStatus.initial;
    final isAction = key == 'تأكيد' || key == '⌫';

    Color bg;
    Color textColor = isDark ? Colors.white : Colors.black87;

    switch (status) {
      case LetterStatus.correctPosition:
        bg = const Color(0xFF2E7D32);
        textColor = Colors.white;
        break;
      case LetterStatus.wrongPosition:
        bg = const Color(0xFFF9A825);
        textColor = Colors.white;
        break;
      case LetterStatus.notInWord:
        bg = isDark ? const Color(0xFF263238) : const Color(0xFFB0BEC5);
        textColor = Colors.white54;
        break;
      case LetterStatus.initial:
        bg = isAction
            ? (key == 'تأكيد' ? AppColors.deepPurple : const Color(0xFFC62828))
            : (isDark ? const Color(0xFF252F3F) : Colors.white);
        if (isAction) textColor = Colors.white;
        break;
    }

    return Expanded(
      flex: isAction ? 2 : 1,
      child: Container(
        height: 42,
        margin: const EdgeInsets.symmetric(horizontal: 1.8),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: textColor,
            padding: EdgeInsets.zero,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _onKeyPress(key),
          child: Text(
            key,
            style: TextStyle(
              fontSize: isAction ? 11 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

