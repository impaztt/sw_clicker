import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/ad_config.dart';

/// Centralized AdMob façade. Only this class talks to google_mobile_ads;
/// everything else asks the service to "show me a rewarded for X" so we
/// can cap frequency, gate by purchase state, and swap stubs in tests.
///
/// Boot order:
///   1. Call [AdService.instance.initialize()] from main() before runApp.
///   2. Set [AdService.instance.adsRemoved] whenever the IAP flag changes
///      (e.g. on save load and after a purchase).
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;
  bool _adsRemoved = false;
  DateTime? _lastInterstitialAt;
  DateTime? _lastPurchaseAt;
  int _interstitialDayKey = 0;
  int _interstitialShownToday = 0;

  InterstitialAd? _interstitialCache;
  RewardedAd? _rewardedCache;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;

  /// True once Mobile Ads SDK init has completed. UI should hold off
  /// requesting ads until this flips.
  bool get isInitialized => _initialized;

  bool get adsRemoved => _adsRemoved;
  set adsRemoved(bool value) {
    _adsRemoved = value;
    if (value) {
      _interstitialCache?.dispose();
      _interstitialCache = null;
    }
  }

  /// Tell the service that the player just made an IAP purchase. We use
  /// this to suppress interstitials for the configured grace window.
  void recordPurchase() {
    _lastPurchaseAt = DateTime.now();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      if (AdConfig.testDeviceIds.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: AdConfig.testDeviceIds),
        );
      }
      _initialized = true;
      _preloadInterstitial();
      _preloadRewarded();
    } catch (e, st) {
      debugPrint('[AdService] init failed: $e\n$st');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Interstitial
  // ─────────────────────────────────────────────────────────────────────────

  void _preloadInterstitial() {
    if (_adsRemoved || _loadingInterstitial || _interstitialCache != null) {
      return;
    }
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialCache = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (err) {
          _loadingInterstitial = false;
          debugPrint('[AdService] interstitial load failed: $err');
        },
      ),
    );
  }

  /// Try to show an interstitial. Returns true only if the ad actually
  /// reached the screen (i.e. wasn't suppressed by purchase grace, daily
  /// ceiling, frequency cap, or load failure).
  Future<bool> showInterstitial({String? trigger}) async {
    if (_adsRemoved) return false;
    if (!_initialized) return false;

    final now = DateTime.now();
    final purchaseGraceUntil = _lastPurchaseAt
        ?.add(AdConfig.interstitialPurchaseGrace);
    if (purchaseGraceUntil != null && now.isBefore(purchaseGraceUntil)) {
      return false;
    }

    final today = _dayKey(now);
    if (_interstitialDayKey != today) {
      _interstitialDayKey = today;
      _interstitialShownToday = 0;
    }
    if (_interstitialShownToday >= AdConfig.interstitialDailyCeiling) {
      return false;
    }
    if (_lastInterstitialAt != null &&
        now.difference(_lastInterstitialAt!) < AdConfig.interstitialMinGap) {
      return false;
    }

    final ad = _interstitialCache;
    if (ad == null) {
      _preloadInterstitial();
      return false;
    }
    _interstitialCache = null;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _lastInterstitialAt = DateTime.now();
        _interstitialShownToday++;
      },
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _preloadInterstitial();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        _preloadInterstitial();
        debugPrint('[AdService] interstitial show failed: $err');
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    try {
      await ad.show();
    } catch (e) {
      _preloadInterstitial();
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Rewarded
  // ─────────────────────────────────────────────────────────────────────────

  void _preloadRewarded() {
    if (_loadingRewarded || _rewardedCache != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedCache = ad;
          _loadingRewarded = false;
        },
        onAdFailedToLoad: (err) {
          _loadingRewarded = false;
          debugPrint('[AdService] rewarded load failed: $err');
        },
      ),
    );
  }

  /// Show a rewarded ad. The returned future resolves with `true` if the
  /// user finished watching and earned the reward, `false` otherwise (load
  /// fail, dismiss, etc.). Rewarded ads are NOT suppressed by adsRemoved
  /// because the player opted in for the reward.
  Future<bool> showRewarded({String? trigger}) async {
    if (!_initialized) return false;
    final ad = _rewardedCache;
    if (ad == null) {
      _preloadRewarded();
      return false;
    }
    _rewardedCache = null;
    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _preloadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        _preloadRewarded();
        debugPrint('[AdService] rewarded show failed: $err');
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, __) => earned = true);
    } catch (e) {
      _preloadRewarded();
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future;
  }

  /// Probe whether a rewarded ad is ready to show right now. UI uses this
  /// to grey the "watch ad" button during a load gap.
  bool get rewardedReady => _initialized && _rewardedCache != null;

  // ─────────────────────────────────────────────────────────────────────────

  int _dayKey(DateTime t) => t.year * 10000 + t.month * 100 + t.day;
}
