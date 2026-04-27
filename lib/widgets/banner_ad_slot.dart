import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ad_config.dart';
import '../providers/game_provider.dart';

/// Adaptive AdMob banner anchored at the bottom of the home screen. Self-
/// hides when:
///   • the player owns the ad-removal IAP, OR
///   • the platform doesn't support google_mobile_ads (web, desktop), OR
///   • the underlying ad request fails to load.
class BannerAdSlot extends ConsumerStatefulWidget {
  const BannerAdSlot({super.key});

  @override
  ConsumerState<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends ConsumerState<BannerAdSlot> {
  BannerAd? _ad;
  bool _failed = false;

  bool get _platformSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (_platformSupported) _load();
  }

  void _load() {
    final ad = BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (a, err) {
          a.dispose();
          if (mounted) setState(() => _failed = true);
          debugPrint('[BannerAdSlot] failed: $err');
        },
      ),
    )..load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_platformSupported || _failed) return const SizedBox.shrink();
    final adsRemoved = ref.watch(
      gameProvider.select((s) => s.adsRemoved),
    );
    if (adsRemoved) return const SizedBox.shrink();

    final ad = _ad;
    if (ad == null) {
      return const SizedBox(height: 50);
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
