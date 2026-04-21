// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:auto_clipper_app/bottomnavigationbar_scren.dart';
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
  bool _isInitialized = false;
  bool _navigationComplete = false;
  Timer? _minDisplayTimer;

  // ── Animation controllers ─────────────────────────────────────
  late AnimationController _bgController;       // background particles
  late AnimationController _logoController;     // logo bounce-in
  late AnimationController _textController;     // text slide-up
  late AnimationController _cardsController;    // feature pills
  late AnimationController _shimmerController;  // logo shimmer
  late AnimationController _pulseController;    // logo glow pulse
  late AnimationController _progressController; // progress bar

  // ── Animations ────────────────────────────────────────────────
  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _cardsFade;
  late Animation<Offset> _cardsSlide;
  late Animation<double> _shimmer;
  late Animation<double> _pulse;
  late Animation<double> _progress;

  // ── Brand palette (features_hub dark) ────────────────────────
  static const Color _bg        = Color(0xFF0A0E1A);   // same as features_hub
  static const Color _surface   = Color(0xFF111827);   // card bg
  static const Color _border    = Color(0xFF1F2937);   // border
  static const Color _orange    = Color(0xFFFF6B35);
  static const Color _pink      = Color(0xFFE91E63);
  static const Color _purple    = Color(0xFF9C27B0);
  static const Color _green     = Color(0xFF25D366);
  static const Color _blue      = Color(0xFF6C63FF);
  static const Color _coral     = Color(0xFFFF6584);

  // Feature pills data — mirrors features_hub cards
  static const _pills = [
    _Pill('WhatsApp', _green,  Icons.chat_bubble_outline),
    _Pill('Reels',    _pink,   Icons.play_circle_outline),
    _Pill('GIF',      _blue,   Icons.gif_box_outlined),
    _Pill('Auto Split', _orange, Icons.content_cut),
    _Pill('Formats',  _purple, Icons.folder_open_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();
    _runSequence();
    _initApp();
  }

  void _setupControllers() {
    _bgController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800));
  }

  void _setupAnimations() {
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _bgController, curve: Curves.easeIn));

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(
        begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));

    _cardsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _cardsController, curve: Curves.easeOut));
    _cardsSlide = Tween<Offset>(
        begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardsController, curve: Curves.easeOutCubic));

    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.linear));

    _pulse = Tween<double>(begin: 0.82, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeInOut));
  }

  Future<void> _runSequence() async {
    await _bgController.forward();
    _logoController.forward();
    _progressController.forward();
    await Future.delayed(const Duration(milliseconds: 450));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    _cardsController.forward();
  }

  Future<void> _initApp() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    } catch (_) {
      // Firebase fail thay to bhi splash chale
    }
    if (!mounted) return;
    setState(() => _isInitialized = true);

    // Minimum 3s splash display
    _minDisplayTimer = Timer(const Duration(milliseconds: 3000), () {
      _navigateToMain();
    });
  }

  void _navigateToMain() {
    if (!mounted || _navigationComplete) return;
    _navigationComplete = true;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const BottomNavigationScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _minDisplayTimer?.cancel();
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _cardsController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _bgFade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Decorative background glow blobs ──────────────
            _BgBlobs(),

            // ── Main content ──────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Center block — logo + title + pills
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 28.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ── Logo ──────────────────────────
                            AnimatedBuilder(
                              animation: Listenable.merge(
                                  [_logoController, _pulseController]),
                              builder: (_, __) => FadeTransition(
                                opacity: _logoFade,
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: _LogoCard(
                                    shimmer: _shimmer,
                                    pulse: _pulse,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 40.h),

                            // ── App title + tagline ───────────
                            FadeTransition(
                              opacity: _textFade,
                              child: SlideTransition(
                                position: _textSlide,
                                child: _TitleSection(),
                              ),
                            ),

                            SizedBox(height: 40.h),

                            // ── Feature pills row ─────────────
                            FadeTransition(
                              opacity: _cardsFade,
                              child: SlideTransition(
                                position: _cardsSlide,
                                child: _FeaturePillsRow(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Progress pinned to bottom
                  FadeTransition(
                    opacity: _textFade,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 52.h),
                      child: _ProgressSection(
                        progress: _progress,
                        isInitialized: _isInitialized,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Background blobs — same vibe as features_hub gradient overlays
// ═══════════════════════════════════════════════════════════════════
class _BgBlobs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-left purple blob
        Positioned(
          top: -80,
          left: -60,
          child: Container(
            width: 280.w,
            height: 280.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C63FF).withOpacity(0.07),
            ),
          ),
        ),
        // Top-right pink blob
        Positioned(
          top: 60,
          right: -80,
          child: Container(
            width: 220.w,
            height: 220.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF6584).withOpacity(0.06),
            ),
          ),
        ),
        // Bottom-center orange blob
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 260.w,
              height: 180.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(130.r),
                color: const Color(0xFFFF6B35).withOpacity(0.05),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Logo card — features_hub icon container style
// ═══════════════════════════════════════════════════════════════════
class _LogoCard extends StatelessWidget {
  final Animation<double> shimmer;
  final Animation<double> pulse;

  const _LogoCard({required this.shimmer, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring (pulse animation)
        Container(
          width: (148 * pulse.value).w,
          height: (148 * pulse.value).w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE91E63).withOpacity(0.08 * pulse.value),
          ),
        ),
        // Card
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF6B35),
                Color(0xFFE91E63),
                Color(0xFF9C27B0),
              ],
            ),
            // features_hub card boxShadow style
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withOpacity(0.40),
                blurRadius: 32,
                offset: Offset(0, 12.h),
              ),
              BoxShadow(
                color: const Color(0xFFFF6B35).withOpacity(0.18),
                blurRadius: 50,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Logo image
              ClipRRect(
                borderRadius: BorderRadius.circular(32.r),
                child: Image.asset(
                  'assets/images/Gemini_Generated_Image_2raqqs2raqqs2raq.png',
                  width: 120.w,
                  height: 120.w,
                  fit: BoxFit.cover,
                ),
              ),
              // Shimmer sweep
              AnimatedBuilder(
                animation: shimmer,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(32.r),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(shimmer.value - 1.0, -0.3),
                        end: Alignment(shimmer.value, 0.3),
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.22),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Title + tagline — features_hub header text style
// ═══════════════════════════════════════════════════════════════════
class _TitleSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gradient title (ShaderMask — same as features_hub white text but gradient)
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFF6B35),
              Color(0xFFE91E63),
              Color(0xFF9C27B0),
            ],
          ).createShader(bounds),
          child: Text(
            'Video Clipper',
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
        ),

        SizedBox(height: 12.h),

        // Tagline chip — matches features_hub promo banner style
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            // features_hub gradient banner opacity style
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withOpacity(0.15),
                const Color(0xFFFF6584).withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.20),
            ),
          ),
          child: Text(
            'Split Long Videos in Seconds',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Feature pills — features_hub tag chip style, horizontal scroll
// ═══════════════════════════════════════════════════════════════════

class _Pill {
  final String label;
  final Color color;
  final IconData icon;
  const _Pill(this.label, this.color, this.icon);
}

class _FeaturePillsRow extends StatelessWidget {
  static const _pills = _SplashscreensState._pills;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.center,
      children: _pills.map((p) => _PillChip(pill: p)).toList(),
    );
  }
}

class _PillChip extends StatelessWidget {
  final _Pill pill;
  const _PillChip({required this.pill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        // Same tag style as features_hub
        color: pill.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: pill.color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pill.icon, color: pill.color, size: 13.sp),
          SizedBox(width: 5.w),
          Text(
            pill.label,
            style: TextStyle(
              color: pill.color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Progress section — dark themed
// ═══════════════════════════════════════════════════════════════════
class _ProgressSection extends StatelessWidget {
  final Animation<double> progress;
  final bool isInitialized;

  const _ProgressSection({
    required this.progress,
    required this.isInitialized,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, __) => Column(
        children: [
          // Progress track — features_hub surface color
          Container(
            width: 140.w,
            height: 3.h,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),  // features_hub border color
              borderRadius: BorderRadius.circular(2.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFE91E63)],
                  ),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
          ),

          SizedBox(height: 14.h),

          Text(
            isInitialized ? 'Ready' : 'Starting up...',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white38,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}