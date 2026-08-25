// lib/views/screens/catalog_page.dart
import 'dart:async';
import 'package:marketky/constant/app_shapes.dart';

import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/app_text_styles.dart';
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/services/catalog_service.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/services/analytics_service.dart';
import 'package:marketky/views/widgets/app_network_image.dart';
import 'package:marketky/views/widgets/app_buttons.dart';
import 'package:marketky/views/widgets/product_grid_card.dart';

/// صفحه جست‌وجو و مرور کاتالوگ با فیلتر، دسته‌بندی و مرتب‌سازی
class CatalogPage extends StatefulWidget {
  final String initialQuery;
  final int? initialCategoryId;

  const CatalogPage(
      {super.key, this.initialQuery = '', this.initialCategoryId});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<Product> _all = [];
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;

  late CatalogFilter _filter;

  /// صفحه‌بندی سمت کلاینت تا لیست‌های بلند یکجا رندر نشوند
  static const int _pageSize = 10;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _filter = CatalogFilter(
      query: widget.initialQuery,
      categoryId: widget.initialCategoryId,
    );
    _searchController.text = widget.initialQuery;
    _scrollController.addListener(_onScroll);
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await CatalogService.fetchAllProducts();
      setState(() {
        _all = products;
        _categories = CatalogService.categoriesFrom(products);
        _loading = false;
      });
      AnalyticsService.viewItemList(
          listName: 'catalog', count: products.length);
    } catch (e) {
      setState(() {
        _error = 'دریافت محصولات ناموفق بود';
        _loading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final results = CatalogService.apply(_all, _filter);
      if (_visibleCount < results.length) {
        setState(() => _visibleCount += _pageSize);
      }
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _filter = _filter.copyWith(query: value);
        _visibleCount = _pageSize;
      });
      if (value.trim().isNotEmpty) {
        AnalyticsService.search(
          query: value.trim(),
          resultCount: CatalogService.apply(_all, _filter).length,
        );
      }
    });
  }

  void _updateFilter(CatalogFilter next) {
    setState(() {
      _filter = next;
      _visibleCount = _pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = CatalogService.apply(_all, _filter);
    final visible = results.take(_visibleCount).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColor.milk,
        appBar: AppBar(
          backgroundColor: AppColor.milk,
          elevation: 0,
          centerTitle: true,
          // این صفحه یکی از تب‌های نوار پایین است؛ دکمه‌ی بازگشت خودکار
          // نباید نمایش داده شود.
          automaticallyImplyLeading: false,
          title: Text('فروشگاه',
              style: AppTextStyles.headlineMd
                  .copyWith(fontSize: 17, color: AppColor.ink)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: CircleIconButton(
                icon: Icons.compare_arrows_rounded,
                tooltip: 'مقایسه محصولات',
                onTap: () => Navigator.of(context).pushNamed('/compare'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            if (_categories.isNotEmpty) _buildCategoryChips(),
            _buildToolbar(results.length),
            Divider(height: 1, color: AppColor.line),
            Expanded(child: _buildBody(results, visible)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: ShapeDecoration(
          color: AppColor.card,
          shape: AppShapes.pill,
          shadows: AppColor.cardShadow,
        ),
        child: TextField(
        controller: _searchController,
        onChanged: _onQueryChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontFamily: 'Estedad', color: AppColor.ink),
        decoration: InputDecoration(
          hintText: 'نام محصول را بنویسید…',
          hintStyle: TextStyle(
              fontFamily: 'Estedad',
              fontSize: 13,
              color: AppColor.onSurfaceVariant),
          prefixIcon: const Icon(Icons.search, color: AppColor.onSurfaceVariant),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, color: AppColor.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                    _updateFilter(_filter.copyWith(query: ''));
                  },
                ),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _categoryChip(
              label: 'همه',
              selected: _filter.categoryId == null,
              onTap: () =>
                  _updateFilter(_filter.copyWith(clearCategory: true))),
          ..._categories.map((c) {
            final count = CatalogService.countInCategory(_all, c.id);
            return _categoryChip(
              label: '${c.nameFarsi} ($count)',
              selected: _filter.categoryId == c.id,
              onTap: () => _updateFilter(_filter.copyWith(categoryId: c.id)),
            );
          }),
        ],
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Container(
        decoration: ShapeDecoration(
          color: selected ? null : AppColor.cardMuted,
          gradient: selected ? AppColor.greenGradient : null,
          shape: AppShapes.pill,
          shadows: selected ? AppColor.greenShadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          shape: AppShapes.pill,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Text(label,
                  style: AppTextStyles.labelSm.copyWith(
                    letterSpacing: 0,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : AppColor.inkMuted,
                  )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text('$total محصول', style: AppTextStyles.labelSm),
          const Spacer(),
          TextButton.icon(
            onPressed: _openSortSheet,
            icon: const Icon(Icons.swap_vert,
                size: 18, color: AppColor.onSurfaceVariant),
            label: Text(_filter.sort.label,
                style: AppTextStyles.labelSm),
          ),
          TextButton.icon(
            onPressed: _openFilterSheet,
            icon: Icon(Icons.tune,
                size: 18,
                color: _filter.hasActiveFilter
                    ? AppColor.goldEnd
                    : AppColor.onSurfaceVariant),
            label: Text('فیلتر',
                style: AppTextStyles.labelSm.copyWith(
                  color: _filter.hasActiveFilter
                      ? AppColor.goldEnd
                      : AppColor.onSurfaceVariant,
                  fontWeight: _filter.hasActiveFilter
                      ? FontWeight.w700
                      : FontWeight.w400,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Product> results, List<Product> visible) {
    // اسکلتون به‌جای اسپینر: پرش لِی‌اوت کمتر و حس سرعت بیشتر
    if (_loading) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children:
              List.generate(6, (_) => const ProductCardSkeleton()),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 40, color: AppColor.outlineDark),
            const SizedBox(height: 12),
            Text(_error!, style: AppTextStyles.bodyMd),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.goldEnd,
                shape: AppShapes.pill,
              ),
              child: Text('تلاش مجدد',
                  style: AppTextStyles.labelSm.copyWith(color: AppColor.onGold)),
            ),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 48, color: AppColor.outlineDark),
              const SizedBox(height: 12),
              Text('محصولی با این مشخصات پیدا نشد', style: AppTextStyles.bodyMd),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _updateFilter(const CatalogFilter());
                },
                child: Text('حذف همه فیلترها',
                    style: AppTextStyles.labelSm.copyWith(color: AppColor.goldEnd)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColor.pitchGreen,
      backgroundColor: AppColor.card,
      onRefresh: _fetch,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: visible
                  .map((p) => SizedBox(
                      width: (MediaQuery.of(context).size.width / 2 - 16 - 8)
                          .clamp(130.0, 200.0),
                      child: ProductGridCard(
                          product: p, showAddToCartButton: true)))
                  .toList(),
            ),
            if (visible.length < results.length)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColor.pitchGreen),
              ),
            // فضای خالی زیر لیست تا نوار ناوبری شناور روی محتوا نیفتد
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColor.card,
      shape: AppShapes.borderTop(AppShapes.rXl),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ProductSort.values
                .map((s) => RadioListTile<ProductSort>(
                      value: s,
                      groupValue: _filter.sort,
                      activeColor: AppColor.goldEnd,
                      title: Text(s.label, style: AppTextStyles.bodyMd),
                      onChanged: (v) {
                        Navigator.of(ctx).pop();
                        if (v != null) _updateFilter(_filter.copyWith(sort: v));
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  void _openFilterSheet() {
    final prices =
        _all.map(CatalogService.finalPriceOf).whereType<int>().toList()..sort();
    final int bound = prices.isEmpty ? 10000000 : prices.last;

    RangeValues range = RangeValues(
      (_filter.minPrice ?? 0).toDouble(),
      (_filter.maxPrice ?? bound).toDouble().clamp(0, bound.toDouble()),
    );
    bool onlyDiscounted = _filter.onlyDiscounted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.card,
      shape: AppShapes.borderTop(AppShapes.rXl),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setSheet) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('فیلترها', style: AppTextStyles.headlineMd.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),
                  Text(
                    'محدوده قیمت: ${thousandSeparator(range.start.toInt())} تا ${thousandSeparator(range.end.toInt())} تومان',
                    style: AppTextStyles.labelSm,
                  ),
                  SliderTheme(
                    data: SliderTheme.of(ctx).copyWith(
                      activeTrackColor: AppColor.goldEnd,
                      thumbColor: AppColor.goldEnd,
                      inactiveTrackColor: AppColor.outlineVariantDark,
                      valueIndicatorColor: AppColor.goldEnd,
                    ),
                    child: RangeSlider(
                      values: range,
                      min: 0,
                      max: bound.toDouble(),
                      divisions: 20,
                      labels: RangeLabels(
                        thousandSeparator(range.start.toInt()),
                        thousandSeparator(range.end.toInt()),
                      ),
                      onChanged: (v) => setSheet(() => range = v),
                    ),
                  ),
                  SwitchListTile(
                    value: onlyDiscounted,
                    activeColor: AppColor.goldEnd,
                    contentPadding: EdgeInsets.zero,
                    title: Text('فقط کالاهای تخفیف‌دار', style: AppTextStyles.bodyMd),
                    onChanged: (v) => setSheet(() => onlyDiscounted = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColor.onSurfaceVariant,
                            side: BorderSide(color: AppColor.outlineVariantDark),
                            shape: AppShapes.pill,
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _updateFilter(CatalogFilter(
                              query: _filter.query,
                              sort: _filter.sort,
                            ));
                          },
                          child: Text('حذف فیلترها', style: AppTextStyles.labelSm),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.goldEnd,
                            shape: AppShapes.pill,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _updateFilter(_filter.copyWith(
                              minPrice: range.start.toInt() == 0
                                  ? null
                                  : range.start.toInt(),
                              maxPrice: range.end.toInt() >= bound
                                  ? null
                                  : range.end.toInt(),
                              onlyDiscounted: onlyDiscounted,
                            ));
                          },
                          child: Text('اعمال فیلتر',
                              style: AppTextStyles.labelSm.copyWith(color: AppColor.onGold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
