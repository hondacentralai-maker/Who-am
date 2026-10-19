import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/couples_profile.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';

class PartnerLinkDialog extends StatefulWidget {
  final VoidCallback? onLinked;

  const PartnerLinkDialog({super.key, this.onLinked});

  static Future<void> show(BuildContext context, {VoidCallback? onLinked}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => PartnerLinkDialog(onLinked: onLinked),
    );
  }

  @override
  State<PartnerLinkDialog> createState() => _PartnerLinkDialogState();
}

class _PartnerLinkDialogState extends State<PartnerLinkDialog> {
  late CouplesProfile _profile;
  final TextEditingController _partnerInputCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _profile = PreferencesService.getCouplesProfile();
    if (_profile.linkedPartnerEmail != null) {
      _partnerInputCtrl.text = _profile.linkedPartnerEmail!;
    }
  }

  @override
  void dispose() {
    _partnerInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLinkPartner() async {
    final input = _partnerInputCtrl.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رمز الشريك أو بريده الإلكتروني')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await PreferencesService.linkPartner(
        partnerEmail: input,
      );

      if (mounted) {
        setState(() {
          _profile = PreferencesService.getCouplesProfile();
        });
        widget.onLinked?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF2E7D32),
            content: Text('تم ربط الشريك بنجاح! 💜 يمكنك الآن دعوته للعب بضغطة زر واحدة.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الربط: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUnlinkPartner() async {
    await PreferencesService.unlinkPartner();
    if (mounted) {
      setState(() {
        _profile = PreferencesService.getCouplesProfile();
        _partnerInputCtrl.clear();
      });
      widget.onLinked?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء ربط الشريك')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLinked = _profile.isPartnerLinked;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.link_rounded, color: AppColors.purple),
          SizedBox(width: 8),
          Text('ربط حساب الشريك 🔗'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'عند ربط حساب شريكك، لن تحتاج لنسخ أو إرسال الرمز في كل مرة! ستتمكن من دعوته بضغطة زر واحدة.',
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),

            // My Code Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.palePurple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رمز الارتباط الخاص بحسابك:',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _profile.partnerCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.deepPurple,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        tooltip: 'نسخ الرمز',
                        icon: const Icon(Icons.copy_rounded, color: AppColors.purple, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _profile.partnerCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ رمز الارتباط! 📋 شاركه مع شريكك')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (isLinked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'حساب شريكك مرتبط حالياً:',
                            style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                          ),
                          Text(
                            _profile.linkedPartnerEmail ?? 'شريك مرتبط',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: _handleUnlinkPartner,
                icon: const Icon(Icons.link_off_rounded),
                label: const Text('إلغاء الارتباط الحالي'),
              ),
            ] else ...[
              TextField(
                controller: _partnerInputCtrl,
                decoration: const InputDecoration(
                  labelText: 'رمز الشريك أو بريده الإلكتروني',
                  hintText: 'مثال: LOVE-1234 أو user@mail.com',
                  prefixIcon: Icon(Icons.person_add_alt_1_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isLoading ? null : _handleLinkPartner,
                icon: const Icon(Icons.link_rounded),
                label: Text(_isLoading ? 'جاري التحقق...' : 'ربط الشريك الآن 🔗'),
              ),
            ],
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
