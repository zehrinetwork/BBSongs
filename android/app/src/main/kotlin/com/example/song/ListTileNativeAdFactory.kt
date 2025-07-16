// In android/app/src/main/kotlin/com/your/package/name/ListTileNativeAdFactory.kt
package com.example.song // TODO: Change this to your actual package name

import android.content.Context
import android.view.LayoutInflater
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class ListTileNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.list_tile_native_ad, null) as NativeAdView

        // Associate the AdView with the ad object.
        adView.setNativeAd(nativeAd)

        // Find the views.
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val callToActionView = adView.findViewById<Button>(R.id.ad_call_to_action)

        // Set the ad assets.
        headlineView.text = nativeAd.headline
        bodyView.text = nativeAd.body
        callToActionView.text = nativeAd.callToAction
        nativeAd.icon?.drawable?.let {
            iconView.setImageDrawable(it)
        } ?: iconView.setImageResource(R.mipmap.ic_launcher) // Fallback icon

        // Register the views.
        adView.headlineView = headlineView
        adView.bodyView = bodyView
        adView.callToActionView = callToActionView
        adView.iconView = iconView

        return adView
    }
}