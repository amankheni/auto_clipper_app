// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:auto_clipper_app/Logic/video_downlod_controller.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class VideoDownloadScreen extends StatefulWidget {
  @override
  _VideoDownloadScreenState createState() => _VideoDownloadScreenState();
}

class _VideoDownloadScreenState extends State<VideoDownloadScreen> {
  List<VideoSession> _sessions = [];
  bool _isLoading = false;
  String _statusMessage = '';
  Set<String> _downloadingVideos = {};
  VideoSession? _selectedSession;
  bool _isBulkDownloading = false;
  int _downloadProgress = 0;
  int _totalDownloads = 0;

  @override
  void initState() {
    super.initState();
    _loadVideoSessions();
  }

  Future<void> _loadVideoSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${appDir.path}/processed_videos');

      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
        setState(() {
          _sessions = [];
          _isLoading = false;
        });
        return;
      }

      final sessionDirs =
          await videosDir
              .list()
              .where(
                (entity) =>
                    entity is Directory && entity.path.contains('session_'),
              )
              .cast<Directory>()
              .toList();

      List<VideoSession> sessions = [];

      for (Directory sessionDir in sessionDirs) {
        final sessionId = sessionDir.path.split('/').last;
        final timestamp =
            int.tryParse(sessionId.replaceAll('session_', '')) ?? 0;
        final createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp);

        final videoFiles =
            await sessionDir
                .list()
                .where(
                  (entity) =>
                      entity is File &&
                      entity.path.toLowerCase().endsWith('.mp4'),
                )
                .cast<File>()
                .toList();

        List<ProcessedVideo> videos = [];
        for (File file in videoFiles) {
          final stat = await file.stat();
          videos.add(
            ProcessedVideo(
              path: file.path,
              name: file.path.split('/').last,
              createdAt: stat.modified,
              fileSizeInBytes: stat.size,
              durationInSeconds: await _getVideoDuration(file.path),
            ),
          );
        }

        if (videos.isNotEmpty) {
          sessions.add(
            VideoSession(
              sessionId: sessionId,
              sessionPath: sessionDir.path,
              createdAt: createdAt,
              videos: videos,
            ),
          );
        }
      }

      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _sessions = sessions;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading video sessions: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

 Future<void> _downloadToGallery(String videoPath) async {
    if (_downloadingVideos.contains(videoPath)) return;

    setState(() {
      _downloadingVideos.add(videoPath);
      _statusMessage = 'Requesting permissions...';
    });

    try {
      // Request permissions first
      bool permissionGranted = await requestPermissions();

      if (!permissionGranted) {
        // Try to open app settings if permission denied
        setState(() {
          _statusMessage = 'Please grant storage permission in app settings';
        });

        // Show dialog to open settings
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Permission Required'),
              content: Text(
                'Storage permission is required to download videos. Please grant permission in app settings.',
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Open Settings'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                ),
              ],
            );
          },
        );
        return;
      }

      setState(() {
        _statusMessage = 'Downloading video...';
      });

      // Method 1: Try GallerySaver first
      bool success = false;
      try {
        final result = await GallerySaver.saveVideo(
          videoPath,
          albumName: "Auto Clipper",
        );
        success = result == true;
      } catch (e) {
        print('GallerySaver failed: $e');
        success = false;
      }

      // Method 2: If GallerySaver fails, try manual file copy
      if (!success) {
        try {
          final downloadDir = await getDownloadDirectory();
          if (downloadDir != null) {
            final file = File(videoPath);
            final fileName = videoPath.split('/').last;
            final newPath = '$downloadDir/$fileName';

            await file.copy(newPath);

            // Try to scan the file so it appears in gallery
            if (Platform.isAndroid) {
              try {
                // You might need to add media_scanner package for this
                // await MediaScanner.loadMedia(path: newPath);
                print('File copied to: $newPath');
              } catch (e) {
                print('Media scan failed: $e');
              }
            }

            success = true;
          }
        } catch (e) {
          print('Manual copy failed: $e');
        }
      }

      if (success) {
        setState(() {
          _statusMessage = 'Video downloaded successfully!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('All download methods failed');
      }
    } catch (e) {
      print('Download error: $e');
      setState(() {
        _statusMessage = 'Failed to download video: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _downloadingVideos.remove(videoPath);
      });

      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });
    }
  }

  Future<void> _downloadAllVideosSimple(VideoSession session) async {
    if (_isBulkDownloading) return;

    setState(() {
      _isBulkDownloading = true;
      _downloadProgress = 0;
      _totalDownloads = session.videos.length;
      _statusMessage = 'Starting download...';
    });

    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < session.videos.length; i++) {
      final video = session.videos[i];

      setState(() {
        _downloadProgress = i + 1;
        _statusMessage =
            'Downloading ${video.name} (${_downloadProgress}/$_totalDownloads)';
      });

      try {
        // Direct download - let GallerySaver handle permissions
        final result = await GallerySaver.saveVideo(
          video.path,
          albumName: "Auto Clipper",
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

      // Small delay to prevent overwhelming the system
      await Future.delayed(Duration(milliseconds: 100));
    }

    setState(() {
      _isBulkDownloading = false;
      _downloadProgress = 0;
      _totalDownloads = 0;
      _statusMessage = '$successCount videos downloaded successfully!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$successCount videos downloaded, $failCount failed'),
        backgroundColor: successCount > 0 ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _shareVideo(String videoPath) async {
    try {
      await Share.shareXFiles([XFile(videoPath)]);
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to share video: $e';
      });
    }
  }

  Future<void> _deleteSession(VideoSession session) async {
    try {
      final sessionDir = Directory(session.sessionPath);
      if (await sessionDir.exists()) {
        await sessionDir.delete(recursive: true);
        await _loadVideoSessions();
        setState(() {
          _statusMessage = 'Session deleted successfully';
          _selectedSession = null;
        });

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _statusMessage = '';
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to delete session: $e';
      });
    }
  }
