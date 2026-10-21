import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_config.dart';
import '../network/ai_auth_header.dart';
import '../network/http_calls.dart';

/// The hand-off to the website for Premium bought there (PayPlus in
/// Israel, Paddle through RevenueCat abroad).
///
/// The `upgradeLinks` function mints a one-time link that opens
/// aieasyplate.app/app already signed in as this account, on the pricing
/// page (or the account page, where a web subscription is managed). The
/// token is single-use and lasts half an hour, so the URL is minted at the
/// moment of the tap, never stored.
class WebBillingLinks {
  final HttpCalls _http;

  WebBillingLinks({HttpCalls? http})
    : _http = http ?? HttpCalls(headerProvider: aiProxyAuthHeader);

  /// A fresh link for the signed-in account, or null when the server
  /// refused (flag off, no network).
  Future<Uri?> mint({required String lang}) async {
    try {
      final response = await _http.post(
        ApiConfig.upgradeLinksUrl,
        data: {'action': 'mint', 'lang': lang},
      );
      final url = switch (response?.data) {
        {'url': final String url} => url,
        _ => null,
      };
      return url == null ? null : Uri.tryParse(url);
    } catch (e) {
      debugPrint('Upgrade link mint failed: $e');
      return null;
    }
  }

  /// Mints a link and opens it in the browser. False when either failed.
  Future<bool> open({required String lang}) async {
    final uri = await mint(lang: lang);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Upgrade link launch failed: $e');
      return false;
    }
  }
}
