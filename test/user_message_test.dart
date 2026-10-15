// صندوق پیام‌های کاربر (/v1/user/messages/).
//
// نسخه‌ی قبلیِ این تست روی شکلِ *حدسی* پیام نوشته شده بود (title/body/
// is_read) چون موقع نوشتنش صندوقِ حساب تست خالی بود و DRF شمای GET را
// در OPTIONS نمی‌دهد. حالا شکل واقعی معلوم است: متن در «text» است، عنوان
// جدا ندارد، و خوانده‌شدن با «seen_at» مشخص می‌شود نه یک بولینِ is_read.
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/services/user_message_service.dart';

void main() {
  group('مدل پیام', () {
    test('فیلدهای واقعی سرور خوانده می‌شوند', () {
      final m = UserMessage.fromJson({
        'id': 7,
        'text': 'سفارش شما ارسال شد',
        'created_at': '2026-09-01T10:00:00+03:30',
        'seen_at': null,
        'user': 5061,
      });
      expect(m.id, 7);
      expect(m.text, 'سفارش شما ارسال شد');
      expect(m.user, 5061);
      expect(m.createdAt, isNotNull);
      // آفستِ سرور حفظ می‌شود، نه تبدیل به UTC
      expect(m.createdAt!.hour, 10);
    });

    test('خوانده‌شدن از seen_at می‌آید، نه یک بولین', () {
      expect(UserMessage.fromJson({'text': 'x', 'seen_at': null}).isRead,
          isFalse);
      expect(
          UserMessage.fromJson({
            'text': 'x',
            'seen_at': '2026-09-02T08:00:00+03:30',
          }).isRead,
          isTrue);
    });

    test('پیامِ ناقص کرش نمی‌کند', () {
      final m = UserMessage.fromJson({'something_else': 1});
      expect(m.text, '');
      expect(m.isRead, isFalse);
      expect(m.displayTitle, 'پیام');
      expect(m.id, isNull);
    });

    test('تیتر از خطِ اولِ متن ساخته می‌شود', () {
      final oneLine = UserMessage.fromJson({'text': 'سفارش شما ارسال شد'});
      expect(oneLine.displayTitle, 'سفارش شما ارسال شد');
      // متنِ تک‌خطی تماماً در تیتر آمده، پس تکرارش زیر آن بی‌معنی است
      expect(oneLine.hasMoreThanTitle, isFalse);

      final multi = UserMessage.fromJson({'text': 'عنوان\nادامه‌ی پیام'});
      expect(multi.displayTitle, 'عنوان');
      expect(multi.hasMoreThanTitle, isTrue);
    });

    test('تیترِ بلند بریده می‌شود', () {
      final long = UserMessage.fromJson({'text': 'ب' * 80});
      expect(long.displayTitle.endsWith('…'), isTrue);
      expect(long.displayTitle.length, lessThanOrEqualTo(49));
      expect(long.hasMoreThanTitle, isTrue);
    });

    test('copyWithSeen پیام را خوانده می‌کند بدون دست زدن به بقیه', () {
      final m = UserMessage.fromJson({'id': 3, 'text': 'سلام'});
      final seen = m.copyWithSeen(DateTime(2026, 9, 2));
      expect(m.isRead, isFalse, reason: 'نسخه‌ی اصلی نباید عوض شود');
      expect(seen.isRead, isTrue);
      expect(seen.id, 3);
      expect(seen.text, 'سلام');
    });
  });

  group('صفحه‌بندی', () {
    test('صفحه‌ی خالی امن است', () {
      expect(UserMessagesPage.empty.results, isEmpty);
      expect(UserMessagesPage.empty.count, 0);
      expect(UserMessagesPage.empty.next, isNull);
    });
  });
}
