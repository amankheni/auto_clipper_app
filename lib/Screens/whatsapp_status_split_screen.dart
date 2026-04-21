// ignore_for_file: avoid_print, deprecated_member_use, use_build_context_synchronously, file_names

import 'dart:io';
import 'dart:typed_data';

import 'package:auto_clipper_app/Logic/Split_Controller.dart';
import 'package:auto_clipper_app/Logic/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// WhatsApp Status Split Mode
/// - Splits video into 30-second clips (WhatsApp Status max duration)
/// - Outputs 9:16 portrait format (1080×1920) for full-screen status
/// - Adds black padding bars if video is landscape
/// - Shows clip count preview before processing
class WhatsAppStatusSplitScreen extends StatefulWidget {
  const WhatsAppStatusSplitScreen({super.key});

  @override
  State<WhatsAppStatusSplitScreen> createState() =>
      _WhatsAppStatusSplitScreenState();
}

class _WhatsAppStatusSplitScreenState extends State<WhatsAppStatusSplitScreen>
    with TickerProviderStateMixin {
  late VideoSplitterService _splitterService;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  String? _selectedVideoPath;
  Uint8List? _thumbnail;
  double _videoDuration = 0;
  int _estimatedClips = 0;
  bool _isProcessing = false;
  bool _isPickingVideo = false;
  double _progress = 0.0;
  int _currentClip = 0;
  int _totalClips = 0;
  String _statusText = '';
  bool _isDone = false;
  String _outputSessionPath = '';

  // WhatsApp Status fixed config
  static const int _statusDuration = 30; // seconds per clip
  static const int _outputWidth = 1080;
  static const int _outputHeight = 1920;

  @override
  void initState() {
    super.initState();
    _splitterService = VideoSplitterService(onProgressUpdate: _onProgress);
    _splitterService.requestPermissions();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
  }

  void _onProgress(VideoSplitterProgress p) {
    setState(() {
      _currentClip = p.currentClip;
      _totalClips = p.totalClips;
      _progress = p.progress;
      _statusText = p.statusText;
      _isProcessing = p.isProcessing;
      if (!p.isProcessing && p.progress >= 1.0 && p.totalClips > 0) {
        _isDone = true;
      }
    });
  }

  Future<void> _pickVideo() async {
    if (_isPickingVideo) return;
    setState(() => _isPickingVideo = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final videoPath = result.files.single.path!;
        setState(() {
          _selectedVideoPath = videoPath;
          _thumbnail = null;
          _videoDuration = 0;
          _estimatedClips = 0;
          _isDone = false;
          _outputSessionPath = '';
        });
        await _loadVideoInfo(videoPath);
      }
    } catch (e) {
      _showSnack('Error picking video: $e');
    } finally {
      setState(() => _isPickingVideo = false);
    }
  }

  Future<void> _loadVideoInfo(String videoPath) async {
    try {
      // Generate thumbnail
      final thumb = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 80,
      );
      final duration = await _splitterService.getVideoDuration(videoPath);
      final clips = (duration / _statusDuration).ceil();
      setState(() {
        _thumbnail = thumb;
        _videoDuration = duration;
        _estimatedClips = clips;
      });
    } catch (e) {
      print('Error loading video info: $e');
    }
  }

  Future<void> _startProcessing() async {
    if (_selectedVideoPath == null || _isProcessing) return;
    setState(() {
      _isProcessing = true;
      _isDone = false;
      _progress = 0;
      _currentClip = 0;
      _totalClips = 0;
      _statusText = 'Preparing WhatsApp Status clips...';
    });

    AdService.showAdThenAction(
      onActionComplete: () async {
        try {
          // Create output session directory
          final appDir = await getApplicationDocumentsDirectory();
          final videosDir = Directory('${appDir.path}/processed_videos');
          if (!await videosDir.exists())
            await videosDir.create(recursive: true);
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final sessionDir = Directory('${videosDir.path}/session_$timestamp');
          await sessionDir.create(recursive: true);
          _outputSessionPath = sessionDir.path;

          final totalClips = _estimatedClips;

          for (int i = 0; i < totalClips; i++) {
            final startTime = i * _statusDuration;
            final outputPath = '${sessionDir.path}/status_${i + 1}.mp4';

            _onProgress(
              VideoSplitterProgress(
                currentClip: i + 1,
                totalClips: totalClips,
                progress: i / totalClips,
                statusText: 'Creating Status clip ${i + 1} of $totalClips...',
                isProcessing: true,
              ),
            );

            // Use FFmpeg to crop/pad to 9:16 portrait and trim to 30s
            await _splitterService.splitVideoClipWithOverlays(
              _selectedVideoPath!,
              outputPath,
              startTime,
              _statusDuration,
              isPortraitMode: true,
            );

            _onProgress(
              VideoSplitterProgress(
                currentClip: i + 1,
                totalClips: totalClips,
                progress: (i + 1) / totalClips,
                statusText: 'Status clip ${i + 1} ready ✓',
                isProcessing: true,
              ),
            );
          }

          _onProgress(
            VideoSplitterProgress(
              currentClip: totalClips,
              totalClips: totalClips,
              progress: 1.0,
              statusText:
                  '🎉 $totalClips WhatsApp Status clips ready! Check Downloads.',
              isProcessing: false,
            ),
          );
        } catch (e) {
          _onProgress(
            VideoSplitterProgress(
              currentClip: 0,
              totalClips: 0,
              progress: 0,
              statusText: 'Error: $e',
              isProcessing: false,
            ),
          );
          _showSnack('Processing failed: $e');
        }
      },
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF25D366),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                color: const Color(0xFF25D366),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Splitter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '30s clips • 9:16 Portrait',
                  style: TextStyle(
                    color: const Color(0xFF25D366),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              _buildInfoBanner(),
              SizedBox(height: 20.h),
              AdService.nativeWidget(
                adId: 'whatsapp_native_preview',
                context: context,
                showLabel: false,
                isLarge: false,
                margin: EdgeInsets.zero,
              ),
              SizedBox(height: 20.h),
              // Video Picker
              _buildVideoPicker(),
              SizedBox(height: 20.h),

              // Video Info + Clip Preview
              if (_selectedVideoPath != null) ...[
                _buildVideoPreview(),
                SizedBox(height: 20.h),
                // ✅ SPOT 1 — Preview પછી, always visible

              ],

              // Processing State
              if (_isProcessing) ...[
                _buildProgressCard(),
                SizedBox(height: 20.h),
              ],

              // Done State
              if (_isDone) ...[_buildDoneCard(), SizedBox(height: 20.h)],

              // Start Button
              if (!_isProcessing && !_isDone && _selectedVideoPath != null)
                _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF25D366).withOpacity(0.15),
            const Color(0xFF128C7E).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF25D366).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _infoRow(
            Icons.timer_outlined,
            'Auto 30s clips',
            'WhatsApp Status max duration',
          ),
          SizedBox(height: 10.h),
          _infoRow(
            Icons.crop_portrait,
            '9:16 Portrait format',
            'Perfect full-screen display',
          ),
          SizedBox(height: 10.h),
          _infoRow(
            Icons.auto_fix_high,
            'Smart padding',
            'Black bars added for landscape videos',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF25D366), size: 18.sp),
        SizedBox(width: 10.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white54, fontSize: 11.sp),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoPicker() {
    return GestureDetector(
      onTap: _isProcessing ? null : _pickVideo,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder:
            (ctx, _) => Transform.scale(
              scale: _selectedVideoPath == null ? _pulseAnimation.value : 1.0,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(28.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        _selectedVideoPath != null
                            ? [const Color(0xFF1E2A1F), const Color(0xFF0D1F12)]
                            : [
                              const Color(0xFF1A2535),
                              const Color(0xFF0D1625),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color:
                        _selectedVideoPath != null
                            ? const Color(0xFF25D366).withOpacity(0.5)
                            : Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _selectedVideoPath != null
                            ? Icons.check_circle_outline
                            : Icons.video_library_outlined,
                        color: const Color(0xFF25D366),
                        size: 32.sp,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      _isPickingVideo
                          ? 'Selecting...'
                          : _selectedVideoPath != null
                          ? path.basename(_selectedVideoPath!)
                          : 'Tap to Select Video',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _selectedVideoPath != null
                          ? 'Tap to change video'
                          : 'MP4, MOV, AVI supported',
                      style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child:
                _thumbnail != null
                    ? Image.memory(
                      _thumbnail!,
                      width: 80.w,
                      height: 80.w,
                      fit: BoxFit.cover,
                    )
                    : Container(
                      width: 80.w,
                      height: 80.w,
                      color: Colors.white10,
                      child: Icon(
                        Icons.videocam,
                        color: Colors.white30,
                        size: 28.sp,
                      ),
                    ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statRow('Duration', _formatDuration(_videoDuration)),
                SizedBox(height: 8.h),
                _statRow('Clip Duration', '30 seconds'),
                SizedBox(height: 8.h),
                _statRow(
                  'Status Clips',
                  '$_estimatedClips clips',
                  highlight: true,
                ),
                SizedBox(height: 8.h),
                _statRow('Output Format', '9:16 • 1080×1920'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFF25D366) : Colors.white,
            fontSize: 12.sp,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF25D366)),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Processing...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$_currentClip / $_totalClips',
                style: TextStyle(
                  color: const Color(0xFF25D366),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF25D366)),
              minHeight: 8.h,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            _statusText,
            style: TextStyle(color: Colors.white54, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF25D366).withOpacity(0.15),
            const Color(0xFF128C7E).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF25D366).withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: const Color(0xFF25D366), size: 48.sp),
          SizedBox(height: 12.h),
          Text(
            '$_estimatedClips WhatsApp Status Clips Ready!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12.sp),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  'Process Another',
                  Icons.refresh,
                  const Color(0xFF374151),
                  () => setState(() {
                    _isDone = false;
                    _selectedVideoPath = null;
                    _thumbnail = null;
                    _videoDuration = 0;
                    _estimatedClips = 0;
                  }),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _actionButton(
                  'View Downloads',
                  Icons.download_done,
                  const Color(0xFF25D366),
                  () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16.sp),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _startProcessing,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF25D366), Color(0xFF128C7E)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25D366).withOpacity(0.4),
              blurRadius: 20.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22.sp),
            SizedBox(width: 10.w),
            Text(
              'Create $_estimatedClips Status Clips',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
