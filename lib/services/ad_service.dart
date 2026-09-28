import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'storage_service.dart';

/// ===================== AdMob unit IDs =====================
/// These are Google's official TEST ids. Before publishing, replace them
/// with the EliteP ids from your AdMob console (and set the App ID in
/// android/app/src/main/AndroidManifest.xml).
class AdIds {
  static const banner = 'ca-app-pub-3940256099942544/6300978111';
  static const interstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const rewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const appOpen = 'ca-app-pub-3940256099942544/9257395921';
}

/// Single place for all ad logic and frequency rules:
/// * no ad during the first 60s after the very first launch
/// * at least 120s between any two full-screen ads (interstitial / app open)
/// * interstitial every 3 attempts
/// * "Remove Ads" purchase disables banner / interstitial / app open only
class AdService {
  static const minGap = Duration(seconds: 120);
  static const firstRunGrace = Duration(seconds: 60);
  static const attemptsPerInterstitial = 3;

  final StorageService storage;
  AdService(this.storage);

  bool _ready = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  AppOpenAd? _appOpen;
  DateTime? _lastFullScreen;
  bool _showingFullScreen = false;
  int _attempts = 0;
  StreamSubscription<AppState>? _appStateSub;

  bool get canShowRewarded => _ready && _rewarded != null;

  bool get _inGrace =>
      DateTime.now().millisecondsSinceEpoch - storage.firstLaunch <
      firstRunGrace.inMilliseconds;

  bool get _gapOk =>
      _lastFullScreen == null ||
      DateTime.now().difference(_lastFullScreen!) >= minGap;

  bool get _nonRewardedAllowed => _ready && !storage.adsRemoved && !_inGrace;

  /// Gathers GDPR consent (UMP) first, then initialises the SDK.
  Future<void> init() async {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((_) {
        if (!completer.isCompleted) completer.complete();
      }),
      (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {},
    );
    if (!await ConsentInformation.instance.canRequestAds()) return;

    await MobileAds.instance.initialize();
    _ready = true;
    _loadInterstitial();
    _loadRewarded();
    _loadAppOpen();
    AppStateEventNotifier.startListening();
    _appStateSub = AppStateEventNotifier.appStateStream.listen((s) {
      if (s == AppState.foreground) _showAppOpen();
    });
  }

  void dispose() => _appStateSub?.cancel();

  // ---------------- Banner ----------------
  BannerAd? createBanner(VoidCallback onLoaded) {
    if (!_ready || storage.adsRemoved) return null;
    return BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  // ---------------- Interstitial ----------------
  void _loadInterstitial() {
    if (storage.adsRemoved) return;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Call after every finished attempt (game over).
  void onAttemptFinished() {
    _attempts++;
    if (_attempts % attemptsPerInterstitial != 0) return;
    final ad = _interstitial;
    if (ad == null || !_nonRewardedAllowed || !_gapOk) return;
    _interstitial = null;
    ad.fullScreenContentCallback = _fullScreenCallback(_loadInterstitial);
    ad.show();
  }

  // ---------------- Rewarded ----------------
  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  /// Shows a rewarded ad (always player-initiated). Completes with true
  /// only if the reward was earned.
  Future<bool> showRewarded() {
    final ad = _rewarded;
    if (ad == null) return Future.value(false);
    _rewarded = null;
    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = _fullScreenCallback(() {
      _loadRewarded();
      if (!result.isCompleted) result.complete(earned);
    });
    ad.show(onUserEarnedReward: (_, _) => earned = true);
    return result.future;
  }

  // ---------------- App Open ----------------
  void _loadAppOpen() {
    if (storage.adsRemoved) return;
    AppOpenAd.load(
      adUnitId: AdIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpen = ad,
        onAdFailedToLoad: (_) => _appOpen = null,
      ),
    );
  }

  void _showAppOpen() {
    final ad = _appOpen;
    if (ad == null || _showingFullScreen) return;
    if (!_nonRewardedAllowed || !_gapOk) return;
    _appOpen = null;
    ad.fullScreenContentCallback = _fullScreenCallback(_loadAppOpen);
    ad.show();
  }

  FullScreenContentCallback<T> _fullScreenCallback<T extends Ad>(
    VoidCallback onDone,
  ) {
    return FullScreenContentCallback<T>(
      onAdShowedFullScreenContent: (_) {
        _showingFullScreen = true;
        _lastFullScreen = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        _showingFullScreen = false;
        _lastFullScreen = DateTime.now();
        ad.dispose();
        onDone();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        _showingFullScreen = false;
        ad.dispose();
        onDone();
      },
    );
  }
}
