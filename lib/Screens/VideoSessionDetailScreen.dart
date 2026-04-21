// ignore_for_file: file_names, deprecated_member_use

import 'dart:io';
import 'package:auto_clipper_app/Logic/ad_service.dart';
import 'package:auto_clipper_app/Logic/video_downlod_controller.dart';
import 'package:auto_clipper_app/Screens/Video_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── Dark palette — FeaturesHubScreen exact ──────────────────────────────────
const _kDarkBg = Color(0xFF0A0E1A);
const _kDarkCard = Color(0xFF111827);
const _kDarkCardAlt = Color(0xFF1F2937);
const _kGradOrange = Color(0xFFFF6B35);
const _kGradPink = Color(0xFFE91E63);
const _kGradPurple = Color(0xFF9C27B0);
const _kGradCyan = Color(0xFF00BCD4);
const _kErr = Color(0xFFEF4444);
const _kSuccess = Color(0xFF22C55E);

const _primaryGradient = LinearGradient(
  colors: [_kGradOrange, _kGradPink, _kGradPurple],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Rotating video card gradients
const List<List<Color>> _kVidGrads = [
  [Color(0xFFFF6B35), Color(0xFFE91E63)],
  [Color(0xFF6C63FF), Color(0xFF9C27B0)],
  [Color(0xFF25D366), Color(0xFF128C7E)],
  [Color(0xFFE1306C), Color(0xFF833AB4)],
  [Color(0xFF00BCD4), Color(0xFF2196F3)],
];

List<Color> _gc(int i) => _kVidGrads[i % _kVidGrads.length];

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

  // Header — same 600ms as FeaturesHubScreen
  late AnimationController _headerController;

  // Card stagger — same as FeaturesHubScreen
  List<AnimationController> _cardControllers = [];
  List<Animation<double>> _cardFadeAnims = [];
  List<Animation<Offset>> _cardSlideAnims = [];

  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _buildCardAnimations();
  }

  void _buildCardAnimations() {
    final count = widget.session.videos.length + 1; // +1 for stats card
    _cardControllers = List.generate(
      count,
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
    // Stagger 200ms + i*150ms — same as FeaturesHubScreen
    for (int i = 0; i < count; i++) {
      Future.delayed(Duration(milliseconds: 200 + i * 150), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    for (final c in _cardControllers) c.dispose();
    super.dispose();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _downloadToGallery(String path) async {
    // ✅ FIX 1: mounted check before setState
    if (!mounted) return;
    setState(() => _statusMessage = 'Saving...');

    String msg;
    try {
      msg = await _controller.downloadToGallery(path);
    } catch (e) {
      if (mounted) setState(() => _statusMessage = '');
      return;
    }

    // ✅ FIX 2: mounted check after async
    if (!mounted) return;
    setState(() => _statusMessage = msg);

    if (msg.contains('successfully')) {
      _showSnack('Video saved ✓', _kSuccess, Icons.check_circle);
    } else if (msg.contains('permission')) {
      _showPermissionDialog();
    } else {
      _showSnack('Download failed', _kErr, Icons.error);
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _statusMessage = '');
    });
  }

  Future<void> _downloadAllVideos() async {
    if (!mounted) return; // ✅
    try {
      final msg = await _controller.downloadAllVideosSimple(
          widget.session, context);
      if (!mounted) return; // ✅
      setState(() => _statusMessage = msg);
    } catch (e) {
      if (mounted) setState(() => _statusMessage = 'Error: $e');
    }
  }

  Future<void> _shareVideo(String path) async {
    try {
      await _controller.shareVideo(path);
      if (!mounted) return; // ✅
      _showSnack('Sharing...', _kGradCyan, Icons.share);
    } catch (e) {
      if (mounted) setState(() => _statusMessage = 'Share failed: $e');
    }
  }

  void _showSnack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _previewVideo(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: _kDarkBg,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.download_outlined, color: _kGradOrange),
                    onPressed: () => _downloadToGallery(path),
                  ),
                  IconButton(
                    icon: Icon(Icons.share_outlined, color: _kGradPink),
                    onPressed: () => _shareVideo(path),
                  ),
                ],
              ),
              body: Center(child: VideoPlayerWidget(videoPath: path)),
            ),
      ),
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: _kDarkCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kGradOrange, _kGradPink],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      Icons.security_rounded,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Permission Required',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Storage permission is needed to save videos.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white54,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 44.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            openAppSettings();
                          },
                          child: Container(
                            height: 44.h,
                            decoration: BoxDecoration(
                              gradient: _primaryGradient,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Center(
                              child: Text(
                                'Open Settings',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
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

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: _kDarkCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: _kErr.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: _kErr,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Delete Session',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Delete "${widget.session.displayName}" and all clips?',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white54,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 44.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            await _controller.deleteSession(widget.session);
                            if (mounted) Navigator.pop(context);
                          },
                          child: Container(
                            height: 44.h,
                            decoration: BoxDecoration(
                              color: _kErr,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Center(
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header — same structure as FeaturesHubScreen ──────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerController,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back + icon + title + menu
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white54,
                                size: 16.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Container(
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
                              Icons.video_library_rounded,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.session.displayName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${widget.session.videos.length} clips  •  ${widget.session.totalSize}',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: Colors.white54,
                                size: 20.sp,
                              ),
                              padding: EdgeInsets.all(8.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              color: _kDarkCardAlt,
                              onSelected: (v) {
                                if (v == 'delete') _showDeleteDialog();
                              },
                              itemBuilder:
                                  (_) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(6.r),
                                            decoration: BoxDecoration(
                                              color: _kErr.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                            ),
                                            child: Icon(
                                              Icons.delete_outline_rounded,
                                              color: _kErr,
                                              size: 16.sp,
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Text(
                                            'Delete Session',
                                            style: TextStyle(
                                              color: _kErr,
                                              fontSize: 14.sp,
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
                      SizedBox(height: 20.h),

                      // Promo banner — same as FeaturesHubScreen
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
                            Text('🎬', style: TextStyle(fontSize: 22.sp)),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.session.videos.length} Processed Clips',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Download • Share • Preview each clip',
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
                      SizedBox(height: 20.h),
                      AdService.nativeWidget(
                        adId: 'vide_session_medium_1',
                        isLarge: false,
                        showLabel: false,
                        margin: const EdgeInsets.only(bottom: 8),
                        context: context,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Stats card ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _staggerWrap(
                0,
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
                  child: _buildStatsCard(),
                ),
              ),
            ),

            // ── Status banner ─────────────────────────────────────────────
            if (_statusMessage.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                  child: _buildStatusBanner(),
                ),
              ),

            // ── Download All btn ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                child: _buildDownloadAllBtn(),
              ),
            ),

            // ── Video cards — staggered like FeaturesHubScreen ────────────
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _staggerWrap(
                    i + 1,
                    _buildVideoCard(i, widget.session.videos[i]),
                  ),
                  childCount: widget.session.videos.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stagger wrapper ──────────────────────────────────────────────────────

  Widget _staggerWrap(int i, Widget child) {
    if (i >= _cardFadeAnims.length) return child;
    return AnimatedBuilder(
      animation: _cardFadeAnims[i],
      builder:
          (_, __) => SlideTransition(
            position: _cardSlideAnims[i],
            child: FadeTransition(opacity: _cardFadeAnims[i], child: child),
          ),
    );
  }

  // ─── Stats card ───────────────────────────────────────────────────────────

  Widget _buildStatsCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _kDarkCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGradOrange, _kGradPink],
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: _kGradOrange.withOpacity(0.3),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(
              Icons.video_library_rounded,
              color: Colors.white,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Overview',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _statItem(
                      '${widget.session.videos.length}',
                      'Videos',
                      _kGradOrange,
                    ),
                    Container(
                      width: 1,
                      height: 30.h,
                      color: Colors.white.withOpacity(0.08),
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                    ),
                    _statItem(
                      widget.session.totalSize,
                      'Storage',
                      _kGradPurple,
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

  Widget _statItem(String val, String lbl, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        val,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      Text(
        lbl,
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.white38,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  // ─── Status banner ────────────────────────────────────────────────────────

  Widget _buildStatusBanner() {
    final isErr =
        _statusMessage.toLowerCase().contains('error') ||
        _statusMessage.toLowerCase().contains('failed');
    final isDown = _controller.isBulkDownloading;
    final color =
        isErr
            ? _kErr
            : isDown
            ? _kGradCyan
            : _kSuccess;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (isDown)
            SizedBox(
              width: 18.w,
              height: 18.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            )
          else
            Icon(
              isErr ? Icons.error_outline : Icons.check_circle_outline,
              color: color,
              size: 18.sp,
            ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 13.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Download All ─────────────────────────────────────────────────────────

  Widget _buildDownloadAllBtn() {
    return GestureDetector(
      onTap: _controller.isBulkDownloading ? null : _downloadAllVideos,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54.h,
        decoration: BoxDecoration(
          gradient: _controller.isBulkDownloading ? null : _primaryGradient,
          color:
              _controller.isBulkDownloading
                  ? Colors.white.withOpacity(0.06)
                  : null,
          borderRadius: BorderRadius.circular(16.r),
          border:
              _controller.isBulkDownloading
                  ? Border.all(color: Colors.white.withOpacity(0.10))
                  : null,
          boxShadow:
              _controller.isBulkDownloading
                  ? []
                  : [
                    BoxShadow(
                      color: _kGradPink.withOpacity(0.4),
                      blurRadius: 20.r,
                      offset: Offset(0, 8.h),
                    ),
                    BoxShadow(
                      color: _kGradOrange.withOpacity(0.2),
                      blurRadius: 30.r,
                      offset: Offset(0, 12.h),
                    ),
                  ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.isBulkDownloading)
                SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white54),
                  ),
                )
              else
                Icon(Icons.download_rounded, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                _controller.isBulkDownloading
                    ? 'Downloading ${_controller.downloadProgress}/${_controller.totalDownloads}'
                    : 'Download All ${widget.session.videos.length} Clips',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color:
                      _controller.isBulkDownloading
                          ? Colors.white38
                          : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Video card — _FeatureCardWidget style ────────────────────────────────

  Widget _buildVideoCard(int index, ProcessedVideo video) {
    final g = _gc(index);
    return _PressableCard(
      gradientColors: g,
      onTap: () => _previewVideo(video.path),
      child: Column(
        children: [
          // Top strip + decorative circles + thumbnail — same as FeaturesHubScreen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  g[0].withOpacity(0.25),
                  g[1].withOpacity(0.1),
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
                // Decorative circles
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: g[0].withOpacity(0.08),
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
                      color: g[1].withOpacity(0.06),
                    ),
                  ),
                ),

                // Thumbnail overlay if available
                if (video.thumbnailPath != null)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                      child: Stack(
                        children: [
                          Image.file(
                            File(video.thumbnailPath!),
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
                                stops: const [0.4, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Content row — same layout as FeaturesHubScreen
                SizedBox(
                  height: 120.h,
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: g),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: g[0].withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26.sp,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Tap to preview',
                                style: TextStyle(
                                  color: g[0],
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            '${video.durationInSeconds}s',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Description + tags — same as FeaturesHubScreen
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap to preview, or download & share below.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 10.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  children: [
                    _chip(video.formattedSize, g[0]),
                    _chip('${video.durationInSeconds}s', g[1]),
                    _chip('Clip ${index + 1}', Colors.white38),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
            child: Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    label: 'Download',
                    icon: Icons.download_outlined,
                    gc: g,
                    onTap: () async {
                      AdService.showAdThenAction(
                        onActionComplete: () async {
                          if (Navigator.of(context).canPop()) {
                            Navigator.pop(context);
                          }
                          _downloadToGallery(video.path);
                        },
                      );
                    },
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _actionBtn(
                    label: 'Share',
                    icon: Icons.share_outlined,
                    gc: g,
                    isOutlined: true,
                    onTap: () async {
                      AdService.showAdThenAction(
                        onActionComplete: () async {
                          if (Navigator.of(context).canPop()) {
                            Navigator.pop(context);
                          }
                          _shareVideo(video.path);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Center(
            child: Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: _kDarkCard,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_kGradPink),
              ),
            ),
          ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required List<Color> gc,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46.h,
        decoration: BoxDecoration(
          gradient: isOutlined ? null : LinearGradient(colors: gc),
          color: isOutlined ? Colors.white.withOpacity(0.06) : null,
          borderRadius: BorderRadius.circular(12.r),
          border: isOutlined ? Border.all(color: gc[0].withOpacity(0.4)) : null,
          boxShadow:
              isOutlined
                  ? []
                  : [
                    BoxShadow(
                      color: gc[0].withOpacity(0.3),
                      blurRadius: 10.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17.sp, color: isOutlined ? gc[0] : Colors.white),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: isOutlined ? gc[0] : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pressable Card — exactly _FeatureCardWidget from FeaturesHubScreen ───────

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
  late AnimationController _pc;
  late Animation<double> _sc;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pc = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _sc = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pc, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 16.h),
    child: GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _pc.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _pc.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _pc.reverse();
      },
      child: ScaleTransition(
        scale: _sc,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            // dark card same as FeaturesHubScreen
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
    ),
  );
}
