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

      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('NativeAds initialization error: $e');
      }
      _isInitialized = true; // Allow fallback to test ads
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
    adLayoutBuilder,
    Function(NativeAd)? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
  }) async {
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
      print('🔄 Loading native ad with ID: $adUnitId');
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
          if (onAdLoaded != null) {
            onAdLoaded(ad as NativeAd);
          }
        },
        onAdFailedToLoad: (ad, error) {
          _isNativeAdReady = false;
          _isLoading = false;
          ad.dispose();
          _nativeAd = null;
          if (kDebugMode) {
            print('❌ Native ad failed to load: $error');
          }
          if (onAdFailedToLoad != null) {
            onAdFailedToLoad(error);
          }
        },
        onAdClicked: (ad) {
          if (kDebugMode) {
            print('🖱️ Native ad clicked');
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
            print('👆 Native ad opened');
          }
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        // You can customize the template style here
        templateType: TemplateType.medium,
        cornerRadius: 10.0,
      ),
    );

    try {
      await _nativeAd!.load();
    } catch (e) {
      if (kDebugMode) {
        print('💥 Exception during native ad loading: $e');
      }
      _isNativeAdReady = false;
      _isLoading = false;
      _nativeAd?.dispose();
      _nativeAd = null;
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
}
