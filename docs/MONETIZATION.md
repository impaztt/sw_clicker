# Monetization Setup (AdMob + IAP)

This game ships with AdMob ads and Google Play in-app purchases pre-wired.
Default configuration uses **test ad units and unregistered product IDs**, so
you have to swap a handful of constants and finish the store-side setup
before publishing.

## 1. Application ID

`android/app/build.gradle.kts` currently hard-codes `com.example.sw_clicker`.
Change this to your own (e.g. `com.impaztt.swordclicker`) **before** uploading
the first build to Play Console — once published, you can never rename it.

## 2. AdMob

### 2-1. Create the AdMob app

1. https://admob.google.com → **Apps → Add app → Android → no, my app isn't listed yet**
2. Note the **App ID** (looks like `ca-app-pub-XXXX~YYYY`).
3. Create three ad units:
   - Banner (Adaptive)
   - Interstitial
   - Rewarded
4. Note each ad unit ID (`ca-app-pub-XXXX/ZZZZ`).

### 2-2. Wire the IDs into the project

- `android/app/src/main/AndroidManifest.xml` — replace the
  `com.google.android.gms.ads.APPLICATION_ID` meta-data value with your real
  App ID.
- `lib/core/ad_config.dart` — fill in `_prodBannerAndroid`,
  `_prodInterstitialAndroid`, `_prodRewardedAndroid` (and the iOS variants
  when iOS lands), then flip `_useProdAds` to `true`.

### 2-3. Add test devices for QA

In `lib/core/ad_config.dart`, append your physical test device IDs to
`testDeviceIds`. Get the ID from logcat after your first ad request — the
SDK prints a line like:

```
Use RequestConfiguration.Builder.setTestDeviceIds(["XXXXXXXX..."])
```

Devices listed here always see test ads even when `_useProdAds` is true.

### 2-4. Account requirements (before going live)

- Verify payment + tax info in the AdMob dashboard.
- Add a privacy policy URL (Play Console requires it for any app with ads).
- For Korean publishers, register the app's age rating (14+ recommended).

## 3. In-App Purchases

### 3-1. Register products in Play Console

Go to **Play Console → Monetize → Products → In-app products** and create
each ID below with the corresponding price tier. The IDs must match
`lib/core/iap_config.dart` exactly.

| Product ID | Price (KRW) | Type |
|---|---|---|
| `premium_ad_removal` | 4,900 | Non-consumable |
| `premium_monthly_essence_pass` | 5,900 | Consumable |
| `premium_starter_package` | 4,900 | Non-consumable |
| `premium_first_purchase` | 1,100 | Non-consumable |
| `premium_essence_small` | 1,100 | Consumable |
| `premium_essence_medium` | 3,300 | Consumable |
| `premium_essence_large` | 9,900 | Consumable |
| `premium_essence_xlarge` | 19,900 | Consumable |
| `premium_master_package` | 49,900 | Non-consumable |
| `premium_season_pass` | 14,900 | Consumable |

> Activate each product after registering. Inactive products won't load.

### 3-2. Closed testing

Add yourself as a **License tester** in Play Console (Settings → License
testing). License testers get free real-money flows for QA.

### 3-3. Server-side validation (future)

The current implementation grants entitlements client-side after the IAP
plugin returns `purchased`/`restored`. For a hardened production setup,
add Google Play Developer API receipt validation server-side and gate the
`purchasePremiumProduct(...)` grant on a backend ack. Out of scope for
v1 launch but easy to retrofit (the grant call already lives in one
place: `GameNotifier._wireIapListener`).

## 4. Frequency caps in code

Adjust these in `lib/core/ad_config.dart` if telemetry shows users
ejecting on ad fatigue:

- `interstitialMinGap` — minimum gap between any two interstitials
  (default 5 minutes)
- `interstitialDailyCeiling` — daily hard ceiling (default 6)
- `interstitialPurchaseGrace` — silence interstitials for this many days
  after any IAP (default 14)

Rewarded ads have no system-wide cap because they're opt-in. Per-slot
caps live in the dialog that calls `AdService.showRewarded` (e.g. the
offline-reward dialog only shows the ×2 button when the reward exists).

## 5. Pre-launch checklist

- [ ] applicationId changed from `com.example.*` to your own
- [ ] AdMob App ID swapped in AndroidManifest.xml
- [ ] All three prod ad-unit IDs filled in `ad_config.dart`
- [ ] `_useProdAds = true` in `ad_config.dart`
- [ ] All 10 IAP products registered + active in Play Console
- [ ] License testers added for QA
- [ ] Privacy policy URL filled in Play Console listing
- [ ] AdMob payment + tax info verified
- [ ] Age rating questionnaire completed
- [ ] Closed testing track ran a full purchase flow end-to-end
