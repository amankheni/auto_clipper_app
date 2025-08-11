// ignore_for_file: file_names, deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:auto_clipper_app/Constant/Colors.dart';
import 'package:auto_clipper_app/Logic/Interstitial_Controller.dart';
import 'package:auto_clipper_app/Logic/Nativ_controller.dart';
import 'package:auto_clipper_app/Logic/video_downlod_controller.dart';
import 'package:auto_clipper_app/Screens/Video_player_screen.dart';
import 'package:auto_clipper_app/widget/Native_ads_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoSessionDetailScreen extends StatefulWidget {
  final VideoSession session;

  const VideoSessionDetailScreen({super.key, required this.session});

  @override
  _VideoSessionDetailScreenState createState() =>
      _VideoSessionDetailScreenState();
}

class _VideoSessionDetailScreenState extends State<VideoSessionDetailScreen>
    with TickerProviderStateMixin {
  final VideoDownloadController _controller = VideoDownloadController();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  String _statusMessage = '';
  final NativeAdsController _nativeAdsController = NativeAdsController();
  bool _shouldShowAd = false;
  bool _hasError = false; // Defined the missing variable
   
// Defined the missing variable
  bool _isAdLoading = false; // Corrected typo from _isAdvLoading

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );


    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _initializeAndLoadAd();
  }




  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndLoadAd() async {
    try {
      // Ensure remote config is ready

      // Initialize ads controller
      await _nativeAdsController.initializeAds();

      // Wait a bit more for stability
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        setState(() {
          _shouldShowAd = true; // Enable ad widget creation
        });

        // Small delay before loading
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          _loadAd();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ad initialization error: $e');
      }
      if (mounted) {
        setState(() {
          _shouldShowAd = true; // Still show widget for retry
          _hasError = true;
        });
      }
    }
  }

  Future<void> _loadAd() async {
    if (!mounted || _isAdLoading) return;

    setState(() {
      _isAdLoading = true;
      _hasError = false;
    });

    try {
      // Double-check initialization
      if (!_nativeAdsController.isInitialized) {
        await _nativeAdsController.initializeAds();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      await _nativeAdsController.loadNativeAd(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoading = false;
              _hasError = false;
            });
          }
        },
        onAdFailedToLoad: (error) {
          if (mounted) {
            setState(() {
              _isAdLoading = false;
              _hasError = true;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // Copy your existing methods here: _initializeAndLoadAd, _downloadToGallery,
  // _shareVideo, _previewVideo, _showCustomSnackBar, etc.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildSessionDetailAppBar(),
            Expanded(child: _buildSessionDetailContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionDetailAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.2),
            blurRadius: 12.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 68.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Session icon and title
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.video_library_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.session.displayName,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.session.videos.length} Videos',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),

              // Delete session button
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                  onSelected: (value) {
                    if (value == 'delete_session') {
                      _showDeleteSessionDialog();
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'delete_session',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.errorColor,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Delete Session',
                                style: TextStyle(color: AppColors.errorColor),
                              ),
                            ],
                          ),
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

  Widget _buildSessionDetailContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Session info (reuse your existing _buildEnhancedStorageInfo but for single session)
          _buildSessionStorageInfo(),

          // Status message
          if (_statusMessage.isNotEmpty) _buildEnhancedStatusMessage(),

          // Native ad
          if (_shouldShowAd)
           NativeAdWidget(
              height: 100.sp,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              margin: EdgeInsets.all(0),
              backgroundColor: Colors.white,      
              showLoadingShimmer: false,
            ),

          // Download all button
          _buildDownloadAllButton(),

          // Videos list
          _buildVideosList(),
        ],
      ),
    );
  }

  Widget _buildSessionStorageInfo() {
    // Similar to your existing _buildEnhancedStorageInfo but for single session
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.h,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.video_library_outlined,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Details',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Videos',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10.sp,
                            ),
                          ),
                          Text(
                            '${widget.session.videos.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1.w,
                      height: 28.h,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Storage',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10.sp,
                            ),
                          ),
                          Text(
                            widget.session.totalSize,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadAllButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: _buildEnhancedActionButton(
        icon:
            _controller.isBulkDownloading
                ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Icon(
                  Icons.download_rounded,
                  size: 20.sp,
                  color: Colors.white,
                ),
        label:
            _controller.isBulkDownloading
                ? 'Downloading ${_controller.downloadProgress}/${_controller.totalDownloads}'
                : 'Download All Videos',
        onTap:
            _controller.isBulkDownloading ? null : () => _downloadAllVideos(),
        gradient: AppColors.primaryGradient,
      ),
    );
  }

  Widget _buildVideosList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: widget.session.videos.length,
      itemBuilder: (context, index) {
        return _buildEnhancedVideoItem(widget.session.videos[index]);
      },
    );
  }

  void _showDeleteSessionDialog() {
    // Show delete dialog and pop back to previous screen after deletion
  }

  void _downloadAllVideos() async {
    final message = await _controller.downloadAllVideosSimple(
      widget.session,
      context,
    );
    setState(() => _statusMessage = message);
  }

   Widget _buildEnhancedActionButton({
    required Widget icon,
    required String label,
    required VoidCallback? onTap,
    required Gradient gradient,
  }) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        gradient:
            onTap != null
                ? gradient
                : LinearGradient(
                  colors: [
                    AppColors.textTertiary.withOpacity(0.3),
                    AppColors.textTertiary.withOpacity(0.2),
                  ],
                ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow:
            onTap != null
                ? [
                  BoxShadow(
                    color:
                        gradient == AppColors.primaryGradient
                            ? AppColors.primaryOrange.withOpacity(0.3)
                            : AppColors.primaryPink.withOpacity(0.3),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                if (label.isNotEmpty) ...[
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

   Widget _buildEnhancedVideoItem(ProcessedVideo video) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          // Video preview with thumbnail
          GestureDetector(
            onTap: () => _previewVideo(video.path),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 200.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20.r),
                    ),
                    image:
                        video.thumbnailPath != null
                            ? DecorationImage(
                              image: FileImage(File(video.thumbnailPath!)),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      video.thumbnailPath == null
                          ? Icon(
                            Icons.videocam,
                            size: 50.sp,
                            color: Colors.white,
                          )
                          : null,
                ),
                Positioned(
                  child: Icon(
                    Icons.play_circle_filled,
                    size: 50.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Video info and actions
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      video.formattedSize,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    Text(
                      '${video.durationInSeconds}s',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.download,
                        label: 'Download',
                        onPressed: () => _downloadToGallery(video.path),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.share,
                        label: 'Share',
                        onPressed: () => _shareVideo(video.path),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Future<void> _downloadToGallery(String videoPath) async {
    setState(() {
      _statusMessage = 'Requesting permissions...';
    });

    final message = await _controller.downloadToGallery(videoPath);

    setState(() {
      _statusMessage = message;
    });

    if (message.contains('successfully')) {
      _showCustomSnackBar(
        'Video saved successfully',
        AppColors.successColor,
        Icons.check_circle,
      );
    } else if (message.contains('permission')) {
      _showPermissionDialog();
    } else {
      _showCustomSnackBar(
        'Download failed: $message',
        AppColors.errorColor,
        Icons.error,
      );
    }

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.security, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                'Permission Required',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Storage permission is required to download videos. Please grant permission in app settings.',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: TextButton(
                child: Text(
                  'Open Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
              ),
            ),
          ],
        );
      },
    );
  }

   void _showCustomSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.r),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareVideo(String videoPath) async {
    try {
      await _controller.shareVideo(videoPath);
      _showCustomSnackBar('Sharing video...', AppColors.infoColor, Icons.share);
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to share video: $e';
      });
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,

                builder:
                    (context) => Center(child: CircularProgressIndicator()),
              );

              // Wait 1-2 seconds
              await Future.delayed(Duration(seconds: 1));

              // Show interstitial ad
              InterstitialAdsController().handleButtonClick(context);

              // Dismiss loader
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }

              // Execute original onPressed
              onPressed();
            },
            borderRadius: BorderRadius.circular(14.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20.sp, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


   void _previewVideo(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text('Video Preview'),
                actions: [
                  IconButton(
                    icon: Icon(Icons.download),
                    onPressed: () => _downloadToGallery(path),
                  ),
                  IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () => _shareVideo(path),
                  ),
                ],
              ),
              body: Center(child: VideoPlayerWidget(videoPath: path)),
            ),
      ),
    );
  }
  

  Widget _buildEnhancedStatusMessage() {
    if (_statusMessage.isEmpty) return SizedBox.shrink();

    final isError =
        _statusMessage.toLowerCase().contains('error') ||
        _statusMessage.toLowerCase().contains('failed');
    final isDownloading = _controller.isBulkDownloading;

    Color statusColor =
        isError
            ? AppColors.errorColor
            : isDownloading
            ? AppColors.infoColor
            : AppColors.successColor;

    IconData statusIcon =
        isError
            ? Icons.error_outline
            : isDownloading
            ? Icons.download
            : Icons.check_circle_outline;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          if (isDownloading)
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(statusIcon, color: statusColor, size: 16.sp),
            ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 14.sp,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
