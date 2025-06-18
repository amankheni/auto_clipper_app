// import 'package:auto_clipper_app/widget/Custom_Slider_ThumbShape.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// // Enum for watermark positions
// enum WatermarkPosition { topLeft, topRight, bottomLeft, bottomRight, center }

// class WatermarkSection extends StatefulWidget {
//   @override
//   _WatermarkSectionState createState() => _WatermarkSectionState();
// }

// class _WatermarkSectionState extends State<WatermarkSection>
//     with SingleTickerProviderStateMixin {
//   bool _useWatermark = false;
//   bool _isProcessing = false;
//   String? _selectedWatermarkPath;
//   double _watermarkOpacity = 0.5;
//   WatermarkPosition _watermarkPosition = WatermarkPosition.bottomRight;
//   late AnimationController _animationController;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _animation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     );
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _pickWatermark() async {
//     // Simulate file picking
//     setState(() {
//       _isProcessing = true;
//     });

//     // Simulate delay
//     await Future.delayed(Duration(milliseconds: 500));

//     setState(() {
//       _selectedWatermarkPath = "watermark_image.png";
//       _isProcessing = false;
//     });
//   }

//   Widget _buildToggleSwitch() {
//     return GestureDetector(
//       onTap:
//           _isProcessing
//               ? null
//               : () {
//                 setState(() {
//                   _useWatermark = !_useWatermark;
//                 });
//                 if (_useWatermark) {
//                   _animationController.forward();
//                 } else {
//                   _animationController.reverse();
//                 }
//               },
//       child: AnimatedContainer(
//         duration: Duration(milliseconds: 300),
//         width: 56.w,
//         height: 28.h,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14.r),
//           gradient: LinearGradient(
//             colors:
//                 _useWatermark
//                     ? [Color(0xFFE91E63), Color(0xFFE91E63).withOpacity(0.8)]
//                     : [Colors.grey.shade300, Colors.grey.shade400],
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: (_useWatermark ? Color(0xFFE91E63) : Colors.grey)
//                   .withOpacity(0.3),
//               blurRadius: 8.r,
//               offset: Offset(0, 3.h),
//             ),
//           ],
//         ),
//         child: Stack(
//           children: [
//             AnimatedPositioned(
//               duration: Duration(milliseconds: 300),
//               curve: Curves.easeInOut,
//               left: _useWatermark ? 30.w : 2.w,
//               top: 2.h,
//               child: Container(
//                 width: 24.w,
//                 height: 24.h,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12.r),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.15),
//                       blurRadius: 4.r,
//                       offset: Offset(0, 2.h),
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   _useWatermark ? Icons.check : Icons.close,
//                   size: 12.sp,
//                   color:
//                       _useWatermark ? Color(0xFFE91E63) : Colors.grey.shade600,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOpacitySection() {
//     return Container(
//       padding: EdgeInsets.all(20.r),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.grey.shade50, Colors.white],
//         ),
//         borderRadius: BorderRadius.circular(16.r),
//         border: Border.all(color: Colors.grey.shade200, width: 1.w),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     Icons.opacity_rounded,
//                     color: Color(0xFFE91E63),
//                     size: 18.sp,
//                   ),
//                   SizedBox(width: 8.w),
//                   Text(
//                     'Opacity',
//                     style: TextStyle(
//                       fontSize: 15.sp,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey.shade800,
//                     ),
//                   ),
//                 ],
//               ),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Color(0xFFE91E63),
//                       Color(0xFFE91E63).withOpacity(0.8),
//                     ],
//                   ),
//                   borderRadius: BorderRadius.circular(16.r),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Color(0xFFE91E63).withOpacity(0.25),
//                       blurRadius: 6.r,
//                       offset: Offset(0, 3.h),
//                     ),
//                   ],
//                 ),
//                 child: Text(
//                   '${(_watermarkOpacity * 100).round()}%',
//                   style: TextStyle(
//                     fontSize: 12.sp,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 20.h),

//           // Custom Slider
//           SliderTheme(
//             data: SliderTheme.of(context).copyWith(
//               trackHeight: 6.h,
//               thumbShape: CustomSliderThumbShape(
//                 enabledThumbRadius: 12.r,
//                 elevation: 3,
//               ),
//               overlayShape: RoundSliderOverlayShape(overlayRadius: 18.r),
//               activeTrackColor: Color(0xFFE91E63),
//               inactiveTrackColor: Colors.grey.shade300,
//               thumbColor: Colors.white,
//               overlayColor: Color(0xFFE91E63).withOpacity(0.2),
//             ),
//             child: Slider(
//               value: _watermarkOpacity,
//               min: 0.1,
//               max: 1.0,
//               divisions: 9,
//               onChanged:
//                   _isProcessing
//                       ? null
//                       : (value) {
//                         setState(() {
//                           _watermarkOpacity = value;
//                         });
//                       },
//             ),
//           ),

//           // Opacity indicators
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 8.w),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   '10%',
//                   style: TextStyle(
//                     fontSize: 10.sp,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//                 Text(
//                   '100%',
//                   style: TextStyle(
//                     fontSize: 10.sp,
//                     fontWeight: FontWeight.w500,
//                     color: Color(0xFFE91E63),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.white, Colors.grey.shade50],
//         ),
//         borderRadius: BorderRadius.circular(20.r),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 20.r,
//             offset: Offset(0, 8.h),
//             spreadRadius: 0,
//           ),
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 6.r,
//             offset: Offset(0, 2.h),
//             spreadRadius: 0,
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20.r),
//         child: Container(
//           padding: EdgeInsets.all(24.r),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header Section
//               Row(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.all(10.r),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           Color(0xFFE91E63),
//                           Color(0xFFE91E63).withOpacity(0.8),
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(12.r),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Color(0xFFE91E63).withOpacity(0.3),
//                           blurRadius: 8.r,
//                           offset: Offset(0, 4.h),
//                         ),
//                       ],
//                     ),
//                     child: Icon(
//                       Icons.layers_rounded,
//                       color: Colors.white,
//                       size: 20.sp,
//                     ),
//                   ),
//                   SizedBox(width: 14.w),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Watermark Settings',
//                           style: TextStyle(
//                             fontSize: 18.sp,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey.shade800,
//                             letterSpacing: -0.3,
//                           ),
//                         ),
//                         SizedBox(height: 2.h),
//                         Text(
//                           'Customize your watermark appearance',
//                           style: TextStyle(
//                             fontSize: 12.sp,
//                             color: Colors.grey.shade600,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   _buildToggleSwitch(),
//                 ],
//               ),

