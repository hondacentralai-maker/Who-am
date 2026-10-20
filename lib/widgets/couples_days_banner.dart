import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/couples_profile.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import 'bouncy_tap.dart';

/// An aesthetic couples banner displaying days together, upcoming anniversary,
/// and partner linking state with quick personalization.
class CouplesDaysBanner extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const CouplesDaysBanner({super.key, this.onProfileUpdated});

  @override
  State<CouplesDaysBanner> createState() => _CouplesDaysBannerState();
}

class _CouplesDaysBannerState extends State<CouplesDaysBanner> {
  late CouplesProfile _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _profile = PreferencesService.getCouplesProfile();
    });
  }

  void _showEditProfileDialog() {
    final name1Ctrl = TextEditingController(text: _profile.partner1Name);
    final name2Ctrl = TextEditingController(text: _profile.partner2Name);
    final titleCtrl = TextEditingController(text: _profile.specialTitle);
    DateTime selectedDate = _profile.startDate;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ملف الشريكين والمناسبة السعيدة 💍',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'خصصا أسماءكما وتاريخ بداية ارتباطكما لحساب أيام الحب والذكرى السنوية',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Name 1
                TextField(
                  controller: name1Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'اسمك / اللقب',
                    prefixIcon: Icon(Icons.person_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Name 2
                TextField(
                  controller: name2Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الشريك / اللقب',
                    prefixIcon: Icon(Icons.favorite_rounded, color: AppColors.accentPink),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'عنوان المناسبة الخاصة',
                    hintText: 'ذكرى زواجنا / أول لقاء',
                    prefixIcon: Icon(Icons.celebration_rounded, color: AppColors.accentGold),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Date Picker Button
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(1980),
                      lastDate: DateTime.now(),
                      locale: const Locale('ar', ''),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    'تاريخ البداية: ${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),

                // My Partner Code
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.palePurple,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_rounded, color: AppColors.purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'رمز الارتباط الخاص بك (شاركه مع شريكك):',
                              style: TextStyle(fontSize: 11, color: AppColors.muted),
                            ),
                            Text(
                              _profile.partnerCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppColors.deepPurple,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'نسخ الرمز',
                        icon: const Icon(Icons.copy_rounded, color: AppColors.purple),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _profile.partnerCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ رمز الارتباط! 📋')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Save Button
                FilledButton(
                  onPressed: () async {
                    final updated = _profile.copyWith(
                      partner1Name: name1Ctrl.text.trim().isEmpty ? 'أنا' : name1Ctrl.text.trim(),
                      partner2Name: name2Ctrl.text.trim().isEmpty ? 'شريكي' : name2Ctrl.text.trim(),
                      specialTitle: titleCtrl.text.trim().isEmpty ? 'ذكرى ارتباطنا' : titleCtrl.text.trim(),
                      startDate: selectedDate,
                    );
                    await PreferencesService.saveCouplesProfile(updated);
                    _loadProfile();
                    widget.onProfileUpdated?.call();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('حفظ التعديلات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysTogether = _profile.daysTogether;
    final daysToAnniversary = _profile.daysUntilNextAnniversary;

    return BouncyTap(
      onTap: _showEditProfileDialog,
      hapticType: AppHapticType.selection,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.midnightAurora
              : const LinearGradient(
                  colors: [Color(0xFF5E2B97), Color(0xFF8E37D7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(24),
          border: isDark
              ? Border.all(
                  color: AppColors.neonPurple.withValues(alpha: 0.35),
                  width: 1.5,
                )
              : null,
          boxShadow: isDark
              ? [
                  ...AppShadows.glow(AppColors.neonPurple, blur: 22, alpha: 0.2),
                  const BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x337047D7),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
                // Header: Names & Edit Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: AppColors.accentPink, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_profile.partner1Name}  ❤️  ${_profile.partner2Name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'تعديل',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Main Metric: Days Together
                Row(
                  children: [
                    Text(
                      '$daysTogether',
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'يومًا من الحب والتناغم',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'كل لحظة تقربكما من بعض أكثر ✨',
                            style: TextStyle(
                              color: Color(0xFFE6DFFF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Footer Pills: Anniversary Countdown & Partner link
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.celebration_rounded, color: AppColors.accentGold, size: 15),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                daysToAnniversary == 0
                                    ? 'اليوم ذكرى ${_profile.specialTitle}! 🎉'
                                    : 'متبقي $daysToAnniversary يوماً على ${_profile.specialTitle} 💍',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
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
