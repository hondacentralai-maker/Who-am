import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../models/couples_profile.dart';
import '../models/decision_wheel_item.dart';
import '../models/love_note.dart';

/// Haptic feedback intensity options.
enum AppHapticType { light, medium, heavy, selection }

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

  static Future<void> recordJackarooWin({int pointsEarned = 100}) async {
    await recordGamePlay();
    final current = getStats();
    final updated = current.copyWith(
      gamesPlayed: current.gamesPlayed + 1,
      totalPoints: current.totalPoints + pointsEarned,
      jackarooWins: current.jackarooWins + 1,
      currentStreak: streakDays,
      highestStreak:
          streakDays > current.highestStreak ? streakDays : current.highestStreak,
    );
    await saveStats(updated);

    await unlockAchievement('first_game');
    await unlockAchievement('jackaroo_first_win');
    if (updated.jackarooWins >= 3) {
      await unlockAchievement('jackaroo_master');
    }
    if (streakDays >= 3) await unlockAchievement('streak_3');
    if (streakDays >= 7) await unlockAchievement('streak_7');
  }

  static Future<void> recordJackarooMatchPlayed() async {
    await recordGamePlay();
    final current = getStats();
    final updated = current.copyWith(
      gamesPlayed: current.gamesPlayed + 1,
      totalPoints: current.totalPoints + 20, // مكافأة مشاركة وجولة تكتيكية
      currentStreak: streakDays,
      highestStreak:
          streakDays > current.highestStreak ? streakDays : current.highestStreak,
    );
    await saveStats(updated);
    await unlockAchievement('first_game');
    if (streakDays >= 3) await unlockAchievement('streak_3');
  }

  static Future<void> recordWheelSpin({int pointsEarned = 10}) async {
    await recordGamePlay();
    final current = getStats();
    final updated = current.copyWith(
      gamesPlayed: current.gamesPlayed + 1,
      totalPoints: current.totalPoints + pointsEarned,
      wheelSpins: current.wheelSpins + 1,
      currentStreak: streakDays,
      highestStreak:
          streakDays > current.highestStreak ? streakDays : current.highestStreak,
    );
    await saveStats(updated);
    await unlockAchievement('first_game');
    await unlockAchievement('wheel_spinner');
    if (streakDays >= 3) await unlockAchievement('streak_3');
  }

  static Future<void> recordPartyGameFinished({int pointsEarned = 10}) async {
    await recordGamePlay();
    final current = getStats();
    final updated = current.copyWith(
      gamesPlayed: current.gamesPlayed + 1,
      totalPoints: current.totalPoints + pointsEarned,
      partyGamesPlayed: current.partyGamesPlayed + 1,
      currentStreak: streakDays,
      highestStreak:
          streakDays > current.highestStreak ? streakDays : current.highestStreak,
    );
    await saveStats(updated);
    await unlockAchievement('first_game');
    if (updated.partyGamesPlayed >= 3) {
      await unlockAchievement('party_star');
    }
    if (streakDays >= 3) await unlockAchievement('streak_3');
  }

  static Future<void> recordPartyGamePlayed([String? gameId]) =>
      recordPartyGameFinished();

  // ─── Memory Match Best Scores ────────────────────────
  static int getMemoryBestMoves(String themeKey) {
    try {
      return _p.getInt('memory_best_moves_$themeKey') ?? 999;
    } catch (_) {
      return 999;
    }
  }

  static Future<bool> saveMemoryBestMoves(String themeKey, int moves) async {
    try {
      final prev = getMemoryBestMoves(themeKey);
      if (moves < prev) {
        await _p.setInt('memory_best_moves_$themeKey', moves);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ─── Wordle Stats ─────────────────────────────────────
  static int getWordlePlayed() {
    try {
      return _p.getInt('wordle_played') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static int getWordleWins() {
    try {
      return _p.getInt('wordle_wins') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static int getWordleCurrentStreak() {
    try {
      return _p.getInt('wordle_current_streak') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static int getWordleMaxStreak() {
    try {
      return _p.getInt('wordle_max_streak') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static int getWordleGuessCount(int attempt) {
    try {
      return _p.getInt('wordle_guess_$attempt') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> recordWordleResult({required bool won, required int attempts}) async {
    try {
      final played = getWordlePlayed() + 1;
      await _p.setInt('wordle_played', played);
      if (won) {
        final wins = getWordleWins() + 1;
        final streak = getWordleCurrentStreak() + 1;
        final maxStreak = streak > getWordleMaxStreak() ? streak : getWordleMaxStreak();
        await _p.setInt('wordle_wins', wins);
        await _p.setInt('wordle_current_streak', streak);
        await _p.setInt('wordle_max_streak', maxStreak);
        final count = getWordleGuessCount(attempts) + 1;
        await _p.setInt('wordle_guess_$attempts', count);
      } else {
        await _p.setInt('wordle_current_streak', 0);
      }
    } catch (_) {}
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
          id: 'jackaroo_first_win',
          title: 'بطل السهرة 👑',
          description: 'فزتم بأول جولة في ألعاب الجلسات والتجمعات',
          emoji: '🎉',
          points: 50,
        ),
        const Achievement(
          id: 'jackaroo_master',
          title: 'داهية التكتيك 🎯',
          description: 'حقتتم 3 انتصارات حماسية في ألعاب التجمعات',
          emoji: '🏆',
          points: 100,
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
        const Achievement(
          id: 'party_star',
          title: 'نجمة الجلسات 🥳',
          description: 'شاركت في 3 جولات ضمن ألعاب الجلسات والتجمعات',
          emoji: '🎉',
          points: 35,
        ),
        const Achievement(
          id: 'love_capsule',
          title: 'صندوق الذكريات 💌',
          description: 'كتبت وحفظت رسالة أو كبسولة زمنية مؤجلة',
          emoji: '🎁',
          points: 25,
        ),
        const Achievement(
          id: 'wheel_spinner',
          title: 'حاسمة القرارات 🎡',
          description: 'دوّرت عجلة القرارات العفوية وحسمت الاختيار',
          emoji: '🎡',
          points: 20,
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

  // ─── Last Played Game & Quick Resume ───────────────
  static String? get lastPlayedGameTitle => _p.getString('last_played_game_title');
  static String? get lastPlayedGameRoute => _p.getString('last_played_game_route');

  static Future<void> setLastPlayedGame({required String title, required String route}) async {
    await _p.setString('last_played_game_title', title);
    await _p.setString('last_played_game_route', route);
  }

  // ─── Settings ──────────────────────────────────────
  static bool get isDarkMode => _p.getBool('dark_mode') ?? false;
  static Future<void> setDarkMode(bool v) => _p.setBool('dark_mode', v);

  static bool get reducedMotion => _p.getBool('reduced_motion') ?? false;
  static set reducedMotion(bool v) => _p.setBool('reduced_motion', v);
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
        case AppHapticType.heavy:
          await HapticFeedback.heavyImpact();
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

  // ─── Couples Profile & Days Together ───────────────
  static const _profileKey = 'couples_profile_v1';

  static CouplesProfile getCouplesProfile() {
    final raw = _p.getString(_profileKey);
    if (raw == null) {
      final defaultProfile = CouplesProfile(
        partner1Name: 'أنا',
        partner2Name: 'شريكي',
        startDate: DateTime(DateTime.now().year, 1, 1),
        specialTitle: 'ذكرى ارتباطنا',
        partnerCode: 'LOVE-${(1000 + DateTime.now().millisecondsSinceEpoch % 9000)}',
      );
      saveCouplesProfile(defaultProfile);
      return defaultProfile;
    }
    try {
      return CouplesProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return CouplesProfile(
        partner1Name: 'أنا',
        partner2Name: 'شريكي',
        startDate: DateTime(DateTime.now().year, 1, 1),
        specialTitle: 'ذكرى ارتباطنا',
        partnerCode: 'LOVE-7777',
      );
    }
  }

  static Future<void> saveCouplesProfile(CouplesProfile profile) =>
      _p.setString(_profileKey, jsonEncode(profile.toJson()));

  static Future<void> linkPartner({
    required String partnerEmail,
    String? partnerName,
    String? partnerId,
  }) async {
    final current = getCouplesProfile();
    final updated = current.copyWith(
      linkedPartnerEmail: partnerEmail,
      linkedPartnerId: partnerId,
      partner2Name: (partnerName != null && partnerName.isNotEmpty)
          ? partnerName
          : current.partner2Name,
    );
    await saveCouplesProfile(updated);
  }

  static Future<void> unlinkPartner() async {
    final current = getCouplesProfile();
    final updated = current.copyWith(clearLinkedPartner: true);
    await saveCouplesProfile(updated);
  }

  // ─── Love Notes & Time Capsules ────────────────────
  static const _notesKey = 'couples_love_notes_v1';

  static List<LoveNote> getLoveNotes() {
    final raw = _p.getString(_notesKey);
    if (raw == null) return _defaultLoveNotes();
    try {
      final list = (jsonDecode(raw) as List)
          .map((m) => LoveNote.fromJson(m as Map<String, dynamic>))
          .toList();
      return list.isEmpty ? _defaultLoveNotes() : list;
    } catch (_) {
      return _defaultLoveNotes();
    }
  }

  static List<LoveNote> _defaultLoveNotes() {
    return [
      LoveNote(
        id: 'default_note_1',
        authorName: 'فريق سوالفنا 💜',
        title: 'أهلاً بكما في مساحتكم الخاصة ✨',
        content:
            'هذه المساحة مخصصة لكما فقط لكتابة رسائل الحب والكبسولات الزمنية التي تُفتح في تواريخكم المميزة! جربوا كتابة أول رسالة الآن 💌',
        createdAt: DateTime.now(),
        isOpened: true,
        emoji: '🎁',
      ),
    ];
  }

  static Future<void> saveLoveNotes(List<LoveNote> notes) =>
      _p.setString(_notesKey, jsonEncode(notes.map((n) => n.toJson()).toList()));

  static Future<void> addLoveNote(LoveNote note) async {
    final list = getLoveNotes();
    list.insert(0, note);
    await saveLoveNotes(list);
    await unlockAchievement('custom_creator');
  }

  static Future<void> deleteLoveNote(String id) async {
    final list = getLoveNotes();
    list.removeWhere((n) => n.id == id);
    await saveLoveNotes(list);
  }

  static Future<void> markLoveNoteOpened(String id) async {
    final list = getLoveNotes();
    final idx = list.indexWhere((n) => n.id == id);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(isOpened: true);
      await saveLoveNotes(list);
    }
  }

  // ─── Custom Decision Wheel Items ───────────────────
  static const _wheelKey = 'couples_custom_wheel_items_v1';

  static List<DecisionWheelItem> getCustomWheelItems() {
    final raw = _p.getString(_wheelKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((m) => DecisionWheelItem.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomWheelItems(List<DecisionWheelItem> items) =>
      _p.setString(_wheelKey, jsonEncode(items.map((i) => i.toJson()).toList()));

  static Future<void> addCustomWheelItem(DecisionWheelItem item) async {
    final list = getCustomWheelItems();
    list.add(item);
    await saveCustomWheelItems(list);
  }
}
