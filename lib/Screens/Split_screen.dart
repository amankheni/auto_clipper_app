// video_splitter_screen.dart
// ignore_for_file: avoid_print, depend_on_referenced_packages, deprecated_member_use, file_names

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:auto_clipper_app/Logic/Split_Controller.dart';
import 'package:auto_clipper_app/Logic/ad_service.dart';
import 'package:auto_clipper_app/Screens/video_download_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path/path.dart' as path;
import 'package:video_thumbnail/video_thumbnail.dart';

// ─── Dark palette — exactly matching FeaturesHubScreen ───────────────────────
const _kDarkBg = Color(0xFF0A0E1A);
const _kDarkCard = Color(0xFF111827);
const _kDarkCardAlt = Color(0xFF1F2937);
const _kGradOrange = Color(0xFFFF6B35);
const _kGradPink = Color(0xFFE91E63);
const _kGradPurple = Color(0xFF9C27B0);
const _kErr = Color(0xFFEF4444);
const _kSuccess = Color(0xFF22C55E);

const _primaryGradient = LinearGradient(
  colors: [_kGradOrange, _kGradPink, _kGradPurple],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Per-section gradient colors — same as features_hub cards
const _videoGrad = [Color(0xFFFF6B35), Color(0xFFE91E63)];
const _durationGrad = [Color(0xFF6C63FF), Color(0xFF9C27B0)];
const _watermarkGrad = [Color(0xFFE1306C), Color(0xFF833AB4)];

class VideoSplitterScreen extends StatefulWidget {
  const VideoSplitterScreen({super.key});

  @override
  State<VideoSplitterScreen> createState() => _VideoSplitterScreenState();
}

class _VideoSplitterScreenState extends State<VideoSplitterScreen>
    with TickerProviderStateMixin {
  late VideoSplitterService _videoSplitterService;

  // Header animation — same as features_hub
  late AnimationController _headerController;

  // 3 card stagger controllers — same as features_hub
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardFadeAnims;
  late List<Animation<Offset>> _cardSlideAnims;

  // Processing spinner
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  // Split button press scale
  late AnimationController _btnPressController;
  late Animation<double> _btnScaleAnim;

  // State
  String? _selectedVideoPath;
  String? _selectedWatermarkPath;
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
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
  final bool _isPortraitMode = false;
  final bool _useTextOverlay = false;
  final String _textPrefix = 'Part';
  final TextPosition _textPosition = TextPosition.topCenter;
  final Color _textColor = Colors.white;
  final double _fontSize = 24.0;

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
    // Header fade — same 600ms as features_hub
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    // 3 staggered cards — same timing as features_hub
    _cardControllers = List.generate(
      3,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      ),
    );
    _cardFadeAnims =
        _cardControllers
            .map(
              (c) => Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack)),
            )
            .toList();
    _cardSlideAnims =
        _cardControllers
            .map(
              (c) => Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
            )
            .toList();

    // Stagger: 200ms + i*150ms — exactly features_hub
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: 200 + i * 150), () {
        if (mounted) _cardControllers[i].forward();
      });
    }

    // Spinner
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Button press
    _btnPressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _btnScaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _btnPressController, curve: Curves.easeOut),
    );
  }

  Future<void> _requestPermissions() async =>
      await _videoSplitterService.requestPermissions();

  void _onProgressUpdate(VideoSplitterProgress p) {
    setState(() {
      _currentClip = p.currentClip;
      _totalClips = p.totalClips;
      _progress = p.progress;
      _statusText = p.statusText;
      _isProcessing = p.isProcessing;
    });
    _isProcessing ? _rotationController.repeat() : _rotationController.stop();
  }

  Future<void> _pickVideo() async {
    try {
      final vp = await _videoSplitterService.pickVideo();
      if (vp != null) {
        setState(() {
          _selectedVideoPath = vp;
          _statusText = '';
        });
        await _generateThumbnail(vp);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _generateThumbnail(String vp) async {
    try {
      final t = await VideoThumbnail.thumbnailData(
        video: vp,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 80,
      );
      setState(() => _videoThumbnail = t);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pickWatermark() async {
    try {
      final wm = await _videoSplitterService.pickWatermark();
      if (wm != null) setState(() => _selectedWatermarkPath = wm);
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _startSplitting() async {
    if (_selectedVideoPath == null) {
      _showSnack('Please select a video', isError: true);
      return;
    }
    final dt = _durationController.text.trim();
    if (dt.isEmpty) {
      _showSnack('Enter duration', isError: true);
      return;
    }
    final dur = double.tryParse(dt) ?? 0;
    if (dur <= 0) {
      _showSnack('Enter valid duration', isError: true);
      return;
    }
    if (_useWatermark && _selectedWatermarkPath == null) {
      _showSnack('Select a watermark image', isError: true);
      return;
    }
    final clipDur = _videoSplitterService.getDurationInSeconds(
      dur,
      _selectedUnit,
    );
    AdService.showAdThenAction(
      onActionComplete: () async{
        try {
          await _videoSplitterService.splitVideo(
            videoPath: _selectedVideoPath!,
            clipDurationInSeconds: clipDur,
            useWatermark: _useWatermark,
            watermarkPath: _selectedWatermarkPath,
            watermarkOpacity: _watermarkOpacity,
            watermarkPosition: _watermarkPosition,
            useTextOverlay: _useTextOverlay,
            textPrefix: _textPrefix,
            textPosition: _textPosition,
            fontSize: _fontSize,
            textColor: _textColor.value.toRadixString(16).substring(2),
            isPortraitMode: _isPortraitMode,
          );
          if (!_isProcessing && _statusText.toLowerCase().contains('completed')) {
            _showSuccessDialog();
          }
        } catch (e) {
          _showSnack('Error: $e', isError: true);
        }
      },
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(fontSize: 14.sp, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? _kErr : _kGradPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.r),
      ),
    );
  }

  String _fmtSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const s = ['B', 'KB', 'MB', 'GB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(i > 0 ? 1 : 0)} ${s[i]}';
  }

  Offset _wmPos() {
    switch (_watermarkPosition) {
      case WatermarkPosition.topLeft:
        return Offset(8.w, 8.h);
      case WatermarkPosition.topRight:
        return Offset(130.w, 8.h);
      case WatermarkPosition.bottomLeft:
        return Offset(8.w, 70.h);
      case WatermarkPosition.bottomRight:
        return Offset(130.w, 70.h);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBg, // same as FeaturesHubScreen
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              FadeTransition(
                opacity: _headerController,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Animated icon — spins while processing
                          AnimatedBuilder(
                            animation: _rotationAnimation,
                            builder:
                                (_, __) => Transform.rotate(
                                  angle:
                                      _isProcessing
                                          ? _rotationAnimation.value * 2 * pi
                                          : 0,
                                  child: Container(
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [_kGradOrange, _kGradPink],
                                      ),
                                      borderRadius: BorderRadius.circular(14.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _kGradPink.withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isProcessing
                                          ? Icons.autorenew_rounded
                                          : Icons.content_cut_rounded,
                                      color: Colors.white,
                                      size: 22.sp,
                                    ),
                                  ),
                                ),
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Video Clipper',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                _isProcessing
                                    ? 'Processing clip $_currentClip of $_totalClips...'
                                    : 'Professional Video Splitter',
                                style: TextStyle(
                                  color:
                                      _isProcessing
                                          ? _kGradOrange
                                          : Colors.white54,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // Promo banner
                      Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _kGradOrange.withOpacity(0.15),
                              _kGradPink.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: _kGradOrange.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text('✂️', style: TextStyle(fontSize: 22.sp)),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Smart Auto-Split Technology',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Watermark • Custom Duration • All Formats',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11.sp,
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

              // ── Cards ───────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 30.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 0: Video picker
                    _staggerCard(0, _buildVideoCard()),
                    SizedBox(height: 16.h),

                    AdService.nativeWidget(
                      adId: 'split_medium_1',
                      isLarge: true,
                      showLabel: false,
                      margin: const EdgeInsets.only(bottom: 8),
                      context: context,
                    ),
                    SizedBox(height: 16.h),

                    // Card 1: Duration
                    _staggerCard(1, _buildDurationCard()),
                    SizedBox(height: 16.h),

                    // Card 2: Watermark
                    _staggerCard(2, _buildWatermarkCard()),
                    SizedBox(height: 24.h),

                    // Split button
                    _buildSplitBtn(),

                    if (_isProcessing) ...[
                      SizedBox(height: 16.h),
                      _buildProgressCard(),
                    ],

                    if (_statusText.isNotEmpty && !_isProcessing) ...[
                      SizedBox(height: 16.h),
                      _buildStatusCard(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stagger wrapper — same as features_hub AnimatedBuilder wrapper ──────────

  Widget _staggerCard(int i, Widget child) {
    return AnimatedBuilder(
      animation: _cardFadeAnims[i],
      builder:
          (_, __) => SlideTransition(
            position: _cardSlideAnims[i],
            child: FadeTransition(opacity: _cardFadeAnims[i], child: child),
          ),
    );
  }

  // ─── _FeatureCardWidget-style wrapper (dark card shell) ──────────────────────

  Widget _darkCard({
    required List<Color> gradColors,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return _PressableCard(
      gradientColors: gradColors,
      onTap: onTap,
      child: child,
    );
  }

  // ─── Top gradient strip — exact structure from features_hub ─────────────────

  Widget _topStrip({
    required List<Color> gradColors,
    required double height,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradColors[0].withOpacity(0.25),
            gradColors[1].withOpacity(0.1),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles — same as features_hub
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gradColors[0].withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -10,
            child: Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gradColors[1].withOpacity(0.06),
              ),
            ),
          ),
          // Content row — same layout as features_hub
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradColors),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: gradColors[0].withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: gradColors[0],
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ??
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 14.sp,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Description + tags — same as features_hub bottom section ────────────────

  Widget _descAndTags({
    required String description,
    required List<String> tags,
    required List<Color> gradColors,
    Widget? extra,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children:
                tags
                    .map(
                      (tag) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: gradColors[0].withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: gradColors[0].withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: gradColors[0],
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          if (extra != null) extra,
        ],
      ),
    );
  }

  // ─── Card 0: Video Picker ─────────────────────────────────────────────────────

  Widget _buildVideoCard() {
    final selected = _selectedVideoPath != null;
    return _darkCard(
      gradColors: _videoGrad,
      onTap: _isProcessing ? null : _pickVideo,
      child: Column(
        children: [
          Stack(
            children: [
              _topStrip(
                gradColors: _videoGrad,
                height: 120.h,
                icon:
                    selected
                        ? Icons.check_circle_outline
                        : Icons.video_library_outlined,
                title: 'Select Video',
                subtitle: selected ? 'Video Ready ✓' : 'Tap to browse',
                trailing: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    selected ? Icons.edit_outlined : Icons.add,
                    color: Colors.white54,
                    size: 14.sp,
                  ),
                ),
              ),
              // Thumbnail overlay
              if (_videoThumbnail != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                    child: Stack(
                      children: [
                        Image.memory(
                          _videoThumbnail!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.65),
                              ],
                            ),
                          ),
                        ),
                        if (_useWatermark && _selectedWatermarkPath != null)
                          Positioned(
                            top: _wmPos().dy,
                            left: _wmPos().dx,
                            child: Container(
                              width: 44.w,
                              height: 44.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.r),
                                image: DecorationImage(
                                  image: FileImage(
                                    File(_selectedWatermarkPath!),
                                  ),
                                  opacity: _watermarkOpacity,
                                  fit: BoxFit.contain,
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          _descAndTags(
            description:
                selected
                    ? '${path.basename(_selectedVideoPath!)}  •  ${_fmtSize(File(_selectedVideoPath!).lengthSync())}'
                    : 'Tap to browse MP4, MOV, AVI files from your device.',
            tags: ['MP4', 'MOV', 'AVI', 'MKV'],
            gradColors: _videoGrad,
          ),
        ],
      ),
    );
  }

  // ─── Card 1: Duration ─────────────────────────────────────────────────────────

  Widget _buildDurationCard() {
    return _darkCard(
      gradColors: _durationGrad,
      child: Column(
        children: [
          _topStrip(
            gradColors: _durationGrad,
            height: 90.h,
            icon: Icons.timer_outlined,
            title: 'Clip Duration',
            subtitle: 'Set split interval',
            trailing: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.tune, color: Colors.white54, size: 14.sp),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: TextField(
                          controller: _durationController,
                          enabled: !_isProcessing,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g., 30',
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 14.sp,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14.r),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: DropdownButtonFormField<DurationUnit>(
                          value: _selectedUnit,
                          dropdownColor: _kDarkCardAlt,
                          iconEnabledColor: Colors.white54,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 14.h,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
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
                                  : (v) => setState(() => _selectedUnit = v!),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // Quick chips
                Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  children:
                      ['15s', '30s', '60s', '90s'].map((t) {
                        final val = double.parse(t.replaceAll('s', ''));
                        final sel =
                            _durationController.text == '$val' &&
                            _selectedUnit == DurationUnit.seconds;
                        return GestureDetector(
                          onTap:
                              () => setState(() {
                                _durationController.text = '$val';
                                _selectedUnit = DurationUnit.seconds;
                              }),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              gradient:
                                  sel
                                      ? const LinearGradient(
                                        colors: _durationGrad,
                                      )
                                      : null,
                              color:
                                  sel ? null : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color:
                                    sel
                                        ? Colors.transparent
                                        : Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                color: sel ? Colors.white : Colors.white54,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                SizedBox(height: 8.h),
                // Tags
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children:
                        ['Seconds', 'Minutes', 'Hours']
                            .map(
                              (tag) => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: _durationGrad[0].withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: _durationGrad[0].withOpacity(0.25),
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: _durationGrad[0],
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card 2: Watermark ────────────────────────────────────────────────────────

  Widget _buildWatermarkCard() {
    return _darkCard(
      gradColors: _watermarkGrad,
      child: Column(
        children: [
          _topStrip(
            gradColors: _watermarkGrad,
            height: 90.h,
            icon: Icons.layers_rounded,
            title: 'Watermark',
            subtitle: 'Add logo to clips',
            trailing: GestureDetector(
              onTap:
                  _isProcessing
                      ? null
                      : () => setState(() => _useWatermark = !_useWatermark),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 52.w,
                height: 28.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  gradient:
                      _useWatermark
                          ? const LinearGradient(colors: _watermarkGrad)
                          : null,
                  color: _useWatermark ? null : Colors.white.withOpacity(0.12),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  alignment:
                      _useWatermark
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: Container(
                    width: 22.w,
                    height: 22.h,
                    margin: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4.r,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _descAndTags(
            description:
                'Brand your clips with a logo or image overlay. Adjustable opacity and position.',
            tags: ['Logo Overlay', 'PNG/JPG', 'Opacity', '4 Positions'],
            gradColors: _watermarkGrad,
            extra: AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              child:
                  _useWatermark
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 16.h),
                          // Watermark picker
                          GestureDetector(
                            onTap: _isProcessing ? null : _pickWatermark,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.all(14.r),
                              decoration: BoxDecoration(
                                color:
                                    _selectedWatermarkPath != null
                                        ? _watermarkGrad[0].withOpacity(0.10)
                                        : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color:
                                      _selectedWatermarkPath != null
                                          ? _watermarkGrad[0].withOpacity(0.35)
                                          : Colors.white.withOpacity(0.10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10.r),
                                    decoration: BoxDecoration(
                                      color:
                                          _selectedWatermarkPath != null
                                              ? _watermarkGrad[0].withOpacity(
                                                0.20,
                                              )
                                              : Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Icon(
                                      _selectedWatermarkPath != null
                                          ? Icons.check_circle_outline
                                          : Icons.add_photo_alternate_outlined,
                                      color:
                                          _selectedWatermarkPath != null
                                              ? _watermarkGrad[0]
                                              : Colors.white54,
                                      size: 22.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedWatermarkPath == null
                                              ? 'Select Watermark Image'
                                              : 'Watermark Ready ✓',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _selectedWatermarkPath != null
                                                    ? _watermarkGrad[0]
                                                    : Colors.white,
                                          ),
                                        ),
                                        Text(
                                          _selectedWatermarkPath == null
                                              ? 'JPG, PNG supported'
                                              : path.basename(
                                                _selectedWatermarkPath!,
                                              ),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.white54,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white38,
                                    size: 14.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 14.h),
                          // Opacity slider
                          Container(
                            padding: EdgeInsets.all(14.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.opacity,
                                          color: Colors.white54,
                                          size: 16.sp,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          'Opacity',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 3.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _watermarkGrad[0].withOpacity(
                                          0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: Text(
                                        '${(_watermarkOpacity * 100).round()}%',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w700,
                                          color: _watermarkGrad[0],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4.h,
                                    activeTrackColor: _watermarkGrad[0],
                                    inactiveTrackColor: Colors.white
                                        .withOpacity(0.15),
                                    thumbColor: Colors.white,
                                    overlayColor: _watermarkGrad[0].withOpacity(
                                      0.15,
                                    ),
                                    thumbShape: CustomSliderThumbShape(
                                      enabledThumbRadius: 11.r,
                                      elevation: 3,
                                    ),
                                  ),
                                  child: Slider(
                                    value: _watermarkOpacity,
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: 20,
                                    onChanged:
                                        (v) => setState(
                                          () => _watermarkOpacity = v,
                                        ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (final entry in [
                                      ('Light', 0.3),
                                      ('Medium', 0.5),
                                      ('Strong', 0.8),
                                    ]) ...[
                                      SizedBox(width: 4.w),
                                      GestureDetector(
                                        onTap:
                                            () => setState(
                                              () =>
                                                  _watermarkOpacity = entry.$2,
                                            ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 5.h,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient:
                                                (_watermarkOpacity - entry.$2)
                                                            .abs() <
                                                        0.05
                                                    ? const LinearGradient(
                                                      colors: _watermarkGrad,
                                                    )
                                                    : null,
                                            color:
                                                (_watermarkOpacity - entry.$2)
                                                            .abs() <
                                                        0.05
                                                    ? null
                                                    : Colors.white.withOpacity(
                                                      0.08,
                                                    ),
                                            borderRadius: BorderRadius.circular(
                                              20.r,
                                            ),
                                            border: Border.all(
                                              color:
                                                  (_watermarkOpacity - entry.$2)
                                                              .abs() <
                                                          0.05
                                                      ? Colors.transparent
                                                      : Colors.white
                                                          .withOpacity(0.12),
                                            ),
                                          ),
                                          child: Text(
                                            entry.$1,
                                            style: TextStyle(
                                              color:
                                                  (_watermarkOpacity - entry.$2)
                                                              .abs() <
                                                          0.05
                                                      ? Colors.white
                                                      : Colors.white54,
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 14.h),
                          // Position
                          Row(
                            children: [
                              Icon(
                                Icons.photo_size_select_actual_outlined,
                                color: _watermarkGrad[0],
                                size: 16.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Position',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: DropdownButtonFormField<WatermarkPosition>(
                              value: _watermarkPosition,
                              dropdownColor: _kDarkCardAlt,
                              iconEnabledColor: Colors.white54,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 14.h,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: WatermarkPosition.topLeft,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.north_west,
                                        size: 16,
                                        color: Colors.white54,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Top Left'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: WatermarkPosition.topRight,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.north_east,
                                        size: 16,
                                        color: Colors.white54,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Top Right'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: WatermarkPosition.bottomLeft,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.south_west,
                                        size: 16,
                                        color: Colors.white54,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Bottom Left'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: WatermarkPosition.bottomRight,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.south_east,
                                        size: 16,
                                        color: Colors.white54,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Bottom Right'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged:
                                  _isProcessing
                                      ? null
                                      : (v) => setState(
                                        () => _watermarkPosition = v!,
                                      ),
                            ),
                          ),
                        ],
                      )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Split button — features_hub press animation ─────────────────────────────

  Widget _buildSplitBtn() {
    return GestureDetector(
      onTapDown: (_) {
        if (!_isProcessing) _btnPressController.forward();
      },
      onTapUp: (_) {
        _btnPressController.reverse();
        if (!_isProcessing) {
          // InterstitialAdsController().handleButtonClick(context);
          _startSplitting();
        }
      },
      onTapCancel: () => _btnPressController.reverse(),
      child: ScaleTransition(
        scale: _btnScaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 60.h,
          decoration: BoxDecoration(
            gradient:
                _isProcessing
                    ? LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.05),
                      ],
                    )
                    : _primaryGradient,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color:
                  _isProcessing
                      ? Colors.white.withOpacity(0.12)
                      : Colors.transparent,
            ),
            boxShadow:
                _isProcessing
                    ? []
                    : [
                      BoxShadow(
                        color: _kGradPink.withOpacity(0.4),
                        blurRadius: 24.r,
                        offset: Offset(0, 10.h),
                      ),
                      BoxShadow(
                        color: _kGradOrange.withOpacity(0.2),
                        blurRadius: 40.r,
                        offset: Offset(0, 16.h),
                      ),
                    ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isProcessing)
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white54),
                    ),
                  )
                else
                  Icon(
                    Icons.content_cut_rounded,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                SizedBox(width: 10.w),
                Text(
                  _isProcessing ? 'Processing...' : 'Split Video',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: _isProcessing ? Colors.white38 : Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Progress card ───────────────────────────────────────────────────────────

  Widget _buildProgressCard() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: _kDarkCard,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _kGradPink.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: _kGradPink.withOpacity(0.08),
            blurRadius: 20.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kGradOrange, _kGradPink],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Processing Video',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Creating clips...',
                      style: TextStyle(fontSize: 12.sp, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: _primaryGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${(_progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: _kGradPink.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  'Clip $_currentClip of $_totalClips',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: _kGradPink,
                  ),
                ),
              ),
              Text(
                'Processing...',
                style: TextStyle(fontSize: 12.sp, color: Colors.white54),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            height: 10.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _primaryGradient,
                      borderRadius: BorderRadius.circular(5.r),
                      boxShadow: [
                        BoxShadow(
                          color: _kGradPink.withOpacity(0.5),
                          blurRadius: 8.r,
                        ),
                      ],
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

  // ─── Status card ─────────────────────────────────────────────────────────────

  Widget _buildStatusCard() {
    final isSuccess = _statusText.toLowerCase().contains('completed');
    final isError = _statusText.toLowerCase().contains('error');
    final color =
        isError
            ? _kErr
            : isSuccess
            ? _kSuccess
            : const Color(0xFF3B82F6);
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              isError
                  ? Icons.error_outline_rounded
                  : isSuccess
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isError
                      ? 'Failed'
                      : isSuccess
                      ? 'Done! 🎉'
                      : 'Status',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  _statusText,
                  style: TextStyle(fontSize: 13.sp, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Success dialog ───────────────────────────────────────────────────────────

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            backgroundColor: _kDarkCard,
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withOpacity(0.35),
                          blurRadius: 20.r,
                          offset: Offset(0, 8.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 36.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Split Successfully!',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Your video was split into $_totalClips clips.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white54,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 28.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => VideoDownloadScreen(
                                      preserveStateKey: const ValueKey(
                                        'video_download_screen',
                                      ),
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              gradient: _primaryGradient,
                              borderRadius: BorderRadius.circular(14.r),
                              boxShadow: [
                                BoxShadow(
                                  color: _kGradPink.withOpacity(0.35),
                                  blurRadius: 12.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.download_rounded,
                                    color: Colors.white,
                                    size: 18.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Downloads',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Close',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white54,
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
          ),
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    for (final c in _cardControllers) c.dispose();
    _rotationController.dispose();
    _btnPressController.dispose();
    _durationController.dispose();
    _textController.dispose();
    super.dispose();
  }
}

// ─── Pressable card — same as _FeatureCardWidget in features_hub ─────────────

class _PressableCard extends StatefulWidget {
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final Widget child;

  const _PressableCard({
    required this.gradientColors,
    this.onTap,
    required this.child,
  });

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.onTap != null
              ? (_) {
                setState(() => _pressed = true);
                _pressCtrl.forward();
              }
              : null,
      onTapUp:
          widget.onTap != null
              ? (_) {
                setState(() => _pressed = false);
                _pressCtrl.reverse();
                widget.onTap!();
              }
              : null,
      onTapCancel:
          widget.onTap != null
              ? () {
                setState(() => _pressed = false);
                _pressCtrl.reverse();
              }
              : null,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827), // dark card — same as features_hub
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color:
                  _pressed
                      ? widget.gradientColors.first.withOpacity(0.5)
                      : Colors.white.withOpacity(0.07),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.first.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─── Custom Slider Thumb ──────────────────────────────────────────────────────

class CustomSliderThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  final double elevation;

  const CustomSliderThumbShape({
    this.enabledThumbRadius = 10.0,
    this.elevation = 1.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(enabledThumbRadius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(
      center + const Offset(0, 1),
      enabledThumbRadius,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, elevation),
    );
    canvas.drawCircle(
      center,
      enabledThumbRadius,
      Paint()..color = sliderTheme.thumbColor ?? Colors.white,
    );
    canvas.drawCircle(
      center,
      enabledThumbRadius - 1,
      Paint()
        ..color = sliderTheme.activeTrackColor ?? _kGradPink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }
}
