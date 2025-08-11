

// ignore_for_file: file_names

import 'package:auto_clipper_app/comman%20class/remot_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class NativeAdsController {
  static final NativeAdsController _instance = NativeAdsController._internal();
  factory NativeAdsController() => _instance;
  NativeAdsController._internal();

  NativeAd? _nativeAd;
  bool _isNativeAdReady = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isDisposed = false;

  // Test ad unit ID for development
  final String _testAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
  // Your production ad unit ID from the image you shared
  final String _productionAdUnitId = 'ca-app-pub-7772180367051787/2949453118';

  bool get isNativeAdReady => _isNativeAdReady && !_isDisposed;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  NativeAd? get nativeAd => _isDisposed ? null : _nativeAd;

  Future<void> initializeAds() async {
    if (_isInitialized) return;

    try {
      // Initialize RemoteConfig first
      await RemoteConfigService().initialize();

      // Initialize Mobile Ads SDK with a completion handler
      await MobileAds.instance.initialize().then((InitializationStatus status) {
        if (kDebugMode) {
          print('Mobile Ads SDK initialized: ${status.adapterStatuses}');
        }
      });

      // Additional delay for stability
      await Future.delayed(const Duration(seconds: 1));

      _isInitialized = true;
      _isDisposed = false;
    } catch (e) {
      if (kDebugMode) {
        print('NativeAds initialization error: $e');
      }
      // Even if initialization fails, we can try loading ads
      _isInitialized = true;
      _isDisposed = false;
    }
  }

  String _getNativeAdUnitId() {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      final adsEnabled = remoteConfig.getBool('native_ads_enabled');

      if (!adsEnabled) {
        if (kDebugMode) {
          print('❌ Native ads disabled via Remote Config');
        }
        return '';
      }

      final useAccount1 = remoteConfig.getBool('use_native_ad_account_1');
      String adUnitId =
          useAccount1
              ? remoteConfig.getString('native_ad_unit_id_1')
              : remoteConfig.getString('native_ad_unit_id_2');

      if (adUnitId.isEmpty) {
        adUnitId = kDebugMode ? _testAdUnitId : _productionAdUnitId;
      }

      if (kDebugMode) {
        print('🎯 Selected native ad unit ID: $adUnitId');
      }

      return adUnitId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting native ad unit ID: $e');
      }
      return kDebugMode ? _testAdUnitId : _productionAdUnitId;
    }
  }

  Future<void> loadNativeAd({
    Function(NativeAd)? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
    int retryCount = 0,
  }) async {
    // Maximum retry attempts
    const maxRetryCount = 2;

    if (!_isInitialized) {
      await initializeAds();
    }

    if (_isLoading) {
      if (kDebugMode) {
        print('⚠️ Native ad is already loading');
      }
      return;
    }

    final adUnitId = _getNativeAdUnitId();
    if (adUnitId.isEmpty) {
      if (kDebugMode) {
        print('❌ No native ad unit ID available');
      }
      return;
    }

    // Properly dispose existing ad before creating new one
    await _disposeCurrentAd();

    _isLoading = true;
    _isDisposed = false;

    if (kDebugMode) {
      print(
        '🔄 Loading native ad with ID: $adUnitId (attempt ${retryCount + 1})',
      );
    }

    try {
      _nativeAd = NativeAd(
        adUnitId: adUnitId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (_isDisposed) {
              // If controller was disposed while loading, dispose the ad
              ad.dispose();
              return;
            }

            _isNativeAdReady = true;
            _isLoading = false;
            if (kDebugMode) {
              print('✅ Native ad loaded successfully');
            }
            onAdLoaded?.call(ad as NativeAd);
          },
          onAdFailedToLoad: (ad, error) {
            _isNativeAdReady = false;
            _isLoading = false;
            ad.dispose();
            _nativeAd = null;

            if (kDebugMode) {
              print('❌ Native ad failed to load: $error');
            }

            // Automatic retry logic with exponential backoff
            if (retryCount < maxRetryCount && !_isDisposed) {
              if (kDebugMode) {
                print(
                  '🔄 Retrying native ad load in ${(retryCount + 1) * 2} seconds...',
                );
              }
              Future.delayed(Duration(seconds: (retryCount + 1) * 2), () {
                if (!_isDisposed) {
                  loadNativeAd(
                    onAdLoaded: onAdLoaded,
                    onAdFailedToLoad: onAdFailedToLoad,
                    retryCount: retryCount + 1,
                  );
                }
              });
            } else {
              onAdFailedToLoad?.call(error);
            }
          },
          onAdClicked: (ad) {
            if (kDebugMode) {
              print('📱 Native ad clicked');
            }
          },
          onAdImpression: (ad) {
            if (kDebugMode) {
              print('👁️ Native ad impression recorded');
            }
          },
          onAdClosed: (ad) {
            if (kDebugMode) {
              print('❌ Native ad closed');
            }
          },
          onAdOpened: (ad) {
            if (kDebugMode) {
              print('📖 Native ad opened');
            }
          },
        ),
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.small,
          cornerRadius: 15.0,
          mainBackgroundColor: Colors.white,
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: const Color(0xFFE91E63), // Pink accent color
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: const Color(0xFF1A1A1A), // Dark text
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.bold,
            size: 18.0,
          ),
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: const Color(0xFF6B7280), // Medium gray
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.normal,
            size: 15.0,
          ),
          tertiaryTextStyle: NativeTemplateTextStyle(
            textColor: const Color(0xFF9CA3AF), // Light gray
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.normal,
            size: 13.0,
          ),
        ),
      );

      await _nativeAd!.load();
    } catch (e) {
      _isNativeAdReady = false;
      _isLoading = false;
      await _disposeCurrentAd();

      if (kDebugMode) {
        print('💥 Exception during native ad loading: $e');
      }

      // Retry with exponential backoff
      if (retryCount < maxRetryCount && !_isDisposed) {
        Future.delayed(Duration(seconds: (retryCount + 1) * 2), () {
          if (!_isDisposed) {
            loadNativeAd(
              onAdLoaded: onAdLoaded,
              onAdFailedToLoad: onAdFailedToLoad,
              retryCount: retryCount + 1,
            );
          }
        });
      }
    }
  }

  // Helper method to properly dispose current ad
  Future<void> _disposeCurrentAd() async {
    if (_nativeAd != null) {
      try {
        _nativeAd!.dispose();
        if (kDebugMode) {
          print('🗑️ Previous native ad disposed');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error disposing previous ad: $e');
        }
      }
      _nativeAd = null;
    }
    _isNativeAdReady = false;
  }

  void dispose() {
    if (kDebugMode) {
      print('🗑️ Disposing NativeAdsController');
    }
    _isDisposed = true;
    _isLoading = false;
    _isNativeAdReady = false;
    _nativeAd?.dispose();
    _nativeAd = null;
    _isInitialized = false;
  }

  // Update the forceReload method in NativeAdsController
  Future<void> forceReload({
    Function(NativeAd)? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    if (kDebugMode) {
      print('🔄 Force reloading native ad...');
    }

    // Reset all states
    _isLoading = false;
    _isNativeAdReady = false;
    _isDisposed = false;

    // Properly dispose existing ad first
    await _disposeCurrentAd();

    // Add a longer delay to ensure proper cleanup
    await Future.delayed(const Duration(milliseconds: 1000));

    // Load new ad with reset retry count
    await loadNativeAd(
      onAdLoaded: onAdLoaded,
      onAdFailedToLoad: onAdFailedToLoad,
      retryCount: 0, // Reset retry count
    );
  }

  // Method to check if ad is still valid
  bool isAdValid() {
    return _isNativeAdReady && !_isDisposed && _nativeAd != null;
  }

  // Method to refresh ad after a certain time
  Future<void> refreshAdIfNeeded({
    Duration refreshInterval = const Duration(minutes: 5),
    Function(NativeAd)? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    // This method can be called periodically to refresh ads
    // You can store the last load time and compare it
    if (!isAdValid()) {
      await loadNativeAd(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      );
    }
  }
}




