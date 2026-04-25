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
      if (result.isCrit) {
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
              if (game.combo > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ComboChip(combo: game.combo),
                ),
              _TapPowerChip(tapPower: game.tapPower),
              if (game.dps > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _IdleChip(
                    maxReward: game.dps * offlineMaxSeconds,
                    hours: offlineMaxHours,
                  ),
                ),
              if (game.prestigeMultiplier > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _PermanentBoostChip(multiplier: game.prestigeMultiplier),
                ),
              if (notifier.collectionBonusFraction > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _CollectionChip(
                    fraction: notifier.collectionBonusFraction,
                  ),
                ),
              if (game.activeBoosters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _ActiveBoostersStrip(boosters: game.activeBoosters),
                ),
              const SizedBox(height: 24),
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

class _ActiveBoostersStrip extends StatelessWidget {
  final List<Booster> boosters;
  const _ActiveBoostersStrip({required this.boosters});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final b in boosters)
            _BoosterChip(
              type: b.type,
              multiplier: b.multiplier,
              remaining: b.remaining(now),
            ),
        ],
      ),
    );
  }
}

class _BoosterChip extends StatelessWidget {
  final BoosterType type;
  final double multiplier;
  final Duration remaining;
  const _BoosterChip({
    required this.type,
    required this.multiplier,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      BoosterType.dps => 'DPS',
      BoosterType.tap => '터치',
      BoosterType.rush => '러시',
      BoosterType.autoTap => 'AUTO',
    };
    final color = switch (type) {
      BoosterType.dps => const Color(0xFF26A69A),
      BoosterType.tap => AppColors.deepCoral,
      BoosterType.rush => const Color(0xFFFFB300),
      BoosterType.autoTap => const Color(0xFF5C6BC0),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label x${multiplier.toStringAsFixed(multiplier % 1 == 0 ? 0 : 1)} · ${_fmt(remaining)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final totalSec = d.inSeconds.clamp(0, 1 << 31);
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }
}

class _TapPowerChip extends StatelessWidget {
  final double tapPower;
  const _TapPowerChip({required this.tapPower});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app, size: 18, color: Color(0xFF8D6E00)),
          const SizedBox(width: 4),
          Text(
            '터치 +${NumberFormatter.formatPrecise(tapPower)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7A5C00),
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
    final ratio = active
        ? 1.0
        : ((total - remaining) / total).clamp(0.0, 1.0);
    final accent = active
        ? const Color(0xFFE53935)
        : const Color(0xFFFFB300);
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

class _ComboChip extends StatelessWidget {
  final int combo;
  const _ComboChip({required this.combo});

  @override
  Widget build(BuildContext context) {
    final bonus = (combo * 0.01).clamp(0.0, 0.5);
    final pct = (bonus * 100).toStringAsFixed(0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.deepCoral.withValues(alpha: 0.9),
            AppColors.coral.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              size: 18, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '콤보 x$combo · +$pct% 터치',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleChip extends StatelessWidget {
  final double maxReward;
  final int hours;
  const _IdleChip({required this.maxReward, required this.hours});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF9575CD).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.nightlight_round,
              size: 18, color: Color(0xFF5E35B1)),
          const SizedBox(width: 4),
          Text(
            '방치 보상 최대 +${NumberFormatter.format(maxReward)} / ${hours}h',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4527A0),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionChip extends StatelessWidget {
  final double fraction;
  const _CollectionChip({required this.fraction});

  @override
  Widget build(BuildContext context) {
    final pct = (fraction * 100).toStringAsFixed(fraction >= 1 ? 0 : 1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFAB47BC).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.collections_bookmark,
              size: 18, color: Color(0xFF6A1B9A)),
          const SizedBox(width: 4),
          Text(
            '수집 보너스 +$pct% · 터치·동료·초월 모두 적용',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6A1B9A),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermanentBoostChip extends StatelessWidget {
  final double multiplier;
  const _PermanentBoostChip({required this.multiplier});

  @override
  Widget build(BuildContext context) {
    final pct = ((multiplier - 1) * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF00695C)),
          const SizedBox(width: 4),
          Text(
            '영구 배율 +$pct%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00695C),
            ),
          ),
        ],
      ),
    );
  }
}
