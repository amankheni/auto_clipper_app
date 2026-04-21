// lib/main.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';

import 'package:auto_clipper_app/Controller/ThemeController.dart';
import 'package:auto_clipper_app/Logic/ad_service.dart';
import 'package:auto_clipper_app/Logic/notification_service.dart';
import 'package:auto_clipper_app/Screens/splesh_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'comman class/app_theme.dart';

late AdService adService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light, // 👈 white icons
      statusBarBrightness: Brightness.dark,
    ),
  );

  try {
    // Firebase initialize
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');

    // Crashlytics setup
    FlutterError.onError =
        (e) => FirebaseCrashlytics.instance.recordFlutterFatalError(e);

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Analytics: app open event
    await FirebaseAnalytics.instance.logEvent(
      name: 'app_open',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'platform': 'flutter',
      },
    );

    // ✅ AdMob SDK initialize
    await MobileAds.instance.initialize();
    debugPrint('✅ AdMob initialized');

    // ✅ FIX: AdService Get.put — singleton register
    adService = Get.put(AdService());
    await NotificationService.init();
    // Portrait mode only
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await FirebaseAnalytics.instance.logEvent(
      name: 'app_initialized',
      parameters: {'success': 'true'},
    );
  } catch (e, stack) {
    debugPrint('❌ Init error: $e');
    try {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stack,
        reason: 'App initialization failed',
        fatal: false,
      );
    } catch (_) {}
  }

  runApp(const MyApp());

  // ✅ Load ads AFTER app starts (non-blocking)
  adService.initializeInBackground();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver _observer =
  FirebaseAnalyticsObserver(analytics: _analytics);

  // ✅ ThemeController — GetX singleton
  final ThemeController _themeCtrl = Get.put(ThemeController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }


  Future<void> _log(String name, Map<String, Object> params) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e, s) {
      await FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Analytics: $name',
        fatal: false,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeMode = _themeCtrl.themeMode;
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        useInheritedMediaQuery: true,
        builder: (ctx, child) {
          return GetMaterialApp(
            title: 'Auto Clipper App',
            debugShowCheckedModeBanner: false,

            // Themes
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,

            // Analytics observer
            navigatorObservers: [_observer],
            home: const Splashscreens(),
          );
        },
      );
    });
  }
}