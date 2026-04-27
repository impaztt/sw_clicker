import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'providers/game_provider.dart';
import 'screens/main_screen.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';
import 'widgets/achievement_toast.dart';
import 'widgets/feature_unlock_toast.dart';
import 'widgets/first_purchase_popup.dart';
import 'widgets/main_sword_event_host.dart';

class SwClickerApp extends ConsumerStatefulWidget {
  const SwClickerApp({super.key});

  @override
  ConsumerState<SwClickerApp> createState() => _SwClickerAppState();
}

class _SwClickerAppState extends ConsumerState<SwClickerApp>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

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
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt = DateTime.now();
      // Awaiting here doesn't block Flutter's lifecycle dispatch, but it does
      // schedule the local-write continuation immediately so SharedPreferences
      // gets a chance to flush before a force-kill.
      await ref.read(gameProvider.notifier).persist();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      _backgroundedAt = null;
      // Resume interstitial: show only after the player was away long
      // enough that an ad here doesn't feel like punishment for a quick
      // tab-switch. AdService still applies its frequency cap.
      if (since != null &&
          DateTime.now().difference(since) >= const Duration(seconds: 60)) {
        unawaited(
            AdService.instance.showInterstitial(trigger: 'app_resume'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sound = ref.watch(gameProvider.select((s) => s.sound));
    AudioService.instance.setEnabled(sound);

    final darkMode = ref.watch(gameProvider.select((s) => s.darkMode));
    final highContrast = ref.watch(gameProvider.select((s) => s.highContrast));
    final textScale = ref.watch(gameProvider.select((s) => s.textScale));

    return MaterialApp(
      title: '검 키우기',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(highContrast: highContrast),
      darkTheme: buildDarkTheme(highContrast: highContrast),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: AchievementToastHost(
            child: FeatureUnlockToastHost(
              child: MainSwordEventHost(
                child: FirstPurchasePopupHost(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
      home: const MainScreen(),
    );
  }
}
