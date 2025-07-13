  // // ignore_for_file: avoid_print

  // import 'package:firebase_remote_config/firebase_remote_config.dart';
  // import 'package:flutter/foundation.dart';
  // import 'package:google_mobile_ads/google_mobile_ads.dart';
  // Enhanced RemoteConfigService with more Open App Ads configurations
  // ignore_for_file: avoid_print

  import 'package:firebase_remote_config/firebase_remote_config.dart';
  import 'package:flutter/foundation.dart';
  import 'package:google_mobile_ads/google_mobile_ads.dart';

  class RemoteConfigService {
    static final RemoteConfigService _instance = RemoteConfigService._internal();
    factory RemoteConfigService() => _instance;
    RemoteConfigService._internal();

    final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

    Future<void> initialize() async {
      try {
        // Set default values
        await _remoteConfig.setDefaults({
          // Global
          'ads_enabled': true,
          'ads_test_mode': kDebugMode, // Automatically enable test mode in debug
          'ads_load_timeout': 10,

          // Banner
          'banner_ads_enabled': true,
          'banner_ad_unit_id_production':
              'ca-app-pub-7772180367051787/8438591704',
          'banner_ad_unit_id_test': 'ca-app-pub-3940256099942544/2247696110',
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
              'ca-app-pub-7772180367051787/1234567890',
          'interstitial_ad_unit_id_test':
              'ca-app-pub-3940256099942544/1033173712',
          'interstitial_click_threshold': 3,

          // Open App Ads - Enhanced Configuration
          'open_app_ads_enabled': true,
          'open_app_ad_unit_id_production':
              'ca-app-pub-7772180367051787/1508762400', // Use your actual Open App ad unit ID
          'open_app_ad_unit_id_test':
              'ca-app-pub-3940256099942544/9257395921', // Correct test ID for Open App Ads
          'open_app_ad_timeout': 4, // Hours before ad expires
          'open_app_ad_show_frequency':
              1, // Show every X app opens (1 = every time)
          'open_app_ad_first_launch_delay':
              2, // Seconds to wait before showing on first launch
          'open_app_ad_resume_delay':
              100, // Milliseconds to wait before showing on app resume
          'open_app_ad_min_interval': 30, // Minimum seconds between ad shows
          'open_app_ad_max_daily_shows': 10, // Maximum times to show per day
          'open_app_ad_show_on_first_launch':
              true, // Whether to show on very first app launch
          'open_app_ad_show_on_cold_start':
              true, // Whether to show on cold starts
          'open_app_ad_show_on_warm_start':
              true, // Whether to show on warm starts
          'open_app_ad_preload_timeout': 30, // Seconds to timeout ad loading
          'open_app_ad_retry_attempts':
              3, // Number of retry attempts for failed loads
          'open_app_ad_retry_delay': 5, // Seconds between retry attempts
        });

        // Set config settings
        await _remoteConfig.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(seconds: 30),
            minimumFetchInterval:
                kDebugMode
                    ? const Duration(seconds: 10) // Reduced for testing
                    : const Duration(hours: 1), // Reduced from 12 hours
          ),
        );

        // Fetch and activate
        await _fetchAndActivate();

        if (kDebugMode) {
          _logAllParameters();
        }
      } catch (e) {
        if (kDebugMode) {
          print('RemoteConfig initialization error: $e');
        }
      }
    }

    Future<bool> _fetchAndActivate() async {
      try {
        final updated = await _remoteConfig.fetchAndActivate();
        if (kDebugMode) {
          print('RemoteConfig updated: $updated');
        }
        return updated;
      } catch (e) {
        if (kDebugMode) {
          print('RemoteConfig fetch error: $e');
        }
        return false;
      }
    }

    void _logAllParameters() {
      final parameters = _remoteConfig.getAll();
      print('╔═══════════════════════════════════════════');
      print('║ RemoteConfig Parameters');
      print('╠═══════════════════════════════════════════');
      parameters.forEach((key, value) {
        print('║ $key: ${value.asString()}');
      });
      print('╚═══════════════════════════════════════════');
    }

    // Force refresh configuration (useful for testing)
    Future<void> forceRefresh() async {
      try {
        await _remoteConfig.fetch();
        await _remoteConfig.activate();
        if (kDebugMode) {
          print('RemoteConfig force refreshed');
          _logAllParameters();
        }
      } catch (e) {
        if (kDebugMode) {
          print('RemoteConfig force refresh error: $e');
        }
      }
    }

    // Getters for ads parameters
    bool get adsEnabled => _remoteConfig.getBool('ads_enabled');
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

    // Method to get all Open App Ads configuration as a map (useful for debugging)
    Map<String, dynamic> get openAppAdsConfig => {
      'enabled': openAppAdsEnabled,
      'ad_unit_id': openAppAdUnitId,
      'timeout_hours': openAppAdTimeout,
      'show_frequency': openAppAdShowFrequency,
      'first_launch_delay_seconds': openAppAdFirstLaunchDelay,
      'resume_delay_ms': openAppAdResumeDelay,
      'min_interval_seconds': openAppAdMinInterval,
      'max_daily_shows': openAppAdMaxDailyShows,
      'show_on_first_launch': openAppAdShowOnFirstLaunch,
      'show_on_cold_start': openAppAdShowOnColdStart,
      'show_on_warm_start': openAppAdShowOnWarmStart,
      'preload_timeout_seconds': openAppAdPreloadTimeout,
      'retry_attempts': openAppAdRetryAttempts,
      'retry_delay_seconds': openAppAdRetryDelay,
    };
  }

