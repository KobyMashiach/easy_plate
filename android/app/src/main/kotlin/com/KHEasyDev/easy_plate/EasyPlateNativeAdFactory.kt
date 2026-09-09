package com.KHEasyDev.easy_plate

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

/**
 * Lays a native ad out as an EasyPlate feed card (res/layout/easy_plate_native_ad.xml).
 *
 * Registered under `AdsConfig.nativeFactoryId` in MainActivity. The Dart side
 * passes two custom options: `badge`, the localised "Ad" label, and `rtl`,
 * whether the app is currently in a right-to-left language — the platform view
 * follows the *app's* language, not the device's.
 */
class EasyPlateNativeAdFactory(private val inflater: LayoutInflater) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView = inflater.inflate(R.layout.easy_plate_native_ad, null) as NativeAdView

        val rtl = customOptions?.get("rtl") == true
        adView.layoutDirection = if (rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR
        adView.textDirection = if (rtl) View.TEXT_DIRECTION_RTL else View.TEXT_DIRECTION_LTR

        val media = adView.findViewById<MediaView>(R.id.ad_media)
        val headline = adView.findViewById<TextView>(R.id.ad_headline)
        val body = adView.findViewById<TextView>(R.id.ad_body)
        val cta = adView.findViewById<Button>(R.id.ad_call_to_action)
        val badge = adView.findViewById<TextView>(R.id.ad_badge)

        adView.mediaView = media
        adView.headlineView = headline
        adView.bodyView = body
        adView.callToActionView = cta

        // Headline and media are guaranteed by the SDK; the rest is optional.
        headline.text = nativeAd.headline
        media.mediaContent = nativeAd.mediaContent

        val bodyText = nativeAd.body
        if (bodyText.isNullOrBlank()) {
            body.visibility = View.INVISIBLE
        } else {
            body.visibility = View.VISIBLE
            body.text = bodyText
        }

        val ctaText = nativeAd.callToAction
        if (ctaText.isNullOrBlank()) {
            cta.visibility = View.INVISIBLE
        } else {
            cta.visibility = View.VISIBLE
            cta.text = ctaText
        }

        badge.text = (customOptions?.get("badge") as? String)?.takeIf { it.isNotBlank() } ?: "Ad"

        adView.setNativeAd(nativeAd)
        return adView
    }
}
