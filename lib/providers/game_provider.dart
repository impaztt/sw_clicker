import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/achievement_catalog.dart';
import '../data/producer_catalog.dart';
import '../data/sword_catalog.dart';
import '../data/tap_upgrade_catalog.dart';
import '../models/achievement.dart';
import '../models/save_data.dart';
import '../models/sword.dart';
import '../services/save_service.dart';

/// Buy count: 1, 10, 100 or -1 for Max.
final buyMultiplierProvider = StateProvider<int>((_) => 1);

/// Cost in 정수 per single summon.
const summonCostSingle = 30;
const summonCostTen = 270;

/// After this many consecutive non-SR+ pulls, the next pull is guaranteed SR+.
const pityThreshold = 80;

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
  final int essence;
  final Map<String, int> ownedSwords;
  final String? equippedSwordId;
  final int summonsSinceHighRare;
  final Set<String> unlockedAchievements;
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
    required this.essence,
    required this.ownedSwords,
    required this.equippedSwordId,
    required this.summonsSinceHighRare,
    required this.unlockedAchievements,
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
        essence: 90,
        ownedSwords: {},
        equippedSwordId: null,
        summonsSinceHighRare: 0,
        unlockedAchievements: {},
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
    bool hasR = false, hasSr = false, hasSsr = false, hasUr = false;
    int maxLv = 0;
    int maxedCount = 0;
    for (final entry in ownedSwords.entries) {
      if (entry.value <= 0) continue;
      try {
        final tier = swordById(entry.key).tier;
        if (tier == SwordTier.r) hasR = true;
        if (tier == SwordTier.sr) hasSr = true;
        if (tier == SwordTier.ssr) hasSsr = true;
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
      ownsAnyUr: hasUr,
      maxSwordLevel: maxLv,
      maxedSwordCount: maxedCount,
      totalSummons: totalSummons,
      prestigeCount: prestigeCount,
      prestigeSouls: prestigeSouls,
      totalTapUpgradesBought: totalTapUpgradesBought,
      hasEquippedSword: equippedSwordId != null,
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
  final _saveService = SaveService();
  final _random = Random();
  final _achievementUnlocks = StreamController<AchievementDef>.broadcast();
  Timer? _tickTimer;
  Timer? _saveTimer;
  DateTime _lastTick = DateTime.now();
  double _playTimeAcc = 0;
  SaveData _save = SaveData();
  OfflineReward? _pendingOffline;

  @override
  GameState build() {
    ref.onDispose(_dispose);
    Future.microtask(_initialize);
    return GameState.empty();
  }

  void _dispose() {
    _tickTimer?.cancel();
    _saveTimer?.cancel();
    _achievementUnlocks.close();
  }

  Future<void> _initialize() async {
    final loaded = await _saveService.load();
    if (loaded != null) {
      _save = loaded;
      final elapsed = DateTime.now().difference(loaded.lastSavedAt);
      final cappedSeconds = elapsed.inSeconds.clamp(0, 12 * 3600);
      final dpsNow = _calcDps();
      if (cappedSeconds > 60 && dpsNow > 0) {
        _pendingOffline = OfflineReward(
          Duration(seconds: cappedSeconds),
          dpsNow * cappedSeconds,
        );
      }
    }
    _emit(loaded: true);
    _startTicker();
    _startAutoSave();
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
      const Duration(seconds: 30),
      (_) => _persist(),
    );
  }

  Future<void> _persist() async {
    await _saveService.save(_save);
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
      essence: _save.essence,
      ownedSwords: Map.unmodifiable(_save.ownedSwords),
      equippedSwordId: _save.equippedSwordId,
      summonsSinceHighRare: _save.summonsSinceHighRare,
      unlockedAchievements: Set.unmodifiable(_save.unlockedAchievements),
      loaded: loaded,
    );
    if (loaded) _checkAchievements();
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
        essence: _save.essence,
        ownedSwords: state.ownedSwords,
        equippedSwordId: state.equippedSwordId,
        summonsSinceHighRare: state.summonsSinceHighRare,
        unlockedAchievements: Set.unmodifiable(_save.unlockedAchievements),
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
    return base * _prestigeMult() * _equippedTapMult();
  }

  double _calcDps() {
    double sum = 0;
    for (final def in producerCatalog) {
      final lv = _save.producerLevels[def.id] ?? 0;
      sum += def.dpsAt(lv);
    }
    return sum * _prestigeMult() * _equippedDpsMult();
  }

  double tap() {
    final amount = _calcTapPower();
    _save.gold += amount;
    _save.totalGoldEarned += amount;
    _save.stats.lifetimeGold += amount;
    _save.stats.totalTaps++;
    _emit(loaded: true);
    return amount;
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
    _persist();
    return true;
  }

  void claimOfflineReward(OfflineReward r) {
    _save.gold += r.gold;
    _save.totalGoldEarned += r.gold;
    _save.stats.lifetimeGold += r.gold;
    _emit(loaded: true);
  }

  OfflineReward? consumeOfflineReward() {
    final r = _pendingOffline;
    _pendingOffline = null;
    return r;
  }

  void setHaptic(bool value) {
    _save.settings.haptic = value;
    _emit(loaded: true);
  }

  void setSound(bool value) {
    _save.settings.sound = value;
    _emit(loaded: true);
  }

  Future<void> resetAll() async {
    await _saveService.wipe();
    _save = SaveData();
    _pendingOffline = null;
    _emit(loaded: true);
  }

  // ============ Sword collection / gacha ============

  SwordTier _rollTier({required bool forceSrPlus}) {
    final pool = forceSrPlus
        ? const [SwordTier.sr, SwordTier.ssr, SwordTier.ur]
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
    return results;
  }

  void equipSword(String id) {
    if ((_save.ownedSwords[id] ?? 0) <= 0) return;
    _save.equippedSwordId = id;
    _emit(loaded: true);
  }

  Future<void> persist() => _persist();
}

final gameProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
