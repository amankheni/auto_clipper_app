import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 🎯 Complete Ad Service with Firebase Remote Config & Beautiful UI
/// Combines AdController logic + AdService UI
class AdService extends GetxController {
  // Singleton pattern
  static final AdService _instance = AdService._internal();

  factory AdService() => _instance;

  AdService._internal();

  // ==================== FIREBASE REMOTE CONFIG ====================
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // ==================== CONNECTIVITY ====================
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;

  // ==================== AD INSTANCES ====================
  BannerAd? bannerAd;
  InterstitialAd? interstitialAd;
  RewardedAd? rewardedAd;
  final Map<String, NativeAd> _nativeAds = {};

  // ==================== AD STATUS ====================
  final RxBool isBannerAdLoaded = false.obs;
  final RxBool isInterstitialAdLoaded = false.obs;
  final RxBool isRewardedAdLoaded = false.obs;
  final RxBool isInitialized = false.obs;

  // ==================== NAVIGATION COUNTER ====================
  int _navigationCounter = 0;
  final RxInt interstitialAdCounter = 0.obs;

  // ==================== INITIALIZATION ====================

  @override
  void onInit() {
    super.onInit();
    _checkConnectivity();
    _listenToConnectivity();
  }

  @override
  void onClose() {
    bannerAd?.dispose();
    interstitialAd?.dispose();
    rewardedAd?.dispose();
    for (var ad in _nativeAds.values) {
      ad.dispose();
    }
    super.onClose();
  }

  /// 🚀 CRITICAL: Initialize in background after app starts
  Future<void> initializeInBackground() async {
    // ✅ Start Remote Config in background (non-blocking)
    initRemoteConfig();

    // ✅ Mark as initialized immediately with defaults
    isInitialized.value = true;
  }

  /// Initialize AdService - Call this in main.dart before runApp
  static Future<void> initialize() async {
    try {
      final initResult = await MobileAds.instance.initialize();
      print('✅ AdService initialized');
      print('📱 Adapter status: ${initResult.adapterStatuses}');
    } catch (e) {
      print('❌ AdService initialization failed: $e');
    }
  }

  // ==================== FIREBASE REMOTE CONFIG ====================

