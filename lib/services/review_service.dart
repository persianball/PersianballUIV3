// lib/services/review_service.dart
//
// نظرات و پرسش‌وپاسخ محصول.
//
// وضعیت بک‌اند: هیچ endpointی برای نظر یا پرسش‌وپاسخ وجود ندارد و
// ReviewsPage فقط لیستی را که به آن پاس داده می‌شود نمایش می‌دهد.
//
// پیشنهاد برای بک‌اند (وقتی آماده شد فقط همین فایل عوض می‌شود):
//   GET  /v2/product/product/<id>/reviews/     → {count, average, breakdown{5:..,1:..}, results:[…]}
//   POST /v2/product/product/<id>/reviews/     {rating: 1..5, title, body}
//   GET  /v2/product/product/<id>/questions/   → [{id, body, user, created_at, answers:[…]}]
//   POST /v2/product/product/<id>/questions/   {body}
//
// تا آن زمان: داده نمایشی در حافظه نگه داشته می‌شود تا جریان کامل (خواندن،
// ثبت، میانگین امتیاز) برای بک‌اند قابل مشاهده باشد.

class ProductReview {
  final int id;
  final String userName;
  final int rating; // 1..5
  final String body;
  final String createdAt;
  final bool verifiedPurchase;

  const ProductReview({
    required this.id,
    required this.userName,
    required this.rating,
    required this.body,
    required this.createdAt,
    this.verifiedPurchase = false,
  });
}

class ProductQuestion {
  final int id;
  final String userName;
  final String body;
  final String createdAt;
  final String? answer;
  final String? answeredBy;

  const ProductQuestion({
    required this.id,
    required this.userName,
    required this.body,
    required this.createdAt,
    this.answer,
    this.answeredBy,
  });
}

class ReviewSummary {
  final List<ProductReview> reviews;

  const ReviewSummary(this.reviews);

  int get count => reviews.length;

  double get average => reviews.isEmpty
      ? 0
      : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

  /// تعداد نظر به تفکیک ستاره، از ۵ تا ۱
  Map<int, int> get breakdown {
    final map = {for (int i = 5; i >= 1; i--) i: 0};
    for (final r in reviews) {
      map[r.rating] = (map[r.rating] ?? 0) + 1;
    }
    return map;
  }
}

class ReviewService {
  /// داده نمایشی در حافظه: productId → لیست
  static final Map<int, List<ProductReview>> _reviews = {};
  static final Map<int, List<ProductQuestion>> _questions = {};
  static int _nextId = 1000;

  static bool get isMock => true;

  static Future<ReviewSummary> fetchReviews(int productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _seed(productId);
    return ReviewSummary(List.unmodifiable(_reviews[productId]!));
  }

  static Future<ProductReview> addReview(
    int productId, {
    required int rating,
    required String body,
    String userName = 'شما',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _seed(productId);
    final review = ProductReview(
      id: _nextId++,
      userName: userName,
      rating: rating,
      body: body,
      createdAt: 'همین حالا',
      verifiedPurchase: true,
    );
    _reviews[productId]!.insert(0, review);
    return review;
  }

  static Future<List<ProductQuestion>> fetchQuestions(int productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _seed(productId);
    return List.unmodifiable(_questions[productId]!);
  }

  static Future<ProductQuestion> addQuestion(
    int productId, {
    required String body,
    String userName = 'شما',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _seed(productId);
    final q = ProductQuestion(
      id: _nextId++,
      userName: userName,
      body: body,
      createdAt: 'همین حالا',
    );
    _questions[productId]!.insert(0, q);
    return q;
  }

  static void _seed(int productId) {
    _reviews.putIfAbsent(
      productId,
      () => [
        const ProductReview(
          id: 1,
          userName: 'مریم ر.',
          rating: 5,
          body: 'کیفیت دوخت عالی بود و دقیقاً اندازه‌ای که انتخاب کردم رسید.',
          createdAt: '۱۴۰۴/۰۵/۰۲',
          verifiedPurchase: true,
        ),
        const ProductReview(
          id: 2,
          userName: 'کاربر پرشین‌بال',
          rating: 4,
          body: 'ارسال سریع بود، فقط رنگ کمی تیره‌تر از عکس است.',
          createdAt: '۱۴۰۴/۰۴/۲۸',
          verifiedPurchase: true,
        ),
        const ProductReview(
          id: 3,
          userName: 'امیر ک.',
          rating: 3,
          body: 'برای استفاده روزمره خوب است ولی برای مسابقه سبک‌تر لازم دارم.',
          createdAt: '۱۴۰۴/۰۴/۱۰',
        ),
      ],
    );

    _questions.putIfAbsent(
      productId,
      () => [
        const ProductQuestion(
          id: 1,
          userName: 'سینا',
          body: 'این مدل یک سایز بزرگ‌تر بگیرم یا سایز معمول خودم؟',
          createdAt: '۱۴۰۴/۰۵/۰۱',
          answer: 'سایز استاندارد است؛ همان سایز همیشگی خود را انتخاب کنید.',
          answeredBy: 'پشتیبانی فروشگاه',
        ),
        const ProductQuestion(
          id: 2,
          userName: 'نگار',
          body: 'امکان تعویض سایز بعد از خرید وجود دارد؟',
          createdAt: '۱۴۰۴/۰۴/۲۵',
        ),
      ],
    );
  }
}
