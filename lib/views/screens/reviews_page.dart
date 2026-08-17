// lib/views/screens/reviews_page.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/services/review_service.dart';

/// همه نظرات یک محصول با فیلتر بر اساس ستاره
class ReviewsPage extends StatefulWidget {
  final int productId;

  const ReviewsPage({super.key, required this.productId});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  /// 0 یعنی همه، ۱ تا ۵ یعنی فیلتر همان تعداد ستاره
  int _selectedStar = 0;

  ReviewSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await ReviewService.fetchReviews(widget.productId);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  List<ProductReview> get _visible {
    final all = _summary?.reviews ?? const <ProductReview>[];
    if (_selectedStar == 0) return all;
    return all.where((r) => r.rating == _selectedStar).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.obsidianBg,
        appBar: AppBar(
          backgroundColor: AppColor.obsidianBg,
          foregroundColor: AppColor.onSurface,
          elevation: 0,
          title: const Text('نظرات کاربران',
              style: TextStyle(fontFamily: 'Estedad', fontSize: 16, color: AppColor.onSurface)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColor.goldEnd))
            : SafeArea(child: _buildBody(_summary!)),
      ),
    );
  }

  Widget _buildBody(ReviewSummary s) {
    return Column(
      children: [
        _header(s),
        _starFilters(s),
        Divider(height: 1, color: AppColor.outlineVariantDark),
        Expanded(
          child: _visible.isEmpty
              ? _empty()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _reviewTile(_visible[i]),
                ),
        ),
      ],
    );
  }

  Widget _header(ReviewSummary s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // لیست خالی دیگر NaN نمی‌دهد
                s.count == 0 ? '—' : s.average.toStringAsFixed(1),
                style: const TextStyle(
                    fontFamily: 'Estedad',
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: AppColor.onSurface),
              ),
              _stars(s.average.round(), size: 16),
              const SizedBox(height: 4),
              Text('بر اساس ${s.count} نظر',
                  style: const TextStyle(
                      fontFamily: 'Estedad',
                      fontSize: 11,
                      color: AppColor.onSurfaceVariant)),
            ],
          ),
          const SizedBox(width: 24),
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
                              fontFamily: 'Estedad', fontSize: 11, color: AppColor.onSurfaceVariant)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 11, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            color: AppColor.goldEnd,
                            backgroundColor: AppColor.outlineVariantDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 18,
                        child: Text('${e.value}',
                            style: const TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 10,
                                color: AppColor.onSurfaceVariant)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _starFilters(ReviewSummary s) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _chip(label: 'همه (${s.count})', star: 0),
          ...s.breakdown.entries
              .map((e) => _chip(label: '${e.key} (${e.value})', star: e.key)),
        ],
      ),
    );
  }

  Widget _chip({required String label, required int star}) {
    final selected = _selectedStar == star;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ChoiceChip(
        avatar: star == 0
            ? null
            : Icon(Icons.star,
                size: 14, color: selected ? AppColor.onGold : Colors.amber),
        label: Text(label,
            style: TextStyle(
              fontFamily: 'Estedad',
              fontSize: 12,
              color: selected ? AppColor.onGold : AppColor.onSurfaceVariant,
            )),
        selected: selected,
        onSelected: (_) => setState(() => _selectedStar = star),
        selectedColor: AppColor.goldEnd,
        backgroundColor: AppColor.surfaceContainer,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColor.outlineVariantDark),
        ),
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rate_review_outlined,
                  size: 48, color: AppColor.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                _selectedStar == 0
                    ? 'هنوز نظری ثبت نشده است'
                    : 'نظری با $_selectedStar ستاره ثبت نشده است',
                style: const TextStyle(fontFamily: 'Estedad', color: AppColor.onSurface),
              ),
              if (_selectedStar != 0)
                TextButton(
                  onPressed: () => setState(() => _selectedStar = 0),
                  child: const Text('نمایش همه نظرات',
                      style: TextStyle(fontFamily: 'Estedad', color: AppColor.goldEnd)),
                ),
            ],
          ),
        ),
      );

  Widget _stars(int rating, {double size = 16}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => Icon(i < rating ? Icons.star : Icons.star_border,
              size: size, color: Colors.amber),
        ),
      );

  Widget _reviewTile(ProductReview r) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColor.surfaceContainer,
          border: Border.all(color: AppColor.outlineVariantDark),
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
                        fontWeight: FontWeight.w600,
                        color: AppColor.onSurface)),
                if (r.verifiedPurchase) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.verified, size: 13, color: AppColor.successDark),
                ],
                const Spacer(),
                Text(r.createdAt,
                    style: const TextStyle(
                        fontFamily: 'Estedad',
                        fontSize: 10,
                        color: AppColor.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 6),
            Text(r.body,
                style: const TextStyle(
                    fontFamily: 'Estedad', fontSize: 12, height: 1.8, color: AppColor.onSurfaceVariant)),
          ],
        ),
      );
}
