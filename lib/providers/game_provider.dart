import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/producer_catalog.dart';
import '../data/tap_upgrade_catalog.dart';
import '../models/save_data.dart';
import '../services/save_service.dart';

/// Buy count: 1, 10, 100 or -1 for Max.
final buyMultiplierProvider = StateProvider<int>((_) => 1);

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
  final bool haptic;
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
    required this.haptic,
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
        haptic: true,
        loaded: false,
      );

  double get prestigeMultiplier => 1.0 + (prestigeSouls * 0.02);

  int get prestigeSoulsAvailable {
    if (totalGoldEarned < 1e9) return 0;
    return sqrt(totalGoldEarned / 1e9).floor();
  }

  int producerLevel(String id) => producerLevels[id] ?? 0;
  int tapUpgradeLevel(String id) => tapUpgradeLevels[id] ?? 0;

  bool canAfford(double cost) => gold >= cost;
}

class OfflineReward {
  final Duration duration;
  final double gold;
  OfflineReward(this.duration, this.gold);
}

class GameNotifier extends Notifier<GameState> {
  final _saveService = SaveService();
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
        _emit(loaded: true);
      }
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
      haptic: _save.settings.haptic,
      loaded: loaded,
    );
  }

  double _prestigeMult() => 1.0 + (_save.prestigeSouls * 0.02);

  double _calcTapPower() {
    double base = 1.0;
    for (final def in tapUpgradeCatalog) {
      final lv = _save.tapUpgradeLevels[def.id] ?? 0;
      base += def.tapPowerPerLevel * lv;
    }
    return base * _prestigeMult();
  }

  double _calcDps() {
    double sum = 0;
    for (final def in producerCatalog) {
      final lv = _save.producerLevels[def.id] ?? 0;
      sum += def.dpsAt(lv);
    }
    return sum * _prestigeMult();
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

  /// Buy [count] levels. Pass -1 for Max. Returns actual bought count (0 if none).
  int buyProducer(String id, int count) {
    final def = producerCatalog.firstWhere((p) => p.id == id);
    final lv = _save.producerLevels[id] ?? 0;
    final n = count < 0 ? def.maxAffordable(_save.gold, lv) : count;
    if (n <= 0) return 0;
    final cost = def.costForNext(lv, n);
    if (_save.gold < cost) return 0;
    _save.gold -= cost;
    _save.producerLevels[id] = lv + n;
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
    _emit(loaded: true);
    return n;
  }

  bool prestige() {
    final souls = state.prestigeSoulsAvailable;
    if (souls <= 0) return false;
    _save.prestigeSouls += souls;
    _save.prestigeCount += 1;
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

  Future<void> resetAll() async {
    await _saveService.wipe();
    _save = SaveData();
    _pendingOffline = null;
    _emit(loaded: true);
  }

  Future<void> persist() => _persist();
}

final gameProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
