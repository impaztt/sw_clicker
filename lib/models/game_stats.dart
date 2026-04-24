class GameStats {
  int totalTaps;
  int playTimeSeconds;
  double maxDpsEver;
  double lifetimeGold;
  int totalSummons;
  int totalTapUpgradesBought;
  int totalCrits;
  int maxCombo;

  GameStats({
    this.totalTaps = 0,
    this.playTimeSeconds = 0,
    this.maxDpsEver = 0,
    this.lifetimeGold = 0,
    this.totalSummons = 0,
    this.totalTapUpgradesBought = 0,
    this.totalCrits = 0,
    this.maxCombo = 0,
  });

  Map<String, dynamic> toJson() => {
        'totalTaps': totalTaps,
        'playTimeSeconds': playTimeSeconds,
        'maxDpsEver': maxDpsEver,
        'lifetimeGold': lifetimeGold,
        'totalSummons': totalSummons,
        'totalTapUpgradesBought': totalTapUpgradesBought,
        'totalCrits': totalCrits,
        'maxCombo': maxCombo,
      };

  factory GameStats.fromJson(Map<String, dynamic> json) => GameStats(
        totalTaps: json['totalTaps'] as int? ?? 0,
        playTimeSeconds: json['playTimeSeconds'] as int? ?? 0,
        maxDpsEver: (json['maxDpsEver'] as num?)?.toDouble() ?? 0,
        lifetimeGold: (json['lifetimeGold'] as num?)?.toDouble() ?? 0,
        totalSummons: json['totalSummons'] as int? ?? 0,
        totalTapUpgradesBought: json['totalTapUpgradesBought'] as int? ?? 0,
        totalCrits: json['totalCrits'] as int? ?? 0,
        maxCombo: json['maxCombo'] as int? ?? 0,
      );
}

class GameSettings {
  bool haptic;
  bool sound;
  bool darkMode;

  GameSettings({
    this.haptic = true,
    this.sound = true,
    this.darkMode = false,
  });

  Map<String, dynamic> toJson() => {
        'haptic': haptic,
        'sound': sound,
        'darkMode': darkMode,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        haptic: json['haptic'] as bool? ?? true,
        sound: json['sound'] as bool? ?? true,
        darkMode: json['darkMode'] as bool? ?? false,
      );
}
