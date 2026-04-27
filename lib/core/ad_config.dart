import 'dart:io' show Platform;

/// AdMob configuration. The default IDs in this file are Google's published
/// test IDs — they always show test ads and never accrue revenue. Swap each
/// `_prod*` value to the real production unit before publishing.
///
/// Test ID reference:
///   https://developers.google.com/admob/android/test-ads
///
/// AndroidManifest.xml also has an `APPLICATION_ID` meta-data tag — keep
/// that synchronized with the Android app ID below when you go live.
class AdConfig {
  // ───────── Android ─────────
  // App ID lives in AndroidManifest.xml, not here. Make sure to update it
  // there too when you swap to production.

  // Test (Google official sample IDs)
  static const _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';

  // ───────── iOS ─────────
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';

  // ───────── Production ─────────
  // TODO(release): replace these with the real ad-unit IDs from your AdMob
  // dashboard. Until then, _useProdAds stays false so the app keeps showing
  // safe test ads in CI/QA.
  static const _prodBannerAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/0000000000';
  static const _prodInterstitialAndroid =
      'ca-app-pub-XXXXXXXXXXXXXXXX/0000000000';
  static const _prodRewardedAndroid =
      'ca-app-pub-XXXXXXXXXXXXXXXX/0000000000';
  static const _prodBannerIos = 'ca-app-pub-XXXXXXXXXXXXXXXX/0000000000';
  static const _prodInterstitialIos =
      'ca-app-pub-XXXXXXXXXXXXXXXX/0000000000';
  static const _prodRewardedIos =
      'ca-app-pub-XXXXXXXXXXXXXXXX/0000000000';

  /// Flip to true on release builds once the prod IDs above are filled in.
  /// Keep false until then so QA never accidentally shows real ads.
  static const bool _useProdAds = false;

  static String get bannerUnitId =>
      _isAndroid ? _bannerAndroid : _bannerIos;
  static String get interstitialUnitId =>
      _isAndroid ? _interstitialAndroid : _interstitialIos;
  static String get rewardedUnitId =>
      _isAndroid ? _rewardedAndroid : _rewardedIos;

  static String get _bannerAndroid =>
      _useProdAds ? _prodBannerAndroid : _testBannerAndroid;
  static String get _interstitialAndroid =>
      _useProdAds ? _prodInterstitialAndroid : _testInterstitialAndroid;
  static String get _rewardedAndroid =>
      _useProdAds ? _prodRewardedAndroid : _testRewardedAndroid;
  static String get _bannerIos =>
      _useProdAds ? _prodBannerIos : _testBannerIos;
  static String get _interstitialIos =>
      _useProdAds ? _prodInterstitialIos : _testInterstitialIos;
  static String get _rewardedIos =>
      _useProdAds ? _prodRewardedIos : _testRewardedIos;

  static bool get _isAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      // dart:io throws on web; treat web like Android for ad-unit lookup
      // (won't actually display ads — google_mobile_ads is mobile-only).
      return true;
    }
  }

  // ───────── Frequency caps (interstitial) ─────────
  /// Minimum gap between any two interstitials.
  static const Duration interstitialMinGap = Duration(minutes: 5);

  /// Hard daily ceiling on interstitials per user.
  static const int interstitialDailyCeiling = 6;

  /// Quarantine window after a fresh purchase: don't show interstitials
  /// for this many days so the player isn't punished for paying.
  static const Duration interstitialPurchaseGrace = Duration(days: 14);

  // ───────── Test devices ─────────
  /// Add your own physical devices here so they always receive test ads
  /// even when _useProdAds is true. Pull the ID from logcat
  /// ("Use RequestConfiguration.Builder.setTestDeviceIds(...)").
  static const List<String> testDeviceIds = <String>[
    // 'ABCDEF1234567890ABCDEF1234567890',
  ];
}
