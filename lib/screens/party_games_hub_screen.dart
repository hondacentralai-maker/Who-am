import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import 'online_room_screen.dart';
import 'party_games/five_seconds_screen.dart';
import 'party_games/most_likely_to_screen.dart';
import 'party_games/spyfall_screen.dart';
import 'party_games/stop_game_screen.dart';
import 'party_games/taboo_screen.dart';
import 'party_games/would_you_rather_screen.dart';

class PartyGamesHubScreen extends StatefulWidget {
  const PartyGamesHubScreen({super.key});

  @override
  State<PartyGamesHubScreen> createState() => _PartyGamesHubScreenState();
}

class _PartyGamesHubScreenState extends State<PartyGamesHubScreen> {
  List<String> _groupPlayers = ['سارة', 'نور', 'شهد', 'ريم'];

  @override
  void initState() {
    super.initState();
    final profile = PreferencesService.getCouplesProfile();
    _groupPlayers = [profile.partner1Name, profile.partner2Name, 'صديقة 1', 'صديقة 2'];
  }

  void _showManagePlayersDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('قائمة لاعبات الجلسة 👧'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'أضيفي أسماء الحاضرات لتسجيل النقاط وتمرير الأدوار تلقائياً:',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          decoration: const InputDecoration(
                            labelText: 'اسم لاعبة جديدة',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final name = ctrl.text.trim();
                          if (name.isNotEmpty) {
                            setState(() {
                              _groupPlayers.add(name);
                            });
                            setDialogState(() {
                              ctrl.clear();
                            });
                          }
                        },
                        child: const Text('إضافة'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _groupPlayers.map((p) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: AppColors.purple,
                          child: Text(
                            p.characters.first,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                        label: Text(p, style: const TextStyle(fontWeight: FontWeight.bold)),
                        onDeleted: _groupPlayers.length > 2
                            ? () {
                                setState(() {
                                  _groupPlayers.remove(p);
                                });
                                setDialogState(() {});
                              }
                            : null,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('تم وحفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ألعاب الجلسات والتجمعات 🥳'),
        actions: [
          IconButton(
            tooltip: 'إدارة لاعبات الجلسة',
            icon: const Icon(Icons.group_add_rounded),
            onPressed: _showManagePlayersDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Hero Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.deepPurple, AppColors.purple],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('🎉', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مهرجان الألعاب الجماعية',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'ألعاب حماسية للبنات والجلسات والأصدقاء',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'اللاعبات الحاضرات: ${_groupPlayers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                        ),
                        onPressed: _showManagePlayersDialog,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('تعديل الأسماء'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Game Cards
            _buildPartyCard(
              title: 'إنسان، حيوان، نبات (أوتوبيس كومبليت)',
              subtitle: 'لعبة الكلمات التنافسية الكلاسيكية مع عجلة الحروف وزر STOP الحاسم!',
              emoji: '🚌',
              tag: '2 - 8 لاعبين • سرعة وتحدي',
              color: const Color(0xFFE8F5E9),
              borderColor: const Color(0xFF81C784),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StopGameScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildPartyCard(
              title: 'مين فينا؟ / مين أكثر واحدة؟',
              subtitle: 'تصويت جماعي سري يكشف أكثر واحدة تنطبق عليها المواقف الطريفة!',
              emoji: '🎭',
              tag: '3 - 10 لاعبين • كشف وفضائح عفوية',
              color: const Color(0xFFF3E5F5),
              borderColor: AppColors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MostLikelyToScreen(initialPlayers: _groupPlayers),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildPartyCard(
              title: 'تحدي الـ 5 ثواني',
              subtitle: 'اذكري 3 أشياء قبل انتهاء الـ 5 ثواني مع المؤقت الحماسي والنبضات!',
              emoji: '⏱️',
              tag: '2 - 6 لاعبين • سرعة بديهة فائقة',
              color: const Color(0xFFFFF3E0),
              borderColor: Colors.orangeAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FiveSecondsScreen(initialPlayers: _groupPlayers),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildPartyCard(
              title: 'الجاسوسة والمندَسّة (Spyfall)',
              subtitle: 'الجميع في مكان سري واحد عدا الجاسوسة! اطرحوا أسئلة لكشفها قبل فوات الأوان.',
              emoji: '🕵️‍♀️',
              tag: '3 - 8 لاعبين • ذكاء اجتماعي وتمويه',
              color: const Color(0xFFFFEBEE),
              borderColor: Colors.redAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpyfallScreen(initialPlayers: _groupPlayers),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildPartyCard(
              title: 'قول بس لا تقول (المحظورات)',
              subtitle: 'اشرحي الكلمة الرئيسية لفريقك بدون نطق الكلمات المحظورة في البطاقة!',
              emoji: '🤐',
              tag: 'فريقين (4+ لاعبين) • تنافس كلامي',
              color: const Color(0xFFE1F5FE),
              borderColor: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TabooScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildPartyCard(
              title: 'لو خيروك الجماعي',
              subtitle: 'معضلات طريفة وخيارات صعبة وتصويت جماعي لمعرفة مدى انسجام الجلسة!',
              emoji: '🤔',
              tag: 'الجميع • نقاش وضحك',
              color: const Color(0xFFFBE9E7),
              borderColor: Colors.deepOrangeAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WouldYouRatherScreen()),
                );
              },
            ),
            const SizedBox(height: 24),

            // Remote Play Online Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_tethering_rounded, color: AppColors.purple, size: 36),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ترغبون باللعب من جهازين مختلفين؟',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'افتحوا غرفة اللعب عن بعد للاتصال المباشر واللعب في وقت واحد!',
                          style: TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OnlineRoomScreen()),
                      );
                    },
                    child: const Text('الغرفة 🌐'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyCard({
    required String title,
    required String subtitle,
    required String emoji,
    required String tag,
    required Color color,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          PreferencesService.triggerHaptic(AppHapticType.light);
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppColors.deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: borderColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