  /// Initialize Firebase Remote Config - NON-BLOCKING
  Future<void> initRemoteConfig() async {
    try {
      // ✅ Set default values
      await _remoteConfig.setDefaults({
        // Global
        'ads_enabled': true,
        'ads_test_mode': kDebugMode,
        // Automatically enable test mode in debug
        'ads_load_timeout': 10,

        // Banner
        'banner_ads_enabled': true,
        'banner_ad_unit_id_production':
        'ca-app-pub-7772180367051787/8438591704',
        'banner_ad_unit_id_test': '',
        'banner_ad_refresh_rate': 60,

        // Native
        'native_ads_enabled': true,
        'native_ad_unit_id_production':
        'ca-app-pub-7772180367051787/2949453118',
        'native_ad_unit_id_test': 'ca-app-pub-3940256099942544/2247696110',
        'native_ad_template_type': 'medium',
        'native_ad_corner_radius': 10,

        // Interstitial
        'interstitial_ads_enabled': true,
        'interstitial_ad_unit_id_production':
        'ca-app-pub-7772180367051787/7636645925',
        'interstitial_ad_unit_id_test':
        'ca-app-pub-3940256099942544/1033173712',
        'interstitial_click_threshold': 1,

        // Open App Ads - Enhanced Configuration
        'open_app_ads_enabled': true,
        'open_app_ad_unit_id_production':
        'ca-app-pub-7772180367051787/1508762400',
        // Use your actual Open App ad unit ID
        'open_app_ad_unit_id_test': 'ca-app-pub-3940256099942544/9257395921',
        // Correct test ID for Open App Ads
        'open_app_ad_timeout': 4,
        // Hours before ad expires
        'open_app_ad_show_frequency': 1,
        // Show every X app opens (1 = every time)
        'open_app_ad_first_launch_delay': 2,
        // Seconds to wait before showing on first launch
        'open_app_ad_resume_delay': 100,
        // Milliseconds to wait before showing on app resume
        'open_app_ad_min_interval': 30,
        // Minimum seconds between ad shows
        'open_app_ad_max_daily_shows': 10,
        // Maximum times to show per day
        'open_app_ad_show_on_first_launch': true,
        // Whether to show on very first app launch
        'open_app_ad_show_on_cold_start': true,
        // Whether to show on cold starts
        'open_app_ad_show_on_warm_start': true,
        // Whether to show on warm starts
        'open_app_ad_preload_timeout': 30,
        // Seconds to timeout ad loading
        'open_app_ad_retry_attempts': 3,
        // Number of retry attempts for failed loads
        'open_app_ad_retry_delay': 5,
        // Seconds between retry attempts

        // Rewarded ads - missing defaults added
        'rewarded_ads_enabled': true,
        'rewarded_ad_unit_id_production':
        'ca-app-pub-7772180367051787/0000000000',
        // Replace with your actual rewarded ad unit ID
        'rewarded_ad_unit_id_test': 'ca-app-pub-3940256099942544/5224354917',

        // ===== App Update Config =====
        'latest_version': '1.0.0', // e.g. "2.1.0" — bump to trigger update
        'force_update': false, // true = user cannot skip
        'update_title': '', // custom dialog title (blank = default)
        'update_message': '', // custom dialog body  (blank = default)
        'store_url_android': '', // Play Store URL
        'store_url_ios': '', // App Store URL
      });

      // ✅ CRITICAL: Reduced timeout and fetch interval
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5), // ✅ Reduced from 10s
          minimumFetchInterval:
          Duration.zero, // ✅ No cache delay (fetch fresh every time)
        ),
      );

      // ✅ Fetch in background - don't block startup
      _remoteConfig
          .fetchAndActivate()
          .then((_) {
        print('✅ Firebase Remote Config loaded');

        // ✅ Load ads only if enabled
        if (shouldShowAds && isConnected.value) {
          _loadAllAds();
        }
      })
          .catchError((e) {
        print('⚠️ Remote Config fetch failed (using defaults): $e');
        // ✅ Still load ads with default values
        if (isConnected.value) {
          _loadAllAds();
        }
      });
    } catch (e) {
      print('❌ Error initializing Remote Config: $e');
    }
  }

  // ==================== APP UPDATE CONFIG GETTERS ====================

  String get _latestVersion => _remoteConfig.getString('latest_version').trim();

  bool get _forceUpdate => _remoteConfig.getBool('force_update');

  String get _updateTitle => _remoteConfig.getString('update_title').trim();

  String get _updateMessage => _remoteConfig.getString('update_message').trim();

  String get _storeUrlAndroid =>
      _remoteConfig.getString('store_url_android').trim();

  String get _storeUrlIos => _remoteConfig.getString('store_url_ios').trim();

  // ==================== APP UPDATE CHECK ====================

  /// Called automatically after Remote Config fetches.
  /// Shows update dialog if latest_version > current app version.
  Future<void> _checkAndShowUpdateDialog() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = _parseVersion(info.version);
      final latest = _parseVersion(_latestVersion);

      if (!_isNewerVersion(latest, current)) {
        print('✅ App is up to date (${info.version})');
        return;
      }

      print('🔄 Update available: ${info.version} → $_latestVersion');

      // Resolve title & message
      final title =
      _updateTitle.isNotEmpty ? _updateTitle : 'New Update Available 🚀';
      final message =
      _updateMessage.isNotEmpty
          ? _updateMessage
          : 'Version $_latestVersion is available with new features and improvements. Update now for the best experience!';

      final storeUrl = Platform.isIOS ? _storeUrlIos : _storeUrlAndroid;

      // Wait for a valid context (NavigatorKey needed)
      final context = Get.context;
      if (context == null) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: !_forceUpdate,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        useSafeArea: false,
        builder:
            (_) => PopScope(
          canPop: !_forceUpdate,
          child: _AppUpdateDialog(
            currentVersion: info.version,
            latestVersion: _latestVersion,
            title: title,
            message: message,
            isForced: _forceUpdate,
            storeUrl: storeUrl,
          ),
        ),
      );
    } catch (e) {
      print('❌ Update check failed: $e');
    }
  }

  /// Public static method — call manually from any screen if needed.
  static Future<void> checkForUpdate() => _instance._checkAndShowUpdateDialog();

  // ─── Version helpers ────────────────────────────────────────────────────────
  static List<int> _parseVersion(String v) {
    try {
      return v.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    } catch (_) {
      return [0, 0, 0];
    }
  }

  static bool _isNewerVersion(List<int> latest, List<int> current) {
    final len = latest.length > current.length ? latest.length : current.length;
    for (int i = 0; i < len; i++) {
      final l = i < latest.length ? latest[i] : 0;
      final c = i < current.length ? current[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  /// Manually refresh remote config
  static Future<void> refreshRemoteConfig() async {
    try {
      await _instance._remoteConfig.fetchAndActivate();
      print('✅ Remote config refreshed');

      // Reload ads with new config
      _instance._disposeAllAds();
      _instance._loadAllAds();
    } catch (e) {
      print('❌ Error refreshing remote config: $e');
    }
  }

  // ==================== CONNECTIVITY CHECK ====================

  /// Check initial connectivity
  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    isConnected.value =
        !results.contains(ConnectivityResult.none) && results.isNotEmpty;
    print('📡 Initial connectivity: ${isConnected.value}');
  }

  /// Listen to connectivity changes
  void _listenToConnectivity() {
    _connectivity.onConnectivityChanged.listen((results) {
      final connected =
          !results.contains(ConnectivityResult.none) && results.isNotEmpty;
      final wasConnected = isConnected.value;
      isConnected.value = connected;

      if (connected && !wasConnected) {
        print('🟢 Internet connected - Loading ads...');
        if (shouldShowAds) {
          _loadAllAds();
        }
      } else if (!connected && wasConnected) {
        print('🔴 Internet disconnected - Disposing ads...');
        _disposeAllAds();
      }
    });
  }

  // ==================== REMOTE CONFIG GETTERS ====================

  bool get adsEnabled => false;

  bool get adsTestMode => _remoteConfig.getBool('ads_test_mode');

  int get adsLoadTimeout => _remoteConfig.getInt('ads_load_timeout');

  // Banner ads getters
  bool get bannerAdsEnabled => _remoteConfig.getBool('banner_ads_enabled');

  String get bannerAdUnitId =>
      (kDebugMode || adsTestMode)
          ? _remoteConfig.getString('banner_ad_unit_id_test')
          : _remoteConfig.getString('banner_ad_unit_id_production');

  int get bannerAdRefreshRate => _remoteConfig.getInt('banner_ad_refresh_rate');

  // Native ads getters
  bool get nativeAdsEnabled => _remoteConfig.getBool('native_ads_enabled');

  String get nativeAdUnitId =>
      (kDebugMode || adsTestMode)
          ? _remoteConfig.getString('native_ad_unit_id_test')
          : _remoteConfig.getString('native_ad_unit_id_production');

  TemplateType get nativeAdTemplateType {
    final type = _remoteConfig.getString('native_ad_template_type');
    return type == 'small' ? TemplateType.small : TemplateType.medium;
  }

  double get nativeAdCornerRadius =>
      _remoteConfig.getInt('native_ad_corner_radius').toDouble();

  // Interstitial ads getters
  bool get interstitialAdsEnabled =>
      _remoteConfig.getBool('interstitial_ads_enabled');

  String get interstitialAdUnitId =>
      (kDebugMode || adsTestMode)
          ? _remoteConfig.getString('interstitial_ad_unit_id_test')
          : _remoteConfig.getString('interstitial_ad_unit_id_production');

  int get interstitialClickThreshold =>
      _remoteConfig.getInt('interstitial_click_threshold');

  // Open App Ads getters - Enhanced
  bool get openAppAdsEnabled => _remoteConfig.getBool('open_app_ads_enabled');

  String get openAppAdUnitId =>
      (kDebugMode || adsTestMode)
          ? _remoteConfig.getString('open_app_ad_unit_id_test')
          : _remoteConfig.getString('open_app_ad_unit_id_production');

  int get openAppAdTimeout => _remoteConfig.getInt('open_app_ad_timeout');

  int get openAppAdShowFrequency =>
      _remoteConfig.getInt('open_app_ad_show_frequency');

  int get openAppAdFirstLaunchDelay =>
      _remoteConfig.getInt('open_app_ad_first_launch_delay');

  int get openAppAdResumeDelay =>
      _remoteConfig.getInt('open_app_ad_resume_delay');

  int get openAppAdMinInterval =>
      _remoteConfig.getInt('open_app_ad_min_interval');

  int get openAppAdMaxDailyShows =>
      _remoteConfig.getInt('open_app_ad_max_daily_shows');

  bool get openAppAdShowOnFirstLaunch =>
      _remoteConfig.getBool('open_app_ad_show_on_first_launch');

  bool get openAppAdShowOnColdStart =>
      _remoteConfig.getBool('open_app_ad_show_on_cold_start');

  bool get openAppAdShowOnWarmStart =>
      _remoteConfig.getBool('open_app_ad_show_on_warm_start');

  int get openAppAdPreloadTimeout =>
      _remoteConfig.getInt('open_app_ad_preload_timeout');

  int get openAppAdRetryAttempts =>
      _remoteConfig.getInt('open_app_ad_retry_attempts');

  int get openAppAdRetryDelay =>
      _remoteConfig.getInt('open_app_ad_retry_delay');

  // Helper methods for Open App Ads
  Duration get openAppAdTimeoutDuration => Duration(hours: openAppAdTimeout);

  Duration get openAppAdFirstLaunchDelayDuration =>
      Duration(seconds: openAppAdFirstLaunchDelay);

  Duration get openAppAdResumeDelayDuration =>
      Duration(milliseconds: openAppAdResumeDelay);

  Duration get openAppAdMinIntervalDuration =>
      Duration(seconds: openAppAdMinInterval);

  Duration get openAppAdPreloadTimeoutDuration =>
      Duration(seconds: openAppAdPreloadTimeout);

  Duration get openAppAdRetryDelayDuration =>
      Duration(seconds: openAppAdRetryDelay);

  // ==================== MISSING COMPUTED GETTERS ====================

  /// Master switch: ads enabled AND initialized
  bool get shouldShowAds => adsEnabled && isInitialized.value;

  /// Banner ads enabled (alias using isInitialized guard)
  bool get isBannerAdsEnabled => bannerAdsEnabled && shouldShowAds;

  /// Interstitial ads enabled
  bool get isInterstitialAdsEnabled => interstitialAdsEnabled && shouldShowAds;

  /// Rewarded ads enabled (remote config doesn't define separately; piggybacks interstitial flag)
  bool get isRewardedAdsEnabled =>
      _remoteConfig.getBool('rewarded_ads_enabled') && shouldShowAds;

  /// Native ads enabled
  bool get isNativeAdsEnabled => nativeAdsEnabled && shouldShowAds;

  /// Private ad unit ID resolvers
  String get _bannerAdUnitId => bannerAdUnitId;

  String get _interstitialAdUnitId => interstitialAdUnitId;

  String get _rewardedAdUnitId =>
      (kDebugMode || adsTestMode)
          ? _remoteConfig.getString('rewarded_ad_unit_id_test')
          : _remoteConfig.getString('rewarded_ad_unit_id_production');

  /// How many workout completions before showing interstitial
  int get interstitialWorkoutFrequency => interstitialClickThreshold;

  /// How many navigations before showing interstitial
  int get interstitialNavigationFrequency => interstitialClickThreshold;

  // ==================== AD LOADING ====================

  /// Load all ads based on remote config
  void _loadAllAds() {
    if (!shouldShowAds) {
      print('⚠️ Ads disabled in remote config');
      return;
    }

    if (!isConnected.value) {
      print('⚠️ No internet connection - Ads will not load');
      return;
    }

    print('🔄 Loading ads...');
    if (isBannerAdsEnabled) {
      print('  → Loading Banner Ad');
      loadBannerAd();
    }
    if (isInterstitialAdsEnabled) {
      print('  → Loading Interstitial Ad');
      loadInterstitialAd();
    }
    if (isRewardedAdsEnabled) {
      print('  → Loading Rewarded Ad');
      loadRewardedAd();
    }
  }

  /// Dispose all ads
  void _disposeAllAds() {
    print('🗑️ Disposing all ads...');

    if (bannerAd != null) {
      bannerAd?.dispose();
      bannerAd = null;
      isBannerAdLoaded.value = false;
    }

    if (interstitialAd != null) {
      interstitialAd?.dispose();
      interstitialAd = null;
      isInterstitialAdLoaded.value = false;
    }

    if (rewardedAd != null) {
      rewardedAd?.dispose();
      rewardedAd = null;
      isRewardedAdLoaded.value = false;
    }

    for (var ad in _nativeAds.values) {
      ad.dispose();
    }
    _nativeAds.clear();
  }

  // ==================== BANNER AD ====================

  /// Load Banner Ad
  void loadBannerAd() {
    if (!isBannerAdsEnabled || !isConnected.value) {
      print('⚠️ Banner ads disabled or no internet');
      return;
    }

    bannerAd?.dispose();
    bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          isBannerAdLoaded.value = true;
          print('✅ Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner ad failed: ${error.message} (${error.code})');
          ad.dispose();
          bannerAd = null;
          isBannerAdLoaded.value = false;

          // Retry only if internet is available
          if (isConnected.value) {
            Future.delayed(const Duration(seconds: 30), loadBannerAd);
          }
        },
        onAdOpened: (ad) => print('👆 Banner ad opened'),
        onAdClosed: (ad) => print('🔒 Banner ad closed'),
      ),
    );
    bannerAd!.load();
  }

  /// Banner Widget with beautiful UI
  static Widget bannerWidget({Color? backgroundColor, bool showShadow = true}) {
    return Obx(() {
      if (_instance.isBannerAdsEnabled &&
          _instance.isBannerAdLoaded.value &&
          _instance.bannerAd != null) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            boxShadow:
            showShadow
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ]
                : null,
          ),
          alignment: Alignment.center,
          child: AdWidget(ad: _instance.bannerAd!),
        );
      }
      return const SizedBox.shrink();
    });
  }

  // ==================== INTERSTITIAL AD ====================

  /// Load Interstitial Ad
  void loadInterstitialAd() {
    if (!isInterstitialAdsEnabled || !isConnected.value) {
      print('⚠️ Interstitial ads disabled or no internet');
      return;
    }

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          isInterstitialAdLoaded.value = true;
          print('✅ Interstitial ad loaded successfully');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent:
                (ad) => print('📺 Interstitial showing'),
            onAdDismissedFullScreenContent: (ad) {
              print('🔒 Interstitial dismissed');
              ad.dispose();
              interstitialAd = null;
              isInterstitialAdLoaded.value = false;
              if (isConnected.value && isInterstitialAdsEnabled) {
                loadInterstitialAd();
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ Interstitial show failed: ${error.message}');
              ad.dispose();
              interstitialAd = null;
              isInterstitialAdLoaded.value = false;
              if (isConnected.value && isInterstitialAdsEnabled) {
                loadInterstitialAd();
              }
            },
          );
        },
        onAdFailedToLoad: (error) {
          interstitialAd = null;
          isInterstitialAdLoaded.value = false;
          print('❌ Interstitial load failed: ${error.message} (${error.code})');

          // Retry only if internet is available
          if (isConnected.value) {
            Future.delayed(const Duration(seconds: 60), () {
              if (isConnected.value && isInterstitialAdsEnabled) {
                loadInterstitialAd();
              }
            });
          }
        },
      ),
    );
  }

  /// Show Interstitial Ad (for workout completion)
  void showInterstitialAd() {
    if (!isInterstitialAdsEnabled || !isConnected.value) return;

    interstitialAdCounter.value++;

    // Show ad based on remote config frequency
    if (interstitialAdCounter.value >= interstitialWorkoutFrequency) {
      if (isInterstitialAdLoaded.value && interstitialAd != null) {
        interstitialAd!.show();
        interstitialAdCounter.value = 0;
      }
    }
  }

  // ==================== NAVIGATION WITH ADS ====================

  /// Navigate with automatic ad display
  static Future<T?>? navigateWithAd<T>(
      String route, {
        dynamic arguments,
        Function? onComplete,
      }) async {
    _instance._navigationCounter++;
    print('📢 Navigation counter: ${_instance._navigationCounter}');

    // Check if should show ad based on remote config frequency
    if (_instance.isInterstitialAdsEnabled &&
        _instance._navigationCounter >=
            _instance.interstitialNavigationFrequency &&
        _instance.isInterstitialAdLoaded.value &&
        _instance.interstitialAd != null) {
      _instance._navigationCounter = 0;

      // Show loading dialog
      _showAdLoadingDialog();
      await Future.delayed(const Duration(seconds: 2));

      // Set up callback BEFORE showing ad
      _instance
          .interstitialAd!
          .fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('📺 Interstitial ad showed');
          _dismissAdLoadingDialog();
        },
        onAdDismissedFullScreenContent: (ad) {
          print('✅ Ad dismissed - Now navigating to $route');
          _dismissAdLoadingDialog();

          ad.dispose();
          _instance.interstitialAd = null;
          _instance.isInterstitialAdLoaded.value = false;
          _instance.loadInterstitialAd();

          // Navigate after ad is dismissed
          if (arguments != null) {
            Get.toNamed<T>(route, arguments: arguments)?.then((value) {
              onComplete?.call();
              return value;
            });
          } else {
            Get.toNamed<T>(route)?.then((value) {
              onComplete?.call();
              return value;
            });
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ Interstitial show failed: ${error.message}');
          _dismissAdLoadingDialog();

          ad.dispose();
          _instance.interstitialAd = null;
          _instance.isInterstitialAdLoaded.value = false;
          _instance.loadInterstitialAd();

          // Navigate anyway if ad fails
          if (arguments != null) {
            Get.toNamed<T>(route, arguments: arguments)?.then((value) {
              onComplete?.call();
              return value;
            });
          } else {
            Get.toNamed<T>(route)?.then((value) {
              onComplete?.call();
              return value;
            });
          }
        },
      );

      _instance.interstitialAd!.show();
      return null;
    } else {
      // Navigate directly without ad
      if (arguments != null) {
        return Get.toNamed<T>(route, arguments: arguments)?.then((value) {
          onComplete?.call();
          return value;
        });
      } else {
        return Get.toNamed<T>(route)?.then((value) {
          onComplete?.call();
          return value;
        });
      }
    }
  }

  /// ✅ Action with Ad — Navigate વગર
  /// Button click → Ad show → Ad close → callback (download/process start)
  static void showAdThenAction({required Function onActionComplete}) async {
    _instance._navigationCounter++;
    print('📢 Navigation counter: ${_instance._navigationCounter}');

    // Check if should show ad based on remote config frequency
    if (_instance.isInterstitialAdsEnabled &&
        _instance._navigationCounter >=
            _instance.interstitialNavigationFrequency &&
        _instance.isInterstitialAdLoaded.value &&
        _instance.interstitialAd != null) {
      _instance._navigationCounter = 0;

      // Show loading dialog
      _showAdLoadingDialog();
      await Future.delayed(const Duration(seconds: 2));

      // Set up callback BEFORE showing ad
      _instance
          .interstitialAd!
          .fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('📺 Interstitial ad showed');
          _dismissAdLoadingDialog();
        },
        onAdDismissedFullScreenContent: (ad) {
          print('✅ Ad dismissed - Now navigating to ');
          _dismissAdLoadingDialog();

          ad.dispose();
          _instance.interstitialAd = null;
          _instance.isInterstitialAdLoaded.value = false;
          _instance.loadInterstitialAd();

          onActionComplete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ Interstitial show failed: ${error.message}');
          _dismissAdLoadingDialog();

          ad.dispose();
          _instance.interstitialAd = null;
          _instance.isInterstitialAdLoaded.value = false;
          _instance.loadInterstitialAd();

          onActionComplete();
        },
      );

      _instance.interstitialAd!.show();
      return null;
    } else {
      onActionComplete();
    }
  }

  /// Increment navigation counter - Call this on every navigation
  void incrementNavigationCounter() {
    if (!isInterstitialAdsEnabled || !isConnected.value) return;
    _navigationCounter++;
    print('📍 Navigation counter: $_navigationCounter');
  }

  /// Check if should show interstitial ad based on navigation
  bool shouldShowNavigationAd() {
    if (!isInterstitialAdsEnabled || !isConnected.value) return false;
    if (!isInterstitialAdLoaded.value) return false;

    if (_navigationCounter >= interstitialNavigationFrequency) {
      _navigationCounter = 0;
      return true;
    }

    return false;
  }

  /// Show Interstitial Ad with callback (for navigation)
  void showInterstitialAdWithCallback({Function? onAdDismissed}) {
    if (!isInterstitialAdsEnabled || !isConnected.value) {
      onAdDismissed?.call();
      return;
    }

    if (interstitialAd != null && isInterstitialAdLoaded.value) {
      interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('📺 Interstitial ad showed full screen');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('🔒 Interstitial ad dismissed');
          ad.dispose();
          interstitialAd = null;
          isInterstitialAdLoaded.value = false;
          if (isConnected.value) loadInterstitialAd();
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ Interstitial ad failed to show: $error');
          ad.dispose();
          interstitialAd = null;
          isInterstitialAdLoaded.value = false;
          if (isConnected.value) loadInterstitialAd();
          onAdDismissed?.call();
        },
      );

      interstitialAd!.show();
    } else {
      print('⚠️ Interstitial ad not ready');
      onAdDismissed?.call();
    }
  }

  /// Reset navigation counter
  static void resetNavigationCounter() {
    _instance._navigationCounter = 0;
  }

  // ==================== AD LOADING DIALOG ====================

  static bool _isLoadingDialogShowing = false;

  /// Show beautiful loading dialog
  static void _showAdLoadingDialog() {
    if (_isLoadingDialogShowing) return;
    _isLoadingDialogShowing = true;

    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated loader
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Get.theme.colorScheme.primary,
                        Get.theme.colorScheme.primary.withValues(alpha: 0.6),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.video_library_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Loading Ad...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Please wait a moment',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Animated dots
                const _AnimatedDots(),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
    );
  }

  /// Dismiss loading dialog
  static void _dismissAdLoadingDialog() {
    if (!_isLoadingDialogShowing) return;
    _isLoadingDialogShowing = false;

    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  // ==================== REWARDED AD ====================

  /// Load Rewarded Ad
  void loadRewardedAd() {
    if (!isRewardedAdsEnabled || !isConnected.value) {
      print('⚠️ Rewarded ads disabled or no internet');
      return;
    }

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
          isRewardedAdLoaded.value = true;
          print('✅ Rewarded ad loaded successfully');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent:
                (ad) => print('📺 Rewarded ad showing'),
            onAdDismissedFullScreenContent: (ad) {
              print('🔒 Rewarded ad dismissed');
              ad.dispose();
              rewardedAd = null;
              isRewardedAdLoaded.value = false;
              if (isConnected.value && isRewardedAdsEnabled) {
                loadRewardedAd();
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ Rewarded show failed: ${error.message}');
              ad.dispose();
              rewardedAd = null;
              isRewardedAdLoaded.value = false;
              if (isConnected.value && isRewardedAdsEnabled) {
                loadRewardedAd();
              }
            },
          );
        },
        onAdFailedToLoad: (error) {
          isRewardedAdLoaded.value = false;
          print('❌ Rewarded load failed: ${error.message} (${error.code})');

          // Retry only if internet is available
          if (isConnected.value) {
            Future.delayed(const Duration(seconds: 60), () {
              if (isConnected.value && isRewardedAdsEnabled) {
                loadRewardedAd();
              }
            });
          }
        },
      ),
    );
  }

  /// Show Rewarded Ad
  static Future<bool> showRewardedAd({String? message}) async {
    if (!_instance.isRewardedAdsEnabled || !_instance.isConnected.value) {
      Get.snackbar(
        'No Internet',
        'Please check your connection',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (!_instance.isRewardedAdLoaded.value || _instance.rewardedAd == null) {
      Get.snackbar(
        'Ad Not Ready',
        message ?? 'Please try again in a moment',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    bool rewarded = false;
    final Completer<bool> adCompleter = Completer<bool>();

    try {
      _instance
          .rewardedAd!
          .fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          print('🔴 Ad dismissed - Rewarded: $rewarded');
          ad.dispose();
          _instance.rewardedAd = null;
          _instance.isRewardedAdLoaded.value = false;
          _instance.loadRewardedAd();

          adCompleter.complete(rewarded);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ Ad failed: $error');
          ad.dispose();
          _instance.rewardedAd = null;
          _instance.isRewardedAdLoaded.value = false;
          _instance.loadRewardedAd();

          adCompleter.complete(false);
        },
      );

      await _instance.rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('🎁 User earned reward: ${reward.amount} ${reward.type}');
          rewarded = true;
        },
      );

      return await adCompleter.future;
    } catch (e) {
      print('❌ Error showing rewarded ad: $e');
      return false;
    }
  }

  // ==================== NATIVE AD ====================

  /// Get dynamic height based on template type
  static double _getHeightForTemplate(TemplateType templateType) {
    switch (templateType) {
      case TemplateType.small:
        return 90;
      case TemplateType.medium:
        return 350;
      default:
        return 350;
    }
  }

  /// Create Native Ad
  static NativeAd createNativeAd({
    required String adId,
    required BuildContext context,
    TemplateType templateType = TemplateType.medium,
    required VoidCallback onAdLoaded,
    required Function(LoadAdError) onAdFailedToLoad,
  }) {
    // Check if native ads are enabled
    if (!_instance.isNativeAdsEnabled || !_instance.isConnected.value) {
      throw Exception('Native ads disabled or no internet');
    }

    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final nativeAd = NativeAd(
      adUnitId: _instance.nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _instance._nativeAds[adId] = ad as NativeAd;
          onAdLoaded();
          print('✅ Native ad loaded: $adId');
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Native ad failed ($adId): ${error.message} (${error.code})');
          ad.dispose();
          onAdFailedToLoad(error);
        },
        onAdOpened: (ad) => print('👆 Native ad opened: $adId'),
        onAdClosed: (ad) => print('🔒 Native ad closed: $adId'),
        onAdClicked: (ad) => print('🖱️ Native ad clicked: $adId'),
        onAdImpression: (ad) => print('👁️ Native ad impression: $adId'),
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: templateType,

        // ✅ FIX: App dark card color — white background removed
        mainBackgroundColor: const Color(0xFF111827),
        cornerRadius: 14.0,
        // CTA Button — app orange gradient
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFFFF6B35),
          style: NativeTemplateFontStyle.bold,
          size: templateType == TemplateType.small ? 12.0 : 14.0,
        ),

        // Title — white text
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: templateType == TemplateType.small ? 13.0 : 15.0,
        ),

        // Description — muted gray
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF9CA3AF),
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: templateType == TemplateType.small ? 11.0 : 13.0,
        ),

        // Extra — darker gray
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF6B7280),
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: templateType == TemplateType.small ? 10.0 : 11.0,
        ),
      ),
    );

    nativeAd.load();
    return nativeAd;
  }

  /// Native Ad Widget
  /// [isLarge] = true → large ad (with media), false → small ad (compact)
  static Widget nativeWidget({
    required String adId,
    required BuildContext context,
    bool isLarge = false,           // ✅ simple toggle: small vs large
    double? height,
    bool showLabel = true,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
  }) {
    if (!_instance.isNativeAdsEnabled) {
      return const SizedBox.shrink();
    }

    return _NativeAdWidget(
      adId: adId,
      isLarge: isLarge,
      height: height ?? (isLarge ? 310.0 : 72.0),
      showLabel: showLabel,
      margin: margin,
      borderRadius: borderRadius,
    );
  }

  /// Dispose specific native ad
  static void disposeNativeAd(String adId) {
    _instance._nativeAds[adId]?.dispose();
    _instance._nativeAds.remove(adId);
    print('🗑️ Native ad disposed: $adId');
  }

