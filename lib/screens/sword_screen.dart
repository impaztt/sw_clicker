import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/sword_catalog.dart';
import '../models/sword.dart';
import '../providers/game_provider.dart';
import '../widgets/summon_dialog.dart';
import '../widgets/sword_preview.dart';

class SwordScreen extends ConsumerStatefulWidget {
  const SwordScreen({super.key});

  @override
  ConsumerState<SwordScreen> createState() => _SwordScreenState();
}

class _SwordScreenState extends ConsumerState<SwordScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _HeaderBar(),
            const SizedBox(height: 8),
            const TabBar(
              labelColor: AppColors.deepCoral,
              unselectedLabelColor: Colors.black45,
              indicatorColor: AppColors.coral,
              labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              tabs: [
                Tab(text: '수집'),
                Tab(text: '소환'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _CollectionView(),
                  _SummonView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends ConsumerWidget {
  const _HeaderBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final essence = ref.watch(gameProvider).essence;
    final owned = ref.watch(gameProvider).ownedSwords.length;
    final total = swordCatalog.length;
    final bonus = ref.read(gameProvider.notifier).collectionBonusFraction;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon: Icons.diamond,
                  color: const Color(0xFF7C4DFF),
                  label: '정수',
                  value: '$essence',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoChip(
                  icon: Icons.collections_bookmark,
                  color: AppColors.deepCoral,
                  label: '수집',
                  value: '$owned / $total',
                ),
              ),
            ],
          ),
          if (bonus > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFAB47BC).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFAB47BC).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: Color(0xFF6A1B9A), size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '수집 보너스 — 모든 보유 검이 터치·DPS에 +${(bonus * 100).toStringAsFixed(bonus >= 1 ? 0 : 1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6A1B9A),
                        ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionView extends ConsumerWidget {
  const _CollectionView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    // Sort: owned first (by tier desc), then locked (by tier desc).
    final sorted = [...swordCatalog]..sort((a, b) {
        final aOwned = game.ownsSword(a.id);
        final bOwned = game.ownsSword(b.id);
        if (aOwned != bOwned) return aOwned ? -1 : 1;
        return b.tier.index.compareTo(a.tier.index);
      });
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.7,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final def = sorted[i];
        final level = game.swordLevel(def.id);
        final owned = level > 0;
        final equipped = game.equippedSwordId == def.id;
        return _SwordCard(
          def: def,
          level: level,
          owned: owned,
          equipped: equipped,
          onTap: () => _showDetail(context, ref, def),
        );
      },
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref, SwordDef def) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SwordDetailSheet(def: def),
    );
  }
}

class _SwordCard extends StatelessWidget {
  final SwordDef def;
  final int level;
  final bool owned;
  final bool equipped;
  final VoidCallback onTap;

