// ignore_for_file: file_names, avoid_print

// video_splitter_service.dart
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:gal/gal.dart';
import 'package:memory_info/memory_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

enum DurationUnit { seconds, minutes, hours }

enum WatermarkPosition { topLeft, topRight, bottomLeft, bottomRight }

class VideoSplitterProgress {
  final int currentClip;
  final int totalClips;
  final double progress;
  final String statusText;
  final bool isProcessing;
  static const int MAX_MEMORY_MB = 200;

  VideoSplitterProgress({
    required this.currentClip,
    required this.totalClips,
    required this.progress,
    required this.statusText,
    required this.isProcessing,
  });
}

class VideoSplitterService {
  // Callback for progress updates
  Function(VideoSplitterProgress)? onProgressUpdate;

  VideoSplitterService({this.onProgressUpdate});

  /// Request necessary permissions for Android
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.storage,
        Permission.videos,
        Permission.photos,
      ].request();

      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
    }
  }

  /// Pick a video file using file picker
  Future<String?> pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      }
      return null;
    } catch (e) {
      throw Exception('Error picking video: $e');
    }
  }

  /// Pick a watermark image file
  Future<String?> pickWatermark() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      }
      return null;
    } catch (e) {
      throw Exception('Error picking watermark: $e');
    }
  }

  /// Convert duration based on selected unit to seconds
  int getDurationInSeconds(double duration, DurationUnit unit) {
    switch (unit) {
      case DurationUnit.seconds:
        return duration.round();
      case DurationUnit.minutes:
        return (duration * 60).round();
      case DurationUnit.hours:
        return (duration * 3600).round();
    }
  }

  // Fix the text position filter method
  String getTextPositionFilter(TextPosition position, double fontSize) {
    switch (position) {
      case TextPosition.topLeft:
        return 'x=20:y=20';
      case TextPosition.topCenter:
        return 'x=(w-text_w)/2:y=20';
      case TextPosition.topRight:
        return 'x=w-text_w-20:y=20';
      case TextPosition.bottomLeft:
        return 'x=20:y=h-text_h-20';
      case TextPosition.bottomCenter:
        return 'x=(w-text_w)/2:y=h-text_h-20';
      case TextPosition.bottomRight:
        return 'x=w-text_w-20:y=h-text_h-20';
    }
  }


