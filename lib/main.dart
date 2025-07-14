// Production main.dart - Cleaned up for release

import 'dart:async';
import 'package:auto_clipper_app/Logic/Interstitial_Controller.dart';
import 'package:auto_clipper_app/Logic/open_app_ads_controller.dart';
import 'package:auto_clipper_app/Screens/splesh_screen.dart';
import 'package:auto_clipper_app/comman%20class/remot_config.dart';
import 'package:auto_clipper_app/manager/AppLifecycle_Manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Mobile Ads
  await MobileAds.instance.initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run the app
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AppLifecycleManager _appLifecycleManager = AppLifecycleManager();
  final RemoteConfigService _remoteConfigService = RemoteConfigService();
  final OpenAppAdsManager _openAppAdsManager = OpenAppAdsManager();

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
        if (!_isFirstLaunch && _isInitialized) {
          _isAppInForeground = true;
          _showOpenAppAd(isFirstLaunch: false, isColdStart: false);
        }
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

 Future<void> _initializeApp() async {
    try {
      // Initialize Remote Config Service
      await _remoteConfigService.initialize();

      // Initialize Open App Ads Manager
      await _openAppAdsManager.initialize();

      // Initialize Interstitial Ads Controller
      await InterstitialAdsController().initialize();

      // Initialize App Lifecycle Manager
      _appLifecycleManager.initialize();

      // Load the first ad
      await _loadFirstAd();

      // Load interstitial ad for future use
      await _loadInterstitialAd();

      setState(() {
        _isInitialized = true;
      });

      // Show first launch ad after initialization
      if (_isFirstLaunch) {
        _scheduleFirstLaunchAd();
      }
    } catch (e) {
      setState(() {
        _isInitialized = true;
      });
    }
  }
  Future<void> _loadInterstitialAd() async {
    try {
      if (_remoteConfigService.adsEnabled &&
          _remoteConfigService.interstitialAdsEnabled) {
        await InterstitialAdsController().loadInterstitialAd();
      }
    } catch (e) {
      // Handle error silently in production
    }
  }

  Future<void> _loadFirstAd() async {
    try {
      if (_remoteConfigService.adsEnabled &&
          _remoteConfigService.openAppAdsEnabled) {
        await _openAppAdsManager.loadAd();
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      // Handle error silently in production
    }
  }

  void _scheduleFirstLaunchAd() {
    final delay = _remoteConfigService.openAppAdFirstLaunchDelayDuration;

    Timer(delay, () {
      if (mounted && _isAppInForeground && _isInitialized) {
        _showOpenAppAd(isFirstLaunch: true, isColdStart: true);
        _isFirstLaunch = false;
      }
    });
  }

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
          ),
          home: Splashscreens(),
        );
      },
    );
  }
}
