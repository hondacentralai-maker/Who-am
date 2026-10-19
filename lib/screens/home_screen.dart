import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import 'achievements_screen.dart';
import 'character_screens.dart';
import 'couples_cards_screen.dart';
import 'extra_games_screen.dart';
import 'know_me_screen.dart';
import 'online_room_screen.dart';
import 'settings_screen.dart';
import 'structured_session_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const HomeScreen({super.key, required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _activeSession;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  void _loadState() {
    setState(() {
      _activeSession = PreferencesService.getActiveSession();
    });
  }

  void _showGameRules() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: AppColors.purple),
            SizedBox(width: 10),
            Text('قواعد لعبة «من أنا؟» 📖'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. يختار كل لاعب شخصية سرية من اللوحة، ويتم إخفاؤها تماماً عن الشريك.',
                  style: TextStyle(height: 1.6, fontWeight: FontWeight.w600)),
              SizedBox(height: 10),
              Text('2. يتناوب الشريكان على طرح أسئلة إجابتها (نعم / لا) حول صفات الشخصية (اللحية، النظارة، الشماغ، الحجاب، إلخ).',
                  style: TextStyle(height: 1.6)),
              SizedBox(height: 10),
              Text('3. يتم استبعاد الشخصيات التي لا تنطبق عليها الإجابات لتضييق دائرة التخمين.',
                  style: TextStyle(height: 1.6)),
              SizedBox(height: 10),
              Text('4. أول من يخمن شخصية الطرف الآخر بدقة يفوز بالجولة ويحصل على +30 نقطة!',
                  style: TextStyle(height: 1.6)),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('فهمت القواعد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = PreferencesService.streakDays;
    final stats = PreferencesService.getStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('من أنا؟ 💜'),
        actions: [
          // Points & Achievements button
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AchievementsScreen(),
                ),
              );
              _loadState();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.palePurple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.totalPoints} ن',
                    style: const TextStyle(
                      color: AppColors.deepPurple,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Streak indicator badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.palePurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: const TextStyle(
                    color: AppColors.deepPurple,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings_outlined, color: AppColors.ink),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              );
              _loadState();
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Banner Matching Reference Screen 1
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppShadows.elevatedShadow,
                ),
                child: Column(
                  children: [
                    const Text(
                      'من أنا؟ 💜',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'خمن شخصية شريكك',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 3D Couple Illustration
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/hero_couple.png',
                        height: 175,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('👳🏻‍♂️', style: TextStyle(fontSize: 42)),
                            SizedBox(width: 14),
                            Text('❔', style: TextStyle(fontSize: 30)),
                            SizedBox(width: 14),
                            Text('🧕🏻', style: TextStyle(fontSize: 42)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Button 1: ابدأ اللعب
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CharacterIntroScreen(),
                            ),
                          );
                          _loadState();
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 24),
                        label: const Text(
                          'ابدأ اللعب',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Button 2: اللعب عن بعد
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OnlineRoomScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.people_outline_rounded, size: 20),
                        label: const Text(
                          'اللعب عن بُعد',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Button 3: قواعد اللعبة
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _showGameRules,
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text(
                          'قواعد اللعبة',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Resume Session Banner (if available)
              if (_activeSession != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.palePurple,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.purple, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Text('⏳', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تابع لعبتك السابقة',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.deepPurple,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'لديك جلسة غير مكتملة، هل ترغب في إكمالها؟',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          PreferencesService.clearActiveSession();
                          _loadState();
                        },
                        child: const Text('إلغاء',
                            style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Section Title
              const Text(
                'ألعاب وتجارب اللقاء',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),

              // Mode 1: خمن الشخصية
              _ModeTile(
                icon: Icons.people_alt_rounded,
                title: 'خمن الشخصية',
                subtitle:
                    '24 شخصية بملامح وأزياء عربية، أسئلة نعم/لا مع شاشة تسليم الهاتف',
                badgeText: 'كلاسيكي 🎭',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CharacterIntroScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Mode 2: قد إيش تعرفني؟ (Dedicated Mode!)
              _ModeTile(
                icon: Icons.psychology_alt_rounded,
                title: 'قد إيش تعرفني؟',
                subtitle:
                    'إجابة سرية وتخمين للشريك في التفضيلات والعادات مع احتساب النقاط',
                badgeText: 'جديد ✨',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const KnowMeScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Mode 3: جلسة الأزواج المنظمة
              _ModeTile(
                icon: Icons.access_time_rounded,
                title: 'جلسة الأزواج المنظمة',
                subtitle:
                    '4 خطوات مدروسة: افتتاحية → سؤال → امتنان → تأمل ختامي',
                badgeText: 'موصى به ⭐',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StructuredSessionScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Mode 4: أسئلة وتحديات للأزواج
              _ModeTile(
                icon: Icons.favorite_rounded,
                title: 'أسئلة وتحديات للأزواج',
                subtitle: '100+ بطاقة حوار متدرجة بدون تكرار في الجلسة الواحدة',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CouplesCardsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Mode 5: ألعاب إضافية
              _ModeTile(
                icon: Icons.auto_awesome_rounded,
                title: 'ألعاب خفيفة وسؤال اليوم',
                subtitle:
                    'هذا أو ذاك، المفضلة، وإدارة أسئلتكم الخاصة بالتعديل والحذف',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExtraGamesScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Mode 6: غرف اللعب عن بعد (Supabase)
              _ModeTile(
                icon: Icons.cloud_sync_rounded,
                title: 'غرف اللعب عن بُعد (جميع الألعاب)',
                subtitle:
                    'العبوا معاً من هاتفين: بطاقات الحوار، قد إيش تعرفني؟، وخمن الشخصية بمزامنة سريعة',
                badgeText: 'أونلاين 🌐',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnlineRoomScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Offline & Privacy reassurance footer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.palePurple.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 18, color: AppColors.purple),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'اللعب على جهاز واحد يعمل أوفلاين 100% مع شاشة تسليم محمية تمنع كشف الأسرار.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.palePurple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.purple, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.palePurple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badgeText!,
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: AppColors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
