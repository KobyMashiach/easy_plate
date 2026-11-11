import '../../../core/constants/api_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/ai_auth_header.dart';
import '../../../core/network/http_calls.dart';
import '../domain/whatsapp_link_status.dart';

/// Why the server said no, by its own word for it.
class WhatsappLinkRefused implements Exception {
  final String code;
  const WhatsappLinkRefused(this.code);

  static const unavailable = 'unavailable';
  static const premiumRequired = 'premium_required';
  static const listNotWritable = 'list_not_writable';
  static const known = {unavailable, premiumRequired, listNotWritable};

  @override
  String toString() => 'WhatsappLinkRefused($code)';
}

/// The `whatsappLink` function: every field it touches on users/{uid} is
/// the server's to write (the rules refuse the app), so a number can only
/// be linked by the bot seeing the code arrive from it.
class WhatsappLinkRemoteDataSource {
  final HttpCalls _http;

  WhatsappLinkRemoteDataSource({HttpCalls? http})
    : _http = http ?? HttpCalls(headerProvider: aiProxyAuthHeader);

  Future<WhatsappLinkStatus> status() => _call({'action': 'status'});

  /// A fresh six-digit code, valid for 15 minutes.
  Future<WhatsappLinkStatus> createCode() => _call({'action': 'code'});

  /// [listId] null = automatic (the main list, or a new one).
  Future<WhatsappLinkStatus> setList(String? listId) =>
      _call({'action': 'setList', 'listId': listId});

  Future<WhatsappLinkStatus> unlink() => _call({'action': 'unlink'});

  Future<WhatsappLinkStatus> _call(Map<String, dynamic> body) async {
    try {
      final response = await _http.post(ApiConfig.whatsappLinkUrl, data: body);
      final data = response?.data;
      if (data is! Map) {
        throw const AppException(
          AppErrorType.parsingFailed,
          message: 'No WhatsApp status',
        );
      }
      return WhatsappLinkStatus.fromJson(Map<String, dynamic>.from(data));
    } on AppException catch (e) {
      final code = refusalIn(e.message);
      if (code != null) throw WhatsappLinkRefused(code);
      rethrow;
    }
  }

  /// The server's code inside the stringified error body.
  static String? refusalIn(String message) {
    final code = RegExp(r'code[":\s]+([a-z_]+)').firstMatch(message)?.group(1);
    return code != null && WhatsappLinkRefused.known.contains(code)
        ? code
        : null;
  }
}
