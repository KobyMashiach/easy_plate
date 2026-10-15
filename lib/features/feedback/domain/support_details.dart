import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/services/auth_session_service.dart';
import '../../../core/utils/i18n/strings.g.dart';

/// Who is writing and from where: the same lines the mail and WhatsApp
/// signatures print under the user's message, as a map for the support
/// conversation. Stored on the message for the administrator; the chat
/// itself never shows them to the writer.
abstract class SupportDetails {
  static Future<Map<String, String>> collect() async {
    final session = AuthSessionService();
    String? version;
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version} (${info.buildNumber})';
    } catch (_) {}
    final device = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.android => 'Android',
      final other => other.name,
    };
    final entries = <String, String?>{
      'name': session.profile?.fullName,
      'email': session.profile?.email ?? session.user?.email,
      'phone': session.user?.phoneNumber,
      'uid': session.user?.uid,
      'version': version,
      'device': device,
      'language': LocaleSettings.currentLocale.languageCode,
    };
    return {
      for (final e in entries.entries)
        if (e.value != null && e.value!.trim().isNotEmpty)
          e.key: e.value!.trim(),
    };
  }
}
