import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

class VideoEditorController extends ChangeNotifier {
  // State variables
  File? _selectedVideo;
  File? _processedVideo;
  VideoPlayerController? _videoController;
  bool _isProcessing = false;
  bool _showSuccessDialog = false;
  String? _errorMessage;
  double _trimStart = 0.0;
  double _trimEnd = 30.0;
  int _rotationDegrees = 0;
  double _videoDuration = 30.0;
  List<Uint8List> _thumbnails = [];
  bool _isGeneratingThumbnails = false;
    String _activeTab = 'video';
  String _activeAction = 'Trim';
  double _currentPosition = 0.0;
  double _timelineWidth = 300.0;
  double _splitPosition = 0.0;
  double _speedMultiplier = 1.0;
  List<double> _splitPoints = [];


  // Getters
  File? get selectedVideo => _selectedVideo;
  File? get processedVideo => _processedVideo;
  VideoPlayerController? get videoController => _videoController;
  bool get isProcessing => _isProcessing;
  bool get showSuccessDialog => _showSuccessDialog;
  String? get errorMessage => _errorMessage;
  double get trimStart => _trimStart;
  double get trimEnd => _trimEnd;
  int get rotationDegrees => _rotationDegrees;
  double get videoDuration => _videoDuration;
  List<Uint8List> get thumbnails => _thumbnails;
  bool get isGeneratingThumbnails => _isGeneratingThumbnails;
   String get activeTab => _activeTab;
  String get activeAction => _activeAction;
  double get currentPosition => _currentPosition;
  double get splitPosition => _splitPosition;
  double get speedMultiplier => _speedMultiplier;
  List<double> get splitPoints => _splitPoints;

  // Setters
  void setTrimStart(double value) {
    _trimStart = value;
    if (_trimStart >= _trimEnd) {
      _trimStart = _trimEnd - 1;
    }
    notifyListeners();
  }

  void setTrimEnd(double value) {
    _trimEnd = value;
    if (_trimEnd <= _trimStart) {
      _trimEnd = _trimStart + 1;
    }
    notifyListeners();
  }

