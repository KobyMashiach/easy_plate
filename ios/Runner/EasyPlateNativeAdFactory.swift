import Flutter
import GoogleMobileAds
import UIKit
import google_mobile_ads

/// Lays a native ad out as an EasyPlate feed card — the iOS twin of
/// `EasyPlateNativeAdFactory.kt` and `res/layout/easy_plate_native_ad.xml`.
///
/// The white clay frame is drawn by `NativeAdCard` in Dart; this fills it
/// with the ad's assets in the app palette (see `lib/core/constants/
/// app_colors.dart`): 16pt padding, a 100x72 media thumbnail, headline and
/// body, then the "Ad" pill and the call-to-action pill on one row. Total
/// height 156pt, which is what `NativeAdCard.height` reserves.
///
/// Custom options from Dart: `badge`, the localised "Ad" label, and `rtl`,
/// whether the app is in a right-to-left language.
class EasyPlateNativeAdFactory: NSObject, FLTNativeAdFactory {
  private enum Palette {
    static let primary = UIColor(red: 0x5B / 255, green: 0x3C / 255, blue: 0xDD / 255, alpha: 1)
    static let onPrimary = UIColor.white
    static let primaryFixed = UIColor(red: 0xE5 / 255, green: 0xDE / 255, blue: 0xFF / 255, alpha: 1)
    static let onSurface = UIColor(red: 0x18 / 255, green: 0x14 / 255, blue: 0x45 / 255, alpha: 1)
    static let onSurfaceVariant = UIColor(red: 0x48 / 255, green: 0x45 / 255, blue: 0x55 / 255, alpha: 1)
    static let surfaceContainerLow = UIColor(red: 0xF6 / 255, green: 0xF2 / 255, blue: 0xFF / 255, alpha: 1)
    static let surfaceContainerLowest = UIColor.white
  }

  func createNativeAd(
    _ nativeAd: NativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> NativeAdView? {
    let adView = NativeAdView()
    adView.backgroundColor = Palette.surfaceContainerLowest

    let rtl = (customOptions?["rtl"] as? Bool) ?? false
    let badgeText = (customOptions?["badge"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "Ad"
    let attribute: UISemanticContentAttribute = rtl ? .forceRightToLeft : .forceLeftToRight
    adView.semanticContentAttribute = attribute

    // Media: required by the SDK for every native ad, and the thumbnail here.
    let media = MediaView()
    media.translatesAutoresizingMaskIntoConstraints = false
    media.backgroundColor = Palette.surfaceContainerLow
    media.layer.cornerRadius = 12
    media.clipsToBounds = true
    media.contentMode = .scaleAspectFill
    media.mediaContent = nativeAd.mediaContent

    let headline = UILabel()
    headline.translatesAutoresizingMaskIntoConstraints = false
    headline.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    headline.textColor = Palette.onSurface
    headline.numberOfLines = 1
    headline.lineBreakMode = .byTruncatingTail
    headline.text = nativeAd.headline
    headline.textAlignment = rtl ? .right : .left

    let body = UILabel()
    body.translatesAutoresizingMaskIntoConstraints = false
    body.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    body.textColor = Palette.onSurfaceVariant
    body.numberOfLines = 2
    body.lineBreakMode = .byTruncatingTail
    body.text = nativeAd.body
    body.isHidden = (nativeAd.body ?? "").isEmpty
    body.textAlignment = rtl ? .right : .left

    let textColumn = UIStackView(arrangedSubviews: [headline, body])
    textColumn.translatesAutoresizingMaskIntoConstraints = false
    textColumn.axis = .vertical
    textColumn.spacing = 2
    textColumn.alignment = .fill
    textColumn.semanticContentAttribute = attribute

    let topRow = UIStackView(arrangedSubviews: [media, textColumn])
    topRow.translatesAutoresizingMaskIntoConstraints = false
    topRow.axis = .horizontal
    topRow.spacing = 12
    topRow.alignment = .center
    topRow.semanticContentAttribute = attribute

    // The "Ad" pill.
    let badge = PaddedLabel()
    badge.translatesAutoresizingMaskIntoConstraints = false
    badge.font = UIFont.systemFont(ofSize: 11, weight: .bold)
    badge.textColor = Palette.primary
    badge.backgroundColor = Palette.primaryFixed
    badge.text = badgeText
    badge.insets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
    badge.layer.cornerRadius = 11
    badge.clipsToBounds = true
    badge.setContentHuggingPriority(.required, for: .horizontal)

    let spacer = UIView()
    spacer.translatesAutoresizingMaskIntoConstraints = false
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

    // The call to action. Touches are handled by the SDK through the ad
    // view, which is why the button itself must not take them.
    let cta = UIButton(type: .custom)
    cta.translatesAutoresizingMaskIntoConstraints = false
    cta.isUserInteractionEnabled = false
    cta.backgroundColor = Palette.primary
    cta.setTitleColor(Palette.onPrimary, for: .normal)
    cta.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    cta.titleLabel?.lineBreakMode = .byTruncatingTail
    cta.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    cta.layer.cornerRadius = 20
    cta.clipsToBounds = true
    cta.setTitle(nativeAd.callToAction, for: .normal)
    cta.isHidden = (nativeAd.callToAction ?? "").isEmpty

    let bottomRow = UIStackView(arrangedSubviews: [badge, spacer, cta])
    bottomRow.translatesAutoresizingMaskIntoConstraints = false
    bottomRow.axis = .horizontal
    bottomRow.spacing = 8
    bottomRow.alignment = .center
    bottomRow.semanticContentAttribute = attribute

    let column = UIStackView(arrangedSubviews: [topRow, bottomRow])
    column.translatesAutoresizingMaskIntoConstraints = false
    column.axis = .vertical
    column.spacing = 12
    column.alignment = .fill
    column.semanticContentAttribute = attribute
    adView.addSubview(column)

    NSLayoutConstraint.activate([
      column.topAnchor.constraint(equalTo: adView.topAnchor, constant: 16),
      column.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
      column.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
      column.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor, constant: -16),
      media.widthAnchor.constraint(equalToConstant: 100),
      media.heightAnchor.constraint(equalToConstant: 72),
      topRow.heightAnchor.constraint(equalToConstant: 72),
      cta.heightAnchor.constraint(equalToConstant: 40),
      cta.widthAnchor.constraint(greaterThanOrEqualToConstant: 96),
      bottomRow.heightAnchor.constraint(equalToConstant: 40),
    ])

    adView.mediaView = media
    adView.headlineView = headline
    adView.bodyView = body
    adView.callToActionView = cta

    // Tells the SDK the view is populated; must come last.
    adView.nativeAd = nativeAd
    return adView
  }
}

/// A label with inner padding, for the pill-shaped badge.
private final class PaddedLabel: UILabel {
  var insets = UIEdgeInsets.zero

  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: insets))
  }

  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    return CGSize(
      width: size.width + insets.left + insets.right,
      height: size.height + insets.top + insets.bottom
    )
  }
}
