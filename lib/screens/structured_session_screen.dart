import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../services/game_data_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';

class StructuredSessionScreen extends StatefulWidget {
  const StructuredSessionScreen({super.key});

  @override
  State<StructuredSessionScreen> createState() =>
      _StructuredSessionScreenState();
}

class _StructuredSessionScreenState extends State<StructuredSessionScreen> {
  StructuredSession? _session;
  bool _loading = true;
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final cards = await GameDataService.loadTypedCards();
    _favorites = PreferencesService.getFavorites();
    if (mounted) {
      setState(() {
        _session = StructuredSession(allCards: cards);
        _loading = false;
      });
    }
  }

  void _nextStep() {
    if (_session == null) return;
    setState(() {
      _session!.next();
      if (_session!.isCompleted) {
        PreferencesService.recordGamePlay();
      }
    });
  }

  void _toggleFavorite(String? cardId) async {
    if (cardId == null) return;
    await PreferencesService.toggleFavorite(cardId, _favorites);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _favorites.contains(cardId)
                ? 'تمت الإضافة للمفضلة 💜'
                : 'تمت الإزالة من المفضلة',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جلسة الأزواج المنظمة (10 دقائق)'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _session == null || _session!.isCompleted
                ? _buildCompletedView()
                : _buildSessionStepView(),
      ),
    );
  }

  Widget _buildSessionStepView() {
    final stepInfo = _session!.currentStep!;
    final card = stepInfo.card;
    final isFav = card != null && _favorites.contains(card.id);
    final stepNum = _session!.currentStepIndex + 1;
    final totalSteps = _session!.steps.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step progress bar
          Row(
            children: [
              Text(
                'الخطوة $stepNum من $totalSteps',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '${(_session!.progress * 100).toInt()}% مكتمل',
                style: const TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_session!.currentStepIndex + 1) / totalSteps,
              minHeight: 8,
              backgroundColor: AppColors.palePurple,
              color: AppColors.purple,
            ),
          ),
          const SizedBox(height: 20),

          // Step header chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.palePurple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(stepInfo.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stepInfo.title,
                        style: const TextStyle(
                          color: AppColors.deepPurple,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        stepInfo.description,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main Card
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: AppShadows.floatingShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (card != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${card.category} • ${card.type}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isFav ? Icons.bookmark : Icons.bookmark_border,
                              color: isFav ? AppColors.accentGold : Colors.white,
                            ),
                            onPressed: () => _toggleFavorite(card.id),
                            tooltip: 'حفظ بالمفضلة',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        card.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.6,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (card.purpose.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          card.purpose,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ] else ...[
                      const Text(
                        'لا توجد بطاقة لهذه المرحلة',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _nextStep,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('تخطي للخطوة التالية'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _nextStep,
                  icon: Icon(
                    stepNum == totalSteps
                        ? Icons.check_circle_rounded
                        : Icons.arrow_back_ios_new_rounded,
                    size: 18,
                  ),
                  label: Text(
                    stepNum == totalSteps ? 'إنهاء الجلسة 🎉' : 'الخطوة التالية',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            const Text(
              'أحسنتم! جلسة مميزة 💜',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '10 دقائق من الحوار والتأمل تصنع فارقًا كبيرًا في القرب والتفاهم.\nتم تسجيل يوم جديد في سلسلتكم!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _initSession();
                });
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('بدء جلسة جديدة'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('الرجوع للرئيسية'),
            ),
          ],
        ),
      ),
    );
  }
}
