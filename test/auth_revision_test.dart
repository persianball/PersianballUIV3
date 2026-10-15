// وضعیت ورود باید به بقیه‌ی برنامه خبر بدهد.
//
// انگیزه: کاربر وسط کار وارد می‌شد، به صفحه‌ی قبلی برمی‌گشت و بجِ تعداد سبد
// روی صفر می‌ماند — چون آن صفحه از قبل ساخته شده بود و LoadCart دوباره
// فرستاده نمی‌شد. حالا هر ورود/خروج authRevision را جلو می‌برد و ریشه‌ی
// برنامه سبد را دوباره می‌خواند.
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ذخیره‌ی توکن، نسخه‌ی وضعیت ورود را جلو می‌برد', () async {
    final before = AuthService.authRevision.value;
    await AuthService.saveTokens('t-123');
    expect(AuthService.authRevision.value, before + 1);
  });

  test('خروج هم خبر می‌دهد تا بج سبد صفر شود', () async {
    await AuthService.saveTokens('t-123');
    final afterLogin = AuthService.authRevision.value;
    await AuthService.logout();
    expect(AuthService.authRevision.value, afterLogin + 1);
  });

  test('خبر بعد از نوشتنِ توکن می‌رسد، نه قبلش', () async {
    String? seen = 'not-read';
    void listener() {
      // شنونده باید توکنِ تازه را ببیند؛ اگر خبر زودتر از نوشتن برسد،
      // اینجا هنوز null است و درخواستِ بعدی مهمان حساب می‌شود.
      SharedPreferences.getInstance()
          .then((p) => seen = p.getString('auth_token'));
    }

    AuthService.authRevision.addListener(listener);
    addTearDown(() => AuthService.authRevision.removeListener(listener));

    await AuthService.saveTokens('t-abc');
    await Future<void>.delayed(Duration.zero);

    expect(seen, 't-abc');
  });
}
