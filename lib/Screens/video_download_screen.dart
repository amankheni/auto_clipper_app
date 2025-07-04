// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_brace_in_string_interps, avoid_print, library_private_types_in_public_api, unnecessary_null_comparison

import 'dart:io';
import 'dart:ui';

import 'package:auto_clipper_app/Constant/Colors.dart';
import 'package:auto_clipper_app/Logic/Interstitial_Controller.dart';
import 'package:auto_clipper_app/Logic/Nativ_controller.dart';
import 'package:auto_clipper_app/Logic/video_downlod_controller.dart';
import 'package:auto_clipper_app/comman%20class/remot_config.dart';
import 'package:auto_clipper_app/widget/Native_ads_widget.dart';
import 'package:flutter/foundation.dart';


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class VideoDownloadScreen extends StatefulWidget {
  const VideoDownloadScreen({super.key, this.preserveStateKey});

  final Key? preserveStateKey;

  @override
  _VideoDownloadScreenState createState() => _VideoDownloadScreenState();
}

class _VideoDownloadScreenState extends State<VideoDownloadScreen>
    with TickerProviderStateMixin {
  final VideoDownloadController _controller = VideoDownloadController();
  List<VideoSession> _sessions = [];
  bool _isLoading = false;
  String _statusMessage = '';
  VideoSession? _selectedSession;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final NativeAdsController _nativeAdsController = NativeAdsController();
  bool _hasError = false; // Defined the missing variable
  bool _isAdLoading = false; // Corrected typo from _isAdvLoading
  bool _shouldShowAd = false;

@override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _loadVideoSessions();
    _animationController.forward();

    final remoteConfig = RemoteConfigService();
    if (kDebugMode) {
      print("Native ads enabled: ${remoteConfig.nativeAdsEnabled}");
      print("Native ad unit ID: ${remoteConfig.nativeAdUnitId}");
    }
_initializeAndLoadAd();


    // // Initialize ads controller first, then load ad
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   if (mounted) {
    //     // Ensure controller is properly initialized
    //     await _nativeAdsController.initializeAds();

    //     // Add delay to ensure everything is ready
    //     await Future.delayed(const Duration(milliseconds: 800));

    //     if (mounted) {
    //       _loadAd();
    //     }
    //   }
    // });
  }


 @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Re-initialize and load ad if controller was disposed
    if (!_nativeAdsController.isInitialized || _hasError) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadAd();
        }
      });
    }
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }




