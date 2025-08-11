// File: main.dart - Production version with UpdateManager integration

import 'dart:async';
// import 'package:auto_clipper_app/bottomnavigationbar_scren.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
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
  } catch (e) {
    debugPrint('Error during initialization: $e');
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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _isAppInForeground = false;
        break;
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Handle app resume - show ads and check for updates
  void _handleAppResumed() {
    if (!_isFirstLaunch && _isInitialized) {
      _isAppInForeground = true;

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

      // Initialize Remote Config Service
      await _remoteConfigService.initialize();
      debugPrint('Remote Config Service initialized');

      // Initialize Open App Ads Manager
      await _openAppAdsManager.initialize();
      debugPrint('Open App Ads Manager initialized');

      // Initialize Interstitial Ads Controller
      await InterstitialAdsController().initialize();
      debugPrint('Interstitial Ads Controller initialized');

      // Initialize App Lifecycle Manager
      _appLifecycleManager.initialize();
      debugPrint('App Lifecycle Manager initialized');

      // Load the first ad and interstitial ad
      await Future.wait([_loadFirstAd(), _loadInterstitialAd()]);

      setState(() {
        _isInitialized = true;
      });

      debugPrint('App initialization complete');

      // Schedule first launch ad
      if (_isFirstLaunch) {
        _scheduleFirstLaunchAd();
      }

      // Schedule initial update check
      _scheduleUpdateCheck(delay: const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Error during app initialization: $e');
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
      }
    } catch (e) {
      debugPrint('Error loading first ad: $e');
    }
  }

  /// Load interstitial ad for future use
  Future<void> _loadInterstitialAd() async {
    try {
      if (_remoteConfigService.adsEnabled &&
          _remoteConfigService.interstitialAdsEnabled) {
        await InterstitialAdsController().loadInterstitialAd();
        debugPrint('Interstitial ad loaded successfully');
      }
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
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
        await _updateManager.checkForUpdates(context, silent: silent);
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
  }

  /// Schedule first launch ad display
  void _scheduleFirstLaunchAd() {
    final delay = _remoteConfigService.openAppAdFirstLaunchDelayDuration;

    Timer(delay, () {
      if (mounted && _isAppInForeground && _isInitialized) {
        _showOpenAppAd(isFirstLaunch: true, isColdStart: true);
        _isFirstLaunch = false;
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
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    Key? key,
    required this.isInitialized,
    required this.onManualUpdateCheck,
  }) : super(key: key);

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  final UpdateManager _updateManager = UpdateManager();

  @override
  Widget build(BuildContext context) {
    // Show loading screen while app is initializing
    if (!widget.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Return your main bottom navigation screen
    return Splashscreens();
  }

  /// Method to manually check for updates
  /// Can be called from anywhere in your app (e.g., settings screen, app drawer)
  Future<void> manualUpdateCheck() async {
    if (_updateManager.isInitialized) {
      await _updateManager.checkForUpdates(context, silent: false);
    } else {
      _showUpdateNotAvailableSnackBar();
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
  }

  /// Force refresh update configuration (for testing purposes)
  Future<void> forceRefreshUpdates() async {
    if (_updateManager.isInitialized) {
      await _updateManager.forceRefresh();
      await _updateManager.checkForUpdates(context, silent: false);
    }
  }
}
