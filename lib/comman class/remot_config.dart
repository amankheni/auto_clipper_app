// ignore_for_file: avoid_print

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      // Set default values
      await _remoteConfig.setDefaults({
        // Global
        'ads_enabled': true,
        'ads_test_mode': false,
        'ads_load_timeout': 10,

        // Banner
        'banner_ads_enabled': true,
        'banner_ad_unit_id_production':
            'ca-app-pub-7772180367051787/8438591704',
        'banner_ad_unit_id_test': 'ca-app-pub-3940256099942544/6300978111',
        'banner_ad_refresh_rate': 60,

        // Native
        'native_ads_enabled': true,
        'native_ad_unit_id_production':
            'ca-app-pub-7772180367051787/6519005372',
        'native_ad_unit_id_test': 'ca-app-pub-3940256099942544/2247696110',
        'native_ad_template_type': 'medium',
        'native_ad_corner_radius': 10,
      });

      // Set config settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval:
              kDebugMode
                  ? const Duration(minutes: 5)
                  : const Duration(hours: 12),
        ),
      );

      // Fetch and activate
      await _fetchAndActivate();

      if (kDebugMode) {
        _logAllParameters();
      }
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfig initialization error: $e');
      }
    }
  }

  Future<bool> _fetchAndActivate() async {
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      if (kDebugMode) {
        print('RemoteConfig updated: $updated');
      }
      return updated;
    } catch (e) {
      if (kDebugMode) {
        print('RemoteConfig fetch error: $e');
      }
      return false;
    }
  }

  void _logAllParameters() {
    final parameters = _remoteConfig.getAll();
    print('╔═══════════════════════════════════════════');
    print('║ RemoteConfig Parameters');
    print('╠═══════════════════════════════════════════');
    parameters.forEach((key, value) {
      print('║ $key: ${value.asString()}');
    });
    print('╚═══════════════════════════════════════════');
  }

  // Getters for ads parameters
  bool get adsEnabled => _remoteConfig.getBool('ads_enabled');
  bool get adsTestMode => _remoteConfig.getBool('ads_test_mode');
  int get adsLoadTimeout => _remoteConfig.getInt('ads_load_timeout');

  // Banner ads getters
  bool get bannerAdsEnabled => _remoteConfig.getBool('banner_ads_enabled');
  String get bannerAdUnitId =>
      (kDebugMode || adsTestMode)
          ? _remoteConfig.getString('banner_ad_unit_id_test')
          : _remoteConfig.getString('banner_ad_unit_id_production');
  int get bannerAdRefreshRate => _remoteConfig.getInt('banner_ad_refresh_rate');

  // Native ads getters
  bool get nativeAdsEnabled => _remoteConfig.getBool('native_ads_enabled');
  String get nativeAdUnitId =>
      (kDebugMode || adsTestMode)
          ? _remoteConfig.getString('native_ad_unit_id_test')
          : _remoteConfig.getString('native_ad_unit_id_production');
  TemplateType get nativeAdTemplateType {
    final type = _remoteConfig.getString('native_ad_template_type');
    return type == 'small' ? TemplateType.small : TemplateType.medium;
  }

  double get nativeAdCornerRadius =>
      _remoteConfig.getInt('native_ad_corner_radius').toDouble();


      bool get interstitialAdsEnabled =>
      _remoteConfig.getBool('interstitial_ads_enabled');
  String get interstitialAdUnitId =>
      (kDebugMode || adsTestMode)
          ? _remoteConfig.getString('interstitial_ad_unit_id_test')
          : _remoteConfig.getString('interstitial_ad_unit_id_production');
  int get interstitialClickThreshold =>
      _remoteConfig.getInt('interstitial_click_threshold');
}
