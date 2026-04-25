import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/achievement_catalog.dart';
import '../data/producer_catalog.dart';
import '../data/sword_catalog.dart';
import '../data/skill_catalog.dart';
import '../data/sword_sets.dart';
import '../data/tap_upgrade_catalog.dart';
import '../models/achievement.dart';
import '../models/booster.dart';
import '../models/save_data.dart';
import '../models/skill.dart';
import '../models/sword.dart';
import '../services/sync_service.dart';

/// Buy count: 1, 10, 100 or -1 for Max.
final buyMultiplierProvider = StateProvider<int>((_) => 1);

/// Cost in 정수 per single summon.
const summonCostSingle = 30;
const summonCostTen = 270;

/// After this many consecutive non-SR+ pulls, the next pull is guaranteed SR+.
const pityThreshold = 80;

/// Idle earnings config.
const offlineMaxHours = 12;
const offlineMaxSeconds = offlineMaxHours * 3600;

/// Minimum away-time (seconds) before the "welcome back" dialog shows.
/// Short enough to verify the feature quickly, long enough to skip tab-switch
/// round-trips.
const offlineMinSeconds = 30;

/// Crit + combo config.
const critChance = 0.05; // 5%
const critMultiplier = 10.0;
const comboWindowMs = 1500; // taps within this many ms extend the combo
const comboMax = 50;
const comboBonusPerStack = 0.01; // +1% tap per combo stack, cap +50%

/// Daily login reward table: streak day (1-indexed) → essence reward.
/// Streak resets when the user skips a day (>48h since last claim).
const dailyRewards = <int>[0, 5, 10, 15, 20, 30, 40, 60];
int dailyRewardFor(int streak) {
  if (streak < 1) return dailyRewards[1];
  if (streak >= dailyRewards.length) return dailyRewards.last;
  return dailyRewards[streak];
}

/// Booster shop catalog. (`adOnly`=true means essence cost is N/A; only
/// purchasable via the ad stub.)
class BoosterOffer {
  final String id;
  final String title;
  final String subtitle;
  final BoosterType type;
  final double multiplier;
  final int durationSec;
  final int essenceCost; // 0 → ad-only
  const BoosterOffer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.multiplier,
    required this.durationSec,
    required this.essenceCost,
  });
}

const boosterOffers = <BoosterOffer>[
  BoosterOffer(
    id: 'dps_2x_30m',
    title: '자동 수익 x2 · 30분',
    subtitle: '동료들의 DPS가 두 배가 돼요',
    type: BoosterType.dps,
    multiplier: 2.0,
    durationSec: 1800,
    essenceCost: 50,
  ),
  BoosterOffer(
    id: 'tap_2x_15m',
    title: '터치 x2 · 15분',
    subtitle: '탭당 획득 골드 두 배',
    type: BoosterType.tap,
    multiplier: 2.0,
    durationSec: 900,
    essenceCost: 30,
  ),
  BoosterOffer(
    id: 'rush_3x_5m',
    title: '골드러시 x3 · 5분',
    subtitle: 'DPS + 터치 모두 3배',
    type: BoosterType.rush,
    multiplier: 3.0,
    durationSec: 300,
    essenceCost: 100,
  ),
];

/// Slime config — guaranteed spawn every N taps so the player can
/// predict it. Counter persists in SaveData.tapsSinceSlime.
const slimeSpawnEvery = 250;
const slimeLifetimeMs = 7000;
/// HP the slime takes to defeat — each tap on the slime deals 1 damage.
const slimeMaxHp = 10;
/// Reward when the slime is killed: gold = tapPower × this many taps.
const slimeRewardTaps = 5000;

/// Auto-tap config: when an autoTap booster is active, fire a tap every
/// [autoTapIntervalMs] milliseconds. ~4 taps/sec is comfortable: visible
/// progress without trashing the framerate.
const autoTapIntervalMs = 250;

/// Combo burst: triggered the first time combo reaches comboMax during a
/// single combo streak. Reward = current DPS × this many seconds.
const comboBurstWorthSeconds = 60;

/// Combo surge skill: extra combo stacks per tap and bonus multiplier
/// applied while the surge window is active.
const comboSurgePerTap = 2;
const comboSurgeBonus = 2.0; // tap reward × this while surging

/// Slash burst skill: instant gold equal to current DPS × this seconds.
const slashBurstWorthSeconds = 300;
const essenceGatherAmount = 30;

/// Stream of newly unlocked achievements (for toast UI).
final achievementUnlockProvider = StreamProvider<AchievementDef>(
  (ref) => ref.watch(gameProvider.notifier)._achievementUnlocks.stream,
);

class SummonResult {
  final SwordDef sword;
  final int levelAfter;
  final bool isDuplicate;
  final bool isMaxed;
  SummonResult({
    required this.sword,
    required this.levelAfter,
    required this.isDuplicate,
    required this.isMaxed,
  });
}

class TapResult {
  final double amount;
  final bool isCrit;
  final int combo;
  final bool slimeSpawned;
  final bool isBurst;
  final double burstAmount;
  const TapResult({
    required this.amount,
    required this.isCrit,
    required this.combo,
    this.slimeSpawned = false,
    this.isBurst = false,
    this.burstAmount = 0,
  });
}

