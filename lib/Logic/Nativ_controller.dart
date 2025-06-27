import 'package:auto_clipper_app/comman%20class/remot_config.dart';
import 'package:flutter/foundation.dart';
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

  // Test ad unit ID for development
  final String _testAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
  // Your production ad unit ID from the image you shared
  final String _productionAdUnitId = 'ca-app-pub-7772180367051787/6519005372';

  bool get isNativeAdReady => _isNativeAdReady;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  NativeAd? get nativeAd => _nativeAd;

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
    } catch (e) {
      if (kDebugMode) {
        print('NativeAds initialization error: $e');
      }
      // Even if initialization fails, we can try loading ads
      _isInitialized = true;
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

  // Update your NativeAdsController's loadNativeAd method
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

    // Dispose existing ad
    _nativeAd?.dispose();
    _nativeAd = null;
    _isNativeAdReady = false;
    _isLoading = true;

    if (kDebugMode) {
      print(
        '🔄 Loading native ad with ID: $adUnitId (attempt ${retryCount + 1})',
      );
    }

    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
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

          // Automatic retry logic
          if (retryCount < maxRetryCount) {
            if (kDebugMode) {
              print('🔄 Retrying native ad load...');
            }
            Future.delayed(const Duration(seconds: 1), () {
              loadNativeAd(
                onAdLoaded: onAdLoaded,
                onAdFailedToLoad: onAdFailedToLoad,
                retryCount: retryCount + 1,
              );
            });
          } else {
            onAdFailedToLoad?.call(error);
          }
        },
        // ... rest of your listener code ...
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        cornerRadius: 10.0,
      ),
    );

    try {
      await _nativeAd!.load();
    } catch (e) {
      _isNativeAdReady = false;
      _isLoading = false;
      _nativeAd?.dispose();
      _nativeAd = null;

      if (kDebugMode) {
        print('💥 Exception during native ad loading: $e');
      }

      if (retryCount < maxRetryCount) {
        Future.delayed(const Duration(seconds: 1), () {
          loadNativeAd(
            onAdLoaded: onAdLoaded,
            onAdFailedToLoad: onAdFailedToLoad,
            retryCount: retryCount + 1,
          );
        });
      }
    }
  }

  void dispose() {
    if (kDebugMode) {
      print('🗑️ Disposing NativeAdsController');
    }
    _nativeAd?.dispose();
    _nativeAd = null;
    _isNativeAdReady = false;
    _isLoading = false;
    _isInitialized = false;
  }
  // Add this method to your NativeAdsController class
  Future<void> forceReload() async {
    if (_isLoading) return;

    // Dispose existing ad first
    _nativeAd?.dispose();
    _nativeAd = null;
    _isNativeAdReady = false;
    _isLoading = false;

    // Add a small delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Load new ad
    await loadNativeAd();
  }
}
