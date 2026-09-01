// lib/views/widgets/product_reviews_section.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_text_styles.dart';
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/services/rating_service.dart';
import 'package:marketky/views/widgets/app_buttons.dart';

/// بخش نظرات و پرسش‌وپاسخ محصول در صفحه جزئیات کالا
class ProductReviewsSection extends StatefulWidget {
  final int productId;

  /// میانگین امتیاز واقعی محصول (فیلد avg_rate در پاسخ محصول)
  final double avgRate;

  /// تفکیک ستاره‌ای واقعی (فیلد rating_distribution): ستاره → تعداد
  final Map<int, int> ratingDistribution;

  /// نظرهای *تأییدشده*ی محصول (فیلد comments در پاسخ محصول).
  /// بک‌اند endpoint جداگانه‌ای برای خواندن نظرها ندارد.
  final List<ProductComment> comments;

  /// بعد از ثبت نظر/امتیاز، صفحه‌ی محصول دوباره از سرور خوانده می‌شود
  final VoidCallback? onSubmitted;

  const ProductReviewsSection({
    super.key,
    required this.productId,
    this.avgRate = 0,
    this.ratingDistribution = const {},
    this.comments = const [],
    this.onSubmitted,
  });

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  bool _submitting = false;

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontFamily: 'Estedad')),
        backgroundColor: error ? AppColor.danger : AppColor.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('نظرات کاربران', 'ثبت نظر', _openReviewSheet),
            _ratingSummary(),
            const SizedBox(height: 4),
            if (widget.comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('هنوز نظری برای این کالا ثبت نشده است',
                    style: AppTextStyles.labelSm),
              )
            else
              // همه‌ی نظرها همین‌جا می‌آیند؛ «مشاهده همه» و لیست تکراری حذف شد
              ...widget.comments.map(_commentTile),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onTap) => Row(
        children: [
          Flexible(
            child: Text(title,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headlineMd.copyWith(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          const Spacer(),
          // TextButton ساده از متنِ کنارش قابل تشخیص نبود و کاربر نمی‌فهمید
          // قابلِ زدن است؛ حالا دکمه‌ی قرصیِ گرادیانی با آیکن است.
          GradientButton(
            label: action,
            icon: const Icon(Icons.rate_review_outlined),
            onPressed: onTap,
            expand: false,
            height: 38,
            fontSize: 12.5,
          ),
        ],
      );

  /// خلاصه‌ی امتیاز: میانگین، تعداد رأی و تفکیک ستاره‌ای.
  ///
  /// داده‌ی نمودار از `rating_distribution` بک‌اند می‌آید. پیش‌تر چنین فیلدی
  /// نبود و نمودار همه‌ی نظرها را زیر ستاره‌ی گردشده‌ی میانگین می‌ریخت که
  /// ساختگی بود؛ حالا واقعی است. امتیاز و نظر همچنان دو چیز جدا هستند —
  /// یک نظر می‌تواند امتیاز نداشته باشد و برعکس.
  Widget _ratingSummary() {
    final dist = widget.ratingDistribution;
    final totalVotes = dist.values.fold<int>(0, (a, b) => a + b);
    final commentCount = widget.comments.length;
    final bool hasRate = widget.avgRate > 0 || totalVotes > 0;
    if (!hasRate && commentCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.border(
            AppShapes.rLg,
            side: const BorderSide(color: AppColor.line),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.avgRate.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: AppColor.ink,
                  ),
                ),
                const SizedBox(height: 2),
                _stars(widget.avgRate.round(), size: 13),
                const SizedBox(height: 4),
                Text(
                  totalVotes > 0 ? '$totalVotes امتیاز' : 'بدون امتیاز',
                  style: AppTextStyles.labelSm,
                ),
              ],
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 64, color: AppColor.line),
            const SizedBox(width: 14),
            // نمودار تفکیک: از ۵ ستاره به ۱
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int star = 5; star >= 1; star--)
                    _distributionRow(star, dist[star] ?? 0, totalVotes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _distributionRow(int star, int count, int total) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            child: Text('$star',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColor.inkMuted)),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  color: AppColor.pitchGreen,
                  backgroundColor: AppColor.cardMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text('$count',
                textAlign: TextAlign.left,
                style: AppTextStyles.labelSm),
          ),
        ],
      ),
    );
  }

  Widget _stars(int rating, {double size = 16}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => Icon(
            i < rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: i < rating ? Colors.amber : AppColor.lineStrong,
          ),
        ),
      );

  /// رنگِ آواتار از روی نام ساخته می‌شود تا هر کاربر همیشه یک رنگ ثابت
  /// داشته باشد (بدون نیاز به فیلدِ رنگ از بک‌اند).
  static const List<List<Color>> _avatarPalette = [
    [Color(0xFF2FA45C), Color(0xFF1B7A3E)],
    [Color(0xFF4C8DF6), Color(0xFF2563EB)],
    [Color(0xFF9B6BE0), Color(0xFF7C3AED)],
    [Color(0xFFF0A03C), Color(0xFFD97706)],
    [Color(0xFF20B7B0), Color(0xFF0E8F8A)],
    [Color(0xFFEF6A6A), Color(0xFFDC2626)],
  ];

  List<Color> _avatarColors(String seed) {
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return _avatarPalette[hash % _avatarPalette.length];
  }

  /// نظر واقعی محصول (مدل ProductComment از پاسخ بک‌اند).
  ///
  /// نامِ کاربر با آواتارِ حرف‌اول و رنگِ اختصاصی نمایش داده می‌شود؛
  /// امتیازِ هر نظر عمداً نیامده چون بک‌اند آن را همراه نظر نمی‌دهد.
  Widget _commentTile(ProductComment c) {
    final colors = _avatarColors(c.username.isEmpty ? c.text : c.username);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.border(
            AppShapes.rLg,
            side: const BorderSide(color: AppColor.line),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: colors,
                    ),
                    shape: const CircleBorder(),
                  ),
                  child: Text(
                    c.initial,
                    style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColor.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(_shortDate(c.createAt), style: AppTextStyles.labelSm),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              c.text,
              style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 13,
                height: 1.85,
                color: AppColor.ink,
              ),
            ),
            if (c.adminResponse.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: ShapeDecoration(
                  color: AppColor.pitchGreenSoft,
                  shape: AppShapes.border(AppShapes.rMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded,
                            size: 14, color: AppColor.pitchGreen),
                        const SizedBox(width: 5),
                        Text('پاسخ فروشگاه',
                            style: AppTextStyles.labelSm.copyWith(
                                color: AppColor.pitchGreen,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      c.adminResponse,
                      style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 12,
                        height: 1.8,
                        color: AppColor.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// تاریخ ISO بک‌اند فقط تا روز نمایش داده می‌شود
  String _shortDate(String raw) =>
      raw.length >= 10 ? raw.substring(0, 10) : raw;


  /// امتیاز و متن نظر را به APIهای واقعی v2/rating می‌فرستد.
  ///
  /// این دو، دو اندپوینت جدا هستند: اگر ثبت امتیاز شکست بخورد، متن نظر
  /// همچنان ارسال می‌شود و برعکس؛ نتیجه‌ی هرکدام جدا به کاربر گفته می‌شود.
  /// ثبت نظر و امتیاز. هر دو اختیاری‌اند: کاربر می‌تواند فقط متن بنویسد
  /// (بدون امتیاز)، فقط ستاره بدهد، یا هر دو را با هم بفرستد.
  Future<void> _submitReview({int? rating, String? text}) async {
    final body = (text ?? '').trim();
    final bool hasText = body.isNotEmpty;
    final bool hasRating = rating != null && rating > 0;
    if (!hasText && !hasRating) return;

    setState(() => _submitting = true);

    RatingResult? commentResult;
    RatingResult? rateResult;

    if (hasText) {
      commentResult = await RatingService.commentOnProduct(
        productId: widget.productId,
        text: body,
      );
    }
    // فقط وقتی کاربر واقعاً ستاره‌ای انتخاب کرده باشد امتیاز فرستاده می‌شود؛
    // پیش‌تر امتیاز پیش‌فرض ۵ بود و نظرِ بدون امتیاز هم بی‌اطلاعِ کاربر
    // ۵ ستاره ثبت می‌کرد.
    if (hasRating) {
      rateResult = await RatingService.rateProduct(
        productId: widget.productId,
        rating: rating,
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (commentResult != null) {
      _snack(commentResult.message, error: !commentResult.success);
    }
    if (rateResult != null && !rateResult.success) {
      _snack('ثبت امتیاز: ${rateResult.message}', error: true);
    } else if (commentResult == null && rateResult != null) {
      _snack(rateResult.message);
    }

    if ((commentResult?.success ?? false) || (rateResult?.success ?? false)) {
      widget.onSubmitted?.call();
    }
  }

  void _openReviewSheet() {
    // ۰ یعنی «امتیازی انتخاب نشده»
    int rating = 0;
    final bodyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.obsidianBg,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColor.outlineVariantDark),
        borderRadius: AppShapes.radius(AppShapes.rMd),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ثبت نظر', style: AppTextStyles.headlineMd.copyWith(fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('امتیاز (اختیاری)', style: AppTextStyles.labelSm),
                    const Spacer(),
                    if (rating > 0)
                      TextButton(
                        onPressed: () => setSheet(() => rating = 0),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('حذف امتیاز',
                            style: AppTextStyles.labelSm
                                .copyWith(color: AppColor.danger)),
                      ),
                  ],
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: '${i + 1} ستاره',
                      // زدنِ دوباره‌ی همان ستاره، امتیاز را برمی‌دارد
                      onPressed: () => setSheet(
                          () => rating = (rating == i + 1) ? 0 : i + 1),
                      icon: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: i < rating ? Colors.amber : AppColor.lineStrong,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 4,
                  onChanged: (_) => setSheet(() {}),
                  style: const TextStyle(
                      fontFamily: 'Estedad', fontSize: 13, color: AppColor.onSurface),
                  decoration: InputDecoration(
                    hintText: 'تجربه خود از این کالا را بنویسید…',
                    hintStyle: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 12,
                        color: AppColor.onSurfaceVariant),
                    filled: true,
                    fillColor: AppColor.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: AppShapes.radius(AppShapes.rMd),
                      borderSide: BorderSide(color: AppColor.outlineVariantDark),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppShapes.radius(AppShapes.rMd),
                      borderSide: BorderSide(color: AppColor.outlineVariantDark),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppShapes.radius(AppShapes.rMd),
                      borderSide: BorderSide(color: AppColor.goldEnd, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GradientButton(
                  label: 'ثبت نظر',
                  icon: const Icon(Icons.send_rounded),
                  loading: _submitting,
                  // نوشتنِ متن یا دادنِ امتیاز، هرکدام به‌تنهایی کافی است
                  enabled: bodyCtrl.text.trim().isNotEmpty || rating > 0,
                  onPressed: () async {
                    final text = bodyCtrl.text.trim();
                    if (text.isEmpty && rating == 0) return;
                    Navigator.of(ctx).pop();
                    await _submitReview(rating: rating, text: text);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
