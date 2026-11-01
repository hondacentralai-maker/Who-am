import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/interactive_3d_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late GameStats _stats;
  late List<Achievement> _achievements;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _stats = PreferencesService.getStats();
      _achievements = PreferencesService.getAchievements();
    });
  }

  String _getLevelTitle(int points) {
    if (points >= 500) return 'أسطورة التفاهم والشراكة 👑💎';
    if (points >= 300) return 'رفيق الروح المتألق 💎';
    if (points >= 180) return 'خبير التقارب والتفاهم 🌟';
    if (points >= 80) return 'محاور ذهبي مخلص 👑';
    if (points >= 30) return 'شريك متفاعل ومتفهم 💜';
    return 'مبتدئ في رحلة التقارب 🌱';
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount =
        _achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      appBar: AppBar(title: const Text('الإنجازات والنقاط 🏆')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Level & Points Header Card
            Interactive3DCard(
              borderRadius: BorderRadius.circular(26),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: AppShadows.floatingShadow,
                ),
                child: Column(
                  children: [
                    const Text('👑', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 8),
                    Text(
                      _getLevelTitle(_stats.totalPoints),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded,
                                  color: AppColors.accentGold, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                '${_stats.totalPoints} نقطة',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$unlockedCount من ${_achievements.length} شارة',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Grid
            const Text(
              'إحصائيات اللعب والتقارب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.sports_esports_rounded,
                    label: 'الجولات المكتملة',
                    value: '${_stats.gamesPlayed}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'تخمينات فائزة',
                    value: '${_stats.correctGuesses}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.style_outlined,
                    label: 'بطاقات تمت مناقشتها',
                    value: '${_stats.cardsExplored}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.local_fire_department_rounded,
                    label: 'أعلى سلسلة أيام',
                    value: '${_stats.highestStreak} يوم',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.grid_view_rounded,
                    label: 'ألعاب التجمعات',
                    value: '${_stats.gamesPlayed}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.favorite_border_rounded,
                    label: 'أسئلة تعرفني',
                    value: '${_stats.knowMeAnswered}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.celebration_rounded,
                    label: 'ألعاب الجلسات',
                    value: '${_stats.partyGamesPlayed}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatTile(
                    icon: Icons.casino_rounded,
                    label: 'لفات العجلة',
                    value: '${_stats.wheelSpins}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Badges Section
            const Text(
              'الشارات والإنجازات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            ..._achievements.map((achievement) {
              final badgeCard = Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: achievement.isUnlocked
                      ? Colors.white
                      : const Color(0xFFF6F4FA),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: achievement.isUnlocked
                        ? AppColors.purple.withValues(alpha: 0.3)
                        : const Color(0xFFE5E0F0),
                    width: achievement.isUnlocked ? 1.5 : 1,
                  ),
                  boxShadow:
                      achievement.isUnlocked ? AppShadows.cardShadow : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: achievement.isUnlocked
                            ? AppColors.palePurple
                            : const Color(0xFFEAE7F2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        achievement.emoji,
                        style: TextStyle(
                          fontSize: 26,
                          color: achievement.isUnlocked
                              ? null
                              : Colors.grey.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                achievement.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: achievement.isUnlocked
                                      ? AppColors.ink
                                      : AppColors.muted,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '+${achievement.points} ن',
                                style: TextStyle(
                                  color: achievement.isUnlocked
                                      ? AppColors.purple
                                      : AppColors.muted,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement.description,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              return achievement.isUnlocked
                  ? Interactive3DCard(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      maxTiltAngle: 0.14,
                      enableGlare: true,
                      child: badgeCard,
                    )
                  : badgeCard;
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.outlinedCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.purple, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
