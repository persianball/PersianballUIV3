import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('بدون توکن، کاربر وارد نشده است', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await AuthService.isLoggedIn(), isFalse);
  });

  test('توکن خالی هم یعنی وارد نشده', () async {
    SharedPreferences.setMockInitialValues({'auth_token': ''});
    expect(await AuthService.isLoggedIn(), isFalse);
  });

  test('با توکن معتبر، کاربر وارد شده است', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'abc123'});
    expect(await AuthService.isLoggedIn(), isTrue);
    expect(await AuthService.getToken(), 'abc123');
  });

  test('بعد از خروج، توکن پاک می‌شود', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'abc123'});
    await AuthService.logout();
    expect(await AuthService.isLoggedIn(), isFalse);
    expect(await AuthService.getToken(), isNull);
  });
}
