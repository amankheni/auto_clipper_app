// Updated main.dart with Open App Ads integration

// ignore_for_file: avoid_print

import 'dart:async';
import 'package:auto_clipper_app/Logic/open_app_ads_controller.dart';
import 'package:auto_clipper_app/Screens/splesh_screen.dart';
import 'package:auto_clipper_app/comman%20class/remot_config.dart';
import 'package:auto_clipper_app/manager/AppLifecycle_Manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
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

  // Set up error handling
  _setupErrorHandling();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run the app with error zone
  runZonedGuarded(() => runApp(MyApp()), (error, stack) {
    if (kDebugMode) {
      print('Zone Error: $error');
      print('Stack trace: $stack');
    }
  });
}

void _setupErrorHandling() {
  // Handle Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
    }
  };

  // Handle platform channel errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('Platform Error: $error');
      print('Stack trace: $stack');
    }
    return true;
  };
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
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isFirstLaunch && _isInitialized) {
          _isAppInForeground = true;
          // Show ad when app comes to foreground
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
        // Do nothing for inactive state
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
Future<void> _initializeApp() async {
    try {
      // Initialize Remote Config Service first
      await _remoteConfigService.initialize();

      // Initialize Open App Ads Manager
      await _openAppAdsManager.initialize();

      // Initialize App Lifecycle Manager
      _appLifecycleManager.initialize();

      // IMPORTANT: Load the first ad and wait for it
      await _loadFirstAd();

      setState(() {
        _isInitialized = true;
      });

      // Show first launch ad after initialization
      if (_isFirstLaunch) {
        _scheduleFirstLaunchAd();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during app initialization: $e');
      }
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadFirstAd() async {
    try {
      if (_remoteConfigService.adsEnabled &&
          _remoteConfigService.openAppAdsEnabled) {
        // Load ad and wait for completion
        await _openAppAdsManager.loadAd();

        // Wait a bit more to ensure ad is fully loaded
        await Future.delayed(const Duration(milliseconds: 500));

        if (kDebugMode) {
          print(
            'First ad loaded successfully: ${_openAppAdsManager.isAdAvailable}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading first ad: $e');
      }
    }
  }


void _scheduleFirstLaunchAd() {
    final delay = _remoteConfigService.openAppAdFirstLaunchDelayDuration;

    if (kDebugMode) {
      print('Scheduling first launch ad in ${delay.inSeconds} seconds');
    }

    Timer(delay, () {
      if (mounted && _isAppInForeground && _isInitialized) {
        if (kDebugMode) {
          print('First launch timer triggered, showing ad');
        }
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

    // Add a small delay to ensure UI is ready
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
          home:
              _isInitialized
                  ? SplashScreen() // Your actual splash screen
                  : _buildInitializingScreen(),
        );
      },
    );
  }

  Widget _buildInitializingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.content_cut,
                size: 40.w,
                color: Colors.blue.shade600,
              ),
            ),

            SizedBox(height: 24.h),

            // App Name
            Text(
              'AutoClipper',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),

            SizedBox(height: 32.h),

            // Loading Indicator
            SizedBox(
              width: 32.w,
              height: 32.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            ),

            SizedBox(height: 16.h),

            Text(
              'Initializing...',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
            ),

            // Debug info for development
            if (kDebugMode) ...[
              SizedBox(height: 20.h),
              Text(
                'Loading ads configuration...',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(FlutterErrorDetails errorDetails) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
              SizedBox(height: 16.h),
              Text(
                'Something went wrong!',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Please restart the app',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  // Try to reinitialize the app
                  setState(() {
                    _isInitialized = false;
                    _isFirstLaunch = true;
                  });
                  _initializeApp();
                },
                child: Text('Retry'),
              ),
              if (kDebugMode) ...[
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    errorDetails.exception.toString(),
                    style: TextStyle(fontSize: 12.sp, fontFamily: 'monospace'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
