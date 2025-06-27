// import 'package:auto_clipper_app/comman%20class/remot_config.dart';
// import 'package:auto_clipper_app/widget/applife_cycle.dart';
// import 'package:flutter/foundation.dart';


// /// Helper class to manage ads throughout the app
// class AdsHelper {
//   static final AdsHelper _instance = AdsHelper._internal();
//   factory AdsHelper() => _instance;
//   AdsHelper._internal();

//   final AppLifecycleManager _lifecycleManager = AppLifecycleManager();
//   final RemoteConfigService _remoteConfig = RemoteConfigService();

//   /// Show open app ad with optional callback
//   static bool showOpenAppAd({VoidCallback? onAdDismissed}) {
//     final instance = AdsHelper();

//     if (!instance._remoteConfig.adsEnabled ||
//         !instance._remoteConfig.openAppAdsEnabled) {
//       debugPrint('Open app ads are disabled');
//       onAdDismissed?.call();
//       return false;
//     }

//     final adShown = instance._lifecycleManager.showAdIfAvailable();

//     if (adShown) {
//       debugPrint('Open app ad shown successfully');
//       // If you need to handle callbacks, you might need to modify AppOpenAdManager
//       // to accept callback parameters
//     } else {
//       debugPrint('No open app ad available');
//       onAdDismissed?.call();
//     }

//     return adShown;
//   }

//   /// Preload open app ad for future use
//   static void preloadOpenAppAd() {
//     final instance = AdsHelper();

//     if (!instance._remoteConfig.adsEnabled ||
//         !instance._remoteConfig.openAppAdsEnabled) {
//       debugPrint('Open app ads are disabled, skipping preload');
//       return;
//     }

//     instance._lifecycleManager.preloadAd();
//     debugPrint('Open app ad preload initiated');
//   }

//   /// Check if open app ad is available
//   static bool get isOpenAppAdAvailable {
//     final instance = AdsHelper();
//     return instance._lifecycleManager.isAdAvailable;
//   }

//   /// Check if open app ad is currently showing
//   static bool get isOpenAppAdShowing {
//     final instance = AdsHelper();
//     return instance._lifecycleManager.isShowingAd;
//   }

//   /// Show open app ad on specific user actions (e.g., app launch, major navigation)
//   static void showAdOnUserAction(String actionName) {
//     if (kDebugMode) {
//       debugPrint('Attempting to show open app ad for action: $actionName');
//     }

//     final adShown = showOpenAppAd();

//     if (kDebugMode) {
//       debugPrint('Ad shown for $actionName: $adShown');
//     }
//   }

//   /// Check ads configuration status
//   static Map<String, dynamic> getAdsStatus() {
//     final instance = AdsHelper();

//     return {
//       'ads_enabled': instance._remoteConfig.adsEnabled,
//       'ads_test_mode': instance._remoteConfig.adsTestMode,
//       'open_app_ads_enabled': instance._remoteConfig.openAppAdsEnabled,
//       'open_app_ad_available': isOpenAppAdAvailable,
//       'open_app_ad_showing': isOpenAppAdShowing,
//       'banner_ads_enabled': instance._remoteConfig.bannerAdsEnabled,
//       'native_ads_enabled': instance._remoteConfig.nativeAdsEnabled,
//       'interstitial_ads_enabled': instance._remoteConfig.interstitialAdsEnabled,
//     };
//   }

//   /// Debug method to print ads status
//   static void printAdsStatus() {
//     if (kDebugMode) {
//       final status = getAdsStatus();
//       print('╔═══════════════════════════════════════════');
//       print('║ Ads Status Report');
//       print('╠═══════════════════════════════════════════');
//       status.forEach((key, value) {
//         print('║ $key: $value');
//       });
//       print('╚═══════════════════════════════════════════');
//     }
//   }
// }
