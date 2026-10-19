import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';

/// Haptic feedback intensity options.
enum AppHapticType { light, medium, selection }

/// Local storage service wrapping SharedPreferences.
class PreferencesService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p => _prefs!;

  // ─── Favorites ──────────────────────────────────────
  static const _favKey = 'favorite_couples_cards_v1';

  static Set<String> getFavorites() =>
      (_p.getStringList(_favKey) ?? []).toSet();

  static Future<void> saveFavorites(Set<String> ids) =>
      _p.setStringList(_favKey, ids.toList());

  static Future<void> toggleFavorite(String id, Set<String> current) async {
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    await saveFavorites(current);
  }

  // ─── Custom Cards (CRUD) ───────────────────────────
  static const _customKey = 'custom_couples_cards_v1';

  static List<Map<String, dynamic>> getCustomCards() {
    final raw = _p.getString(_customKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomCards(List<Map<String, dynamic>> cards) =>
      _p.setString(_customKey, jsonEncode(cards));

  static Future<void> addCustomCard(Map<String, dynamic> card) async {
    final list = getCustomCards();
    list.add(card);
    await saveCustomCards(list);
    await unlockAchievement('custom_creator');
  }

  static Future<void> updateCustomCard(
      String id, Map<String, dynamic> updated) async {
    final list = getCustomCards();
    final index = list.indexWhere((c) => c['id'] == id);
    if (index != -1) {
      list[index] = updated;
      await saveCustomCards(list);
    }
  }

  static Future<void> deleteCustomCard(String id) async {
    final list = getCustomCards();
    list.removeWhere((c) => c['id'] == id);
    await saveCustomCards(list);
  }

  // ─── Custom Know-Me Questions (CRUD) ───────────────
  static const _customKnowMeKey = 'custom_know_me_questions_v1';

  static List<Map<String, dynamic>> getCustomKnowMeQuestions() {
    final raw = _p.getString(_customKnowMeKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomKnowMeQuestions(
      List<Map<String, dynamic>> questions) =>
      _p.setString(_customKnowMeKey, jsonEncode(questions));

  static Future<void> addCustomKnowMeQuestion(
      Map<String, dynamic> question) async {
    final list = getCustomKnowMeQuestions();
    list.add(question);
    await saveCustomKnowMeQuestions(list);
    await unlockAchievement('custom_creator');
  }

  static Future<void> deleteCustomKnowMeQuestion(String id) async {
    final list = getCustomKnowMeQuestions();
    list.removeWhere((q) => q['id'] == id);
    await saveCustomKnowMeQuestions(list);
  }

  // ─── Active Session Resumption ──────────────────────
  static const _activeSessionKey = 'active_game_session_v1';

  static Map<String, dynamic>? getActiveSession() {
    final raw = _p.getString(_activeSessionKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveActiveSession(Map<String, dynamic> data) =>
      _p.setString(_activeSessionKey, jsonEncode(data));

  static Future<void> clearActiveSession() =>
      _p.remove(_activeSessionKey);

  // ─── Stats & Points ────────────────────────────────
  static const _statsKey = 'player_game_stats_v1';

  static GameStats getStats() {
    final raw = _p.getString(_statsKey);
    if (raw == null) {
      return GameStats(
        currentStreak: streakDays,
        highestStreak: streakDays,
      );
    }
    try {
      return GameStats.fromJson(jsonDecode(raw));
    } catch (_) {
      return const GameStats();
    }
  }

  static Future<void> saveStats(GameStats stats) =>
      _p.setString(_statsKey, jsonEncode(stats.toJson()));

  static Future<void> addPoints(int points) async {
    final current = getStats();
    final updated = current.copyWith(
      totalPoints: current.totalPoints + points,
    );
    await saveStats(updated);
  }

  static Future<void> recordGameFinished({
    bool isGuessWin = false,
    bool isKnowMe = false,
    bool isCard = false,
    int pointsEarned = 10,
  }) async {
    await recordGamePlay();
    final current = getStats();
    final updated = current.copyWith(
      gamesPlayed: current.gamesPlayed + 1,
      totalPoints: current.totalPoints + pointsEarned,
      correctGuesses:
          isGuessWin ? current.correctGuesses + 1 : current.correctGuesses,
      knowMeAnswered:
          isKnowMe ? current.knowMeAnswered + 1 : current.knowMeAnswered,
      cardsExplored:
          isCard ? current.cardsExplored + 1 : current.cardsExplored,
      currentStreak: streakDays,
      highestStreak: streakDays > current.highestStreak
          ? streakDays
          : current.highestStreak,
    );
    await saveStats(updated);

    // Check achievement triggers
    await unlockAchievement('first_game');
    if (streakDays >= 3) await unlockAchievement('streak_3');
    if (streakDays >= 7) await unlockAchievement('streak_7');
    if (updated.correctGuesses >= 3) {
      await unlockAchievement('guess_master');
    }
    if (updated.cardsExplored >= 20) {
      await unlockAchievement('deep_talker');
    }
    if (updated.knowMeAnswered >= 10) {
      await unlockAchievement('know_me_pro');
    }
  }

  // ─── Achievements ──────────────────────────────────
  static const _achievementsKey = 'player_achievements_v1';

  static List<Achievement> _defaultAchievements() => [
        const Achievement(
          id: 'first_game',
          title: 'أول خطوة 💜',
          description: 'أكملتم أول جولة لعب معًا بنجاح',
          emoji: '🌱',
          points: 20,
        ),
        const Achievement(
          id: 'streak_3',
          title: 'بداية الالتزام 🔥',
          description: 'حافظتم على اللعب والتقارب لمدة 3 أيام متتالية',
          emoji: '🔥',
          points: 30,
        ),
        const Achievement(
          id: 'streak_7',
          title: 'شعلة الأسبوع 🌟',
          description: 'سلسلة أسبوع كامل من الحوارات اليومية',
          emoji: '👑',
          points: 50,
        ),
        const Achievement(
          id: 'guess_master',
          title: 'خبير التخمين 🎭',
          description: 'فزتم بـ 3 تخمينات صحيحة في خمن الشخصية',
          emoji: '🎯',
          points: 40,
        ),
        const Achievement(
          id: 'know_me_pro',
          title: 'فاهم شريكي 💜',
          description: 'أجبتم على 10 أسئلة في قد إيش تعرفني',
          emoji: '✨',
          points: 40,
        ),
        const Achievement(
          id: 'deep_talker',
          title: 'حوار من القلب 💬',
          description: 'تصفحتم 20 بطاقة حوار وتحدي',
          emoji: '💌',
          points: 30,
        ),
        const Achievement(
          id: 'custom_creator',
          title: 'لمستنا الخاصة ✏️',
          description: 'أضفتم بطاقة أو سؤالاً خاصاً بكم إلى اللعبة',
          emoji: '🎨',
          points: 25,
        ),
      ];

  static List<Achievement> getAchievements() {
    final raw = _p.getString(_achievementsKey);
    final defaults = _defaultAchievements();
    if (raw == null) return defaults;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Achievement.fromJson(e))
          .toList();
      // Ensure all defaults exist
      final map = {for (final a in list) a.id: a};
      return defaults.map((d) => map[d.id] ?? d).toList();
    } catch (_) {
      return defaults;
    }
  }

  static Future<void> saveAchievements(List<Achievement> list) =>
      _p.setString(
          _achievementsKey, jsonEncode(list.map((e) => e.toJson()).toList()));

  static Future<bool> unlockAchievement(String id) async {
    final list = getAchievements();
    final index = list.indexWhere((a) => a.id == id);
    if (index != -1 && !list[index].isUnlocked) {
      list[index] = list[index].copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      await saveAchievements(list);
      await addPoints(list[index].points);
      return true;
    }
    return false;
  }

  // ─── Streak & Habits ────────────────────────────────
  static int get streakDays => _p.getInt('streak_days') ?? 1;
  static String? get lastPlayedDate => _p.getString('last_played_date');

  static Future<void> recordGamePlay() async {
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final last = lastPlayedDate;

    if (last == null) {
      await _p.setInt('streak_days', 1);
      await _p.setString('last_played_date', today);
    } else if (last != today) {
      final parts = last.split('-').map(int.parse).toList();
      final lastDate = DateTime(parts[0], parts[1], parts[2]);
      final difference = now.difference(lastDate).inDays;

      if (difference == 1) {
        await _p.setInt('streak_days', streakDays + 1);
      } else if (difference > 1) {
        await _p.setInt('streak_days', 1);
      }
      await _p.setString('last_played_date', today);
    }
  }

  // ─── Settings ──────────────────────────────────────
  static bool get isDarkMode => _p.getBool('dark_mode') ?? false;
  static Future<void> setDarkMode(bool v) => _p.setBool('dark_mode', v);

  static bool get reducedMotion => _p.getBool('reduced_motion') ?? false;
  static Future<void> setReducedMotion(bool v) =>
      _p.setBool('reduced_motion', v);

  static double get fontScale => _p.getDouble('font_scale') ?? 1.0;
  static Future<void> setFontScale(double v) => _p.setDouble('font_scale', v);

  static bool get soundEnabled => _p.getBool('sound_enabled') ?? true;
  static Future<void> setSoundEnabled(bool v) =>
      _p.setBool('sound_enabled', v);

  /// Triggers haptic feedback safely according to sound & haptic settings.
  static Future<void> triggerHaptic(
      [AppHapticType type = AppHapticType.light]) async {
    if (!soundEnabled) return;
    try {
      switch (type) {
        case AppHapticType.light:
          await HapticFeedback.lightImpact();
          break;
        case AppHapticType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case AppHapticType.selection:
          await HapticFeedback.selectionClick();
          break;
      }
    } catch (_) {
      // Graceful fallback on devices/platforms without haptics
    }
  }

  // ─── Auth Cache ────────────────────────────────────
  static String? get cachedEmail => _p.getString('cached_email');
  static Future<void> setCachedEmail(String? v) =>
      v == null ? _p.remove('cached_email') : _p.setString('cached_email', v);
}
