import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_provider.dart';
import '../widgets/daily_bonus_dialog.dart';
import '../widgets/offline_reward_dialog.dart';
import 'home_screen.dart';
import 'prestige_screen.dart';
import 'settings_screen.dart';
import 'sword_screen.dart';
import 'upgrade_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _index = 0;
  bool _bootDialogsShown = false;

  static const _pages = <Widget>[
    HomeScreen(),
    UpgradeScreen(),
    SwordScreen(),
    PrestigeScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    if (game.loaded && !_bootDialogsShown) {
      _bootDialogsShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _runBootDialogs());
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.upgrade_outlined),
            selectedIcon: Icon(Icons.upgrade_rounded),
            label: '강화',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_outlined),
            selectedIcon: Icon(Icons.collections),
            label: '검',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '환생',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: '설정',
          ),
        ],
      ),
    );
  }

  Future<void> _runBootDialogs() async {
    // Offline reward first (time-sensitive context from lastSavedAt), then
    // daily bonus. Both are shown sequentially so the user can't miss one.
    final notifier = ref.read(gameProvider.notifier);
    final offline = notifier.consumeOfflineReward();
    if (offline != null && mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => OfflineRewardDialog(reward: offline),
      );
    }
    final daily = notifier.consumePendingDaily();
    if (daily != null && mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DailyBonusDialog(bonus: daily),
      );
    }
  }
}
