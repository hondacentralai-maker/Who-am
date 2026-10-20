import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/preferences_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/couples_days_banner.dart';
import 'achievements_screen.dart';
import 'character_screens.dart';
import 'couples_cards_screen.dart';
import 'decision_wheel_screen.dart';
import 'extra_games_screen.dart';
import 'know_me_screen.dart';
import 'love_notes_screen.dart';
import 'online_room_screen.dart';
import 'partner_link_dialog.dart';
import 'party_games_hub_screen.dart';
import 'settings_screen.dart';
import 'share_moments_dialog.dart';
import 'structured_session_screen.dart';
import '../widgets/bouncy_tap.dart';
import '../widgets/glass_bottom_nav.dart';
import 'party_games/five_seconds_screen.dart';
import 'party_games/most_likely_to_screen.dart';
import 'party_games/spyfall_screen.dart';
import 'party_games/stop_game_screen.dart';
import 'party_games/taboo_screen.dart';
import 'party_games/would_you_rather_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const HomeScreen({super.key, required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _activeTabIndex = 0;
  Map<String, dynamic>? _activeSession;
  RealtimeChannel? _invitesChannel;

  @override
  void initState() {
    super.initState();
    _loadState();
    _listenForPartnerInvites();
  }

  void _listenForPartnerInvites() {
    final profile = PreferencesService.getCouplesProfile();
    final userIdentifier =
        SupabaseService.currentUser?.email ?? profile.partnerCode;
    _invitesChannel = SupabaseService.subscribeToUserInvites(
      userIdentifier: userIdentifier,
      onInviteReceived: _handleIncomingInvite,
    );
  }

  @override
  void dispose() {
    if (_invitesChannel != null && SupabaseService.isInitialized) {
      SupabaseService.client.removeChannel(_invitesChannel!);
    }
    super.dispose();
  }

  void _handleIncomingInvite(Map<String, dynamic> payload) {
    if (!mounted) return;
    PreferencesService.triggerHaptic(AppHapticType.medium);
    final hostName = payload['host_name']?.toString() ?? 'شريكك';
    final roomId = payload['room_id']?.toString();
    final roomCode = payload['room_code']?.toString();
    if (roomId == null || roomCode == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.mark_email_unread_rounded, color: AppColors.accentPink),
            SizedBox(width: 8),
            Text('دعوة لعب مباشرة! 💌'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أنشأ $hostName غرفة لعب عن بُعد ويرغب في اللعب معك الآن!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.palePurple,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'رمز الغرفة: $roomCode',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.deepPurple,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لاحقاً'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActiveOnlineRoomScreen(
                    roomId: roomId,
                    roomCode: roomCode,
                    isHost: false,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('قبول والانضمام فوراً 🎮'),
          ),
        ],
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = PreferencesService.streakDays;
    final stats = PreferencesService.getStats();

    String appBarTitle;
    switch (_activeTabIndex) {
      case 1:
        appBarTitle = 'مهرجان الجلسات 🥳';
        break;
      case 2:
        appBarTitle = 'مساحة الشريكين 💍';
        break;
      case 3:
        appBarTitle = 'اللعب عن بُعد 🌐';
        break;
      default:
        appBarTitle = 'من أنا؟ 💜';
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          // Points & Achievements button
          BouncyTap(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AchievementsScreen(),
                ),
              );
              _loadState();
            },
            hapticType: AppHapticType.selection,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF231B3D) : AppColors.palePurple,
                borderRadius: BorderRadius.circular(20),
                border: isDark
                    ? Border.all(
                        color: AppColors.neonPurple.withValues(alpha: 0.35),
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${stats.totalPoints} ن',
                    style: TextStyle(
                      color: isDark ? AppColors.neonPurple : AppColors.deepPurple,
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
              color: isDark ? const Color(0xFF231B3D) : AppColors.palePurple,
              borderRadius: BorderRadius.circular(20),
              border: isDark
                  ? Border.all(
                      color: AppColors.accentGold.withValues(alpha: 0.35),
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: TextStyle(
                    color: isDark ? AppColors.neonGold : AppColors.deepPurple,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'ربط الشريك 🔗',
            icon: Icon(
              Icons.link_rounded,
              color: isDark ? AppColors.neonPurple : AppColors.purple,
            ),
            onPressed: () {
              PartnerLinkDialog.show(context, onLinked: _loadState);
            },
          ),

          IconButton(
            tooltip: 'بطاقة الحب والتوافق 💌',
            icon: const Icon(Icons.favorite_rounded, color: AppColors.accentPink),
            onPressed: () {
              ShareMomentsDialog.show(context);
            },
          ),

          IconButton(
            tooltip: 'الإعدادات',
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? AppColors.midnightText : AppColors.ink,
            ),
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
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _activeTabIndex,
        onTap: (index) {
          setState(() => _activeTabIndex = index);
        },
        items: const [
          GlassNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'الرئيسية',
          ),
          GlassNavItem(
            icon: Icons.celebration_outlined,
            selectedIcon: Icons.celebration_rounded,
            label: 'الجلسات',
          ),
          GlassNavItem(
            icon: Icons.favorite_outline_rounded,
            selectedIcon: Icons.favorite_rounded,
            label: 'الشريكين',
          ),
          GlassNavItem(
            icon: Icons.wifi_tethering_outlined,
            selectedIcon: Icons.wifi_tethering_rounded,
            label: 'عن بُعد',
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: _buildCurrentTab(context, isDark),
        ),
      ),
    );
  }

  Widget _buildCurrentTab(BuildContext context, bool isDark) {
    switch (_activeTabIndex) {
      case 1:
        return _buildPartyTab(context, isDark);
      case 2:
        return _buildCouplesTab(context, isDark);
      case 3:
        return _buildOnlineTab(context, isDark);
      default:
        return _buildHomeTab(context, isDark);
    }
  }

  // ══════════════════════════════════════════════════════════
  // TAB 0: 🏠 الرئيسية (Home Dashboard)
  // ══════════════════════════════════════════════════════════
  Widget _buildHomeTab(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('tab_home'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Couples Days Banner (Days Together, Anniversary & Names)
          CouplesDaysBanner(onProfileUpdated: _loadState),

          // Hero Banner Matching Reference Screen 1
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.midnightAurora
                  : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(30),
              border: isDark
                  ? Border.all(
                      color: AppColors.neonPurple.withValues(alpha: 0.35),
                      width: 1.5,
                    )
                  : null,
              boxShadow: isDark
                  ? [
                      ...AppShadows.glow(AppColors.neonPurple, blur: 26, alpha: 0.22),
                      const BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : AppShadows.elevatedShadow,
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
                BouncyTap(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CharacterIntroScreen(),
                      ),
                    );
                    _loadState();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, color: AppColors.deepPurple, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'ابدأ اللعب',
                          style: TextStyle(
                            color: AppColors.deepPurple,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Button 2: اللعب عن بعد
                BouncyTap(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OnlineRoomScreen(),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'اللعب عن بُعد',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Button 3: قواعد اللعبة
                BouncyTap(
                  onTap: _showGameRules,
                  child: Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'قواعد اللعبة',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
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
                color: isDark ? const Color(0xFF1E1736) : AppColors.palePurple,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.neonPurple : AppColors.purple,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Text('⏳', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تابع لعبتك السابقة',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.neonPurple : AppColors.deepPurple,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'لديك جلسة غير مكتملة، هل ترغب في إكمالها؟',
                          style: TextStyle(
                            color: isDark ? AppColors.midnightMuted : AppColors.muted,
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
            const SizedBox(height: 18),
          ],

          // Quick Moments Bar (Fast Access Tools)
          _buildQuickMomentsBar(context, isDark),
          const SizedBox(height: 22),

          // Section Title
          Text(
            'ألعاب وتجارب اللقاء',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.midnightText : AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),

          // Mode 0: ألعاب الجلسات والتجمعات (Party Games Hub)
          _ModeTile(
            icon: Icons.celebration_rounded,
            title: 'ألعاب الجلسات والتجمعات',
            subtitle:
                '6 ألعاب حماسية للجلسات والبنات (إنسان حيوان، مين فينا، 5 ثواني، الجاسوسة، المحظورات، لو خيروك)',
            badgeText: 'مهرجان الجلسات 🥳',
            accentColor: const Color(0xFFFF5252),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PartyGamesHubScreen(),
              ),
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
            accentColor: AppColors.purple,
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
            accentColor: const Color(0xFF8B5CF6),
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
            accentColor: const Color(0xFFF59E0B),
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
            accentColor: const Color(0xFFEC4899),
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
            accentColor: const Color(0xFF06B6D4),
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
            accentColor: const Color(0xFF3B82F6),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OnlineRoomScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Mode 7: عجلة القرارات اللطيفة للأزواج
          _ModeTile(
            icon: Icons.sync_rounded,
            title: 'عجلة القرارات اللطيفة للأزواج',
            subtitle:
                'حسم عشاء الليلة، السهرة، وتحديات الدلع بعجلة دوارة تفاعلية',
            badgeText: 'عفوية 🎡',
            accentColor: const Color(0xFF10B981),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DecisionWheelScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Mode 8: كبسولة رسائل الحب والذكريات
          _ModeTile(
            icon: Icons.mark_email_read_rounded,
            title: 'كبسولة رسائل الحب والذكريات',
            subtitle:
                'اكتبا لبعضكما رسائل وكبسولات زمنية مقفلة تُفتح في التواريخ السعيدة',
            badgeText: 'رومانسي 💌',
            accentColor: const Color(0xFFE11D48),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LoveNotesScreen(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Offline & Privacy reassurance footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF17122A)
                  : AppColors.palePurple.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: isDark
                  ? Border.all(color: AppColors.midnightCardBorder)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: isDark ? AppColors.neonPurple : AppColors.purple,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'اللعب على جهاز واحد يعمل أوفلاين 100% مع شاشة تسليم محمية تمنع كشف الأسرار.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isDark ? AppColors.midnightMuted : AppColors.muted,
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
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1: 🥳 الجلسات (Party Games Gathering Festival)
  // ══════════════════════════════════════════════════════════
  Widget _buildPartyTab(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('tab_party'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Festival Hero Banner
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF2E0854), Color(0xFF6B1D7C), Color(0xFFB5179E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD), Color(0xFFFF52A8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                ...AppShadows.glow(const Color(0xFFFF52A8), blur: 22, alpha: isDark ? 0.25 : 0.18),
                const BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 26)),
                    SizedBox(width: 8),
                    Text(
                      'مهرجان ألعاب الجلسات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('🥳', style: TextStyle(fontSize: 26)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '6 ألعاب جماعية حماسية للبنات والتجمعات على هاتف واحد أو أونلاين',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                BouncyTap(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PartyGamesHubScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dashboard_customize_rounded, color: Color(0xFF7B2CBF), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'مركز الجلسة الشامل وإدارة الأسماء 👧',
                          style: TextStyle(
                            color: Color(0xFF7B2CBF),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'اختر لعبة الجلسة الفورية 🎲',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.midnightText : AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),

          // 1. Stop Game
          _ModeTile(
            icon: Icons.pets_rounded,
            title: 'إنسان حيوان جماد بلاد',
            subtitle: 'عجلة الحروف العربية، مؤقت حماسي، وحساب النقاط تلقائياً',
            badgeText: 'كلاسيكية 🦁',
            accentColor: const Color(0xFF4CAF50),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StopGameScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Most Likely To
          _ModeTile(
            icon: Icons.how_to_vote_rounded,
            title: 'مين فينا؟ (الأكثر احتمالاً)',
            subtitle: 'تصويت سري ومواقف طريفة تكشف أسرار وتفاصيل الجلسة',
            badgeText: 'ضحك وفضايح 🙋',
            accentColor: const Color(0xFFE91E63),
            onTap: () {
              final profile = PreferencesService.getCouplesProfile();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MostLikelyToScreen(
                    initialPlayers: [profile.partner1Name, profile.partner2Name, 'صديقة 1', 'صديقة 2'],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 3. 5 Seconds
          _ModeTile(
            icon: Icons.timer_rounded,
            title: 'تحدي الـ 5 ثواني',
            subtitle: 'اذكري 3 أشياء قبل انتهاء الـ 5 ثواني مع المؤقت الحماسي',
            badgeText: 'سرعة بديهة ⏱️',
            accentColor: const Color(0xFFFF9800),
            onTap: () {
              final profile = PreferencesService.getCouplesProfile();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FiveSecondsScreen(
                    initialPlayers: [profile.partner1Name, profile.partner2Name, 'صديقة 1', 'صديقة 2'],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 4. Spyfall
          _ModeTile(
            icon: Icons.fingerprint_rounded,
            title: 'الجاسوسة والمندَسّة (Spyfall)',
            subtitle: 'الجميع في مكان سري واحد عدا الجاسوسة! اطرحوا أسئلة لكشفها',
            badgeText: 'تمويه وذكاء 🕵️‍♀️',
            accentColor: const Color(0xFF9C27B0),
            onTap: () {
              final profile = PreferencesService.getCouplesProfile();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SpyfallScreen(
                    initialPlayers: [profile.partner1Name, profile.partner2Name, 'صديقة 1', 'صديقة 2'],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // 5. Taboo
          _ModeTile(
            icon: Icons.speaker_notes_off_rounded,
            title: 'قول بس لا تقول (المحظورات)',
            subtitle: 'اشرحي الكلمة الرئيسية لفريقك بدون نطق الكلمات المحظورة',
            badgeText: 'تحدي كلامي 🤐',
            accentColor: const Color(0xFF00BCD4),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TabooScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // 6. Would You Rather
          _ModeTile(
            icon: Icons.alt_route_rounded,
            title: 'لو خيروك الجماعي',
            subtitle: 'معضلات طريفة وخيارات صعبة وتصويت جماعي لأجواء الجلسة',
            badgeText: 'نقاش وتصويت 🤔',
            accentColor: const Color(0xFFFF5722),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WouldYouRatherScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 2: 💍 الشريكين (Couples Space)
  // ══════════════════════════════════════════════════════════
  Widget _buildCouplesTab(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('tab_couples'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CouplesDaysBanner(onProfileUpdated: _loadState),

          Text(
            'مساحة التعميق والمودة 💖',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.midnightText : AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),

          _ModeTile(
            icon: Icons.access_time_rounded,
            title: 'جلسة الأزواج المنظمة',
            subtitle: '4 خطوات مدروسة: افتتاحية → سؤال → امتنان → تأمل ختامي',
            badgeText: 'موصى به ⭐',
            accentColor: const Color(0xFFF59E0B),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StructuredSessionScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          _ModeTile(
            icon: Icons.favorite_rounded,
            title: 'أسئلة وتحديات للأزواج',
            subtitle: '100+ بطاقة حوار متدرجة بدون تكرار في الجلسة الواحدة',
            accentColor: const Color(0xFFEC4899),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CouplesCardsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          _ModeTile(
            icon: Icons.psychology_alt_rounded,
            title: 'قد إيش تعرفني؟',
            subtitle: 'إجابة سرية وتخمين للشريك في التفضيلات والعادات مع احتساب النقاط',
            badgeText: 'تناغم ✨',
            accentColor: const Color(0xFF8B5CF6),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const KnowMeScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          _ModeTile(
            icon: Icons.sync_rounded,
            title: 'عجلة القرارات اللطيفة للأزواج',
            subtitle: 'حسم عشاء الليلة، السهرة، وتحديات الدلع بعجلة دوارة تفاعلية',
            badgeText: 'عفوية 🎡',
            accentColor: const Color(0xFF10B981),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DecisionWheelScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          _ModeTile(
            icon: Icons.mark_email_read_rounded,
            title: 'كبسولة رسائل الحب والذكريات',
            subtitle: 'اكتبا لبعضكما رسائل وكبسولات زمنية مقفلة تُفتح في التواريخ السعيدة',
            badgeText: 'رومانسي 💌',
            accentColor: const Color(0xFFE11D48),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LoveNotesScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: BouncyTap(
                  onTap: () => PartnerLinkDialog.show(context, onLinked: _loadState),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1736) : AppColors.palePurple,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.neonPurple : AppColors.purple,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.link_rounded,
                          color: isDark ? AppColors.neonPurple : AppColors.deepPurple,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ربط الشريك 🔗',
                          style: TextStyle(
                            color: isDark ? AppColors.neonPurple : AppColors.deepPurple,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BouncyTap(
                  onTap: () => ShareMomentsDialog.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1736) : AppColors.palePurple,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.neonPink : AppColors.accentPink,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_rounded, color: AppColors.accentPink, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'بطاقة الحب 💌',
                          style: TextStyle(
                            color: AppColors.accentPink,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 3: 🌐 عن بُعد (Online Multiplayer Hub)
  // ══════════════════════════════════════════════════════════
  Widget _buildOnlineTab(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('tab_online'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF415A77)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF3A86FF), Color(0xFF5E60CE), Color(0xFF7209B7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                ...AppShadows.glow(const Color(0xFF3A86FF), blur: 22, alpha: isDark ? 0.25 : 0.18),
                const BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'اللعب عن بُعد (غرف Supabase)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'العبوا معاً من هاتفين في أي وقت ومن أي مكان مع مزامنة تفاعلية فورية ودعوة الشريك بنقرة واحدة!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 20),
                BouncyTap(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OnlineRoomScreen(),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_fill_rounded, color: Color(0xFF3A86FF), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'دخول ردهة الغرف الآن 🎮',
                          style: TextStyle(
                            color: Color(0xFF3A86FF),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text(
            'الألعاب المدعومة أونلاين 🌐',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.midnightText : AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),

          _ModeTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'بطاقات الحوار المتزامنة',
            subtitle: 'سحب متزامن للبطاقات وتفاعل مباشر برياكشنز القلوب والضحكات',
            badgeText: 'أونلاين 💬',
            accentColor: const Color(0xFF3B82F6),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OnlineRoomScreen()),
            ),
          ),
          const SizedBox(height: 12),

          _ModeTile(
            icon: Icons.lock_clock_rounded,
            title: 'قد إيش تعرفني؟ (إجابات مشفرة)',
            subtitle: 'إجابة سرية متزامنة من هاتفين وكشف النتيجة والتطابق فوراً',
            badgeText: 'أونلاين 💜',
            accentColor: const Color(0xFF8B5CF6),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OnlineRoomScreen()),
            ),
          ),
          const SizedBox(height: 12),

          _ModeTile(
            icon: Icons.theater_comedy_rounded,
            title: 'خمن الشخصية أونلاين',
            subtitle: 'اختيار سري للشخصية، أسئلة وأجوبة نعم/لا واستبعاد متزامن',
            badgeText: 'أونلاين 🎭',
            accentColor: const Color(0xFFEC4899),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OnlineRoomScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // QUICK MOMENTS BAR (Direction 2: Micro-interactions)
  // ══════════════════════════════════════════════════════════
  Widget _buildQuickMomentsBar(BuildContext context, bool isDark) {
    final items = [
      (
        icon: Icons.sync_rounded,
        color: const Color(0xFF10B981),
        title: 'عجلة القرارات',
        badge: 'عفوية 🎡',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DecisionWheelScreen()),
        ),
      ),
      (
        icon: Icons.mark_email_read_rounded,
        color: const Color(0xFFEC4899),
        title: 'كبسولة الذكريات',
        badge: 'رومانسي 💌',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoveNotesScreen()),
        ),
      ),
      (
        icon: Icons.favorite_rounded,
        color: const Color(0xFFF43F5E),
        title: 'بطاقة التوافق',
        badge: 'مشاركة 📸',
        onTap: () => ShareMomentsDialog.show(context),
      ),
      (
        icon: Icons.link_rounded,
        color: const Color(0xFF8B5CF6),
        title: 'دعوة الشريك',
        badge: 'مزامنة 🔗',
        onTap: () => PartnerLinkDialog.show(context, onLinked: _loadState),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'لحظات سريعة ⚡',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.midnightText : AppColors.ink,
              ),
            ),
            Text(
              'أدوات فورية وممتعة',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.midnightMuted : AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return BouncyTap(
                onTap: item.onTap,
                hapticType: AppHapticType.light,
                child: Container(
                  width: 142,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: isDark
                      ? BoxDecoration(
                          color: const Color(0xFF17122A),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: item.color.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            ...AppShadows.glow(item.color, blur: 14, alpha: 0.12),
                            const BoxShadow(
                              color: Color(0x44000000),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        )
                      : BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: item.color.withValues(alpha: 0.2),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: item.color.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon, size: 16, color: item.color),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: isDark ? 0.2 : 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.badge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: item.color,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.midnightText : AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Tactile Glassmorphic Mode Tile
// ══════════════════════════════════════════════════════════════
class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? accentColor;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.purple;

    return BouncyTap(
      onTap: onTap,
      hapticType: AppHapticType.selection,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: isDark
            ? BoxDecoration(
                color: const Color(0xFF17122A),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  ...AppShadows.glow(color, blur: 18, alpha: 0.12),
                  const BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: color.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: isDark ? 0.28 : 0.15),
                    color.withValues(alpha: isDark ? 0.14 : 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.4 : 0.2),
                ),
              ),
              child: Icon(
                icon,
                color: isDark ? (color == AppColors.purple ? AppColors.neonPurple : color) : color,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.midnightText : AppColors.ink,
                          ),
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
                            color: isDark
                                ? color.withValues(alpha: 0.25)
                                : AppColors.palePurple,
                            borderRadius: BorderRadius.circular(10),
                            border: isDark
                                ? Border.all(color: color.withValues(alpha: 0.4), width: 1)
                                : null,
                          ),
                          child: Text(
                            badgeText!,
                            style: TextStyle(
                              color: isDark ? (color == AppColors.purple ? AppColors.neonPurple : color) : AppColors.purple,
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
                    style: TextStyle(
                      color: isDark ? AppColors.midnightMuted : AppColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: isDark ? AppColors.neonPurple : AppColors.purple,
            ),
          ],
        ),
      ),
    );
  }
}
