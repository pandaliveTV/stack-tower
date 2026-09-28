# Stack Tower — EliteP

One-tap hyper-casual stacking game (Flutter + Flame). Package: `com.elitep.stacktower`.

## Features
- Moving block, tap to drop; overhang is sliced off and falls with simple physics.
- PERFECT drops give bonus coins; 3 perfects in a row grow the block back.
- Speed ramps up, camera follows the tower, background gradient shifts with height.
- Game over → **Continue** via rewarded ad (once per run), **x2 coins** via rewarded ad.
- Coins unlock block skins and color themes (Shop).
- Sound/vibration toggles, privacy policy link, "Remove Ads" IAP + restore.

## Run
```bash
flutter pub get
flutter run
flutter analyze
```

## Project layout
```
lib/
  game/      stack_game.dart (Flame game)
  screens/   splash, home, game, shop, settings
  services/  ad_service, iap_service, storage_service, audio_service
  widgets/   shared UI (banner slot, buttons, backgrounds)
  data/      skins & themes catalog
assets/sounds/  sound effects
```

## AdMob — where to change IDs
Currently uses **Google test IDs**. Before release:
1. `lib/services/ad_service.dart` → class `AdIds` (banner, interstitial, rewarded, app open).
2. `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`.
3. Configure the GDPR message in AdMob → Privacy & messaging (UMP is already wired).

Ad rules (all in `AdService`): banner on Home/Shop only, interstitial every 3 attempts,
≥120 s between full-screen ads, no ads in the first 60 s of the first launch,
App Open on resume, rewarded always player-initiated. "Remove Ads" disables banner,
interstitial and app open only.

## In-app purchase
Create a managed (non-consumable) product `remove_ads` in Play Console
(id in `lib/services/iap_service.dart`).

## Privacy policy
Set the URL in `lib/widgets/common.dart` (`privacyPolicyUrl`).

## Build AAB for Google Play
1. Create a keystore:
   `keytool -genkey -v -keystore ~/elitep-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Create `android/key.properties` (don't commit it):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/path/to/elitep-upload.jks
   ```
3. In `android/app/build.gradle.kts` add a `signingConfigs { create("release") { ... } }`
   block reading `key.properties` and set `buildTypes.release.signingConfig` to it
   (see https://docs.flutter.dev/deployment/android#configure-signing-in-gradle).
4. Bump `version:` in `pubspec.yaml`, then:
   `flutter build appbundle --release`
5. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.