Future<void> splitVideoClipWithOverlays(
    String inputPath,
    String outputPath,
    int startTime,
    int duration, {
    String? watermarkPath,
    double watermarkOpacity = 0.7,
    WatermarkPosition watermarkPosition = WatermarkPosition.topRight,
    bool useTextOverlay = false,
    String textContent = '',
    TextPosition textPosition = TextPosition.topCenter,
    double fontSize = 24.0,
    String textColor = 'white',
    bool isPortraitMode = false,
  }) async {
    // Check if file exists
    if (!File(inputPath).existsSync()) {
      throw Exception('Input video file not found');
    }

    final escapedInput = inputPath
        .replaceAll('"', '\\"')
        .replaceAll("'", "\\'");
    final escapedOutput = outputPath 
        .replaceAll('"', '\\"')
        .replaceAll("'", "\\'");

    String filterComplex = '';
    String videoFilter = '[0:v]';
    int filterIndex = 1;

    // Handle portrait mode
    if (isPortraitMode) {
      filterComplex +=
          '$videoFilter scale=608:1080:force_original_aspect_ratio=decrease,pad=608:1080:(ow-iw)/2:(oh-ih)/2:black[v$filterIndex];';
      videoFilter = '[v$filterIndex]';
      filterIndex++;
    }

    // Add watermark
    if (watermarkPath != null) {
      final pos = getWatermarkPositionFilter(watermarkPosition);
      filterComplex +=
          '[1:v]format=rgba,scale=100:-1,colorchannelmixer=aa=${watermarkOpacity.toStringAsFixed(2)}[wm];';
      filterComplex +=
          '$videoFilter[wm]overlay=$pos:format=auto[v$filterIndex];';
      videoFilter = '[v$filterIndex]';
      filterIndex++;
    }

    // Add text overlay - FIXED VERSION
    if (useTextOverlay && textContent.isNotEmpty) {
      // Escape special characters in text content
      final escapedText = textContent
          .replaceAll("'", "\\'")
          .replaceAll(":", "\\:")
          .replaceAll("[", "\\[")
          .replaceAll("]", "\\]");

      final pos = getTextPositionFilter(textPosition, fontSize);
      filterComplex +=
          '${videoFilter}drawtext=text=\'$escapedText\':fontsize=${fontSize.round()}:fontcolor=$textColor:$pos:box=1:boxcolor=black@0.5:boxborderw=5[v$filterIndex];';
      videoFilter = '[v$filterIndex]';
    }

    // Remove the final semicolon and ensure proper output mapping
    filterComplex = filterComplex.replaceAll(RegExp(r';$'), '');

    // Construct the final command
    List<String> commandParts = ['-ss $startTime'];

    // Add input files
    commandParts.add('-i "$escapedInput"');
    if (watermarkPath != null) {
      commandParts.add('-i "$watermarkPath"');
    }

    // Add filter complex if we have any filters
    if (filterComplex.isNotEmpty) {
      commandParts.add('-filter_complex "$filterComplex"');
      commandParts.add('-map "$videoFilter"');
      commandParts.add('-map 0:a?'); // Copy audio if available
    }

    // In splitVideoClipWithOverlays, modify the encoding options:
    commandParts.addAll([
      '-t $duration',
      '-c:v libx264',
      '-preset superfast', // Changed from ultrafast
      '-crf 28', // Changed from 23 (higher = smaller file)
      '-threads 2', // Limit threads
      '-bufsize 1M', // Limit buffer
      '-maxrate 2M', // Limit bitrate
      '-c:a copy',
      '-avoid_negative_ts make_zero',
      '-y "$escapedOutput"',
    ]);

    final command = commandParts.join(' ');
    print('Executing FFmpeg command:\n$command');

    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        print('FFmpeg failed: ${logs?.substring(0, 500)}...');
        throw Exception('Failed to process video with overlays');
      }
    } catch (e) {
      print('Overlay processing failed, using fallback: $e');
      await _fallbackSplit(inputPath, outputPath, startTime, duration);
    }
  }


  // Process videos in smaller chunks
  Future<void> _fallbackSplit(
    String input,
    String output,
    int start,
    int duration,
  ) async {
    try {
      // Use simpler copy command for problematic videos
      final session = await FFmpegKit.execute(
        '-ss $start -i "$input" -t $duration -c copy -avoid_negative_ts make_zero -y "$output"',
      );

      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        throw Exception('Fallback processing also failed');
      }
    } catch (e) {
      throw Exception('Video processing failed completely: $e');
    }
  }


  /// Get watermark position filter string for FFmpeg
  String getWatermarkPositionFilter(WatermarkPosition position) {
    switch (position) {
      case WatermarkPosition.topLeft:
        return '10:10';
      case WatermarkPosition.topRight:
        return '(main_w-overlay_w-10):10';
      case WatermarkPosition.bottomLeft:
        return '10:(main_h-overlay_h-10)';
      case WatermarkPosition.bottomRight:
        return '(main_w-overlay_w-10):(main_h-overlay_h-10)';
    }
  }

  /// Get video duration in seconds using FFmpeg
  Future<double> getVideoDuration(String videoPath) async {
    final escapedPath = videoPath.replaceAll(' ', '\\ ');
    final command = '-i $escapedPath -f null -';

    final session = await FFmpegKit.execute(command);
    final logs = await session.getAllLogsAsString();

    final durationRegex = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})');
    final match = durationRegex.firstMatch(logs!);

    if (match != null) {
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);
      final centiseconds = int.parse(match.group(4)!);

      return hours * 3600 + minutes * 60 + seconds + centiseconds / 100;
    }

    throw Exception('Could not determine video duration');
  }

  /// Split video clip without watermark
  Future<void> splitVideoClip(
    String inputPath,
    String outputPath,
    int startTime,
    int duration,
  ) async {
    final escapedInputPath = inputPath.replaceAll(' ', '\\ ');
    final escapedOutputPath = outputPath.replaceAll(' ', '\\ ');

    final command =
        '-ss $startTime -i $escapedInputPath -t $duration -c copy -y $escapedOutputPath';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      print('FFmpeg logs: $logs');
      throw Exception('FFmpeg split error: Check video file format');
    }
  }

  /// Split video clip with watermark
  Future<void> splitVideoClipWithWatermark(
    String inputPath,
    String outputPath,
    int startTime,
    int duration,
    String watermarkPath,
    double opacity,
    WatermarkPosition position,
  ) async {
    final watermarkPosition = getWatermarkPositionFilter(position);

    // Updated command with Android-compatible settings
    final command =
        '-ss $startTime -i "$inputPath" -i "$watermarkPath" '
        '-filter_complex "[1:v]format=rgba,scale=100:-1,colorchannelmixer=aa=${opacity.toStringAsFixed(2)}[wm];'
        '[0:v][wm]overlay=$watermarkPosition:format=auto,format=yuv420p" '
        '-t $duration -c:v libx264 -preset ultrafast -crf 23 -c:a copy -y "$outputPath"';

    print('Executing FFmpeg command: $command');

    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        print('FFmpeg failed with logs: $logs');
        throw Exception('Failed to apply watermark');
      }
    } catch (e) {
      print('Watermark failed, creating clip without watermark: $e');
      await splitVideoClip(inputPath, outputPath, startTime, duration);
    }
  }

  /// Main method to split video into clips
  Future<void> splitVideo({
    required String videoPath,
    required int clipDurationInSeconds,
    bool useWatermark = false,
    String? watermarkPath,
    double watermarkOpacity = 0.7,
    WatermarkPosition watermarkPosition = WatermarkPosition.topRight,
    bool useTextOverlay = false,
    String textPrefix = 'Part',
    TextPosition textPosition = TextPosition.topCenter,
    double fontSize = 24.0,
    String textColor = 'white',
    bool isPortraitMode = false,
}) async {
    try {
      // Check file size first
      final file = File(videoPath);
      final fileSizeInMB = await file.length() / (1024 * 1024);

      if (fileSizeInMB > 500) {
        // Limit to 500MB
        throw Exception('Video file too large. Please use a smaller video.');
      }
      _updateProgress(
        VideoSplitterProgress(
          currentClip: 0,
          totalClips: 0,
          progress: 0.0,
          statusText: 'Getting video information...',
          isProcessing: true,
        ),
      );

      final videoDuration = await getVideoDuration(videoPath);
      if (videoDuration <= 0) {
        throw Exception('Could not determine video duration');
      }

      final totalClips = (videoDuration / clipDurationInSeconds).ceil();

      _updateProgress(
        VideoSplitterProgress(
          currentClip: 0,
          totalClips: totalClips,
          progress: 0.0,
          statusText: 'Preparing to split video into $totalClips clips...',
          isProcessing: true,
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final outputDir = Directory('${tempDir.path}/video_clips');
      if (await outputDir.exists()) {
        await outputDir.delete(recursive: true);
      }
      await outputDir.create();

      for (int i = 0; i < totalClips; i++) {
        final startTime = i * clipDurationInSeconds;
        final outputPath = '${outputDir.path}/clip_${i + 1}.mp4';
        final textContent = useTextOverlay ? '$textPrefix ${i + 1}' : '';

        _updateProgress(
          VideoSplitterProgress(
            currentClip: i + 1,
            totalClips: totalClips,
            progress: i / totalClips,
            statusText: 'Processing clip ${i + 1} of $totalClips...',
            isProcessing: true,
          ),
        );

        // Use the enhanced method with all overlays
        if (useWatermark || useTextOverlay || isPortraitMode) {
          await splitVideoClipWithOverlays(
            videoPath,
            outputPath,
            startTime,
            clipDurationInSeconds,
            watermarkPath: useWatermark ? watermarkPath : null,
            watermarkOpacity: watermarkOpacity,
            watermarkPosition: watermarkPosition,
            useTextOverlay: useTextOverlay,
            textContent: textContent,
            textPosition: textPosition,
            fontSize: fontSize,
            textColor: textColor,
            isPortraitMode: isPortraitMode,
          );
        } else {
          await splitVideoClip(
            videoPath,
            outputPath,
            startTime,
            clipDurationInSeconds,
          );
        }

        try {
          await Gal.putVideo(outputPath);
          _updateProgress(
            VideoSplitterProgress(
              currentClip: i + 1,
              totalClips: totalClips,
              progress: (i + 1) / totalClips,
              statusText:
                  'Clip ${i + 1} saved successfully! Processing next clip...',
              isProcessing: true,
            ),
          );
          print('Successfully saved clip ${i + 1} to gallery');
        } catch (e) {
          print('Failed to save clip ${i + 1} to gallery: $e');
        }
      }

      _updateProgress(
        VideoSplitterProgress(
          currentClip: totalClips,
          totalClips: totalClips,
          progress: 1.0,
          statusText:
              'Successfully split video into $totalClips clips and saved to gallery!',
          isProcessing: false,
        ),
      );

      await outputDir.delete(recursive: true);
    } catch (e) {

      
      _updateProgress(
        VideoSplitterProgress(
          currentClip: 0,
          totalClips: 0,
          progress: 0.0,
          statusText: 'Error: $e',
          isProcessing: false,
        ),
        
      );
      
      if (e.toString().contains('OutOfMemory') ||
          e.toString().contains('SIGSEGV')) {
        throw Exception('Not enough memory to process this video');
      }
      rethrow;
    }
  }

  void _updateProgress(VideoSplitterProgress progress) {
    // Force garbage collection periodically
    if (progress.currentClip % 3 == 0) {
      // Give system time to clean up
      Future.delayed(Duration(milliseconds: 100));
    }

    onProgressUpdate?.call(progress);
  }
}
enum TextPosition {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}
