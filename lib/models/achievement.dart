class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int points;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.points,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) =>
      Achievement(
        id: id,
        title: title,
        description: description,
        emoji: emoji,
        points: points,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );

  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        emoji: j['emoji'] ?? '🏆',
        points: j['points'] ?? 10,
        isUnlocked: j['is_unlocked'] ?? false,
        unlockedAt: j['unlocked_at'] != null
            ? DateTime.tryParse(j['unlocked_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'emoji': emoji,
        'points': points,
        'is_unlocked': isUnlocked,
        'unlocked_at': unlockedAt?.toIso8601String(),
      };
}

class GameStats {
  final int totalPoints;
  final int gamesPlayed;
  final int correctGuesses;
  final int cardsExplored;
  final int knowMeAnswered;
  final int jackarooWins;
  final int currentStreak;
  final int highestStreak;
  final int wheelSpins;
  final int partyGamesPlayed;

  const GameStats({
    this.totalPoints = 0,
    this.gamesPlayed = 0,
    this.correctGuesses = 0,
    this.cardsExplored = 0,
    this.knowMeAnswered = 0,
    this.jackarooWins = 0,
    this.currentStreak = 1,
    this.highestStreak = 1,
    this.wheelSpins = 0,
    this.partyGamesPlayed = 0,
  });

  int get level => (totalPoints ~/ 50) + 1;

  factory GameStats.fromJson(Map<String, dynamic> j) => GameStats(
        totalPoints: j['total_points'] ?? 0,
        gamesPlayed: j['games_played'] ?? 0,
        correctGuesses: j['correct_guesses'] ?? 0,
        cardsExplored: j['cards_explored'] ?? 0,
        knowMeAnswered: j['know_me_answered'] ?? 0,
        jackarooWins: j['jackaroo_wins'] ?? 0,
        currentStreak: j['current_streak'] ?? 1,
        highestStreak: j['highest_streak'] ?? 1,
        wheelSpins: j['wheel_spins'] ?? 0,
        partyGamesPlayed: j['party_games_played'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'total_points': totalPoints,
        'games_played': gamesPlayed,
        'correct_guesses': correctGuesses,
        'cards_explored': cardsExplored,
        'know_me_answered': knowMeAnswered,
        'jackaroo_wins': jackarooWins,
        'current_streak': currentStreak,
        'highest_streak': highestStreak,
        'wheel_spins': wheelSpins,
        'party_games_played': partyGamesPlayed,
      };

  GameStats copyWith({
    int? totalPoints,
    int? gamesPlayed,
    int? correctGuesses,
    int? cardsExplored,
    int? knowMeAnswered,
    int? jackarooWins,
    int? currentStreak,
    int? highestStreak,
    int? wheelSpins,
    int? partyGamesPlayed,
  }) =>
      GameStats(
        totalPoints: totalPoints ?? this.totalPoints,
        gamesPlayed: gamesPlayed ?? this.gamesPlayed,
        correctGuesses: correctGuesses ?? this.correctGuesses,
        cardsExplored: cardsExplored ?? this.cardsExplored,
        knowMeAnswered: knowMeAnswered ?? this.knowMeAnswered,
        jackarooWins: jackarooWins ?? this.jackarooWins,
        currentStreak: currentStreak ?? this.currentStreak,
        highestStreak: highestStreak ?? this.highestStreak,
        wheelSpins: wheelSpins ?? this.wheelSpins,
        partyGamesPlayed: partyGamesPlayed ?? this.partyGamesPlayed,
      );
}
