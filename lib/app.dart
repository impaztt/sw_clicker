import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'providers/game_provider.dart';
import 'screens/main_screen.dart';
import 'services/audio_service.dart';
import 'widgets/achievement_toast.dart';

class SwClickerApp extends ConsumerStatefulWidget {
  const SwClickerApp({super.key});

  @override
  ConsumerState<SwClickerApp> createState() => _SwClickerAppState();
}

class _SwClickerAppState extends ConsumerState<SwClickerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      ref.read(gameProvider.notifier).persist();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sound = ref.watch(gameProvider.select((s) => s.sound));
    AudioService.instance.setEnabled(sound);

    return MaterialApp(
      title: '검 키우기',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) =>
          AchievementToastHost(child: child ?? const SizedBox.shrink()),
      home: const MainScreen(),
    );
  }
}