// ==================== CLEANUP ====================
//
// static void dispose() {
//   _instance._disposeAllAds();
// }
}

// ==================== NATIVE AD WIDGET ====================

// App dark palette
const _kAdDarkCard = Color(0xFF111827);
const _kAdOrange   = Color(0xFFFF6B35);
const _kAdPink     = Color(0xFFE91E63);

class _NativeAdWidget extends StatefulWidget {
  final String adId;
  final bool isLarge;
  final double height;
  final bool showLabel;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;

  const _NativeAdWidget({
    required this.adId,
    this.isLarge = false,
    this.height = 72,
    this.showLabel = true,
    this.margin,
    this.borderRadius,
  });

  @override
  State<_NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<_NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isFailed = false;

  // ✅ factoryId — matches MainActivity.kt registration
  String get _factoryId =>
      widget.isLarge ? 'native_ad_large' : 'native_ad_small';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!AdService._instance.isNativeAdsEnabled ||
        !AdService._instance.isConnected.value) {
      if (mounted) setState(() => _isFailed = true);
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: AdService._instance.nativeAdUnitId,
      factoryId: _factoryId, // ✅ Custom Android XML layout
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
          debugPrint('✅ Native Ad loaded ($_factoryId)');
        },
        onAdFailedToLoad: (_, error) {
          if (mounted) setState(() => _isFailed = true);
          debugPrint('❌ Native Ad failed: ${error.message}');
        },
        onAdClicked:    (_) => debugPrint('🖱️ Native ad clicked'),
        onAdImpression: (_) => debugPrint('👁️ Native ad impression'),
      ),
      request: const AdRequest(),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    AdService._instance._nativeAds.remove(widget.adId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFailed) return const SizedBox.shrink();

    final br = widget.borderRadius ?? BorderRadius.circular(14);
    final totalH = widget.showLabel
        ? widget.height + 36.0
        : widget.height;

    // Loading placeholder
    if (!_isLoaded || _nativeAd == null) {
      return Container(
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 6),
        height: totalH,
        decoration: BoxDecoration(
          color: _kAdDarkCard,
          borderRadius: br,
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_kAdOrange),
                ),
              ),
              const SizedBox(width: 10),
              Text('Loading ad...',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.3),
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
      );
    }

    // Ad loaded
    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: _kAdDarkCard,
        borderRadius: br,
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: _kAdOrange.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sponsored label
            if (widget.showLabel)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _kAdOrange.withOpacity(0.12),
                    _kAdPink.withOpacity(0.06),
                  ]),
                  border: Border(
                    bottom: BorderSide(
                        color: Colors.white.withOpacity(0.07), width: 1),
                  ),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _kAdOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.campaign_rounded,
                        size: 11, color: _kAdOrange),
                  ),
                  const SizedBox(width: 7),
                  const Text('Sponsored',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_kAdOrange, _kAdPink]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Ad',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        )),
                  ),
                ]),
              ),

            // ✅ Android XML layout rendered here
            SizedBox(
              height: widget.height,
              child: AdWidget(ad: _nativeAd!),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== APP UPDATE DIALOG ====================

class _AppUpdateDialog extends StatefulWidget {
  final String currentVersion;
  final String latestVersion;
  final String title;
  final String message;
  final bool isForced;
  final String storeUrl;

  const _AppUpdateDialog({
    required this.currentVersion,
    required this.latestVersion,
    required this.title,
    required this.message,
    required this.isForced,
    required this.storeUrl,
  });

  @override
  State<_AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<_AppUpdateDialog>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;

  late Animation<double> _scale;
  late Animation<double> _slideUp;
  late Animation<double> _pulse;
  late Animation<double> _shimmer;

  bool _isLaunching = false;

  // ── Colors ──────────────────────────────────────────────────────────────────
  static const _electric = Color(0xFF4F8EFF);
  static const _neon = Color(0xFF00E5A0);
  static const _fire = Color(0xFFFF6B35);
  static const _darkCard = Color(0xFF1E2535);
  static const _darkBdr = Color(0xFF2A3347);
  static const List<Color> _heroGrad = [Color(0xFF1A2AFF), Color(0xFF4F8EFF)];

  bool get _isDark => true;

  Color get _card => _isDark ? _darkCard : Colors.white;

  Color get _bdr => _isDark ? _darkBdr : const Color(0xFFE0E8FF);

  Color get _textP => _isDark ? Colors.white : const Color(0xFF0D0F14);

  Color get _textS =>
      _isDark ? const Color(0xFF8899BB) : const Color(0xFF5E6B8A);

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _scale = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack));
    _slideUp = Tween<double>(
      begin: 48,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _shimmer = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _openStore() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLaunching = true);
    if (widget.storeUrl.isNotEmpty) {
      final uri = Uri.parse(widget.storeUrl);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _isLaunching = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder:
          (ctx, child) => Transform.translate(
        offset: Offset(0, _slideUp.value),
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 40),
        child: SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _bdr, width: 1),
              boxShadow: [
                BoxShadow(
                  color: _electric.withValues(alpha: _isDark ? 0.28 : 0.14),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isDark ? 0.45 : 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGradientHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                  child: Column(
                    children: [
                      _buildVersionBadges(),
                      const SizedBox(height: 16),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: _textS,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.isForced) ...[
                        const SizedBox(height: 14),
                        _buildForceNotice(),
                      ],
                      const SizedBox(height: 20),
                      _buildUpdateButton(),
                      if (!widget.isForced) ...[
                        const SizedBox(height: 10),
                        _buildSkipButton(),
                      ],
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ), // SizedBox
      ),
    );
  }

  // ── Gradient header ────────────────────────────────────────────────────────
  Widget _buildGradientHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: _heroGrad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -18,
            right: -18,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -22,
            left: -10,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder:
                      (ctx, child) =>
                      Transform.scale(scale: _pulse.value, child: child),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🚀', style: TextStyle(fontSize: 30)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Version badges ─────────────────────────────────────────────────────────
  Widget _buildVersionBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _versionChip(
          label: 'Current',
          ver: widget.currentVersion,
          color: _textS,
          bg:
          _isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.arrow_forward_rounded, color: _electric, size: 20),
        ),
        _versionChip(
          label: 'Latest',
          ver: widget.latestVersion,
          color: _neon,
          bg: _neon.withValues(alpha: 0.12),
          glowing: true,
        ),
      ],
    );
  }

  Widget _versionChip({
    required String label,
    required String ver,
    required Color color,
    required Color bg,
    bool glowing = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: glowing ? color.withValues(alpha: 0.4) : _bdr,
          width: 1,
        ),
        boxShadow:
        glowing
            ? [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ]
            : [],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'v$ver',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Force notice ───────────────────────────────────────────────────────────
  Widget _buildForceNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _fire.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fire.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _fire, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'This update is required to continue using the app.',
              style: const TextStyle(
                fontSize: 12,
                color: _fire,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Update button ──────────────────────────────────────────────────────────
  Widget _buildUpdateButton() {
    return GestureDetector(
      onTap: _isLaunching ? null : _openStore,
      child: AnimatedBuilder(
        animation: _shimmerCtrl,
        builder:
            (ctx, child) => Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: _heroGrad),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _electric.withValues(alpha: 0.42),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Shimmer sweep
                if (!_isLaunching)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(
                        _shimmer.value * MediaQuery.of(context).size.width,
                        0,
                      ),
                      child: Container(
                        width: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.14),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Center(
                  child:
                  _isLaunching
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.system_update_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Update Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Skip button ────────────────────────────────────────────────────────────
  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        height: 44,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _bdr, width: 1),
        ),
        child: Center(
          child: Text(
            'Maybe Later',
            style: TextStyle(
              color: _textS,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== ANIMATED DOTS WIDGET ====================

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _dotCount = IntTween(
      begin: 0,
      end: 3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                index <= _dotCount.value
                    ? Get.theme.colorScheme.primary
                    : Colors.grey[300],
              ),
            );
          }),
        );
      },
    );
  }
}