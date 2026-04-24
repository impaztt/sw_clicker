import 'game_stats.dart';

class SaveData {
  static const currentVersion = 2;

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
  })  : producerLevels = producerLevels ?? {},
        tapUpgradeLevels = tapUpgradeLevels ?? {},
        lastSavedAt = lastSavedAt ?? DateTime.now(),
        stats = stats ?? GameStats(),
        settings = settings ?? GameSettings();

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
      );
}
