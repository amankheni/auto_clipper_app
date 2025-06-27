// Optimized main.dart with proper error handling and ads initialization

import 'dart:async';
// import 'package:auto_clipper_app/Screens/splesh_screen.dart';
// import 'package:auto_clipper_app/Logic/remote_config_service.dart';
// import 'package:auto_clipper_app/Logic/app_lifecycle_manager.dart';
import 'package:auto_clipper_app/Screens/splesh_screen.dart';
import 'package:auto_clipper_app/widget/applife_cycle.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Import your ads controller
// import 'package:auto_clipper_app/controllers/native_ads_controller.dart';

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

class _MyAppState extends State<MyApp> {
  // final AppLifecycleManager _appLifecycleManager = AppLifecycleManager();
  // final RemoteConfigService _remoteConfigService = RemoteConfigService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      if (kDebugMode) {
        print('Starting app initialization...');
      }

      // Initialize Remote Config Service
    //  await _remoteConfigService.initialize();
      if (kDebugMode) {
        print('Remote Config initialized');
      }

      // Initialize App Lifecycle Manager for Open App Ads
      // _appLifecycleManager.initialize();
      if (kDebugMode) {
        print('App Lifecycle Manager initialized');
      }

      // Pre-initialize other ads
      await _preInitializeAds();

      setState(() {
        _isInitialized = true;
      });

      if (kDebugMode) {
        print('App initialization completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during app initialization: $e');
      }
      // Even if initialization fails, allow the app to continue
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _preInitializeAds() async {
    try {
      // Pre-initialize ads controller
      // Uncomment when you have the NativeAdsController
      // final adsController = NativeAdsController();
      // await adsController.initializeAds();

      // Pre-load a native ad with delay
      // await Future.delayed(const Duration(milliseconds: 1000));
      // await adsController.loadNativeAd();

      // Preload an open app ad for future use
     // _appLifecycleManager.preloadAd();

      if (kDebugMode) {
        print('Ads pre-initialization completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error pre-initializing ads: $e');
      }
    }
  }

  @override
  void dispose() {
    // Clean up lifecycle manager
   // _appLifecycleManager.dispose();
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

          // Global error handling
          builder: (context, widget) {
            ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
              return _buildErrorWidget(errorDetails);
            };

            if (widget != null) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: 1.0, // Prevent text scaling issues
                ),
                child: widget,
              );
            }
            return const SizedBox.shrink();
          },

          // Theme configuration
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),

          // Show loading screen until initialization is complete
          home: SafeAreaWrapper(
            child:
                _isInitialized
                    ? SimpleSplashScreen()
                    : _buildInitializingScreen(),
          ),
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

// Safe area wrapper to prevent overflow issues
class SafeAreaWrapper extends StatelessWidget {
  final Widget child;

  const SafeAreaWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: child);
  }
}

// Extension to provide easy access to lifecycle manager throughout the app
extension BuildContextExtension on BuildContext {
 // AppLifecycleManager get appLifecycleManager => AppLifecycleManager();
}
