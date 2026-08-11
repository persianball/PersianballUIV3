import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/services/review_service.dart';

void main() {
  test('میانگین امتیاز درست محاسبه می‌شود', () {
    const s = ReviewSummary([
      ProductReview(id: 1, userName: 'a', rating: 5, body: '', createdAt: ''),
      ProductReview(id: 2, userName: 'b', rating: 3, body: '', createdAt: ''),
    ]);
    expect(s.average, 4.0);
    expect(s.count, 2);
  });

  test('لیست خالی میانگین صفر می‌دهد', () {
    const s = ReviewSummary([]);
    expect(s.average, 0);
  });

  test('تفکیک ستاره‌ها همه سطوح را پوشش می‌دهد', () {
    const s = ReviewSummary([
      ProductReview(id: 1, userName: 'a', rating: 5, body: '', createdAt: ''),
      ProductReview(id: 2, userName: 'b', rating: 5, body: '', createdAt: ''),
      ProductReview(id: 3, userName: 'c', rating: 2, body: '', createdAt: ''),
    ]);
    expect(s.breakdown.keys.toList(), [5, 4, 3, 2, 1]);
    expect(s.breakdown[5], 2);
    expect(s.breakdown[2], 1);
    expect(s.breakdown[1], 0);
  });

  test('ثبت نظر جدید، آن را ابتدای لیست می‌گذارد و شمارش را زیاد می‌کند', () async {
    final before = await ReviewService.fetchReviews(101);
    await ReviewService.addReview(101, rating: 4, body: 'عالی بود');
    final after = await ReviewService.fetchReviews(101);

    expect(after.count, before.count + 1);
    expect(after.reviews.first.body, 'عالی بود');
    expect(after.reviews.first.verifiedPurchase, isTrue);
  });

  test('ثبت سؤال جدید بدون پاسخ ذخیره می‌شود', () async {
    await ReviewService.addQuestion(202, body: 'گارانتی دارد؟');
    final questions = await ReviewService.fetchQuestions(202);
    expect(questions.first.body, 'گارانتی دارد؟');
    expect(questions.first.answer, isNull);
  });

  test('نظرات هر محصول از محصول دیگر جداست', () async {
    await ReviewService.addReview(301, rating: 5, body: 'مخصوص ۳۰۱');
    final other = await ReviewService.fetchReviews(302);
    expect(other.reviews.any((r) => r.body == 'مخصوص ۳۰۱'), isFalse);
  });
}
