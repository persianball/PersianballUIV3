// lib/constant/shoe_size_chart.dart
//
// جدولِ راهنمای سایزِ کفش. سایزهای فروشگاه اروپایی (EU) هستند؛ UK/US و
// طولِ پا (پاشنه تا نوکِ بلندترین انگشت) برای کسی است که سایزِ خودش را
// به سیستمِ دیگری می‌شناسد یا فقط طولِ پایش را می‌داند.

class ShoeSizeRow {
  const ShoeSizeRow(this.eu, this.uk, this.us, this.footCm);

  final int eu;
  final double uk;
  final double us;

  /// طولِ پا به سانتی‌متر
  final double footCm;
}

class ShoeSizeChart {
  ShoeSizeChart._();

  static const List<ShoeSizeRow> rows = [
    ShoeSizeRow(36, 3.5, 4, 24),
    ShoeSizeRow(37, 4.5, 5, 24.5),
    ShoeSizeRow(38, 5, 6, 25),
    ShoeSizeRow(39, 6, 7, 25.5),
    ShoeSizeRow(40, 6.5, 7.5, 26),
    ShoeSizeRow(41, 7.5, 8.5, 26.5),
    ShoeSizeRow(42, 8, 9, 27),
    ShoeSizeRow(43, 9, 10, 27.5),
    ShoeSizeRow(44, 9.5, 10.5, 28),
    ShoeSizeRow(45, 10.5, 11.5, 28.5),
    ShoeSizeRow(46, 11, 12, 29.5),
  ];

  static double get minFoot => rows.first.footCm;
  static double get maxFoot => rows.last.footCm;

  /// کوچک‌ترین سایزی که پا در آن جا می‌شود (طولِ جدول ≥ طولِ پا). پای
  /// بینِ دو سایز به سایزِ بزرگ‌تر می‌رود. بزرگ‌تر از جدول → null.
  static ShoeSizeRow? forFoot(double cm) {
    for (final r in rows) {
      if (r.footCm >= cm - 0.001) return r;
    }
    return null;
  }

  static ShoeSizeRow? byEu(String size) {
    final n = int.tryParse(size.trim());
    if (n == null) return null;
    for (final r in rows) {
      if (r.eu == n) return r;
    }
    return null;
  }

  static const List<String> _keywords = [
    'کفش', 'کتانی', 'استوک', 'shoe', 'boot', 'sneaker', 'cleat',
  ];

  /// راهنما فقط برای کفش: دسته یا نامِ محصول کفش باشد و دست‌کم یکی از
  /// سایزهایش در جدول باشد. (توپ هم سایز دارد — «۵» — پس سایزِ عددی به
  /// تنهایی کافی نیست.)
  static bool appliesTo({
    required String? categoryName,
    required String? productName,
    required Iterable<String> sizes,
  }) {
    final text = '${categoryName ?? ''} ${productName ?? ''}'.toLowerCase();
    if (!_keywords.any(text.contains)) return false;
    return sizes.any((s) => byEu(s) != null);
  }
}
