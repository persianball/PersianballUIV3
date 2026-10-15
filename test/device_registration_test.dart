import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/services/device_registration_service.dart';

DeviceProfile _p({
  String display = 'display',
  String deviceId = 'id',
  int sdk = 34,
  String type = 'mobile',
}) =>
    DeviceProfile(
      sdkVersion: sdk,
      sdkRelease: '14',
      display: display,
      manufacturer: 'Samsung',
      model: 'SM-G991B',
      versionName: '1.0.0',
      versionCode: '1',
      deviceId: deviceId,
      deviceType: type,
    );

void main() {
  group('محدودیت‌های طولِ سرور رعایت می‌شود', () {
    test('display به ۱۵ کاراکتر بریده می‌شود', () {
      final j = _p(display: 'a' * 40).toJson();
      expect((j['display'] as String).length, 15);
    });

    test('device_id به ۲۰ کاراکتر بریده می‌شود (UUID آی‌اواس ۳۶ است)', () {
      final j = _p(deviceId: '123e4567-e89b-12d3-a456-426614174000').toJson();
      expect((j['device_id'] as String).length, 20);
    });

    test('fcm_token به ۲۰۰ کاراکتر بریده می‌شود', () {
      final j = _p().toJson(fcmToken: 't' * 350);
      expect((j['fcm_token'] as String).length, 200);
    });

    test('sdk_version در بازه‌ی ۰ تا ۳۲۷۶۷ می‌ماند', () {
      expect(_p(sdk: 99999).toJson()['sdk_version'], 32767);
      expect(_p(sdk: -5).toJson()['sdk_version'], 0);
    });

    test('مقادیر کوتاه دست‌نخورده می‌مانند', () {
      final j = _p(display: 'Pixel').toJson();
      expect(j['display'], 'Pixel');
      expect(j['model'], 'SM-G991B');
    });
  });

  group('شکلِ بدنه‌ی درخواست', () {
    test('بدون توکن، کلید fcm_token اصلاً فرستاده نمی‌شود', () {
      expect(_p().toJson().containsKey('fcm_token'), isFalse);
      expect(_p().toJson(fcmToken: '').containsKey('fcm_token'), isFalse);
    });

    test('همه‌ی فیلدهای اجباری سرور حاضرند', () {
      final j = _p().toJson(fcmToken: 'abc');
      for (final k in ['sdk_version', 'sdk_release', 'display', 'device_type']) {
        expect(j.containsKey(k), isTrue, reason: '$k اجباری است');
      }
      expect(j['fcm_token'], 'abc');
    });

    test('device_type فقط web یا mobile است', () {
      expect(_p(type: 'mobile').toJson()['device_type'], 'mobile');
      expect(_p(type: 'web').toJson()['device_type'], 'web');
    });
  });
}
