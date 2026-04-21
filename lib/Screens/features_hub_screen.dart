// ignore_for_file: deprecated_member_use, file_names

import 'package:auto_clipper_app/Logic/ad_service.dart';
import 'package:auto_clipper_app/Screens/story_editor_screen.dart';
import 'package:auto_clipper_app/Screens/whatsapp_status_split_screen.dart';
import 'package:auto_clipper_app/Screens/reels_shorts_preset_screen.dart';
import 'package:auto_clipper_app/Screens/video_to_gif_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class _FeatureCard {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final List<String> tags;
  final Widget Function() routeBuilder;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.tags,
    required this.routeBuilder,
  });
}

final List<_FeatureCard> _features = [
  _FeatureCard(
    title: 'WhatsApp Status',
    subtitle: 'Split Mode',
    description:
    'Auto-split any video into 30-second clips with 9:16 portrait format. Perfect for WhatsApp Status stories.',
    icon: Icons.chat_bubble_outline,
    gradientColors: [const Color(0xFF25D366), const Color(0xFF128C7E)],
    tags: ['30s clips', '9:16', 'Portrait'],
    routeBuilder: () => const WhatsAppStatusSplitScreen(),
  ),
  _FeatureCard(
    title: 'Reels & Shorts',
    subtitle: 'Platform Presets',
    description:
    'Choose from Instagram Reels, YouTube Shorts, TikTok, Facebook, X/Twitter & Snapchat — auto-configured durations.',
    icon: Icons.play_circle_fill_outlined,
    gradientColors: [const Color(0xFFE1306C), const Color(0xFF833AB4)],
    tags: ['6 platforms', 'Auto format', 'Smart split'],
    routeBuilder: () => const ReelsShortsPresetScreen(),
  ),
  _FeatureCard(
    title: 'Video to GIF',
    subtitle: 'GIF Maker',
    description:
    'Convert any video clip into a high-quality animated GIF. Trim, adjust quality, then save or share.',
    icon: Icons.gif_box_outlined,
    gradientColors: [const Color(0xFF6C63FF), const Color(0xFFFF6584)],
    tags: ['Trim & crop', 'Quality control', 'Share ready'],
    routeBuilder: () => const VideoToGifScreen(),
  ),
  _FeatureCard(
    title: 'Story Creator',
    subtitle: 'Instagram Style',
    description:
    'Design stunning stories with text, emojis & stickers on your photos. Share directly to Instagram, WhatsApp & more.',
    icon: Icons.auto_awesome_rounded,
    gradientColors: [const Color(0xFFF58529), const Color(0xFFDD2A7B)],
    tags: ['Text & Emoji', 'Stickers', 'One-tap Share'],
    routeBuilder: () => const StoryEditorScreen(),
  ),
];

class FeaturesHubScreen extends StatefulWidget {
  const FeaturesHubScreen({super.key});

  @override
  State<FeaturesHubScreen> createState() => _FeaturesHubScreenState();
}

class _FeaturesHubScreenState extends State<FeaturesHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;
  late List<Animation<Offset>> _cardSlideAnimations;


  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _cardControllers = List.generate(
      _features.length,
          (i) => AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      ),
    );

    _cardAnimations = _cardControllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: c, curve: Curves.easeOutBack),
    ))
        .toList();

    _cardSlideAnimations = _cardControllers
        .map((c) => Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + i * 150), () {
        if (mounted) _cardControllers[i].forward();
      });
    }

  }


  @override
  void dispose() {
    _headerController.dispose();
    for (final c in _cardControllers) c.dispose();
    super.dispose();
  }

  void _navigate(int index) {
    AdService.showAdThenAction(
      onActionComplete: () async{
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (ctx, anim, _) => _features[index].routeBuilder(),
            transitionsBuilder: (ctx, anim, _, child) {
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerController,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                              ),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Icon(Icons.auto_awesome,
                                color: Colors.white, size: 22.sp),
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Tools',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Advanced video features',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 13.sp),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ✅ Feature Cards + Native Ad after card 1
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 30.h),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                    // ✅ Native Ad — Card 0 (WhatsApp) ની પછી insert
                    if (i == 0) {
                      return Column(
                        children: [
                          // Feature Card 1
                          AnimatedBuilder(
                            animation: _cardAnimations[i],
                            builder: (ctx, _) => SlideTransition(
                              position: _cardSlideAnimations[i],
                              child: FadeTransition(
                                opacity: _cardAnimations[i],
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 16.h),
                                  child: _FeatureCardWidget(
                                    feature: _features[i],
                                    onTap: () => _navigate(i),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          AdService.nativeWidget(
                            adId: 'feature_hub_medium_1',
                            isLarge: true,
                            showLabel: false,
                            margin: const EdgeInsets.only(bottom: 8),
                            context: context,
                          ),
                        ],
                      );
                    }

                    return AnimatedBuilder(
                      animation: _cardAnimations[i],
                      builder: (ctx, _) => SlideTransition(
                        position: _cardSlideAnimations[i],
                        child: FadeTransition(
                          opacity: _cardAnimations[i],
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: _FeatureCardWidget(
                              feature: _features[i],
                              onTap: () => _navigate(i),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _features.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feature Card Widget ─────────────────────────────────────────────────────

class _FeatureCardWidget extends StatefulWidget {
  final _FeatureCard feature;
  final VoidCallback onTap;

  const _FeatureCardWidget({
    required this.feature,
    required this.onTap,
  });

  @override
  State<_FeatureCardWidget> createState() => _FeatureCardWidgetState();
}

class _FeatureCardWidgetState extends State<_FeatureCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _pressController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _pressController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: _isPressed
                  ? f.gradientColors.first.withOpacity(0.5)
                  : Colors.white.withOpacity(0.07),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: f.gradientColors.first.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 120.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      f.gradientColors[0].withOpacity(0.25),
                      f.gradientColors[1].withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: f.gradientColors[0].withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: -10,
                      child: Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: f.gradientColors[1].withOpacity(0.06),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: f.gradientColors),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: f.gradientColors[0].withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(f.icon, color: Colors.white, size: 26.sp),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  f.subtitle,
                                  style: TextStyle(
                                    color: f.gradientColors[0],
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white54,
                              size: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.description,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: f.tags
                          .map((tag) => Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: f.gradientColors[0].withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: f.gradientColors[0].withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: f.gradientColors[0],
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}