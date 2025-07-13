// ignore_for_file: use_build_context_synchronously

import 'package:auto_clipper_app/Logic/open_app_ads_controller.dart';
import 'package:auto_clipper_app/bottomnavigationbar_scren.dart';
import 'package:auto_clipper_app/comman%20class/remot_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final RemoteConfigService _remoteConfig = RemoteConfigService();

  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';
  bool _navigationComplete = false;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      _updateStatus('Connecting to server...');
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp();
      }

      _updateStatus('Loading settings...');
      await _remoteConfig.initialize();

      _updateStatus('Preparing services...');

      setState(() => _isInitialized = true);
      _updateStatus('Ready to start...');

      await Future.delayed(const Duration(milliseconds: 800));

      if (!_navigationComplete) {
        _navigateToHome();
      }
    } catch (e) {
      debugPrint('Splash initialization error: $e');
      _updateStatus('Starting app...');
      await Future.delayed(const Duration(milliseconds: 1000));
      _navigateToHome();
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() => _statusMessage = message);
      debugPrint('SplashScreen Status: $message');
    }
  }

  void _navigateToHome() {
    if (!mounted || _navigationComplete) return;

    _navigationComplete = true;
    _navigationTimer?.cancel();
    debugPrint('Splash: Navigating to home screen');

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.content_cut,
                    size: 60.w,
                    color: Colors.blue.shade600,
                  ),
                ),

                SizedBox(height: 32.h),

                Text(
                  'AutoClipper',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                    letterSpacing: 1.2,
                  ),
                ),

                SizedBox(height: 8.h),

                Text(
                  'Smart Video Clipping Tool',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey.shade600,
                  ),
                ),

                SizedBox(height: 48.h),

                SizedBox(
                  width: 40.w,
                  height: 40.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.w,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade600,
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (_isInitialized) ...[
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Ready',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                if (kDebugMode) ...[
                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Info:',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Ads Enabled: ${_remoteConfig.adsEnabled}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'Open App Ads: ${_remoteConfig.openAppAdsEnabled}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'Test Mode: ${_remoteConfig.adsTestMode}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _logoController;
//   late AnimationController _textController;
//   late AnimationController _fadeController;
//   late AnimationController _scaleController;

//   late Animation<double> _logoAnimation;
//   late Animation<double> _textAnimation;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;

//   @override
//   void initState() {
//     super.initState();

//     // Initialize animation controllers
//     _logoController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     );

//     _textController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );

//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );

//     _scaleController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );

//     // Initialize animations
//     _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
//     );

//     _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
//     );

//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
//     );

//     // Start animations with delays
//     _startAnimations();

//     // Navigate to next screen after splash
//     Future.delayed(const Duration(milliseconds: 3500), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => BottomNavigationScreen()),
//       );
//     });
//   }

//   void _startAnimations() async {
//     await _fadeController.forward();
//     await Future.delayed(const Duration(milliseconds: 200));
//     _scaleController.forward();
//     _logoController.forward();
//     await Future.delayed(const Duration(milliseconds: 800));
//     _textController.forward();
//   }

//   @override
//   void dispose() {
//     _logoController.dispose();
//     _textController.dispose();
//     _fadeController.dispose();
//     _scaleController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [Color(0xFFF8F9FA), Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
//           ),
//         ),
//         child: Center(
//           child: AnimatedBuilder(
//             animation: Listenable.merge([
//               _logoController,
//               _textController,
//               _fadeController,
//               _scaleController,
//             ]),
//             builder: (context, child) {
//               return FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: Transform.scale(
//                   scale: _scaleAnimation.value,
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Logo with animation
//                       Transform.scale(
//                         scale: _logoAnimation.value,
//                         child: Transform.rotate(
//                           angle: (1 - _logoAnimation.value) * 0.5,
//                           child: Container(
//                             width: 180.w,
//                             height: 180.w,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(30.r),
//                               gradient: const LinearGradient(
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                                 colors: [
//                                   Color(0xFFFFD700),
//                                   Color(0xFFFF6B35),
//                                   Color(0xFFE91E63),
//                                   Color(0xFF9C27B0),
//                                   Color(0xFF673AB7),
//                                   Color(0xFF2196F3),
//                                   Color(0xFF00BCD4),
//                                 ],
//                               ),
//                               boxShadow: [
//                                 BoxShadow(
//                                   // ignore: deprecated_member_use
//                                   color: Colors.black.withOpacity(0.2),
//                                   blurRadius: 20.r,
//                                   offset: Offset(0, 10.h),
//                                 ),
//                               ],
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(30.r),
//                               child: Image.asset(
//                                 'assets/images/Gemini_Generated_Image_2raqqs2raqqs2raq.png',
//                                 width: 180.w,
//                                 height: 180.w,
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),

//                       SizedBox(height: 40.h),

//                       // App Name with animation
//                       SlideTransition(
//                         position: Tween<Offset>(
//                           begin: const Offset(0, 0.5),
//                           end: Offset.zero,
//                         ).animate(_textAnimation),
//                         child: FadeTransition(
//                           opacity: _textAnimation,
//                           child: Column(
//                             children: [
//                               ShaderMask(
//                                 shaderCallback:
//                                     (bounds) => const LinearGradient(
//                                       colors: [
//                                         Color(0xFFFF6B35),
//                                         Color(0xFFE91E63),
//                                         Color(0xFF9C27B0),
//                                         Color(0xFF2196F3),
//                                       ],
//                                     ).createShader(bounds),
//                                 child: Text(
//                                   'AutoClipper',
//                                   style: TextStyle(
//                                     fontSize: 36.sp,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                     letterSpacing: 1.2,
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(height: 8.h),
//                               Text(
//                                 'Smart Video Editing Made Easy',
//                                 style: TextStyle(
//                                   fontSize: 16.sp,
//                                   color: Colors.grey[600],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),

//                       SizedBox(height: 60.h),

//                       // Loading indicator
//                       SlideTransition(
//                         position: Tween<Offset>(
//                           begin: const Offset(0, 1),
//                           end: Offset.zero,
//                         ).animate(_textAnimation),
//                         child: FadeTransition(
//                           opacity: _textAnimation,
//                           child: Column(
//                             children: [
//                               Container(
//                                 width: 60.w,
//                                 height: 4.h,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(2.r),
//                                   gradient: const LinearGradient(
//                                     colors: [
//                                       Color(0xFFFF6B35),
//                                       Color(0xFFE91E63),
//                                       Color(0xFF9C27B0),
//                                       Color(0xFF2196F3),
//                                     ],
//                                   ),
//                                 ),
//                                 child: LinearProgressIndicator(
//                                   backgroundColor: Colors.transparent,
//                                   valueColor: AlwaysStoppedAnimation<Color>(
//                                     Colors.white.withOpacity(0.3),
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(height: 16.h),
//                               Text(
//                                 'Loading...',
//                                 style: TextStyle(
//                                   fontSize: 14.sp,
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

