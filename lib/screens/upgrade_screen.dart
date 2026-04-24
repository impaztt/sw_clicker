import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../data/producer_catalog.dart';
import '../data/tap_upgrade_catalog.dart';
import '../providers/game_provider.dart';
import '../widgets/dps_display.dart';
import '../widgets/gold_display.dart';
import '../widgets/upgrade_tile.dart';

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final multiplier = ref.watch(buyMultiplierProvider);

    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: GoldDisplay(amount: game.gold)),
                  const SizedBox(width: 12),
                  DpsDisplay(dps: game.dps),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const _BuyMultiplierSelector(),
            const SizedBox(height: 4),
            const TabBar(
              labelColor: AppColors.deepCoral,
              unselectedLabelColor: Colors.black45,
              indicatorColor: AppColors.coral,
              labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              tabs: [
                Tab(text: '터치 강화'),
                Tab(text: '동료'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final def in tapUpgradeCatalog)
                        Builder(builder: (_) {
                          final lv = game.tapUpgradeLevel(def.id);
                          final maxN = def.maxAffordable(game.gold, lv);
                          final isMax = multiplier < 0;
                          final n = isMax ? (maxN > 0 ? maxN : 1) : multiplier;
                          final cost = def.costForNext(lv, n);
                          final affordable = isMax
                              ? maxN > 0
                              : game.canAfford(cost);
                          return UpgradeTile(
                            icon: def.icon,
                            accent: def.accent,
                            name: def.name,
                            description: def.description,
                            level: lv,
                            cost: cost,
                            buyCount: n,
                            gainLabel:
                                '터치당 +${NumberFormatter.formatPrecise(def.tapPowerPerLevel * n)}',
                            affordable: affordable,
                            onBuy: () =>
                                notifier.buyTapUpgrade(def.id, multiplier),
                          );
                        }),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final def in producerCatalog)
                        Builder(builder: (_) {
                          final lv = game.producerLevel(def.id);
                          final maxN = def.maxAffordable(game.gold, lv);
                          final isMax = multiplier < 0;
                          final n = isMax ? (maxN > 0 ? maxN : 1) : multiplier;
                          final cost = def.costForNext(lv, n);
                          final affordable = isMax
                              ? maxN > 0
                              : game.canAfford(cost);
                          final nextMs = def.nextMilestone(lv);
                          final curMult = def.milestoneMultiplier(lv).toInt();
                          final msLabel = nextMs == null
                              ? '마일스톤 완주! (x$curMult DPS)'
                              : '다음 Lv $nextMs → DPS x2 (현재 x$curMult)';
                          return UpgradeTile(
                            icon: def.icon,
                            accent: def.accent,
                            name: def.name,
                            description: def.description,
                            level: lv,
                            cost: cost,
                            buyCount: n,
                            gainLabel:
                                'DPS +${NumberFormatter.formatPrecise(def.baseDps * n * def.milestoneMultiplier(lv))}',
                            milestoneLabel: msLabel,
                            affordable: affordable,
                            onBuy: () =>
                                notifier.buyProducer(def.id, multiplier),
                          );
                        }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyMultiplierSelector extends ConsumerWidget {
  const _BuyMultiplierSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(buyMultiplierProvider);
    const options = <(int, String)>[
      (1, 'x1'),
      (10, 'x10'),
      (100, 'x100'),
      (-1, 'Max'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final opt in options)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _SegmentButton(
                  label: opt.$2,
                  selected: selected == opt.$1,
                  onTap: () => ref.read(buyMultiplierProvider.notifier).state =
                      opt.$1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.coral : Colors.white;
    final fg = selected ? Colors.white : AppColors.deepCoral;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.coral
                  : AppColors.coral.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
