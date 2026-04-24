import 'game_stats.dart';

class SaveData {
  static const currentVersion = 4;

  int version;
  double gold;
  double totalGoldEarned;
  Map<String, int> producerLevels;
  Map<String, int> tapUpgradeLevels;
  int prestigeSouls;
  int prestigeCount;
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

  SaveData({
    this.version = currentVersion,
    this.gold = 0,
    this.totalGoldEarned = 0,
    Map<String, int>? producerLevels,
    Map<String, int>? tapUpgradeLevels,
    this.prestigeSouls = 0,
    this.prestigeCount = 0,
    DateTime? lastSavedAt,
    GameStats? stats,
    GameSettings? settings,
    this.essence = 90,
    Map<String, int>? ownedSwords,
    this.equippedSwordId,
    this.summonsSinceHighRare = 0,
    Set<String>? unlockedAchievements,
  })  : producerLevels = producerLevels ?? {},
        tapUpgradeLevels = tapUpgradeLevels ?? {},
        lastSavedAt = lastSavedAt ?? DateTime.now(),
        stats = stats ?? GameStats(),
        settings = settings ?? GameSettings(),
        ownedSwords = ownedSwords ?? {},
        unlockedAchievements = unlockedAchievements ?? <String>{};

  Map<String, dynamic> toJson() => {
        'version': version,
        'gold': gold,
        'totalGoldEarned': totalGoldEarned,
        'producerLevels': producerLevels,
        'tapUpgradeLevels': tapUpgradeLevels,
        'prestigeSouls': prestigeSouls,
        'prestigeCount': prestigeCount,
        'lastSavedAt': lastSavedAt.toIso8601String(),
        'stats': stats.toJson(),
        'settings': settings.toJson(),
        'essence': essence,
        'ownedSwords': ownedSwords,
        'equippedSwordId': equippedSwordId,
        'summonsSinceHighRare': summonsSinceHighRare,
        'unlockedAchievements': unlockedAchievements.toList(),
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
        lastSavedAt:
            DateTime.tryParse(json['lastSavedAt'] as String? ?? '') ??
                DateTime.now(),
        stats:
            GameStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
        settings: GameSettings.fromJson(
            json['settings'] as Map<String, dynamic>? ?? {}),
        essence: json['essence'] as int? ?? 90,
        ownedSwords:
            Map<String, int>.from(json['ownedSwords'] as Map? ?? {}),
        equippedSwordId: json['equippedSwordId'] as String?,
        summonsSinceHighRare: json['summonsSinceHighRare'] as int? ?? 0,
        unlockedAchievements: (json['unlockedAchievements'] as List?)
                ?.map((e) => e as String)
                .toSet() ??
            <String>{},
      );
}
