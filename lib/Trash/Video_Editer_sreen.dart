// // // ignore_for_file: deprecated_member_use

// // ignore_for_file: deprecated_member_use, use_super_parameters

// import 'package:auto_clipper_app/Constant/Colors.dart';
// import 'package:auto_clipper_app/Trash/Video_editor_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:video_player/video_player.dart';



// class VideoEditorScreen extends StatefulWidget {
//   const VideoEditorScreen({Key? key}) : super(key: key);

//   @override
//   State<VideoEditorScreen> createState() => _VideoEditorScreenState();
// }

// class _VideoEditorScreenState extends State<VideoEditorScreen>
//     with TickerProviderStateMixin {
//   late VideoEditorController _controller;
//   late AnimationController _fadeController;
//   late AnimationController _slideController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoEditorController();
    
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
    
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
//     );
    

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

//     _fadeController.forward();
//     _slideController.forward();
//   }

//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _slideController.dispose();
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color(0xFFF8F9FA),
//               Color(0xFFE3F2FD),
//               Color(0xFFFCE4EC),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: AnimatedBuilder(
//             animation: _controller,
//             builder: (context, child) {
//               // Show success dialog when processing is complete
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 if (_controller.showSuccessDialog) {
//                   _showSuccessDialog();
//                 }
//               });

//               return FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: SlideTransition(
//                   position: _slideAnimation,
//                   child: Column(
//                     children: [
//                       _buildGradientAppBar(),
//                       Expanded(
//                         child: SingleChildScrollView(
//                           physics: const BouncingScrollPhysics(),
//                           padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
//                           child: Column(
//                             children: [
//                               _buildVideoSelectionCard(),
//                               SizedBox(height: 24.h),
//                               if (_controller.selectedVideo != null) ...[
//                                 _buildVideoPreviewCard(),
//                                 SizedBox(height: 24.h),
//                                 _buildThumbnailTimelineCard(),
//                                 SizedBox(height: 24.h),
//                                 _buildRotationCard(),
//                                 SizedBox(height: 32.h),
//                                 _buildProcessButton(),
//                               ],
//                               if (_controller.errorMessage != null) ...[
//                                 SizedBox(height: 20.h),
//                                 _buildErrorCard(),
//                               ],
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildGradientAppBar() {
//     return Container(
//       height: 80.h,
//       decoration: BoxDecoration(
//         gradient: AppColors.primaryGradient,
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadowMedium,
//             blurRadius: 12.r,
//             offset: Offset(0, 4.h),
//           ),
//         ],
//       ),
//       child: Stack(
//         children: [
//           // Animated background pattern
//           Positioned.fill(
//             child: CustomPaint(
//               painter: GradientPatternPainter(),
//             ),
//           ),
//           // Content
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 20.w),
//             child: Row(
//               children: [
//                 // Container(
//                 //   width: 36.w,
//                 //   height: 36.w,
//                 //   decoration: BoxDecoration(
//                 //     color: AppColors.glassBackground,
//                 //     borderRadius: BorderRadius.circular(12.r),
//                 //     border: Border.all(color: AppColors.glassBorder),
//                 //   ),
//                 //   child: IconButton(
//                 //     onPressed: () => Navigator.pop(context),
//                 //     icon: Icon(
//                 //       Icons.arrow_back_ios_new,
//                 //       color: Colors.white,
//                 //       size: 18.w,
//                 //     ),
//                 //     padding: EdgeInsets.zero,
//                 //   ),
//                 // ),
//                 Expanded(
//                   child: Center(
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Logo placeholder - replace with your actual logo
//                         Container(
//                           width: 28.w,
//                           height: 28.w,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(8.r),
//                           ),
//                           child: Icon(
//                             Icons.content_cut,
//                             color: AppColors.primaryPurple,
//                             size: 16.w,
//                           ),
//                         ),
//                         SizedBox(width: 12.w),
//                         Text(
//                           'AutoClipper',
//                           style: TextStyle(
//                             fontSize: 22.sp,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                             letterSpacing: 0.5,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 36.w), // Balance the back button
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildVideoSelectionCard() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             Colors.white,
//             Colors.white.withOpacity(0.9),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(24.r),
//         border: Border.all(color: AppColors.borderLight),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadowLight,
//             blurRadius: 20.r,
//             offset: Offset(0, 8.h),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(28.w),
//         child: Column(
//           children: [
//             Container(
//               width: 80.w,
//               height: 80.w,
//               decoration: BoxDecoration(
//                 gradient: _controller.selectedVideo != null
//                     ? AppColors.primaryGradient
//                     : LinearGradient(
//                         colors: [AppColors.textTertiary, AppColors.textSecondary],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                 borderRadius: BorderRadius.circular(20.r),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.shadowMedium,
//                     blurRadius: 16.r,
//                     offset: Offset(0, 4.h),
//                   ),
//                 ],
//               ),
//               child: Icon(
//                 _controller.selectedVideo != null
//                     ? Icons.video_library
//                     : Icons.video_library_outlined,
//                 size: 36.w,
//                 color: Colors.white,
//               ),
//             ),
//             SizedBox(height: 20.h),
//             Text(
//               _controller.selectedVideo != null
//                   ? 'Video Ready for Editing'
//                   : 'Select Video to Begin',
//               style: TextStyle(
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.w600,
//                 color: _controller.selectedVideo != null
//                     ? AppColors.textPrimary
//                     : AppColors.textSecondary,
//               ),
//             ),
//             if (_controller.selectedVideo != null) ...[
//               SizedBox(height: 8.h),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
//                 decoration: BoxDecoration(
//                   gradient: AppColors.accentGradient,
//                   borderRadius: BorderRadius.circular(20.r),
//                 ),
//                 child: Text(
//                   '${_controller.videoDuration.toStringAsFixed(1)}s duration',
//                   style: TextStyle(
//                     fontSize: 12.sp,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ],
//             SizedBox(height: 24.h),
//             Container(
//               width: double.infinity,
//               height: 56.h,
//               decoration: BoxDecoration(
//                 gradient: AppColors.primaryGradient,
//                 borderRadius: BorderRadius.circular(16.r),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.primaryPink.withOpacity(0.3),
//                     blurRadius: 12.r,
//                     offset: Offset(0, 6.h),
//                   ),
//                 ],
//               ),
//               child: ElevatedButton(
//                 onPressed: _controller.pickVideo,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.transparent,
//                   shadowColor: Colors.transparent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16.r),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.folder_open, size: 20.w, color: Colors.white),
//                     SizedBox(width: 12.w),
//                     Text(
//                       'Choose from Gallery',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildVideoPreviewCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24.r),
//         border: Border.all(color: AppColors.borderLight),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadowLight,
//             blurRadius: 20.r,
//             offset: Offset(0, 8.h),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(24.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 6.w,
//                   height: 24.h,
//                   decoration: BoxDecoration(
//                     gradient: AppColors.primaryGradient,
//                     borderRadius: BorderRadius.circular(3.r),
//                   ),
//                 ),
//                 SizedBox(width: 12.w),
//                 Text(
//                   'Video Preview',
//                   style: TextStyle(
//                     fontSize: 20.sp,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 20.h),
//             Container(
//               width: double.infinity,
//               height: 220.h,
//               decoration: BoxDecoration(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.circular(16.r),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.shadowMedium,
//                     blurRadius: 16.r,
//                     offset: Offset(0, 4.h),
//                   ),
//                 ],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(16.r),
//                 child: _controller.videoController != null &&
//                         _controller.videoController!.value.isInitialized
//                     ? AspectRatio(
//                         aspectRatio: _controller.videoController!.value.aspectRatio,
//                         child: VideoPlayer(_controller.videoController!),
//                       )
//                     : _buildVideoLoadingState(),
//               ),
//             ),
//             SizedBox(height: 16.h),
//             Center(
//               child: Container(
//                 width: 64.w,
//                 height: 64.w,
//                 decoration: BoxDecoration(
//                   gradient: AppColors.primaryGradient,
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppColors.primaryPink.withOpacity(0.4),
//                       blurRadius: 12.r,
//                       offset: Offset(0, 4.h),
//                     ),
//                   ],
//                 ),
//                 child: IconButton(
//                   onPressed: () {
//                     if (_controller.videoController != null) {
//                       if (_controller.videoController!.value.isPlaying) {
//                         _controller.videoController!.pause();
//                       } else {
//                         _controller.videoController!.play();
//                       }
//                     }
//                   },
//                   icon: Icon(
//                     _controller.videoController?.value.isPlaying == true
//                         ? Icons.pause
//                         : Icons.play_arrow,
//                     size: 28.w,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildVideoLoadingState() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             Colors.black.withOpacity(0.8),
//             Colors.black.withOpacity(0.6),
//           ],
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 60.w,
//             height: 60.w,
//             decoration: BoxDecoration(
//               gradient: AppColors.primaryGradient,
//               shape: BoxShape.circle,
//             ),
//             child: const CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               strokeWidth: 3,
//             ),
//           ),
//           SizedBox(height: 16.h),
//           Text(
//             'Loading video...',
//             style: TextStyle(
//               color: Colors.white70,
//               fontSize: 14.sp,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildThumbnailTimelineCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24.r),
//         border: Border.all(color: AppColors.borderLight),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadowLight,
//             blurRadius: 20.r,
//             offset: Offset(0, 8.h),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(24.w),
//         child: Column(
//           children: [
//             // Enhanced Tab Bar
//             Container(
//               height: 48.h,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.grey[50]!, Colors.grey[100]!],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(24.r),
//                 border: Border.all(color: AppColors.borderLight),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(child: _buildTabButton('video', Icons.videocam, 'Video')),
//                   Expanded(child: _buildTabButton('audio', Icons.volume_up, 'Audio')),
//                 ],
//               ),
//             ),

//             SizedBox(height: 28.h),

//             // Enhanced Action Tabs
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildEnhancedActionTab('Split', Icons.content_cut, AppColors.primaryOrange),
//                 _buildEnhancedActionTab('Trim', Icons.crop, AppColors.primaryPink),
//                 _buildEnhancedActionTab('Speed', Icons.speed, AppColors.primaryPurple),
//               ],
//             ),

//             SizedBox(height: 32.h),

//             // Enhanced Timeline
//             _buildEnhancedTimeline(),

//             SizedBox(height: 24.h),

//             // Action-specific controls
//             if (_controller.activeAction == 'Trim') ...[
//               _buildTrimControls(),
//             ] else if (_controller.activeAction == 'Split') ...[
//               _buildSplitControls(),
//             ] else if (_controller.activeAction == 'Speed') ...[
//               _buildSpeedControls(),
//             ],

//             SizedBox(height: 24.h),

//             // Enhanced Action Button
//             _buildEnhancedActionButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTabButton(String tab, IconData icon, String label) {
//     final isActive = _controller.activeTab == tab;
//     return GestureDetector(
//       onTap: () => _controller.setActiveTab(tab),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         height: 44.h,
//         margin: EdgeInsets.all(2.w),
//         decoration: BoxDecoration(
//           gradient: isActive ? AppColors.primaryGradient : null,
//           color: isActive ? null : Colors.transparent,
//           borderRadius: BorderRadius.circular(22.r),
//           boxShadow: isActive
//               ? [
//                   BoxShadow(
//                     color: AppColors.primaryPink.withOpacity(0.3),
//                     blurRadius: 8.r,
//                     offset: Offset(0, 2.h),
//                   ),
//                 ]
//               : null,
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               size: 18.w,
//               color: isActive ? Colors.white : AppColors.textSecondary,
//             ),
//             SizedBox(width: 8.w),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 14.sp,
//                 fontWeight: FontWeight.w600,
//                 color: isActive ? Colors.white : AppColors.textSecondary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEnhancedActionTab(String title, IconData icon, Color color) {
//     final isActive = _controller.activeAction == title;
//     return GestureDetector(
//       onTap: () => _controller.setActiveAction(title),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
//         decoration: BoxDecoration(
//           gradient: isActive
//               ? LinearGradient(
//                   colors: [color, color.withOpacity(0.8)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 )
//               : null,
//           color: isActive ? null : Colors.grey[50],
//           borderRadius: BorderRadius.circular(16.r),
//           border: Border.all(
//             color: isActive ? color : AppColors.borderLight,
//             width: isActive ? 2 : 1,
//           ),
//           boxShadow: isActive
//               ? [
//                   BoxShadow(
//                     color: color.withOpacity(0.3),
//                     blurRadius: 8.r,
//                     offset: Offset(0, 4.h),
//                   ),
//                 ]
//               : null,
//         ),
//         child: Column(
//           children: [
//             Icon(
//               icon,
//               size: 24.w,
//               color: isActive ? Colors.white : color,
//             ),
//             SizedBox(height: 8.h),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 12.sp,
//                 fontWeight: FontWeight.w600,
//                 color: isActive ? Colors.white : AppColors.textPrimary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEnhancedTimeline() {
//     return Container(
//       height: 120.h,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.grey[50]!, Colors.white],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//         borderRadius: BorderRadius.circular(16.r),
//         border: Border.all(color: AppColors.borderLight),
//       ),
//       child: Column(
//         children: [
//           // Timeline header
//           Container(
//             height: 40.h,
//             padding: EdgeInsets.symmetric(horizontal: 16.w),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Timeline',
//                   style: TextStyle(
//                     fontSize: 12.sp,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//                 if (_controller.isGeneratingThumbnails)
//                   Row(
//                     children: [
//                       SizedBox(
//                         width: 12.w,
//                         height: 12.w,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
//                         ),
//                       ),
//                       SizedBox(width: 8.w),
//                       Text(
//                         'Generating...',
//                         style: TextStyle(
//                           fontSize: 10.sp,
//                           color: AppColors.textTertiary,
//                         ),
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//           ),
//           // Thumbnail strip
//           Expanded(
//             child: Container(
//               margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8.r),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.shadowLight,
//                     blurRadius: 4.r,
//                     offset: Offset(0, 2.h),
//                   ),
//                 ],
//               ),
//               child: _controller.isGeneratingThumbnails
//                   ? _buildThumbnailLoadingState()
//                   : _buildThumbnailRow(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildThumbnailLoadingState() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.grey[200]!, Colors.grey[100]!],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(8.r),
//       ),
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 24.w,
//               height: 24.w,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
//               ),
//             ),
//             SizedBox(height: 8.h),
//             Text(
//               'Creating thumbnails...',
//               style: TextStyle(
//                 fontSize: 10.sp,
//                 color: AppColors.textTertiary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildThumbnailRow() {
//     return Stack(
//       children: [
//         Row(
//           children: _controller.thumbnails.asMap().entries.map((entry) {
//             return Expanded(
//               child: Container(
//                 height: double.infinity,
//                 margin: EdgeInsets.only(right: 1.w),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(4.r),
//                   image: DecorationImage(
//                     image: MemoryImage(entry.value),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//         // Trim overlay
//         if (_controller.activeAction == 'Trim' && _controller.thumbnails.isNotEmpty)
//           _buildTrimOverlay(),
//       ],
//     );
//   }

//   Widget _buildTrimOverlay() {
//     return Positioned.fill(
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           final double totalWidth = constraints.maxWidth;
//           final double startPos = (_controller.trimStart / _controller.videoDuration) * totalWidth;
//           final double endPos = (_controller.trimEnd / _controller.videoDuration) * totalWidth;

//           return Stack(
//             children: [
//               // Dark overlays
//               if (startPos > 0)
//                 Positioned(
//                   left: 0,
//                   top: 0,
//                   width: startPos,
//                   height: double.infinity,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.7),
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(4.r),
//                         bottomLeft: Radius.circular(4.r),
//                       ),
//                     ),
//                   ),
//                 ),
//               if (endPos < totalWidth)
//                 Positioned(
//                   left: endPos,
//                   top: 0,
//                   width: totalWidth - endPos,
//                   height: double.infinity,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.7),
//                       borderRadius: BorderRadius.only(
//                         topRight: Radius.circular(4.r),
//                         bottomRight: Radius.circular(4.r),
//                       ),
//                     ),
//                   ),
//                 ),
//               // Selection border
//               Positioned(
//                 left: startPos,
//                 top: 0,
//                 width: endPos - startPos,
//                 height: double.infinity,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     border: Border.all(color: AppColors.primaryPink, width: 3),
//                     borderRadius: BorderRadius.circular(4.r),
//                   ),
//                 ),
//               ),
//               // Trim handles
//               _buildTrimHandle(startPos, true),
//               _buildTrimHandle(endPos, false),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildTrimHandle(double position, bool isStart) {
//     return Positioned(
//       left: position - 6.w,
//       top: -4.h,
//       child: Container(
//         width: 12.w,
//         height: 68.h,
//         decoration: BoxDecoration(
//           gradient: AppColors.accentGradient,
//           borderRadius: BorderRadius.circular(6.r),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.primaryPink.withOpacity(0.4),
//               blurRadius: 4.r,
//               offset: Offset(0, 2.h),
//             ),
//           ],
//         ),
//         child: Center(
//           child:           Container(
//             width: 4.w,
//             height: 40.h,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(2.r),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTrimControls() {
//     return Column(
//       children: [
//         SizedBox(height: 16.h),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               _controller.formatTime(_controller.trimStart),
//               style: TextStyle(
//                 fontSize: 12.sp,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.textPrimary,
//               ),
//             ),
//             Text(
//               _controller.formatTime(_controller.trimEnd),
//               style: TextStyle(
//                 fontSize: 12.sp,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.textPrimary,
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: 12.h),
//         RangeSlider(
//           values: RangeValues(
//             _controller.trimStart.clamp(0.0, _controller.videoDuration),
//             _controller.trimEnd.clamp(0.0, _controller.videoDuration),
//           ),
//           min: 0.0,
//           max: _controller.videoDuration,
//           divisions: _controller.videoDuration.round(),
//           activeColor: AppColors.primaryPink,
//           inactiveColor: AppColors.borderLight,
//           onChanged: (RangeValues values) {
//             _controller.setTrimStart(values.start);
//             _controller.setTrimEnd(values.end);
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildSplitControls() {
//     return Column(
//       children: [
//         SizedBox(height: 16.h),
//         Text(
//           'Split Position: ${_controller.formatTime(_controller.splitPosition)}',
//           style: TextStyle(
//             fontSize: 14.sp,
//             fontWeight: FontWeight.w600,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         SizedBox(height: 12.h),
//         Slider(
//           value: _controller.splitPosition,
//           min: 0.0,
//           max: _controller.videoDuration,
//           divisions: _controller.videoDuration.round(),
//           activeColor: AppColors.primaryOrange,
//           inactiveColor: AppColors.borderLight,
//           onChanged: (value) {
//             _controller.setSplitPosition(value);
//           },
//         ),
//         SizedBox(height: 12.h),
//         Container(
//           width: double.infinity,
//           height: 48.h,
//           decoration: BoxDecoration(
//             gradient: AppColors.accentGradient,
//             borderRadius: BorderRadius.circular(12.r),
//             boxShadow: [
//               BoxShadow(
//                 color: AppColors.primaryPink.withOpacity(0.3),
//                 blurRadius: 8.r,
//                 offset: Offset(0, 4.h),
//               ),
//             ],
//           ),
//           child: ElevatedButton(
//             onPressed:
//                 () => _controller.addSplitPoint(_controller.splitPosition),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.transparent,
//               shadowColor: Colors.transparent,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12.r),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.add, size: 20.w, color: Colors.white),
//                 SizedBox(width: 8.w),
//                 Text(
//                   'Add Split Point',
//                   style: TextStyle(
//                     fontSize: 14.sp,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         SizedBox(height: 16.h),
//         if (_controller.splitPoints.isNotEmpty) ...[
//           Text(
//             'Split Points:',
//             style: TextStyle(
//               fontSize: 14.sp,
//               fontWeight: FontWeight.w600,
//               color: AppColors.textPrimary,
//             ),
//           ),
//           SizedBox(height: 8.h),
//           Wrap(
//             spacing: 8.w,
//             runSpacing: 8.h,
//             children:
//                 _controller.splitPoints.map((point) {
//                   return Chip(
//                     label: Text(
//                       _controller.formatTime(point),
//                       style: TextStyle(fontSize: 12.sp),
//                     ),
//                     deleteIcon: Icon(Icons.close, size: 14.w),
//                     onDeleted: () => _controller.removeSplitPoint(point),
//                     backgroundColor: AppColors.primaryOrange.withOpacity(0.2),
//                     labelPadding: EdgeInsets.symmetric(horizontal: 8.w),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8.r),
//                     ),
//                   );
//                 }).toList(),
//           ),
//           SizedBox(height: 16.h),
//         ],
//       ],
//     );
//   }

//   Widget _buildSpeedControls() {
//     return Column(
//       children: [
//         SizedBox(height: 16.h),
//         Text(
//           'Speed: ${_controller.speedMultiplier.toStringAsFixed(2)}x',
//           style: TextStyle(
//             fontSize: 14.sp,
//             fontWeight: FontWeight.w600,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         SizedBox(height: 12.h),
//         Slider(
//           value: _controller.speedMultiplier,
//           min: 0.25,
//           max: 4.0,
//           divisions: 15,
//           activeColor: AppColors.primaryPurple,
//           inactiveColor: AppColors.borderLight,
//           onChanged: (value) {
//             _controller.setSpeedMultiplier(value);
//           },
//         ),
//         SizedBox(height: 12.h),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             _buildSpeedPresetButton('0.5x', 0.5),
//             _buildSpeedPresetButton('1x', 1.0),
//             _buildSpeedPresetButton('1.5x', 1.5),
//             _buildSpeedPresetButton('2x', 2.0),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildSpeedPresetButton(String label, double speed) {
//     final isSelected = (_controller.speedMultiplier - speed).abs() < 0.01;
//     return GestureDetector(
//       onTap: () => _controller.setSpeedMultiplier(speed),
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//         decoration: BoxDecoration(
//           gradient: isSelected ? AppColors.secondaryGradient : null,
//           color: isSelected ? null : AppColors.cardBackground,
//           borderRadius: BorderRadius.circular(12.r),
//           border: Border.all(
//             color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
//             width: isSelected ? 2 : 1,
//           ),
//           boxShadow:
//               isSelected
//                   ? [
//                     BoxShadow(
//                       color: AppColors.primaryBlue.withOpacity(0.2),
//                       blurRadius: 8.r,
//                       offset: Offset(0, 4.h),
//                     ),
//                   ]
//                   : null,
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontSize: 12.sp,
//             fontWeight: FontWeight.w600,
//             color: isSelected ? Colors.white : AppColors.textPrimary,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEnhancedActionButton() {
//     return Container(
//       width: double.infinity,
//       height: 56.h,
//       decoration: BoxDecoration(
//         gradient: AppColors.primaryGradient,
//         borderRadius: BorderRadius.circular(16.r),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primaryPink.withOpacity(0.4),
//             blurRadius: 12.r,
//             offset: Offset(0, 6.h),
//           ),
//         ],
//       ),
//       child: ElevatedButton(
//         onPressed:
//             _controller.isProcessing
//                 ? null
//                 : () {
//                   if (_controller.activeAction == 'Trim') {
//                     _controller.trimVideo();
//                   } else if (_controller.activeAction == 'Split') {
//                     _controller.splitVideo();
//                   } else if (_controller.activeAction == 'Speed') {
//                     _controller.speedVideo();
//                   }
//                 },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16.r),
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               _controller.activeAction == 'Trim'
//                   ? Icons.crop
//                   : _controller.activeAction == 'Split'
//                   ? Icons.content_cut
//                   : Icons.speed,
//               size: 20.w,
//               color: Colors.white,
//             ),
//             SizedBox(width: 12.w),
//             Text(
//               _controller.activeAction,
//               style: TextStyle(
//                 fontSize: 16.sp,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//               ),
//             ),
//             if (_controller.isProcessing) ...[
//               SizedBox(width: 12.w),
//               SizedBox(
//                 width: 16.w,
//                 height: 16.w,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRotationCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24.r),
//         border: Border.all(color: AppColors.borderLight),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadowLight,
//             blurRadius: 20.r,
//             offset: Offset(0, 8.h),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(24.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 6.w,
//                   height: 24.h,
//                   decoration: BoxDecoration(
//                     gradient: AppColors.primaryGradient,
//                     borderRadius: BorderRadius.circular(3.r),
//                   ),
//                 ),
//                 SizedBox(width: 12.w),
//                 Text(
//                   'Rotation',
//                   style: TextStyle(
//                     fontSize: 20.sp,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 20.h),
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.symmetric(horizontal: 16.w),
//               decoration: BoxDecoration(
//                 color: AppColors.backgroundColor,
//                 borderRadius: BorderRadius.circular(16.r),
//                 border: Border.all(color: AppColors.borderLight),
//               ),
//               child: DropdownButton<int>(
//                 value: _controller.rotationDegrees,
//                 isExpanded: true,
//                 underline: const SizedBox(),
//                 style: TextStyle(
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.w500,
//                   color: AppColors.textPrimary,
//                 ),
//                 items: [
//                   DropdownMenuItem(value: 0, child: Text('0° (No Rotation)')),
//                   DropdownMenuItem(value: 90, child: Text('90° (Clockwise)')),
//                   DropdownMenuItem(
//                     value: 180,
//                     child: Text('180° (Upside Down)'),
//                   ),
//                   DropdownMenuItem(
//                     value: 270,
//                     child: Text('270° (Counter-Clockwise)'),
//                   ),
//                 ],
//                 onChanged: (value) {
//                   if (value != null) {
//                     _controller.setRotation(value);
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProcessButton() {
//     return Container(
//       width: double.infinity,
//       height: 56.h,
//       decoration: BoxDecoration(
//         gradient: AppColors.secondaryGradient,
//         borderRadius: BorderRadius.circular(16.r),
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.primaryBlue.withOpacity(0.4),
//             blurRadius: 12.r,
//             offset: Offset(0, 6.h),
//           ),
//         ],
//       ),
//       child: ElevatedButton(
//         onPressed:
//             _controller.isProcessing ? null : _controller.processAndSaveVideo,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16.r),
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.check_circle, size: 20.w, color: Colors.white),
//             SizedBox(width: 12.w),
//             Text(
//               'Apply & Save',
//               style: TextStyle(
//                 fontSize: 16.sp,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//               ),
//             ),
//             if (_controller.isProcessing) ...[
//               SizedBox(width: 12.w),
//               SizedBox(
//                 width: 16.w,
//                 height: 16.w,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.errorColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16.r),
//         border: Border.all(color: AppColors.errorColor.withOpacity(0.3)),
//       ),
//       padding: EdgeInsets.all(16.w),
//       child: Row(
//         children: [
//           Icon(Icons.error_outline, color: AppColors.errorColor, size: 24.w),
//           SizedBox(width: 12.w),
//           Expanded(
//             child: Text(
//               _controller.errorMessage!,
//               style: TextStyle(
//                 fontSize: 14.sp,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.errorColor,
//               ),
//             ),
//           ),
//           IconButton(
//             onPressed: _controller.clearError,
//             icon: Icon(Icons.close, color: AppColors.errorColor, size: 20.w),
//             padding: EdgeInsets.zero,
//             constraints: BoxConstraints(),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(28.r),
//           ),
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [Colors.white, Colors.white, AppColors.backgroundColor],
//               ),
//               borderRadius: BorderRadius.circular(28.r),
//             ),
//             padding: EdgeInsets.all(28.w),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 80.w,
//                   height: 80.w,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         AppColors.successColor,
//                         AppColors.successColor.withOpacity(0.8),
//                       ],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: AppColors.successColor.withOpacity(0.3),
//                         blurRadius: 12.r,
//                         offset: Offset(0, 4.h),
//                       ),
//                     ],
//                   ),
//                   child: Icon(Icons.check, size: 40.w, color: Colors.white),
//                 ),
//                 SizedBox(height: 24.h),
//                 Text(
//                   'Video Saved Successfully!',
//                   style: TextStyle(
//                     fontSize: 22.sp,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 SizedBox(height: 12.h),
//                 Text(
//                   'Your edited video has been saved to the gallery.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 14.sp,
//                     color: AppColors.textSecondary,
//                   ),
//                 ),
//                 SizedBox(height: 24.h),
//                 if (_controller.processedVideo != null)
//                   Container(
//                     width: 120.w,
//                     height: 80.h,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12.r),
//                       border: Border.all(color: AppColors.borderLight),
//                       image: DecorationImage(
//                         image: MemoryImage(_controller.processedThumbnail!),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                 SizedBox(height: 32.h),
//                 Container(
//                   width: double.infinity,
//                   height: 56.h,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         AppColors.successColor,
//                         AppColors.successColor.withOpacity(0.8),
//                       ],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(16.r),
//                     boxShadow: [
//                       BoxShadow(
//                         color: AppColors.successColor.withOpacity(0.3),
//                         blurRadius: 8.r,
//                         offset: Offset(0, 4.h),
//                       ),
//                     ],
//                   ),
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                       _controller.hideSuccessDialog();
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.transparent,
//                       shadowColor: Colors.transparent,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16.r),
//                       ),
//                     ),
//                     child: Text(
//                       'Done',
//                       style: TextStyle(
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class GradientPatternPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint =
//         Paint()
//           ..shader = LinearGradient(
//             colors: [
//               Colors.white.withOpacity(0.05),
//               Colors.white.withOpacity(0.02),
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

//     final path = Path();
//     final spacing = 40.0;

//     for (double x = 0; x < size.width; x += spacing) {
//       for (double y = 0; y < size.height; y += spacing) {
//         path.addOval(Rect.fromCircle(center: Offset(x, y), radius: 1.0));
//       }
//     }

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }





