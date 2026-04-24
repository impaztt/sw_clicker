import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../widgets/dps_display.dart';
import '../widgets/floating_number.dart';
import '../widgets/gold_display.dart';
import '../widgets/sword_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<FloatingNumberData> _floats = [];
  int _nextId = 0;

  void _handleTap(Offset globalPos) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPos);
    final amount = ref.read(gameProvider.notifier).tap();
    final state = ref.read(gameProvider);
    if (state.haptic) HapticFeedback.lightImpact();
    if (state.sound) AudioService.instance.playTap();
    setState(() {
      _floats.add(FloatingNumberData(
        id: _nextId++,
        origin: local,
        amount: amount,
      ));
    });
  }

  void _removeFloat(int id) {
    if (!mounted) return;
    setState(() => _floats.removeWhere((f) => f.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);

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
              _TapPowerChip(tapPower: game.tapPower),
              if (game.prestigeSouls > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _SoulChip(
                    souls: game.prestigeSouls,
                    multiplier: game.prestigeMultiplier,
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
          FloatingNumberLayer(items: _floats, onDone: _removeFloat),
        ],
      ),
    );
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

class _SoulChip extends StatelessWidget {
  final int souls;
  final double multiplier;
  const _SoulChip({required this.souls, required this.multiplier});

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
            '검의 혼 $souls · +$pct%',
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
