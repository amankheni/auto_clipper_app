package com.honorixinnovation.auto_clipper

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ✅ Register Small Native Ad Factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_ad_small",
            NativeAdSmallFactory(applicationContext)
        )

        // ✅ Register Large Native Ad Factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "native_ad_large",
            NativeAdLargeFactory(applicationContext)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine, "native_ad_small")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine, "native_ad_large")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
