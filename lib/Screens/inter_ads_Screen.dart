// ignore_for_file: file_names

import 'package:auto_clipper_app/widget/inter_ad_comman.dart';
import 'package:flutter/material.dart';
import 'package:auto_clipper_app/Logic/Interstitial_controller.dart';

class InterstitialAdDemoScreen extends StatefulWidget {
  const InterstitialAdDemoScreen({super.key});

  @override
  State<InterstitialAdDemoScreen> createState() =>
      _InterstitialAdDemoScreenState();
}

class _InterstitialAdDemoScreenState extends State<InterstitialAdDemoScreen> {
  final InterstitialAdsController _interstitialController =
      InterstitialAdsController();

  @override
  void initState() {
    super.initState();
    // Load the interstitial ad when the screen initializes
    _interstitialController.loadInterstitialAd();
  }

  @override
  void dispose() {
    _interstitialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interstitial Ad Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Press the button below to trigger interstitial ads'),
            const SizedBox(height: 20),
            // Using our AdButton which handles the click counting
            AdButton(
              text: 'Click Me',
              onPressed: () {
                // Your normal button functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Button pressed!')),
                );
              },
            ),
            const SizedBox(height: 20),
            // Alternative way to use the controller directly
            ElevatedButton(
              onPressed: () {
                _interstitialController.handleButtonClick(context);
                // Your normal button functionality
              },
              child: const Text('Another Button'),
            ),
          ],
        ),
      ),
    );
  }
}
