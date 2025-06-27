// import 'package:auto_clipper_app/Logic/open_app_ads_controller.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';


// /// Manages app lifecycle and shows open app ads when appropriate
// class AppLifecycleManager extends WidgetsBindingObserver {
//   static final AppLifecycleManager _instance = AppLifecycleManager._internal();
//   factory AppLifecycleManager() => _instance;
//   AppLifecycleManager._internal();

//   final AppOpenAdManager _adManager = AppOpenAdManager();
//   AppLifecycleState? _currentState;
//   DateTime? _backgroundTime;

//   /// Minimum time app should be in background before showing ad on resume
//   static const Duration _minimumBackgroundDuration = Duration(seconds: 30);

//   /// Initialize the lifecycle manager
//   void initialize() {
//     WidgetsBinding.instance.addObserver(this);
//     // Preload an ad for future use
//     _adManager.loadAd();
//   }

//   /// Dispose the lifecycle manager
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _adManager.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     debugPrint('App lifecycle state changed to: $state');

//     switch (state) {
//       case AppLifecycleState.resumed:
//         _onAppResumed();
//         break;
//       case AppLifecycleState.paused:
//         _onAppPaused();
//         break;
//       case AppLifecycleState.detached:
//       case AppLifecycleState.inactive:
//         // Handle if needed
//         break;
//       case AppLifecycleState.hidden:
//         // Handle if needed
//         break;
//     }

//     _currentState = state;
//   }

//   void _onAppResumed() {
//     debugPrint('App resumed');

//     // Check if app was in background long enough
//     if (_backgroundTime != null) {
//       final backgroundDuration = DateTime.now().difference(_backgroundTime!);
//       debugPrint(
//         'App was in background for: ${backgroundDuration.inSeconds} seconds',
//       );

//       if (backgroundDuration >= _minimumBackgroundDuration) {
//         // Show ad if available
//         final adShown = _adManager.showAdIfAvailable();
//         if (adShown) {
//           debugPrint('Showing open app ad on app resume');
//         } else {
//           debugPrint('No ad available on app resume, loading new ad');
//           _adManager.loadAd();
//         }
//       }
//     }

//     _backgroundTime = null;
//   }

//   void _onAppPaused() {
//     debugPrint('App paused');
//     _backgroundTime = DateTime.now();
//   }

//   /// Manually show ad if available (useful for specific triggers)
//   bool showAdIfAvailable() {
//     return _adManager.showAdIfAvailable();
//   }

//   /// Preload an ad for future use
//   void preloadAd() {
//     _adManager.loadAd();
//   }

//   /// Check if an ad is currently available
//   bool get isAdAvailable => _adManager.isAdAvailable;

//   /// Check if an ad is currently being shown
//   bool get isShowingAd => _adManager.isShowingAd;
// }
