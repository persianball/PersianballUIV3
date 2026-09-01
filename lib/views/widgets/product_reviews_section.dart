// lib/views/widgets/product_reviews_section.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_shapes.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_text_styles.dart';
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/services/rating_service.dart';
import 'package:marketky/services/review_service.dart';
import 'package:marketky/views/widgets/app_buttons.dart';

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
            _ratingLine(),
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

  /// خلاصه‌ی امتیاز در یک خطِ جمع‌وجور.
  ///
  /// امتیاز و نظر در بک‌اند دو چیز جدا هستند: `avg_rate` میانگین امتیازهاست
  /// و `comments` نظرهای متنی که *فیلد امتیاز ندارند*. پس نه می‌توان به هر
  /// نظر ستاره نسبت داد و نه تفکیک ستاره‌ای ساخت.
  Widget _ratingLine() {
    final count = widget.comments.length;
    final bool hasRate = widget.avgRate > 0;
    if (!hasRate && count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          if (hasRate) ...[
            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              widget.avgRate.toStringAsFixed(1),
              style: const TextStyle(
                fontFamily: 'Estedad',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColor.ink,
              ),
            ),
            const SizedBox(width: 8),
            Text('·', style: AppTextStyles.labelSm),
            const SizedBox(width: 8),
          ],
          Text('$count نظر', style: AppTextStyles.labelSm),
        ],
      ),
    );
  }

  /// نظر واقعی محصول (مدل ProductComment از پاسخ بک‌اند).
  ///
  /// طرحِ مینیمال: نه کارت، نه سایه، نه آواتار — فقط متن و تاریخ، با یک خط
  /// موباریک به‌عنوان جداکننده. نامِ کاربر و امتیازِ هر نظر عمداً نیامده‌اند
  /// چون بک‌اند هیچ‌کدام را همراه نظر نمی‌دهد.
  Widget _commentTile(ProductComment c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColor.line)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.text,
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 13,
                      height: 1.8,
                      color: AppColor.ink),
                ),
                const SizedBox(height: 6),
                Text(_shortDate(c.createAt), style: AppTextStyles.labelSm),
                if (c.adminResponse.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 2,
                        height: 34,
                        color: AppColor.pitchGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('پاسخ فروشگاه',
                                style: AppTextStyles.labelSm.copyWith(
                                    color: AppColor.pitchGreen,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(c.adminResponse,
                                style: const TextStyle(
                                    fontFamily: 'Estedad',
                                    fontSize: 12,
                                    height: 1.7,
                                    color: AppColor.inkMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );

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
                Flexible(
                  child: Text('پرسش و پاسخ',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMd.copyWith(fontSize: 16)),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                GradientButton(
                  label: 'پرسیدن سؤال',
                  icon: const Icon(Icons.help_outline_rounded),
                  onPressed: _openQuestionSheet,
                  expand: false,
                  height: 38,
                  fontSize: 12.5,
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
              GradientButton(
                label: 'ثبت سؤال',
                icon: const Icon(Icons.send_rounded),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