class SkillResult {
  final SkillId id;
  final bool ok;
  final String message;
  /// Extra payload for UI (e.g. how much gold the burst granted).
  final double payload;
  const SkillResult({
    required this.id,
    required this.ok,
    required this.message,
    this.payload = 0,
  });
}

class DailyBonus {
  final int streak;
  final int essence;
  const DailyBonus({required this.streak, required this.essence});
}

class GameState {
  final double gold;
  final double totalGoldEarned;
  final double tapPower;
  final double dps;
  final int prestigeSouls;
  final int prestigeCount;
  final Map<String, int> producerLevels;
  final Map<String, int> tapUpgradeLevels;
  final int totalTaps;
  final int playTimeSeconds;
  final double maxDpsEver;
  final double lifetimeGold;
  final int totalSummons;
  final int totalTapUpgradesBought;
  final bool haptic;
  final bool sound;
  final bool darkMode;
  final int essence;
  final Map<String, int> ownedSwords;
  final String? equippedSwordId;
  final int summonsSinceHighRare;
  final Set<String> unlockedAchievements;
  final int combo;
  final int totalCrits;
  final int maxCombo;
  final int comboBurstCount;
  final int dailyStreak;
  final int maxDailyStreak;
  final DateTime? lastDailyClaimAt;
  final List<Booster> activeBoosters;
  final int tapsUntilSlime;
  final bool autoTapping;
  final bool tutorialSeen;
  final Map<String, DateTime> skillReadyAt;
  final Set<String> completedSetIds;
  final int slimesDefeated;
  final int skillsUsed;
  final int boostersPurchased;
  final bool loaded;

  const GameState({
    required this.gold,
    required this.totalGoldEarned,
    required this.tapPower,
    required this.dps,
    required this.prestigeSouls,
    required this.prestigeCount,
    required this.producerLevels,
    required this.tapUpgradeLevels,
    required this.totalTaps,
    required this.playTimeSeconds,
    required this.maxDpsEver,
    required this.lifetimeGold,
    required this.totalSummons,
    required this.totalTapUpgradesBought,
    required this.haptic,
    required this.sound,
    required this.darkMode,
    required this.essence,
    required this.ownedSwords,
    required this.equippedSwordId,
    required this.summonsSinceHighRare,
    required this.unlockedAchievements,
    required this.combo,
    required this.totalCrits,
    required this.maxCombo,
    required this.comboBurstCount,
    required this.dailyStreak,
    required this.maxDailyStreak,
    required this.lastDailyClaimAt,
    required this.activeBoosters,
    required this.tapsUntilSlime,
    required this.autoTapping,
    required this.tutorialSeen,
    required this.skillReadyAt,
    required this.completedSetIds,
    required this.slimesDefeated,
    required this.skillsUsed,
    required this.boostersPurchased,
    this.loaded = false,
  });

  factory GameState.empty() => const GameState(
        gold: 0,
        totalGoldEarned: 0,
        tapPower: 1,
        dps: 0,
        prestigeSouls: 0,
        prestigeCount: 0,
        producerLevels: {},
        tapUpgradeLevels: {},
        totalTaps: 0,
        playTimeSeconds: 0,
        maxDpsEver: 0,
        lifetimeGold: 0,
        totalSummons: 0,
        totalTapUpgradesBought: 0,
        haptic: true,
        sound: true,
        darkMode: false,
        essence: 90,
        ownedSwords: {},
        equippedSwordId: null,
        summonsSinceHighRare: 0,
        unlockedAchievements: {},
        combo: 0,
        totalCrits: 0,
        maxCombo: 0,
        comboBurstCount: 0,
        dailyStreak: 0,
        maxDailyStreak: 0,
        lastDailyClaimAt: null,
        activeBoosters: const [],
        tapsUntilSlime: slimeSpawnEvery,
        autoTapping: false,
        tutorialSeen: false,
        skillReadyAt: const {},
        completedSetIds: const {},
        slimesDefeated: 0,
        skillsUsed: 0,
        boostersPurchased: 0,
        loaded: false,
      );

  double get prestigeMultiplier => 1.0 + (prestigeSouls * 0.02);

  int get prestigeSoulsAvailable {
    if (totalGoldEarned < 1e9) return 0;
    return sqrt(totalGoldEarned / 1e9).floor();
  }

  int producerLevel(String id) => producerLevels[id] ?? 0;
  int tapUpgradeLevel(String id) => tapUpgradeLevels[id] ?? 0;
  int swordLevel(String id) => ownedSwords[id] ?? 0;
  bool ownsSword(String id) => (ownedSwords[id] ?? 0) > 0;

  SwordDef? get equippedSword {
    final id = equippedSwordId;
    if (id == null) return null;
    try {
      return swordById(id);
    } catch (_) {
      return null;
    }
  }

  bool canAfford(double cost) => gold >= cost;

  bool isAchievementUnlocked(String id) => unlockedAchievements.contains(id);

