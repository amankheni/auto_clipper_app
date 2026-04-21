// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print, library_private_types_in_public_api

import 'dart:async';
import 'package:auto_clipper_app/Logic/ad_service.dart';
import 'package:auto_clipper_app/Logic/video_downlod_controller.dart';
import 'package:auto_clipper_app/Screens/VideoSessionDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';

// Dark palette
const _kDarkBg      = Color(0xFF0A0E1A);
const _kDarkCard    = Color(0xFF111827);
const _kDarkAlt     = Color(0xFF1F2937);
const _kGradOrange  = Color(0xFFFF6B35);
const _kGradPink    = Color(0xFFE91E63);
const _kGradPurple  = Color(0xFF9C27B0);
const _kGradCyan    = Color(0xFF00BCD4);
const _kErr         = Color(0xFFEF4444);
const _kSuccess     = Color(0xFF22C55E);

const _primaryGradient = LinearGradient(
  colors: [_kGradOrange, _kGradPink, _kGradPurple],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const List<List<Color>> _kCardGrads = [
  [Color(0xFFFF6B35), Color(0xFFE91E63)],
  [Color(0xFF6C63FF), Color(0xFF9C27B0)],
  [Color(0xFF25D366), Color(0xFF128C7E)],
  [Color(0xFFE1306C), Color(0xFF833AB4)],
  [Color(0xFF00BCD4), Color(0xFF2196F3)],
];
List<Color> _gradFor(int i) => _kCardGrads[i % _kCardGrads.length];

class VideoDownloadScreen extends StatefulWidget {
  const VideoDownloadScreen({super.key, this.preserveStateKey});
  final Key? preserveStateKey;

  @override
  _VideoDownloadScreenState createState() => _VideoDownloadScreenState();
}

class _VideoDownloadScreenState extends State<VideoDownloadScreen>
    with TickerProviderStateMixin {
  final VideoDownloadController _controller = VideoDownloadController();

  // ✅ FIX 1: In-memory cache — screen reopen instantly
  static List<VideoSession> _cachedSessions = [];
  static bool _hasCached = false;

  List<VideoSession> _sessions = [];
  bool _isLoading = false;
  bool _isFirstLoad = true;
  String _statusMessage = '';
  VideoSession? _selectedSession;

  late AnimationController _headerController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<AnimationController> _cardControllers = [];
  List<Animation<double>> _cardFadeAnims = [];
  List<Animation<Offset>> _cardSlideAnims = [];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400), // ✅ 700 → 400
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    // ✅ FIX 2: Cache available → show instantly, load in background
    if (_hasCached && _cachedSessions.isNotEmpty) {
      _sessions = List.from(_cachedSessions);
      _isFirstLoad = false;
      _fadeController.forward();
      _buildCardAnimations(_sessions.length);
      // Background refresh
      _loadVideoSessionsBackground();
    } else {
      _loadVideoSessions();
    }

    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    _headerController.dispose();
    _fadeController.dispose();
    for (final c in _cardControllers) c.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 8), // ✅ 5s → 8s (less frequent)
          (_) => _silentRefresh(),
    );
  }

  void _stopAutoRefresh() => _refreshTimer?.cancel();

  // ✅ FIX 3: Silent refresh — only update if changed
  Future<void> _silentRefresh() async {
    if (!mounted || _isLoading) return;
    try {
      final sessions = await _controller.loadVideoSessions();
      if (!mounted) return;

      // Update cache
      _cachedSessions = sessions;
      _hasCached = true;

      final oldCount = _sessions.length;
      if (sessions.length != oldCount) {
        setState(() => _sessions = sessions);
        _buildCardAnimations(sessions.length);
        if (sessions.length > oldCount) {
          final added = sessions.length - oldCount;
          _showSnack(
            '$added new video${added > 1 ? "s" : ""} added!',
            _kSuccess,
            Icons.video_library,
          );
        }
      }
    } catch (_) {}
  }

  // ✅ Background refresh — no loading indicator
  Future<void> _loadVideoSessionsBackground() async {
    try {
      final sessions = await _controller.loadVideoSessions();
      if (!mounted) return;

      _cachedSessions = sessions;
      _hasCached = true;

      if (sessions.length != _sessions.length) {
        setState(() => _sessions = sessions);
        _buildCardAnimations(sessions.length);
      }
    } catch (_) {}
  }

  void _buildCardAnimations(int count) {
    for (final c in _cardControllers) c.dispose();
    _cardControllers = List.generate(
      count,
          (i) => AnimationController(
        duration: const Duration(milliseconds: 400), // ✅ 500 → 400
        vsync: this,
      ),
    );
    _cardFadeAnims = _cardControllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _cardSlideAnims = _cardControllers
        .map((c) => Tween<Offset>(
      begin: const Offset(0, 0.2), // ✅ 0.3 → 0.2 (faster feel)
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    for (int i = 0; i < count; i++) {
      // ✅ FIX 4: Stagger reduced — 200+i*150 → 100+i*80
      Future.delayed(Duration(milliseconds: 100 + i * 80), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  Future<void> _loadVideoSessions() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final sessions = await _controller.loadVideoSessions();

      // Update cache
      _cachedSessions = sessions;
      _hasCached = true;

      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _isFirstLoad = false;
      });
      _fadeController.forward(from: 0);
      _buildCardAnimations(sessions.length);
    } catch (e) {
      if (mounted) setState(() => _statusMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ FIX 5: Delete — instant UI update, background delete
  Future<void> _deleteSession(VideoSession session) async {
    // ✅ Instantly remove from UI
    final idx = _sessions.indexOf(session);
    setState(() {
      _sessions.removeWhere((s) => s.sessionPath == session.sessionPath);
      _cachedSessions.removeWhere((s) => s.sessionPath == session.sessionPath);
      _selectedSession = null;
      _statusMessage = 'Deleted';
    });
    _buildCardAnimations(_sessions.length);

    // Background actual delete
    try {
      await _controller.deleteSession(session);
    } catch (e) {
      // Rollback if delete failed
      if (mounted) {
        if (idx >= 0 && idx <= _sessions.length) {
          _sessions.insert(idx, session);
          _cachedSessions.insert(idx, session);
        }
        setState(() => _statusMessage = 'Delete failed: $e');
      }
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _statusMessage = '');
    });
  }

  Future<void> _downloadToGallery(String videoPath) async {
    final msg = await _controller.downloadToGallery(videoPath);
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

  Future<void> _downloadAllVideosSimple(VideoSession session) async {
    final msg = await _controller.downloadAllVideosSimple(session, context);
    setState(() => _statusMessage = msg);
    final success = int.tryParse(msg.split(' ').first) ?? 0;
    final fail = session.videos.length - success;
    _showSnack(
      '$success downloaded, $fail failed',
      success > 0 ? _kSuccess : _kErr,
      success > 0 ? Icons.download_done : Icons.error,
    );
  }

  Future<void> _shareVideo(String videoPath) async {
    try {
      await _controller.shareVideo(videoPath);
      _showSnack('Sharing...', _kGradCyan, Icons.share);
    } catch (e) {
      setState(() => _statusMessage = 'Share failed: $e');
    }
  }

  void _showSnack(String msg, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(msg,
                style: TextStyle(fontSize: 14.sp, color: Colors.white,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.r),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 HEADER
              FadeTransition(
                opacity: _headerController,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_kGradOrange, _kGradPink]),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Icon(Icons.download_rounded,
                              color: Colors.white, size: 22.sp),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Downloads',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.bold)),
                              Text('${_sessions.length} sessions saved',
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13.sp)),
                            ],
                          ),
                        ),
                      ]),
                      SizedBox(height: 20.h),
                      AdService.nativeWidget(
                        adId: 'video_native_preview',
                        context: context,
                        showLabel: false,
                        isLarge: false,
                        margin: EdgeInsets.zero,
                      ),
                      SizedBox(height: 20.h),

                      _buildStatsBar(),
                    ],
                  ),
                ),
              ),

              // 🔹 STATUS
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
                  child: _buildStatusBanner(),
                ),

              // 🔹 CONTENT
              if (_isLoading && _sessions.isEmpty)
                const SizedBox(
                  height: 300,
                  child: _LoadingWidget(),
                )
              else if (!_isLoading && _sessions.isEmpty)
                SizedBox(
                  height: 300,
                  child: _buildEmpty(),
                )
              else
                ListView.builder(
                  shrinkWrap: true, // ✅ overflow fix
                  physics: const NeverScrollableScrollPhysics(), // ✅ nested scroll fix
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 30.h),
                  itemCount: _sessions.length,
                  itemBuilder: (_, i) {
                    return _buildSessionCard(i, _sessions[i]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    final totalVideos =
    _sessions.fold<int>(0, (s, e) => s + e.videos.length);
    final totalBytes = _sessions.fold<int>(
      0,
          (s, e) =>
      s + e.videos.fold<int>(0, (vs, v) => vs + v.fileSizeInBytes),
    );
    final size = totalBytes < 1024 * 1024
        ? '${(totalBytes / 1024).toStringAsFixed(1)} KB'
        : totalBytes < 1024 * 1024 * 1024
        ? '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: _kDarkCard,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2),
                blurRadius: 12.r, offset: Offset(0, 4.h)),
          ],
        ),
        child: Row(children: [
          Expanded(child: _statItem(
              Icons.folder_open_rounded, '${_sessions.length}',
              'Sessions', _kGradOrange)),
          Container(width: 1, height: 36.h,
              color: Colors.white.withOpacity(0.08),
              margin: EdgeInsets.symmetric(horizontal: 16.w)),
          Expanded(child: _statItem(
              Icons.video_library_rounded, '$totalVideos',
              'Videos', _kGradPink)),
          Container(width: 1, height: 36.h,
              color: Colors.white.withOpacity(0.08),
              margin: EdgeInsets.symmetric(horizontal: 16.w)),
          Expanded(child: _statItem(
              Icons.storage_rounded, size, 'Storage', _kGradPurple)),
        ]),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(children: [
      Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: color, size: 18.sp),
      ),
      SizedBox(height: 6.h),
      Text(value, style: TextStyle(fontSize: 14.sp,
          fontWeight: FontWeight.w800, color: Colors.white)),
      Text(label, style: TextStyle(fontSize: 11.sp,
          color: Colors.white38, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildStatusBanner() {
    final isErr = _statusMessage.toLowerCase().contains('error') ||
        _statusMessage.toLowerCase().contains('failed');
    final isDown = _controller.isBulkDownloading;
    final color = isErr ? _kErr : isDown ? _kGradCyan : _kSuccess;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        if (isDown)
          SizedBox(width: 18.w, height: 18.w,
              child: CircularProgressIndicator(strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(color)))
        else
          Icon(isErr ? Icons.error_outline : Icons.check_circle_outline,
              color: color, size: 18.sp),
        SizedBox(width: 10.w),
        Expanded(child: Text(_statusMessage,
            style: TextStyle(fontSize: 13.sp, color: color,
                fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _buildSessionCard(int index, VideoSession session) {
    final gc = _gradFor(index);
    return _PressableCard(
      gradientColors: gc,
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) =>
              VideoSessionDetailScreen(session: session),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 250), // ✅ faster
        ),
      ),
      child: Column(children: [
        // Top strip
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gc[0].withOpacity(0.25),
                gc[1].withOpacity(0.1),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: Stack(children: [
            Positioned(right: -20, top: -20,
                child: Container(width: 100.w, height: 100.w,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: gc[0].withOpacity(0.08)))),
            Positioned(right: 20, bottom: -10,
                child: Container(width: 60.w, height: 60.w,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        color: gc[1].withOpacity(0.06)))),
            SizedBox(height: 120.h,
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gc),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [BoxShadow(
                          color: gc[0].withOpacity(0.4),
                          blurRadius: 12, offset: const Offset(0, 4),
                        )],
                      ),
                      child: Icon(Icons.video_library_rounded,
                          color: Colors.white, size: 26.sp),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.displayName,
                            style: TextStyle(color: Colors.white,
                                fontSize: 16.sp, fontWeight: FontWeight.bold,
                                letterSpacing: -0.3),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          '${session.videos.length} clips • ${session.totalSize}',
                          style: TextStyle(color: gc[0], fontSize: 12.sp,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    )),
                    // ✅ Delete button — instant
                    GestureDetector(
                      onTap: () => _showDeleteDialog(session),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.delete_outline_rounded,
                            color: _kErr, size: 18.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),

        // Tags + action buttons
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 8.w, runSpacing: 6.h, children: [
                _chip(session.totalSize, gc[0]),
                _chip('${session.videos.length} clips', gc[1]),
                _chip('Tap to view', Colors.white38),
              ]),
              SizedBox(height: 12.h),
              Row(children: [
                Expanded(child: _actionBtn(
                  'Download All', Icons.download_rounded, gc,
                      () => _downloadAllVideosSimple(session),
                )),
                SizedBox(width: 10.w),
                Expanded(child: _actionBtn(
                  'View Clips', Icons.play_circle_outline, gc,
                      () => Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (_, anim, __) =>
                        VideoSessionDetailScreen(session: session),
                    transitionDuration: const Duration(milliseconds: 250),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                  )),
                  isOutlined: true,
                )),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11.sp,
        fontWeight: FontWeight.w500)),
  );

  Widget _actionBtn(String label, IconData icon, List<Color> gc,
      VoidCallback onTap, {bool isOutlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40.h,
        decoration: BoxDecoration(
          gradient: isOutlined ? null : LinearGradient(colors: gc),
          color: isOutlined ? Colors.white.withOpacity(0.06) : null,
          borderRadius: BorderRadius.circular(12.r),
          border: isOutlined ? Border.all(color: gc[0].withOpacity(0.4)) : null,
          boxShadow: isOutlined ? [] : [
            BoxShadow(color: gc[0].withOpacity(0.3),
                blurRadius: 10.r, offset: Offset(0, 3.h)),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15.sp, color: isOutlined ? gc[0] : Colors.white),
          SizedBox(width: 5.w),
          Text(label, style: TextStyle(fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: isOutlined ? gc[0] : Colors.white)),
        ]),
      ),
    );
  }

  // ✅ Delete confirm dialog
  void _showDeleteDialog(VideoSession session) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _kDarkCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: _kErr.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  color: _kErr, size: 28.sp),
            ),
            SizedBox(height: 14.h),
            Text('Delete Session',
                style: TextStyle(fontSize: 18.sp,
                    fontWeight: FontWeight.w800, color: Colors.white)),
            SizedBox(height: 8.h),
            Text(
              'Delete "${session.displayName}" and all ${session.videos.length} clips?',
              style: TextStyle(fontSize: 13.sp,
                  color: Colors.white54, height: 1.4),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Center(child: Text('Cancel',
                      style: TextStyle(fontSize: 14.sp,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600))),
                ),
              )),
              SizedBox(width: 10.w),
              Expanded(child: GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close dialog
                  _deleteSession(session); // ✅ Instant delete
                },
                child: Container(
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: _kErr,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(child: Text('Delete',
                      style: TextStyle(fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700))),
                ),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: EdgeInsets.all(32.r),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: EdgeInsets.all(28.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _kGradOrange.withOpacity(0.15),
              _kGradPink.withOpacity(0.08),
            ]),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.video_library_outlined,
              size: 48.sp, color: _kGradOrange),
        ),
        SizedBox(height: 20.h),
        Text('No Sessions Yet',
            style: TextStyle(fontSize: 20.sp,
                fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 8.h),
        Text('Split a video to see sessions here',
            style: TextStyle(fontSize: 14.sp, color: Colors.white54),
            textAlign: TextAlign.center),
        SizedBox(height: 24.h),
        Wrap(spacing: 8.w, runSpacing: 8.h, children: [
          _chip('Auto Split', _kGradOrange),
          _chip('Watermark', _kGradPink),
          _chip('30s Clips', _kGradPurple),
        ]),
      ]),
    ),
  );

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: _kDarkCard,
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_kGradOrange, _kGradPink]),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(Icons.security_rounded,
                  color: Colors.white, size: 28.sp),
            ),
            SizedBox(height: 16.h),
            Text('Permission Required',
                style: TextStyle(fontSize: 18.sp,
                    fontWeight: FontWeight.w800, color: Colors.white)),
            SizedBox(height: 8.h),
            Text('Storage permission is needed to save videos.',
                style: TextStyle(fontSize: 13.sp,
                    color: Colors.white54, height: 1.4),
                textAlign: TextAlign.center),
            SizedBox(height: 20.h),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Center(child: Text('Cancel',
                      style: TextStyle(fontSize: 14.sp,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600))),
                ),
              )),
              SizedBox(width: 10.w),
              Expanded(child: GestureDetector(
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
                  child: Center(child: Text('Open Settings',
                      style: TextStyle(fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700))),
                ),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

// Pressable card
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
        duration: const Duration(milliseconds: 100), vsync: this);
    _sc = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _pc, curve: Curves.easeOut));
  }

  @override
  void dispose() { _pc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 16.h),
    child: GestureDetector(
      onTapDown: (_) { setState(() => _pressed = true); _pc.forward(); },
      onTapUp: (_) { setState(() => _pressed = false); _pc.reverse(); widget.onTap?.call(); },
      onTapCancel: () { setState(() => _pressed = false); _pc.reverse(); },
      child: ScaleTransition(
        scale: _sc,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: _pressed
                  ? widget.gradientColors.first.withOpacity(0.5)
                  : Colors.white.withOpacity(0.07),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(color: widget.gradientColors.first.withOpacity(0.08),
                  blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: widget.child,
        ),
      ),
    ),
  );
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: EdgeInsets.all(28.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            _kGradOrange.withOpacity(0.15),
            _kGradPink.withOpacity(0.08),
          ]),
          shape: BoxShape.circle,
        ),
        child: const CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation(_kGradPink),
        ),
      ),
      SizedBox(height: 20.h),
      Text('Loading sessions...',
          style: TextStyle(fontSize: 15.sp, color: Colors.white54,
              fontWeight: FontWeight.w500)),
    ]),
  );
}