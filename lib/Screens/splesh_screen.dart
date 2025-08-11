// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';

import 'package:auto_clipper_app/bottomnavigationbar_scren.dart';
import 'package:auto_clipper_app/comman%20class/remot_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';

class Splashscreens extends StatefulWidget {
  const Splashscreens({super.key});

  @override
  State<Splashscreens> createState() => _SplashscreensState();
}

class _SplashscreensState extends State<Splashscreens>
    with TickerProviderStateMixin {
  // Ads logic variables
  final RemoteConfigService _remoteConfig = RemoteConfigService();
  bool _isInitialized = false;
  bool _navigationComplete = false;
  Timer? _navigationTimer;

  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  // Animations
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Initialize animation controllers
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Initialize animations
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Start animations with delays
    _startAnimations();
  }

  void _startAnimations() async {
    await _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('SplashScreen Status: Connecting to server...');
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp();
      }

      debugPrint('SplashScreen Status: Loading settings...');
      await _remoteConfig.initialize();

      debugPrint('SplashScreen Status: Preparing services...');

      setState(() => _isInitialized = true);
      debugPrint('SplashScreen Status: Ready to start...');

      // Navigate to BottomNavigationScreen after 3 seconds
      await Future.delayed(const Duration(milliseconds: 3000));

      if (!_navigationComplete) {
        _navigateToVideoSplitter();
      }
    } catch (e) {
      debugPrint('Splash initialization error: $e');
      debugPrint('SplashScreen Status: Starting app...');
      await Future.delayed(const Duration(milliseconds: 3000));
      _navigateToVideoSplitter();
    }
  }

  void _navigateToVideoSplitter() {
    if (!mounted || _navigationComplete) return;

    _navigationComplete = true;
    _navigationTimer?.cancel();
    debugPrint('Splash: Navigating to BottomNavigationScreen');

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const BottomNavigationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _logoController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F9FA), Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _logoController,
              _textController,
              _fadeController,
              _scaleController,
            ]),
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with animation
                      Transform.scale(
                        scale: _logoAnimation.value,
                        child: Transform.rotate(
                          angle: (1 - _logoAnimation.value) * 0.5,
                          child: Container(
                            width: 180.w,
                            height: 180.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.r),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFFF6B35),
                                  Color(0xFFE91E63),
                                  Color(0xFF9C27B0),
                                  Color(0xFF673AB7),
                                  Color(0xFF2196F3),
                                  Color(0xFF00BCD4),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20.r,
                                  offset: Offset(0, 10.h),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30.r),
                              child: Image.asset(
                                'assets/images/Gemini_Generated_Image_2raqqs2raqqs2raq.png',
                                width: 180.w,
                                height: 180.w,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // App Name with animation
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(_textAnimation),
                        child: FadeTransition(
                          opacity: _textAnimation,
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback:
                                    (bounds) => const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6B35),
                                        Color(0xFFE91E63),
                                        Color(0xFF9C27B0),
                                        Color(0xFF2196F3),
                                      ],
                                    ).createShader(bounds),
                                child: Text(
                                  'Video Clipper',
                                  style: TextStyle(
                                    fontSize: 36.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Split Long Videos in Seconds - Automatically!',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 60.h),

                      // Loading indicator
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(_textAnimation),
                        child: FadeTransition(
                          opacity: _textAnimation,
                          child: Column(
                            children: [
                              Container(
                                width: 60.w,
                                height: 4.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2.r),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B35),
                                      Color(0xFFE91E63),
                                      Color(0xFF9C27B0),
                                      Color(0xFF2196F3),
                                    ],
                                  ),
                                ),
                                child: LinearProgressIndicator(
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withOpacity(0.3),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Debug info (only shown in debug mode, but not visible to user)
                      if (kDebugMode && _isInitialized) ...[
                        SizedBox(height: 40.h),
                        Opacity(
                          opacity: 0.0, // Hidden from user but logic is there
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            child: Column(
                              children: [
                                Text(
                                  'Ads Enabled: ${_remoteConfig.adsEnabled}',
                                ),
                                Text(
                                  'Open App Ads: ${_remoteConfig.openAppAdsEnabled}',
                                ),
                                Text('Test Mode: ${_remoteConfig.adsTestMode}'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
