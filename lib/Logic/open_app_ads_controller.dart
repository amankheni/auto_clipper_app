import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime _loadTime = DateTime.now();

  /// Maximum duration allowed between loading and showing the ad
  final Duration maxCacheDuration = const Duration(minutes: 4);

  /// Load an app open ad
  Future<void> loadAd() async {
    try {
      // Initialize Remote Config if not already done
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.ensureInitialized();

      // Check if ads are enabled
      final adsEnabled = remoteConfig.getBool('open_app_ads_enabled');
      if (!adsEnabled) {
        debugPrint('App open ads are disabled in Remote Config');
        return;
      }

      // Get the appropriate ad unit ID
      final adUnitId =
          (kDebugMode || remoteConfig.getBool('ads_test_mode'))
              ? remoteConfig.getString('open_app_ad_unit_id_test')
              : remoteConfig.getString('open_app_ad_unit_id');

      if (adUnitId.isEmpty) {
        debugPrint('App open ad unit ID is empty');
        return;
      }

      debugPrint('Loading app open ad with unit ID: $adUnitId');

      await AppOpenAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        // Remove the orientation parameter - it's no longer supported
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('AppOpenAd loaded successfully');
            _appOpenAd = ad;
            _loadTime = DateTime.now();
            _appOpenAd?.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('AppOpenAd dismissed');
                ad.dispose();
                _appOpenAd = null;
                _isShowingAd = false;
                loadAd(); // Load a new ad after this one is dismissed
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('AppOpenAd failed to show: $error');
                ad.dispose();
                _appOpenAd = null;
                _isShowingAd = false;
                loadAd(); // Try to load another ad
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('AppOpenAd failed to load: $error');
            _appOpenAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading app open ad: $e');
    }
  }
  /// Show the ad if available
  void showAdIfAvailable() {
    if (_appOpenAd == null || _isShowingAd) {
      debugPrint('AppOpenAd not available or already showing');
      return;
    }

    // Check if the cached ad is still valid
    final timeSinceLoad = DateTime.now().difference(_loadTime);
    if (timeSinceLoad >= maxCacheDuration) {
      debugPrint('AppOpenAd cache expired');
      _appOpenAd?.dispose();
      _appOpenAd = null;
      return;
    }

    _isShowingAd = true;
    try {
      _appOpenAd?.show();
    } catch (e) {
      debugPrint('Error showing app open ad: $e');
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _isShowingAd = false;
      loadAd(); // Try to load another ad
    }
  }

  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