// class RemoteConfigService {
//   static final RemoteConfigService _instance = RemoteConfigService._internal();
//   factory RemoteConfigService() => _instance;
//   RemoteConfigService._internal();

//   final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

//   Future<void> initialize() async {
//     try {
//       // Set default values
//       await _remoteConfig.setDefaults({
//         // Global
//         'ads_enabled': true,
//         'ads_test_mode': kDebugMode, // Automatically enable test mode in debug
//         'ads_load_timeout': 10,

//         // Banner
//         'banner_ads_enabled': true,
//         'banner_ad_unit_id_production':
//             'ca-app-pub-7772180367051787/8438591704',
//         'banner_ad_unit_id_test': 'ca-app-pub-3940256099942544/6300978111',
//         'banner_ad_refresh_rate': 60,

//         // Native
//         'native_ads_enabled': true,
//         'native_ad_unit_id_production':
//             'ca-app-pub-7772180367051787/6519005372',
//         'native_ad_unit_id_test': 'ca-app-pub-3940256099942544/2247696110',
//         'native_ad_template_type': 'medium',
//         'native_ad_corner_radius': 10,

//         // Interstitial
//         'interstitial_ads_enabled': true,
//         'interstitial_ad_unit_id_production':
//             'ca-app-pub-7772180367051787/1234567890',
//         'interstitial_ad_unit_id_test':
//             'ca-app-pub-3940256099942544/1033173712',
//         'interstitial_click_threshold': 3,

//         // Open App Ads
//         'open_app_ads_enabled': true,
//         'open_app_ad_unit_id_production':
//             'ca-app-pub-7772180367051787/1508762400', 
//         'open_app_ad_unit_id_test': 'ca-app-pub-3940256099942544/3419835294',
//         'open_app_ad_timeout': 4, // Hours before ad expires
//         'open_app_ad_show_frequency':
//             1, // Show every X app opens (1 = every time)
//       });

//       // Set config settings
//       await _remoteConfig.setConfigSettings(
//         RemoteConfigSettings(
//           fetchTimeout: const Duration(seconds: 30),
//           minimumFetchInterval:
//               kDebugMode
//                   ? const Duration(seconds: 10) // Reduced for testing
//                   : const Duration(hours: 1), // Reduced from 12 hours
//         ),
//       );

//       // Fetch and activate
//       await _fetchAndActivate();

//       if (kDebugMode) {
//         _logAllParameters();
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('RemoteConfig initialization error: $e');
//       }
//     }
//   }

//   Future<bool> _fetchAndActivate() async {
//     try {
//       final updated = await _remoteConfig.fetchAndActivate();
//       if (kDebugMode) {
//         print('RemoteConfig updated: $updated');
//       }
//       return updated;
//     } catch (e) {
//       if (kDebugMode) {
//         print('RemoteConfig fetch error: $e');
//       }
//       return false;
//     }
//   }

//   void _logAllParameters() {
//     final parameters = _remoteConfig.getAll();
//     print('╔═══════════════════════════════════════════');
//     print('║ RemoteConfig Parameters');
//     print('╠═══════════════════════════════════════════');
//     parameters.forEach((key, value) {
//       print('║ $key: ${value.asString()}');
//     });
//     print('╚═══════════════════════════════════════════');
//   }

//   // Getters for ads parameters
//   bool get adsEnabled => _remoteConfig.getBool('ads_enabled');
//   bool get adsTestMode => _remoteConfig.getBool('ads_test_mode');
//   int get adsLoadTimeout => _remoteConfig.getInt('ads_load_timeout');

//   // Banner ads getters
//   bool get bannerAdsEnabled => _remoteConfig.getBool('banner_ads_enabled');
//   String get bannerAdUnitId =>
//       (kDebugMode || adsTestMode)
//           ? _remoteConfig.getString('banner_ad_unit_id_test')
//           : _remoteConfig.getString('banner_ad_unit_id_production');
//   int get bannerAdRefreshRate => _remoteConfig.getInt('banner_ad_refresh_rate');

//   // Native ads getters
//   bool get nativeAdsEnabled => _remoteConfig.getBool('native_ads_enabled');
//   String get nativeAdUnitId =>
//       (kDebugMode || adsTestMode)
//           ? _remoteConfig.getString('native_ad_unit_id_test')
//           : _remoteConfig.getString('native_ad_unit_id_production');
//   TemplateType get nativeAdTemplateType {
//     final type = _remoteConfig.getString('native_ad_template_type');
//     return type == 'small' ? TemplateType.small : TemplateType.medium;
//   }

//   double get nativeAdCornerRadius =>
//       _remoteConfig.getInt('native_ad_corner_radius').toDouble();

//   // Interstitial ads getters
//   bool get interstitialAdsEnabled =>
//       _remoteConfig.getBool('interstitial_ads_enabled');
//   String get interstitialAdUnitId =>
//       (kDebugMode || adsTestMode)
//           ? _remoteConfig.getString('interstitial_ad_unit_id_test')
//           : _remoteConfig.getString('interstitial_ad_unit_id_production');
//   int get interstitialClickThreshold =>
//       _remoteConfig.getInt('interstitial_click_threshold');

//   // Open App Ads getters
//   bool get openAppAdsEnabled => _remoteConfig.getBool('open_app_ads_enabled');
//   String get openAppAdUnitId =>
//       (kDebugMode || adsTestMode)
//           ? _remoteConfig.getString('open_app_ad_unit_id_test')
//           : _remoteConfig.getString('open_app_ad_unit_id_production');
//   int get openAppAdTimeout => _remoteConfig.getInt('open_app_ad_timeout');
//   int get openAppAdShowFrequency =>
//       _remoteConfig.getInt('open_app_ad_show_frequency');
// }
