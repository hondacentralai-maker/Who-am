import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';

class ShareMomentsDialog extends StatelessWidget {
  const ShareMomentsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const ShareMomentsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = PreferencesService.getCouplesProfile();
    final daysTogether = profile.daysTogether;
    final streak = PreferencesService.streakDays;
    final stats = PreferencesService.getStats();
    final points = stats.totalPoints;
    final level = stats.level;

    final shareText =
        '${profile.partner1Name} ❤️ ${profile.partner2Name}\n'
        'معاً منذ $daysTogether يوماً من الحب والتناغم ✨\n'
        'سلسلتنا اليومية: $streak أيام متتالية 🔥\n'
        'المستوى: $level • رصيدنا: $points نقطة 🌟\n'
        'من تطبيق من أنا؟ • لعبة الأزواج 💜';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(22),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'بطاقة مشاركة الحب والتوافق 💌',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),

            // Visual Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5E2B97), Color(0xFF903DD8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x337047D7),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('💍', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    '${profile.partner1Name}  ❤️  ${profile.partner2Name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$daysTogether',
                    style: const TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'يوماً من الألفة والتقارب',
                    style: TextStyle(color: Color(0xFFE6DFFF), fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatChip(icon: '🔥', label: '$streak أيام'),
                      const SizedBox(width: 8),
                      _StatChip(icon: '🌟', label: '$points نقطة'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: shareText));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ نص البطاقة لمشاركتها على واتساب أو الحسابات! 📋💜'),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('نسخ للمشاركة في واتساب 💬'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$icon $label',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
