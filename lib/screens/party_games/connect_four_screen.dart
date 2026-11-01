import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/celebration_overlay.dart';
import '../../widgets/interactive_3d_card.dart';

class GridPoint {
  final int r;
  final int c;
  const GridPoint(this.r, this.c);
}

enum ConnectPlayer { none, red, yellow }

enum ConnectGameMode { pvp, vsAi }

enum AiDifficulty { easy, medium, hard }

class ConnectFourScreen extends StatefulWidget {
  final List<String>? initialPlayers;

  const ConnectFourScreen({
    super.key,
    this.initialPlayers,
  });

  @override
  State<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends State<ConnectFourScreen>
    with TickerProviderStateMixin {
  final GameAudioService _audio = GameAudioService();

  static const int rows = 6;
  static const int cols = 7;

  late List<List<ConnectPlayer>> _grid;
  ConnectPlayer _currentPlayer = ConnectPlayer.red;
  ConnectGameMode _mode = ConnectGameMode.pvp;
  AiDifficulty _aiDifficulty = AiDifficulty.hard;
  bool _isAiThinking = false;
  ConnectPlayer? _winner;
  List<GridPoint> _winningLine = [];
  bool _isDraw = false;

  final List<GridPoint> _moveHistory = [];

  int _redWins = 0;
  int _yellowWins = 0;
  int _draws = 0;

  String _p1Name = 'اللاعب 1';
  String _p2Name = 'اللاعب 2';

  // Dropping animation state
  int? _droppingCol;
  int? _targetRow;
  ConnectPlayer? _droppingPlayer;
  late AnimationController _dropAnimController;
  late Animation<double> _dropAnimation;

  @override
  void initState() {
    super.initState();
    _initPlayers();
    _resetBoard();

    _dropAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _dropAnimation = CurvedAnimation(
      parent: _dropAnimController,
      curve: Curves.bounceOut,
    );

    PreferencesService.recordPartyGamePlayed('connect_four');
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
    _dropAnimController.dispose();
    super.dispose();
  }

  void _resetBoard() {
    setState(() {
      _grid = List.generate(
        rows,
        (_) => List.generate(cols, (_) => ConnectPlayer.none),
      );
      _currentPlayer = ConnectPlayer.red;
      _winner = null;
      _winningLine = [];
      _isDraw = false;
      _isAiThinking = false;
      _droppingCol = null;
      _targetRow = null;
      _droppingPlayer = null;
      _moveHistory.clear();
    });
  }

  void _undoMove() {
    if (_moveHistory.isEmpty || _isAiThinking || _dropAnimController.isAnimating) return;
    setState(() {
      if (_mode == ConnectGameMode.vsAi) {
        if (_moveHistory.isNotEmpty) {
          final last = _moveHistory.removeLast();
          _grid[last.r][last.c] = ConnectPlayer.none;
        }
        if (_moveHistory.isNotEmpty) {
          final last = _moveHistory.removeLast();
          _grid[last.r][last.c] = ConnectPlayer.none;
        }
        _currentPlayer = ConnectPlayer.red;
      } else {
        final last = _moveHistory.removeLast();
        _grid[last.r][last.c] = ConnectPlayer.none;
        _currentPlayer = (_currentPlayer == ConnectPlayer.red)
            ? ConnectPlayer.yellow
            : ConnectPlayer.red;
      }
      _winner = null;
      _winningLine = [];
      _isDraw = false;
    });
    _audio.playCardSwipe();
    PreferencesService.triggerHaptic(AppHapticType.selection);
  }

  bool _canDrop(int col) {
    if (_winner != null || _isDraw || _isAiThinking) return false;
    if (_dropAnimController.isAnimating) return false;
    return _grid[0][col] == ConnectPlayer.none;
  }

  int _findLowestEmptyRow(int col) {
    for (int r = rows - 1; r >= 0; r--) {
      if (_grid[r][col] == ConnectPlayer.none) {
        return r;
      }
    }
    return -1;
  }

  Future<void> _handleColumnTap(int col) async {
    if (!_canDrop(col)) return;

    final targetRow = _findLowestEmptyRow(col);
    if (targetRow == -1) return;

    final player = _currentPlayer;
    setState(() {
      _droppingCol = col;
      _targetRow = targetRow;
      _droppingPlayer = player;
    });

    _audio.playCardPlace();
    PreferencesService.triggerHaptic(AppHapticType.selection);

    await _dropAnimController.forward(from: 0.0);

    if (!mounted) return;

    setState(() {
      _grid[targetRow][col] = player;
      _moveHistory.add(GridPoint(targetRow, col));
      _droppingCol = null;
      _targetRow = null;
      _droppingPlayer = null;
    });

    _audio.playDiceDrop();
    PreferencesService.triggerHaptic(AppHapticType.medium);

    // Check winner
    final winLine = _checkWinner(targetRow, col, player);
    if (winLine != null && winLine.length >= 4) {
      setState(() {
        _winner = player;
        _winningLine = winLine;
        if (player == ConnectPlayer.red) {
          _redWins++;
        } else {
          _yellowWins++;
        }
      });
      _audio.playVictory();
      PreferencesService.triggerHaptic(AppHapticType.heavy);
      CelebrationOverlay.show(context);
      return;
    }

    // Check draw
    if (_isBoardFull()) {
      setState(() {
        _isDraw = true;
        _draws++;
      });
      return;
    }

    // Switch turn
    setState(() {
      _currentPlayer = (_currentPlayer == ConnectPlayer.red)
          ? ConnectPlayer.yellow
          : ConnectPlayer.red;
    });

    // Trigger AI if vs AI mode and yellow turn
    if (_mode == ConnectGameMode.vsAi && _currentPlayer == ConnectPlayer.yellow) {
      _playAiTurn();
    }
  }

  bool _isBoardFull() {
    for (int c = 0; c < cols; c++) {
      if (_grid[0][c] == ConnectPlayer.none) return false;
    }
    return true;
  }

  Future<void> _playAiTurn() async {
    setState(() => _isAiThinking = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final bestCol = _computeBestAiMove();
    _isAiThinking = false;
    _handleColumnTap(bestCol);
  }

  int _computeBestAiMove() {
    final validCols = [0, 1, 2, 3, 4, 5, 6].where((c) => _findLowestEmptyRow(c) != -1).toList();
    if (validCols.isEmpty) return 0;

    // Easy AI: 45% random move for friendly casual fun
    if (_aiDifficulty == AiDifficulty.easy && math.Random().nextDouble() < 0.45) {
      return validCols[math.Random().nextInt(validCols.length)];
    }

    // 1. Check if AI can win immediately
    for (int c in validCols) {
      final r = _findLowestEmptyRow(c);
      _grid[r][c] = ConnectPlayer.yellow;
      final win = _checkWinner(r, c, ConnectPlayer.yellow);
      _grid[r][c] = ConnectPlayer.none;
      if (win != null) return c;
    }

    // 2. Block human opponent from winning immediately
    for (int c in validCols) {
      final r = _findLowestEmptyRow(c);
      _grid[r][c] = ConnectPlayer.red;
      final win = _checkWinner(r, c, ConnectPlayer.red);
      _grid[r][c] = ConnectPlayer.none;
      if (win != null) return c;
    }

    // If Medium, return best prioritized column
    const priority = [3, 2, 4, 1, 5, 0, 6];
    final prioritizedValid = priority.where((c) => validCols.contains(c)).toList();

    // 3. Hard AI: Avoid moves that give opponent immediate win on top
    final safeCols = <int>[];
    for (final c in prioritizedValid) {
      final r = _findLowestEmptyRow(c);
      if (r > 0) {
        _grid[r][c] = ConnectPlayer.yellow;
        _grid[r - 1][c] = ConnectPlayer.red;
        final oppWin = _checkWinner(r - 1, c, ConnectPlayer.red);
        _grid[r - 1][c] = ConnectPlayer.none;
        _grid[r][c] = ConnectPlayer.none;
        if (oppWin == null) {
          safeCols.add(c);
        }
      } else {
        safeCols.add(c);
      }
    }

    if (safeCols.isNotEmpty) {
      return safeCols.first;
    }

    return prioritizedValid.first;
  }

  List<GridPoint>? _checkWinner(int r, int c, ConnectPlayer p) {
    const directions = [
      [GridPoint(0, 1), GridPoint(0, -1)], // Horizontal
      [GridPoint(1, 0), GridPoint(-1, 0)], // Vertical
      [GridPoint(1, 1), GridPoint(-1, -1)], // Diagonal /
      [GridPoint(1, -1), GridPoint(-1, 1)], // Diagonal \
    ];

    for (final dir in directions) {
      final line = <GridPoint>[GridPoint(r, c)];
      for (final step in dir) {
        int currR = r + step.r;
        int currC = c + step.c;
        while (currR >= 0 && currR < rows && currC >= 0 && currC < cols && _grid[currR][currC] == p) {
          line.add(GridPoint(currR, currC));
          currR += step.r;
          currC += step.c;
        }
      }
      if (line.length >= 4) {
        return line;
      }
    }
    return null;
  }

  bool _isWinningDisc(int r, int c) {
    return _winningLine.any((pt) => pt.r == r && pt.c == c);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F141C) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'أربعة في صف • 4 In A Row 🔴🟡',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'إعادة الجولة',
            onPressed: _resetBoard,
          ),
          IconButton(
            icon: Icon(_mode == ConnectGameMode.pvp ? Icons.people_alt_rounded : Icons.smart_toy_rounded),
            tooltip: _mode == ConnectGameMode.pvp ? 'الوضع: لاعبين' : 'الوضع: ضد الذكاء الاصطناعي',
            onPressed: () {
              setState(() {
                _mode = _mode == ConnectGameMode.pvp ? ConnectGameMode.vsAi : ConnectGameMode.pvp;
                _resetBoard();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _mode == ConnectGameMode.pvp
                        ? 'تم التحويل إلى وضع اللعب الزوجي (لاعب ضد لاعب) 👥'
                        : 'تم التحويل إلى وضع اللعب ضد الذكاء الاصطناعي 🤖',
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
                _buildScoreHeader(isDark),
                if (_mode == ConnectGameMode.vsAi) _buildAiDifficultyBar(isDark),
                const SizedBox(height: 6),
                _buildTurnIndicator(isDark),
                const SizedBox(height: 10),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildConnectGrid(isDark),
                    ),
                  ),
                ),
                _buildBottomControls(isDark),
              ],
            ),
          ),
          if (_winner != null)
            Positioned(
              top: 12,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF673AB7), Color(0xFFE91E63)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  _winner == ConnectPlayer.red
                      ? 'مبروك! فاز $_p1Name بالأحمر! 🔴🎉'
                      : 'مبروك! فاز ${_mode == ConnectGameMode.vsAi ? "الذكاء الاصطناعي" : _p2Name} بالأصفر! 🟡🏆',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B222D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScorePlayerTag(
            name: _p1Name,
            color: const Color(0xFFE53935),
            score: _redWins,
            isCurrent: _currentPlayer == ConnectPlayer.red && _winner == null,
            emoji: '🔴',
          ),
          Column(
            children: [
              const Text(
                'تعادل',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              Text(
                '$_draws',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          _buildScorePlayerTag(
            name: _mode == ConnectGameMode.vsAi ? 'الذكاء الاصطناعي 🤖' : _p2Name,
            color: const Color(0xFFFBC02D),
            score: _yellowWins,
            isCurrent: _currentPlayer == ConnectPlayer.yellow && _winner == null,
            emoji: '🟡',
          ),
        ],
      ),
    );
  }

  Widget _buildScorePlayerTag({
    required String name,
    required Color color,
    required int score,
    required bool isCurrent,
    required String emoji,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isCurrent ? color : null,
                ),
              ),
              Text(
                '$score فوز',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator(bool isDark) {
    if (_winner != null) {
      final name = _winner == ConnectPlayer.red
          ? _p1Name
          : (_mode == ConnectGameMode.vsAi ? 'الذكاء الاصطناعي 🤖' : _p2Name);
      final color = _winner == ConnectPlayer.red ? const Color(0xFFE53935) : const Color(0xFFFBC02D);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          '🎉 انتصار ساحق لـ $name! حقق 4 على التوالي!',
          style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 15),
        ),
      );
    }

    if (_isDraw) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Text(
          '🤝 تعادل رائع! امتلأت الرقعة بالكامل',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      );
    }

    final currName = _currentPlayer == ConnectPlayer.red
        ? _p1Name
        : (_mode == ConnectGameMode.vsAi ? 'الذكاء الاصطناعي' : _p2Name);
    final color = _currentPlayer == ConnectPlayer.red ? const Color(0xFFE53935) : const Color(0xFFFBC02D);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          _isAiThinking ? 'الذكاء الاصطناعي يحلل أفضل حركة...' : 'دور: $currName (المس أي عمود للإسقاط)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectGrid(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 16;
        final availableHeight = constraints.maxHeight - 16;

        final discSize = math.min(
          availableWidth / cols,
          availableHeight / rows,
        );

        final boardWidth = discSize * cols;
        final boardHeight = discSize * rows;

        return Interactive3DCard(
          borderRadius: BorderRadius.circular(24),
          maxTiltAngle: 0.08,
          child: Container(
            width: boardWidth + 16,
            height: boardHeight + 16,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF42A5F5), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 1. Column touch gesture targets & static slots
                Row(
                  children: List.generate(cols, (c) {
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _handleColumnTap(c),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(rows, (r) {
                            final player = _grid[r][c];
                            final isWin = _isWinningDisc(r, c);

                            return _buildDiscSlot(
                              player: player,
                              size: discSize * 0.86,
                              isWinning: isWin,
                              isDark: isDark,
                            );
                          }),
                        ),
                      ),
                    );
                  }),
                ),

                // 2. Animated Falling Disc
                if (_droppingCol != null && _targetRow != null && _droppingPlayer != null)
                  AnimatedBuilder(
                    animation: _dropAnimation,
                    builder: (context, child) {
                      final colX = _droppingCol! * discSize + (discSize - discSize * 0.88) / 2;
                      final targetY = _targetRow! * discSize + (discSize - discSize * 0.88) / 2;
                      final currentY = -discSize + (targetY + discSize) * _dropAnimation.value;

                      return Positioned(
                        left: colX,
                        top: currentY,
                        child: _buildDiscToken(
                          _droppingPlayer!,
                          discSize * 0.88,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscSlot({
    required ConnectPlayer player,
    required double size,
    required bool isWinning,
    required bool isDark,
  }) {
    if (player == ConnectPlayer.none) {
      // Empty recessed hole
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF092552),
          border: Border.all(
            color: const Color(0xFF051733),
            width: 2.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 4,
              offset: Offset(0, 3),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        _buildDiscToken(player, size),
        if (isWinning)
          Container(
            width: size + 4,
            height: size + 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD54F), width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDiscToken(ConnectPlayer player, double size) {
    final isRed = player == ConnectPlayer.red;

    final primary = isRed ? const Color(0xFFE53935) : const Color(0xFFFBC02D);
    final secondary = isRed ? const Color(0xFFFF8A80) : const Color(0xFFFFF59D);
    final shadowColor = isRed ? const Color(0xFFB71C1C) : const Color(0xFFF57F17);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: [
            secondary,
            primary,
            shadowColor,
          ],
          stops: const [0.0, 0.65, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(1, 3),
          ),
        ],
        border: Border.all(
          color: isRed ? const Color(0xFFFFCDD2) : const Color(0xFFFFF9C4),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.42,
          height: size * 0.42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiDifficultyBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('مستوى الذكاء: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 8),
          _buildDifficultyChip('سهل 🐣', AiDifficulty.easy),
          const SizedBox(width: 6),
          _buildDifficultyChip('متوازن ⚖️', AiDifficulty.medium),
          const SizedBox(width: 6),
          _buildDifficultyChip('داهية 🧠', AiDifficulty.hard),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String label, AiDifficulty diff) {
    final isSelected = _aiDifficulty == diff;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _aiDifficulty = diff;
            _resetBoard();
          });
        }
      },
      selectedColor: const Color(0xFF1565C0).withValues(alpha: 0.25),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : null,
        color: isSelected ? const Color(0xFF1565C0) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _buildBottomControls(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _resetBoard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('جولة جديدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            onPressed: _moveHistory.isNotEmpty && !_isAiThinking ? _undoMove : null,
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'تراجع عن الحركة',
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (ctx) => _buildRulesSheet(ctx),
              );
            },
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'طريقة اللعب',
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSheet(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'قواعد لعبة أربعة في صف 🔴🟡',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 12),
          const Text(
            '1. يتبادل اللاعبان إسقاط قرص ملون في أي عمود من الأعمدة السبعة.\n'
            '2. يسقط القرص لأقل خانة فارغة في ذلك العمود بحركة فيزيائية واقعية.\n'
            '3. الهدف هو تكوين خط مستقيم متصل من 4 أقراص من لونك (أفقياً، رأسياً، أو قطرياً).\n'
            '4. أول من يربط 4 أقراص يفوز بالجولة فوراً! 🏆\n'
            '5. يمكنك التبديل للعب ضد الذكاء الاصطناعي الذكي في أي لحظة عبر زر الروبوت بالأعلى.',
            style: TextStyle(fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('فهمت، لنبدأ اللعب! 🚀'),
            ),
          ),
        ],
      ),
    );
  }
}