//               // Expandable Content
//               AnimatedSize(
//                 duration: Duration(milliseconds: 400),
//                 curve: Curves.easeInOutCubic,
//                 child:
//                     _useWatermark
//                         ? Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             SizedBox(height: 24.h),

//                             // Watermark File Selection
//                             Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(16.r),
//                                 border: Border.all(
//                                   color:
//                                       _selectedWatermarkPath != null
//                                           ? Color(0xFFE91E63)
//                                           : Colors.grey.shade300,
//                                   width: 1.5.w,
//                                 ),
//                                 gradient:
//                                     _selectedWatermarkPath != null
//                                         ? LinearGradient(
//                                           colors: [
//                                             Color(0xFFE91E63).withOpacity(0.04),
//                                             Color(0xFFE91E63).withOpacity(0.02),
//                                           ],
//                                         )
//                                         : null,
//                               ),
//                               child: Material(
//                                 color: Colors.transparent,
//                                 child: InkWell(
//                                   onTap: _isProcessing ? null : _pickWatermark,
//                                   borderRadius: BorderRadius.circular(16.r),
//                                   child: Container(
//                                     padding: EdgeInsets.all(16.r),
//                                     child: Row(
//                                       children: [
//                                         AnimatedContainer(
//                                           duration: Duration(milliseconds: 300),
//                                           padding: EdgeInsets.all(10.r),
//                                           decoration: BoxDecoration(
//                                             color:
//                                                 _selectedWatermarkPath != null
//                                                     ? Color(
//                                                       0xFFE91E63,
//                                                     ).withOpacity(0.1)
//                                                     : Colors.grey.shade100,
//                                             borderRadius: BorderRadius.circular(
//                                               10.r,
//                                             ),
//                                           ),
//                                           child: Icon(
//                                             _selectedWatermarkPath != null
//                                                 ? Icons.check_circle_rounded
//                                                 : Icons
//                                                     .add_photo_alternate_rounded,
//                                             color:
//                                                 _selectedWatermarkPath != null
//                                                     ? Color(0xFFE91E63)
//                                                     : Colors.grey.shade600,
//                                             size: 24.sp,
//                                           ),
//                                         ),
//                                         SizedBox(width: 12.w),
//                                         Expanded(
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 _selectedWatermarkPath == null
//                                                     ? 'Select Watermark Image'
//                                                     : 'Watermark Selected',
//                                                 style: TextStyle(
//                                                   fontSize: 14.sp,
//                                                   fontWeight: FontWeight.w600,
//                                                   color:
//                                                       _selectedWatermarkPath !=
//                                                               null
//                                                           ? Color(0xFFE91E63)
//                                                           : Colors
//                                                               .grey
//                                                               .shade800,
//                                                 ),
//                                               ),
//                                               SizedBox(height: 3.h),
//                                               Text(
//                                                 _selectedWatermarkPath == null
//                                                     ? 'JPG, PNG formats supported'
//                                                     : 'Ready to apply watermark',
//                                                 style: TextStyle(
//                                                   fontSize: 11.sp,
//                                                   color: Colors.grey.shade600,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         if (_selectedWatermarkPath != null)
//                                           Container(
//                                             padding: EdgeInsets.all(6.r),
//                                             decoration: BoxDecoration(
//                                               color: Color(
//                                                 0xFFE91E63,
//                                               ).withOpacity(0.1),
//                                               borderRadius:
//                                                   BorderRadius.circular(6.r),
//                                             ),
//                                             child: Icon(
//                                               Icons.arrow_forward_ios_rounded,
//                                               size: 12.sp,
//                                               color: Color(0xFFE91E63),
//                                             ),
//                                           ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),

