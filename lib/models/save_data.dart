import 'booster.dart';
import 'game_stats.dart';

class SaveData {
  static const currentVersion = 9;

  int version;
  double gold;
  double totalGoldEarned;
  Map<String, int> producerLevels;
  Map<String, int> tapUpgradeLevels;
  int prestigeSouls;
  int prestigeCount;
  int prestigeCoins;
  Map<String, int> prestigeUpgradeLevels;
  DateTime lastSavedAt;
  GameStats stats;
  GameSettings settings;

  // Sword collection (v3)
  int essence;
  Map<String, int> ownedSwords; // id → level (1~10)
  String? equippedSwordId;
  int summonsSinceHighRare; // pity counter (reset on SR+)

  // Achievements (v4)
  Set<String> unlockedAchievements;

  // Daily login bonus (v5)
  DateTime? lastDailyClaimAt;
  int dailyStreak;

  // Time-limited boosters (v6)
  List<Booster> activeBoosters;

  // Deterministic golden-slime spawn counter (v7).
  int tapsSinceSlime;

  // Skill cooldowns (v8): skill id → moment when the skill becomes usable
  // again. Skill is "ready" if missing or in the past.
  Map<String, DateTime> skillReadyAt;

  SaveData({
    this.version = currentVersion,
    this.gold = 0,
    this.totalGoldEarned = 0,
    Map<String, int>? producerLevels,
    Map<String, int>? tapUpgradeLevels,
    this.prestigeSouls = 0,
    this.prestigeCount = 0,
    this.prestigeCoins = 0,
    Map<String, int>? prestigeUpgradeLevels,
    DateTime? lastSavedAt,
    GameStats? stats,
    GameSettings? settings,
    this.essence = 90,
    Map<String, int>? ownedSwords,
    this.equippedSwordId,
    this.summonsSinceHighRare = 0,
    Set<String>? unlockedAchievements,
    this.lastDailyClaimAt,
    this.dailyStreak = 0,
    List<Booster>? activeBoosters,
    this.tapsSinceSlime = 0,
    Map<String, DateTime>? skillReadyAt,
  })  : producerLevels = producerLevels ?? {},
        tapUpgradeLevels = tapUpgradeLevels ?? {},
        prestigeUpgradeLevels = prestigeUpgradeLevels ?? {},
        lastSavedAt = lastSavedAt ?? DateTime.now(),
        stats = stats ?? GameStats(),
        settings = settings ?? GameSettings(),
        ownedSwords = ownedSwords ?? {},
        unlockedAchievements = unlockedAchievements ?? <String>{},
        activeBoosters = activeBoosters ?? <Booster>[],
        skillReadyAt = skillReadyAt ?? <String, DateTime>{};

  Map<String, dynamic> toJson() => {
        'version': version,
        'gold': gold,
        'totalGoldEarned': totalGoldEarned,
        'producerLevels': producerLevels,
        'tapUpgradeLevels': tapUpgradeLevels,
        'prestigeSouls': prestigeSouls,
        'prestigeCount': prestigeCount,
        'prestigeCoins': prestigeCoins,
        'prestigeUpgradeLevels': prestigeUpgradeLevels,
        'lastSavedAt': lastSavedAt.toIso8601String(),
        'stats': stats.toJson(),
        'settings': settings.toJson(),
        'essence': essence,
        'ownedSwords': ownedSwords,
        'equippedSwordId': equippedSwordId,
        'summonsSinceHighRare': summonsSinceHighRare,
        'unlockedAchievements': unlockedAchievements.toList(),
        'lastDailyClaimAt': lastDailyClaimAt?.toIso8601String(),
        'dailyStreak': dailyStreak,
        'activeBoosters': activeBoosters.map((b) => b.toJson()).toList(),
        'tapsSinceSlime': tapsSinceSlime,
        'skillReadyAt':
            skillReadyAt.map((k, v) => MapEntry(k, v.toIso8601String())),
      };

  factory SaveData.fromJson(Map<String, dynamic> json) => SaveData(
        version: json['version'] as int? ?? currentVersion,
        gold: (json['gold'] as num?)?.toDouble() ?? 0,
        totalGoldEarned: (json['totalGoldEarned'] as num?)?.toDouble() ?? 0,
        producerLevels:
            Map<String, int>.from(json['producerLevels'] as Map? ?? {}),
        tapUpgradeLevels:
            Map<String, int>.from(json['tapUpgradeLevels'] as Map? ?? {}),
        prestigeSouls: json['prestigeSouls'] as int? ?? 0,
        prestigeCount: json['prestigeCount'] as int? ?? 0,
        prestigeCoins: json['prestigeCoins'] as int? ?? 0,
        prestigeUpgradeLevels:
            Map<String, int>.from(json['prestigeUpgradeLevels'] as Map? ?? {}),
        lastSavedAt: DateTime.tryParse(json['lastSavedAt'] as String? ?? '') ??
            DateTime.now(),
        stats: GameStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
        settings: GameSettings.fromJson(
            json['settings'] as Map<String, dynamic>? ?? {}),
        essence: json['essence'] as int? ?? 90,
        ownedSwords: Map<String, int>.from(json['ownedSwords'] as Map? ?? {}),
        equippedSwordId: json['equippedSwordId'] as String?,
        summonsSinceHighRare: json['summonsSinceHighRare'] as int? ?? 0,
        unlockedAchievements: (json['unlockedAchievements'] as List?)
                ?.map((e) => e as String)
                .toSet() ??
            <String>{},
        lastDailyClaimAt:
            DateTime.tryParse(json['lastDailyClaimAt'] as String? ?? ''),
        dailyStreak: json['dailyStreak'] as int? ?? 0,
        activeBoosters: (json['activeBoosters'] as List?)
                ?.map((e) =>
                    Booster.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            <Booster>[],
        tapsSinceSlime: json['tapsSinceSlime'] as int? ?? 0,
        skillReadyAt: ((json['skillReadyAt'] as Map?) ?? {}).map(
          (k, v) => MapEntry(
            k as String,
            DateTime.tryParse(v as String? ?? '') ?? DateTime.now(),
          ),
        ),
      );
}
