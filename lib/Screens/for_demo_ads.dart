import 'package:auto_clipper_app/Logic/Nativ_controller.dart';
import 'package:auto_clipper_app/widget/Native_ads_widget.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class NativeAdDemoScreen extends StatelessWidget {
  const NativeAdDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Native Ad Demo')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'This is a demo of native ads in your app',
                style: TextStyle(fontSize: 18),
              ),
            ),

            // First native ad
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: NativeAdWidget(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 40),
            const Text('More content here...'),
            const SizedBox(height: 40),

            // Second native ad (same controller manages both)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: NativeAdWidget(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