Future<String?> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Try to get the Downloads directory
      Directory? directory;

      try {
        directory = Directory('/storage/emulated/0/Download/Auto Clipper');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory.path;
      } catch (e) {
        print('Could not create download directory: $e');

        // Fallback to app documents directory
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

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_selectedSession != null)
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedSession = null;
                });
              },
              icon: Icon(Icons.arrow_back, size: 24.sp),
              padding: EdgeInsets.zero,
            ),
          Expanded(
            child: Text(
              _selectedSession != null
                  ? _selectedSession!.displayName
                  : 'My Videos',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          if (_selectedSession != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete_session') {
                  _showDeleteSessionDialog(_selectedSession!);
                }
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'delete_session',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8.w),
                          Text('Delete Session'),
                        ],
                      ),
                    ),
                  ],
            ),
        ],
      ),
    );
  }

Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      print('Android SDK: $sdkInt');

      if (sdkInt >= 33) {
        // Android 13+ (API 33+) - Request specific media permissions
        Map<Permission, PermissionStatus> statuses =
            await [
              Permission.videos,
              Permission.photos,
              Permission.audio,
            ].request();

        print('Permission statuses: $statuses');

        // Check if all permissions are granted
        bool allGranted = statuses.values.every(
          (status) => status == PermissionStatus.granted,
        );

        return allGranted;
      } else if (sdkInt >= 30) {
        // Android 11-12 (API 30-32) - Request MANAGE_EXTERNAL_STORAGE
        var manageStorageStatus = await Permission.manageExternalStorage.status;

        if (!manageStorageStatus.isGranted) {
          manageStorageStatus =
              await Permission.manageExternalStorage.request();
        }

        // Also request regular storage permission as fallback
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }

        print('Manage External Storage: $manageStorageStatus');
        print('Storage: $storageStatus');

        return manageStorageStatus.isGranted || storageStatus.isGranted;
      } else {
        // Android 10 and below - Request regular storage permission
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }

        print('Storage permission: $status');
        return status.isGranted;
      }
    }
    return true;
  }

  Widget _buildStorageInfo() {
    final totalSessions = _sessions.length;
    final totalVideos = _sessions.fold<int>(
      0,
      (sum, session) => sum + session.videos.length,
    );
    final totalSize = _sessions.fold<int>(
      0,
      (sum, session) =>
          sum +
          session.videos.fold<int>(
            0,
            (videoSum, video) => videoSum + video.fileSizeInBytes,
          ),
    );

    String formattedTotalSize =
        totalSize < 1024 * 1024
            ? '${(totalSize / 1024).toStringAsFixed(1)} KB'
            : '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';

    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              _selectedSession != null ? Icons.video_library : Icons.folder,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSession != null
                      ? '${_selectedSession!.videos.length} Videos'
                      : '$totalSessions Sessions',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _selectedSession != null
                      ? 'Total: ${_selectedSession!.totalSize}'
                      : '$totalVideos Videos • $formattedTotalSize',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    if (_statusMessage.isEmpty) return SizedBox.shrink();

    final isError =
        _statusMessage.toLowerCase().contains('error') ||
        _statusMessage.toLowerCase().contains('failed');
    final isDownloading = _isBulkDownloading;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color:
            isError
                ? Colors.red.shade50
                : isDownloading
                ? Colors.blue.shade50
                : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color:
              isError
                  ? Colors.red.shade200
                  : isDownloading
                  ? Colors.blue.shade200
                  : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          if (isDownloading)
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.red : Colors.green,
              size: 20.sp,
            ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 14.sp,
                color:
                    isError
                        ? Colors.red.shade700
                        : isDownloading
                        ? Colors.blue.shade700
                        : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return _buildSessionItem(session);
      },
    );
  }

 Widget _buildSessionItem(VideoSession session) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            // Existing row content
            InkWell(
              onTap: () {
                setState(() {
                  _selectedSession = session;
                });
              },
              borderRadius: BorderRadius.circular(16.r),
              child: Row(
                children: [
                  // Your existing session item content
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.folder, color: Colors.white, size: 28.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.displayName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${session.videos.length} videos • ${session.totalSize}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 24.sp,
                  ),
                ],
              ),
            ),

            // Add download button
            SizedBox(height: 12.h),
            _buildActionButton(
              icon:
                  _isBulkDownloading && _selectedSession == session
                      ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(Icons.download, size: 18.sp),
              label:
                  _isBulkDownloading && _selectedSession == session
                      ? 'Downloading ${_downloadProgress}/${_totalDownloads}'
                      : 'Download All',
              onTap:
                  _isBulkDownloading ? null : () => _downloadAllVideosSimple(session),
              color: Color(0xFF4CAF50),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosList() {
    if (_selectedSession == null) return _buildSessionsList();

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _selectedSession!.videos.length,
      itemBuilder: (context, index) {
        final video = _selectedSession!.videos[index];
        return _buildVideoItem(video);
      },
    );
  }

  Widget _buildVideoItem(ProcessedVideo video) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14.sp,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            video.formattedDuration,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Icon(Icons.storage, size: 14.sp, color: Colors.grey),
                          SizedBox(width: 4.w),
                          Text(
                            video.formattedSize,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon:
                        _downloadingVideos.contains(video.path)
                            ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Icon(Icons.download, size: 18.sp),
                    label:
                        _downloadingVideos.contains(video.path)
                            ? 'Downloading...'
                            : 'Download',
                    onTap:
                        _downloadingVideos.contains(video.path)
                            ? null
                            : () => _downloadToGallery(video.path),
                    color: Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildActionButton(
                    icon: Icon(Icons.share, size: 18.sp),
                    label: 'Share',
                    onTap: () => _shareVideo(video.path),
                    color: Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              if (label.isNotEmpty) ...[
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.r),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.video_library_outlined,
              size: 64.sp,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No videos found',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Process some videos to see them here',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            'Loading videos...',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showDeleteSessionDialog(VideoSession session) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Session'),
            content: Text(
              'Are you sure you want to delete "${session.displayName}" and all its videos?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteSession(session);
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

Future<void> _downloadAllVideos(VideoSession session) async {
    if (_isBulkDownloading) return;

    setState(() {
      _isBulkDownloading = true;
      _downloadProgress = 0;
      _totalDownloads = session.videos.length;
      _statusMessage = 'Requesting permissions...';
    });

    try {
      // Request permissions first
      bool permissionGranted = await requestPermissions();

      if (!permissionGranted) {
        setState(() {
          _statusMessage = 'Storage permission is required for bulk download';
          _isBulkDownloading = false;
        });

        // Show settings dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Permission Required'),
              content: Text(
                'Storage permission is required for bulk download. Please grant permission in app settings.',
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Open Settings'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                ),
              ],
            );
          },
        );
        return;
      }

      int successCount = 0;
      int failCount = 0;

      // Get download directory once
      final downloadDir = await getDownloadDirectory();

      for (int i = 0; i < session.videos.length; i++) {
        final video = session.videos[i];

        setState(() {
          _downloadProgress = i + 1;
          _statusMessage =
              'Downloading ${video.name} (${_downloadProgress}/$_totalDownloads)';
        });

        try {
          bool success = false;

          // Try GallerySaver first
          try {
            final result = await GallerySaver.saveVideo(
              video.path,
              albumName: "Auto Clipper",
            );
            success = result == true;
          } catch (e) {
            print('GallerySaver failed for ${video.name}: $e');
          }

          // If GallerySaver fails, try manual copy
          if (!success && downloadDir != null) {
            try {
              final file = File(video.path);
              final fileName = video.path.split('/').last;
              final newPath = '$downloadDir/$fileName';

              await file.copy(newPath);
              success = true;
            } catch (e) {
              print('Manual copy failed for ${video.name}: $e');
            }
          }

          if (success) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          print('Failed to download ${video.name}: $e');
          failCount++;
        }

        // Shorter delay between downloads
        await Future.delayed(Duration(milliseconds: 500));
      }

      setState(() {
        if (failCount == 0) {
          _statusMessage = 'All $successCount videos downloaded successfully!';
        } else {
          _statusMessage = '$successCount videos downloaded, $failCount failed';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failCount == 0
                ? 'All videos downloaded successfully!'
                : '$successCount downloaded, $failCount failed',
          ),
          backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Bulk download failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isBulkDownloading = false;
        _downloadProgress = 0;
        _totalDownloads = 0;
      });

      Future.delayed(Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });
    }
  } 



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildStorageInfo(),
            _buildStatusMessage(),
            Expanded(
              child:
                  _isLoading
                      ? _buildLoadingState()
                      : _sessions.isEmpty
                      ? _buildEmptyState()
                      : _buildVideosList(),
            ),
          ],
        ),
      ),
    );
  }
}
