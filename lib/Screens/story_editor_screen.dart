// ignore_for_file: deprecated_member_use, file_names

import 'dart:io';
import 'package:auto_clipper_app/Controller/story_editor_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class StoryEditorScreen extends StatelessWidget {
  const StoryEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StoryEditorController());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Obx(() {
        if (controller.selectedImage.value == null) {
          return _ImagePickerView(controller: controller);
        }
        return _EditorView(controller: controller);
      }),
    );
  }
}

// ─── Image Picker Landing ────────────────────────────────────────────────────

class _ImagePickerView extends StatelessWidget {
  final StoryEditorController controller;
  const _ImagePickerView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // AppBar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 16.sp),
                  ),
                ),
                SizedBox(width: 14.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Story Creator',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold)),
                    Text('Add photo & design your story',
                        style:
                        TextStyle(color: Colors.white54, fontSize: 12.sp)),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hero Illustration
                  Container(
                    width: 180.w,
                    height: 180.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDD2A7B).withOpacity(0.35),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(Icons.auto_awesome,
                        color: Colors.white, size: 72.sp),
                  ),
                  SizedBox(height: 32.h),

                  Text('Create Your Story',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5)),
                  SizedBox(height: 10.h),
                  Text(
                    'Pick a photo and add text, emojis\n& stickers like Instagram Stories',
                    textAlign: TextAlign.center,
                    style:
                    TextStyle(color: Colors.white54, fontSize: 14.sp, height: 1.5),
                  ),
                  SizedBox(height: 48.h),

                  // Gallery Button
                  _PickButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Choose from Gallery',
                    subtitle: 'Pick any photo',
                    gradientColors: const [Color(0xFF8134AF), Color(0xFFDD2A7B)],
                    onTap: controller.pickImageFromGallery,
                  ),
                  SizedBox(height: 16.h),

                  // Camera Button
                  _PickButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Take a Photo',
                    subtitle: 'Use your camera',
                    gradientColors: const [Color(0xFFF58529), Color(0xFFDD2A7B)],
                    onTap: controller.pickImageFromCamera,
                  ),

                  SizedBox(height: 32.h),
                  // Features hint row
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 8.h,
                    alignment: WrapAlignment.center,
                    children: ['📝 Text', '😊 Emoji', '⭐ Stickers', '📤 Share']
                        .map((t) => Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12.sp)),
                    ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  const _PickButton(
      {required this.icon,
        required this.label,
        required this.subtitle,
        required this.gradientColors,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: Colors.white, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12.sp)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16.sp),
          ],
        ),
      ),
    );
  }
}

// ─── Editor View ─────────────────────────────────────────────────────────────

class _EditorView extends StatelessWidget {
  final StoryEditorController controller;
  const _EditorView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final canvasHeight = size.width * (16 / 9);

    return Obx(() {
      final tool = controller.currentTool.value;

      return Stack(
        children: [
          // ── Main scaffold
          Scaffold(
            backgroundColor: const Color(0xFF0A0E1A),
            body: SafeArea(
              child: Column(
                children: [
                  // Top toolbar
                  _TopBar(controller: controller),

                  // Canvas
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: _StoryCanvas(
                          controller: controller,
                          canvasWidth: size.width - 24.w,
                          canvasHeight: (size.width - 24.w) * (16 / 9),
                        ),
                      ),
                    ),
                  ),

                  // Bottom toolbar
                  _BottomToolbar(controller: controller),
                ],
              ),
            ),
          ),

          // ── Overlay panels
          if (tool == 'text') _TextInputOverlay(controller: controller),
          if (tool == 'emoji') _EmojiPickerOverlay(controller: controller),
          if (tool == 'sticker') _StickerPickerOverlay(controller: controller),

          // Export loading
          if (controller.isExporting.value)
            Container(
              color: Colors.black87,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFDD2A7B)),
              ),
            ),
        ],
      );
    });
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final StoryEditorController controller;
  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16.sp),
            ),
          ),
          SizedBox(width: 10.w),

          // Change photo
          GestureDetector(
            onTap: controller.pickImageFromGallery,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.photo_library_outlined,
                      color: Colors.white70, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text('Change',
                      style:
                      TextStyle(color: Colors.white70, fontSize: 12.sp)),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Save
          GestureDetector(
            onTap: controller.saveToGallery,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.download_rounded, color: Colors.white70, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text('Save',
                      style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                ],
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Share
          GestureDetector(
            onTap: controller.exportAndShare,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDD2A7B).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.share_rounded, color: Colors.white, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text('Share',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Story Canvas ─────────────────────────────────────────────────────────────

class _StoryCanvas extends StatelessWidget {
  final StoryEditorController controller;
  final double canvasWidth;
  final double canvasHeight;

  const _StoryCanvas({
    required this.controller,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: controller.canvasKey,
      child: Container(
        width: canvasWidth,
        height: canvasHeight,
        margin: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: Colors.black,
        ),
        clipBehavior: Clip.hardEdge,
        child: GestureDetector(
          onTap: controller.clearSelection,
          child: Stack(
            children: [
              // Background image
              Obx(() => controller.selectedImage.value != null
                  ? Positioned.fill(
                child: Image.file(
                  controller.selectedImage.value!,
                  fit: BoxFit.cover,
                ),
              )
                  : const SizedBox()),

              // Dark overlay (subtle)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),

              // Text Elements
              Obx(() => Stack(
                children: List.generate(controller.textElements.length, (i) {
                  return _DraggableTextElement(
                    controller: controller,
                    index: i,
                  );
                }),
              )),

              // Emoji Elements
              Obx(() => Stack(
                children: List.generate(controller.emojiElements.length, (i) {
                  return _DraggableEmojiElement(
                    controller: controller,
                    index: i,
                  );
                }),
              )),

              // Sticker Elements
              Obx(() => Stack(
                children: List.generate(controller.stickerElements.length, (i) {
                  return _DraggableStickerElement(
                    controller: controller,
                    index: i,
                  );
                }),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Draggable Text ───────────────────────────────────────────────────────────

class _DraggableTextElement extends StatefulWidget {
  final StoryEditorController controller;
  final int index;
  const _DraggableTextElement(
      {required this.controller, required this.index});

  @override
  State<_DraggableTextElement> createState() => _DraggableTextElementState();
}

class _DraggableTextElementState extends State<_DraggableTextElement> {
  Offset _start = Offset.zero;
  double _startScaleSize = 28;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.index >= widget.controller.textElements.length) {
        return const SizedBox();
      }
      final el = widget.controller.textElements[widget.index];
      final isSelected =
          widget.controller.selectedTextIndex.value == widget.index;

      return Positioned(
        left: el.position.dx - 80,
        top: el.position.dy - 20,
        child: GestureDetector(
          onTap: () {
            widget.controller.selectedTextIndex.value = widget.index;
            widget.controller.selectedEmojiIndex.value = -1;
            widget.controller.selectedStickerIndex.value = -1;
          },
          onPanStart: (d) => _start = d.localPosition,
          onPanUpdate: (d) {
            final delta = d.localPosition - _start;
            _start = d.localPosition;
            widget.controller.updateTextPosition(
              widget.index,
              el.position + delta,
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: el.hasBg ? el.backgroundColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8.r),
              border: isSelected
                  ? Border.all(
                  color: Colors.white.withOpacity(0.6), width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  el.text,
                  textAlign: el.textAlign,
                  style: TextStyle(
                    color: el.color,
                    fontSize: el.fontSize.sp,
                    fontWeight: FontWeight.bold,
                    fontStyle: el.fontStyle,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...[
                  SizedBox(width: 6.w),
                  GestureDetector(
                    onTap: widget.controller.deleteSelectedText,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          color: Colors.white, size: 10.sp),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─── Draggable Emoji ──────────────────────────────────────────────────────────

class _DraggableEmojiElement extends StatefulWidget {
  final StoryEditorController controller;
  final int index;
  const _DraggableEmojiElement(
      {required this.controller, required this.index});

  @override
  State<_DraggableEmojiElement> createState() =>
      _DraggableEmojiElementState();
}

class _DraggableEmojiElementState extends State<_DraggableEmojiElement> {
  Offset _start = Offset.zero;
  double _prevScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.index >= widget.controller.emojiElements.length) {
        return const SizedBox();
      }
      final el = widget.controller.emojiElements[widget.index];
      final isSelected =
          widget.controller.selectedEmojiIndex.value == widget.index;

      return Positioned(
        left: el.position.dx - el.size / 2,
        top: el.position.dy - el.size / 2,
        child: GestureDetector(
          onTap: () {
            widget.controller.selectedEmojiIndex.value = widget.index;
            widget.controller.selectedTextIndex.value = -1;
            widget.controller.selectedStickerIndex.value = -1;
          },
          onPanStart: (d) => _start = d.localPosition,
          onPanUpdate: (d) {
            final delta = d.localPosition - _start;
            _start = d.localPosition;
            widget.controller
                .updateEmojiPosition(widget.index, el.position + delta);
          },
          onScaleStart: (d) => _prevScale = 1.0,
          onScaleUpdate: (d) {
            if (d.scale != 1.0) {
              final factor = d.scale / _prevScale;
              _prevScale = d.scale;
              widget.controller.updateEmojiSize(widget.index, factor);
            }
          },
          child: Stack(
            children: [
              Container(
                decoration: isSelected
                    ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.6), width: 1.5),
                )
                    : null,
                child: Text(
                  el.emoji,
                  style: TextStyle(fontSize: el.size),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: widget.controller.deleteSelectedEmoji,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child:
                      Icon(Icons.close, color: Colors.white, size: 10.sp),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Draggable Sticker ────────────────────────────────────────────────────────

class _DraggableStickerElement extends StatefulWidget {
  final StoryEditorController controller;
  final int index;
  const _DraggableStickerElement(
      {required this.controller, required this.index});

  @override
  State<_DraggableStickerElement> createState() =>
      _DraggableStickerElementState();
}

class _DraggableStickerElementState
    extends State<_DraggableStickerElement> {
  Offset _start = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.index >= widget.controller.stickerElements.length) {
        return const SizedBox();
      }
      final el = widget.controller.stickerElements[widget.index];
      final isSelected =
          widget.controller.selectedStickerIndex.value == widget.index;

      return Positioned(
        left: el.position.dx - el.size / 2,
        top: el.position.dy - el.size / 2,
        child: GestureDetector(
          onTap: () {
            widget.controller.selectedStickerIndex.value = widget.index;
            widget.controller.selectedTextIndex.value = -1;
            widget.controller.selectedEmojiIndex.value = -1;
          },
          onPanStart: (d) => _start = d.localPosition,
          onPanUpdate: (d) {
            final delta = d.localPosition - _start;
            _start = d.localPosition;
            widget.controller
                .updateStickerPosition(widget.index, el.position + delta);
          },
          child: Stack(
            children: [
              Container(
                width: el.size,
                height: el.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: isSelected
                      ? Border.all(
                      color: Colors.white.withOpacity(0.6), width: 1.5)
                      : null,
                ),
                child: Icon(el.icon, color: el.color, size: el.size * 0.55),
              ),
              if (isSelected)
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: widget.controller.deleteSelectedSticker,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child:
                      Icon(Icons.close, color: Colors.white, size: 10.sp),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Bottom Toolbar ───────────────────────────────────────────────────────────

class _BottomToolbar extends StatelessWidget {
  final StoryEditorController controller;
  const _BottomToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Obx(() {
        final tool = controller.currentTool.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolButton(
              icon: Icons.text_fields_rounded,
              label: 'Text',
              isActive: tool == 'text',
              gradient: const [Color(0xFF6C63FF), Color(0xFFFF6584)],
              onTap: () => controller.currentTool.value = 'text',
            ),
            _ToolButton(
              icon: Icons.emoji_emotions_outlined,
              label: 'Emoji',
              isActive: tool == 'emoji',
              gradient: const [Color(0xFFF58529), Color(0xFFDD2A7B)],
              onTap: () => controller.currentTool.value = 'emoji',
            ),
            _ToolButton(
              icon: Icons.star_outline_rounded,
              label: 'Sticker',
              isActive: tool == 'sticker',
              gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
              onTap: () => controller.currentTool.value = 'sticker',
            ),
            _ToolButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              isActive: false,
              gradient: const [Color(0xFF434343), Color(0xFF000000)],
              onTap: () {
                if (controller.textElements.isNotEmpty) {
                  controller.textElements.removeLast();
                } else if (controller.emojiElements.isNotEmpty) {
                  controller.emojiElements.removeLast();
                } else if (controller.stickerElements.isNotEmpty) {
                  controller.stickerElements.removeLast();
                }
              },
            ),
          ],
        );
      }),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: isActive ? LinearGradient(colors: gradient) : null,
          color: isActive ? null : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: isActive
              ? [
            BoxShadow(
                color: gradient[0].withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive ? Colors.white : Colors.white60,
                size: 22.sp),
            SizedBox(height: 4.h),
            Text(label,
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54,
                    fontSize: 10.sp,
                    fontWeight: isActive
                        ? FontWeight.bold
                        : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ─── Text Input Overlay ───────────────────────────────────────────────────────

class _TextInputOverlay extends StatelessWidget {
  final StoryEditorController controller;
  const _TextInputOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.currentTool.value = 'none',
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {}, // prevent close on inner tap
            child: Column(
              children: [
                // Top action row
                Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => controller.currentTool.value = 'none',
                        child: Text('Cancel',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14.sp)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          final size = MediaQuery.of(context).size;
                          controller.addTextElement(Offset(
                              size.width / 2,
                              size.height * 0.3));
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFDD2A7B), Color(0xFF8134AF)],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text('Add',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Text field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: TextField(
                    controller: controller.textController,
                    autofocus: true,
                    maxLines: 3,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Type something...',
                      hintStyle:
                      TextStyle(color: Colors.white38, fontSize: 18.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: const BorderSide(
                            color: Color(0xFFDD2A7B), width: 2),
                      ),
                      fillColor: Colors.white.withOpacity(0.07),
                      filled: true,
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // Font size slider
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Icon(Icons.text_fields, color: Colors.white54, size: 16.sp),
                      Expanded(
                        child: Obx(() => Slider(
                          value: controller.currentFontSize.value,
                          min: 14,
                          max: 60,
                          activeColor: const Color(0xFFDD2A7B),
                          inactiveColor: Colors.white24,
                          onChanged: (v) =>
                          controller.currentFontSize.value = v,
                        )),
                      ),
                      Icon(Icons.text_fields, color: Colors.white, size: 22.sp),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Text color picker
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Text Color',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12.sp)),
                      SizedBox(height: 8.h),
                      SizedBox(
                        height: 36.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: StoryEditorController.textColors.length,
                          separatorBuilder: (_, __) => SizedBox(width: 8.w),
                          itemBuilder: (_, i) {
                            final c = StoryEditorController.textColors[i];
                            return Obx(() => GestureDetector(
                              onTap: () =>
                              controller.currentTextColor.value = c,
                              child: Container(
                                width: 32.w,
                                height: 32.w,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: controller.currentTextColor.value ==
                                      c
                                      ? Border.all(
                                      color: Colors.white, width: 2.5)
                                      : Border.all(
                                      color: Colors.white24, width: 1),
                                ),
                              ),
                            ));
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Background toggle
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Obx(() => Row(
                    children: [
                      Text('Text Background',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12.sp)),
                      SizedBox(width: 12.w),
                      Switch(
                        value: controller.currentHasBg.value,
                        activeColor: const Color(0xFFDD2A7B),
                        onChanged: (v) =>
                        controller.currentHasBg.value = v,
                      ),
                      if (controller.currentHasBg.value) ...[
                        SizedBox(width: 8.w),
                        SizedBox(
                          height: 32.h,
                          child: ListView.separated(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount:
                            StoryEditorController.bgColors.length - 1,
                            separatorBuilder: (_, __) => SizedBox(width: 6.w),
                            itemBuilder: (_, i) {
                              final c =
                              StoryEditorController.bgColors[i + 1];
                              return GestureDetector(
                                onTap: () =>
                                controller.currentBgColor.value = c,
                                child: Container(
                                  width: 28.w,
                                  height: 28.w,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white38, width: 1),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Emoji Picker Overlay ─────────────────────────────────────────────────────

class _EmojiPickerOverlay extends StatelessWidget {
  final StoryEditorController controller;
  const _EmojiPickerOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: size.height * 0.45,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Text('Pick an Emoji',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => controller.currentTool.value = 'none',
                    child: Icon(Icons.close, color: Colors.white54, size: 20.sp),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1,
                  crossAxisSpacing: 4.w,
                  mainAxisSpacing: 4.h,
                ),
                itemCount: StoryEditorController.popularEmojis.length,
                itemBuilder: (_, i) {
                  final emoji = StoryEditorController.popularEmojis[i];
                  return GestureDetector(
                    onTap: () {
                      final s = MediaQuery.of(context).size;
                      controller.addEmoji(emoji,
                          Offset(s.width / 2, s.height * 0.35));
                    },
                    child: Center(
                      child: Text(emoji,
                          style: TextStyle(fontSize: 28.sp)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sticker Picker Overlay ───────────────────────────────────────────────────

class _StickerPickerOverlay extends StatelessWidget {
  final StoryEditorController controller;
  const _StickerPickerOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: size.height * 0.38,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Text('Stickers',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => controller.currentTool.value = 'none',
                    child: Icon(Icons.close, color: Colors.white54, size: 20.sp),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                ),
                itemCount: StoryEditorController.stickers.length,
                itemBuilder: (_, i) {
                  final s = StoryEditorController.stickers[i];
                  final icon = s['icon'] as IconData;
                  final color = s['color'] as Color;
                  return GestureDetector(
                    onTap: () {
                      final sc = MediaQuery.of(context).size;
                      controller.addSticker(
                          icon, color, Offset(sc.width / 2, sc.height * 0.35));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Icon(icon, color: color, size: 36.sp),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}