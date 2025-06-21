import 'package:auto_clipper_app/Logic/Nativ_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';




class NativeAdWidget extends StatefulWidget {
  final double? height;
  final double? width;
  final EdgeInsets? margin;
  final BoxDecoration? decoration;

  const NativeAdWidget({
    super.key,
    this.height = 300,
    this.width,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.decoration = const BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _ad;
  bool _isLoading = true;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    try {
      final controller = NativeAdsController();
      await controller.loadNativeAd(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _ad = ad;
              _isLoading = false;
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isAdLoaded = false;
            });
          }
          if (kDebugMode) {
            print('Failed to load native ad: $error');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAdLoaded = false;
        });
      }
      if (kDebugMode) {
        print('Error loading native ad: $e');
      }
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        width: widget.width,
        margin: widget.margin,
        decoration: widget.decoration,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdLoaded) {
      return Container(); // Return empty container if ad failed to load
    }

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: widget.decoration,
      child: _ad != null ? AdWidget(ad: _ad!) : Container(),
    );
  }
}