  const _SwordCard({
    required this.def,
    required this.level,
    required this.owned,
    required this.equipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: equipped
                  ? AppColors.coral
                  : def.tier.color.withValues(alpha: 0.4),
              width: equipped ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: def.tier.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  def.tier.label,
                  style: TextStyle(
                    color: def.tier.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: SwordPreview(
                  visual: def.visual,
                  locked: !owned,
                  size: 52,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                owned ? def.name : '???',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: owned
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                ),
              ),
              if (owned)
                Text(
                  equipped ? '장착 · L$level' : 'L$level',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: equipped ? AppColors.coral : Colors.black54,
                  ),
                )
              else
                const Text(
                  '미획득',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.black38,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwordDetailSheet extends ConsumerWidget {
  final SwordDef def;
  const _SwordDetailSheet({required this.def});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final level = game.swordLevel(def.id);
    final owned = level > 0;
    final equipped = game.equippedSwordId == def.id;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SwordPreview(visual: def.visual, locked: !owned, size: 90),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: def.tier.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${def.tier.label} · ${def.tier.korLabel}',
                        style: TextStyle(
                          color: def.tier.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      owned ? def.name : '???',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      owned ? def.description : '소환해서 정보를 확인하세요',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (owned) ...[
            _StatRow(
              label: '장착 시 터치 배율',
              value: '×${def.tapMultAt(level).toStringAsFixed(2)}',
              sub: level < SwordDef.maxLevel
                  ? '최대 Lv ${SwordDef.maxLevel}: ×${def.tapMultAt(SwordDef.maxLevel).toStringAsFixed(2)}'
                  : '최대 레벨 달성',
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: '장착 시 DPS 배율',
              value: '×${def.dpsMultAt(level).toStringAsFixed(2)}',
              sub: level < SwordDef.maxLevel
                  ? '최대 Lv ${SwordDef.maxLevel}: ×${def.dpsMultAt(SwordDef.maxLevel).toStringAsFixed(2)}'
                  : '최대 레벨 달성',
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: '보유 효과 (장착 안해도 적용)',
              value: '+${(def.ownedBonusAt(level) * 100).toStringAsFixed(2)}%',
              sub: level < SwordDef.maxLevel
                  ? '최대 Lv ${SwordDef.maxLevel}: +${(def.ownedBonusAt(SwordDef.maxLevel) * 100).toStringAsFixed(2)}% (터치·DPS 모두)'
                  : '터치·DPS 모두 적용',
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: '레벨',
              value: 'Lv $level / ${SwordDef.maxLevel}',
              sub: level < SwordDef.maxLevel
                  ? '중복 획득 시 자동 레벨업'
                  : '',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: equipped
                  ? null
                  : () {
                      ref.read(gameProvider.notifier).equipSword(def.id);
                      Navigator.of(context).pop();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                minimumSize: const Size.fromHeight(50),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: Text(
                equipped ? '장착 중' : '장착하기',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _DismantleButton(def: def, level: level, equipped: equipped),
          ] else ...[
            _StatRow(
              label: '장착 시 터치 배율',
              value: '?',
              sub: '소환 후 표시',
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: '장착 시 DPS 배율',
              value: '?',
              sub: '소환 후 표시',
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: '보유 효과',
              value: '+${(def.tier.ownedBonusBase * 100).toStringAsFixed(2)}%',
              sub: '획득 즉시 터치·DPS에 적용 (Lv 1 기준)',
            ),
          ],
        ],
      ),
    );
  }
}

class _DismantleButton extends ConsumerWidget {
  final SwordDef def;
  final int level;
  final bool equipped;
  const _DismantleButton({
    required this.def,
    required this.level,
    required this.equipped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final refund = notifier.dismantleRefund(def.id);
    final disabled = equipped || refund <= 0;
    final hint = equipped
        ? '장착 중인 검은 분해할 수 없어요'
        : '분해 시 정수 +$refund (Lv $level 기준)';
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: disabled ? null : () => _confirm(context, ref, refund),
          icon: const Icon(Icons.recycling, size: 18),
          label: Text('분해 (+$refund 정수)'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            foregroundColor: const Color(0xFF7C4DFF),
            side: BorderSide(
              color: disabled
                  ? Colors.grey.shade400
                  : const Color(0xFF7C4DFF).withValues(alpha: 0.6),
              width: 1.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: TextStyle(
            fontSize: 11,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(
      BuildContext context, WidgetRef ref, int refund) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${def.name} 분해'),
        content: Text(
          '이 검은 컬렉션에서 영구 제거되고, 정수 +$refund 가 지급돼요.\n'
          '되돌릴 수 없어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
            ),
            child: const Text('분해'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final granted = ref.read(gameProvider.notifier).dismantleSword(def.id);
    if (granted > 0 && context.mounted) {
      Navigator.of(context).pop(); // close detail sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${def.name} 분해 · 정수 +$granted'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _StatRow({
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.deepCoral,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummonView extends ConsumerWidget {
  const _SummonView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final pityRemaining = pityThreshold - game.summonsSinceHighRare;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.coral.withValues(alpha: 0.85),
                  const Color(0xFF7C4DFF).withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '검을 소환하여 수집하세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '중복 획득은 자동 레벨업 (최대 Lv ${SwordDef.maxLevel})',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '천장 — $pityThreshold회 내에 SR+ 미획득 시 다음 소환 확정',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '남은 회차: $pityRemaining회',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SummonButton(
            label: '1연 소환',
            cost: summonCostSingle,
            essence: game.essence,
            primary: false,
            onTap: () async {
              final r = notifier.summonOne();
              if (r != null) {
                await showSummonDialog(context, [r]);
              }
            },
          ),
          const SizedBox(height: 10),
          _SummonButton(
            label: '10연 소환 (마지막 R+ 확정)',
            cost: summonCostTen,
            essence: game.essence,
            primary: true,
            onTap: () async {
              final r = notifier.summonTen();
              if (r != null) {
                await showSummonDialog(context, r);
              }
            },
          ),
          const SizedBox(height: 20),
          const _RateTable(),
          const SizedBox(height: 20),
          _EssenceSources(),
        ],
      ),
    );
  }
}

class _SummonButton extends StatelessWidget {
  final String label;
  final int cost;
  final int essence;
  final bool primary;
  final VoidCallback onTap;

  const _SummonButton({
    required this.label,
    required this.cost,
    required this.essence,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = essence >= cost;
    final bg = enabled
        ? (primary ? AppColors.coral : Colors.white)
        : Colors.grey.shade300;
    final fg = enabled
        ? (primary ? Colors.white : AppColors.deepCoral)
        : Colors.grey.shade600;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: primary
                ? null
                : Border.all(color: AppColors.coral.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.diamond, color: fg, size: 18),
              const SizedBox(width: 4),
              Text(
                '$cost',
                style: TextStyle(
                  color: fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RateTable extends StatelessWidget {
  const _RateTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            '등급별 확률',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          for (final tier in SwordTier.values.reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tier.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tier.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: tier.color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tier.korLabel,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '${tier.rate.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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

class _EssenceSources extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            '정수 획득처',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          const _SourceRow(
            icon: Icons.upgrade,
            text: '동료 Lv 25 / 50 / 100 / 200 달성 시',
          ),
          const _SourceRow(
            icon: Icons.auto_awesome,
            text: '환생 시 (획득 소울 × 3)',
          ),
          const _SourceRow(
            icon: Icons.calendar_month,
            text: '일일 출석 보너스 (5~60 정수)',
          ),
          const _SourceRow(
            icon: Icons.emoji_events,
            text: '업적 해제 시',
          ),
          const _SourceRow(
            icon: Icons.recycling,
            text: '검 분해 시 (등급·레벨에 비례)',
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SourceRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.coral),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