  void setRotation(int degrees) {
    _rotationDegrees = degrees;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void hideSuccessDialog() {
    _showSuccessDialog = false;
    notifyListeners();
  }

  void setSplitPosition(double position) {
    _splitPosition = position.clamp(0.0, _videoDuration);
    notifyListeners();
  }

  void setSpeedMultiplier(double speed) {
    _speedMultiplier = speed.clamp(0.25, 4.0);
    notifyListeners();
  }

  void addSplitPoint(double position) {
    if (!_splitPoints.contains(position)) {
      _splitPoints.add(position);
      _splitPoints.sort();
      notifyListeners();
    }
  }

  void removeSplitPoint(double position) {
    _splitPoints.remove(position);
    notifyListeners();
  }

  void clearSplitPoints() {
    _splitPoints.clear();
    notifyListeners();
  }

  double get trimStartPosition {
    return (_trimStart / _videoDuration) * _timelineWidth;
  }

  double get trimEndPosition {
    return (_trimEnd / _videoDuration) * _timelineWidth;
  }

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void setActiveAction(String action) {
    _activeAction = action;
    notifyListeners();
  }

  void setCurrentPosition(double position) {
    _currentPosition = position;
    notifyListeners();
  }



  String formatTime(double seconds) {
    int minutes = (seconds / 60).floor();
    int secs = (seconds % 60).floor();
    int milliseconds = ((seconds % 1) * 100).floor();
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
  }

  Future<void> _initializeVideoPlayer() async {
    if (_selectedVideo == null) return;

    try {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(_selectedVideo!);
      await _videoController!.initialize();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error initializing video player: ${e.toString()}';
      notifyListeners();
    }
  }


  // Add this method to your VideoEditorController class

 Future<void> trimVideo() async {
    if (_selectedVideo == null) {
      _errorMessage = 'Please select a video first';
      notifyListeners();
      return;
    }

    if (_trimEnd <= _trimStart) {
      _errorMessage =
          'Invalid trim range. End time must be greater than start time.';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get temporary directory for output
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/trimmed_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Build FFmpeg command specifically for trimming
      String command =
          '-i "${_selectedVideo!.path}" -ss $_trimStart -t ${_trimEnd - _trimStart}';

      // Add rotation if needed
      if (_rotationDegrees != 0) {
        String rotationFilter;
        switch (_rotationDegrees) {
          case 90:
            rotationFilter = 'transpose=1';
            break;
          case 180:
            rotationFilter = 'transpose=1,transpose=1';
            break;
          case 270:
            rotationFilter = 'transpose=2';
            break;
          default:
            rotationFilter = '';
        }
        if (rotationFilter.isNotEmpty) {
          command += ' -vf "$rotationFilter"';
        }
      }

      // Add output parameters
      command += ' -c:v libx264 -c:a aac -preset fast "$outputPath"';

      // Execute FFmpeg
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Save to gallery
        final result = await GallerySaver.saveVideo(outputPath);

        if (result == true) {
          _processedVideo = File(outputPath);
          _showSuccessDialog = true;
          _errorMessage = null;
        } else {
          _errorMessage = 'Failed to save trimmed video to gallery';
        }
      } else {
        final logs = await session.getLogs();
        _errorMessage =
            'Video trimming failed. Please check your trim settings.';
      }
    } catch (e) {
      _errorMessage = 'Error trimming video: ${e.toString()}';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _generateThumbnails() async {
    if (_selectedVideo == null) return;

    _isGeneratingThumbnails = true;
    _thumbnails.clear();
    notifyListeners();

    try {
      final tempDir = await getTemporaryDirectory();
      const int thumbnailCount = 8;
      final double interval = _videoDuration / thumbnailCount;

      for (int i = 0; i < thumbnailCount; i++) {
        final double time = i * interval;
        final String thumbnailPath = '${tempDir.path}/thumbnail_$i.jpg';

        await FFmpegKit.execute(
          '-i "${_selectedVideo!.path}" -ss $time -vframes 1 -q:v 2 "$thumbnailPath"',
        );

        final File thumbnailFile = File(thumbnailPath);
        if (await thumbnailFile.exists()) {
          final Uint8List thumbnailBytes = await thumbnailFile.readAsBytes();
          _thumbnails.add(thumbnailBytes);
          await thumbnailFile.delete();
        }
      }
    } catch (e) {
      _errorMessage = 'Error generating thumbnails: ${e.toString()}';
    } finally {
      _isGeneratingThumbnails = false;
      notifyListeners();
    }
  }

  Future<void> pickVideo() async {
    try {
      // Request storage permission
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        _errorMessage = 'Storage permission is required to select videos';
        notifyListeners();
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        _selectedVideo = File(result.files.single.path!);
        await _getVideoDuration();
        await _initializeVideoPlayer();
        await _generateThumbnails();
        _trimStart = 0.0;
        _trimEnd = _videoDuration > 30 ? 30.0 : _videoDuration;
        _rotationDegrees = 0;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error picking video: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> _getVideoDuration() async {
    if (_selectedVideo == null) return;

    try {
      await FFmpegKit.execute('-i "${_selectedVideo!.path}" -f null -').then((
        session,
      ) async {
        final output = await session.getOutput();
        if (output != null) {
          final durationRegex = RegExp(
            r'Duration: (\d{2}):(\d{2}):(\d{2}\.\d{2})',
          );
          final match = durationRegex.firstMatch(output);

          if (match != null) {
            final hours = int.parse(match.group(1)!);
            final minutes = int.parse(match.group(2)!);
            final seconds = double.parse(match.group(3)!);
            _videoDuration = hours * 3600 + minutes * 60 + seconds;
          }
        }
      });
    } catch (e) {
      _videoDuration = 30.0; // Default fallback
    }
  }
  
  

  Future<void> processAndSaveVideo() async {
    if (_selectedVideo == null) {
      _errorMessage = 'Please select a video first';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get temporary directory for output
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/edited_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Build FFmpeg command
      String command = _buildFFmpegCommand(_selectedVideo!.path, outputPath);

      // Execute FFmpeg
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Save to gallery
        final result = await GallerySaver.saveVideo(outputPath);

        if (result == true) {
          _processedVideo = File(outputPath);
          _showSuccessDialog = true;
          _errorMessage = null;
        } else {
          _errorMessage = 'Failed to save video to gallery';
        }
      } else {
        final logs = await session.getLogs();
        _errorMessage =
            'Video processing failed. Please check your input parameters.';
      }
    } catch (e) {
      _errorMessage = 'Error processing video: ${e.toString()}';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  String _buildFFmpegCommand(String inputPath, String outputPath) {
    List<String> filters = [];

    // Add rotation filter if needed
    if (_rotationDegrees != 0) {
      String rotationFilter;
      switch (_rotationDegrees) {
        case 90:
          rotationFilter = 'transpose=1';
          break;
        case 180:
          rotationFilter = 'transpose=1,transpose=1';
          break;
        case 270:
          rotationFilter = 'transpose=2';
          break;
        default:
          rotationFilter = '';
      }
      if (rotationFilter.isNotEmpty) {
        filters.add(rotationFilter);
      }
    }

    // Build command
    String command = '-i "$inputPath"';

    // Add trim parameters
    command += ' -ss $_trimStart -t ${_trimEnd - _trimStart}';

    // Add filters if any
    if (filters.isNotEmpty) {
      command += ' -vf "${filters.join(',')}"';
    }

    // Add output parameters
    command += ' -c:v libx264 -c:a aac -preset fast "$outputPath"';

    return command;
  }

  Future<void> splitVideo() async {
    if (_selectedVideo == null) {
      _errorMessage = 'Please select a video first';
      notifyListeners();
      return;
    }

    if (_splitPoints.isEmpty) {
      _errorMessage = 'Please add at least one split point';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tempDir = await getTemporaryDirectory();
      List<String> outputPaths = [];

      // Create split points including start and end
      List<double> allSplitPoints = [0.0, ..._splitPoints, _videoDuration];
      allSplitPoints.sort();

      // Remove duplicates
      allSplitPoints = allSplitPoints.toSet().toList();
      allSplitPoints.sort();

      // Split video into segments
      for (int i = 0; i < allSplitPoints.length - 1; i++) {
        double start = allSplitPoints[i];
        double end = allSplitPoints[i + 1];
        double duration = end - start;

        if (duration > 0.1) {
          // Only create segments longer than 0.1 seconds
          final outputPath =
              '${tempDir.path}/split_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.mp4';

          String command =
              '-i "${_selectedVideo!.path}" -ss $start -t $duration';

          // Add rotation if needed
          if (_rotationDegrees != 0) {
            String rotationFilter;
            switch (_rotationDegrees) {
              case 90:
                rotationFilter = 'transpose=1';
                break;
              case 180:
                rotationFilter = 'transpose=1,transpose=1';
                break;
              case 270:
                rotationFilter = 'transpose=2';
                break;
              default:
                rotationFilter = '';
            }
            if (rotationFilter.isNotEmpty) {
              command += ' -vf "$rotationFilter"';
            }
          }

          command += ' -c:v libx264 -c:a aac -preset fast "$outputPath"';

          final session = await FFmpegKit.execute(command);
          final returnCode = await session.getReturnCode();

          if (ReturnCode.isSuccess(returnCode)) {
            outputPaths.add(outputPath);
          }
        }
      }

      // Save all segments to gallery
      int savedCount = 0;
      for (String path in outputPaths) {
        final result = await GallerySaver.saveVideo(path);
        if (result == true) {
          savedCount++;
        }
      }

      if (savedCount > 0) {
        _showSuccessDialog = true;
        _errorMessage = null;
        // Clear split points after successful split
        clearSplitPoints();
      } else {
        _errorMessage = 'Failed to save split videos to gallery';
      }
    } catch (e) {
      _errorMessage = 'Error splitting video: ${e.toString()}';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Speed Video Method
  Future<void> speedVideo() async {
    if (_selectedVideo == null) {
      _errorMessage = 'Please select a video first';
      notifyListeners();
      return;
    }

    if (_speedMultiplier == 1.0) {
      _errorMessage = 'Speed multiplier is already at normal speed (1.0x)';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath =
          '${tempDir.path}/speed_${_speedMultiplier}x_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Build FFmpeg command for speed adjustment
      List<String> filters = [];

      // Add speed filter
      filters.add('setpts=${1 / _speedMultiplier}*PTS');

      // Add rotation if needed
      if (_rotationDegrees != 0) {
        String rotationFilter;
        switch (_rotationDegrees) {
          case 90:
            rotationFilter = 'transpose=1';
            break;
          case 180:
            rotationFilter = 'transpose=1,transpose=1';
            break;
          case 270:
            rotationFilter = 'transpose=2';
            break;
          default:
            rotationFilter = '';
        }
        if (rotationFilter.isNotEmpty) {
          filters.add(rotationFilter);
        }
      }

      String command = '-i "${_selectedVideo!.path}"';

      // Add video filters
      if (filters.isNotEmpty) {
        command += ' -vf "${filters.join(',')}"';
      }

      // Add audio speed adjustment
      command += ' -af "atempo=$_speedMultiplier"';

      // Add output parameters
      command += ' -c:v libx264 -c:a aac -preset fast "$outputPath"';

      // Execute FFmpeg
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Save to gallery
        final result = await GallerySaver.saveVideo(outputPath);

        if (result == true) {
          _processedVideo = File(outputPath);
          _showSuccessDialog = true;
          _errorMessage = null;
        } else {
          _errorMessage = 'Failed to save speed-adjusted video to gallery';
        }
      } else {
        final logs = await session.getLogs();
        _errorMessage =
            'Video speed adjustment failed. Please try a different speed.';
      }
    } catch (e) {
      _errorMessage = 'Error adjusting video speed: ${e.toString()}';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

}
