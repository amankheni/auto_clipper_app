// ignore_for_file: file_names

import 'package:auto_clipper_app/Logic/open_app_ads_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:auto_clipper_app/comman%20class/remot_config.dart';


class AppLifecycleManager with WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  final RemoteConfigService _remoteConfig = RemoteConfigService();
  final OpenAppAdsManager _openAppAdsManager = OpenAppAdsManager();

  bool _isInitialized = false;
  bool _isAppInForeground = true;
  DateTime? _lastResumedTime;

  // Minimum time between app resumes to show ads (to prevent rapid fire)
  static const Duration _minTimeBetweenResumes = Duration(seconds: 3);

  void initialize() {
    if (_isInitialized) return;

    try {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;

      // Load the first ad
      _preloadOpenAppAd();

      if (kDebugMode) {
        print('AppLifecycleManager initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing AppLifecycleManager: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) {
      print('App lifecycle state changed to: $state');
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        // App is transitioning between foreground and background
        break;
      default:
        break;
    }
  }

void _handleAppResumed() {
    final now = DateTime.now();

    // Check if enough time has passed since last resume
    if (_lastResumedTime != null &&
        now.difference(_lastResumedTime!) < _minTimeBetweenResumes) {
      return;
    }

    _lastResumedTime = now;
    _isAppInForeground = true;

    // Show open app ad if available and conditions are met
    if (_remoteConfig.adsEnabled && _remoteConfig.openAppAdsEnabled) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _openAppAdsManager.showAdIfAvailable();
      });
    }
  }

  void _handleAppPaused() {
    _isAppInForeground = false;

    // Preload next ad when app goes to background
    _preloadOpenAppAd();

    if (kDebugMode) {
      print('App paused, preloading next ad');
    }
  }

  void _handleAppDetached() {
    _isAppInForeground = false;

    if (kDebugMode) {
      print('App detached');
    }
  }

  void _preloadOpenAppAd() {
    if (!_remoteConfig.adsEnabled || !_remoteConfig.openAppAdsEnabled) {
      return;
    }

    try {
      _openAppAdsManager.loadAd();
      if (kDebugMode) {
        print('Preloading open app ad');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error preloading open app ad: $e');
      }
    }
  }

  // Public methods for manual control
  void onAppResumed() {
    _handleAppResumed();
  }

  void preloadAd() {
    _preloadOpenAppAd();
  }

  void showAdNow() {
    if (_remoteConfig.adsEnabled && _remoteConfig.openAppAdsEnabled) {
      _openAppAdsManager.showAdIfAvailable();
    }
  }

  void resetAdCount() {
    _openAppAdsManager.resetAppOpenCount();
  }

  // Getters
  bool get isAppInForeground => _isAppInForeground;
  bool get isInitialized => _isInitialized;
  int get appOpenCount => _openAppAdsManager.appOpenCount;
  bool get isAdAvailable => _openAppAdsManager.isAdAvailable;

  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _openAppAdsManager.dispose();
      _isInitialized = false;

      if (kDebugMode) {
        print('AppLifecycleManager disposed');
      }
    }
  }
}
