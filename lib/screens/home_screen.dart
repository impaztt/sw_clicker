import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../models/booster.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../widgets/booster_shop_dialog.dart';
import '../widgets/dps_display.dart';
import '../widgets/floating_number.dart';
import '../widgets/golden_slime.dart';
import '../widgets/gold_display.dart';
import '../widgets/sword_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<FloatingNumberData> _floats = [];
  final List<_SlimeSpawn> _slimes = [];
  int _nextId = 0;
  int _nextSlimeId = 0;
  final _rng = Random();

  void _handleTap(Offset globalPos) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPos);
    final result = ref.read(gameProvider.notifier).tapWithFeedback();
    final state = ref.read(gameProvider);
    if (state.haptic) {
      if (state.reduceTapHaptics) {
        if (result.isCrit) HapticFeedback.mediumImpact();
      } else if (result.isCrit) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
    if (state.sound) AudioService.instance.playTap();
    setState(() {
      _floats.add(FloatingNumberData(
        id: _nextId++,
        origin: local,
        amount: result.amount,
        isCrit: result.isCrit,
      ));
      if (result.slimeSpawned) _spawnSlime(box.size);
    });
  }

  void _removeFloat(int id) {
    if (!mounted) return;
    setState(() => _floats.removeWhere((f) => f.id == id));
  }

  void _spawnSlime(Size bounds) {
    final id = _nextSlimeId++;
    // Keep it clear of the top bar and the sword center by biasing the
    // random position toward the horizontal edges and avoiding the middle
    // band where the main sword sits.
    final w = bounds.width;
    final h = bounds.height;
    final leftSide = _rng.nextBool();
    final dx = leftSide
        ? 16.0 + _rng.nextDouble() * (w * 0.25)
        : w * 0.6 + _rng.nextDouble() * (w * 0.25) - 16.0;
    final dy = h * 0.25 + _rng.nextDouble() * (h * 0.45);
    _slimes.add(_SlimeSpawn(id: id, offset: Offset(dx, dy)));
  }

  void _defeatSlime(int id, Offset slimeOffset) {
    if (!mounted) return;
    final reward = ref.read(gameProvider.notifier).defeatGoldenSlime();
    if (ref.read(gameProvider).haptic) HapticFeedback.heavyImpact();
    setState(() {
      _slimes.removeWhere((s) => s.id == id);
      // Pop a big floating number where the slime was so the reward feels
      // grounded in the actual kill, not a phantom number from elsewhere.
      _floats.add(FloatingNumberData(
        id: _nextId++,
        origin: slimeOffset + const Offset(40, 30),
        amount: reward,
        isCrit: true,
      ));
    });
  }

  void _slimeTimedOut(int id) {
    if (!mounted) return;
    setState(() => _slimes.removeWhere((s) => s.id == id));
  }

  void _openBoosterShop() {
    showDialog<void>(
      context: context,
      builder: (_) => const BoosterShopDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final slimeActive = _slimes.isNotEmpty;

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: GoldDisplay(amount: game.gold)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SlimeProgressBar(
                  remaining: game.tapsUntilSlime,
                  total: slimeSpawnEvery,
                  active: slimeActive,
                  reward: notifier.slimePreviewReward,
                ),
              ),
              const SizedBox(height: 10),
              DpsDisplay(dps: game.dps),
              const Spacer(),
              Center(
                child: Builder(builder: (_) {
                  final equipped = game.equippedSword;
                  if (equipped != null) {
                    return SwordWidget(
                      onTap: _handleTap,
                      visual: equipped.visual,
                    );
                  }
                  return SwordWidget(onTap: _handleTap);
                }),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _BattleStatusPanel(
                  combo: game.combo,
                  tapPower: game.tapPower,
                  maxIdleReward: game.dps * offlineMaxSeconds,
                  idleHours: offlineMaxHours,
                  prestigeMultiplier: game.prestigeMultiplier,
                  collectionFraction: notifier.collectionBonusFraction,
                  boosters: game.activeBoosters,
                ),
              ),
              const SizedBox(height: 76),
            ],
          ),
          FloatingNumberLayer(items: _floats, onDone: _removeFloat),
          for (final slime in _slimes)
            Positioned(
              left: slime.offset.dx,
              top: slime.offset.dy,
              child: GoldenSlime(
                previewReward: notifier.slimePreviewReward,
                onDefeat: () => _defeatSlime(slime.id, slime.offset),
                onTimeout: () => _slimeTimedOut(slime.id),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 16,
            child: _ShopFab(onTap: _openBoosterShop),
          ),
        ],
      ),
    );
  }
}