  /// Build an AchContext snapshot for progress computations.
  AchContext achContext() {
    int totalProducerLv = 0;
    int ownedProducers = 0;
    for (final v in producerLevels.values) {
      totalProducerLv += v;
      if (v > 0) ownedProducers++;
    }
    bool hasR = false, hasSr = false, hasSsr = false, hasLr = false, hasUr = false;
    int maxLv = 0;
    int maxedCount = 0;
    for (final entry in ownedSwords.entries) {
      if (entry.value <= 0) continue;
      try {
        final tier = swordById(entry.key).tier;
        if (tier == SwordTier.r) hasR = true;
        if (tier == SwordTier.sr) hasSr = true;
        if (tier == SwordTier.ssr) hasSsr = true;
        if (tier == SwordTier.lr) hasLr = true;
        if (tier == SwordTier.ur) hasUr = true;
      } catch (_) {}
      if (entry.value > maxLv) maxLv = entry.value;
      if (entry.value >= SwordDef.maxLevel) maxedCount++;
    }
    return AchContext(
      totalTaps: totalTaps,
      lifetimeGold: lifetimeGold,
      maxDpsEver: maxDpsEver,
      playTimeSeconds: playTimeSeconds,
      producerLevels: producerLevels,
      totalProducerLevels: totalProducerLv,
      ownedProducerCount: ownedProducers,
      totalProducerCatalogCount: producerCatalog.length,
      ownedSwords: ownedSwords,
      ownedSwordCount: ownedSwords.values.where((v) => v > 0).length,
      totalSwordCatalogCount: swordCatalog.length,
      ownsAnyR: hasR,
      ownsAnySr: hasSr,
      ownsAnySsr: hasSsr,
      ownsAnyLr: hasLr,
      ownsAnyUr: hasUr,
      maxSwordLevel: maxLv,
      maxedSwordCount: maxedCount,
      totalSummons: totalSummons,
      prestigeCount: prestigeCount,
      prestigeSouls: prestigeSouls,
      totalTapUpgradesBought: totalTapUpgradesBought,
      hasEquippedSword: equippedSwordId != null,
      totalCrits: totalCrits,
      maxCombo: maxCombo,
      comboBurstCount: comboBurstCount,
      slimesDefeated: slimesDefeated,
      skillsUsed: skillsUsed,
      boostersPurchased: boostersPurchased,
      maxDailyStreak: maxDailyStreak,
      completedSetCount: completedSetIds.length,
    );
  }
}

class OfflineReward {
  final Duration duration;
  final double gold;
  OfflineReward(this.duration, this.gold);
}

const _milestoneEssence = <int, int>{
  25: 1,
  50: 2,
  100: 5,
  200: 10,
};

int _milestoneEssenceUpTo(int level) {
  int total = 0;
  _milestoneEssence.forEach((threshold, reward) {
    if (level >= threshold) total += reward;
  });
  return total;
}

class GameNotifier extends Notifier<GameState> {
  final _syncService = SyncService();
  final _random = Random();
  final _achievementUnlocks = StreamController<AchievementDef>.broadcast();
  Timer? _tickTimer;
  Timer? _saveTimer;
  Timer? _comboDecayTimer;
  Timer? _autoTapTimer;
  DateTime _lastTick = DateTime.now();
  double _playTimeAcc = 0;
  SaveData _save = SaveData();
  OfflineReward? _pendingOffline;
  DailyBonus? _pendingDaily;
  int _combo = 0;
  DateTime? _lastTapAt;
  DateTime? _comboSurgeUntil;
  bool _burstFiredThisRun = false;

  @override
  GameState build() {
    ref.onDispose(_dispose);
    Future.microtask(_initialize);
    return GameState.empty();
  }

  void _dispose() {
    _tickTimer?.cancel();
    _saveTimer?.cancel();
    _comboDecayTimer?.cancel();
    _autoTapTimer?.cancel();
    _achievementUnlocks.close();
  }

  Future<void> _initialize() async {
    final loaded = await _syncService.loadResolved();
    if (loaded != null) {
      _save = loaded;
      final elapsed = DateTime.now().difference(loaded.lastSavedAt);
      final cappedSeconds = elapsed.inSeconds.clamp(0, offlineMaxSeconds);
      final dpsNow = _calcDps();
      if (cappedSeconds >= offlineMinSeconds && dpsNow > 0) {
        _pendingOffline = OfflineReward(
          Duration(seconds: cappedSeconds),
          dpsNow * cappedSeconds,
        );
      }
    }
    _pendingDaily = _evaluateDailyEligibility();
    _emit(loaded: true);
    _startTicker();
    _startAutoSave();
  }

