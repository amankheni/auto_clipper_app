  // ignore_for_file: use_build_context_synchronously

  import 'package:auto_clipper_app/Logic/open_app_ads_controller.dart';
  import 'package:auto_clipper_app/bottomnavigationbar_scren.dart';
  import 'package:auto_clipper_app/comman%20class/remot_config.dart';
  import 'package:flutter/foundation.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';
  import 'package:google_mobile_ads/google_mobile_ads.dart';
  import 'package:firebase_core/firebase_core.dart';
  class SimpleSplashScreen extends StatefulWidget {
    const SimpleSplashScreen({Key? key}) : super(key: key);

    @override
    _SimpleSplashScreenState createState() => _SimpleSplashScreenState();
  }

  class _SimpleSplashScreenState extends State<SimpleSplashScreen> {
    final AppOpenAdManager _adManager = AppOpenAdManager();
    final RemoteConfigService _remoteConfig = RemoteConfigService();

    bool _isInitialized = false;
    String _statusMessage = 'Initializing...';

    @override
    void initState() {
      super.initState();
      _initializeApp();
    }

   Future<void> _initializeApp() async {
    try {
      _updateStatus('Initializing Firebase...');
      await Firebase.initializeApp();

      _updateStatus('Loading configuration...');
      await _remoteConfig.initialize();

      _updateStatus('Initializing ads...');
      await MobileAds.instance.initialize();

      _updateStatus('Preparing ads...');
      await _adManager.loadAd();

      // Give more time for ad to load
      _updateStatus('Loading ads...');
      await Future.delayed(const Duration(seconds: 3));

      _updateStatus('Starting app...');
      await Future.delayed(const Duration(seconds: 1));

      setState(() => _isInitialized = true);
      await Future.delayed(const Duration(milliseconds: 500));

      _showAdAndNavigate();
    } catch (e) {
      debugPrint('Initialization error: $e');
      _navigateToHome();
    }
  }

    void _updateStatus(String message) {
      if (mounted) {
        setState(() => _statusMessage = message);
      }
    }

    void _showAdAndNavigate() {
    debugPrint('=== AD DEBUG INFO ===');
    debugPrint('Ads enabled: ${_remoteConfig.adsEnabled}');
    debugPrint('Open app ads enabled: ${_remoteConfig.openAppAdsEnabled}');
    debugPrint('Ad unit ID: ${_remoteConfig.openAppAdUnitId}');
    debugPrint('Is ad available: ${_adManager.isAdAvailable}');
    debugPrint('Is showing ad: ${_adManager.isShowingAd}');

    // Try to show the ad
    final adShown = _adManager.showAdIfAvailable();

    if (adShown) {
      debugPrint(
        'Open app ad shown, navigation will happen after ad is dismissed',
      );
    } else {
      debugPrint('No ad to show, navigating immediately');
      _navigateToHome();
    }
  }

    void _navigateToHome() {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavigationScreen()),
      );
    }

    @override
    void dispose() {
      _adManager.dispose();
      super.dispose();
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
                  // App Logo/Icon
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.content_cut,
                      size: 60.w,
                      color: Colors.blue.shade600,
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // App Name
                  Text(
                    'AutoClipper',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // App Tagline
                  Text(
                    'Smart Clipping Made Easy',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  SizedBox(height: 48.h),

                  // Loading Indicator
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

                  // Status Message
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
                    Text(
                      '✓ Ready',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
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

