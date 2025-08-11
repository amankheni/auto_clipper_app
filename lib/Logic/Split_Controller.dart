// ignore_for_file: file_names, avoid_print, constant_identifier_names

// video_splitter_service.dart

import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
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
      '-preset veryfast', // Changed from superfast
      '-crf 30', // Higher compression for large files
      '-threads 1', // Reduced threads to save memory
      '-bufsize 512k', // Smaller buffer
      '-maxrate 1M', // Lower bitrate for large files
      '-pix_fmt yuv420p', // Force compatible pixel format
      '-movflags +faststart', // Optimize for streaming
      '-c:a aac', // Re-encode audio to save space
      '-b:a 128k', // Lower audio bitrate
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

      // Updated file size limit
      if (fileSizeInMB > 2000) {
        throw Exception(
          'Video file too large. Please use a smaller video (max 2GB).',
        );
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

      // Adjust clip duration for very large files
      int adjustedClipDuration = clipDurationInSeconds;
      if (fileSizeInMB > 1000) {
        adjustedClipDuration = math.min(
          clipDurationInSeconds,
          300,
        ); // Max 5 min clips for large videos
      }

      final totalClips = (videoDuration / adjustedClipDuration).ceil();

      _updateProgress(
        VideoSplitterProgress(
          currentClip: 0,
          totalClips: totalClips,
          progress: 0.0,
          statusText: 'Preparing to split video into $totalClips clips...',
          isProcessing: true,
        ),
      );

      // Create session directory
      final sessionDir = await _createVideoSession();

      // Choose processing method based on file size
      if (fileSizeInMB > 1000) {
        // Use chunked processing for large videos (>1GB)
        await _processLargeVideo(
          videoPath: videoPath,
          clipDurationInSeconds: adjustedClipDuration,
          videoDuration: videoDuration,
          sessionDir: sessionDir,
          totalClips: totalClips,
          fileSizeInMB: fileSizeInMB,
          useWatermark: useWatermark,
          watermarkPath: watermarkPath,
          watermarkOpacity: watermarkOpacity,
          watermarkPosition: watermarkPosition,
          useTextOverlay: useTextOverlay,
          textPrefix: textPrefix,
          textPosition: textPosition,
          fontSize: fontSize,
          textColor: textColor,
          isPortraitMode: isPortraitMode,
        );
      } else {
        // Use standard processing for smaller videos
        await _processStandardVideo(
          videoPath: videoPath,
          clipDurationInSeconds: adjustedClipDuration,
          sessionDir: sessionDir,
          totalClips: totalClips,
          useWatermark: useWatermark,
          watermarkPath: watermarkPath,
          watermarkOpacity: watermarkOpacity,
          watermarkPosition: watermarkPosition,
          useTextOverlay: useTextOverlay,
          textPrefix: textPrefix,
          textPosition: textPosition,
          fontSize: fontSize,
          textColor: textColor,
          isPortraitMode: isPortraitMode,
        );
      }

      _updateProgress(
        VideoSplitterProgress(
          currentClip: totalClips,
          totalClips: totalClips,
          progress: 1.0,
          statusText:
              'Successfully split video into $totalClips clips! Check Downloads section.',
          isProcessing: false,
        ),
      );
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
          e.toString().contains('SIGSEGV') ||
          e.toString().contains('No space left')) {
        throw Exception('Not enough memory or storage to process this video');
      }
      rethrow;
    }
  }

  // New method for processing large videos in batches
  Future<void> _processLargeVideo({
    required String videoPath,
    required int clipDurationInSeconds,
    required double videoDuration,
    required Directory sessionDir,
    required int totalClips,
    required double fileSizeInMB,
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
    // Determine batch size based on file size
    int batchSize;
    if (fileSizeInMB > 1500) {
      batchSize = 1; // Process one clip at a time for very large files
    } else if (fileSizeInMB > 1000) {
      batchSize = 2; // Process 2 clips at a time
    } else {
      batchSize = 3; // Process 3 clips at a time
    }

    print('Processing large video in batches of $batchSize clips');

    for (int batchStart = 0; batchStart < totalClips; batchStart += batchSize) {
      final batchEnd = math.min(batchStart + batchSize, totalClips);

      print('Processing batch: clips ${batchStart + 1} to $batchEnd');

      // Process current batch
      for (int i = batchStart; i < batchEnd; i++) {
        final startTime = i * clipDurationInSeconds;
        final outputPath = '${sessionDir.path}/clip_${i + 1}.mp4';
        final textContent = useTextOverlay ? '$textPrefix ${i + 1}' : '';

        _updateProgress(
          VideoSplitterProgress(
            currentClip: i + 1,
            totalClips: totalClips,
            progress: i / totalClips,
            statusText:
                'Processing large video: clip ${i + 1} of $totalClips...',
            isProcessing: true,
          ),
        );

        try {
          // Process video clip with memory-efficient settings
          if (useWatermark || useTextOverlay || isPortraitMode) {
            await _splitVideoClipWithOverlaysMemoryOptimized(
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
            await _splitVideoClipMemoryOptimized(
              videoPath,
              outputPath,
              startTime,
              clipDurationInSeconds,
            );
          }

          // Memory cleanup after each clip for very large files
          if (fileSizeInMB > 1500) {
            await Future.delayed(Duration(milliseconds: 1000));
          } else if (i > 0 && i % 2 == 0) {
            await Future.delayed(Duration(milliseconds: 500));
          }
        } catch (e) {
          print('Failed to process clip ${i + 1}: $e');
          // Try fallback method
          await _fallbackSplit(
            videoPath,
            outputPath,
            startTime,
            clipDurationInSeconds,
          );
        }

        _updateProgress(
          VideoSplitterProgress(
            currentClip: i + 1,
            totalClips: totalClips,
            progress: (i + 1) / totalClips,
            statusText: 'Large video: Clip ${i + 1} processed successfully!',
            isProcessing: true,
          ),
        );
      }

      // Longer pause between batches for memory cleanup
      if (batchEnd < totalClips) {
        print('Batch completed. Waiting for memory cleanup...');
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }


  // Memory-optimized version for large videos
  Future<void> _splitVideoClipMemoryOptimized(
    String inputPath,
    String outputPath,
    int startTime,
    int duration,
  ) async {
    final escapedInput = inputPath
        .replaceAll('"', '\\"')
        .replaceAll("'", "\\'");
    final escapedOutput = outputPath
        .replaceAll('"', '\\"')
        .replaceAll("'", "\\'");

    // Ultra-low memory settings for large files
    final command =
        '-ss $startTime -i "$escapedInput" -t $duration '
        '-c:v libx264 -preset veryfast -crf 32 '
        '-threads 1 -bufsize 256k -maxrate 800k '
        '-c:a aac -b:a 96k -ac 1 '
        '-movflags +faststart -avoid_negative_ts make_zero -y "$escapedOutput"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      print('FFmpeg split error: ${logs?.substring(0, 300)}...');
      throw Exception('FFmpeg split error for large video');
    }
  }

  // Memory-optimized overlays for large videos
  Future<void> _splitVideoClipWithOverlaysMemoryOptimized(
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
          '[1:v]format=rgba,scale=80:-1,colorchannelmixer=aa=${watermarkOpacity.toStringAsFixed(2)}[wm];';
      filterComplex +=
          '$videoFilter[wm]overlay=$pos:format=auto[v$filterIndex];';
      videoFilter = '[v$filterIndex]';
      filterIndex++;
    }

    // Add text overlay
    if (useTextOverlay && textContent.isNotEmpty) {
      final escapedText = textContent
          .replaceAll("'", "\\'")
          .replaceAll(":", "\\:")
          .replaceAll("[", "\\[")
          .replaceAll("]", "\\]");

      final pos = getTextPositionFilter(textPosition, fontSize);
      filterComplex +=
          '${videoFilter}drawtext=text=\'$escapedText\':fontsize=${fontSize.round()}:fontcolor=$textColor:$pos:box=1:boxcolor=black@0.5:boxborderw=3[v$filterIndex];';
      videoFilter = '[v$filterIndex]';
    }

    filterComplex = filterComplex.replaceAll(RegExp(r';$'), '');

    List<String> commandParts = ['-ss $startTime'];
    commandParts.add('-i "$escapedInput"');

    if (watermarkPath != null) {
      commandParts.add('-i "$watermarkPath"');
    }

    if (filterComplex.isNotEmpty) {
      commandParts.add('-filter_complex "$filterComplex"');
      commandParts.add('-map "$videoFilter"');
      commandParts.add('-map 0:a?');
    }

    // Ultra memory-efficient settings for large videos
    commandParts.addAll([
      '-t $duration',
      '-c:v libx264',
      '-preset veryfast',
      '-crf 34', // Higher compression
      '-threads 1', // Single thread
      '-bufsize 128k', // Very small buffer
      '-maxrate 600k', // Lower bitrate
      '-c:a aac',
      '-b:a 96k', // Lower audio bitrate
      '-ac 1', // Mono audio to save space
      '-movflags +faststart',
      '-avoid_negative_ts make_zero',
      '-y "$escapedOutput"',
    ]);

    final command = commandParts.join(' ');

    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        print('FFmpeg overlay failed: ${logs?.substring(0, 300)}...');
        throw Exception('Failed to process video with overlays');
      }
    } catch (e) {
      print('Overlay processing failed for large video: $e');
      await _splitVideoClipMemoryOptimized(
        inputPath,
        outputPath,
        startTime,
        duration,
      );
    }
  }


Future<void> _processStandardVideo({
    required String videoPath,
    required int clipDurationInSeconds,
    required Directory sessionDir,
    required int totalClips,
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
    for (int i = 0; i < totalClips; i++) {
      final startTime = i * clipDurationInSeconds;
      final outputPath = '${sessionDir.path}/clip_${i + 1}.mp4';
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

      // Use your existing methods for standard processing
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

      _updateProgress(
        VideoSplitterProgress(
          currentClip: i + 1,
          totalClips: totalClips,
          progress: (i + 1) / totalClips,
          statusText: 'Clip ${i + 1} processed successfully!',
          isProcessing: true,
        ),
      );
    }
  }


  // New method to create session directory
  Future<Directory> _createVideoSession() async {
    final appDir = await getApplicationDocumentsDirectory();
    final videosDir = Directory('${appDir.path}/processed_videos');

    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }

    // Create session with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sessionDir = Directory('${videosDir.path}/session_$timestamp');
    await sessionDir.create(recursive: true);

    return sessionDir;
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
