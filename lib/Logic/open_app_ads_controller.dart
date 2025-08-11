// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:auto_clipper_app/comman%20class/remot_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenAppAdsManager {
  static final OpenAppAdsManager _instance = OpenAppAdsManager._internal();
  factory OpenAppAdsManager() => _instance;
  OpenAppAdsManager._internal();

  final RemoteConfigService _remoteConfig = RemoteConfigService();

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isLoadingAd = false;
  DateTime? _appOpenLoadTime;
  DateTime? _lastAdShownTime;
  int _appOpenCount = 0;
  int _dailyAdShowCount = 0;
  int _loadRetryCount = 0;
  String? _currentDayKey;

  // SharedPreferences keys
  static const String _keyAppOpenCount = 'app_open_count';
  static const String _keyDailyAdShowCount = 'daily_ad_show_count';
  static const String _keyLastAdShownTime = 'last_ad_shown_time';
  static const String _keyCurrentDayKey = 'current_day_key';

  /// Initialize the manager and load saved state
  Future<void> initialize() async {
    try {
      await _loadSavedState();
      _checkAndResetDailyCount();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing OpenAppAdsManager: $e');
      }
    }
  }

  /// Load saved state from SharedPreferences
  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _appOpenCount = prefs.getInt(_keyAppOpenCount) ?? 0;
      _dailyAdShowCount = prefs.getInt(_keyDailyAdShowCount) ?? 0;
      _currentDayKey = prefs.getString(_keyCurrentDayKey);

      final lastAdShownTimeString = prefs.getString(_keyLastAdShownTime);
      if (lastAdShownTimeString != null) {
        _lastAdShownTime = DateTime.tryParse(lastAdShownTimeString);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading saved state: $e');
      }
    }
  }

  /// Save current state to SharedPreferences
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyAppOpenCount, _appOpenCount);
      await prefs.setInt(_keyDailyAdShowCount, _dailyAdShowCount);
      await prefs.setString(_keyCurrentDayKey, _currentDayKey ?? '');

      if (_lastAdShownTime != null) {
        await prefs.setString(
          _keyLastAdShownTime,
          _lastAdShownTime!.toIso8601String(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving state: $e');
      }
    }
  }

  /// Check if we need to reset daily count
  void _checkAndResetDailyCount() {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    if (_currentDayKey != todayKey) {
      _currentDayKey = todayKey;
      _dailyAdShowCount = 0;
      _saveState();

      if (kDebugMode) {
        print('Daily ad count reset for new day: $todayKey');
      }
    }
  }

  /// Maximum duration allowed between loading and showing the ad.
  Duration get maxCacheDuration => _remoteConfig.openAppAdTimeoutDuration;

  /// Whether an ad is available to be shown.
  bool get isAdAvailable {
    return _appOpenAd != null && !_isExpired && !_isLoadingAd;
  }

  /// Whether the cached ad is expired.
  bool get _isExpired {
    if (_appOpenLoadTime == null) return true;
    return DateTime.now().subtract(maxCacheDuration).isAfter(_appOpenLoadTime!);
  }

  /// Whether enough time has passed since the last ad was shown
  bool get _canShowBasedOnInterval {
    if (_lastAdShownTime == null) return true;

    final minInterval = _remoteConfig.openAppAdMinIntervalDuration;
    return DateTime.now().difference(_lastAdShownTime!) >= minInterval;
  }

  /// Whether we haven't exceeded daily show limit
  bool get _canShowBasedOnDailyLimit {
    return _dailyAdShowCount < _remoteConfig.openAppAdMaxDailyShows;
  }

  /// Load an [AppOpenAd] with retry logic.
Future<void> loadAd() async {
    if (!_remoteConfig.adsEnabled ||
        !_remoteConfig.openAppAdsEnabled ||
        _isShowingAd ||
        _isLoadingAd) { 
      return;
    }

    // Validate ad unit ID format
    if (!_isValidAdUnitId(_remoteConfig.openAppAdUnitId)) {
      if (kDebugMode) {
        print('❌ Invalid ad unit ID format: ${_remoteConfig.openAppAdUnitId}');
      }
      return;
    }

    // Dispose existing ad if any
    if (_appOpenAd != null) {
      _appOpenAd!.dispose();
      _appOpenAd = null;
    }   

    _isLoadingAd = true;
    _loadRetryCount = 0;

    if (kDebugMode) {
      print('Starting to load Open App Ad...');
    }

    await _attemptLoadAd();
  }

