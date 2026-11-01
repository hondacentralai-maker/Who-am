import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/game_audio_service.dart';
import '../../services/preferences_service.dart';
import '../../widgets/jackaroo_3d_board_view.dart';

/// Native Flutter game surface; controls never cover the reference photograph.
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
  final _boardKey = GlobalKey<Jackaroo3DBoardViewState>();
  final _random = math.Random();
  final _audio = GameAudioService();
  static const _gold = Color(0xFFDCC17D);
  static const _initialHand = ['A♠', 'K♥', '7♦', '4♣', 'J♠'];
  final _hand = List<String>.of(_initialHand);
  int _selectedCardIndex = 0;
  int _team1Score = 0;
  int _team2Score = 0;
  bool _isTopDownView = true;
  bool _busy = false;
  bool _sound = true;
  String _status = 'اختر ورقة ثم المس إحدى كراتك الزرقاء.';

  @override
  void initState() {
    super.initState();
    _sound = _audio.isSoundEnabled;
  }

  void _playCard(int index) {
    if (_busy) return;
    setState(() {
      _selectedCardIndex = index;
      _status = 'تم اختيار ${_hand[index]}؛ المس الكرة التي تريد تحريكها.';
    });
    _audio.playCardDeal();
  }

  void _onTurnFinished() {
    if (!mounted) return;
    const ranks = [
      'A',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
    ];
    const suits = ['♠', '♥', '♦', '♣'];
    setState(() {
      _hand[_selectedCardIndex] =
          '${ranks[_random.nextInt(ranks.length)]}${suits[_random.nextInt(suits.length)]}';
    });
  }

  void _restart() {
    setState(() {
      _hand.setAll(0, _initialHand);
      _selectedCardIndex = 0;
      _team1Score = 0;
      _team2Score = 0;
      _busy = false;
    });
    _boardKey.currentState?.resetGame();
  }

  void _showVictory(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('انتهت الجولة'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restart();
            },
            child: const Text('جولة جديدة'),
          ),
        ],
      ),
    );
  }

  void _showRules() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('قواعد النسخة الحالية'),
        content: const SingleChildScrollView(
          child: Text(
            'الأزرق والأسود فريق، والأخضر والسماوي فريق. تلعب بالأزرق، وتلعب بقية الألوان تلقائيًا.\n\n'
            'A أو K: إخراج كرة من البيت. على المسار: A خطوة، وK ثلاث عشرة خطوة.\n\n'
            '4: أربع خطوات للخلف. Q: اثنتا عشرة خطوة. باقي الأوراق الرقمية: عددها من الخطوات.\n\n'
            'J: اختر كرتك ثم كرة منافس لتبديلهما. الكرة الموجودة على نقطة بدايتها محمية.\n\n'
            'لا تتجاوز كرتك أو كرة على نقطة بداية محمية. النزول على كرة غير محمية يعيدها إلى البيت.\n\n'
            'تدخل مسار الأمان من بوابته بعد إكمال المسار أو الاقتراب منها بالرجوع. لا تتجاوز آخر حفرة أو كرة داخل الأمان.\n\n'
            'عند إدخال كراتك الأربع، تساعد شريكك الأسود. يفوز الفريق بإدخال كراته الثماني.\n\n'
            'زر «لا توجد حركة» يمرر الدور إذا كانت الورقة المختارة لا تملك حركة متاحة.\n\n'
            'الترقيم يبدأ من 1 بعد كل نقطة ملونة وينتهي بـ18 قبل النقطة التالية. تقسيم السبعة واختيار A كإحدى عشرة خطوة غير مضافين في هذه النسخة.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = Jackaroo3DBoardView(
      key: _boardKey,
      activeCard: _hand[_selectedCardIndex],
      isTopDownView: _isTopDownView,
      onStatusMessage: (text) {
        if (mounted) setState(() => _status = text);
      },
      onBusyChanged: (busy) {
        if (mounted) setState(() => _busy = busy);
      },
      onScoresUpdated: (first, second) {
        if (mounted) {
          setState(() {
            _team1Score = first;
            _team2Score = second;
          });
        }
      },
      onTurnFinished: _onTurnFinished,
      onGameWon: _showVictory,
    );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1620),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0E1620),
          foregroundColor: Colors.white,
          title: const Text(
            'جاكارو • اللوحة المعتمدة',
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            IconButton(
              tooltip: _sound ? 'كتم الصوت' : 'تشغيل الصوت',
              onPressed: () {
                setState(() => _sound = !_sound);
                _audio.isSoundEnabled = _sound;
                PreferencesService.triggerHaptic(AppHapticType.selection);
              },
              icon: Icon(
                _sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: _gold,
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panel = Column(
                mainAxisSize: MainAxisSize.min,
                children: [_buildStatus(), _buildControls(), _buildHand()],
              );
              if (constraints.maxWidth > 700 &&
                  constraints.maxWidth > constraints.maxHeight) {
                return Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: board,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: SingleChildScrollView(child: panel),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildStatus(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: board,
                    ),
                  ),
                  _buildControls(),
                  _buildHand(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatus() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isOnline)
              const Text(
                'هذه اللوحة تعمل محليًا حاليًا',
                style: TextStyle(color: _gold, fontSize: 12),
              ),
            Text(
              _status,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 20,
              alignment: WrapAlignment.center,
              children: [
                Text(
                  '🔵 ⚫  فريقك: $_team1Score/8',
                  style: const TextStyle(color: _gold, fontSize: 12),
                ),
                Text(
                  '🟢 🔹  المنافس: $_team2Score/8',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildControls() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 0,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _isTopDownView = !_isTopDownView),
              icon: Icon(
                _isTopDownView ? Icons.camera_alt_outlined : Icons.view_in_ar,
                size: 16,
              ),
              label: Text(_isTopDownView ? 'مظهر الصورة' : 'منظور 3D'),
              style: TextButton.styleFrom(foregroundColor: _gold),
            ),
            TextButton(onPressed: _showRules, child: const Text('القوانين')),
            TextButton(
              onPressed:
                  _busy ? null : () => _boardKey.currentState?.passTurn(),
              child: const Text('لا توجد حركة'),
            ),
            IconButton(
              tooltip: 'جولة جديدة',
              onPressed: _restart,
              icon: const Icon(Icons.restart_alt, color: Colors.white70),
            ),
          ],
        ),
      );

  Widget _buildHand() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أوراقك في اليد (اختر ورقة للعب):',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Row(
                textDirection: TextDirection.ltr,
                children: [
                  for (var index = 0; index < _hand.length; index++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Semantics(
                          button: true,
                          selected: index == _selectedCardIndex,
                          enabled: !_busy,
                          child: GestureDetector(
                            key: ValueKey('jackaroo-card-$index'),
                            onTap: _busy ? null : () => _playCard(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              height: 78,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: _busy
                                    ? const Color(0xFFCCCCCC)
                                    : const Color(0xFFFFFEFA),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: index == _selectedCardIndex
                                      ? _gold
                                      : Colors.white24,
                                  width: 2,
                                ),
                                boxShadow: index == _selectedCardIndex
                                    ? [
                                        BoxShadow(
                                          color: _gold.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: DefaultTextStyle(
                                style: TextStyle(
                                  color: _hand[index].contains('♥') ||
                                          _hand[index].contains('♦')
                                      ? const Color(0xFFB22435)
                                      : const Color(0xFF152133),
                                  fontWeight: FontWeight.bold,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _hand[index],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          _hand[index].characters.last,
                                          style: const TextStyle(fontSize: 27),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}
