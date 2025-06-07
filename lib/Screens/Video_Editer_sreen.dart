// ignore_for_file: deprecated_member_use

import 'package:auto_clipper_app/Logic/Video_editor_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({Key? key}) : super(key: key);

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  late VideoEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoEditorController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Video Editor',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Show success dialog when processing is complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_controller.showSuccessDialog) {
              _showSuccessDialog();
            }
          });

          return SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildVideoSelectionCard(),
                SizedBox(height: 20.h),
                if (_controller.selectedVideo != null) ...[
                  _buildVideoPreviewCard(),
                  SizedBox(height: 20.h),
                  _buildThumbnailTimelineCard(),
                  SizedBox(height: 20.h),
                  _buildRotationCard(),
                  SizedBox(height: 30.h),
                  _buildProcessButton(),
                ],
                if (_controller.errorMessage != null) ...[
                  SizedBox(height: 20.h),
                  _buildErrorCard(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPreviewCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video Preview',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              height: 200.h,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child:
                  _controller.videoController != null &&
                          _controller.videoController!.value.isInitialized
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: AspectRatio(
                          aspectRatio:
                              _controller.videoController!.value.aspectRatio,
                          child: VideoPlayer(_controller.videoController!),
                        ),
                      )
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 48.w,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Loading video...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (_controller.videoController != null) {
                      if (_controller.videoController!.value.isPlaying) {
                        _controller.videoController!.pause();
                      } else {
                        _controller.videoController!.play();
                      }
                    }
                  },
                  icon: Icon(
                    _controller.videoController?.value.isPlaying == true
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 40.w,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailTimelineCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Tab Bar (Video/Audio)
            Container(
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _controller.setActiveTab('video'),
                      child: Container(
                        height: 36.h,
                        margin: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color:
                              _controller.activeTab == 'video'
                                  ? Colors.white
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(18.r),
                          boxShadow:
                              _controller.activeTab == 'video'
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam,
                              size: 16.w,
                              color:
                                  _controller.activeTab == 'video'
                                      ? Colors.blue
                                      : Colors.grey[600],
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Video',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color:
                                    _controller.activeTab == 'video'
                                        ? Colors.blue
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _controller.setActiveTab('audio'),
                      child: Container(
                        height: 36.h,
                        margin: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color:
                              _controller.activeTab == 'audio'
                                  ? Colors.white
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(18.r),
                          boxShadow:
                              _controller.activeTab == 'audio'
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.volume_up,
                              size: 16.w,
                              color:
                                  _controller.activeTab == 'audio'
                                      ? Colors.blue
                                      : Colors.grey[600],
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Audio',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color:
                                    _controller.activeTab == 'audio'
                                        ? Colors.blue
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Action Tabs (Split/Trim/Speed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionTab(
                  'Split',
                  Icons.content_cut,
                  _controller.activeAction == 'Split',
                ),
                _buildActionTab(
                  'Trim',
                  Icons.crop,
                  _controller.activeAction == 'Trim',
                ),
                _buildActionTab(
                  'Speed',
                  Icons.speed,
                  _controller.activeAction == 'Speed',
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Timeline with thumbnails
            Container(
              height: 100.h,
              child: Column(
                children: [
                  // Timeline container
                  Container(
                    height: 60.h,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // Thumbnail strip
                        Container(
                          height: 60.h,
                          child:
                              _controller.isGeneratingThumbnails
                                  ? Center(
                                    child: Text(
                                      'Generating thumbnails...',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                  : Row(
                                    children:
                                        _controller.thumbnails
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                              return Expanded(
                                                child: Container(
                                                  height: 60.h,
                                                  margin: EdgeInsets.only(
                                                    right: 1.w,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4.r,
                                                        ),
                                                    image: DecorationImage(
                                                      image: MemoryImage(
                                                        entry.value,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            })
                                            .toList(),
                                  ),
                        ),

                        // Selection overlay with trim handles
                        if (_controller.activeAction == 'Trim' &&
                            _controller.thumbnails.isNotEmpty)
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double totalWidth = constraints.maxWidth;
                                final double startPos =
                                    (_controller.trimStart /
                                        _controller.videoDuration) *
                                    totalWidth;
                                final double endPos =
                                    (_controller.trimEnd /
                                        _controller.videoDuration) *
                                    totalWidth;

                                return Stack(
                                  children: [
                                    // Dark overlay before trim start
                                    if (startPos > 0)
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        width: startPos,
                                        height: 60.h,
                                        child: Container(
                                          color: Colors.black.withOpacity(0.6),
                                        ),
                                      ),

                                    // Dark overlay after trim end
                                    if (endPos < totalWidth)
                                      Positioned(
                                        left: endPos,
                                        top: 0,
                                        width: totalWidth - endPos,
                                        height: 60.h,
                                        child: Container(
                                          color: Colors.black.withOpacity(0.6),
                                        ),
                                      ),

                                    // Red border around selection
                                    Positioned(
                                      left: startPos,
                                      top: 0,
                                      width: endPos - startPos,
                                      height: 60.h,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4.r,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Start trim handle
                                    Positioned(
                                      left: startPos - 2,
                                      top: 0,
                                      child: Container(
                                        width: 4.w,
                                        height: 60.h,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            2.r,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // End trim handle
                                    Positioned(
                                      left: endPos - 2,
                                      top: 0,
                                      child: Container(
                                        width: 4.w,
                                        height: 60.h,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            2.r,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Time indicators
                  if (_controller.activeAction == 'Trim')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _controller.formatTime(_controller.trimStart),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          _controller.formatTime(_controller.trimEnd),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Range slider for trimming
            if (_controller.activeAction == 'Trim')
              RangeSlider(
                values: RangeValues(
                  _controller.trimStart.clamp(0.0, _controller.videoDuration),
                  _controller.trimEnd.clamp(0.0, _controller.videoDuration),
                ),
                min: 0.0,
                max: _controller.videoDuration,
                divisions: _controller.videoDuration.round(),
                activeColor: Colors.red,
                inactiveColor: Colors.grey[300],
                onChanged: (RangeValues values) {
                  _controller.setTrimStart(values.start);
                  _controller.setTrimEnd(values.end);
                },
              ),

              

            SizedBox(height: 16.h),
if (_controller.activeAction == 'Split') ...[
              // Split position slider
              Text(
                'Split Position: ${_controller.formatTime(_controller.splitPosition)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              Slider(
                value: _controller.splitPosition,
                min: 0.0,
                max: _controller.videoDuration,
                divisions: _controller.videoDuration.round(),
                activeColor: Colors.orange,
                inactiveColor: Colors.grey[300],
                onChanged: (value) {
                  _controller.setSplitPosition(value);
                },
              ),
              SizedBox(height: 8.h),

              // Add split point button
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _controller.addSplitPoint(_controller.splitPosition);
                  },
                  icon: Icon(Icons.add, size: 16.w),
                  label: Text('Add Split Point'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[100],
                    foregroundColor: Colors.orange[800],
                    elevation: 0,
                  ),
                ),
              ),

              // Show split points
              if (_controller.splitPoints.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Text(
                  'Split Points:',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children:
                      _controller.splitPoints.map((point) {
                        return Chip(
                          label: Text(
                            _controller.formatTime(point),
                            style: TextStyle(fontSize: 10.sp),
                          ),
                          deleteIcon: Icon(Icons.close, size: 14.w),
                          onDeleted: () => _controller.removeSplitPoint(point),
                          backgroundColor: Colors.orange[100],
                          deleteIconColor: Colors.orange[800],
                        );
                      }).toList(),
                ),
              ],
            ],


            if (_controller.activeAction == 'Speed') ...[
              Text(
                'Speed: ${_controller.speedMultiplier.toStringAsFixed(2)}x',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              Slider(
                value: _controller.speedMultiplier,
                min: 0.25,
                max: 4.0,
                divisions: 15, // 0.25x increments
                activeColor: Colors.purple,
                inactiveColor: Colors.grey[300],
                onChanged: (value) {
                  _controller.setSpeedMultiplier(value);
                },
              ),
              SizedBox(height: 8.h),

              // Speed preset buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSpeedPresetButton('0.5x', 0.5),
                  _buildSpeedPresetButton('1x', 1.0),
                  _buildSpeedPresetButton('1.5x', 1.5),
                  _buildSpeedPresetButton('2x', 2.0),
                ],
              ),
            ],


            // Instruction text
            Text(
              _controller.activeAction == 'Trim'
                  ? 'Slide the two handles, then hit Trim'
                  : _controller.activeAction == 'Split'
                  ? 'Set split positions and hit Split to create multiple videos'
                  : 'Adjust the speed multiplier and hit Speed',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 16.h),

            // Action button
            Container(
              width: 120.w,
              height: 40.h,
              child: ElevatedButton(
                onPressed:
                    _controller.isProcessing
                        ? null
                        : () {
                          if (_controller.activeAction == 'Trim') {
                            _controller.trimVideo();
                          } else if (_controller.activeAction == 'Split') {
                            _controller.splitVideo();
                          } else if (_controller.activeAction == 'Speed') {
                            _controller.speedVideo();
                          }
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _controller.activeAction == 'Trim'
                          ? Icons.crop
                          : _controller.activeAction == 'Split'
                          ? Icons.content_cut
                          : Icons.speed,
                      size: 16.w,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      _controller.activeAction,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTab(String title, IconData icon, bool isActive) {
    return GestureDetector(
      onTap: () => _controller.setActiveAction(title),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24.w,
            color: isActive ? Colors.blue : Colors.grey[400],
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.blue : Colors.grey[600],
            ),
          ),
          if (isActive) ...[
            SizedBox(height: 4.h),
            Container(
              width: 30.w,
              height: 2.h,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(1.r),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 48.w,
                    color: Colors.green[600],
                  ),
                ),
                SizedBox(height: 20.h),

                Text(
                  'Video Saved Successfully!',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),

                Text(
                  'Your edited video has been saved to the gallery.',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),

                // Preview thumbnail if available
                if (_controller.processedVideo != null)
                  Container(
                    width: 120.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Icon(
                      Icons.video_library,
                      size: 32.w,
                      color: Colors.grey[600],
                    ),
                  ),
                SizedBox(height: 24.h),

                SizedBox(
                  width: double.infinity,
                  height: 44.h,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _controller.hideSuccessDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoSelectionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Icon(
              _controller.selectedVideo != null
                  ? Icons.video_library
                  : Icons.video_library_outlined,
              size: 48.w,
              color:
                  _controller.selectedVideo != null
                      ? Colors.green
                      : Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              _controller.selectedVideo != null
                  ? 'Video Selected'
                  : 'No Video Selected',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color:
                    _controller.selectedVideo != null
                        ? Colors.green[700]
                        : Colors.grey[600],
              ),
            ),
            if (_controller.selectedVideo != null) ...[
              SizedBox(height: 8.h),
              Text(
                'Duration: ${_controller.videoDuration.toStringAsFixed(1)}s',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
            ],
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: _controller.pickVideo,
                icon: Icon(Icons.folder_open, size: 20.w),
                label: Text(
                  'Pick Video from Gallery',
                  style: TextStyle(fontSize: 16.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedPresetButton(String label, double speed) {
    final isSelected = (_controller.speedMultiplier - speed).abs() < 0.01;

    return GestureDetector(
      onTap: () => _controller.setSpeedMultiplier(speed),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.purple[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.purple, width: isSelected ? 2 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.purple[800],
          ),
        ),
      ),
    );
  }


  // Widget _buildTrimControlsCard() {
  //   return Card(
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
  //     child: Padding(
  //       padding: EdgeInsets.all(20.w),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Trim Settings',
  //             style: TextStyle(
  //               fontSize: 18.sp,
  //               fontWeight: FontWeight.w600,
  //               color: Colors.grey[800],
  //             ),
  //           ),
  //           SizedBox(height: 20.h),

  //           // Trim Start
  //           Text(
  //             'Start Time: ${_controller.trimStart.toStringAsFixed(1)}s',
  //             style: TextStyle(
  //               fontSize: 14.sp,
  //               fontWeight: FontWeight.w500,
  //               color: Colors.grey[700],
  //             ),
  //           ),
  //           SizedBox(height: 8.h),
  //           SliderTheme(
  //             data: SliderTheme.of(context).copyWith(
  //               trackHeight: 4.h,
  //               thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
  //             ),
  //             child: Slider(
  //               value: _controller.trimStart,
  //               min: 0.0,
  //               max: _controller.videoDuration - 1,
  //               divisions: (_controller.videoDuration - 1).round(),
  //               onChanged: _controller.setTrimStart,
  //               activeColor: Colors.blue,
  //             ),
  //           ),

  //           SizedBox(height: 16.h),

  //           // Trim End
  //           Text(
  //             'End Time: ${_controller.trimEnd.toStringAsFixed(1)}s',
  //             style: TextStyle(
  //               fontSize: 14.sp,
  //               fontWeight: FontWeight.w500,
  //               color: Colors.grey[700],
  //             ),
  //           ),
  //           SizedBox(height: 8.h),
  //           SliderTheme(
  //             data: SliderTheme.of(context).copyWith(
  //               trackHeight: 4.h,
  //               thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
  //             ),
  //             child: Slider(
  //               value: _controller.trimEnd,
  //               min: _controller.trimStart + 1,
  //               max: _controller.videoDuration,
  //               divisions:
  //                   (_controller.videoDuration - _controller.trimStart - 1)
  //                       .round(),
  //               onChanged: _controller.setTrimEnd,
  //               activeColor: Colors.blue,
  //             ),
  //           ),

  //           SizedBox(height: 12.h),
  //           Container(
  //             padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
  //             decoration: BoxDecoration(
  //               color: Colors.blue[50],
  //               borderRadius: BorderRadius.circular(6.r),
  //             ),
  //             child: Text(
  //               'Duration: ${(_controller.trimEnd - _controller.trimStart).toStringAsFixed(1)}s',
  //               style: TextStyle(
  //                 fontSize: 14.sp,
  //                 color: Colors.blue[800],
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildRotationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rotation',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: DropdownButton<int>(
                value: _controller.rotationDegrees,
                isExpanded: true,
                underline: const SizedBox(),
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[800]),
                items: [
                  DropdownMenuItem(value: 0, child: Text('0° (No Rotation)')),
                  DropdownMenuItem(value: 90, child: Text('90° (Clockwise)')),
                  DropdownMenuItem(
                    value: 180,
                    child: Text('180° (Upside Down)'),
                  ),
                  DropdownMenuItem(
                    value: 270,
                    child: Text('270° (Counter-Clockwise)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _controller.setRotation(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessButton() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed:
            _controller.isProcessing ? null : _controller.processAndSaveVideo,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
        ),
        child:
            _controller.isProcessing
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text('Processing...', style: TextStyle(fontSize: 16.sp)),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 20.w),
                    SizedBox(width: 8.w),
                    Text(
                      'Apply & Save',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 2,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.red[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 24.w),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                _controller.errorMessage!,
                style: TextStyle(fontSize: 14.sp, color: Colors.red[700]),
              ),
            ),
            IconButton(
              onPressed: _controller.clearError,
              icon: Icon(Icons.close, color: Colors.red[600], size: 20.w),
              constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.w),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
