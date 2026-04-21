// Path: android/app/src/main/kotlin/com/honorixinnovation/auto_clipper/NativeAdFactories.kt

package com.honorixinnovation.auto_clipper

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

// ════════════════════════════════════════════════════════════════
// Small Native Ad Factory — factoryId: "native_ad_small"
// ════════════════════════════════════════════════════════════════
class NativeAdSmallFactory(private val context: Context) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val view = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_small, null) as NativeAdView

        // Bind views
        val headlineView = view.findViewById<TextView>(R.id.ad_headline)
        val bodyView     = view.findViewById<TextView>(R.id.ad_body)
        val iconView     = view.findViewById<ImageView>(R.id.ad_app_icon)
        val ctaView      = view.findViewById<TextView>(R.id.ad_call_to_action)

        // Set data
        headlineView.text = nativeAd.headline
        view.headlineView = headlineView

        nativeAd.body?.let {
            bodyView.text = it
            bodyView.visibility = View.VISIBLE
        } ?: run { bodyView.visibility = View.GONE }
        view.bodyView = bodyView

        nativeAd.icon?.let {
            iconView.setImageDrawable(it.drawable)
            iconView.visibility = View.VISIBLE
        } ?: run { iconView.visibility = View.GONE }
        view.iconView = iconView

        nativeAd.callToAction?.let {
            ctaView.text = it
            ctaView.visibility = View.VISIBLE
        } ?: run { ctaView.visibility = View.GONE }
        view.callToActionView = ctaView

        view.setNativeAd(nativeAd)
        return view
    }
}

// ════════════════════════════════════════════════════════════════
// Large Native Ad Factory — factoryId: "native_ad_large"
// ════════════════════════════════════════════════════════════════
class NativeAdLargeFactory(private val context: Context) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val view = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_large, null) as NativeAdView

        val headlineView   = view.findViewById<TextView>(R.id.ad_headline)
        val bodyView       = view.findViewById<TextView>(R.id.ad_body)
        val iconView       = view.findViewById<ImageView>(R.id.ad_app_icon)
        val ctaView        = view.findViewById<TextView>(R.id.ad_call_to_action)
        val mediaView      = view.findViewById<MediaView>(R.id.ad_media)
        val advertiserView = view.findViewById<TextView>(R.id.ad_advertiser)
        val starsView      = view.findViewById<RatingBar>(R.id.ad_stars)

        headlineView.text = nativeAd.headline
        view.headlineView = headlineView

        nativeAd.body?.let {
            bodyView.text = it
            bodyView.visibility = View.VISIBLE
        } ?: run { bodyView.visibility = View.GONE }
        view.bodyView = bodyView

        nativeAd.icon?.let {
            iconView.setImageDrawable(it.drawable)
            iconView.visibility = View.VISIBLE
        } ?: run { iconView.visibility = View.GONE }
        view.iconView = iconView

        nativeAd.callToAction?.let {
            ctaView.text = it
            ctaView.visibility = View.VISIBLE
        } ?: run { ctaView.visibility = View.GONE }
        view.callToActionView = ctaView

        // Media
        view.mediaView = mediaView
        mediaView.mediaContent = nativeAd.mediaContent

        // Advertiser
        nativeAd.advertiser?.let {
            advertiserView.text = it
            advertiserView.visibility = View.VISIBLE
        } ?: run { advertiserView.visibility = View.GONE }
        view.advertiserView = advertiserView

        // Stars
        nativeAd.starRating?.let {
            starsView.rating = it.toFloat()
            starsView.visibility = View.VISIBLE
        } ?: run { starsView.visibility = View.GONE }
        view.starRatingView = starsView

        view.setNativeAd(nativeAd)
        return view
    }
}