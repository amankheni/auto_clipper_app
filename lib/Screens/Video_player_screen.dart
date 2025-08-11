// ignore_for_file: deprecated_member_use, sized_box_for_whitespace, library_private_types_in_public_api, file_names

import 'dart:io';
import 'package:auto_clipper_app/Constant/Colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;

  const VideoPlayerWidget({super.key, required this.videoPath});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isPlaying = false;
  bool _isInitialized = false;
  String _currentPosition = "00:00";
  String _totalDuration = "00:00";

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _totalDuration = _formatDuration(_controller.value.duration);
          });
          _fadeController.forward();
          _scaleController.forward();
          _controller.play();
          _isPlaying = true;

          // Listen to position changes
          _controller.addListener(_updatePosition);
        }
      });
  }

  void _updatePosition() {
    if (mounted) {
      setState(() {
        _currentPosition = _formatDuration(_controller.value.position);
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        gradient: AppColors.secondaryGradient,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.glassBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder, width: 1.w),
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3.w,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnDark),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Loading Video...',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(  
          opacity: _fadeAnimation.value,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withOpacity(0.3),
                        blurRadius: 30.r,
                        offset: Offset(0, 15.h),
                      ),
                      BoxShadow(
                        color: AppColors.primaryPink.withOpacity(0.2),
                        blurRadius: 50.r,
                        offset: Offset(0, 25.h),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(4.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        // Gradient overlay for better control visibility
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                                stops: const [0.0, 0.7, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: [
          Container(
            height: 4.h,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: AppColors.primaryOrange,
                bufferedColor: AppColors.primaryOrange.withOpacity(0.3),
                backgroundColor: AppColors.borderLight,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentPosition,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _totalDuration,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    double size = 24,
    bool isPrimary = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isPrimary ? 30.r : 20.r),
          child: Container(
            padding: EdgeInsets.all(isPrimary ? 16.w : 12.w),
            decoration: BoxDecoration(
              gradient: isPrimary ? AppColors.accentGradient : null,
              color: isPrimary ? null : AppColors.glassBackgroundwhite,
              borderRadius: BorderRadius.circular(isPrimary ? 30.r : 20.r),
              boxShadow: [
                BoxShadow(
                  color:
                      isPrimary
                          ? AppColors.primaryPink.withOpacity(0.4)
                          : AppColors.shadowLight,
                  blurRadius: isPrimary ? 15.r : 8.r,
                  offset: Offset(0, isPrimary ? 8.h : 4.h),
                ),
              ],
              border: Border.all(
                color: isPrimary ? Colors.transparent : AppColors.borderLight,
                width: 1.w,
              ),
            ),
            child: Icon(
              icon,
              size: size.sp,
              color: isPrimary ? AppColors.textOnDark : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
        border: Border.all(color: AppColors.borderLight, width: 1.w),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: Icons.replay_10,
            onPressed: () {
              final currentPosition = _controller.value.position;
              final newPosition = currentPosition - const Duration(seconds: 10);
              _controller.seekTo(
                newPosition > Duration.zero ? newPosition : Duration.zero,
              );
            },
            color: AppColors.textSecondary,
            size: 20,
          ),
          _buildControlButton(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            onPressed: () {
              setState(() {
                _isPlaying ? _controller.pause() : _controller.play();
                _isPlaying = !_isPlaying;
              });
            },
            color: AppColors.textOnDark,
            size: 28,
            isPrimary: true,
          ),
          _buildControlButton(
            icon: Icons.forward_10,
            onPressed: () {
              final currentPosition = _controller.value.position;
              final totalDuration = _controller.value.duration;
              final newPosition = currentPosition + const Duration(seconds: 10);
              _controller.seekTo(
                newPosition < totalDuration ? newPosition : totalDuration,
              );
            },
            color: AppColors.textSecondary,
            size: 20,
          ),
          _buildControlButton(
            icon: Icons.replay,
            onPressed: () {
              _controller.seekTo(Duration.zero);
              _controller.play();
              setState(() => _isPlaying = true);
            },
            color: AppColors.primaryOrange,
            size: 22,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ), // Reduced padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundColor,
            AppColors.backgroundColor.withOpacity(0.8),
            AppColors.primaryCyan.withOpacity(0.05),
          ],
        ),
      ),
      child: SingleChildScrollView(
        // Added scroll for small screens
        child: Column(
          mainAxisSize: MainAxisSize.min, // Important to prevent overflow
          children: [
            if (!_isInitialized)
              SizedBox(
                height: 200.h, // Fixed height for loading
                child: _buildLoadingWidget(),
              )
            else ...[
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height *
                      0.6, // Limit video height
                ),
                child: _buildVideoPlayer(),
              ),
              SizedBox(height: 12.h), // Reduced spacing
              _buildProgressBar(),
              _buildControls(),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_updatePosition);
    _controller.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