Future<void> _initializeAndLoadAd() async {
    try {
      // Ensure remote config is ready
      final remoteConfig = RemoteConfigService();

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

  Future<void> _loadVideoSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await _controller.loadVideoSessions();
      setState(() {
        _sessions = sessions;
        // Preserve the selected session if it still exists
        if (_selectedSession != null) {
          _selectedSession = sessions.firstWhere(
            (s) => s.sessionId == _selectedSession!.sessionId,
            orElse: () => _selectedSession!,
          );
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading video sessions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  Future<void> _downloadAllVideosSimple(VideoSession session) async {
    setState(() {
      _statusMessage = 'Starting download...';
    });

    final message = await _controller.downloadAllVideosSimple(session, context);

    setState(() {
      _statusMessage = message;
    });

    final successCount = int.tryParse(message.split(' ').first) ?? 0;
    final failCount = session.videos.length - successCount;

    _showCustomSnackBar(
      '$successCount videos downloaded, $failCount failed',
      successCount > 0 ? AppColors.successColor : AppColors.errorColor,
      successCount > 0 ? Icons.download_done : Icons.error,
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

  Future<void> _deleteSession(VideoSession session) async {
    try {
      await _controller.deleteSession(session);
      await _loadVideoSessions();
      setState(() {
        _statusMessage = 'Session deleted successfully';
        _selectedSession = null;
      });

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to delete session: $e';
      });
    }
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

  Widget _buildGradientAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.3),
            blurRadius: 20.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Row(
            children: [
              if (_selectedSession != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSession = null;
                    });
                  },
                  // child: Icon(
                  //   Icons.arrow_back_ios_new,
                  //   color: Colors.white,
                  //   size: 20.sp,
                  // ),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    // decoration: BoxDecoration(
                    //   color: Colors.white.withOpacity(0.2),
                    //   borderRadius: BorderRadius.circular(12.r),
                    // ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
              if (_selectedSession != null) SizedBox(width: 16.w),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _selectedSession != null
                      ? Icons.video_library
                      : Icons.download_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedSession != null
                          ? _selectedSession!.displayName
                          : 'My Downloads',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _selectedSession != null
                          ? 'Video Collection'
                          : 'Professional Video Downloader',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedSession != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    onSelected: (value) {
                      if (value == 'delete_session') {
                        _showDeleteSessionDialog(_selectedSession!);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'delete_session',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: AppColors.errorColor,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'Delete Session',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.errorColor,
                                    fontWeight: FontWeight.w500,
                                  ),
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

  Widget _buildEnhancedStorageInfo() {
    final totalSessions = _sessions.length;
    final totalVideos = _sessions.fold<int>(
      0,
      (sum, session) => sum + session.videos.length,
    );
    final totalSize = _sessions.fold<int>(
      0,
      (sum, session) =>
          sum +
          session.videos.fold<int>(
            0,
            (videoSum, video) => videoSum + video.fileSizeInBytes,
          ),
    );

    String formattedTotalSize =
        totalSize < 1024 * 1024
            ? '${(totalSize / 1024).toStringAsFixed(1)} KB'
            : totalSize < 1024 * 1024 * 1024
            ? '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB'
            : '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';

    return Container(
      // Professional background with gradient
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.sp),
          bottomRight: Radius.circular(20.sp),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E), // Dark navy
            Color(0xFF16213E), // Darker blue
            Color(0xFF0F0F23), // Deep dark
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Stack(
              children: [
                // Subtle background pattern
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.1),
                          blurRadius: 50.r,
                          spreadRadius: 10.r,
                          offset: Offset(0, 20.h),
                        ),
                      ],
                    ),
                  ),
                ),
                // Main professional card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20.r,
                        offset: Offset(0, 8.h),
                      ),
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        blurRadius: 40.r,
                        offset: Offset(0, 16.h),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.04),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Header section
                            Row(
                              children: [
                                // Professional icon container
                                Container(
                                  width: 64.w,
                                  height: 64.h,
                                  decoration: BoxDecoration(
                                    gradient:
                                        AppColors.glassBackground != null
                                            ? LinearGradient(
                                              colors: [
                                                AppColors.primaryPurple
                                                    .withOpacity(0.8),
                                                AppColors.primaryPink
                                                    .withOpacity(0.6),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                            : AppColors.accentGradient,
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryPurple
                                            .withOpacity(0.3),
                                        blurRadius: 16.r,
                                        offset: Offset(0, 8.h),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _selectedSession != null
                                        ? Icons.video_library_outlined
                                        : Icons.analytics_outlined,
                                    color: Colors.white,
                                    size: 28.sp,
                                  ),
                                ),
                                SizedBox(width: 20.w),
                                // Title and subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedSession != null
                                            ? 'Session Details'
                                            : 'Storage Overview',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.7),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        _selectedSession != null
                                            ? '${_selectedSession!.videos.length} Videos'
                                            : '$totalSessions Sessions',
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            // Stats section
                            Container(
                              padding: EdgeInsets.all(20.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Left stats
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Videos',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          _selectedSession != null
                                              ? '${_selectedSession!.videos.length}'
                                              : '$totalVideos',
                                          style: TextStyle(
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Divider
                                  Container(
                                    width: 1.w,
                                    height: 40.h,
                                    color: Colors.white.withOpacity(0.15),
                                  ),
                                  SizedBox(width: 20.w),
                                  // Right stats
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Storage Used',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          _selectedSession != null
                                              ? _selectedSession!.totalSize
                                              : formattedTotalSize,
                                          style: TextStyle(
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
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
                  ),
                ),
                // Top highlight
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildSessionsList() {
    return ListView.builder(
      shrinkWrap: true, // Add this
      physics: NeverScrollableScrollPhysics(), // Add this
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 0.1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                (index * 0.1).clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildEnhancedSessionItem(_sessions[index]),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedSessionItem(VideoSession session) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 15.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedSession = session;
            });
          },
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withOpacity(0.3),
                            blurRadius: 12.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.folder_open,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.displayName,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              '${session.videos.length} videos • ${session.totalSize}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.textSecondary,
                        size: 16.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                  _buildEnhancedActionButton(
          icon: _controller.isBulkDownloading &&
                  _selectedSession == session
              ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
              : Icon(
                Icons.download_rounded,
                size: 20.sp,
                color: Colors.white,
              ),
          label: _controller.isBulkDownloading &&
                  _selectedSession == session
              ? 'Downloading ${_controller.downloadProgress}/${_controller.totalDownloads}'
              : 'Download All Videos',
          onTap: _controller.isBulkDownloading
              ? null
              : () async {
                  // Show loading dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,

                              builder:
                                  (context) => Center(
                                    child: CircularProgressIndicator(),
                                  ),
                            );

                            // Wait 1-2 seconds
                            await Future.delayed(Duration(seconds: 1));
                   InterstitialAdsController().handleButtonClick(context);
                  // Then proceed with download
                  _downloadAllVideosSimple(session);
                },
          gradient: AppColors.primaryGradient,
        ),
      
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideosList() {
    if (_selectedSession == null) return _buildSessionsList();

    return ListView.builder(
      shrinkWrap: true, // Add this
      physics: NeverScrollableScrollPhysics(), // Add this
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: _selectedSession!.videos.length,
      itemBuilder: (context, index) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 0.1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                (index * 0.05).clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildEnhancedVideoItem(_selectedSession!.videos[index]),
          ),
        );
      },
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

  Widget _buildEnhancedEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(40.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.1),
                  AppColors.primaryPurple.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.video_library_outlined,
              size: 64.sp,
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No videos found',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Process some videos to see them here',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildEnhancedLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60.w,
            height: 60.w,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Loading videos...',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteSessionDialog(VideoSession session) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            backgroundColor: AppColors.cardBackground,
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: AppColors.errorColor,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        'Delete Session',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Are you sure you want to delete "${session.displayName}" and all its videos?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.errorColor,
                              AppColors.errorColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteSession(session);
                          },
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildVideoThumbnail(ProcessedVideo video) {
    return GestureDetector(
      onTap: () => _previewVideo(video.path),
      child: Container(
        width: 60.w,
        height: 60.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: AppColors.secondaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
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
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 24.sp,
                )
                : Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white.withOpacity(0.8),
                    size: 24.sp,
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
void preloadNativeAds() {
    final nativeAdsController = NativeAdsController();
    nativeAdsController.initializeAds().then((_) {
      nativeAdsController.loadNativeAd();
    });
  }


@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildGradientAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildEnhancedStorageInfo(),
                    _buildEnhancedStatusMessage(),

                    // Only show native ad when ready
                    if (_shouldShowAd)
                      const NativeAdWidget(
                        height: 300,
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),

                    if (_isLoading)
                      SizedBox(
                        height: 300.h,
                        child: _buildEnhancedLoadingState(),
                      )
                    else if (_sessions.isEmpty)
                      SizedBox(height: 400.h, child: _buildEnhancedEmptyState())
                    else
                      _buildVideosList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;

  const VideoPlayerWidget({required this.videoPath});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
          _isPlaying = true;
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,
          colors: VideoProgressColors(
            playedColor: AppColors.primaryBlue,
            bufferedColor: AppColors.primaryBlue.withOpacity(0.3),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 32.sp,
              ),
              onPressed: () {
                setState(() {
                  _isPlaying ? _controller.pause() : _controller.play();
                  _isPlaying = !_isPlaying;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.replay, size: 32.sp),
              onPressed: () {
                _controller.seekTo(Duration.zero);
                _controller.play();
                setState(() => _isPlaying = true);
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    
    super.dispose();
  }
}
