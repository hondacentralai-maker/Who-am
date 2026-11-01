import 'package:flutter/material.dart';
import '../services/game_audio_service.dart';
import '../services/preferences_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _reducedMotion = false;
  bool _soundEnabled = true;
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _darkMode = PreferencesService.isDarkMode;
    _reducedMotion = PreferencesService.reducedMotion;
    _soundEnabled = PreferencesService.soundEnabled;
    _fontScale = PreferencesService.fontScale;
  }

  void _toggleDarkMode(bool v) async {
    setState(() => _darkMode = v);
    await PreferencesService.setDarkMode(v);
    PreferencesService.triggerHaptic(AppHapticType.selection);
    widget.onThemeChanged();
  }

  void _toggleReducedMotion(bool v) async {
    setState(() => _reducedMotion = v);
    await PreferencesService.setReducedMotion(v);
    PreferencesService.triggerHaptic(AppHapticType.selection);
  }

  void _toggleSound(bool v) async {
    setState(() => _soundEnabled = v);
    await PreferencesService.setSoundEnabled(v);
    GameAudioService().isSoundEnabled = v;
    if (v) {
      GameAudioService().playTap();
      PreferencesService.triggerHaptic(AppHapticType.light);
    }
  }

  void _setFontScale(double v) async {
    setState(() => _fontScale = v);
    await PreferencesService.setFontScale(v);
    PreferencesService.triggerHaptic(AppHapticType.selection);
    widget.onThemeChanged();
  }

  void _clearData() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح البيانات المحلية'),
        content: const Text(
          'هل أنت متأكد من مسح جميع الأسئلة الخاصة والمفضلة المحفوظة على هذا الجهاز؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await PreferencesService.saveFavorites({});
              await PreferencesService.saveCustomCards([]);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم مسح البيانات المحلية بنجاح')),
                );
              }
            },
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = PreferencesService.streakDays;
    final user = SupabaseService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Streak Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سلسلة الأيام: $streak ${streak == 1 ? "يوم" : "أيام"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'استمروا في تخصيص وقت يومي للحديث والتقارب 💜',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account Section
            const Text(
              'الحساب والسحابة (Supabase)',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: AppDecorations.outlinedCard(),
              child: ListTile(
                leading: const Icon(Icons.account_circle_outlined,
                    color: AppColors.purple),
                title: Text(
                  user != null ? (user.email ?? 'مسجل') : 'غير مسجل دخولك',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  user != null
                      ? 'مزامنة السحابة مفعلة'
                      : 'سجل دخولك لحفظ غرف اللعب والمفضلة',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                trailing: user != null
                    ? TextButton(
                        onPressed: () async {
                          await SupabaseService.signOut();
                          setState(() {});
                        },
                        child: const Text('خروج'),
                      )
                    : FilledButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AuthScreen(),
                            ),
                          );
                          setState(() {});
                        },
                        child: const Text('دخول'),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Experience Settings
            const Text(
              'تجربة الاستخدام والعرض',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: AppDecorations.outlinedCard(),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'الوضع الداكن',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'ألوان مريحة للعين في الجلسات المسائية',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    value: _darkMode,
                    onChanged: _toggleDarkMode,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'تقليل الحركة (Reduced Motion)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'تقليل المؤثرات الحركية والتنقلات السريعة',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    value: _reducedMotion,
                    onChanged: _toggleReducedMotion,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'المؤثرات الصوتية والاهتزاز',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    value: _soundEnabled,
                    onChanged: _toggleSound,
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'حجم الخط',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('صغير', style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: Slider(
                                value: _fontScale,
                                min: 0.9,
                                max: 1.3,
                                divisions: 4,
                                label: '${(_fontScale * 100).toInt()}%',
                                onChanged: _setFontScale,
                              ),
                            ),
                            const Text('كبير', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About & Legal
            const Text(
              'حول التطبيق والخصوصية',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: AppDecorations.outlinedCard(),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shield_outlined,
                        color: AppColors.purple),
                    title: const Text('سياسة الخصوصية وشروط الاستخدام'),
                    trailing: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent),
                    title: const Text(
                      'مسح البيانات المحلية المحفوظة',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: _clearData,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'نسخة 1.9.0 • صُنع بحب للأزواج في العالم العربي 💜',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
