// video_splitter_screen.dart
// ignore_for_file: avoid_print, depend_on_referenced_packages, deprecated_member_use

import 'dart:typed_data';

import 'package:auto_clipper_app/Constant/Colors.dart';
import 'package:auto_clipper_app/Logic/Split_Controller.dart';
import 'package:auto_clipper_app/Screens/video_download_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import 'package:video_thumbnail/video_thumbnail.dart';

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

  Widget _buildTextOverlaySection() {
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
                child: Icon(
                  Icons.text_fields,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Text Overlay',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: _useTextOverlay,
                onChanged:
                    _isProcessing
                        ? null
                        : (value) {
                          setState(() {
                            _useTextOverlay = value;
                          });
                        },
                activeColor: AppColors.primaryPink,
              ),
            ],
          ),
          if (_useTextOverlay) ...[
            SizedBox(height: 20.h),
            // Text prefix input
            TextField(
              controller: _textController,
              enabled: !_isProcessing,
              decoration: InputDecoration(
                labelText: 'Text Prefix (e.g., Part, Clip)',
                hintText: 'Part',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding: EdgeInsets.all(16.r),
              ),
              onChanged: (value) {
                setState(() {
                  _textPrefix = value.isEmpty ? 'Part' : value;
                });
              },
            ),
            SizedBox(height: 16.h),
            // Text position dropdown
            DropdownButtonFormField<TextPosition>(
              value: _textPosition,
              decoration: InputDecoration(
                labelText: 'Text Position',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding: EdgeInsets.all(16.r),
              ),
              items: [
                DropdownMenuItem(
                  value: TextPosition.topCenter,
                  child: Text('Top Center'),
                ),
                DropdownMenuItem(
                  value: TextPosition.topLeft,
                  child: Text('Top Left'),
                ),
                DropdownMenuItem(
                  value: TextPosition.topRight,
                  child: Text('Top Right'),
                ),
                DropdownMenuItem(
                  value: TextPosition.bottomCenter,
                  child: Text('Bottom Center'),
                ),
                DropdownMenuItem(
                  value: TextPosition.bottomLeft,
                  child: Text('Bottom Left'),
                ),
                DropdownMenuItem(
                  value: TextPosition.bottomRight,
                  child: Text('Bottom Right'),
                ),
              ],
              onChanged:
                  _isProcessing
                      ? null
                      : (value) {
                        setState(() {
                          _textPosition = value!;
                        });
                      },
            ),
            SizedBox(height: 16.h),
            // Font size slider
            Row(
              children: [
                Text('Font Size: ${_fontSize.round()}px'),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 16.0,
                    max: 48.0,
                    divisions: 16,
                    onChanged:
                        _isProcessing
                            ? null
                            : (value) {
                              setState(() {
                                _fontSize = value;
                              });
                            },
                  ),
                ),
              ],
            ),
          ],
        ],
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
                child: Icon(Icons.image, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Watermark Settings',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: _useWatermark,
                onChanged:
                    _isProcessing
                        ? null
                        : (value) {
                          setState(() {
                            _useWatermark = value;
                          });
                        },
                activeColor: AppColors.primaryPink,
              ),
            ],
          ),
          if (_useWatermark) ...[
            SizedBox(height: 20.h),
            // Watermark file selection
            GestureDetector(
              onTap: _isProcessing ? null : _pickWatermark,
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        _selectedWatermarkPath != null
                            ? AppColors.primaryPink
                            : AppColors.borderLight,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  color:
                      _selectedWatermarkPath != null
                          ? AppColors.primaryPink.withOpacity(0.05)
                          : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedWatermarkPath != null
                          ? Icons.check_circle
                          : Icons.add_photo_alternate,
                      color:
                          _selectedWatermarkPath != null
                              ? AppColors.primaryPink
                              : AppColors.textSecondary,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        _selectedWatermarkPath == null
                            ? 'Select Watermark (JPG/PNG)'
                            : 'Watermark Selected',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color:
                              _selectedWatermarkPath != null
                                  ? AppColors.primaryPink
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
            // Opacity slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Opacity',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(12.r),
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
                SizedBox(height: 8.h),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6.h,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.r),
                  ),
                  child: Slider(
                    value: _watermarkOpacity,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    activeColor: AppColors.primaryPink,
                    inactiveColor: AppColors.borderLight,
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
            SizedBox(height: 16.h),
            // Position dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Position',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: DropdownButtonFormField<WatermarkPosition>(
                    value: _watermarkPosition,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: WatermarkPosition.topLeft,
                        child: Text('Top Left'),
                      ),
                      DropdownMenuItem(
                        value: WatermarkPosition.topRight,
                        child: Text('Top Right'),
                      ),
                      DropdownMenuItem(
                        value: WatermarkPosition.bottomLeft,
                        child: Text('Bottom Left'),
                      ),
                      DropdownMenuItem(
                        value: WatermarkPosition.bottomRight,
                        child: Text('Bottom Right'),
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
        ],
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
                  Icon(Icons.content_cut, color: Colors.white, size: 24.sp),
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
      child: Row(
        children: [
          Expanded(
            child: _buildSplitButton(), // Your existing split button
          ),
          SizedBox(width: 12.w),
          Container(
            height: 60.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 20.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoDownloadScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(30.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download, color: Colors.white, size: 24.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Downloads',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // // Add this method to show success dialog after processing
  // void _showProcessingComplete() {
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder:
  //           (context) => AlertDialog(
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(16.r),
  //             ),
  //             title: Row(
  //               children: [
  //                 Container(
  //                   padding: EdgeInsets.all(8.r),
  //                   decoration: BoxDecoration(
  //                     color: Colors.green.shade100,
  //                     shape: BoxShape.circle,
  //                   ),
  //                   child: Icon(
  //                     Icons.check_circle,
  //                     color: Colors.green,
  //                     size: 24.sp,
  //                   ),
  //                 ),
  //                 SizedBox(width: 12.w),
  //                 Text(
  //                   'Processing Complete!',
  //                   style: TextStyle(
  //                     fontSize: 18.sp,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Your video has been successfully split into clips.',
  //                   style: TextStyle(
  //                     fontSize: 14.sp,
  //                     color: Colors.grey.shade700,
  //                   ),
  //                 ),
  //                 SizedBox(height: 12.h),
  //                 Container(
  //                   padding: EdgeInsets.all(12.r),
  //                   decoration: BoxDecoration(
  //                     color: Colors.blue.shade50,
  //                     borderRadius: BorderRadius.circular(8.r),
  //                     border: Border.all(color: Colors.blue.shade200),
  //                   ),
  //                   child: Row(
  //                     children: [
  //                       Icon(
  //                         Icons.info_outline,
  //                         color: Colors.blue.shade600,
  //                         size: 20.sp,
  //                       ),
  //                       SizedBox(width: 8.w),
  //                       Expanded(
  //                         child: Text(
  //                           'Videos are ready to download in the Downloads section.',
  //                           style: TextStyle(
  //                             fontSize: 13.sp,
  //                             color: Colors.blue.shade700,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: Text(
  //                   'OK',
  //                   style: TextStyle(
  //                     color: Colors.grey.shade600,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //               ),
  //               ElevatedButton(
  //                 onPressed: () {
  //                   Navigator.pop(context);
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => VideoDownloadScreen(),
  //                     ),
  //                   );
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.blue,
  //                   foregroundColor: Colors.white,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(8.r),
  //                   ),
  //                   padding: EdgeInsets.symmetric(
  //                     horizontal: 16.w,
  //                     vertical: 8.h,
  //                   ),
  //                 ),
  //                 child: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Icon(Icons.download, size: 18.sp),
  //                     SizedBox(width: 6.w),
  //                     Text(
  //                       'View Downloads',
  //                       style: TextStyle(fontWeight: FontWeight.w600),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //     );
  //   }

  Widget _buildProgressSection() {
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
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.schedule, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Processing Progress',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(20.r),
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
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clip $_currentClip of $_totalClips',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Processing...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.primaryPink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            height: 8.h,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
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
            blurRadius: 15.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color:
                  isError
                      ? AppColors.errorColor.withOpacity(0.1)
                      : isSuccess
                      ? AppColors.successColor.withOpacity(0.1)
                      : AppColors.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              isError
                  ? Icons.error_outline
                  : isSuccess
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
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
                      ? 'Error'
                      : isSuccess
                      ? 'Success'
                      : 'Status',
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
                  ),
                ),
              ],
            ),
          ),
          if (isSuccess)
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.folder_open, color: Colors.white, size: 20.sp),
            ),
        ],
      ),
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
