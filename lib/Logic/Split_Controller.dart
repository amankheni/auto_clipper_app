// ignore_for_file: file_names, avoid_print

// video_splitter_service.dart
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:gal/gal.dart';
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
  }) async {
    try {
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

        _updateProgress(
          VideoSplitterProgress(
            currentClip: i + 1,
            totalClips: totalClips,
            progress: i / totalClips,
            statusText: 'Processing clip ${i + 1} of $totalClips...',
            isProcessing: true,
          ),
        );

        if (useWatermark && watermarkPath != null) {
          await splitVideoClipWithWatermark(
            videoPath,
            outputPath,
            startTime,
            clipDurationInSeconds,
            watermarkPath,
            watermarkOpacity,
            watermarkPosition,
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
                  'Clip ${i + 1} saved successfully! Processing clip ${i + 2} of $totalClips...',
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
      rethrow;
    }
  }

  void _updateProgress(VideoSplitterProgress progress) {
    onProgressUpdate?.call(progress);
  }
}
