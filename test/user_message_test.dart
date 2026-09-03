import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/services/user_message_service.dart';

void main() {
  group('پارسرِ تحمل‌پذیرِ پیام', () {
    test('نام‌های رایج فیلد شناسایی می‌شوند', () {
      final m = UserMessage.fromJson({
        'id': 7,
        'title': 'سلام',
        'body': 'متن پیام',
        'created_at': '2026-09-01T10:00:00Z',
        'is_read': true,
      });
      expect(m.id, 7);
      expect(m.title, 'سلام');
      expect(m.body, 'متن پیام');
      expect(m.isRead, isTrue);
    });

    test('نام‌های جای‌گزین هم کار می‌کنند', () {
      final m = UserMessage.fromJson({
        'subject': 'عنوان',
        'message': 'محتوا',
        'date': '۱۴۰۴/۰۶/۱۰',
        'is_readed': false,
      });
      expect(m.title, 'عنوان');
      expect(m.body, 'محتوا');
      expect(m.createdAt, '۱۴۰۴/۰۶/۱۰');
      expect(m.isRead, isFalse);
    });

    test('پیامِ ناشناخته کرش نمی‌کند و خالی می‌ماند', () {
      final m = UserMessage.fromJson({'something_else': 1});
      expect(m.title, '');
      expect(m.body, '');
      expect(m.isRead, isFalse);
      expect(m.displayTitle, 'پیام');
    });

    test('نبودِ عنوان از متن جبران می‌شود', () {
      final short = UserMessage.fromJson({'body': 'سفارش شما ارسال شد'});
      expect(short.displayTitle, 'سفارش شما ارسال شد');

      final long = UserMessage.fromJson({'body': 'ب' * 80});
      expect(long.displayTitle.endsWith('…'), isTrue);
      expect(long.displayTitle.length, lessThanOrEqualTo(41));
    });

    test('is_read فقط با true واقعی، خوانده حساب می‌شود', () {
      expect(UserMessage.fromJson({'is_read': 'yes'}).isRead, isFalse);
      expect(UserMessage.fromJson({'is_read': 1}).isRead, isFalse);
      expect(UserMessage.fromJson({'is_read': true}).isRead, isTrue);
    });
  });
}
