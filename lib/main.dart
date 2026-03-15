// File: main.dart - Production version with UpdateManager, Analytics & Crashlytics integration

import 'dart:async';
import 'dart:ui';
// import 'package:auto_clipper_app/bottomnavigationbar_scren.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Import your existing controllers and managers
import 'package:auto_clipper_app/Logic/Interstitial_Controller.dart';
import 'package:auto_clipper_app/Logic/open_app_ads_controller.dart';
import 'package:auto_clipper_app/Screens/splesh_screen.dart';
import 'package:auto_clipper_app/comman%20class/remot_config.dart';
import 'package:auto_clipper_app/manager/AppLifecycle_Manager.dart';
import 'package:auto_clipper_app/manager/update_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase first
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');

    // Initialize Firebase Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Initialize Firebase Analytics
    await FirebaseAnalytics.instance.logEvent(
      name: 'app_open',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'platform': 'flutter',
      },
    );
    debugPrint('Firebase Analytics initialized');

    // Initialize Mobile Ads
    await MobileAds.instance.initialize();
    debugPrint('Google Mobile Ads initialized');

    // Initialize Update Manager (requires Firebase)
    await UpdateManager().initialize();
    debugPrint('Update Manager initialized');

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Log successful initialization
    await FirebaseAnalytics.instance.logEvent(
      name: 'app_initialized',
      parameters: {'success': true, 'duration': 'fast'},
    );
  } catch (e, stackTrace) {
    debugPrint('Error during initialization: $e');

    // Record the error in Crashlytics
    await FirebaseCrashlytics.instance.recordError(
      e,
      stackTrace,
      reason: 'App initialization failed',
      fatal: false,
    );

    // Log error in Analytics
    await FirebaseAnalytics.instance.logEvent(
      name: 'app_init_error',
      parameters: {
        'error_message': e.toString(),
        'error_type': 'initialization_error',
      },
    );
  }

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Firebase Analytics instance
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: analytics,
  );

  // Existing managers
  final AppLifecycleManager _appLifecycleManager = AppLifecycleManager();
  final RemoteConfigService _remoteConfigService = RemoteConfigService();
  final OpenAppAdsManager _openAppAdsManager = OpenAppAdsManager();
  final UpdateManager _updateManager = UpdateManager();

  // State variables
  bool _isInitialized = false;
  bool _isFirstLaunch = true;
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();

    // Log app start event
    _logAnalyticsEvent('app_start', {
      'first_launch': _isFirstLaunch,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Log app lifecycle events
    _logAnalyticsEvent('app_lifecycle_change', {
      'state': state.name,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _isAppInForeground = false;
        _logAnalyticsEvent('app_backgrounded', {});
        break;
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        _logAnalyticsEvent('app_detached', {});
        break;
      case AppLifecycleState.inactive:
        _logAnalyticsEvent('app_inactive', {});
        break;
      case AppLifecycleState.hidden:
        _logAnalyticsEvent('app_hidden', {});
        break;
    }
  }

  /// Log analytics events with error handling
  Future<void> _logAnalyticsEvent(
    String eventName,
    Map<String, Object> parameters,
  ) async {
    try {
      await analytics.logEvent(name: eventName, parameters: parameters);
    } catch (e, stackTrace) {
      debugPrint('Analytics logging error: $e');
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Analytics event logging failed: $eventName',
        fatal: false,
      );
    }
  }

  /// Handle app resume - show ads and check for updates
  void _handleAppResumed() {
    if (!_isFirstLaunch && _isInitialized) {
      _isAppInForeground = true;

      // Log app resume event
      _logAnalyticsEvent('app_resumed', {
        'session_duration': 'unknown', // You can track this if needed
        'background_time': 'unknown',
      });

      // Show open app ad when returning to app
      _showOpenAppAd(isFirstLaunch: false, isColdStart: false);

      // Check for updates when app comes back to foreground
      _scheduleUpdateCheck(delay: const Duration(seconds: 1));
    }
  }

  /// Initialize all app services and managers
  Future<void> _initializeApp() async {
    try {
      debugPrint('Starting app initialization...');

      // Set user properties for Analytics
      await analytics.setUserProperty(
        name: 'app_version',
        value: '1.0.0',
      ); // Replace with actual version
      await analytics.setUserProperty(name: 'platform', value: 'flutter');

      // Initialize Remote Config Service
      await _remoteConfigService.initialize();
      debugPrint('Remote Config Service initialized');
      _logAnalyticsEvent('remote_config_initialized', {'success': true});

      // Initialize Open App Ads Manager
      await _openAppAdsManager.initialize();
      debugPrint('Open App Ads Manager initialized');
      _logAnalyticsEvent('ads_manager_initialized', {'type': 'open_app_ads'});

      // Initialize Interstitial Ads Controller
      await InterstitialAdsController().initialize();
      debugPrint('Interstitial Ads Controller initialized');
      _logAnalyticsEvent('ads_manager_initialized', {
        'type': 'interstitial_ads',
      });

      // Initialize App Lifecycle Manager
      _appLifecycleManager.initialize();
      debugPrint('App Lifecycle Manager initialized');
      _logAnalyticsEvent('lifecycle_manager_initialized', {'success': true});

      // Load the first ad and interstitial ad
      await Future.wait([_loadFirstAd(), _loadInterstitialAd()]);

      setState(() {
        _isInitialized = true;
      });

      debugPrint('App initialization complete');
      _logAnalyticsEvent('app_initialization_complete', {
        'duration': 'fast', // You can measure actual duration if needed
        'success': true,
      });

      // Schedule first launch ad
      if (_isFirstLaunch) {
        _scheduleFirstLaunchAd();
      }

      // Schedule initial update check
      _scheduleUpdateCheck(delay: const Duration(seconds: 3));
    } catch (e, stackTrace) {
      debugPrint('Error during app initialization: $e');

      // Record error in Crashlytics
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'App initialization failed',
        fatal: false,
      );

      // Log error in Analytics
      _logAnalyticsEvent('app_initialization_error', {
        'error_message': e.toString(),
        'error_type': 'initialization_failure',
      });

      setState(() {
        _isInitialized = true;
      });
    }
  }

  /// Load the first open app ad
  Future<void> _loadFirstAd() async {
    try {
      if (_remoteConfigService.adsEnabled &&
          _remoteConfigService.openAppAdsEnabled) {
        await _openAppAdsManager.loadAd();
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint('First ad loaded successfully');

        _logAnalyticsEvent('ad_loaded', {
          'ad_type': 'open_app_ad',
          'load_time': 'fast',
          'success': true,
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading first ad: $e');

      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'First ad loading failed',
        fatal: false,
      );

      _logAnalyticsEvent('ad_load_error', {
        'ad_type': 'open_app_ad',
        'error_message': e.toString(),
      });
    }
  }

  /// Load interstitial ad for future use
  Future<void> _loadInterstitialAd() async {
    try {
      if (_remoteConfigService.adsEnabled &&
          _remoteConfigService.interstitialAdsEnabled) {
        await InterstitialAdsController().loadInterstitialAd();
        debugPrint('Interstitial ad loaded successfully');

        _logAnalyticsEvent('ad_loaded', {
          'ad_type': 'interstitial_ad',
          'success': true,
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading interstitial ad: $e');

      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Interstitial ad loading failed',
        fatal: false,
      );

      _logAnalyticsEvent('ad_load_error', {
        'ad_type': 'interstitial_ad',
        'error_message': e.toString(),
      });
    }
  }

  /// Schedule update check with configurable delay
  void _scheduleUpdateCheck({Duration delay = const Duration(seconds: 2)}) {
    Timer(delay, () {
      if (mounted && _isAppInForeground && _isInitialized) {
        _checkForUpdates(silent: true);
      }
    });
  }

  /// Check for app updates using UpdateManager
  Future<void> _checkForUpdates({bool silent = true}) async {
    try {
      if (mounted && _updateManager.isInitialized) {
        _logAnalyticsEvent('update_check_started', {
          'silent': silent,
          'auto_check': true,
        });

        await _updateManager.checkForUpdates(context, silent: silent);

        _logAnalyticsEvent('update_check_completed', {
          'silent': silent,
          'success': true,
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Update check error: $e');

      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Update check failed',
        fatal: false,
      );

      _logAnalyticsEvent('update_check_error', {
        'error_message': e.toString(),
        'silent': silent,
      });
    }
  }

  /// Schedule first launch ad display
  void _scheduleFirstLaunchAd() {
    final delay = _remoteConfigService.openAppAdFirstLaunchDelayDuration;

    Timer(delay, () {
      if (mounted && _isAppInForeground && _isInitialized) {
        _showOpenAppAd(isFirstLaunch: true, isColdStart: true);
        _isFirstLaunch = false;

        _logAnalyticsEvent('first_launch_ad_scheduled', {
          'delay_seconds': delay.inSeconds,
        });
      }
    });
  }

  /// Show open app ad with specified parameters
  void _showOpenAppAd({
    required bool isFirstLaunch,
    required bool isColdStart,
  }) {
    if (!_isInitialized || !_isAppInForeground) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _isAppInForeground) {
        _openAppAdsManager.showAdIfAvailable(
          isFirstLaunch: isFirstLaunch,
          isColdStart: isColdStart,
        );

        _logAnalyticsEvent('ad_shown', {
          'ad_type': 'open_app_ad',
          'is_first_launch': isFirstLaunch,
          'is_cold_start': isColdStart,
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logAnalyticsEvent('app_disposed', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Auto Clipper App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            useMaterial3: true,
          ),
          // Add Firebase Analytics observer for automatic screen tracking
          navigatorObservers: [observer],
          home: AppHome(
            isInitialized: _isInitialized,
            onManualUpdateCheck: () => _checkForUpdates(silent: false),
          ),
        );
      },
    );
  }
}

/// Home widget with update functionality
class AppHome extends StatefulWidget {
  final bool isInitialized;
  final VoidCallback onManualUpdateCheck;

  const AppHome({
    super.key,
    required this.isInitialized,
    required this.onManualUpdateCheck,
  });

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  final UpdateManager _updateManager = UpdateManager();
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();

    // Set custom Crashlytics keys for this screen
    FirebaseCrashlytics.instance.setCustomKey('screen', 'app_home');
    FirebaseCrashlytics.instance.setCustomKey(
      'initialized',
      widget.isInitialized,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while app is initializing
    if (!widget.isInitialized) {
      // Log loading screen view
      analytics.logScreenView(
        screenName: 'loading_screen',
        screenClass: 'AppHome',
      );

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Log main screen view
    analytics.logScreenView(
      screenName: 'splash_screen',
      screenClass: 'AppHome',
    );

    // Return your main bottom navigation screen
    return Splashscreens();
  }

  /// Method to manually check for updates
  /// Can be called from anywhere in your app (e.g., settings screen, app drawer)
  Future<void> manualUpdateCheck() async {
    try {
      // Log manual update check
      await analytics.logEvent(
        name: 'manual_update_check',
        parameters: {
          'source': 'user_action',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      if (_updateManager.isInitialized) {
        await _updateManager.checkForUpdates(context, silent: false);

        await analytics.logEvent(
          name: 'manual_update_check_success',
          parameters: {'method': 'update_manager'},
        );
      } else {
        _showUpdateNotAvailableSnackBar();

        await analytics.logEvent(
          name: 'manual_update_check_failed',
          parameters: {
            'reason': 'update_manager_not_initialized',
            'error_type': 'service_unavailable',
          },
        );
      }
    } catch (e, stackTrace) {
      // Record error in Crashlytics
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Manual update check failed',
        fatal: false,
      );

      // Log error in Analytics
      await analytics.logEvent(
        name: 'manual_update_check_error',
        parameters: {'error_message': e.toString(), 'error_type': 'exception'},
      );
    }
  }

  /// Show snackbar when update service is not available
  void _showUpdateNotAvailableSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Update service is not available at the moment.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );

    // Log snackbar show event
    analytics.logEvent(
      name: 'snackbar_shown',
      parameters: {
        'message_type': 'update_unavailable',
        'context': 'manual_update_check',
      },
    );
  }

  /// Force refresh update configuration (for testing purposes)
  Future<void> forceRefreshUpdates() async {
    try {
      await analytics.logEvent(
        name: 'force_refresh_updates',
        parameters: {
          'source': 'debug_action',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      if (_updateManager.isInitialized) {
        await _updateManager.forceRefresh();
        await _updateManager.checkForUpdates(context, silent: false);

        await analytics.logEvent(
          name: 'force_refresh_success',
          parameters: {'method': 'update_manager'},
        );
      }
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Force refresh updates failed',
        fatal: false,
      );

      await analytics.logEvent(
        name: 'force_refresh_error',
        parameters: {'error_message': e.toString(), 'error_type': 'exception'},
      );
    }
  }
}
