// ignore_for_file: file_names

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

    // FIX: Initialize properly with longer delay
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(
        const Duration(milliseconds: 1000),
      ); // Increased delay
      if (mounted) {
        _initializeAndLoadAd();
      }
    });
  }


   @override
  void dispose() {
    _timeoutTimer?.cancel();
    _animationController.dispose();
    // FIX: Don't dispose the singleton controller here
    super.dispose();
  }

  Future<void> _initializeAndLoadAd() async {
    if (!mounted) return;

    try {
      // Force reinitialize the controller to ensure clean state
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

    // FIX: Force reload to ensure fresh ad
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      // Increased timeout
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
      // FIX: Use forceReload instead of loadNativeAd for subsequent loads
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
    color: widget.backgroundColor ?? const Color(0xFFF8F9FA),
    borderRadius: const BorderRadius.all(Radius.circular(16)),
    border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  Widget _buildShimmerEffect() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App icon and title placeholder
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Description placeholder
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Spacer(),
            // Install button placeholder
            Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(8),
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

    return Container(
      decoration: _defaultDecoration,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading Ad...',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Container(
      height: widget.height ?? 120.sp,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Error icon with circular background
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main error title
                  const Text(
                    'Ad Failed to Load',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Error message subtitle
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                : _hasError ||
                    !_controller.isNativeAdReady ||
                    _controller.nativeAd == null
                ? _buildErrorState()
                : AdWidget(ad: _controller.nativeAd!),
      ),
    );
  }
}
