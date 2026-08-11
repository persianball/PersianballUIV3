// lib/views/widgets/product_reviews_section.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/services/review_service.dart';

/// بخش نظرات و پرسش‌وپاسخ محصول در صفحه جزئیات کالا
class ProductReviewsSection extends StatefulWidget {
  final int productId;

  const ProductReviewsSection({super.key, required this.productId});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  ReviewSummary? _summary;
  List<ProductQuestion> _questions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await ReviewService.fetchReviews(widget.productId);
    final questions = await ReviewService.fetchQuestions(widget.productId);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _questions = questions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ReviewService.isMock) _mockBanner(),
            _sectionHeader('نظرات کاربران', 'ثبت نظر', _openReviewSheet),
            const SizedBox(height: 8),
            _ratingSummary(_summary!),
            const SizedBox(height: 12),
            ..._summary!.reviews.take(3).map(_reviewTile),
            if (_summary!.reviews.length > 3)
              TextButton(
                onPressed: _openAllReviews,
                child: Text('مشاهده همه ${_summary!.count} نظر',
                    style: const TextStyle(fontFamily: 'Estedad', fontSize: 12)),
              ),
            const SizedBox(height: 20),
            _sectionHeader('پرسش و پاسخ', 'پرسیدن سؤال', _openQuestionSheet),
            const SizedBox(height: 8),
            if (_questions.isEmpty)
              Text('هنوز سؤالی ثبت نشده است',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 12,
                      color: Colors.grey.shade600))
            else
              ..._questions.take(3).map(_questionTile),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _mockBanner() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          border: Border.all(color: Colors.amber.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'نظرات و پرسش‌ها نمایشی است؛ بک‌اند هنوز endpoint نظرات ندارد.',
                style: TextStyle(fontFamily: 'Estedad', fontSize: 10),
              ),
            ),
          ],
        ),
      );

  Widget _sectionHeader(String title, String action, VoidCallback onTap) => Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          TextButton(
            onPressed: onTap,
            child: Text(action,
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 12,
                    color: AppColor.primary)),
          ),
        ],
      );

  Widget _ratingSummary(ReviewSummary s) {
    if (s.count == 0) {
      return Text('هنوز نظری ثبت نشده است',
          style: TextStyle(
              fontFamily: 'Estedad', fontSize: 12, color: Colors.grey.shade600));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(s.average.toStringAsFixed(1),
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
            _stars(s.average.round(), size: 14),
            Text('${s.count} نظر',
                style: TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 11,
                    color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: s.breakdown.entries.map((e) {
              final ratio = s.count == 0 ? 0.0 : e.value / s.count;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${e.key}',
                        style: const TextStyle(
                            fontFamily: 'Estedad', fontSize: 11)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 11, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          color: AppColor.primary,
                          backgroundColor: AppColor.border,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 18,
                      child: Text('${e.value}',
                          style: TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 10,
                              color: Colors.grey.shade600)),
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

  Widget _reviewTile(ProductReview r) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _stars(r.rating, size: 13),
                const SizedBox(width: 8),
                Text(r.userName,
                    style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                if (r.verifiedPurchase) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.verified, size: 13, color: Colors.green.shade600),
                ],
                const Spacer(),
                Text(r.createdAt,
                    style: TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 10,
                        color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 6),
            Text(r.body,
                style: const TextStyle(
                    fontFamily: 'Estedad', fontSize: 12, height: 1.6)),
          ],
        ),
      );

  Widget _questionTile(ProductQuestion q) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.primarySoft.withOpacity(0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(q.body,
                      style: const TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (q.answer != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.answer!,
                        style: const TextStyle(
                            fontFamily: 'Estedad', fontSize: 12, height: 1.6)),
                    const SizedBox(height: 4),
                    Text(q.answeredBy ?? '',
                        style: TextStyle(
                            fontFamily: 'Estedad',
                            fontSize: 10,
                            color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
              Text('در انتظار پاسخ فروشنده',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 10,
                      color: Colors.grey.shade600)),
            ],
          ],
        ),
      );

  void _openAllReviews() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              const Text('همه نظرات',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ..._summary!.reviews.map(_reviewTile),
            ],
          ),
        ),
      ),
    );
  }

  void _openReviewSheet() {
    int rating = 5;
    final bodyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                const Text('ثبت نظر',
                    style: TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
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
                  style: const TextStyle(fontFamily: 'Estedad', fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'تجربه خود از این کالا را بنویسید…',
                    hintStyle: const TextStyle(
                        fontFamily: 'Estedad', fontSize: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final text = bodyCtrl.text.trim();
                      if (text.isEmpty) return;
                      Navigator.of(ctx).pop();
                      await ReviewService.addReview(widget.productId,
                          rating: rating, body: text);
                      await _load();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('نظر شما ثبت شد',
                              style: TextStyle(fontFamily: 'Estedad')),
                        ),
                      );
                    },
                    child: const Text('ثبت نظر',
                        style: TextStyle(
                            fontFamily: 'Estedad', color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openQuestionSheet() {
    final bodyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              const Text('پرسیدن سؤال',
                  style: TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'Estedad', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'سؤال خود درباره این کالا را بنویسید…',
                  hintStyle:
                      const TextStyle(fontFamily: 'Estedad', fontSize: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    final text = bodyCtrl.text.trim();
                    if (text.isEmpty) return;
                    Navigator.of(ctx).pop();
                    await ReviewService.addQuestion(widget.productId,
                        body: text);
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
                      style: TextStyle(
                          fontFamily: 'Estedad', color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