  /// Decide whether the user is eligible for a daily bonus right now.
  /// Does NOT mutate state — the claim happens via [claimDailyBonus] after
  /// the user taps "수령" on the dialog, so we can reflect it in stats atomically.
  DailyBonus? _evaluateDailyEligibility() {
    final last = _save.lastDailyClaimAt;
    final now = DateTime.now();
    // First-ever claim → day 1.
    if (last == null) {
      return DailyBonus(streak: 1, essence: dailyRewardFor(1));
    }
    final hours = now.difference(last).inHours;
    if (hours < 24) return null; // already claimed today
    // 24h ≤ elapsed < 48h → streak continues.
    // Beyond 48h → streak resets to day 1.
    final nextStreak = hours < 48
        ? ((_save.dailyStreak % (dailyRewards.length - 1)) + 1)
        : 1;
    return DailyBonus(streak: nextStreak, essence: dailyRewardFor(nextStreak));
  }

  void _startTicker() {
    _lastTick = DateTime.now();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final now = DateTime.now();
      final dt = now.difference(_lastTick).inMilliseconds / 1000.0;
      _lastTick = now;
      _playTimeAcc += dt;
      if (_playTimeAcc >= 1.0) {
        final whole = _playTimeAcc.floor();
        _save.stats.playTimeSeconds += whole;
        _playTimeAcc -= whole;
      }
      final dps = _calcDps();
      if (dps > _save.stats.maxDpsEver) _save.stats.maxDpsEver = dps;
      if (dps > 0) {
        final gain = dps * dt;
        _save.gold += gain;
        _save.totalGoldEarned += gain;
        _save.stats.lifetimeGold += gain;
      }
      _emit(loaded: true);
    });
  }

  void _startAutoSave() {
    _saveTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _persist(),
    );
  }

  Future<void> _persist() async {
    await _syncService.persist(_save);
  }

  void _emit({required bool loaded}) {
    state = GameState(
      gold: _save.gold,
      totalGoldEarned: _save.totalGoldEarned,
      tapPower: _calcTapPower(),
      dps: _calcDps(),
      prestigeSouls: _save.prestigeSouls,
      prestigeCount: _save.prestigeCount,
      producerLevels: Map.unmodifiable(_save.producerLevels),
      tapUpgradeLevels: Map.unmodifiable(_save.tapUpgradeLevels),
      totalTaps: _save.stats.totalTaps,
      playTimeSeconds: _save.stats.playTimeSeconds,
      maxDpsEver: _save.stats.maxDpsEver,
      lifetimeGold: _save.stats.lifetimeGold,
      totalSummons: _save.stats.totalSummons,
      totalTapUpgradesBought: _save.stats.totalTapUpgradesBought,
      haptic: _save.settings.haptic,
      sound: _save.settings.sound,
      darkMode: _save.settings.darkMode,
      essence: _save.essence,
      ownedSwords: Map.unmodifiable(_save.ownedSwords),
      equippedSwordId: _save.equippedSwordId,
      summonsSinceHighRare: _save.summonsSinceHighRare,
      unlockedAchievements: Set.unmodifiable(_save.unlockedAchievements),
      combo: _combo,
      totalCrits: _save.stats.totalCrits,
      maxCombo: _save.stats.maxCombo,
      comboBurstCount: _save.stats.comboBurstCount,
      dailyStreak: _save.dailyStreak,
      maxDailyStreak: _save.stats.maxDailyStreak,
      lastDailyClaimAt: _save.lastDailyClaimAt,
      activeBoosters: List.unmodifiable(_save.activeBoosters),
      tapsUntilSlime: (slimeSpawnEvery - _save.tapsSinceSlime).clamp(0, slimeSpawnEvery),
      autoTapping: _autoTapActive(),
      tutorialSeen: _save.settings.tutorialSeen,
      skillReadyAt: Map.unmodifiable(_save.skillReadyAt),
      completedSetIds: Set.unmodifiable(_completedSetIds()),
      slimesDefeated: _save.stats.slimesDefeated,
      skillsUsed: _save.stats.skillsUsed,
      boostersPurchased: _save.stats.boostersPurchased,
      loaded: loaded,
    );
    if (loaded) _checkAchievements();
  }

  bool _autoTapActive() {
    final now = DateTime.now();
    return _save.activeBoosters
        .any((b) => b.type == BoosterType.autoTap && b.isActive(now));
  }

  Set<String> _completedSetIds() {
    final ids = <String>{};
    for (final s in swordSets) {
      if (s.swordIds.every((id) => (_save.ownedSwords[id] ?? 0) > 0)) {
        ids.add(s.id);
      }
    }
    return ids;
  }

  double _setDpsBonus() {
    double bonus = 0;
    final completed = _completedSetIds();
    for (final s in swordSets) {
      if (completed.contains(s.id)) bonus += s.dpsBonus;
    }
    return 1.0 + bonus;
  }

  double _setTapBonus() {
    double bonus = 0;
    final completed = _completedSetIds();
    for (final s in swordSets) {
      if (completed.contains(s.id)) bonus += s.tapBonus;
    }
    return 1.0 + bonus;
  }

  void _checkAchievements() {
    final ctx = state.achContext();
    bool anyChanged = false;
    for (final def in achievementCatalog) {
      if (_save.unlockedAchievements.contains(def.id)) continue;
      if (def.id == 'master_perfectionist') continue; // handled below
      if (def.progress(ctx).done) {
        _save.unlockedAchievements.add(def.id);
        _save.essence += def.essenceReward;
        _achievementUnlocks.add(def);
        anyChanged = true;
      }
    }
    // Perfectionist: unlocks when every other achievement is done.
    if (!_save.unlockedAchievements.contains('master_perfectionist')) {
      final others =
          achievementCatalog.where((a) => a.id != 'master_perfectionist');
      if (others.every((a) => _save.unlockedAchievements.contains(a.id))) {
        final def = achievementCatalog
            .firstWhere((a) => a.id == 'master_perfectionist');
        _save.unlockedAchievements.add(def.id);
        _save.essence += def.essenceReward;
        _achievementUnlocks.add(def);
        anyChanged = true;
      }
    }
    if (anyChanged) {
      // Re-emit to reflect new essence + unlock set in a single next frame.
      state = GameState(
        gold: state.gold,
        totalGoldEarned: state.totalGoldEarned,
        tapPower: state.tapPower,
        dps: state.dps,
        prestigeSouls: state.prestigeSouls,
        prestigeCount: state.prestigeCount,
        producerLevels: state.producerLevels,
        tapUpgradeLevels: state.tapUpgradeLevels,
        totalTaps: state.totalTaps,
        playTimeSeconds: state.playTimeSeconds,
        maxDpsEver: state.maxDpsEver,
        lifetimeGold: state.lifetimeGold,
        totalSummons: state.totalSummons,
        totalTapUpgradesBought: state.totalTapUpgradesBought,
        haptic: state.haptic,
        sound: state.sound,
        darkMode: state.darkMode,
        essence: _save.essence,
        ownedSwords: state.ownedSwords,
        equippedSwordId: state.equippedSwordId,
        summonsSinceHighRare: state.summonsSinceHighRare,
        unlockedAchievements: Set.unmodifiable(_save.unlockedAchievements),
        combo: state.combo,
        totalCrits: state.totalCrits,
        maxCombo: state.maxCombo,
        comboBurstCount: state.comboBurstCount,
        dailyStreak: state.dailyStreak,
        maxDailyStreak: state.maxDailyStreak,
        lastDailyClaimAt: state.lastDailyClaimAt,
        activeBoosters: state.activeBoosters,
        tapsUntilSlime: state.tapsUntilSlime,
        autoTapping: state.autoTapping,
        tutorialSeen: state.tutorialSeen,
        skillReadyAt: state.skillReadyAt,
        completedSetIds: state.completedSetIds,
        slimesDefeated: state.slimesDefeated,
        skillsUsed: state.skillsUsed,
        boostersPurchased: state.boostersPurchased,
        loaded: true,
      );
    }
  }

  double _prestigeMult() => 1.0 + (_save.prestigeSouls * 0.02);

  double _equippedTapMult() {
    final id = _save.equippedSwordId;
    if (id == null) return 1.0;
    final lv = _save.ownedSwords[id] ?? 0;
    if (lv <= 0) return 1.0;
    try {
      return swordById(id).tapMultAt(lv);
    } catch (_) {
      return 1.0;
    }
  }

  double _equippedDpsMult() {
    final id = _save.equippedSwordId;
    if (id == null) return 1.0;
    final lv = _save.ownedSwords[id] ?? 0;
    if (lv <= 0) return 1.0;
    try {
      return swordById(id).dpsMultAt(lv);
    } catch (_) {
      return 1.0;
    }
  }

  double _calcTapPower() {
    double base = 1.0;
    for (final def in tapUpgradeCatalog) {
      final lv = _save.tapUpgradeLevels[def.id] ?? 0;
      base += def.tapPowerPerLevel * lv;
    }
    return base *
        _prestigeMult() *
        _equippedTapMult() *
        _boosterTapMult() *
        _setTapBonus();
  }

  double _calcDps() {
    double sum = 0;
    for (final def in producerCatalog) {
      final lv = _save.producerLevels[def.id] ?? 0;
      sum += def.dpsAt(lv);
    }
    return sum *
        _prestigeMult() *
        _equippedDpsMult() *
        _boosterDpsMult() *
        _setDpsBonus();
  }

  /// Drop expired boosters from the save (called before any calculation that
  /// reads them, to avoid "ghost" multipliers after their timer ran out).
  void _reapBoosters() {
    final now = DateTime.now();
    _save.activeBoosters.removeWhere((b) => !b.isActive(now));
  }

  double _boosterDpsMult() {
    _reapBoosters();
    double m = 1.0;
    for (final b in _save.activeBoosters) {
      if (b.type == BoosterType.dps || b.type == BoosterType.rush) {
        m *= b.multiplier;
      }
    }
    return m;
  }

  double _boosterTapMult() {
    _reapBoosters();
    double m = 1.0;
    for (final b in _save.activeBoosters) {
      if (b.type == BoosterType.tap || b.type == BoosterType.rush) {
        m *= b.multiplier;
      }
    }
    return m;
  }

  /// Back-compat shim for callers that still treat tap() as "give me gold".
  /// New UI should prefer [tapWithFeedback] to access crit/combo info.
  double tap() => tapWithFeedback().amount;

  TapResult tapWithFeedback() {
    final now = DateTime.now();
    final withinWindow = _lastTapAt != null &&
        now.difference(_lastTapAt!).inMilliseconds <= comboWindowMs;
    final surge = _comboSurgeUntil != null && now.isBefore(_comboSurgeUntil!);
    final increment = surge ? comboSurgePerTap : 1;
    _combo = withinWindow ? (_combo + increment).clamp(0, comboMax) : increment;
    _lastTapAt = now;
    if (_combo > _save.stats.maxCombo) _save.stats.maxCombo = _combo;

    final base = _calcTapPower();
    final comboMult = 1.0 + (_combo * comboBonusPerStack).clamp(0.0, 0.5);
    final surgeMult = surge ? comboSurgeBonus : 1.0;
    final isCrit = _random.nextDouble() < critChance;
    final critMult = isCrit ? critMultiplier : 1.0;
    final amount = base * comboMult * surgeMult * critMult;

    _save.gold += amount;
    _save.totalGoldEarned += amount;
    _save.stats.lifetimeGold += amount;
    _save.stats.totalTaps++;
    if (isCrit) _save.stats.totalCrits++;

    _save.tapsSinceSlime++;
    final slimeSpawned = _save.tapsSinceSlime >= slimeSpawnEvery;
    if (slimeSpawned) _save.tapsSinceSlime = 0;

    // Combo burst — fires once when combo first hits the cap during a run.
    bool isBurst = false;
    double burstAmount = 0;
    if (_combo >= comboMax && !_burstFiredThisRun) {
      _burstFiredThisRun = true;
      isBurst = true;
      burstAmount = _calcDps() * comboBurstWorthSeconds;
      _save.gold += burstAmount;
      _save.totalGoldEarned += burstAmount;
      _save.stats.lifetimeGold += burstAmount;
      _save.stats.comboBurstCount++;
    }

    _scheduleComboDecay();
    _emit(loaded: true);
    return TapResult(
      amount: amount,
      isCrit: isCrit,
      combo: _combo,
      slimeSpawned: slimeSpawned,
      isBurst: isBurst,
      burstAmount: burstAmount,
    );
  }

  void _scheduleComboDecay() {
    _comboDecayTimer?.cancel();
    _comboDecayTimer =
        Timer(const Duration(milliseconds: comboWindowMs), () {
      if (_combo == 0) return;
      _combo = 0;
      _burstFiredThisRun = false;
      _emit(loaded: true);
    });
  }

  int buyProducer(String id, int count) {
    final def = producerCatalog.firstWhere((p) => p.id == id);
    final oldLv = _save.producerLevels[id] ?? 0;
    final n = count < 0 ? def.maxAffordable(_save.gold, oldLv) : count;
    if (n <= 0) return 0;
    final cost = def.costForNext(oldLv, n);
    if (_save.gold < cost) return 0;
    final newLv = oldLv + n;
    _save.gold -= cost;
    _save.producerLevels[id] = newLv;
    final essenceGain =
        _milestoneEssenceUpTo(newLv) - _milestoneEssenceUpTo(oldLv);
    if (essenceGain > 0) _save.essence += essenceGain;
    _emit(loaded: true);
    unawaited(_persist());
    return n;
  }

  int buyTapUpgrade(String id, int count) {
    final def = tapUpgradeCatalog.firstWhere((p) => p.id == id);
    final lv = _save.tapUpgradeLevels[id] ?? 0;
    final n = count < 0 ? def.maxAffordable(_save.gold, lv) : count;
    if (n <= 0) return 0;
    final cost = def.costForNext(lv, n);
    if (_save.gold < cost) return 0;
    _save.gold -= cost;
    _save.tapUpgradeLevels[id] = lv + n;
    _save.stats.totalTapUpgradesBought += n;
    _emit(loaded: true);
    unawaited(_persist());
    return n;
  }

  bool prestige() {
    final souls = state.prestigeSoulsAvailable;
    if (souls <= 0) return false;
    _save.prestigeSouls += souls;
    _save.prestigeCount += 1;
    _save.essence += souls * 3;
    _save.gold = 0;
    _save.totalGoldEarned = 0;
    _save.producerLevels.clear();
    _save.tapUpgradeLevels.clear();
    _emit(loaded: true);
    unawaited(_persist());
    return true;
  }

  void claimOfflineReward(OfflineReward r) {
    _save.gold += r.gold;
    _save.totalGoldEarned += r.gold;
    _save.stats.lifetimeGold += r.gold;
    _emit(loaded: true);
    unawaited(_persist());
  }

  OfflineReward? consumeOfflineReward() {
    final r = _pendingOffline;
    _pendingOffline = null;
    return r;
  }

  void setHaptic(bool value) {
    _save.settings.haptic = value;
    _emit(loaded: true);
    unawaited(_persist());
  }

  void setSound(bool value) {
    _save.settings.sound = value;
    _emit(loaded: true);
    unawaited(_persist());
  }

  void setDarkMode(bool value) {
    _save.settings.darkMode = value;
    _emit(loaded: true);
    unawaited(_persist());
  }

  void setTutorialSeen(bool value) {
    _save.settings.tutorialSeen = value;
    _emit(loaded: true);
    unawaited(_persist());
  }

  /// Returns (and clears) the pending daily bonus computed at load time.
  DailyBonus? consumePendingDaily() {
    final r = _pendingDaily;
    _pendingDaily = null;
    return r;
  }

  void claimDailyBonus(DailyBonus bonus) {
    _save.essence += bonus.essence;
    _save.dailyStreak = bonus.streak;
    if (bonus.streak > _save.stats.maxDailyStreak) {
      _save.stats.maxDailyStreak = bonus.streak;
    }
    _save.lastDailyClaimAt = DateTime.now();
    _emit(loaded: true);
    unawaited(_persist());
  }

  // ============ Boosters + ads ============

  /// Attempt to buy [offer] with essence. Returns true on success.
  bool buyBoosterWithEssence(BoosterOffer offer) {
    if (_save.essence < offer.essenceCost) return false;
    _save.essence -= offer.essenceCost;
    _applyBooster(offer.type, offer.multiplier, offer.durationSec);
    _save.stats.boostersPurchased++;
    _emit(loaded: true);
    unawaited(_persist());
    return true;
  }

  /// Dev stub for ad rewards — in production this would actually show an
  /// ad via AdMob / UnityAds and only grant on the completion callback.
  /// Right now we just hand the reward out for testing.
  void grantAdBooster(BoosterOffer offer) {
    _applyBooster(offer.type, offer.multiplier, offer.durationSec);
    _save.stats.boostersPurchased++;
    _emit(loaded: true);
    unawaited(_persist());
  }

  void _applyBooster(BoosterType type, double multiplier, int durationSec) {
    _reapBoosters();
    final now = DateTime.now();
    // If the same type+multiplier is already active, extend its timer
    // instead of stacking a second identical booster.
    final existing = _save.activeBoosters.indexWhere(
      (b) => b.type == type && b.multiplier == multiplier,
    );
    if (existing >= 0) {
      final prev = _save.activeBoosters[existing];
      final base = prev.expiresAt.isAfter(now) ? prev.expiresAt : now;
      _save.activeBoosters[existing] = Booster(
        type: type,
        multiplier: multiplier,
        expiresAt: base.add(Duration(seconds: durationSec)),
      );
    } else {
      _save.activeBoosters.add(Booster(
        type: type,
        multiplier: multiplier,
        expiresAt: now.add(Duration(seconds: durationSec)),
      ));
    }
    if (type == BoosterType.autoTap) _ensureAutoTapTimer();
  }

  void _ensureAutoTapTimer() {
    if (_autoTapTimer != null) return;
    _autoTapTimer = Timer.periodic(
      const Duration(milliseconds: autoTapIntervalMs),
      (_) {
        if (!_autoTapActive()) {
          _autoTapTimer?.cancel();
          _autoTapTimer = null;
          _emit(loaded: true);
          return;
        }
        tapWithFeedback();
      },
    );
  }

  // ============ Skills ============

  /// Returns the moment a skill becomes ready, or null if it's already
  /// usable. UI uses this to render cooldown overlays.
  DateTime? skillCooldownEndsAt(SkillId id) {
    final ready = _save.skillReadyAt[id.id];
    if (ready == null) return null;
    return ready.isAfter(DateTime.now()) ? ready : null;
  }

  SkillResult useSkill(SkillId id) {
    final def = skillDefFor(id);
    final cooldownEnd = skillCooldownEndsAt(id);
    if (cooldownEnd != null) {
      return SkillResult(
        id: id,
        ok: false,
        message: '아직 쿨타임이에요',
      );
    }
    final now = DateTime.now();
    SkillResult result;
    switch (id) {
      case SkillId.slashBurst:
        final reward = _calcDps() * slashBurstWorthSeconds;
        _save.gold += reward;
        _save.totalGoldEarned += reward;
        _save.stats.lifetimeGold += reward;
        result = SkillResult(
          id: id,
          ok: true,
          message: '검기 폭발!',
          payload: reward,
        );
      case SkillId.comboSurge:
        _comboSurgeUntil = now.add(const Duration(seconds: 10));
        result = SkillResult(
          id: SkillId.comboSurge,
          ok: true,
          message: '10초간 콤보 폭주!',
        );
      case SkillId.essenceGather:
        _save.essence += essenceGatherAmount;
        result = SkillResult(
          id: SkillId.essenceGather,
          ok: true,
          message: '정수 +$essenceGatherAmount',
          payload: essenceGatherAmount.toDouble(),
        );
    }
    _save.skillReadyAt[id.id] = now.add(def.cooldown);
    _save.stats.skillsUsed++;
    _emit(loaded: true);
    unawaited(_persist());
    return result;
  }

  /// Called by the home screen when a golden slime is killed (its HP drops
  /// to 0). Grants gold equal to [slimeRewardTaps] × current tap power and
  /// returns the awarded amount so the UI can show a floating number.
  double defeatGoldenSlime() {
    final reward = _calcTapPower() * slimeRewardTaps;
    _save.gold += reward;
    _save.totalGoldEarned += reward;
    _save.stats.lifetimeGold += reward;
    _save.stats.slimesDefeated++;
    _emit(loaded: true);
    unawaited(_persist());
    return reward;
  }

  /// Estimated reward shown on the slime HP bar so the player can see what
  /// finishing it off is worth at the current moment.
  double get slimePreviewReward => _calcTapPower() * slimeRewardTaps;

  // ============ Sword dismantle ============

  /// Returns the amount of essence that dismantling [swordId] would refund,
  /// or 0 if the sword can't be dismantled.
  int dismantleRefund(String swordId) {
    final lv = _save.ownedSwords[swordId] ?? 0;
    if (lv <= 0) return 0;
    if (_save.equippedSwordId == swordId) return 0;
    final SwordDef def;
    try {
      def = swordById(swordId);
    } catch (_) {
      return 0;
    }
    return _dismantleEssencePerLevel(def.tier) * lv;
  }

  int _dismantleEssencePerLevel(SwordTier tier) {
    return switch (tier) {
      SwordTier.n => 2,
      SwordTier.r => 5,
      SwordTier.sr => 12,
      SwordTier.ssr => 25,
      SwordTier.lr => 40,
      SwordTier.ur => 60,
    };
  }

  /// Dismantle an owned, non-equipped sword. Returns essence granted (0 on
  /// failure — usually because the sword is equipped or not owned).
  int dismantleSword(String swordId) {
    final refund = dismantleRefund(swordId);
    if (refund <= 0) return 0;
    _save.ownedSwords.remove(swordId);
    _save.essence += refund;
    _emit(loaded: true);
    unawaited(_persist());
    return refund;
  }

  Future<void> resetAll() async {
    await _syncService.wipe();
    _save = SaveData();
    _pendingOffline = null;
    _pendingDaily = null;
    _combo = 0;
    _lastTapAt = null;
    _emit(loaded: true);
    // Push the fresh state up immediately so other devices see the reset
    // without waiting for the next auto-save tick.
    await _persist();
  }

  // ============ Sword collection / gacha ============

  SwordTier _rollTier({required bool forceSrPlus}) {
    final pool = forceSrPlus
        ? const [SwordTier.sr, SwordTier.ssr, SwordTier.lr, SwordTier.ur]
        : SwordTier.values;
    final totalWeight =
        pool.map((t) => t.rate).fold<double>(0, (a, b) => a + b);
    final roll = _random.nextDouble() * totalWeight;
    double cum = 0;
    for (final t in pool) {
      cum += t.rate;
      if (roll < cum) return t;
    }
    return pool.last;
  }

  SwordDef _pickRandomOfTier(SwordTier tier) {
    final pool = swordCatalog.where((s) => s.tier == tier).toList();
    return pool[_random.nextInt(pool.length)];
  }

  SummonResult _doOnePull({required bool guaranteedRPlus}) {
    final pityHit = _save.summonsSinceHighRare + 1 >= pityThreshold;
    SwordTier tier;
    if (pityHit) {
      tier = _rollTier(forceSrPlus: true);
    } else if (guaranteedRPlus) {
      tier = _rollTier(forceSrPlus: false);
      if (tier == SwordTier.n) tier = SwordTier.r;
    } else {
      tier = _rollTier(forceSrPlus: false);
    }
    final def = _pickRandomOfTier(tier);
    final oldLv = _save.ownedSwords[def.id] ?? 0;
    final wasOwned = oldLv > 0;
    final wasMaxed = oldLv >= SwordDef.maxLevel;
    final newLv = wasMaxed ? SwordDef.maxLevel : (wasOwned ? oldLv + 1 : 1);
    _save.ownedSwords[def.id] = newLv;
    _save.equippedSwordId ??= def.id;
    _save.stats.totalSummons++;
    if (tier.index >= SwordTier.sr.index) {
      _save.summonsSinceHighRare = 0;
    } else {
      _save.summonsSinceHighRare++;
    }
    return SummonResult(
      sword: def,
      levelAfter: newLv,
      isDuplicate: wasOwned,
      isMaxed: wasMaxed,
    );
  }

  SummonResult? summonOne() {
    if (_save.essence < summonCostSingle) return null;
    _save.essence -= summonCostSingle;
    final r = _doOnePull(guaranteedRPlus: false);
    _emit(loaded: true);
    unawaited(_persist());
    return r;
  }

  List<SummonResult>? summonTen() {
    if (_save.essence < summonCostTen) return null;
    _save.essence -= summonCostTen;
    final results = <SummonResult>[];
    for (int i = 0; i < 10; i++) {
      final isLast = i == 9;
      results.add(_doOnePull(guaranteedRPlus: isLast));
    }
    _emit(loaded: true);
    unawaited(_persist());
    return results;
  }

  void equipSword(String id) {
    if ((_save.ownedSwords[id] ?? 0) <= 0) return;
    _save.equippedSwordId = id;
    _emit(loaded: true);
    unawaited(_persist());
  }

  Future<void> persist() => _persist();
}

final gameProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
