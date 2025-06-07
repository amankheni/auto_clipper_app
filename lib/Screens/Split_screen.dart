// video_splitter_screen.dart
// ignore_for_file: avoid_print

import 'package:auto_clipper_app/Logic/Split_Controller.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;


class VideoSplitterScreen extends StatefulWidget {
  const VideoSplitterScreen({super.key});

  @override
  State<VideoSplitterScreen> createState() => _VideoSplitterScreenState();
}

class _VideoSplitterScreenState extends State<VideoSplitterScreen> {
  late VideoSplitterService _videoSplitterService;

  // UI State variables
  String? _selectedVideoPath;
  String? _selectedWatermarkPath;
  final TextEditingController _durationController = TextEditingController();
  bool _isProcessing = false;
  double _progress = 0.0;
  String _statusText = '';
  int _currentClip = 0;
  int _totalClips = 0;
  bool _useWatermark = false;
  DurationUnit _selectedUnit = DurationUnit.seconds;
  WatermarkPosition _watermarkPosition = WatermarkPosition.topRight;
  double _watermarkOpacity = 0.7;

  @override
  void initState() {
    super.initState();
    _videoSplitterService = VideoSplitterService(
      onProgressUpdate: _onProgressUpdate,
    );
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _videoSplitterService.requestPermissions();
  }

  void _onProgressUpdate(VideoSplitterProgress progress) {
    setState(() {
      _currentClip = progress.currentClip;
      _totalClips = progress.totalClips;
      _progress = progress.progress;
      _statusText = progress.statusText;
      _isProcessing = progress.isProcessing;
    });
  }

  Future<void> _pickVideo() async {
    try {
      final videoPath = await _videoSplitterService.pickVideo();
      if (videoPath != null) {
        setState(() {
          _selectedVideoPath = videoPath;
          _statusText = 'Video selected: ${path.basename(videoPath)}';
        });
      }
    } catch (e) {
      _showError('Error picking video: $e');
    }
  }

  Future<void> _pickWatermark() async {
    try {
      final watermarkPath = await _videoSplitterService.pickWatermark();
      if (watermarkPath != null) {
        setState(() {
          _selectedWatermarkPath = watermarkPath;
        });
      }
    } catch (e) {
      _showError('Error picking watermark: $e');
    }
  }

  Future<void> _startSplitting() async {
    if (_selectedVideoPath == null) {
      _showError('Please select a video first');
      return;
    }

    final durationText = _durationController.text.trim();
    if (durationText.isEmpty) {
      _showError('Please enter clip duration');
      return;
    }

    final duration = double.tryParse(durationText) ?? 0;
    if (duration <= 0) {
      _showError('Please enter a valid duration');
      return;
    }

    if (_useWatermark && _selectedWatermarkPath == null) {
      _showError('Please select a watermark image');
      return;
    }

    final clipDurationInSeconds = _videoSplitterService.getDurationInSeconds(
      duration,
      _selectedUnit,
    );

    try {
      await _videoSplitterService.splitVideo(
        videoPath: _selectedVideoPath!,
        clipDurationInSeconds: clipDurationInSeconds,
        useWatermark: _useWatermark,
        watermarkPath: _selectedWatermarkPath,
        watermarkOpacity: _watermarkOpacity,
        watermarkPosition: _watermarkPosition,
      );
    } catch (e) {
      _showError('Error splitting video: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Video Splitter Pro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVideoSelection(),
            const SizedBox(height: 20),
            _buildDurationInput(),
            const SizedBox(height: 20),
            _buildWatermarkSection(),
            const SizedBox(height: 20),
            _buildSplitButton(),
            const SizedBox(height: 30),
            if (_isProcessing) _buildProgressSection(),
            if (_statusText.isNotEmpty) _buildStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSelection() {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : _pickVideo,
      icon: const Icon(Icons.video_file),
      label: Text(
        _selectedVideoPath == null ? 'Select Video' : 'Video Selected',
      ),
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
    );
  }

  Widget _buildDurationInput() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _durationController,
            enabled: !_isProcessing,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Clip Duration',
              hintText: 'e.g., 30, 1.5, 2',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.timer),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<DurationUnit>(
            value: _selectedUnit,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: DurationUnit.seconds,
                child: Text('Seconds'),
              ),
              DropdownMenuItem(
                value: DurationUnit.minutes,
                child: Text('Minutes'),
              ),
              DropdownMenuItem(value: DurationUnit.hours, child: Text('Hours')),
            ],
            onChanged:
                _isProcessing
                    ? null
                    : (value) {
                      setState(() {
                        _selectedUnit = value!;
                      });
                    },
          ),
        ),
      ],
    );
  }

  Widget _buildWatermarkSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _useWatermark,
                  onChanged:
                      _isProcessing
                          ? null
                          : (value) {
                            setState(() {
                              _useWatermark = value ?? false;
                            });
                          },
                ),
                const Text(
                  'Add Watermark',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (_useWatermark) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickWatermark,
                icon: const Icon(Icons.image),
                label: Text(
                  _selectedWatermarkPath == null
                      ? 'Select Watermark (JPG/PNG)'
                      : 'Watermark Selected',
                ),
              ),
              const SizedBox(height: 10),
              const Text('Watermark Opacity:'),
              Slider(
                value: _watermarkOpacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: '${(_watermarkOpacity * 100).round()}%',
                onChanged:
                    _isProcessing
                        ? null
                        : (value) {
                          setState(() {
                            _watermarkOpacity = value;
                          });
                        },
              ),
              const Text('Watermark Position:'),
              const SizedBox(height: 5),
              DropdownButtonFormField<WatermarkPosition>(
                value: _watermarkPosition,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: WatermarkPosition.topLeft,
                    child: Text('Top Left'),
                  ),
                  DropdownMenuItem(
                    value: WatermarkPosition.topRight,
                    child: Text('Top Right'),
                  ),
                  DropdownMenuItem(
                    value: WatermarkPosition.bottomLeft,
                    child: Text('Bottom Left'),
                  ),
                  DropdownMenuItem(
                    value: WatermarkPosition.bottomRight,
                    child: Text('Bottom Right'),
                  ),
                ],
                onChanged:
                    _isProcessing
                        ? null
                        : (value) {
                          setState(() {
                            _watermarkPosition = value!;
                          });
                        },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSplitButton() {
    return ElevatedButton.icon(
      onPressed:
          (_isProcessing || _selectedVideoPath == null)
              ? null
              : _startSplitting,
      icon:
          _isProcessing
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.content_cut),
      label: Text(_isProcessing ? 'Processing...' : 'Split Video'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: $_currentClip / $_totalClips',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.deepPurple,
                  ),
                  minHeight: 8,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isProcessing ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isProcessing ? Colors.blue[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isProcessing ? Icons.info : Icons.check_circle,
            color: _isProcessing ? Colors.blue : Colors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusText,
              style: TextStyle(
                fontSize: 14,
                color: _isProcessing ? Colors.blue[800] : Colors.green[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }
}
