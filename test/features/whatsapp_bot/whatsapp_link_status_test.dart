import 'package:easy_plate/features/whatsapp_bot/data/whatsapp_link_remote_datasource.dart';
import 'package:easy_plate/features/whatsapp_bot/domain/whatsapp_link_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatsappLinkStatus.fromJson', () {
    test('a linked free account', () {
      final s = WhatsappLinkStatus.fromJson({
        'linked': true,
        'phone': '+972501234567',
        'premium': false,
        'used': 10,
        'limit': 10,
        'listId': 'primary',
        'code': null,
        'botNumber': '+972 50-000-0000',
        'access': 'open',
      });
      expect(s.linked, isTrue);
      expect(s.phone, '+972501234567');
      expect(s.quotaReached, isTrue);
      expect(s.usageFraction, 1.0);
      expect(s.botNumber, '972500000000');
      expect(s.listId, 'primary');
    });

    test('not linked, with a code that is still valid', () {
      final expires = DateTime.now().add(const Duration(minutes: 10));
      final s = WhatsappLinkStatus.fromJson({
        'linked': false,
        'phone': null,
        'used': 0,
        'limit': 10,
        'code': '042917',
        'codeExpiresAt': expires.toUtc().toIso8601String(),
        'botNumber': '972500000000',
      });
      expect(s.linked, isFalse);
      expect(s.codeValidAt(DateTime.now()), isTrue);
      expect(
        s.codeValidAt(DateTime.now().add(const Duration(minutes: 11))),
        isFalse,
      );
      final uri = s.chatUri(text: 'קוד 042917')!;
      expect(uri.host, 'wa.me');
      expect(uri.path, '/972500000000');
      expect(uri.queryParameters['text'], 'קוד 042917');
    });

    test('missing fields fall back safely', () {
      final s = WhatsappLinkStatus.fromJson(const {});
      expect(s.linked, isFalse);
      expect(s.limit, 10);
      expect(s.used, 0);
      expect(s.chatUri(), isNull);
      expect(s.access, 'open');
    });

    test('a premium account shows its own allowance', () {
      final s = WhatsappLinkStatus.fromJson({
        'linked': true,
        'phone': '+33612345678',
        'premium': true,
        'used': 12,
        'limit': 300,
      });
      expect(s.premium, isTrue);
      expect(s.quotaReached, isFalse);
      expect(s.usageFraction, closeTo(0.04, 0.0001));
    });
  });

  test('refusalIn reads the server code and ignores unknown ones', () {
    expect(
      WhatsappLinkRemoteDataSource.refusalIn(
        '{error: {code: premium_required, message: Premium only}}',
      ),
      WhatsappLinkRefused.premiumRequired,
    );
    expect(
      WhatsappLinkRemoteDataSource.refusalIn('{"error":{"code":"unavailable"}}'),
      WhatsappLinkRefused.unavailable,
    );
    expect(
      WhatsappLinkRemoteDataSource.refusalIn('{error: {code: something_else}}'),
      isNull,
    );
  });
}
