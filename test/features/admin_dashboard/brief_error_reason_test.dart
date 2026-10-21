import 'package:easy_plate/features/admin_dashboard/presentation/widgets/dashboard_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps only the first non-blank line', () {
    final error = Exception(
      'permission-denied: not an admin\n#0 main (file.dart:1)\n#1 run',
    );
    expect(
      briefErrorReason(error),
      'Exception: permission-denied: not an admin',
    );
    expect(briefErrorReason('\n\n  timeout  \nmore'), 'timeout');
  });

  test('caps the reason at 200 characters', () {
    final reason = briefErrorReason('x' * 500);
    expect(reason.length, 200);
    expect(reason.endsWith('…'), isTrue);
    expect(briefErrorReason('x' * 200), 'x' * 200);
  });
}
