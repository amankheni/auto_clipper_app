import 'package:auto_clipper_app/Logic/Nativ_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

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
  final NativeAdsController _controller = NativeAdsController();
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _timeoutTimer;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait for the controller to be properly initialized
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        _loadAd();
      }
    });
  }

  Future<void> _loadAd() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    });

    try {
      await _controller.loadNativeAd(
        onAdLoaded: (ad) {
          _timeoutTimer?.cancel();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = false;
              _retryCount = 0;
            });
          }
        },
        onAdFailedToLoad: (error) {
          _timeoutTimer?.cancel();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          }
        },
      );
    } catch (e) {
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Show loading indicator while ad is loading
    if (_isLoading) {
      return Container(
        height: widget.height,
        width: widget.width,
        margin: widget.margin,
        decoration:
            widget.decoration?.copyWith(color: Colors.grey[100]) ??
            BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text(
                'Loading Ad...',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Hide widget if ad failed to load or not ready
    if (_hasError ||
        !_controller.isNativeAdReady ||
        _controller.nativeAd == null) {
      if (kDebugMode) {
        // Show error state in debug mode
        return Container(
          height: widget.height,
          width: widget.width,
          margin: widget.margin,
          decoration:
              widget.decoration?.copyWith(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
              ) ??
              BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
          child:  Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 32),
                SizedBox(height: 8),
                Text(
                  'Ad Failed to Load',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                TextButton(
                  onPressed: _loadAd,
                  child: Text('Retry', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ),
        );
      }
      // Return empty widget in production
      return const SizedBox.shrink();
    }

    // Show the native ad
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: widget.decoration,
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: _controller.nativeAd!),
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    // Don't dispose the ad here since it's managed by the singleton controller
    super.dispose();
  }
}
