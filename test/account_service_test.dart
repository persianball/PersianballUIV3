import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/services/account_service.dart';

void main() {
  group('بازیابی رمز', () {
    test('مقصد خالی رد می‌شود', () async {
      final r = await AccountService.requestPasswordReset('  ');
      expect(r.success, isFalse);
    });

    test('مقصد معتبر کد ارسال می‌کند و ماک بودن را اعلام می‌کند', () async {
      final r = await AccountService.requestPasswordReset('user@test.com');
      expect(r.success, isTrue);
      expect(r.isMock, isTrue);
    });

    test('کد کوتاه پذیرفته نمی‌شود', () async {
      final r = await AccountService.confirmPasswordReset(
          destination: 'user@test.com', code: '12', newPassword: 'secret123');
      expect(r.success, isFalse);
    });

    test('رمز کوتاه پذیرفته نمی‌شود', () async {
      final r = await AccountService.confirmPasswordReset(
          destination: 'user@test.com', code: '1234', newPassword: '123');
      expect(r.success, isFalse);
    });

    test('کد و رمز معتبر موفق است', () async {
      final r = await AccountService.confirmPasswordReset(
          destination: 'user@test.com', code: '1234', newPassword: 'secret123');
      expect(r.success, isTrue);
    });
  });

  group('تغییر رمز', () {
    test('رمز فعلی خالی رد می‌شود', () async {
      final r = await AccountService.changePassword(
          oldPassword: '', newPassword: 'secret123');
      expect(r.success, isFalse);
    });

    test('رمز جدید نباید با رمز فعلی یکی باشد', () async {
      final r = await AccountService.changePassword(
          oldPassword: 'secret123', newPassword: 'secret123');
      expect(r.success, isFalse);
    });

    test('تغییر معتبر موفق است', () async {
      final r = await AccountService.changePassword(
          oldPassword: 'oldpass1', newPassword: 'newpass1');
      expect(r.success, isTrue);
    });
  });
}