//                             SizedBox(height: 20.h),

//                             // Opacity Section
//                             _buildOpacitySection(),

//                             SizedBox(height: 20.h),

//                             // Position Selection
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Icon(
//                                       Icons.photo_size_select_actual_rounded,
//                                       color: Color(0xFFE91E63),
//                                       size: 18.sp,
//                                     ),
//                                     SizedBox(width: 8.w),
//                                     Text(
//                                       'Position',
//                                       style: TextStyle(
//                                         fontSize: 15.sp,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.grey.shade800,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(height: 12.h),
//                                 Container(
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(12.r),
//                                     border: Border.all(
//                                       color: Colors.grey.shade300,
//                                       width: 1.w,
//                                     ),
//                                     gradient: LinearGradient(
//                                       colors: [
//                                         Colors.white,
//                                         Colors.grey.shade50,
//                                       ],
//                                     ),
//                                   ),
//                                   child: DropdownButtonFormField<
//                                     WatermarkPosition
//                                   >(
//                                     value: _watermarkPosition,
//                                     decoration: InputDecoration(
//                                       border: InputBorder.none,
//                                       contentPadding: EdgeInsets.symmetric(
//                                         horizontal: 16.w,
//                                         vertical: 12.h,
//                                       ),
//                                       suffixIcon: Icon(
//                                         Icons.keyboard_arrow_down_rounded,
//                                         color: Color(0xFFE91E63),
//                                         size: 20.sp,
//                                       ),
//                                     ),
//                                     dropdownColor: Colors.white,
//                                     style: TextStyle(
//                                       fontSize: 13.sp,
//                                       color: Colors.grey.shade800,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                     items: const [
//                                       DropdownMenuItem(
//                                         value: WatermarkPosition.topLeft,
//                                         child: Row(
//                                           children: [
//                                             Icon(Icons.north_west, size: 14),
//                                             SizedBox(width: 6),
//                                             Text('Top Left'),
//                                           ],
//                                         ),
//                                       ),
//                                       DropdownMenuItem(
//                                         value: WatermarkPosition.topRight,
//                                         child: Row(
//                                           children: [
//                                             Icon(Icons.north_east, size: 14),
//                                             SizedBox(width: 6),
//                                             Text('Top Right'),
//                                           ],
//                                         ),
//                                       ),
//                                       DropdownMenuItem(
//                                         value: WatermarkPosition.bottomLeft,
//                                         child: Row(
//                                           children: [
//                                             Icon(Icons.south_west, size: 14),
//                                             SizedBox(width: 6),
//                                             Text('Bottom Left'),
//                                           ],
//                                         ),
//                                       ),
//                                       DropdownMenuItem(
//                                         value: WatermarkPosition.bottomRight,
//                                         child: Row(
//                                           children: [
//                                             Icon(Icons.south_east, size: 14),
//                                             SizedBox(width: 6),
//                                             Text('Bottom Right'),
//                                           ],
//                                         ),
//                                       ),
//                                       DropdownMenuItem(
//                                         value: WatermarkPosition.center,
//                                         child: Row(
//                                           children: [
//                                             Icon(
//                                               Icons.center_focus_strong,
//                                               size: 14,
//                                             ),
//                                             SizedBox(width: 6),
//                                             Text('Center'),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                     onChanged:
//                                         _isProcessing
//                                             ? null
//                                             : (value) {
//                                               setState(() {
//                                                 _watermarkPosition = value!;
//                                               });
//                                             },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         )
//                         : SizedBox.shrink(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