Future<void> _attemptLoadAd() async {
    try {
      if (kDebugMode) {
        print(
          'Loading Open App Ad (attempt ${_loadRetryCount + 1}/${_remoteConfig.openAppAdRetryAttempts + 1})',
        );
        print('Ad Unit ID: ${_remoteConfig.openAppAdUnitId}');
      }

      // Add validation for ad unit ID format
      final adUnitId = _remoteConfig.openAppAdUnitId;
      if (adUnitId.isEmpty || !adUnitId.contains('ca-app-pub-')) {
        if (kDebugMode) {
          print('❌ Invalid ad unit ID format: $adUnitId');
        }
        _handleLoadFailure();
        return;
      }

      final adRequest = AdRequest();
      final completer = Completer<void>();

      await AppOpenAd.load(
        adUnitId: adUnitId,
        request: adRequest,
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            if (kDebugMode) {
              print('✅ Open App Ad loaded successfully');
            }
            _appOpenLoadTime = DateTime.now();
            _appOpenAd = ad;
            _isLoadingAd = false;
            _loadRetryCount = 0;
            _setAdCallbacks();
            completer.complete();
          },
          onAdFailedToLoad: (error) {
            if (kDebugMode) {
              print('❌ Open App Ad failed to load: ${error.message}');
              print('❌ Error code: ${error.code}');
              print('❌ Error domain: ${error.domain}');
            }
            _isLoadingAd = false;
            _handleLoadFailure();
            completer.complete();
          },
        ),
      );

      await completer.future;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading Open App Ad: $e');
      }
      _isLoadingAd = false;
      _handleLoadFailure();
    }
  }
