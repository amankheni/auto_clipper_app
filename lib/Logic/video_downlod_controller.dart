// ignore_for_file: avoid_print, deprecated_member_use, unused_local_variable, depend_on_referenced_packages

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path/path.dart' as path;

class VideoDownloadController {
  final Set<String> _downloadingVideos = {};
  bool _isBulkDownloading = false;
  int _downloadProgress = 0;
  int _totalDownloads = 0;

  Set<String> get downloadingVideos => _downloadingVideos;
  bool get isBulkDownloading => _isBulkDownloading;
  int get downloadProgress => _downloadProgress;
  int get totalDownloads => _totalDownloads;




 Future<List<VideoSession>> loadVideoSessions() async {
  final appDir = await getApplicationDocumentsDirectory();
  final videosDir = Directory('${appDir.path}/processed_videos');

  if (!await videosDir.exists()) {
    await videosDir.create(recursive: true);
    return [];
  }

  final sessionDirs = await videosDir.list()
      .where((entity) => entity is Directory && entity.path.contains('session_'))
      .cast<Directory>()
      .toList();

  List<VideoSession> sessions = [];

  for (Directory sessionDir in sessionDirs) {
    final videoFiles = await sessionDir.list()
        .where((entity) => entity is File && entity.path.toLowerCase().endsWith('.mp4'))
        .cast<File>()
        .toList();

    List<ProcessedVideo> videos = [];
    for (File file in videoFiles) {
      final stat = await file.stat();
      final video = ProcessedVideo(
        path: file.path,
        name: path.basename(file.path),
        createdAt: stat.modified,
        fileSizeInBytes: stat.size,
        durationInSeconds: await _getVideoDuration(file.path),
      );
      await video.generateThumbnail();
      videos.add(video);
    }

    if (videos.isNotEmpty) {
      sessions.add(VideoSession(
  sessionId: sessionDir.path.split('/').last,
  sessionPath: sessionDir.path,
  createdAt: DateTime.fromMillisecondsSinceEpoch(
    int.parse(sessionDir.path.split('_').last),
  ),
  videos: videos, // Changed from 'video' to 'videos'
));
    }
  }

  sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sessions;
}

  Future<int> _getVideoDuration(String videoPath) async {
    try {
      final file = File(videoPath);
      if (await file.exists()) {
        final sizeInMB = await file.length() / (1024 * 1024);
        return (sizeInMB * 10).round();
      }
    } catch (e) {
      print('Error getting duration: $e');
    }
    return 0;
  }

Future<String> downloadToGallery(String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        return 'Video file not found';
      }

      // Remove permission check and use GallerySaver directly like in bulk download
      final result = await GallerySaver.saveVideo(
        videoPath,
        albumName: "Auto Clipper",
      );

      if (result == true) {
        return 'Video downloaded successfully!';
      } else {
        return 'Failed to download video to gallery';
      }
    } catch (e) {
      return 'Failed to download video: ${e.toString()}';
    }
  }

  Future<String> downloadAllVideosSimple(
    VideoSession session,
    BuildContext context,
  ) async {
    if (_isBulkDownloading) return 'Already downloading';

    _isBulkDownloading = true;
    _downloadProgress = 0;
    _totalDownloads = session.videos.length;

    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < session.videos.length; i++) {
      final video = session.videos[i];
      _downloadProgress = i + 1;

      try {
        final result = await GallerySaver.saveVideo(
          video.path,
          albumName: "Video Clipper",
        );

        if (result == true) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
        print('Download failed for ${video.name}: $e');
      }

      await Future.delayed(Duration(milliseconds: 100));
    }

    _isBulkDownloading = false;
    _downloadProgress = 0;
    _totalDownloads = 0;

    return '$successCount videos downloaded successfully!';
  }

  Future<void> shareVideo(String videoPath) async {
    try {
      await Share.shareXFiles([XFile(videoPath)]);
    } catch (e) {
      print('Share failed: $e');
      throw Exception('Failed to share video: $e');
    }
  }

  Future<void> deleteSession(VideoSession session) async {
    try {
      final sessionDir = Directory(session.sessionPath);
      if (await sessionDir.exists()) {
        await sessionDir.delete(recursive: true);
      }
    } catch (e) {
      print('Delete failed: $e');
      throw Exception('Failed to delete session: $e');
    }
  }

  Future<String?> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      Directory? directory;
      try {
        directory = Directory('/storage/emulated/0/Download/Auto Clipper');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory.path;
      } catch (e) {
        print('Could not create download directory: $e');
        final appDir = await getApplicationDocumentsDirectory();
        final downloadDir = Directory('${appDir.path}/Downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir.path;
      }
    }
    return null;
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        Map<Permission, PermissionStatus> statuses =
            await [
              Permission.videos,
              Permission.photos,
              Permission.audio,
            ].request();

        return statuses.values.every(
          (status) => status == PermissionStatus.granted,
        );
      } else if (sdkInt >= 30) {
        var manageStorageStatus = await Permission.manageExternalStorage.status;
        if (!manageStorageStatus.isGranted) {
          manageStorageStatus =
              await Permission.manageExternalStorage.request();
        }

        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }

        return manageStorageStatus.isGranted || storageStatus.isGranted;
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    }
    return true;
  }

  Future<void> renameVideo(ProcessedVideo video, String newName) async {
    try {
      final file = File(video.path);
      final directory = file.parent;
      final newPath = '${directory.path}/$newName.mp4';
      await file.rename(newPath);
    } catch (e) {
      print('Error renaming video: $e');
      throw Exception('Failed to rename video: $e');
    }
  }

  



}

class VideoSession {
  final String sessionId;
  final String sessionPath;
  final DateTime createdAt;
  final List<ProcessedVideo> videos;

  VideoSession({
    required this.sessionId,
    required this.sessionPath,
    required this.createdAt,
    required this.videos,
  });

  String get displayName {
    final date = createdAt;
    return 'Session ${date.day}/${date.month}/${date.year}';
  }

  String get totalSize {
    final totalBytes = videos.fold<int>(
      0,
      (sum, video) => sum + video.fileSizeInBytes,
    );
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
class ProcessedVideo {
  final String path;
  final String name;
  final DateTime createdAt;
  final int fileSizeInBytes;
  final int durationInSeconds;
  String? thumbnailPath;

  ProcessedVideo({
    required this.path,
    required this.name,
    required this.createdAt,
    required this.fileSizeInBytes,
    required this.durationInSeconds,
  });

  Future<void> generateThumbnail() async {
    try {
      thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
      );
    } catch (e) {
      print('Error generating thumbnail: $e');
    }
  }

  String get formattedSize {
    if (fileSizeInBytes < 1024 * 1024) {
      return '${(fileSizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