class _SlimeSpawn {
  final int id;
  final Offset offset;
  const _SlimeSpawn({required this.id, required this.offset});
}

class _ShopFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ShopFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.coral,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.bolt, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _BattleStatusPanel extends StatelessWidget {
  final int combo;
  final double tapPower;
  final double maxIdleReward;
  final int idleHours;
  final double prestigeMultiplier;
  final double collectionFraction;
  final List<Booster> boosters;
  const _BattleStatusPanel({
    required this.combo,
    required this.tapPower,
    required this.maxIdleReward,
    required this.idleHours,
    required this.prestigeMultiplier,
    required this.collectionFraction,
    required this.boosters,
  });

  @override
  Widget build(BuildContext context) {
    final comboPct =
        ((combo * comboBonusPerStack).clamp(0.0, 0.5) * 100).toStringAsFixed(0);
    final permanentPct = ((prestigeMultiplier - 1) * 100).clamp(0.0, 9999999.0);
    final collectionPct = (collectionFraction * 100).clamp(0.0, 9999999.0);

    final now = DateTime.now();
    final activeBoosters = boosters.where((b) => b.isActive(now)).toList();
    Duration minRemaining = Duration.zero;
    double strongestBoost = 1.0;
    if (activeBoosters.isNotEmpty) {
      minRemaining = activeBoosters
          .map((b) => b.remaining(now))
          .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
      strongestBoost = activeBoosters
          .map((b) => b.multiplier)
          .fold<double>(1.0, (a, b) => a > b ? a : b);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_customize,
                  size: 18, color: AppColors.deepCoral),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '전투 요약',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
              if (combo > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.deepCoral.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.deepCoral.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '콤보 x$combo (+$comboPct%)',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.deepCoral,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetricPill(
                icon: Icons.touch_app,
                label: '터치',
                value: '+${NumberFormatter.formatPrecise(tapPower)}',
                color: const Color(0xFF8D6E00),
              ),
              _MetricPill(
                icon: Icons.nightlight_round,
                label: '방치',
                value:
                    '+${NumberFormatter.format(maxIdleReward)} / ${idleHours}h',
                color: const Color(0xFF5E35B1),
              ),
              _MetricPill(
                icon: Icons.auto_awesome,
                label: '영구',
                value: '+${permanentPct.toStringAsFixed(0)}%',
                color: const Color(0xFF00695C),
              ),
              _MetricPill(
                icon: Icons.collections_bookmark,
                label: '수집',
                value:
                    '+${collectionPct.toStringAsFixed(collectionFraction >= 1 ? 0 : 1)}%',
                color: const Color(0xFF6A1B9A),
              ),
              if (activeBoosters.isNotEmpty)
                _MetricPill(
                  icon: Icons.bolt,
                  label: '부스터',
                  value:
                      '${activeBoosters.length}개 · 최고 x${strongestBoost.toStringAsFixed(strongestBoost % 1 == 0 ? 0 : 1)} · ${_fmtDuration(minRemaining)}',
                  color: AppColors.deepCoral,
                  highlight: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDuration(Duration d) {
    final totalSec = d.inSeconds.clamp(0, 1 << 31);
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool highlight;
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: highlight ? 0.16 : 0.11),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: highlight ? 0.45 : 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            '$label $value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Visible-from-anywhere progress bar for the next slime spawn. Replaces the
/// old text-only "슬라임까지 N회 터치" hint. While a slime is on screen, the
/// bar switches to an "출현 중!" call-to-action so the player knows it's the
/// active state, not a stuck progress meter.
class _SlimeProgressBar extends StatelessWidget {
  final int remaining;
  final int total;
  final bool active;
  final double reward;
  const _SlimeProgressBar({
    required this.remaining,
    required this.total,
    required this.active,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = active ? 1.0 : ((total - remaining) / total).clamp(0.0, 1.0);
    final accent = active ? const Color(0xFFE53935) : const Color(0xFFFFB300);
    final label = active
        ? '🟡 슬라임 출현! 처치 보상 +${NumberFormatter.format(reward)}'
        : '🟡 슬라임까지 $remaining회 · 처치 시 +${NumberFormatter.format(reward)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accent.computeLuminance() < 0.5
                  ? accent
                  : const Color(0xFF8D6E00),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ],
      ),
    );
  }
}
