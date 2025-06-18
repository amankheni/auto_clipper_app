// Custom Slider Thumb Shape
import 'package:auto_clipper_app/Constant/Colors.dart';
import 'package:flutter/material.dart';

// Custom Slider Thumb Shape
class CustomSliderThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  final double elevation;

  const CustomSliderThumbShape({
    required this.enabledThumbRadius,
    this.elevation = 1,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Shadow
    final shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.15)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, elevation);

    canvas.drawCircle(
      center + Offset(0, elevation),
      enabledThumbRadius,
      shadowPaint,
    );

    // Outer ring
    final outerPaint =
        Paint()
          ..color = Color(0xFFE91E63)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, enabledThumbRadius, outerPaint);

    // Inner circle
    final innerPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, enabledThumbRadius - 2.5, innerPaint);

    // Center dot
    final centerPaint =
        Paint()
          ..color = Color(0xFFE91E63)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 2.5, centerPaint);
  }
}
