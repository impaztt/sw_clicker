import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../data/main_sword_enhancement.dart';
import '../data/main_sword_evolution.dart';
import '../providers/game_provider.dart';
import 'main_sword_widget.dart';

/// Full-screen-ish dialog that lets the player enhance the home-tab main
/// sword. Shows the current stage's preview, the next stage's preview,
/// and three currency tracks (gold / essence / hybrid) with their
/// individual costs and success rates.
class MainSwordEnhanceDialog extends ConsumerStatefulWidget {
  const MainSwordEnhanceDialog({super.key});

  @override
  ConsumerState<MainSwordEnhanceDialog> createState() =>
      _MainSwordEnhanceDialogState();
}

class _MainSwordEnhanceDialogState
    extends ConsumerState<MainSwordEnhanceDialog> {
  MainSwordBoostLevel _boost = MainSwordBoostLevel.none;
  bool _useProtection = false;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final stage = game.mainSwordStage;
    final atMax = stage >= mainSwordEnhanceMaxStage;
    final targetStage = atMax ? stage : stage + 1;
    final cost = mainSwordEnhanceCost(targetStage);
    final tierCurrent = mainSwordTierFor(stage);
    final tierNext = mainSwordTierFor(targetStage);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 720, maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                name: game.mainSwordName ?? '이름 없는 검',
                stage: stage,
                tierLabel: tierCurrent.name,
                essence: game.essence,
              ),
              const SizedBox(height: 14),
              _StagePreview(stage: stage, targetStage: targetStage),
              if (!atMax) ...[
                const SizedBox(height: 12),
                Text(
                  '다음: +$targetStage (${tierNext.name})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _GoldTrackSection(
                        cost: cost,
                        boost: _boost,
                        useProtection: _useProtection,
                        gold: game.gold,
                        essence: game.essence,
                        onBoostChanged: (b) => setState(() => _boost = b),
                        onProtectionChanged: (v) =>
                            setState(() => _useProtection = v),
                        onTry: () => _attempt(
                            MainSwordEnhanceCurrency.gold, notifier),
                      ),
                      const SizedBox(height: 10),
                      _EssenceTrackSection(
                        cost: cost,
                        essence: game.essence,
                        onTry: () => _attempt(
                            MainSwordEnhanceCurrency.essence, notifier),
                      ),
                      const SizedBox(height: 10),
                      _HybridTrackSection(
                        cost: cost,
                        gold: game.gold,
                        essence: game.essence,
                        onTry: () => _attempt(
                            MainSwordEnhanceCurrency.hybrid, notifier),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '실패 시 단계 손실: ${cost.penaltyOnFail}강 (정수·하이브리드는 보존)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '+50 단계 도달! 강화는 여기까지입니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _attempt(
    MainSwordEnhanceCurrency currency,
    GameNotifier notifier,
  ) async {
    final result = notifier.attemptMainSwordEnhance(
      currency: currency,
      boostLevel:
          currency == MainSwordEnhanceCurrency.gold ? _boost : MainSwordBoostLevel.none,
      useProtection:
          currency == MainSwordEnhanceCurrency.gold && _useProtection,
    );
    if (!mounted) return;
    if (!result.ok) {
      _toast(_failureLabel(result.reason));
      return;
    }
    if (result.success) {
      _toast('성공! +${result.newStage} 단계 진입');
    } else if (result.penaltyApplied > 0) {
      _toast('실패 — ${result.penaltyApplied}강 손실 (+${result.newStage})');
    } else {
      _toast('실패 — 단계 보존');
    }
    // Reset transient toggles after a successful attempt so the next try
    // starts fresh and the player isn't surprised by stale boost essence
    // costs.
    if (result.success) {
      setState(() {
        _boost = MainSwordBoostLevel.none;
        _useProtection = false;
      });
    }
  }

  void _toast(String msg) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _failureLabel(MainSwordEnhanceFailure r) => switch (r) {
        MainSwordEnhanceFailure.notEnoughGold => '골드가 부족해요',
        MainSwordEnhanceFailure.notEnoughEssence => '정수가 부족해요',
        MainSwordEnhanceFailure.alreadyMaxed => '이미 최대 단계입니다',
        MainSwordEnhanceFailure.rolledFailure ||
        MainSwordEnhanceFailure.none =>
          '',
      };
}

class _Header extends StatelessWidget {
  final String name;
  final int stage;
  final String tierLabel;
  final int essence;
  const _Header({
    required this.name,
    required this.stage,
    required this.tierLabel,
    required this.essence,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.auto_fix_high,
            color: AppColors.deepCoral, size: 22),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$tierLabel · +$stage 단계',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.diamond, color: Colors.teal.shade700, size: 18),
        const SizedBox(width: 4),
        Text(
          '$essence',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.teal.shade700,
          ),
        ),
      ],
    );
  }
}

