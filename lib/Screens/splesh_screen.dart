import 'package:auto_clipper_app/bottomnavigationbar_scren.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SimpleSplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNavigationScreen()),
      );
    });

    return Scaffold(
      body: Center(
        child: Text(
          'AutoClipper',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

