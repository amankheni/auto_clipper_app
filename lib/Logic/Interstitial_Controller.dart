// ignore_for_file: file_names

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:auto_clipper_app/comman%20class/remot_config.dart';

class InterstitialAdsController {
  static final InterstitialAdsController _instance =
      InterstitialAdsController._internal();
  factory InterstitialAdsController() => _instance;
  InterstitialAdsController._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  int _clickCounter = 0;
  int _showAfterClicks = 2; // Default value

  // Test ad unit ID for development
  final String _testAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  // Your production ad unit ID
  final String _productionAdUnitId = 'ca-app-pub-7772180367051787/7636645925';

  bool get isAdLoaded => _isAdLoaded;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize RemoteConfig first
      await RemoteConfigService().initialize();

      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();

      // Get the click threshold from RemoteConfig using the service
      _showAfterClicks = RemoteConfigService().interstitialClickThreshold;

      _isInitialized = true;

      if (kDebugMode) {
        print(
          '🎯 Interstitial ads initialized with click threshold: $_showAfterClicks',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('InterstitialAds initialization error: $e');
      }
      _isInitialized = true;
    }
  }


  String _getAdUnitId() {
    try {
      final remoteConfigService = RemoteConfigService();

      // Check if ads are enabled globally and interstitial ads specifically
      if (!remoteConfigService.adsEnabled ||
          !remoteConfigService.interstitialAdsEnabled) {
        if (kDebugMode) {
          print('❌ Interstitial ads disabled via Remote Config');
        }
        return '';
      }

      // Get the ad unit ID from RemoteConfig service
      String adUnitId = remoteConfigService.interstitialAdUnitId;

      if (kDebugMode) {
        print('🎯 Selected interstitial ad unit ID: $adUnitId');
        print('🎯 Test mode: ${remoteConfigService.adsTestMode}');
        print('🎯 Debug mode: $kDebugMode');
      }

      return adUnitId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting interstitial ad unit ID: $e');
      }
      return kDebugMode ? _testAdUnitId : _productionAdUnitId;
    }
  }

  Future<void> loadInterstitialAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isLoading) {
      if (kDebugMode) {
        print('⚠️ Interstitial ad is already loading');
      }
      return;
    }

    final adUnitId = _getAdUnitId();

    if (adUnitId.isEmpty) {
      if (kDebugMode) {
        print('❌ No interstitial ad unit ID available');
      }
      return;
    }

    // Dispose existing ad
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;

    _isLoading = true;

    if (kDebugMode) {
      print('🔄 Loading interstitial ad with ID: $adUnitId');
    }

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _isLoading = false;

          // Set full screen content callback
          _interstitialAd
              ?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _interstitialAd = null;
              _isAdLoaded = false;
              // Load a new ad after dismissal
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (
              InterstitialAd ad,
              AdError error,
            ) {
              if (kDebugMode) {
                print('$ad onAdFailedToShowFullScreenContent: $error');
              }
              ad.dispose();
              _interstitialAd = null;
              _isAdLoaded = false;
              // Load a new ad after failure
              loadInterstitialAd();
            },
          );

          if (kDebugMode) {
            print('✅ Interstitial ad loaded successfully');
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (kDebugMode) {
            print('❌ Interstitial ad failed to load: $error');
          }
          _isAdLoaded = false;
          _isLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void handleButtonClick(BuildContext context) {
    _clickCounter++;

    if (kDebugMode) {
      print('🖱️ Button clicked. Count: $_clickCounter/$_showAfterClicks');
    }

    if (_clickCounter >= _showAfterClicks) {
      showInterstitialAd(context);
      _clickCounter = 0; // Reset counter after showing ad
    }
  }

  void showInterstitialAd(BuildContext context) {
    if (!_isAdLoaded) {
      if (kDebugMode) {
        print('⚠️ Interstitial ad not loaded yet');
      }
      // Try to load ad if not loaded
      loadInterstitialAd();
      return;
    }

    if (_interstitialAd != null) {
      if (kDebugMode) {
        print('👆 Showing interstitial ad');
      }
      _interstitialAd?.show();
    } else {
      if (kDebugMode) {
        print('⚠️ No interstitial ad available to show');
      }
    }
  }

  void dispose() {
    if (kDebugMode) {
      print('🗑️ Disposing InterstitialAdsController');
    }
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
    _isLoading = false;
    _isInitialized = false;
  }
}