class _StagePreview extends StatelessWidget {
  final int stage;
  final int targetStage;
  const _StagePreview({required this.stage, required this.targetStage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Row(
        children: [
          Expanded(
            child: _SwordPreviewCard(
              label: '현재',
              stage: stage,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward,
              color: AppColors.deepCoral, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: _SwordPreviewCard(
              label: '다음',
              stage: targetStage,
              highlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwordPreviewCard extends StatelessWidget {
  final String label;
  final int stage;
  final bool highlight;
  const _SwordPreviewCard({
    required this.label,
    required this.stage,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppColors.coral.withValues(alpha: 0.6)
              : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          Text(
            '$label +$stage',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: highlight
                  ? AppColors.deepCoral
                  : Colors.black.withValues(alpha: 0.55),
            ),
          ),
          Expanded(
            child: MainSwordWidget(
              stage: stage,
              size: 88,
              onTap: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldTrackSection extends StatelessWidget {
  final MainSwordEnhanceCost cost;
  final MainSwordBoostLevel boost;
  final bool useProtection;
  final double gold;
  final int essence;
  final ValueChanged<MainSwordBoostLevel> onBoostChanged;
  final ValueChanged<bool> onProtectionChanged;
  final VoidCallback onTry;

  const _GoldTrackSection({
    required this.cost,
    required this.boost,
    required this.useProtection,
    required this.gold,
    required this.essence,
    required this.onBoostChanged,
    required this.onProtectionChanged,
    required this.onTry,
  });

  @override
  Widget build(BuildContext context) {
    final boostBonus = boost.successBonus;
    final finalRate = (cost.goldSuccessBase + boostBonus).clamp(0.0, 1.0);
    final extraEssence =
        boost.essenceCost + (useProtection ? mainSwordProtectionEssenceCost : 0);
    final canAfford = gold >= cost.goldCost && essence >= extraEssence;
    return _TrackContainer(
      title: '🟡 골드로 시도',
      lines: [
        '비용: ${NumberFormatter.format(cost.goldCost)} 골드'
            '${extraEssence > 0 ? ' + 정수 $extraEssence' : ''}',
        '성공률: ${(finalRate * 100).toStringAsFixed(0)}%',
        '실패 시: ${useProtection ? '단계 보존' : '−${cost.penaltyOnFail}강'}',
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final b in MainSwordBoostLevel.values)
                _Chip(
                  label: b.label,
                  selected: boost == b,
                  onTap: () => onBoostChanged(b),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Checkbox(
                value: useProtection,
                onChanged: (v) => onProtectionChanged(v ?? false),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Expanded(
                child: Text(
                  '보호권 (정수 $mainSwordProtectionEssenceCost) — 실패해도 단계 유지',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FilledButton(
            onPressed: canAfford ? onTry : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              minimumSize: const Size.fromHeight(40),
            ),
            child: const Text('골드로 강화 시도'),
          ),
        ],
      ),
    );
  }
}

class _EssenceTrackSection extends StatelessWidget {
  final MainSwordEnhanceCost cost;
  final int essence;
  final VoidCallback onTry;
  const _EssenceTrackSection({
    required this.cost,
    required this.essence,
    required this.onTry,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = essence >= cost.essenceCost;
    return _TrackContainer(
      title: '🟣 정수로 시도',
      lines: [
        '비용: 정수 ${cost.essenceCost}',
        '성공률: ${(cost.essenceSuccessBase * 100).toStringAsFixed(0)}% (보정)',
        '실패 시: 단계 보존',
      ],
      child: FilledButton(
        onPressed: canAfford ? onTry : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF7C4DFF),
          minimumSize: const Size.fromHeight(40),
        ),
        child: const Text('정수로 강화 시도'),
      ),
    );
  }
}

class _HybridTrackSection extends StatelessWidget {
  final MainSwordEnhanceCost cost;
  final double gold;
  final int essence;
  final VoidCallback onTry;
  const _HybridTrackSection({
    required this.cost,
    required this.gold,
    required this.essence,
    required this.onTry,
  });

  @override
  Widget build(BuildContext context) {
    final hybridGold = cost.goldCost * mainSwordHybridGoldMultiplier;
    final hybridEssence =
        (cost.essenceCost * mainSwordHybridEssenceMultiplier).round();
    final rate =
        (cost.goldSuccessBase + mainSwordHybridSuccessBonus).clamp(0.0, 1.0);
    final canAfford = gold >= hybridGold && essence >= hybridEssence;
    return _TrackContainer(
      title: '⚡ 하이브리드 (자원 모두 사용)',
      lines: [
        '비용: ${NumberFormatter.format(hybridGold)} 골드 + 정수 $hybridEssence',
        '성공률: ${(rate * 100).toStringAsFixed(0)}%',
        '실패 시: 단계 보존',
      ],
      child: FilledButton(
        onPressed: canAfford ? onTry : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFB300),
          minimumSize: const Size.fromHeight(40),
        ),
        child: const Text('하이브리드 시도'),
      ),
    );
  }
}

class _TrackContainer extends StatelessWidget {
  final String title;
  final List<String> lines;
  final Widget child;
  const _TrackContainer({
    required this.title,
    required this.lines,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                line,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),
            ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.coral.withValues(alpha: 0.85)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.coral : Colors.black26,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
