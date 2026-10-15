import 'package:easy_plate/features/auth/presentation/widgets/session_takeover_sheet.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the SMS sheet shows enough of the number to recognise it', () {
    expect(maskPhone('+972501564465'), '+97250•••4465');
    expect(maskPhone('+12345'), '+12345');
  });

  test('only "admin" grants admin; anything else is a user', () {
    expect(UserPermission.fromName('admin'), UserPermission.admin);
    expect(UserPermission.fromName('user'), UserPermission.user);
    expect(UserPermission.fromName('Admin'), UserPermission.user);
    expect(UserPermission.fromName(null), UserPermission.user);
  });
}
