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
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Reduce delay to 500ms
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _loadAd();
      }
    });
  }

  Future<void> _loadAd() async {
    if (!mounted) return;

    if (kDebugMode) {
      print('🔄 Starting native ad load...');
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    // Check if controller is initialized
    if (!_controller.isInitialized) {
      if (kDebugMode) {
        print('⚠️ Controller not initialized, initializing...');
      }
      await _controller.initializeAds();
    }

    // Set timeout to 10 seconds
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Ad loading timeout';
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
              _errorMessage = '';
            });
          }
        },
        onAdFailedToLoad: (error) {
          _timeoutTimer?.cancel();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.message;
            });
          }
          if (kDebugMode) {
            print('Native ad failed: ${error.message}');
          }
        },
      );
    } catch (e) {
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              CircularProgressIndicator(strokeWidth: 2),
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

    if (_hasError ||
        !_controller.isNativeAdReady ||
        _controller.nativeAd == null) {
      if (kDebugMode) {
        return Container(
          height: widget.height,
          width: widget.width,
          margin: widget.margin,
          decoration: widget.decoration?.copyWith(
            color: Colors.red[50],
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 24),
                SizedBox(height: 8),
                Text(
                  'Ad Failed',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadAd,
                  child: Text('Retry', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: widget.decoration,
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: _controller.nativeAd!),
    );
  }
}
