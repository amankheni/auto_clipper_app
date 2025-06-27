import 'package:auto_clipper_app/comman%20class/remot_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';


class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isLoadingAd = false;
  DateTime _loadTime = DateTime.now();

  final RemoteConfigService _remoteConfig = RemoteConfigService();
  VoidCallback? _onAdDismissed;

  /// Maximum duration allowed between loading and showing the ad
  Duration get maxCacheDuration =>
      Duration(minutes: _remoteConfig.openAppAdCacheDurationMinutes);

  /// Load an app open ad
  /// Load an app open ad
  Future<void> loadAd() async {
    if (_isLoadingAd) {
      debugPrint('AppOpenAd already loading, skipping...');
      return;
    }

    if (!_remoteConfig.adsEnabled || !_remoteConfig.openAppAdsEnabled) {
      debugPrint('Open app ads are disabled in config');
      return;
    }

    final adUnitId = _remoteConfig.openAppAdUnitId;
    debugPrint('Loading ad with unit ID: $adUnitId');

    _isLoadingAd = true;

    try {
      await AppOpenAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('✅ AppOpenAd loaded successfully');
            _appOpenAd = ad;
            _loadTime = DateTime.now();
            _isLoadingAd = false;

            _appOpenAd?.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('✅ AppOpenAd showed full screen content');
                _isShowingAd = true;
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('✅ AppOpenAd dismissed');
                _isShowingAd = false;
                ad.dispose();
                _appOpenAd = null;
                loadAd(); // Preload next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('❌ AppOpenAd failed to show: $error');
                _isShowingAd = false;
                ad.dispose();
                _appOpenAd = null;
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ AppOpenAd failed to load: $error');
            _appOpenAd = null;
            _isLoadingAd = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Error loading open app ad: $e');
      _isLoadingAd = false;
    }
  }
  /// Show the ad if available and valid
  bool showAdIfAvailable({VoidCallback? onAdDismissed}) {
    _onAdDismissed = onAdDismissed;
    if (!_remoteConfig.adsEnabled || !_remoteConfig.openAppAdsEnabled) {
      debugPrint('Open app ads are disabled');
      return false;
    }

    if (_appOpenAd == null) {
      debugPrint('AppOpenAd not available');
      return false;
    }

    if (_isShowingAd) {
      debugPrint('AppOpenAd already showing');
      return false;
    }

    // Check if the cached ad is still valid
    final timeSinceLoad = DateTime.now().difference(_loadTime);
    if (timeSinceLoad >= maxCacheDuration) {
      debugPrint(
        'AppOpenAd cache expired (${timeSinceLoad.inMinutes} minutes old)',
      );
      _appOpenAd?.dispose();
      _appOpenAd = null;
      // Load a fresh ad for next time
      loadAd();
      return false;
    }

    try {
      debugPrint('Showing AppOpenAd');
      _appOpenAd?.show();
      return true;
    } catch (e) {
      debugPrint('Error showing open app ad: $e');
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _isShowingAd = false;
      // Try to load another ad
      loadAd();
      return false;
    }
  }

  /// Check if an ad is currently loaded and valid
  bool get isAdAvailable {
    if (_appOpenAd == null) return false;

    final timeSinceLoad = DateTime.now().difference(_loadTime);
    return timeSinceLoad < maxCacheDuration;
  }

  /// Check if an ad is currently being shown
  bool get isShowingAd => _isShowingAd;

  /// Dispose of the current ad
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isShowingAd = false;
    _isLoadingAd = false;
  }
}
