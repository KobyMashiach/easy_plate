/// What the `whatsappLink` function says about this account's WhatsApp
/// grocery bot: whether a number is linked, this month's usage, the open
/// link code, and the bot's own number for click-to-chat.
class WhatsappLinkStatus {
  /// The linked number in E.164 ("+972501234567"), or null.
  final String? phone;
  final bool premium;

  /// Messages counted this month (Israel time) and the plan's allowance.
  final int used;
  final int limit;

  /// The list the bot writes to, or null for "automatic".
  final String? listId;

  /// The six-digit code to send to the bot, while it is still valid.
  final String? code;
  final DateTime? codeExpiresAt;

  /// The bot's number, digits only, for wa.me; null until it is set up.
  final String? botNumber;

  /// "open" | "premium_only" | "closed" — the server's own verdict.
  final String access;

  const WhatsappLinkStatus({
    this.phone,
    this.premium = false,
    this.used = 0,
    this.limit = 10,
    this.listId,
    this.code,
    this.codeExpiresAt,
    this.botNumber,
    this.access = 'open',
  });

  bool get linked => phone != null && phone!.isNotEmpty;
  bool get quotaReached => used >= limit;

  /// 0..1 for the usage bar.
  double get usageFraction =>
      limit <= 0 ? 1 : (used / limit).clamp(0, 1).toDouble();

  bool codeValidAt(DateTime now) =>
      code != null && (codeExpiresAt == null || codeExpiresAt!.isAfter(now));

  /// https://wa.me/{bot}?text=… — the chat with the bot, the message ready.
  Uri? chatUri({String? text}) {
    final bot = botNumber;
    if (bot == null || bot.isEmpty) return null;
    return Uri.https('wa.me', '/$bot', {
      if (text != null && text.isNotEmpty) 'text': text,
    });
  }

  factory WhatsappLinkStatus.fromJson(Map<String, dynamic> json) {
    String? str(String key) => switch (json[key]) {
      final String v when v.trim().isNotEmpty => v.trim(),
      _ => null,
    };
    int number(String key, int fallback) => switch (json[key]) {
      final num v => v.toInt(),
      _ => fallback,
    };
    final expires = str('codeExpiresAt');
    final bot = str('botNumber')?.replaceAll(RegExp(r'[^\d]'), '');
    return WhatsappLinkStatus(
      phone: json['linked'] == false ? null : str('phone'),
      premium: json['premium'] == true,
      used: number('used', 0),
      limit: number('limit', 10),
      listId: str('listId'),
      code: str('code'),
      codeExpiresAt: expires == null ? null : DateTime.tryParse(expires),
      botNumber: bot == null || bot.isEmpty ? null : bot,
      access: str('access') ?? 'open',
    );
  }
}
