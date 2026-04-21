// ignore_for_file: avoid_print, deprecated_member_use, use_build_context_synchronously, file_names

import 'dart:io';
import 'dart:typed_data';

import 'package:auto_clipper_app/Logic/ad_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

// ─── GIF Quality Preset ───────────────────────────────────────────────────────

class GifQualityPreset {
  final String id;
  final String label;
  final String description;
  final int fps;
  final int width; // -1 = keep original
  final int colors; // palette colors
  final IconData icon;

  const GifQualityPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.fps,
    required this.width,
    required this.colors,
    required this.icon,
  });
}

final List<GifQualityPreset> _kQualityPresets = [
  GifQualityPreset(
    id: 'small',
    label: 'Small',
    description: 'Fast & tiny file, 10fps',
    fps: 10,
    width: 320,
    colors: 64,
    icon: Icons.data_saver_on,
  ),
  GifQualityPreset(
    id: 'medium',
    label: 'Medium',
    description: 'Balanced quality, 15fps',
    fps: 15,
    width: 480,
    colors: 128,
    icon: Icons.tune,
  ),
  GifQualityPreset(
    id: 'high',
    label: 'High',
    description: 'Best quality, 24fps',
    fps: 24,
    width: 640,
    colors: 256,
    icon: Icons.hd,
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class VideoToGifScreen extends StatefulWidget {
  const VideoToGifScreen({super.key});

  @override
  State<VideoToGifScreen> createState() => _VideoToGifScreenState();
}

class _VideoToGifScreenState extends State<VideoToGifScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _progressController;
  late Animation<double> _iconRotation;

  // Video state
  String? _selectedVideoPath;
  Uint8List? _thumbnail;
  double _videoDuration = 0.0;

  // Clip range (trim)
  double _startSeconds = 0;
  double _endSeconds = 10;
  static const double _maxGifDuration = 30.0; // user can pick up to 30s

  // Quality
  GifQualityPreset _selectedQuality = _kQualityPresets[1]; // medium default

  // Processing state
  bool _isPickingVideo = false;
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusText = '';
  String? _outputGifPath;
  bool _isDone = false;
  int _gifFileSizeKB = 0;


  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _iconRotation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.linear),
    );
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await [Permission.storage, Permission.videos, Permission.photos].request();
    }
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
        final vp = result.files.single.path!;
        setState(() {
          _selectedVideoPath = vp;
          _thumbnail = null;
          _videoDuration = 0;
          _startSeconds = 0;
          _endSeconds = 10;
          _isDone = false;
          _outputGifPath = null;
        });
        await _loadVideoInfo(vp);
      }
    } catch (e) {
      _showSnack('Error: $e');
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
      // Get duration via FFmpeg probe
      final session = await FFmpegKit.execute('-i "$vp" -f null -');
      final logs = await session.getAllLogsAsString() ?? '';
      final match = RegExp(
          r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})')
          .firstMatch(logs);
      double dur = 60;
      if (match != null) {
        dur = int.parse(match.group(1)!) * 3600 +
            int.parse(match.group(2)!) * 60 +
            int.parse(match.group(3)!) +
            int.parse(match.group(4)!) / 100;
      }
      final end = dur < _maxGifDuration ? dur : _maxGifDuration.toDouble();
      setState(() {
        _thumbnail = thumb;
        _videoDuration = dur;
        _startSeconds = 0;
        _endSeconds = end > 10 ? 10 : end;
      });
    } catch (e) {
      print('Error loading video info: $e');
    }
  }

  double get _clipDuration => (_endSeconds - _startSeconds).clamp(1, _maxGifDuration);

  Future<void> _convertToGif() async {
    if (_selectedVideoPath == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isDone = false;
      _outputGifPath = null;
      _progress = 0.0;
      _statusText = 'Generating color palette...';
    });

    AdService.showAdThenAction(
      onActionComplete: () async{
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final gifDir = Directory('${appDir.path}/gifs');
          if (!await gifDir.exists()) await gifDir.create(recursive: true);

          final ts = DateTime.now().millisecondsSinceEpoch;
          final palettePath = '${gifDir.path}/palette_$ts.png';
          final outputPath = '${gifDir.path}/gif_$ts.gif';

          final q = _selectedQuality;
          final scale = q.width > 0 ? 'scale=${q.width}:-1:flags=lanczos' : 'scale=-1:-1:flags=lanczos';

          // Step 1: Generate palette
          setState(() {
            _progress = 0.1;
            _statusText = 'Generating color palette...';
          });

          final paletteCmd = '-ss ${_startSeconds.toStringAsFixed(2)} '
              '-t ${_clipDuration.toStringAsFixed(2)} '
              '-i "${_selectedVideoPath!}" '
              '-vf "$scale,palettegen=max_colors=${q.colors}:stats_mode=diff" '
              '-y "$palettePath"';

          final paletteSession = await FFmpegKit.execute(paletteCmd);
          final paletteCode = await paletteSession.getReturnCode();
          if (!ReturnCode.isSuccess(paletteCode)) {
            throw Exception('Palette generation failed');
          }

          setState(() {
            _progress = 0.4;
            _statusText = 'Creating GIF frames...';
          });

          // Step 2: Generate GIF using palette
          final gifCmd = '-ss ${_startSeconds.toStringAsFixed(2)} '
              '-t ${_clipDuration.toStringAsFixed(2)} '
              '-i "${_selectedVideoPath!}" '
              '-i "$palettePath" '
              '-lavfi "$scale [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" '
              '-r ${q.fps} '
              '-y "$outputPath"';

          final gifSession = await FFmpegKit.execute(gifCmd);
          final gifCode = await gifSession.getReturnCode();
          if (!ReturnCode.isSuccess(gifCode)) {
            // Fallback: simple GIF without palette
            setState(() => _statusText = 'Trying simplified GIF...');
            await _fallbackGif(outputPath);
          }

          setState(() {
            _progress = 0.85;
            _statusText = 'Finalizing...';
          });

          // Cleanup palette
          try {
            File(palettePath).deleteSync();
          } catch (_) {}

          // Check output size
          final outputFile = File(outputPath);
          if (await outputFile.exists()) {
            final sizeBytes = await outputFile.length();
            setState(() {
              _gifFileSizeKB = (sizeBytes / 1024).round();
              _outputGifPath = outputPath;
              _progress = 1.0;
              _statusText = 'GIF ready! (${_gifFileSizeKB ~/ 1} KB)';
              _isDone = true;
              _isProcessing = false;
            });
          } else {
            throw Exception('Output GIF not found');
          }
        } catch (e) {
          setState(() {
            _isProcessing = false;
            _progress = 0;
            _statusText = 'Error: $e';
          });
          _showSnack('GIF creation failed: $e');
        }
      },
    );

  }

  Future<void> _fallbackGif(String outputPath) async {
    final q = _selectedQuality;
    final scale = q.width > 0 ? 'scale=${q.width}:-1' : '';
    final vf = scale.isNotEmpty ? '-vf "$scale"' : '';
    final cmd = '-ss ${_startSeconds.toStringAsFixed(2)} '
        '-t ${_clipDuration.toStringAsFixed(2)} '
        '-i "${_selectedVideoPath!}" '
        '$vf -r ${q.fps} -y "$outputPath"';
    await FFmpegKit.execute(cmd);
  }

  Future<void> _saveToGallery() async {
    if (_outputGifPath == null) return;
    try {
      // GallerySaver doesn't support GIF directly — save to downloads
      final downloadsDir = Directory('/storage/emulated/0/Download/AutoClipper');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final destPath =
          '${downloadsDir.path}/gif_${DateTime.now().millisecondsSinceEpoch}.gif';
      await File(_outputGifPath!).copy(destPath);
      _showSnack('GIF saved to Downloads/AutoClipper ✓');
    } catch (e) {
      _showSnack('Save failed: $e');
    }
  }

  Future<void> _shareGif() async {
    if (_outputGifPath == null) return;
    try {
      await Share.shareXFiles([XFile(_outputGifPath!)], text: 'Check this GIF!');
    } catch (e) {
      _showSnack('Share failed: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6C63FF),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  String _fmtSec(double s) {
    final m = s ~/ 60;
    final sec = (s % 60).toStringAsFixed(1);
    return m > 0 ? '${m}m ${sec}s' : '${sec}s';
  }

  @override
  void dispose() {
    _iconController.dispose();
    _progressController.dispose();
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
          icon: Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            RotationTransition(
              turns: _iconRotation,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.gif_box_outlined,
                    color: Colors.white, size: 20.sp),
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GIF Maker',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold)),
                Text('Video → Animated GIF',
                    style: TextStyle(
                        color: const Color(0xFF6C63FF),
                        fontSize: 11.sp)),
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
              // Video Picker
              _buildVideoPicker(),
              SizedBox(height: 20.h),

              if (_selectedVideoPath != null) ...[
                // Trim Range
                _buildTrimSection(),
                SizedBox(height: 20.h),

                // Quality Preset
                _buildQualitySection(),
                SizedBox(height: 20.h),

                // GIF Preview info
                _buildGifPreviewInfo(),
                SizedBox(height: 20.h),
              ],

              // Processing
              if (_isProcessing) ...[
                _buildProgressCard(),
                SizedBox(height: 20.h),
              ],

              // Done
              if (_isDone) ...[
                _buildDoneCard(),
                SizedBox(height: 20.h),
              ],

              // Convert Button
              if (!_isProcessing && !_isDone && _selectedVideoPath != null)
                _buildConvertButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPicker() {
    return GestureDetector(
      onTap: _isProcessing ? null : _pickVideo,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: _selectedVideoPath != null
                ? const Color(0xFF6C63FF).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _selectedVideoPath != null
                ? [const Color(0xFF1A1535), const Color(0xFF0F1025)]
                : [const Color(0xFF1A2535), const Color(0xFF0D1625)],
          ),
        ),
        child: _selectedVideoPath != null && _thumbnail != null
            ? _buildThumbnailPreview()
            : _buildPickerEmpty(),
      ),
    );
  }

  Widget _buildPickerEmpty() {
    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C63FF).withOpacity(0.2),
                  const Color(0xFFFF6584).withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.gif_box_outlined,
                color: const Color(0xFF6C63FF), size: 36.sp),
          ),
          SizedBox(height: 14.h),
          Text('Select Video to Make GIF',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 6.h),
          Text('MP4, MOV, AVI • Up to 30s clip',
              style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildThumbnailPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: Image.memory(_thumbnail!,
              width: double.infinity,
              height: 180.h,
              fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12.h,
          left: 12.w,
          right: 12.w,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  path.basename(_selectedVideoPath!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600),
                ),
              ),
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text('Change',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 12.h,
          right: 12.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(_fmtSec(_videoDuration),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }

  Widget _buildTrimSection() {
    final maxEnd = _videoDuration.clamp(1, _maxGifDuration).toDouble();
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.content_cut,
                  color: const Color(0xFF6C63FF), size: 16.sp),
              SizedBox(width: 8.w),
              Text('Trim Clip',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${_fmtSec(_startSeconds)} → ${_fmtSec(_endSeconds)}  (${_clipDuration.toStringAsFixed(1)}s)',
                  style: TextStyle(
                      color: const Color(0xFF6C63FF),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Start slider
          _sliderRow(
            'Start',
            _startSeconds,
            0,
            (_endSeconds - 1).clamp(0, maxEnd),
                (v) => setState(() => _startSeconds = v),
            Colors.green,
          ),
          SizedBox(height: 10.h),

          // End slider
          _sliderRow(
            'End',
            _endSeconds,
            (_startSeconds + 1).clamp(1, maxEnd),
            maxEnd,
                (v) => setState(() => _endSeconds = v),
            const Color(0xFFFF6584),
          ),

          if (_clipDuration > _maxGifDuration) ...[
            SizedBox(height: 8.h),
            Text(
              '⚠️ Max $_maxGifDuration seconds recommended for GIF',
              style: TextStyle(
                  color: Colors.orange, fontSize: 11.sp),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sliderRow(String label, double value, double min, double max,
      ValueChanged<double> onChanged, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 36.w,
          child: Text(label,
              style:
              TextStyle(color: Colors.white54, fontSize: 11.sp)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: Colors.white10,
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36.w,
          child: Text(
            _fmtSec(value),
            textAlign: TextAlign.right,
            style: TextStyle(
                color: color, fontSize: 11.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildQualitySection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.high_quality_outlined,
                  color: const Color(0xFF6C63FF), size: 16.sp),
              SizedBox(width: 8.w),
              Text('Quality',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: _kQualityPresets.map((q) {
              final selected = _selectedQuality.id == q.id;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedQuality = q),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    padding: EdgeInsets.symmetric(
                        vertical: 12.h, horizontal: 6.w),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF5A52E0)],
                      )
                          : null,
                      color: selected ? null : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF6C63FF)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(q.icon,
                            color: selected
                                ? Colors.white
                                : Colors.white38,
                            size: 18.sp),
                        SizedBox(height: 6.h),
                        Text(q.label,
                            style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.white54,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold)),
                        Text('${q.fps}fps',
                            style: TextStyle(
                                color: selected
                                    ? Colors.white70
                                    : Colors.white24,
                                fontSize: 10.sp)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 8.h),
          Text(
            _selectedQuality.description,
            style: TextStyle(
                color: const Color(0xFF6C63FF).withOpacity(0.8),
                fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildGifPreviewInfo() {
    final q = _selectedQuality;
    final estFrames = (_clipDuration * q.fps).round();
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.1),
            const Color(0xFFFF6584).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoChip(Icons.timer_outlined, 'Duration',
              '${_clipDuration.toStringAsFixed(1)}s'),
          _infoChip(Icons.movie_filter_outlined, 'Frames', '$estFrames'),
          _infoChip(Icons.aspect_ratio, 'Size',
              '${q.width > 0 ? '${q.width}px' : 'Original'}'),
          _infoChip(Icons.palette_outlined, 'Colors', '${q.colors}'),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 18.sp),
        SizedBox(height: 4.h),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                  AlwaysStoppedAnimation(Color(0xFF6C63FF)),
                ),
              ),
              SizedBox(width: 10.w),
              Text('Creating GIF...',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(_progress * 100).round()}%',
                  style: TextStyle(
                      color: const Color(0xFF6C63FF),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 14.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
              minHeight: 8.h,
            ),
          ),
          SizedBox(height: 10.h),
          Text(_statusText,
              style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
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
            const Color(0xFF6C63FF).withOpacity(0.15),
            const Color(0xFFFF6584).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.4)),
      ),
      child: Column(
        children: [
          // GIF badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFFF6584)]),
              borderRadius: BorderRadius.circular(40.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gif_box, color: Colors.white, size: 24.sp),
                SizedBox(width: 8.w),
                Text('GIF Created!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chipStat('Duration', '${_clipDuration.toStringAsFixed(1)}s'),
              SizedBox(width: 16.w),
              _chipStat('File Size', '$_gifFileSizeKB KB'),
              SizedBox(width: 16.w),
              _chipStat('Quality', _selectedQuality.label),
            ],
          ),
          SizedBox(height: 18.h),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  'Save to Downloads',
                  Icons.download,
                  const Color(0xFF6C63FF),
                  _saveToGallery,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _actionBtn(
                  'Share GIF',
                  Icons.share_outlined,
                  const Color(0xFFFF6584),
                  _shareGif,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: () => setState(() {
              _isDone = false;
              _selectedVideoPath = null;
              _thumbnail = null;
              _outputGifPath = null;
              _progress = 0;
              _videoDuration = 0;
              _startSeconds = 0;
              _endSeconds = 10;
            }),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: Colors.white54, size: 16.sp),
                  SizedBox(width: 6.w),
                  Text('Make Another GIF',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipStat(String l, String v) {
    return Column(
      children: [
        Text(v,
            style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold)),
        Text(l,
            style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
      ],
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16.sp),
            SizedBox(width: 6.w),
            Text(label,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildConvertButton() {
    return GestureDetector(
      onTap: _convertToGif,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFFFF6584)]),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gif_box_outlined, color: Colors.white, size: 22.sp),
            SizedBox(width: 10.w),
            Text(
              'Convert to GIF  •  ${_clipDuration.toStringAsFixed(1)}s',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}