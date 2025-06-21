import 'package:flutter/material.dart';
import 'package:auto_clipper_app/Logic/Interstitial_controller.dart';

class AdButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final Widget? child;

  const AdButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: () {
        // Handle the ad click logic
        InterstitialAdsController().handleButtonClick(context);
        // Execute the original onPressed callback
        onPressed();
      },
      child: child ?? Text(text),
    );
  }
}
