// ignore_for_file: avoid_print, deprecated_member_use, use_build_context_synchronously, file_names

import 'dart:io';
import 'dart:typed_data';

import 'package:auto_clipper_app/Logic/Split_Controller.dart';
import 'package:auto_clipper_app/Logic/ad_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

// ─── Platform Preset Model ───────────────────────────────────────────────────

class PlatformPreset {
  final String id;
  final String name;
  final String platform;
  final int maxDurationSeconds;
  final String aspectRatio; // display label
  final bool portrait; // 9:16
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final String tip;

  const PlatformPreset({
    required this.id,
    required this.name,
    required this.platform,
    required this.maxDurationSeconds,
    required this.aspectRatio,
    required this.portrait,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.tip,
  });
}

// ─── All platform presets ─────────────────────────────────────────────────────

final List<PlatformPreset> _kPresets = [
  PlatformPreset(
    id: 'reels_60',
    name: 'Reels',
    platform: 'Instagram',
    maxDurationSeconds: 60,
    aspectRatio: '9:16',
    portrait: true,
    primaryColor: const Color(0xFFE1306C),
    secondaryColor: const Color(0xFF833AB4),
    icon: Icons.camera_alt_outlined,
    tip: 'Best: 15–60s, vertical format for max reach',
  ),
  PlatformPreset(
    id: 'shorts_60',
    name: 'Shorts',
    platform: 'YouTube',
    maxDurationSeconds: 60,
    aspectRatio: '9:16',
    portrait: true,
    primaryColor: const Color(0xFFFF0000),
    secondaryColor: const Color(0xFFCC0000),
    icon: Icons.play_circle_outline,
    tip: 'Under 60s vertical videos get Shorts feed boost',
  ),
  PlatformPreset(
    id: 'tiktok_60',
    name: 'TikTok',
    platform: 'TikTok',
    maxDurationSeconds: 60,
    aspectRatio: '9:16',
    portrait: true,
    primaryColor: const Color(0xFF69C9D0),
    secondaryColor: const Color(0xFFEE1D52),
    icon: Icons.music_note_outlined,
    tip: '15–60s gets best algorithmic push',
  ),
  PlatformPreset(
    id: 'fb_reels',
    name: 'FB Reels',
    platform: 'Facebook',
    maxDurationSeconds: 90,
    aspectRatio: '9:16',
    portrait: true,
    primaryColor: const Color(0xFF1877F2),
    secondaryColor: const Color(0xFF0D6EFD),
    icon: Icons.thumb_up_outlined,
    tip: 'Up to 90s, vertical preferred',
  ),
  PlatformPreset(
    id: 'twitter_140',
    name: 'Twitter/X',
    platform: 'X (Twitter)',
    maxDurationSeconds: 140,
    aspectRatio: '16:9',
    portrait: false,
    primaryColor: const Color(0xFF1DA1F2),
    secondaryColor: const Color(0xFF0A85C7),
    icon: Icons.alternate_email,
    tip: 'Max 2m20s, landscape or portrait',
  ),
  PlatformPreset(
    id: 'snapchat_60',
    name: 'Snap Story',
    platform: 'Snapchat',
    maxDurationSeconds: 60,
    aspectRatio: '9:16',
    portrait: true,
    primaryColor: const Color(0xFFFFFC00),
    secondaryColor: const Color(0xFFFFD000),
    icon: Icons.wb_sunny_outlined,
    tip: 'Snapchat stories: up to 60s each',
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class ReelsShortsPresetScreen extends StatefulWidget {
  const ReelsShortsPresetScreen({super.key});

  @override
  State<ReelsShortsPresetScreen> createState() =>
      _ReelsShortsPresetScreenState();
}

class _ReelsShortsPresetScreenState extends State<ReelsShortsPresetScreen>
    with TickerProviderStateMixin {
  late VideoSplitterService _splitterService;
  late AnimationController _cardAnimController;
  late List<Animation<double>> _cardAnimations;

  PlatformPreset? _selectedPreset;
  String? _selectedVideoPath;
  Uint8List? _thumbnail;
  double _videoDuration = 0;
  int _estimatedClips = 0;

  bool _isPickingVideo = false;
  bool _isProcessing = false;
  double _progress = 0;
  int _currentClip = 0;
  int _totalClips = 0;
  String _statusText = '';
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _splitterService = VideoSplitterService(onProgressUpdate: _onProgress);
    _splitterService.requestPermissions();

    _cardAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardAnimations = List.generate(
      _kPresets.length,
      (i) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _cardAnimController,
          curve: Interval(i * 0.08, 0.6 + i * 0.08, curve: Curves.easeOutBack),
        ),
      ),
    );
    _cardAnimController.forward();
  }

  void _onProgress(VideoSplitterProgress p) {
    if (!mounted) return;
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
    if (_isPickingVideo || _selectedPreset == null) return;
    if (!mounted) return;
    setState(() => _isPickingVideo = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final vp = result.files.single.path!;
        if (!mounted) return;
        setState(() {
          _selectedVideoPath = vp;
          _thumbnail = null;
          _videoDuration = 0;
          _estimatedClips = 0;
          _isDone = false;
        });
        await _loadVideoInfo(vp);
      }
    } catch (e) {
      _showSnack('Error picking video: $e');
    } finally {
      setState(() => _isPickingVideo = false);
    }
  }

  Future<void> _loadVideoInfo(String vp) async {
    try {
      final thumb = await VideoThumbnail.thumbnailData(
        video: vp,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 80,
      );
      final dur = await _splitterService.getVideoDuration(vp);
      final clips = (dur / _selectedPreset!.maxDurationSeconds).ceil();
      if (!mounted) return;
      setState(() {
        _thumbnail = thumb;
        _videoDuration = dur;
        _estimatedClips = clips;
      });
    } catch (e) {
      print('Error loading video info: $e');
    }
  }

  Future<void> _startProcessing() async {
    if (_selectedVideoPath == null || _selectedPreset == null || _isProcessing)
      return;
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _isDone = false;
      _progress = 0;
      _currentClip = 0;
      _totalClips = 0;
      _statusText = 'Starting...';
    });

    AdService.showAdThenAction(
      onActionComplete: () async {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final videosDir = Directory('${appDir.path}/processed_videos');
          if (!await videosDir.exists())
            await videosDir.create(recursive: true);
          final ts = DateTime.now().millisecondsSinceEpoch;
          final sessionDir = Directory('${videosDir.path}/session_$ts');
          await sessionDir.create(recursive: true);

          final clipDur = _selectedPreset!.maxDurationSeconds;
          final total = _estimatedClips;

          for (int i = 0; i < total; i++) {
            final startTime = i * clipDur;
            final outputPath = '${sessionDir.path}/clip_${i + 1}.mp4';

            _onProgress(
              VideoSplitterProgress(
                currentClip: i + 1,
                totalClips: total,
                progress: i / total,
                statusText:
                    'Creating ${_selectedPreset!.name} clip ${i + 1} of $total...',
                isProcessing: true,
              ),
            );

            await _splitterService.splitVideoClipWithOverlays(
              _selectedVideoPath!,
              outputPath,
              startTime,
              clipDur,
              isPortraitMode: _selectedPreset!.portrait,
            );

            _onProgress(
              VideoSplitterProgress(
                currentClip: i + 1,
                totalClips: total,
                progress: (i + 1) / total,
                statusText: 'Clip ${i + 1} done ✓',
                isProcessing: i + 1 < total,
              ),
            );
          }

          _onProgress(
            VideoSplitterProgress(
              currentClip: total,
              totalClips: total,
              progress: 1.0,
              statusText:
                  '🎉 $total ${_selectedPreset!.name} clips ready! Check Downloads.',
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
        }
      },
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  String _fmtDur(double s) {
    final m = (s / 60).floor();
    final sec = (s % 60).floor();
    return m > 0 ? '${m}m ${sec}s' : '${sec}s';
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reels & Shorts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Platform Split Presets',
              style: TextStyle(color: Colors.white54, fontSize: 11.sp),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Platform grid (fixed, always visible)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Platform',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10.w,
                      mainAxisSpacing: 10.h,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: _kPresets.length,
                    itemBuilder: (ctx, i) {
                      return AnimatedBuilder(
                        animation: _cardAnimations[i],
                        builder:
                            (ctx, _) => Transform.scale(
                              scale: _cardAnimations[i].value,
                              child: Opacity(
                                opacity: _cardAnimations[i].value.clamp(
                                  0.0,
                                  1.0,
                                ),
                                child: _buildPresetCard(_kPresets[i]),
                              ),
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Bottom scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                child: Column(
                  children: [
                    // Selected preset info
                    if (_selectedPreset != null) ...[
                      _buildSelectedPresetInfo(),
                      SizedBox(height: 16.h),
                    ],

                    // Video picker
                    if (_selectedPreset != null) ...[
                      _buildVideoPicker(),
                      SizedBox(height: 16.h),
                    ],

                    // Video info
                    if (_selectedVideoPath != null &&
                        !_isProcessing &&
                        !_isDone) ...[
                      _buildVideoInfo(),
                      SizedBox(height: 16.h),
                      _buildStartButton(),
                    ],

                    // Progress
                    if (_isProcessing) _buildProgressCard(),

                    // Done
                    if (_isDone) _buildDoneCard(),

                    // Empty state
                    if (_selectedPreset == null) _buildEmptyState(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCard(PlatformPreset preset) {
    final isSelected = _selectedPreset?.id == preset.id;
    return GestureDetector(
      onTap: () {
        if (!mounted) return;
        setState(() {
          _selectedPreset = preset;
          _selectedVideoPath = null;
          _thumbnail = null;
          _videoDuration = 0;
          _estimatedClips = 0;
          _isDone = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      preset.primaryColor.withOpacity(0.3),
                      preset.secondaryColor.withOpacity(0.2),
                    ],
                  )
                  : const LinearGradient(
                    colors: [Color(0xFF111827), Color(0xFF1F2937)],
                  ),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color:
                isSelected
                    ? preset.primaryColor.withOpacity(0.7)
                    : Colors.white.withOpacity(0.07),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: preset.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [preset.primaryColor, preset.secondaryColor],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(preset.icon, color: Colors.white, size: 20.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              preset.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${preset.maxDurationSeconds}s',
              style: TextStyle(
                color: isSelected ? preset.primaryColor : Colors.white38,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPresetInfo() {
    final p = _selectedPreset!;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            p.primaryColor.withOpacity(0.1),
            p.secondaryColor.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: p.primaryColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.primaryColor, p.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(p.icon, color: Colors.white, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.platform} ${p.name}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  p.tip,
                  style: TextStyle(color: Colors.white54, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${p.maxDurationSeconds}s',
                style: TextStyle(
                  color: p.primaryColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                p.aspectRatio,
                style: TextStyle(color: Colors.white38, fontSize: 10.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPicker() {
    return GestureDetector(
      onTap: _isProcessing ? null : _pickVideo,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color:
                _selectedVideoPath != null
                    ? _selectedPreset!.primaryColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: (_selectedPreset?.primaryColor ?? Colors.blue)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                _selectedVideoPath != null
                    ? Icons.check
                    : Icons.video_library_outlined,
                color: _selectedPreset?.primaryColor ?? Colors.blue,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isPickingVideo
                        ? 'Selecting...'
                        : _selectedVideoPath != null
                        ? path.basename(_selectedVideoPath!)
                        : 'Select Video',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _selectedVideoPath != null
                        ? 'Tap to change'
                        : 'Tap to pick a video file',
                    style: TextStyle(color: Colors.white38, fontSize: 11.sp),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          if (_thumbnail != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.memory(
                _thumbnail!,
                width: 60.w,
                height: 60.w,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.videocam, color: Colors.white30, size: 24.sp),
            ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              children: [
                _row('Duration', _fmtDur(_videoDuration)),
                SizedBox(height: 6.h),
                _row(
                  'Clip Length',
                  '${_selectedPreset!.maxDurationSeconds}s each',
                ),
                SizedBox(height: 6.h),
                _row(
                  'Total Clips',
                  '$_estimatedClips clips',
                  highlight: true,
                  color: _selectedPreset!.primaryColor,
                ),
                SizedBox(height: 6.h),
                _row('Format', _selectedPreset!.aspectRatio),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    String l,
    String v, {
    bool highlight = false,
    Color color = Colors.white,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
        Text(
          v,
          style: TextStyle(
            color: highlight ? color : Colors.white,
            fontSize: 11.sp,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final p = _selectedPreset;
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: (p?.primaryColor ?? Colors.blue).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18.w,
                height: 18.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    p?.primaryColor ?? Colors.blue,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Processing ${p?.name ?? ''} clips...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$_currentClip/$_totalClips',
                style: TextStyle(
                  color: p?.primaryColor ?? Colors.blue,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(
                p?.primaryColor ?? Colors.blue,
              ),
              minHeight: 6.h,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _statusText,
            style: TextStyle(color: Colors.white38, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneCard() {
    final p = _selectedPreset!;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            p.primaryColor.withOpacity(0.12),
            p.secondaryColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: p.primaryColor.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.primaryColor, p.secondaryColor],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Colors.white, size: 28.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            '$_estimatedClips ${p.name} Clips Ready!',
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
            style: TextStyle(color: Colors.white54, fontSize: 12.sp),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _btn(
                  'New Video',
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
                child: _btn(
                  'Downloads',
                  Icons.download_done,
                  p.primaryColor,
                  () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    final p = _selectedPreset!;
    return GestureDetector(
      onTap: _startProcessing,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [p.primaryColor, p.secondaryColor]),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: p.primaryColor.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(p.icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 10.w),
            Text(
              'Split into $_estimatedClips ${p.name} Clips',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        children: [
          Icon(Icons.touch_app_outlined, color: Colors.white30, size: 48.sp),
          SizedBox(height: 12.h),
          Text(
            'Select a platform above',
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
          ),
          Text(
            'to get started',
            style: TextStyle(color: Colors.white30, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }

  Widget _btn(String l, IconData icon, Color c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 15.sp),
            SizedBox(width: 6.w),
            Text(
              l,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
