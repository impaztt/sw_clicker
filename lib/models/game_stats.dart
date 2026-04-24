class GameStats {
  int totalTaps;
  int playTimeSeconds;
  double maxDpsEver;
  double lifetimeGold;

  GameStats({
    this.totalTaps = 0,
    this.playTimeSeconds = 0,
    this.maxDpsEver = 0,
    this.lifetimeGold = 0,
  });

  Map<String, dynamic> toJson() => {
        'totalTaps': totalTaps,
        'playTimeSeconds': playTimeSeconds,
        'maxDpsEver': maxDpsEver,
        'lifetimeGold': lifetimeGold,
      };

  factory GameStats.fromJson(Map<String, dynamic> json) => GameStats(
        totalTaps: json['totalTaps'] as int? ?? 0,
        playTimeSeconds: json['playTimeSeconds'] as int? ?? 0,
        maxDpsEver: (json['maxDpsEver'] as num?)?.toDouble() ?? 0,
        lifetimeGold: (json['lifetimeGold'] as num?)?.toDouble() ?? 0,
      );
}

class GameSettings {
  bool haptic;

  GameSettings({this.haptic = true});

  Map<String, dynamic> toJson() => {'haptic': haptic};

  factory GameSettings.fromJson(Map<String, dynamic> json) =>
      GameSettings(haptic: json['haptic'] as bool? ?? true);
}
