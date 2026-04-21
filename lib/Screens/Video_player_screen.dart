// ignore_for_file: deprecated_member_use, sized_box_for_whitespace, library_private_types_in_public_api, file_names

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

// ─── Dark palette ─────────────────────────────────────────────────────────────
const _kDarkBg     = Color(0xFF0A0E1A);
const _kDarkCard   = Color(0xFF111827);
const _kGradOrange = Color(0xFFFF6B35);
const _kGradPink   = Color(0xFFE91E63);
const _kGradPurple = Color(0xFF9C27B0);

const _primaryGradient = LinearGradient(
  colors: [_kGradOrange, _kGradPink, _kGradPurple],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  const VideoPlayerWidget({super.key, required this.videoPath});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late AnimationController _controlsController;
  late Animation<double> _controlsAnimation;

  bool _isPlaying     = false;
  bool _isInitialized = false;
  bool _showControls  = true;

  // ✅ FIX 1: Remove manual position strings — use ValueListenableBuilder
  // No more _currentPosition / _totalDuration string fields

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _scaleController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _controlsController = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack));
    _controlsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controlsController, curve: Curves.easeOut));

    _controlsController.forward();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.file(File(widget.videoPath));
    _controller.initialize().then((_) {
      if (!mounted) return;

      // ✅ FIX 2: setState BEFORE play() — UI reflects initialized state first
      setState(() => _isInitialized = true);

      _fadeController.forward();
      _scaleController.forward();

      // ✅ FIX 3: addListener BEFORE play() — captures all events
      _controller.addListener(_onVideoUpdate);

      _controller.play();
      if (mounted) setState(() => _isPlaying = true);

      _scheduleHideControls();
    }).catchError((e) {
      debugPrint('❌ Video init error: $e');
    });
  }

  // ✅ FIX 4: Renamed + cleaner listener — no setState for position
  // Position updates via ValueListenableBuilder (no rebuild needed)
  void _onVideoUpdate() {
    if (!mounted) return;

    final value = _controller.value;

    // ✅ BUG FIX: Video finish detection — position >= duration check add કર્યો
    final isFinished = value.position >= value.duration && value.duration > Duration.zero;

    if ((!value.isPlaying && _isPlaying) || isFinished) {
      setState(() {
        _isPlaying = false;
        _showControls = true;
      });
      _controlsController.forward();
    }

    if (value.hasError) {
      debugPrint('❌ Video error: ${value.errorDescription}');
    }
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    setState(() {
      if (_isPlaying) {
        _controller.pause();
        _isPlaying = false;
        // Keep controls visible when paused
        _showControls = true;
        _controlsController.forward();
      } else {
        _controller.play();
        _isPlaying = true;
        _scheduleHideControls();
      }
    });
  }

  void _toggleControls() {
    if (!_isInitialized) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _controlsController.forward();
      if (_isPlaying) _scheduleHideControls();
    } else {
      _controlsController.reverse();
    }
  }

  void _scheduleHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying && _showControls) {
        setState(() => _showControls = false);
        _controlsController.reverse();
        // ✅ BUG FIX: _togglePlayPause() અહીં ન કરવો — video pause ન થવો જોઈએ
      }
    });
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kDarkBg,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isInitialized)
              _buildLoading()
            else ...[
              // ✅ AnimatedBuilder — fade + scale on init
              AnimatedBuilder(
                animation:
                Listenable.merge([_fadeAnimation, _scaleAnimation]),
                builder: (_, __) => Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _buildVideoPlayer(),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _buildProgressBar(),
              SizedBox(height: 10.h),
              _buildControls(),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Loading ──────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Container(
      height: 240.h,
      decoration: BoxDecoration(
        color: _kDarkCard,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3),
              blurRadius: 20.r, offset: Offset(0, 8.h)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
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
          SizedBox(height: 16.h),
          Text('Loading Video...',
              style: TextStyle(fontSize: 15.sp,
                  fontWeight: FontWeight.w600, color: Colors.white54)),
        ],
      ),
    );
  }

  // ─── Video player ─────────────────────────────────────────────────────────

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
              color: _kGradPink.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(color: _kGradPink.withOpacity(0.15),
                blurRadius: 30.r, offset: Offset(0, 12.h)),
            BoxShadow(color: _kGradOrange.withOpacity(0.10),
                blurRadius: 50.r, offset: Offset(0, 20.h)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: Stack(children: [
            // Video frame
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.50),
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),

            // Bottom gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // ✅ FIX 6: Center play/pause — AnimatedSwitcher for smooth icon change
            Positioned.fill(
              child: FadeTransition(
                opacity: _controlsAnimation,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          gradient: _primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: _kGradPink.withOpacity(0.5),
                                blurRadius: 20.r),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey(_isPlaying), // ✅ key for AnimatedSwitcher
                            color: Colors.white,
                            size: 32.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Progress bar ─────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.h,
            activeTrackColor: _kGradPink,
            inactiveTrackColor: Colors.white.withOpacity(0.12),
            thumbColor: Colors.white,
            overlayColor: _kGradPink.withOpacity(0.2),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
          ),
          // ✅ FIX 7: ValueListenableBuilder — slider updates WITHOUT setState
          child: ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller,
            builder: (_, value, __) {
              final total = value.duration.inMilliseconds;
              final pos   = value.position.inMilliseconds;
              return Slider(
                value: total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0,
                onChanged: (v) {
                  // ✅ BUG FIX: Seek only — _togglePlayPause() દૂર કર્યો
                  _controller.seekTo(
                      Duration(milliseconds: (v * total).round()));
                },
                onChangeStart: (_) {
                  setState(() => _showControls = true);
                  _controlsController.forward();
                },
                onChangeEnd: (_) {
                  if (_isPlaying) _scheduleHideControls();
                },
              );
            },
          ),
        ),

        SizedBox(height: 2.h),

        // ✅ FIX 8: Time display via ValueListenableBuilder — no setState needed
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: _controller,
          builder: (_, value, __) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(value.position),
                    style: TextStyle(color: Colors.white38, fontSize: 12.sp,
                        fontWeight: FontWeight.w600)),
                Text(_fmt(value.duration),
                    style: TextStyle(color: Colors.white38, fontSize: 12.sp,
                        fontWeight: FontWeight.w600)),
              ],
            );
          },
        ),
      ]),
    );
  }

  // ─── Controls ─────────────────────────────────────────────────────────────

  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: _kDarkCard,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1.5),
        boxShadow: [
          BoxShadow(color: _kGradPink.withOpacity(0.08),
              blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // -10s
          _ctrlBtn(
            icon: Icons.replay_10,
            onTap: () {
              final pos  = _controller.value.position;
              final next = pos - const Duration(seconds: 10);
              _controller.seekTo(
                  next > Duration.zero ? next : Duration.zero);
              _scheduleHideControls();
            },
          ),
          SizedBox(width: 12.w),

          // ✅ Play/Pause — AnimatedSwitcher for smooth icon change
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: _primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _kGradPink.withOpacity(0.4),
                      blurRadius: 16.r, offset: Offset(0, 6.h)),
                  BoxShadow(color: _kGradOrange.withOpacity(0.2),
                      blurRadius: 30.r, offset: Offset(0, 10.h)),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  key: ValueKey(_isPlaying), // ✅ required for AnimatedSwitcher
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // +10s
          _ctrlBtn(
            icon: Icons.forward_10,
            onTap: () {
              final pos   = _controller.value.position;
              final total = _controller.value.duration;
              final next  = pos + const Duration(seconds: 10);
              _controller.seekTo(next < total ? next : total);
              _scheduleHideControls();
            },
          ),
          SizedBox(width: 12.w),

          // Replay
          _ctrlBtn(
            icon: Icons.replay_rounded,
            color: _kGradOrange,
            onTap: () {
              _controller.seekTo(Duration.zero);
              _controller.play();
              setState(() => _isPlaying = true);
              _scheduleHideControls();
            },
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn({
    required IconData icon,
    required VoidCallback onTap,
    double size = 22,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Icon(icon, size: size.sp, color: color ?? Colors.white54),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _controlsController.dispose();
    super.dispose();
  }
}