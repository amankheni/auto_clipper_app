// ignore_for_file: curly_braces_in_flow_control_structures
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
    return 'Session ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get totalSize {
    final totalBytes = videos.fold<int>(
      0,
      (sum, video) => sum + video.fileSizeInBytes,
    );
    if (totalBytes < 1024 * 1024)
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ProcessedVideo {
  final String path;
  final String name;
  final DateTime createdAt;
  final int fileSizeInBytes;
  final int durationInSeconds;

  ProcessedVideo({
    required this.path,
    required this.name,
    required this.createdAt,
    required this.fileSizeInBytes,
    required this.durationInSeconds,
  });

  String get formattedSize {
    if (fileSizeInBytes < 1024) return '${fileSizeInBytes} B';
    if (fileSizeInBytes < 1024 * 1024)
      return '${(fileSizeInBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDuration {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
