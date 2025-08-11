// ignore_for_file: file_names, deprecated_member_use

import 'package:auto_clipper_app/Logic/Nativ_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

class NativeAdWidget extends StatefulWidget {
  final double? height;
  final double? width;
  final EdgeInsets? margin;
  final BoxDecoration? decoration;
  final bool showLoadingShimmer;
  final Color? backgroundColor;

  const NativeAdWidget({
    super.key,
    this.height = 300,
    this.width,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.decoration,
    this.showLoadingShimmer = true,
    this.backgroundColor,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget>
    with SingleTickerProviderStateMixin {
  final NativeAdsController _controller = NativeAdsController();
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _timeoutTimer;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize shimmer animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.showLoadingShimmer) {
      _animationController.repeat();
    }

    // Initialize properly with longer delay
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        _initializeAndLoadAd();
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndLoadAd() async {
    if (!mounted) return;

    try {
      _controller.dispose();
      await Future.delayed(const Duration(milliseconds: 300));

      await _controller.initializeAds();
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _loadAd();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Initialization failed: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadAd() async {
    if (!mounted) return;

    if (kDebugMode) {
      print('🔄 Starting native ad load...');
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    // Start shimmer animation
    if (widget.showLoadingShimmer && !_animationController.isAnimating) {
      _animationController.repeat();
    }

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isLoading) {
        _animationController.stop();
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Ad loading timeout';
        });
      }
    });

    try {
      await _controller.forceReload(
        onAdLoaded: (ad) {
          _timeoutTimer?.cancel();
          _animationController.stop();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = false;
              _errorMessage = '';
            });
          }
        },
        onAdFailedToLoad: (error) {
          _timeoutTimer?.cancel();
          _animationController.stop();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.message;
            });
          }
          if (kDebugMode) {
            print('Native ad failed: ${error.message}');
          }
        },
      );
    } catch (e) {
      _timeoutTimer?.cancel();
      _animationController.stop();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  BoxDecoration get _defaultDecoration => BoxDecoration(
    color: widget.backgroundColor ?? Colors.white,

    borderRadius: BorderRadius.circular(20.sp), // Added .sp
  );

  Widget _buildShimmerEffect() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.sp), // Added .sp
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE91E63).withOpacity(0.1),
                const Color(0xFFE91E63).withOpacity(0.05),
                const Color(0xFFE91E63).withOpacity(0.1),
              ],
              stops:
                  [
                    _shimmerAnimation.value - 0.3,
                    _shimmerAnimation.value,
                    _shimmerAnimation.value + 0.3,
                  ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.all(16.sp), // Added .sp
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App icon and title placeholder
            Row(
              children: [
                Container(
                  width: 40.sp, // Added .sp
                  height: 40.sp, // Added .sp
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.sp), // Added .sp
                  ),
                ),
                SizedBox(width: 12.sp), // Added .sp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16.sp, // Added .sp
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(
                            4.sp,
                          ), // Added .sp
                        ),
                      ),
                      SizedBox(height: 8.sp), // Added .sp
                      Container(
                        height: 12.sp, // Added .sp
                        width: 120.sp, // Added .sp
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            4.sp,
                          ), // Added .sp
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.sp), // Added .sp
            // Description placeholder
            Container(
              height: 12.sp, // Added .sp
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4.sp), // Added .sp
              ),
            ),
            SizedBox(height: 8.sp), // Added .sp
            Container(
              height: 12.sp, // Added .sp
              width: 200.sp, // Added .sp
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4.sp), // Added .sp
              ),
            ),
            const Spacer(),
            // Install button placeholder
            Container(
              height: 40.sp, // Added .sp
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.sp), // Added .sp
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    if (widget.showLoadingShimmer) {
      return _buildShimmerEffect();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24.sp, // Added .sp
            height: 24.sp, // Added .sp
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
            ),
          ),
          SizedBox(height: 12.sp), // Added .sp
          Text(
            'Loading Ad...',
            style: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: 14.sp, // Added .sp
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.sp,
        vertical: 12.sp,
      ), // Added .sp
      child: Row(
        children: [
          // Error icon with circular background
          Container(
            width: 36.sp, // Added .sp
            height: 36.sp, // Added .sp
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              color: const Color(0xFFE91E63),
              size: 20.sp, // Added .sp
            ),
          ),
          SizedBox(width: 12.sp), // Added .sp
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main error title
                Text(
                  'Ad Failed to Load',
                  style: TextStyle(
                    color: const Color(0xFFE91E63),
                    fontSize: 14.sp, // Added .sp
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Error message subtitle
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.sp), // Added .sp
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 11.sp, // Added .sp
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    // Return only SizedBox with height 1 when there's an error or no ad loaded
    if ((_hasError || _controller.nativeAd == null) && !_isLoading) {
      return const SizedBox(height: 1);
    }

    final decoration = widget.decoration ?? _defaultDecoration;

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child:
            _isLoading
                ? _buildLoadingState()
                : AdWidget(ad: _controller.nativeAd!),
      ),
    );
  }
}
