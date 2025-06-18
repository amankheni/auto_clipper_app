// video_splitter_screen.dart
// ignore_for_file: avoid_print, depend_on_referenced_packages, deprecated_member_use

import 'dart:typed_data';

import 'package:auto_clipper_app/Constant/Colors.dart';
import 'package:auto_clipper_app/Logic/Split_Controller.dart';
import 'package:auto_clipper_app/Screens/video_download_screen.dart';
import 'package:auto_clipper_app/widget/Custom_Slider_ThumbShape.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';

class VideoSplitterScreen extends StatefulWidget {
  const VideoSplitterScreen({super.key});

  @override
  State<VideoSplitterScreen> createState() => _VideoSplitterScreenState();
}

class _VideoSplitterScreenState extends State<VideoSplitterScreen>
    with TickerProviderStateMixin {
  late VideoSplitterService _videoSplitterService;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  // UI State variables
  String? _selectedVideoPath;
  String? _selectedWatermarkPath;
  final TextEditingController _durationController = TextEditingController();
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusText = '';
  int _currentClip = 0;
  int _totalClips = 0;
  bool _useWatermark = false;
  DurationUnit _selectedUnit = DurationUnit.seconds;
  WatermarkPosition _watermarkPosition = WatermarkPosition.topRight;
  double _watermarkOpacity = 0.7;
  Uint8List? _videoThumbnail;
  bool _isPortraitMode = false;
  bool _useTextOverlay = false;
  final TextEditingController _textController = TextEditingController();
  String _textPrefix = 'Part';
  TextPosition _textPosition = TextPosition.topCenter;
  double _textOpacity = 1.0;
  Color _textColor = Colors.white;
  double _fontSize = 24.0;

  @override
  void initState() {
    super.initState();
    _videoSplitterService = VideoSplitterService(
      onProgressUpdate: _onProgressUpdate,
    );
    _requestPermissions();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseController.repeat(reverse: true);
  }

  Future<void> _requestPermissions() async {
    await _videoSplitterService.requestPermissions();
  }

  void _onProgressUpdate(VideoSplitterProgress progress) {
    setState(() {
      _currentClip = progress.currentClip;
      _totalClips = progress.totalClips;
      _progress = progress.progress;
      _statusText = progress.statusText;
      _isProcessing = progress.isProcessing;
    });

    if (_isProcessing) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  Future<void> _pickVideo() async {
    try {
      final videoPath = await _videoSplitterService.pickVideo();
      if (videoPath != null) {
        setState(() {
          _selectedVideoPath = videoPath;
          _statusText = 'Video selected: ${path.basename(videoPath)}';
        });
        // Generate thumbnail after video selection
        await _generateThumbnail(videoPath);
      }
    } catch (e) {
      _showError('Error picking video: $e');
    }
  }

  Future<void> _generateThumbnail(String videoPath) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );

      setState(() {
        _videoThumbnail = thumbnail;
      });
    } catch (e) {
      print('Error generating thumbnail: $e');
    }
  }

  Future<void> _pickWatermark() async {
    try {
      final watermarkPath = await _videoSplitterService.pickWatermark();
      if (watermarkPath != null) {
        setState(() {
          _selectedWatermarkPath = watermarkPath;
        });
      }
    } catch (e) {
      _showError('Error picking watermark: $e');
    }
  }

 // Update your startSplitting method to call the success dialog
  Future<void> _startSplitting() async {
    if (_selectedVideoPath == null) {
      _showError('Please select a video first');
      return;
    }

    final durationText = _durationController.text.trim();
    if (durationText.isEmpty) {
      _showError('Please enter clip duration');
      return;
    }

    final duration = double.tryParse(durationText) ?? 0;
    if (duration <= 0) {
      _showError('Please enter a valid duration');
      return;
    }

    if (_useWatermark && _selectedWatermarkPath == null) {
      _showError('Please select a watermark image');
      return;
    }

    if (_useTextOverlay && _textPrefix.trim().isEmpty) {
      _showError('Please enter text prefix for overlay');
      return;
    }

    final clipDurationInSeconds = _videoSplitterService.getDurationInSeconds(
      duration,
      _selectedUnit,
    );

    try {
      await _videoSplitterService.splitVideo(
        videoPath: _selectedVideoPath!,
        clipDurationInSeconds: clipDurationInSeconds,
        useWatermark: _useWatermark,
        watermarkPath: _selectedWatermarkPath,
        watermarkOpacity: _watermarkOpacity,
        watermarkPosition: _watermarkPosition,
        useTextOverlay: _useTextOverlay,
        textPrefix: _textPrefix,
        textPosition: _textPosition,
        fontSize: _fontSize,
        textColor: _textColor.value
            .toRadixString(16)
            .substring(2), // Convert Color to hex
        isPortraitMode: _isPortraitMode,
      );

      // After successful completion, call the success dialog
      if (!_isProcessing && _statusText.toLowerCase().contains('completed')) {
        _showSuccessDialog();
      }
    } catch (e) {
      _showError('Error splitting video: $e');
    }
  }
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(child: Text(message, style: TextStyle(fontSize: 14.sp))),
          ],
        ),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.r),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundColor, Color(0xFFF0F4F8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildVideoSelection(),
                      SizedBox(height: 24.h),
                      _buildDurationInput(),
                      SizedBox(height: 24.h),
                      _buildWatermarkSection(),
                      // SizedBox(height: 24.h),
                      // _buildTextOverlaySection(),
                      SizedBox(height: 32.h),

                      _buildNavigationSection(),
                      SizedBox(height: 24.h),
                      if (_isProcessing) _buildProgressSection(),
                      SizedBox(height: 7.h),
                      if (_statusText.isNotEmpty) _buildStatusSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo with scissors animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.content_cut,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto Clipper',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Professional Video Clipper',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 2 * 3.14159,
                  child: Icon(
                    Icons.autorenew,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVideoSelection() {
    return Container(
      decoration: BoxDecoration(
        gradient:
            _selectedVideoPath != null
                ? AppColors.secondaryGradient
                : LinearGradient(colors: [Colors.white, Colors.grey.shade50]),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessing ? null : _pickVideo,
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              children: [
                // Thumbnail or default icon
                if (_videoThumbnail != null) ...[
                  Container(
                    width: 200.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Image.memory(
                            _videoThumbnail!,
                            width: 200.w,
                            height: 120.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Watermark preview overlay
                        if (_useWatermark && _selectedWatermarkPath != null)
                          Positioned(
                            top: _getWatermarkPreviewPosition().dy,
                            left: _getWatermarkPreviewPosition().dx,
                            child: Container(
                              width: 30.w,
                              height: 30.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                  _watermarkOpacity,
                                ),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Icon(
                                Icons.image,
                                size: 16.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        // Text overlay preview
                        if (_useTextOverlay)
                          Positioned(
                            top: _getTextPreviewPosition().dy,
                            left: _getTextPreviewPosition().dx,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                '${_textPrefix} 1',
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        // Portrait/Landscape mode indicator
                        Positioned(
                          bottom: 8.h,
                          right: 8.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _isPortraitMode
                                      ? AppColors.primaryPink
                                      : AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              _isPortraitMode ? 'Portrait' : 'Landscape',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Orientation toggle buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildOrientationButton(
                        icon: Icons.stay_current_portrait,
                        label: 'Portrait',
                        isSelected: _isPortraitMode,
                        onTap: () => setState(() => _isPortraitMode = true),
                      ),
                      SizedBox(width: 12.w),
                      _buildOrientationButton(
                        icon: Icons.stay_current_landscape,
                        label: 'Landscape',
                        isSelected: !_isPortraitMode,
                        onTap: () => setState(() => _isPortraitMode = false),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGradient.colors.first.withOpacity(
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(40.r),
                    ),
                    child: Icon(
                      Icons.video_file,
                      size: 40.sp,
                      color: AppColors.primaryGradient.colors.first,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                Text(
                  _selectedVideoPath == null
                      ? 'Select Video File'
                      : 'Video Selected',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color:
                        _selectedVideoPath != null
                            ? Colors.white
                            : AppColors.textPrimary,
                  ),
                ),
                if (_selectedVideoPath != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    path.basename(_selectedVideoPath!),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  SizedBox(height: 8.h),
                  Text(
                    'Tap to browse and select your video',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Offset _getWatermarkPreviewPosition() {
    switch (_watermarkPosition) {
      case WatermarkPosition.topLeft:
        return Offset(8.w, 8.h);
      case WatermarkPosition.topRight:
        return Offset(160.w, 8.h);
      case WatermarkPosition.bottomLeft:
        return Offset(8.w, 80.h);
      case WatermarkPosition.bottomRight:
        return Offset(160.w, 80.h);
    }
  }

  Offset _getTextPreviewPosition() {
    switch (_textPosition) {
      case TextPosition.topCenter:
        return Offset(85.w, 8.h);
      case TextPosition.topLeft:
        return Offset(8.w, 8.h);
      case TextPosition.topRight:
        return Offset(140.w, 8.h);
      case TextPosition.bottomCenter:
        return Offset(85.w, 90.h);
      case TextPosition.bottomLeft:
        return Offset(8.w, 90.h);
      case TextPosition.bottomRight:
        return Offset(140.w, 90.h);
    }
  }

  Widget _buildOrientationButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color:
                isSelected ? Colors.transparent : Colors.white.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16.sp),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDurationInput() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.timer, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                'Clip Duration',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _durationController,
                    enabled: !_isProcessing,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(fontSize: 16.sp),
                    decoration: InputDecoration(
                      hintText: 'e.g., 30, 1.5, 2',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: DropdownButtonFormField<DurationUnit>(
                    value: _selectedUnit,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: DurationUnit.seconds,
                        child: Text('Seconds'),
                      ),
                      DropdownMenuItem(
                        value: DurationUnit.minutes,
                        child: Text('Minutes'),
                      ),
                      DropdownMenuItem(
                        value: DurationUnit.hours,
                        child: Text('Hours'),
                      ),
                    ],
                    onChanged:
                        _isProcessing
                            ? null
                            : (value) {
                              setState(() {
                                _selectedUnit = value!;
                              });
                            },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatermarkSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30.r,
            offset: Offset(0, 10.h),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.all(28.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPink,
                          AppColors.primaryPink.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPink.withOpacity(0.3),
                          blurRadius: 12.r,
                          offset: Offset(0, 6.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.layers_rounded,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Watermark Settings',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Customize your watermark appearance',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Animated Toggle Switch
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: GestureDetector(
                      onTap:
                          _isProcessing
                              ? null
                              : () {
                                setState(() {
                                  _useWatermark = !_useWatermark;
                                });
                              },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: 60.w,
                        height: 32.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          gradient: LinearGradient(
                            colors:
                                _useWatermark
                                    ? [
                                      AppColors.primaryPink,
                                      AppColors.primaryPink.withOpacity(0.8),
                                    ]
                                    : [
                                      Colors.grey.shade300,
                                      Colors.grey.shade400,
                                    ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_useWatermark
                                      ? AppColors.primaryPink
                                      : Colors.grey)
                                  .withOpacity(0.3),
                              blurRadius: 8.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: AnimatedAlign(
                          duration: Duration(milliseconds: 300),
                          alignment:
                              _useWatermark
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            width: 26.w,
                            height: 26.h,
                            margin: EdgeInsets.all(3.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              _useWatermark ? Icons.check : Icons.close,
                              size: 14.sp,
                              color:
                                  _useWatermark
                                      ? AppColors.primaryPink
                                      : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Expandable Content
              AnimatedSize(
                duration: Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                child:
                    _useWatermark
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 32.h),

                            // Watermark File Selection
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color:
                                      _selectedWatermarkPath != null
                                          ? AppColors.primaryPink
                                          : Colors.grey.shade300,
                                  width: 2.w,
                                ),
                                gradient:
                                    _selectedWatermarkPath != null
                                        ? LinearGradient(
                                          colors: [
                                            AppColors.primaryPink.withOpacity(
                                              0.05,
                                            ),
                                            AppColors.primaryPink.withOpacity(
                                              0.02,
                                            ),
                                          ],
                                        )
                                        : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isProcessing ? null : _pickWatermark,
                                  borderRadius: BorderRadius.circular(20.r),
                                  child: Container(
                                    padding: EdgeInsets.all(20.r),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: Duration(milliseconds: 300),
                                          padding: EdgeInsets.all(12.r),
                                          decoration: BoxDecoration(
                                            color:
                                                _selectedWatermarkPath != null
                                                    ? AppColors.primaryPink
                                                        .withOpacity(0.1)
                                                    : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                          child: Icon(
                                            _selectedWatermarkPath != null
                                                ? Icons.check_circle_rounded
                                                : Icons
                                                    .add_photo_alternate_rounded,
                                            color:
                                                _selectedWatermarkPath != null
                                                    ? AppColors.primaryPink
                                                    : Colors.grey.shade600,
                                            size: 28.sp,
                                          ),
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _selectedWatermarkPath == null
                                                    ? 'Select Watermark Image'
                                                    : 'Watermark Selected',
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      _selectedWatermarkPath !=
                                                              null
                                                          ? AppColors
                                                              .primaryPink
                                                          : AppColors
                                                              .textPrimary,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                _selectedWatermarkPath == null
                                                    ? 'JPG, PNG formats supported'
                                                    : 'Ready to apply watermark',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (_selectedWatermarkPath != null)
                                          Container(
                                            padding: EdgeInsets.all(8.r),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryPink
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                            ),
                                            child: Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14.sp,
                                              color: AppColors.primaryPink,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 32.h),

                            // Opacity Section with Progress Bar
                            Container(
                              padding: EdgeInsets.all(24.r),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.grey.shade50, Colors.white],
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1.w,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.opacity_rounded,
                                            color: AppColors.primaryPink,
                                            size: 20.sp,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Opacity',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primaryPink,
                                              AppColors.primaryPink.withOpacity(
                                                0.8,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryPink
                                                  .withOpacity(0.3),
                                              blurRadius: 8.r,
                                              offset: Offset(0, 4.h),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '${(_watermarkOpacity * 100).round()}%',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20.h),

                                  // Custom Progress Bar with Percent Indicator
                                  LinearPercentIndicator(
                                    width: 170.sp,
                                    // MediaQuery.of(context).size.width -
                                    // 120.w,
                                    animation: true,
                                    animationDuration: 300,
                                    lineHeight: 12.h,
                                    percent: _watermarkOpacity,
                                    center: Container(),
                                    linearStrokeCap: LinearStrokeCap.roundAll,
                                    progressColor: AppColors.primaryPink,
                                    backgroundColor: Colors.grey.shade200,
                                    barRadius: Radius.circular(6.r),
                                    leading: Container(
                                      padding: EdgeInsets.all(6.r),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      child: Text(
                                        '',
                                        style: TextStyle(
                                          fontSize: 1.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: EdgeInsets.all(6.r),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPink
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      child: Text(
                                        '100%',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primaryPink,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 16.h),

                                  // Custom Slider
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4.h,
                                      thumbShape: CustomSliderThumbShape(
                                        enabledThumbRadius: 12.r,
                                        elevation: 4,
                                      ),
                                      overlayShape: RoundSliderOverlayShape(
                                        overlayRadius: 20.r,
                                      ),
                                      activeTrackColor: AppColors.primaryPink,
                                      //   inactiveTrackColor: Colors.grey.shade300,
                                      thumbColor: Colors.white,
                                      overlayColor: AppColors.primaryPink
                                          .withOpacity(0.2),
                                    ),
                                    child: Slider(
                                      value: _watermarkOpacity,
                                      min: 0.1,
                                      max: 1.0,
                                      divisions: 9,
                                      onChanged:
                                          _isProcessing
                                              ? null
                                              : (value) {
                                                setState(() {
                                                  _watermarkOpacity = value;
                                                });
                                              },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24.h),

                            // Position Selection
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.photo_size_select_actual_rounded,
                                      color: AppColors.primaryPink,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Position',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1.w,
                                    ),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.grey.shade50,
                                      ],
                                    ),
                                  ),
                                  child: DropdownButtonFormField<
                                    WatermarkPosition
                                  >(
                                    value: _watermarkPosition,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 16.h,
                                      ),
                                      suffixIcon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.primaryPink,
                                        size: 24.sp,
                                      ),
                                    ),
                                    dropdownColor: Colors.white,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: WatermarkPosition.topLeft,
                                        child: Row(
                                          children: [
                                            Icon(Icons.north_west, size: 16),
                                            SizedBox(width: 8),
                                            Text('Top Left'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: WatermarkPosition.topRight,
                                        child: Row(
                                          children: [
                                            Icon(Icons.north_east, size: 16),
                                            SizedBox(width: 8),
                                            Text('Top Right'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: WatermarkPosition.bottomLeft,
                                        child: Row(
                                          children: [
                                            Icon(Icons.south_west, size: 16),
                                            SizedBox(width: 8),
                                            Text('Bottom Left'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: WatermarkPosition.bottomRight,
                                        child: Row(
                                          children: [
                                            Icon(Icons.south_east, size: 16),
                                            SizedBox(width: 8),
                                            Text('Bottom Right'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged:
                                        _isProcessing
                                            ? null
                                            : (value) {
                                              setState(() {
                                                _watermarkPosition = value!;
                                              });
                                            },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                        : SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildSplitButton() {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        gradient:
            _isProcessing
                ? LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                )
                : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          if (!_isProcessing)
            BoxShadow(
              color: AppColors.primaryPink.withOpacity(0.3),
              blurRadius: 20.r,
              offset: Offset(0, 8.h),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessing ? null : _startSplitting,
          borderRadius: BorderRadius.circular(30.r),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isProcessing)
                  SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    Icons.content_cut_rounded,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                SizedBox(width: 12.w),
                Text(
                  _isProcessing ? 'Processing...' : 'Split Video',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildNavigationSection() {
    return Container(
      padding: EdgeInsets.all(16.r),
      child: _buildSplitButton(), // Only split button now
    );
  }

  // Enhanced Progress Section
 Widget _buildProgressSection() {
    return Container(
      padding: EdgeInsets.all(24.r),
      margin: EdgeInsets.symmetric(horizontal: 4.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.primaryPink.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 25.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.2),
                      blurRadius: 8.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome,
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
                      'Processing Video',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Creating amazing clips for you...',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.2),
                      blurRadius: 8.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Text(
                  '${(_progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Progress Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Clip $_currentClip of $_totalClips',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Replaced circular progress with linear progress
              Row(
                children: [
                  Container(
                    width: 60.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progress,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Enhanced Main Progress Bar (Left to Right)
          Container(
            height: 12.h, // Made slightly taller for better visibility
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Stack(
              children: [
                // Background track
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                // Progress fill (left to right)
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(6.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPink.withOpacity(0.4),
                          blurRadius: 6.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    // Optional: Add animated shimmer effect
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.r),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: [0.0, 0.5, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final isSuccess = !_isProcessing && _statusText.contains('completed');
    final isError = _statusText.toLowerCase().contains('error');

    return Container(
      padding: EdgeInsets.all(20.r),
      margin: EdgeInsets.symmetric(horizontal: 4.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color:
              isError
                  ? AppColors.errorColor.withOpacity(0.3)
                  : isSuccess
                  ? AppColors.successColor.withOpacity(0.3)
                  : AppColors.infoColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color:
                  isError
                      ? AppColors.errorColor.withOpacity(0.1)
                      : isSuccess
                      ? AppColors.successColor.withOpacity(0.1)
                      : AppColors.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isError
                  ? Icons.error_outline_rounded
                  : isSuccess
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              color:
                  isError
                      ? AppColors.errorColor
                      : isSuccess
                      ? AppColors.successColor
                      : AppColors.infoColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isError
                      ? 'Processing Failed'
                      : isSuccess
                      ? 'Success!'
                      : 'Status Update',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color:
                        isError
                            ? AppColors.errorColor
                            : isSuccess
                            ? AppColors.successColor
                            : AppColors.infoColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (isSuccess)
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.celebration_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
        ],
      ),
    );
  }

  // Success Dialog Method
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Animation Container
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 20.r,
                        offset: Offset(0, 8.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 40.sp,
                  ),
                ),
                SizedBox(height: 24.h),

                // Success Title
                Text(
                  'Video Split Successfully!',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),

                // Success Message
                Text(
                  'Your video has been split into $_totalClips clips and saved successfully.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),

                // Action Buttons
                Row(
                  children: [
                    // Download Button
                    Expanded(
                      child: Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(25.r),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF667EEA).withOpacity(0.3),
                              blurRadius: 15.r,
                              offset: Offset(0, 6.h),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop(); // Close dialog
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoDownloadScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(25.r),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.download_rounded,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Downloads',
                                    style: TextStyle(
                                      fontSize: 16.sp,
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
                    ),
                    SizedBox(width: 12.w),

                    // OK Button
                    Expanded(
                      child: Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primaryPink.withOpacity(0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop(); // Close dialog
                            },
                            borderRadius: BorderRadius.circular(25.r),
                            child: Center(
                              child: Text(
                                'OK',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    _textController.dispose(); // Add this line
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}








// text overlaping function    


  // Widget _buildTextOverlaySection() {
  //   return Container(
  //     padding: EdgeInsets.all(24.r),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(20.r),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppColors.shadowLight,
  //           blurRadius: 20.r,
  //           offset: Offset(0, 8.h),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               padding: EdgeInsets.all(8.r),
  //               decoration: BoxDecoration(
  //                 gradient: AppColors.accentGradient,
  //                 borderRadius: BorderRadius.circular(8.r),
  //               ),
  //               child: Icon(
  //                 Icons.text_fields,
  //                 color: Colors.white,
  //                 size: 20.sp,
  //               ),
  //             ),
  //             SizedBox(width: 12.w),
  //             Expanded(
  //               child: Text(
  //                 'Text Overlay',
  //                 style: TextStyle(
  //                   fontSize: 18.sp,
  //                   fontWeight: FontWeight.bold,
  //                   color: AppColors.textPrimary,
  //                 ),
  //               ),
  //             ),
  //             Switch(
  //               value: _useTextOverlay,
  //               onChanged:
  //                   _isProcessing
  //                       ? null
  //                       : (value) {
  //                         setState(() {
  //                           _useTextOverlay = value;
  //                         });
  //                       },
  //               activeColor: AppColors.primaryPink,
  //             ),
  //           ],
  //         ),
  //         if (_useTextOverlay) ...[
  //           SizedBox(height: 20.h),
  //           // Text prefix input
  //           TextField(
  //             controller: _textController,
  //             enabled: !_isProcessing,
  //             decoration: InputDecoration(
  //               labelText: 'Text Prefix (e.g., Part, Clip)',
  //               hintText: 'Part',
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(12.r),
  //               ),
  //               contentPadding: EdgeInsets.all(16.r),
  //             ),
  //             onChanged: (value) {
  //               setState(() {
  //                 _textPrefix = value.isEmpty ? 'Part' : value;
  //               });
  //             },
  //           ),
  //           SizedBox(height: 16.h),
  //           // Text position dropdown
  //           DropdownButtonFormField<TextPosition>(
  //             value: _textPosition,
  //             decoration: InputDecoration(
  //               labelText: 'Text Position',
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(12.r),
  //               ),
  //               contentPadding: EdgeInsets.all(16.r),
  //             ),
  //             items: [
  //               DropdownMenuItem(
  //                 value: TextPosition.topCenter,
  //                 child: Text('Top Center'),
  //               ),
  //               DropdownMenuItem(
  //                 value: TextPosition.topLeft,
  //                 child: Text('Top Left'),
  //               ),
  //               DropdownMenuItem(
  //                 value: TextPosition.topRight,
  //                 child: Text('Top Right'),
  //               ),
  //               DropdownMenuItem(
  //                 value: TextPosition.bottomCenter,
  //                 child: Text('Bottom Center'),
  //               ),
  //               DropdownMenuItem(
  //                 value: TextPosition.bottomLeft,
  //                 child: Text('Bottom Left'),
  //               ),
  //               DropdownMenuItem(
  //                 value: TextPosition.bottomRight,
  //                 child: Text('Bottom Right'),
  //               ),
  //             ],
  //             onChanged:
  //                 _isProcessing
  //                     ? null
  //                     : (value) {
  //                       setState(() {
  //                         _textPosition = value!;
  //                       });
  //                     },
  //           ),
  //           SizedBox(height: 16.h),
  //           // Font size slider
  //           Row(
  //             children: [
  //               Text('Font Size: ${_fontSize.round()}px'),
  //               Expanded(
  //                 child: Slider(
  //                   value: _fontSize,
  //                   min: 16.0,
  //                   max: 48.0,
  //                   divisions: 16,
  //                   onChanged:
  //                       _isProcessing
  //                           ? null
  //                           : (value) {
  //                             setState(() {
  //                               _fontSize = value;
  //                             });
  //                           },
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }