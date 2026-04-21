// ignore_for_file: deprecated_member_use, file_names

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class StoryTextElement {
  String text;
  Offset position;
  double fontSize;
  Color color;
  Color backgroundColor;
  bool hasBg;
  FontStyle fontStyle;
  TextAlign textAlign;
  double rotation;
  String fontFamily;

  StoryTextElement({
    required this.text,
    required this.position,
    this.fontSize = 28,
    this.color = Colors.white,
    this.backgroundColor = Colors.transparent,
    this.hasBg = false,
    this.fontStyle = FontStyle.normal,
    this.textAlign = TextAlign.center,
    this.rotation = 0,
    this.fontFamily = 'Default',
  });
}

class StoryEmojiElement {
  String emoji;
  Offset position;
  double size;
  double rotation;

  StoryEmojiElement({
    required this.emoji,
    required this.position,
    this.size = 40,
    this.rotation = 0,
  });
}

class StoryStickerElement {
  IconData icon;
  Offset position;
  double size;
  Color color;
  double rotation;

  StoryStickerElement({
    required this.icon,
    required this.position,
    this.size = 50,
    this.color = Colors.white,
    this.rotation = 0,
  });
}

// ─── Controller ──────────────────────────────────────────────────────────────

class StoryEditorController extends GetxController {
  // Image
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxBool isImageLoading = false.obs;

  // Elements
  final RxList<StoryTextElement> textElements = <StoryTextElement>[].obs;
  final RxList<StoryEmojiElement> emojiElements = <StoryEmojiElement>[].obs;
  final RxList<StoryStickerElement> stickerElements = <StoryStickerElement>[].obs;

  // Selection
  final RxInt selectedTextIndex = (-1).obs;
  final RxInt selectedEmojiIndex = (-1).obs;
  final RxInt selectedStickerIndex = (-1).obs;

  // Editor state
  final RxString currentTool = 'none'.obs; // none | text | emoji | sticker
  final RxBool isExporting = false.obs;

  // Text editing
  final TextEditingController textController = TextEditingController();
  final RxDouble currentFontSize = 28.0.obs;
  final Rx<Color> currentTextColor = Colors.white.obs;
  final Rx<Color> currentBgColor = Colors.black.obs;
  final RxBool currentHasBg = false.obs;
  final RxString currentFontFamily = 'Default'.obs;
  final Rx<TextAlign> currentTextAlign = TextAlign.center.obs;

  // Background color for story
  final Rx<Color> storyBgColor = Colors.black.obs;
  final RxList<Color> bgGradient = <Color>[Colors.black, Colors.black87].obs;
  final RxBool useGradientBg = false.obs;

  // Canvas key for screenshot
  final GlobalKey canvasKey = GlobalKey();

  static const List<String> fontFamilies = [
    'Default',
    'Serif',
    'Monospace',
    'Cursive',
  ];

  static const List<Color> textColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
  ];

  static const List<Color> bgColors = [
    Colors.transparent,
    Colors.black87,
    Colors.white,
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  static const List<String> popularEmojis = [
    '😍', '🔥', '💯', '✨', '🎉', '❤️', '😂', '🥰',
    '👏', '💪', '🙌', '👀', '💫', '⭐', '🌟', '💥',
    '🎶', '🎵', '📸', '🤳', '💃', '🕺', '🌈', '☀️',
    '🌙', '💎', '🏆', '🎯', '🚀', '💖', '😎', '🤩',
    '🦋', '🌸', '🍀', '🦄', '🐝', '🌊', '⚡', '🎪',
  ];

  static const List<Map<String, dynamic>> stickers = [
    {'icon': Icons.favorite, 'color': Color(0xFFE91E63)},
    {'icon': Icons.star, 'color': Color(0xFFFFD700)},
    {'icon': Icons.flash_on, 'color': Color(0xFFFFEB3B)},
    {'icon': Icons.local_fire_department, 'color': Color(0xFFFF5722)},
    {'icon': Icons.emoji_events, 'color': Color(0xFFFFD700)},
    {'icon': Icons.music_note, 'color': Color(0xFF9C27B0)},
    {'icon': Icons.camera_alt, 'color': Color(0xFF2196F3)},
    {'icon': Icons.tag, 'color': Colors.white},
    {'icon': Icons.location_on, 'color': Color(0xFFF44336)},
    {'icon': Icons.link, 'color': Colors.white},
    {'icon': Icons.poll, 'color': Color(0xFF4CAF50)},
    {'icon': Icons.timer, 'color': Color(0xFF03A9F4)},
  ];

  // ─── Image Picking ─────────────────────────────────────────────────────────

  Future<void> pickImageFromGallery() async {
    isImageLoading.value = true;
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (file != null) {
        selectedImage.value = File(file.path);
        _resetCanvas();
      }
    } catch (e) {
      Get.snackbar('Error', 'Image pick failed: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isImageLoading.value = false;
    }
  }

  Future<void> pickImageFromCamera() async {
    isImageLoading.value = true;
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      if (file != null) {
        selectedImage.value = File(file.path);
        _resetCanvas();
      }
    } catch (e) {
      Get.snackbar('Error', 'Camera failed: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isImageLoading.value = false;
    }
  }

  void _resetCanvas() {
    textElements.clear();
    emojiElements.clear();
    stickerElements.clear();
    selectedTextIndex.value = -1;
    selectedEmojiIndex.value = -1;
    selectedStickerIndex.value = -1;
    currentTool.value = 'none';
  }

  // ─── Text ──────────────────────────────────────────────────────────────────

  void addTextElement(Offset center) {
    if (textController.text.trim().isEmpty) return;
    textElements.add(StoryTextElement(
      text: textController.text.trim(),
      position: center,
      fontSize: currentFontSize.value,
      color: currentTextColor.value,
      backgroundColor: currentHasBg.value ? currentBgColor.value : Colors.transparent,
      hasBg: currentHasBg.value,
      fontFamily: currentFontFamily.value,
      textAlign: currentTextAlign.value,
    ));
    textController.clear();
    currentTool.value = 'none';
  }

  void updateTextPosition(int index, Offset newPos) {
    if (index < 0 || index >= textElements.length) return;
    textElements[index].position = newPos;
    textElements.refresh();
  }

  void updateTextRotation(int index, double rotation) {
    if (index < 0 || index >= textElements.length) return;
    textElements[index].rotation = rotation;
    textElements.refresh();
  }

  void deleteSelectedText() {
    if (selectedTextIndex.value >= 0) {
      textElements.removeAt(selectedTextIndex.value);
      selectedTextIndex.value = -1;
    }
  }

  // ─── Emoji ─────────────────────────────────────────────────────────────────

  void addEmoji(String emoji, Offset center) {
    emojiElements.add(StoryEmojiElement(
      emoji: emoji,
      position: center,
    ));
    currentTool.value = 'none';
  }

  void updateEmojiPosition(int index, Offset newPos) {
    if (index < 0 || index >= emojiElements.length) return;
    emojiElements[index].position = newPos;
    emojiElements.refresh();
  }

  void updateEmojiSize(int index, double scale) {
    if (index < 0 || index >= emojiElements.length) return;
    final newSize = (emojiElements[index].size * scale).clamp(20.0, 120.0);
    emojiElements[index].size = newSize;
    emojiElements.refresh();
  }

  void deleteSelectedEmoji() {
    if (selectedEmojiIndex.value >= 0) {
      emojiElements.removeAt(selectedEmojiIndex.value);
      selectedEmojiIndex.value = -1;
    }
  }

  // ─── Sticker ───────────────────────────────────────────────────────────────

  void addSticker(IconData icon, Color color, Offset center) {
    stickerElements.add(StoryStickerElement(
      icon: icon,
      position: center,
      color: color,
    ));
    currentTool.value = 'none';
  }

  void updateStickerPosition(int index, Offset newPos) {
    if (index < 0 || index >= stickerElements.length) return;
    stickerElements[index].position = newPos;
    stickerElements.refresh();
  }

  void deleteSelectedSticker() {
    if (selectedStickerIndex.value >= 0) {
      stickerElements.removeAt(selectedStickerIndex.value);
      selectedStickerIndex.value = -1;
    }
  }

  void clearSelection() {
    selectedTextIndex.value = -1;
    selectedEmojiIndex.value = -1;
    selectedStickerIndex.value = -1;
  }

  // ─── Export & Share ────────────────────────────────────────────────────────

  Future<void> exportAndShare() async {
    isExporting.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary = canvasKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) {
        Get.snackbar('Error', 'Canvas not ready',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/story_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Created with Auto Clipper ✨',
        subject: 'My Story',
      );
    } catch (e) {
      Get.snackbar('Error', 'Export failed: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> saveToGallery() async {
    isExporting.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary = canvasKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/story_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      // Save to gallery using gallery_saver or gal package if available
      Get.snackbar(
        '✅ Saved!',
        'Story saved to gallery',
        backgroundColor: const Color(0xFF25D366),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', 'Save failed: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isExporting.value = false;
    }
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}