bool _isValidAdUnitId(String adUnitId) {
    // Check if it's a valid AdMob ad unit ID format
    final regex = RegExp(r'^ca-app-pub-[0-9]+\/[0-9]+$');
    return regex.hasMatch(adUnitId);
  }

  /// Handle load failure with retry logic
  void _handleLoadFailure() {
    if (_loadRetryCount < _remoteConfig.openAppAdRetryAttempts) {
      _loadRetryCount++;

      if (kDebugMode) {
        print(
          'Retrying ad load in ${_remoteConfig.openAppAdRetryDelay} seconds...',
        );
      }

      Future.delayed(_remoteConfig.openAppAdRetryDelayDuration, () {
        if (!_isLoadingAd && _appOpenAd == null) {
          _attemptLoadAd();
        }
      });
    } else {
      if (kDebugMode) {
        print('Max retry attempts reached. Giving up on loading ad.');
      }
      _loadRetryCount = 0;
    }
  }

  /// Set callbacks for the loaded ad.
  void _setAdCallbacks() {
    if (_appOpenAd == null) return;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        _lastAdShownTime = DateTime.now();
        _dailyAdShowCount++;
        _saveState();

        if (kDebugMode) {
          print(
            'Open App Ad showed full screen content (Daily count: $_dailyAdShowCount)',
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          print('Open App Ad failed to show: $error');
        }
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAdAfterDelay();
      },
      onAdDismissedFullScreenContent: (ad) {
        if (kDebugMode) {
          print('Open App Ad dismissed');
        }
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAdAfterDelay();
      },
      onAdClicked: (ad) {
        if (kDebugMode) {
          print('Open App Ad clicked');
        }
      },
      onAdImpression: (ad) {
        if (kDebugMode) {
          print('Open App Ad impression recorded');
        }
      },
    );
  }

  /// Load ad after a delay to prevent rapid loading
  void _loadAdAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isLoadingAd && _appOpenAd == null) {
        loadAd();
      }
    });
  }



 Future<void> showAdIfAvailable({
    bool isFirstLaunch = false,
    bool isColdStart = false,
  }) async {
    _checkAndResetDailyCount();

    if (kDebugMode) {
      print('=== Open App Ad Show Attempt ===');
      print('First Launch: $isFirstLaunch');
      print('Cold Start: $isColdStart');
      print('Ad Available: $isAdAvailable');
      print('Is Showing: $_isShowingAd');
      print('Ads Enabled: ${_remoteConfig.adsEnabled}');
      print('Open App Ads Enabled: ${_remoteConfig.openAppAdsEnabled}');
      print('Ad Unit ID: ${_remoteConfig.openAppAdUnitId}');
    }

    // Basic availability checks
    if (!_remoteConfig.adsEnabled || !_remoteConfig.openAppAdsEnabled) {
      if (kDebugMode) {
        print('❌ Ads disabled in remote config');
      }
      return;
    }

    if (_isShowingAd) {
      if (kDebugMode) {
        print('❌ Already showing an ad');
      }
      return;
    }

    // Check if ad is available
    if (_appOpenAd == null) {
      if (kDebugMode) {
        print('❌ No ad loaded, attempting to load...');
      }
      await loadAd();
      // Wait for ad to load
      await Future.delayed(const Duration(seconds: 2));

      if (_appOpenAd == null) {
        if (kDebugMode) {
          print('❌ Still no ad available after loading attempt');
        }
        return;
      }
    }

    // Check if ad is expired
    if (_isExpired) {
      if (kDebugMode) {
        print('❌ Ad is expired, loading new one...');
      }
      _appOpenAd?.dispose();
      _appOpenAd = null;
      await loadAd();
      await Future.delayed(const Duration(seconds: 2));

      if (_appOpenAd == null) {
        if (kDebugMode) {
          print('❌ No ad available after reload');
        }
        return;
      }
    }

    // Launch type checks
    if (isFirstLaunch && !_remoteConfig.openAppAdShowOnFirstLaunch) {
      if (kDebugMode) {
        print('❌ First launch ads disabled');
      }
      return;
    }

    if (isColdStart && !_remoteConfig.openAppAdShowOnColdStart) {
      if (kDebugMode) {
        print('❌ Cold start ads disabled');
      }
      return;
    }

    if (!isColdStart &&
        !isFirstLaunch &&
        !_remoteConfig.openAppAdShowOnWarmStart) {
      if (kDebugMode) {
        print('❌ Warm start ads disabled');
      }
      return;
    }

    // Frequency and timing checks
    _appOpenCount++;
    await _saveState();

    if (_remoteConfig.openAppAdShowFrequency > 1 &&
        _appOpenCount % _remoteConfig.openAppAdShowFrequency != 0) {
      if (kDebugMode) {
        print(
          '❌ Frequency check failed (${_appOpenCount} % ${_remoteConfig.openAppAdShowFrequency})',
        );
      }
      return;
    }

    if (!_canShowBasedOnInterval) {
      if (kDebugMode) {
        print('❌ Interval check failed');
      }
      return;
    }

    if (!_canShowBasedOnDailyLimit) {
      if (kDebugMode) {
        print('❌ Daily limit reached');
      }
      return;
    }

    // All checks passed - show the ad
    try {
      if (kDebugMode) {
        print('✅ Showing Open App Ad');
      }

      _appOpenAd!.show();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing ad: $e');
      }
      _handleShowError();
    }
  }

  void _handleShowError() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isShowingAd = false;

    // Try to load a new ad
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isLoadingAd && _appOpenAd == null) {
        loadAd().catchError((error) {
          if (kDebugMode) {
            print('Error loading ad after error: $error');
          }
        });
      }
    });
  }




  /// Dispose of the ad.
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isShowingAd = false;
    _isLoadingAd = false;
  }

  /// Reset the app open count (useful for testing)
  void resetAppOpenCount() {
    _appOpenCount = 0;
    _saveState();
  }

  /// Reset daily ad show count (useful for testing)
  void resetDailyAdShowCount() {
    _dailyAdShowCount = 0;
    _saveState();
  }

  /// Reset all counters
  void resetAllCounters() {
    _appOpenCount = 0;
    _dailyAdShowCount = 0;
    _lastAdShownTime = null;
    _currentDayKey = null;
    _saveState();
  }

  // Getters for status and debugging
  int get appOpenCount => _appOpenCount;
  int get dailyAdShowCount => _dailyAdShowCount;
  DateTime? get lastAdShownTime => _lastAdShownTime;
  bool get isLoadingAd => _isLoadingAd;
  bool get isShowingAd => _isShowingAd;
  int get loadRetryCount => _loadRetryCount;
  bool get canShowBasedOnInterval => _canShowBasedOnInterval;
  bool get canShowBasedOnDailyLimit => _canShowBasedOnDailyLimit;

  /// Get comprehensive status for debugging
  Map<String, dynamic> get debugStatus => {
    'isAdAvailable': isAdAvailable,
    'isExpired': _isExpired,
    'isLoadingAd': _isLoadingAd,
    'isShowingAd': _isShowingAd,
    'appOpenCount': _appOpenCount,
    'dailyAdShowCount': _dailyAdShowCount,
    'loadRetryCount': _loadRetryCount,
    'canShowBasedOnInterval': _canShowBasedOnInterval,
    'canShowBasedOnDailyLimit': _canShowBasedOnDailyLimit,
    'lastAdShownTime': _lastAdShownTime?.toIso8601String(),
    'appOpenLoadTime': _appOpenLoadTime?.toIso8601String(),
    'currentDayKey': _currentDayKey,
  };
}
