import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../data/producer_catalog.dart';
import '../data/prestige_upgrade_catalog.dart';
import '../models/producer.dart';
import '../models/prestige_upgrade.dart';
import '../providers/game_provider.dart';

class PrestigeScreen extends ConsumerWidget {
  const PrestigeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '환생',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              '현재 회차를 리셋하고 영구 재화를 얻어, 영구 성장을 진행하세요.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: AppColors.deepCoral,
                    unselectedLabelColor: Colors.black45,
                    indicatorColor: AppColors.coral,
                    tabs: [
                      Tab(text: '환생'),
                      Tab(text: '코인 상점'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _PrestigeOverview(),
                        _PrestigeShop(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrestigeOverview extends ConsumerWidget {
  const _PrestigeOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final coinsGain = game.prestigeCoinsAvailable;
    final canPrestige = coinsGain > 0;
    final currentPct = ((game.prestigeMultiplier - 1) * 100).toStringAsFixed(0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _StatCard(
          icon: Icons.auto_awesome,
          iconColor: const Color(0xFF00695C),
          label: '현재 영구 배율',
          value: '+$currentPct%',
          subValue: '코인 상점의 영구 각인 업그레이드로 증가합니다',
        ),
        const SizedBox(height: 10),
        _StatCard(
          icon: Icons.currency_exchange,
          iconColor: const Color(0xFF7C4DFF),
          label: '환생 코인 보유량',
          value: '${game.prestigeCoins}',
          subValue: '코인 상점에서만 사용 가능한 영구 재화',
        ),
        const SizedBox(height: 10),
        _StatCard(
          icon: Icons.trending_up,
          iconColor: AppColors.deepCoral,
          label: '지금 환생 시 획득',
          value: '+$coinsGain 코인',
          subValue: canPrestige
              ? '환생 후 코인 상점에서 영구 성장을 구매할 수 있습니다'
              : '골드와 진행도를 더 올리면 보상이 증가합니다',
        ),
        const SizedBox(height: 10),
        _StatCard(
          icon: Icons.history_toggle_off,
          iconColor: AppColors.mint,
          label: '현재 회차 진행도',
          value: '환생 횟수 ${game.prestigeCount}',
          subValue: '현재 회차 골드 ${NumberFormatter.format(game.totalGoldEarned)}',
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: canPrestige
              ? () => _confirmPrestige(
                    context,
                    ref,
                    coinsGain: coinsGain,
                  )
              : null,
          style: FilledButton.styleFrom(
            backgroundColor:
                canPrestige ? AppColors.coral : Colors.grey.shade300,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
          ),
          child: Text(
            canPrestige ? '환생하기 (+$coinsGain 코인)' : '아직 보상이 부족합니다',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '환생 시 현재 회차 골드와 업그레이드는 초기화되지만,\n환생 코인과 코인 상점 업그레이드는 유지됩니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmPrestige(
    BuildContext context,
    WidgetRef ref, {
    required int coinsGain,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('환생 확인'),
        content: Text(
          '환생 코인 +$coinsGain 을 획득합니다.\n'
          '획득한 코인으로 영구 각인/영구 업그레이드를 구매할 수 있습니다.\n\n'
          '현재 회차 골드와 업그레이드는 초기화됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            child: const Text('환생'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = ref.read(gameProvider.notifier).prestige();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('환생 보상이 아직 0입니다. 더 진행한 뒤 시도해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _PrestigeShop extends ConsumerWidget {
  const _PrestigeShop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    var maxTranscendentLevel = 0;
    for (final def in producerCatalog) {
      if (def.category != ProducerCategory.transcendent) continue;
      final lv = game.producerLevels[def.id] ?? 0;
      if (lv > maxTranscendentLevel) maxTranscendentLevel = lv;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _StatCard(
          icon: Icons.currency_exchange,
          iconColor: const Color(0xFF7C4DFF),
          label: '환생 코인',
          value: '${game.prestigeCoins}',
          subValue: '코인 상점에서 영구 업그레이드를 구매할 수 있습니다',
        ),
        const SizedBox(height: 10),
        _AscensionCoreCard(
          level: game.ascensionCoreLevel,
          unlocked: game.ascensionCoreUnlocked,
          currentMult: game.ascensionCoreMultiplier,
          nextCost: game.ascensionCoreNextCost,
          coins: game.prestigeCoins,
          prestigeCount: game.prestigeCount,
          maxTranscendentLevel: maxTranscendentLevel,
          onBuy: notifier.buyAscensionCore,
        ),
        const SizedBox(height: 10),
        for (final def in prestigeUpgradeCatalog) ...[
          _ShopTile(
            def: def,
            level: game.prestigeUpgradeLevel(def.id),
            coins: game.prestigeCoins,
            onBuy: () => notifier.buyPrestigeUpgrade(def.id),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AscensionCoreCard extends StatelessWidget {
  final int level;
  final bool unlocked;
  final double currentMult;
  final int nextCost;
  final int coins;
  final int prestigeCount;
  final int maxTranscendentLevel;
  final bool Function() onBuy;
  const _AscensionCoreCard({
    required this.level,
    required this.unlocked,
    required this.currentMult,
    required this.nextCost,
    required this.coins,
    required this.prestigeCount,
    required this.maxTranscendentLevel,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final canBuy = unlocked && coins >= nextCost;
    final prestigeRemaining = (5 - prestigeCount).clamp(0, 5);
    final transcendentRemaining = (25 - maxTranscendentLevel).clamp(0, 25);
    final pct = ((currentMult - 1) * 100).toStringAsFixed(1);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: unlocked
            ? null
            : () => _showLockedHint(
                  context,
                  prestigeRemaining: prestigeRemaining,
                  transcendentRemaining: transcendentRemaining,
                ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F8FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF90CAF9), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_graph, color: Color(0xFF1565C0)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '초월 코어 연구 (중후반 루프)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                unlocked
                    ? 'Lv $level · 전체 수익 영구 +$pct%'
                    : '해금 조건: 환생 5회 + 초월 유닛 중 하나 Lv 25',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.72),
                ),
              ),
              if (!unlocked) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _UnlockRequirementChip(
                      label: '환생',
                      value: '$prestigeCount / 5',
                      done: prestigeRemaining == 0,
                    ),
                    _UnlockRequirementChip(
                      label: '초월 최고',
                      value: 'Lv $maxTranscendentLevel / 25',
                      done: transcendentRemaining == 0,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: unlocked
                      ? (canBuy
                          ? () {
                              final ok = onBuy();
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('조건 미달 또는 코인이 부족합니다'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('환생 코인이 부족합니다'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            })
                      : () => _showLockedHint(
                            context,
                            prestigeRemaining: prestigeRemaining,
                            transcendentRemaining: transcendentRemaining,
                          ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        canBuy ? const Color(0xFF1976D2) : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    unlocked
                        ? '연구 업그레이드 (${NumberFormatter.format(nextCost.toDouble())} 코인)'
                        : '아직 잠겨 있음',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLockedHint(
    BuildContext context, {
    required int prestigeRemaining,
    required int transcendentRemaining,
  }) {
    final remain = <String>[];
    if (prestigeRemaining > 0) remain.add('환생 ${prestigeRemaining}회');
    if (transcendentRemaining > 0) remain.add('초월 ${transcendentRemaining}레벨');
    final remainText = remain.isEmpty ? '곧 해금됩니다.' : '남은 조건: ${remain.join(' · ')}';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '초월 코어는 환생 5회 + 초월 유닛 Lv 25에서 해금됩니다.\n'
            '현재 진행: 환생 $prestigeCount/5 · 초월 최고 Lv $maxTranscendentLevel/25\n'
            '$remainText',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}

class _UnlockRequirementChip extends StatelessWidget {
  final String label;
  final String value;
  final bool done;
  const _UnlockRequirementChip({
    required this.label,
    required this.value,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final bg = done
        ? AppColors.mint.withValues(alpha: 0.24)
        : Colors.black.withValues(alpha: 0.05);
    final fg = done ? const Color(0xFF00695C) : Colors.black.withValues(alpha: 0.72);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: done
              ? AppColors.mint.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  final PrestigeUpgradeDef def;
  final int level;
  final int coins;
  final bool Function() onBuy;

  const _ShopTile({
    required this.def,
    required this.level,
    required this.coins,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final atMax = level >= def.maxLevel;
    final cost = atMax ? 0 : def.costAt(level);
    final canBuy = !atMax && coins >= cost;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: def.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(def.icon, color: def.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      def.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '레벨 $level / ${def.maxLevel}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00695C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '현재 효과: ${_effectLabel(def, level)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00695C),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            atMax ? '최대 레벨입니다' : '다음 효과: ${_effectLabel(def, level + 1)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canBuy
                  ? () {
                      final ok = onBuy();
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('환생 코인이 부족합니다'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor:
                    canBuy ? AppColors.coral : Colors.grey.shade300,
                foregroundColor: Colors.white,
              ),
              child: Text(
                atMax ? '최대' : '구매 ($cost 코인)',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _effectLabel(PrestigeUpgradeDef def, int level) {
    final clamped = level.clamp(0, def.maxLevel);
    final parts = <String>[];
    if (def.globalBonusPerLevel > 0) {
      final pct = (def.globalBonusPerLevel * clamped * 100).toStringAsFixed(0);
      parts.add('전체 +$pct%');
    }
    if (def.tapBonusPerLevel > 0) {
      final pct = (def.tapBonusPerLevel * clamped * 100).toStringAsFixed(0);
      parts.add('터치 +$pct%');
    }
    if (def.dpsBonusPerLevel > 0) {
      final pct = (def.dpsBonusPerLevel * clamped * 100).toStringAsFixed(0);
      parts.add('DPS +$pct%');
    }
    if (def.coinGainBonusPerLevel > 0) {
      final pct =
          (def.coinGainBonusPerLevel * clamped * 100).toStringAsFixed(0);
      parts.add('코인 획득 +$pct%');
    }
    if (parts.isEmpty) return '-';
    return parts.join(' / ');
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subValue;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subValue,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00695C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
