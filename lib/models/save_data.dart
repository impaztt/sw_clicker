import 'booster.dart';
import 'game_stats.dart';
import 'run_stats.dart';
import 'stock_market.dart';

class SaveData {
  static const currentVersion = 13;

  int version;
  double gold;
  double totalGoldEarned;
  Map<String, int> producerLevels;
  Map<String, int> tapUpgradeLevels;
  int prestigeSouls;
  int prestigeCount;
  int prestigeCoins;
  Map<String, int> prestigeUpgradeLevels;
  int ascensionCoreLevel;
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

  // Mission progress (v10)
  int dailyMissionDayKey;
  int weeklyMissionWeekKey;
  Map<String, int> dailyMissionProgress;
  Set<String> dailyMissionClaimed;
  Map<String, int> weeklyMissionProgress;
  Set<String> weeklyMissionClaimed;

  // Progressive feature unlocks (v11)
  Set<String> unlockedFeatures;

  // Regional stock market (v12)
  StockMarketState market;

  // Repeating-achievement progress (v13). Map id -> cleared stage count.
  Map<String, int> repeatingAchievementStages;

  // Per-prestige run-scoped stats (v13). Reset on prestige().
  RunStats run;

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
    this.ascensionCoreLevel = 0,
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
    this.dailyMissionDayKey = 0,
    this.weeklyMissionWeekKey = 0,
    Map<String, int>? dailyMissionProgress,
    Set<String>? dailyMissionClaimed,
    Map<String, int>? weeklyMissionProgress,
    Set<String>? weeklyMissionClaimed,
    Set<String>? unlockedFeatures,
    StockMarketState? market,
    Map<String, int>? repeatingAchievementStages,
    RunStats? run,
  })  : producerLevels = producerLevels ?? {},
        tapUpgradeLevels = tapUpgradeLevels ?? {},
        prestigeUpgradeLevels = prestigeUpgradeLevels ?? {},
        lastSavedAt = lastSavedAt ?? DateTime.now(),
        stats = stats ?? GameStats(),
        settings = settings ?? GameSettings(),
        ownedSwords = ownedSwords ?? {},
        unlockedAchievements = unlockedAchievements ?? <String>{},
        activeBoosters = activeBoosters ?? <Booster>[],
        skillReadyAt = skillReadyAt ?? <String, DateTime>{},
        dailyMissionProgress = dailyMissionProgress ?? <String, int>{},
        dailyMissionClaimed = dailyMissionClaimed ?? <String>{},
        weeklyMissionProgress = weeklyMissionProgress ?? <String, int>{},
        weeklyMissionClaimed = weeklyMissionClaimed ?? <String>{},
        unlockedFeatures = unlockedFeatures ?? <String>{},
        market = market ?? StockMarketState(),
        repeatingAchievementStages =
            repeatingAchievementStages ?? <String, int>{},
        run = run ?? RunStats();

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
        'ascensionCoreLevel': ascensionCoreLevel,
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
        'dailyMissionDayKey': dailyMissionDayKey,
        'weeklyMissionWeekKey': weeklyMissionWeekKey,
        'dailyMissionProgress': dailyMissionProgress,
        'dailyMissionClaimed': dailyMissionClaimed.toList(),
        'weeklyMissionProgress': weeklyMissionProgress,
        'weeklyMissionClaimed': weeklyMissionClaimed.toList(),
        'unlockedFeatures': unlockedFeatures.toList(),
        'market': market.toJson(),
        'repeatingAchievementStages': repeatingAchievementStages,
        'run': run.toJson(),
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
        ascensionCoreLevel: json['ascensionCoreLevel'] as int? ?? 0,
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
        dailyMissionDayKey: json['dailyMissionDayKey'] as int? ?? 0,
        weeklyMissionWeekKey: json['weeklyMissionWeekKey'] as int? ?? 0,
        dailyMissionProgress:
            Map<String, int>.from(json['dailyMissionProgress'] as Map? ?? {}),
        dailyMissionClaimed: (json['dailyMissionClaimed'] as List?)
                ?.map((e) => e as String)
                .toSet() ??
            <String>{},
        weeklyMissionProgress:
            Map<String, int>.from(json['weeklyMissionProgress'] as Map? ?? {}),
        weeklyMissionClaimed: (json['weeklyMissionClaimed'] as List?)
                ?.map((e) => e as String)
                .toSet() ??
            <String>{},
        unlockedFeatures: (json['unlockedFeatures'] as List?)
                ?.map((e) => e as String)
                .toSet() ??
            <String>{},
        market: json['market'] == null
            ? StockMarketState()
            : StockMarketState.fromJson(
                Map<String, dynamic>.from(json['market'] as Map)),
        repeatingAchievementStages: Map<String, int>.from(
            json['repeatingAchievementStages'] as Map? ?? const {}),
        run: json['run'] == null
            ? RunStats()
            : RunStats.fromJson(Map<String, dynamic>.from(json['run'] as Map)),
      );
}
