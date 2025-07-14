// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_brace_in_string_interps, avoid_print, library_private_types_in_public_api, unnecessary_null_comparison

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:auto_clipper_app/Constant/Colors.dart';
import 'package:auto_clipper_app/Logic/Interstitial_Controller.dart';
import 'package:auto_clipper_app/Logic/Nativ_controller.dart';
import 'package:auto_clipper_app/Logic/video_downlod_controller.dart';
import 'package:auto_clipper_app/Screens/Video_player_screen.dart';
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
  Timer? _refreshTimer;
  bool _isAutoRefreshEnabled = true;
  DateTime? _lastRefreshTime;

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
    _startAutoRefresh(); // Start auto-refresh

    final remoteConfig = RemoteConfigService();
    if (kDebugMode) {
      print("Native ads enabled: ${remoteConfig.nativeAdsEnabled}");
      print("Native ad unit ID: ${remoteConfig.nativeAdUnitId}");
    }
    _initializeAndLoadAd();
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

  // Correct lifecycle method name
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //super.didChangeAppLifecycleState(state); // Note the correct capitalization

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground, start auto-refresh
        _startAutoRefresh();
        // Immediately refresh to catch any changes
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) _refreshVideoSessions();
        });
        break;
      case AppLifecycleState.paused:
        // App went to background, stop auto-refresh to save battery
        _stopAutoRefresh();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh(); // Stop auto-refresh
    _animationController.dispose();
    super.dispose();
  }

  // Add this method to your _VideoDownloadScreenState class
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    if (_isAutoRefreshEnabled) {
      _refreshTimer = Timer.periodic(Duration(seconds: 3), (timer) {
        if (mounted) {
          _refreshVideoSessions();
        }
      });
    }
  }

  // Add this method to your _VideoDownloadScreenState class
  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  // Add this method to your _VideoDownloadScreenState class
  Future<void> _refreshVideoSessions() async {
    if (_isLoading) return; // Prevent multiple simultaneous refreshes

    try {
      final sessions = await _controller.loadVideoSessions();
      if (mounted) {
        setState(() {
          final oldCount = _sessions.fold<int>(
            0,
            (sum, session) => sum + session.videos.length,
          );
          _sessions = sessions;
          final newCount = _sessions.fold<int>(
            0,
            (sum, session) => sum + session.videos.length,
          );

          // Preserve the selected session if it still exists
          if (_selectedSession != null) {
            _selectedSession = sessions.firstWhere(
              (s) => s.sessionId == _selectedSession!.sessionId,
              orElse: () => _selectedSession!,
            );
          }

          // Show notification if new videos were added
          if (newCount > oldCount) {
            final addedCount = newCount - oldCount;
            _showCustomSnackBar(
              '$addedCount new video${addedCount > 1 ? 's' : ''} added!',
              AppColors.successColor,
              Icons.video_library,
            );
          }

          _lastRefreshTime = DateTime.now();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Auto-refresh error: $e');
      }
    }
  }

  Widget _buildRefreshableContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: () async {
            await _loadVideoSessions();
          },
          color: AppColors.primaryBlue,
          backgroundColor: AppColors.cardBackground,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEnhancedStorageInfo(),
                  _buildEnhancedStatusMessage(),
                  _buildAutoRefreshIndicator(),
                  if (_shouldShowAd)
                     NativeAdWidget(
                          height: 100.sp,
                          margin: EdgeInsets.all(20),
                          backgroundColor: Colors.white,
                          showLoadingShimmer: false,
                        ),
                    SizedBox(height: 10.sp),
                  if (_isLoading)
                    SizedBox(height: 300.h, child: _buildEnhancedLoadingState())
                  else if (_sessions.isEmpty)
                    SizedBox(height: 400.h, child: _buildEnhancedEmptyState())
                  else
                    _buildVideosList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Add this new widget to show auto-refresh status
  Widget _buildAutoRefreshIndicator() {
    if (!_isAutoRefreshEnabled || _lastRefreshTime == null) {
      return SizedBox.shrink();
    }

    final timeSinceRefresh = DateTime.now().difference(_lastRefreshTime!);
    final nextRefreshIn = Duration(seconds: 3) - timeSinceRefresh;

    if (nextRefreshIn.isNegative) return SizedBox.shrink();
    return Container();
    // return Container(
    //   margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
    //   padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
    //   decoration: BoxDecoration(
    //     color: AppColors.primaryBlue.withOpacity(0.1),
    //     borderRadius: BorderRadius.circular(12.r),
    //     border: Border.all(
    //       color: AppColors.primaryBlue.withOpacity(0.3),
    //       width: 1,
    //     ),
    //   ),
    //   child: Row(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       SizedBox(
    //         width: 12.w,
    //         height: 12.w,
    //         child: CircularProgressIndicator(
    //           strokeWidth: 1.5,
    //           valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
    //         ),
    //       ),
    //       SizedBox(width: 8.w),
    //       Text(
    //         'Auto-refreshing...',
    //         style: TextStyle(
    //           fontSize: 11.sp,
    //           color: AppColors.primaryBlue,
    //           fontWeight: FontWeight.w500,
    //         ),
    //       ),
    //       SizedBox(width: 8.w),
    //       GestureDetector(
    //         onTap: () {
    //           setState(() {
    //             _isAutoRefreshEnabled = !_isAutoRefreshEnabled;
    //           });
    //           if (_isAutoRefreshEnabled) {
    //             _startAutoRefresh();
    //           } else {
    //             _stopAutoRefresh();
    //           }
    //         },
    //         child: Icon(
    //           _isAutoRefreshEnabled ? Icons.pause_circle : Icons.play_circle,
    //           size: 16.sp,
    //           color: AppColors.primaryBlue,
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }
  // Correct lifecycle method name

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
            color: AppColors.primaryOrange.withOpacity(0.2),
            blurRadius: 12.r,
            offset: Offset(0, 2.h),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.r,
            offset: Offset(0, 1.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 68.h, // Fixed compact height
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              // Back button (if session selected)
              if (_selectedSession != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSession = null;
                    });
                  },
                  child: Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
              if (_selectedSession != null) SizedBox(width: 12.w),

              // Main icon
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  _selectedSession != null
                      ? Icons.video_library_rounded
                      : Icons.download_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),

              // Title section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedSession != null
                          ? _selectedSession!.displayName
                          : 'My Downloads',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _selectedSession != null
                          ? 'Video Collection'
                          : 'Professional Video Downloader',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.75),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Menu button (if session selected)
              if (_selectedSession != null) ...[
                SizedBox(width: 8.w),
                Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    color: Colors.white,
                    elevation: 8,
                    offset: Offset(0, 8.h),
                    onSelected: (value) {
                      if (value == 'delete_session') {
                        _showDeleteSessionDialog(_selectedSession!);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'delete_session',
                            height: 44.h,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32.w,
                                    height: 32.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.errorColor.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.errorColor,
                                      size: 16.sp,
                                    ),
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
                          ),
                        ],
                  ),
                ),
              ],
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F0F23)],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.08),
                    blurRadius: 20.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: EdgeInsets.all(16.r),
                    child: Row(
                      children: [
                        // Compact icon container
                        Container(
                          width: 42.w,
                          height: 42.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurple.withOpacity(0.8),
                                AppColors.primaryPink.withOpacity(0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPurple.withOpacity(
                                  0.25,
                                ),
                                blurRadius: 8.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: Icon(
                            _selectedSession != null
                                ? Icons.video_library_outlined
                                : Icons.analytics_outlined,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // Content section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedSession != null
                                        ? 'Session Details'
                                        : 'Storage Overview',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.7),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      _selectedSession != null
                                          ? '${_selectedSession!.videos.length} Videos'
                                          : '$totalSessions Sessions',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              // Stats row
                              Row(
                                children: [
                                  // Videos count
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Videos',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          _selectedSession != null
                                              ? '${_selectedSession!.videos.length}'
                                              : '$totalVideos',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Compact divider
                                  Container(
                                    width: 1.w,
                                    height: 28.h,
                                    color: Colors.white.withOpacity(0.15),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                    ),
                                  ),
                                  // Storage size
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Storage',
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          _selectedSession != null
                                              ? _selectedSession!.totalSize
                                              : formattedTotalSize,
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
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
                  ),
                ),
              ),
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
                  icon:
                      _controller.isBulkDownloading &&
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
                  label:
                      _controller.isBulkDownloading &&
                              _selectedSession == session
                          ? 'Downloading ${_controller.downloadProgress}/${_controller.totalDownloads}'
                          : 'Download All Videos',
                  onTap:
                      _controller.isBulkDownloading
                          ? null
                          : () async {
                            // Set the selected session to show progress indicator
                            setState(() {
                              _selectedSession = session;
                            });

                            // Ensure ad is loaded before handling click
                            if (!InterstitialAdsController().isAdLoaded) {
                              await InterstitialAdsController()
                                  .loadInterstitialAd();
                            }

                            // Handle the button click (this will show ad if threshold is met)
                            InterstitialAdsController().handleButtonClick(
                              context,
                            );

                            // Small delay to allow ad to show if needed
                            await Future.delayed(Duration(milliseconds: 300));

                            // Start download without showing dialog
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

  Future<void> preloadNativeAds() async {
    final nativeAdsController = NativeAdsController();

    // FIX: Ensure proper initialization sequence
    await nativeAdsController.initializeAds();
    await Future.delayed(const Duration(milliseconds: 500));

    // FIX: Don't preload, just initialize. Let individual widgets load their own ads
    if (kDebugMode) {
      print('✅ Native ads controller preloaded and ready');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildGradientAppBar(),
            Expanded(child: _buildRefreshableContent()),
          ],
        ),
      ),
    );
  }
}
