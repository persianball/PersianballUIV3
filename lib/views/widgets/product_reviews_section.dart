// lib/views/widgets/product_reviews_section.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_text_styles.dart';
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/services/rating_service.dart';
import 'package:marketky/services/review_service.dart';

/// بخش نظرات و پرسش‌وپاسخ محصول در صفحه جزئیات کالا
class ProductReviewsSection extends StatefulWidget {
  final int productId;

  /// میانگین امتیاز واقعی محصول (فیلد avg_rate در پاسخ محصول)
  final double avgRate;

  /// نظرهای *تأییدشده*ی محصول (فیلد comments در پاسخ محصول).
  /// بک‌اند endpoint جداگانه‌ای برای خواندن نظرها ندارد.
  final List<ProductComment> comments;

  /// بعد از ثبت نظر/امتیاز، صفحه‌ی محصول دوباره از سرور خوانده می‌شود
  final VoidCallback? onSubmitted;

  const ProductReviewsSection({
    super.key,
    required this.productId,
    this.avgRate = 0,
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
            const SizedBox(height: 8),
            _ratingSummary(),
            const SizedBox(height: 12),
            if (widget.comments.isEmpty)
              Text('هنوز نظر تأییدشده‌ای برای این کالا ثبت نشده است',
                  style: AppTextStyles.labelSm),
            ...widget.comments.take(3).map(_commentTile),
            if (widget.comments.length > 3)
              TextButton(
                onPressed: _openAllReviews,
                child: Text('مشاهده همه ${widget.comments.length} نظر',
                    style: const TextStyle(fontFamily: 'Estedad', fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onTap) => Row(
        children: [
          Text(title, style: AppTextStyles.headlineMd.copyWith(fontSize: 16)),
          const Spacer(),
          TextButton(
            onPressed: onTap,
            child: Text(action,
                style: AppTextStyles.labelSm.copyWith(color: AppColor.goldEnd)),
          ),
        ],
      );

  Widget _ratingSummary() {
    final count = widget.comments.length;
    if (widget.avgRate <= 0 && count == 0) {
      return Text('هنوز نظری ثبت نشده است', style: AppTextStyles.labelSm);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(widget.avgRate.toStringAsFixed(1),
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColor.goldEnd)),
            _stars(widget.avgRate.round(), size: 14),
            Text('$count نظر', style: AppTextStyles.labelSm),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: _breakdown().entries.map((e) {
              final ratio = count == 0 ? 0.0 : e.value / count;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${e.key}',
                        style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 11,
                            color: AppColor.onSurfaceVariant)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 11, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        color: AppColor.goldEnd,
                        backgroundColor: AppColor.outlineVariantDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 18,
                      child: Text('${e.value}', style: AppTextStyles.labelSm),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _stars(int rating, {double size = 16}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => Icon(
            i < rating ? Icons.star : Icons.star_border,
            size: size,
            color: Colors.amber,
          ),
        ),
      );

  /// نظر واقعی محصول (مدل ProductComment از پاسخ بک‌اند)
  Widget _commentTile(ProductComment c) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.border(AppShapes.rLg),
          shadows: AppColor.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, size: 14, color: AppColor.success),
                const SizedBox(width: 6),
                const Text('نظر تأییدشده',
                    style: TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColor.ink)),
                const Spacer(),
                Text(_shortDate(c.createAt), style: AppTextStyles.labelSm),
              ],
            ),
            const SizedBox(height: 6),
            Text(c.text,
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12,
                    height: 1.7,
                    color: AppColor.inkMuted)),
            if (c.adminResponse.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: ShapeDecoration(
                  color: AppColor.pitchGreenSoft,
                  shape: AppShapes.border(AppShapes.rMd),
                ),
                child: Text('پاسخ فروشگاه: ${c.adminResponse}',
                    style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 11,
                        height: 1.7,
                        color: AppColor.ink)),
              ),
            ],
          ],
        ),
      );

  /// تاریخ ISO بک‌اند فقط تا روز نمایش داده می‌شود
  String _shortDate(String raw) =>
      raw.length >= 10 ? raw.substring(0, 10) : raw;

  /// بک‌اند تفکیک ستاره‌ای نمی‌دهد؛ تا وقتی چنین فیلدی اضافه نشود، همه‌ی
  /// نظرها زیر میانگین امتیاز شمرده می‌شوند.
  Map<int, int> _breakdown() {
    final map = {for (int i = 5; i >= 1; i--) i: 0};
    final bucket = widget.avgRate.round().clamp(1, 5);
    map[bucket] = widget.comments.length;
    return map;
  }

  void _openAllReviews() {
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
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          builder: (ctx, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: [
              Text('همه نظرات', style: AppTextStyles.headlineMd.copyWith(fontSize: 16)),
              const SizedBox(height: 12),
              ...widget.comments.map(_commentTile),
            ],
          ),
        ),
      ),
    );
  }

  /// امتیاز و متن نظر را به APIهای واقعی v2/rating می‌فرستد.
  ///
  /// این دو، دو اندپوینت جدا هستند: اگر ثبت امتیاز شکست بخورد، متن نظر
  /// همچنان ارسال می‌شود و برعکس؛ نتیجه‌ی هرکدام جدا به کاربر گفته می‌شود.
  Future<void> _submitReview({required int rating, required String text}) async {
    setState(() => _submitting = true);

    final commentResult = await RatingService.commentOnProduct(
      productId: widget.productId,
      text: text,
    );
    final rateResult = await RatingService.rateProduct(
      productId: widget.productId,
      rating: rating,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (commentResult.success) {
      _snack(commentResult.message);
    } else {
      _snack(commentResult.message, error: true);
    }
    if (!rateResult.success) {
      _snack('ثبت امتیاز: ${rateResult.message}', error: true);
    }

    if (commentResult.success || rateResult.success) {
      widget.onSubmitted?.call();
    }
  }

  void _openReviewSheet() {
    int rating = 5;
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
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => setSheet(() => rating = i + 1),
                      icon: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 4,
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.goldEnd,
                      shape: AppShapes.pill,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _submitting
                        ? null
                        : () async {
                            final text = bodyCtrl.text.trim();
                            if (text.isEmpty) return;
                            Navigator.of(ctx).pop();
                            await _submitReview(rating: rating, text: text);
                          },
                    child: const Text('ثبت نظر',
                        style: TextStyle(fontFamily: 'Estedad', color: AppColor.onGold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

/// بخشِ «پرسش و پاسخ» محصول — بخشِ مستقل و همیشه‌قابل‌دیدن در صفحه‌ی جزئیات.
class ProductQuestionsSection extends StatefulWidget {
  const ProductQuestionsSection({super.key, required this.productId});

  final int productId;

  @override
  State<ProductQuestionsSection> createState() =>
      _ProductQuestionsSectionState();
}

class _ProductQuestionsSectionState extends State<ProductQuestionsSection> {
  List<ProductQuestion> _questions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final questions = await ReviewService.fetchQuestions(widget.productId);
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
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
            Row(
              children: [
                Text('پرسش و پاسخ',
                    style: AppTextStyles.headlineMd.copyWith(fontSize: 16)),
                const Spacer(),
                TextButton(
                  onPressed: _openQuestionSheet,
                  child: Text('پرسیدن سؤال',
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColor.goldEnd)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColor.goldEnd),
                  ),
                ),
              )
            else if (_questions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('هنوز سؤالی ثبت نشده است — اولین نفر باشید!',
                    style: AppTextStyles.labelSm),
              )
            else
              ..._questions.take(5).map(_questionTile),
          ],
        ),
      ),
    );
  }

  Widget _questionTile(ProductQuestion q) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.border(AppShapes.rLg),
          shadows: AppColor.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.help_outline_rounded,
                    size: 16, color: AppColor.goldEnd),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(q.body,
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.6,
                          color: AppColor.ink)),
                ),
              ],
            ),
            if (q.answer != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: ShapeDecoration(
                  color: AppColor.pitchGreenSoft,
                  shape: AppShapes.border(AppShapes.rMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.answer!,
                        style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 12,
                            height: 1.7,
                            color: AppColor.ink)),
                    const SizedBox(height: 4),
                    Text(q.answeredBy ?? 'پشتیبانی فروشگاه',
                        style: const TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 10,
                            color: AppColor.pitchGreen,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text('در انتظار پاسخ فروشنده', style: AppTextStyles.labelSm),
            ],
          ],
        ),
      );

  void _openQuestionSheet() {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('پرسیدن سؤال',
                  style: AppTextStyles.headlineMd.copyWith(fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 3,
                style: const TextStyle(
                    fontFamily: 'Estedad', fontSize: 13, color: AppColor.onSurface),
                decoration: InputDecoration(
                  hintText: 'سؤال خود درباره این کالا را بنویسید…',
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.goldEnd,
                    shape: AppShapes.pill,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    final text = bodyCtrl.text.trim();
                    if (text.isEmpty) return;
                    Navigator.of(ctx).pop();
                    await ReviewService.addQuestion(widget.productId, body: text);
                    await _load();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('سؤال شما ثبت شد',
                            style: TextStyle(fontFamily: 'Estedad')),
                      ),
                    );
                  },
                  child: const Text('ثبت سؤال',
                      style: TextStyle(fontFamily: 'Estedad', color: AppColor.onGold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
