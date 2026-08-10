// lib/views/screens/catalog_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/services/catalog_service.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/item_card.dart';

/// صفحه جست‌وجو و مرور کاتالوگ با فیلتر، دسته‌بندی و مرتب‌سازی
class CatalogPage extends StatefulWidget {
  final String initialQuery;
  final int? initialCategoryId;

  const CatalogPage({super.key, this.initialQuery = '', this.initialCategoryId});

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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: const Text('جست‌وجو در محصولات',
              style: TextStyle(fontFamily: 'Estedad', fontSize: 16)),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            if (_categories.isNotEmpty) _buildCategoryChips(),
            _buildToolbar(results.length),
            const Divider(height: 1),
            Expanded(child: _buildBody(results, visible)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onQueryChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontFamily: 'Estedad'),
        decoration: InputDecoration(
          hintText: 'نام محصول را بنویسید…',
          hintStyle: TextStyle(
              fontFamily: 'Estedad', fontSize: 13, color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _updateFilter(_filter.copyWith(query: ''));
                  },
                ),
          filled: true,
          fillColor: AppColor.primarySoft.withOpacity(0.4),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
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
          _categoryChip(label: 'همه', selected: _filter.categoryId == null,
              onTap: () => _updateFilter(_filter.copyWith(clearCategory: true))),
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
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
              fontFamily: 'Estedad',
              fontSize: 12,
              color: selected ? Colors.white : AppColor.secondary,
            )),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColor.primary,
        backgroundColor: AppColor.primarySoft.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: AppColor.border),
        ),
      ),
    );
  }

  Widget _buildToolbar(int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text('$total محصول',
              style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 12,
                  color: Colors.grey.shade600)),
          const Spacer(),
          TextButton.icon(
            onPressed: _openSortSheet,
            icon: const Icon(Icons.swap_vert, size: 18),
            label: Text(_filter.sort.label,
                style: const TextStyle(fontFamily: 'Estedad', fontSize: 12)),
          ),
          TextButton.icon(
            onPressed: _openFilterSheet,
            icon: Icon(Icons.tune,
                size: 18,
                color: _filter.hasActiveFilter ? AppColor.primary : null),
            label: Text('فیلتر',
                style: TextStyle(
                  fontFamily: 'Estedad',
                  fontSize: 12,
                  color: _filter.hasActiveFilter ? AppColor.primary : null,
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
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontFamily: 'Estedad')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetch,
              style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
              child: const Text('تلاش مجدد',
                  style: TextStyle(fontFamily: 'Estedad', color: Colors.white)),
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
              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('محصولی با این مشخصات پیدا نشد',
                  style: TextStyle(fontFamily: 'Estedad')),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _updateFilter(const CatalogFilter());
                },
                child: const Text('حذف همه فیلترها',
                    style: TextStyle(fontFamily: 'Estedad')),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColor.primary,
      onRefresh: _fetch,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: visible.map((p) => ItemCard(product: p)).toList(),
            ),
            if (visible.length < results.length)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ProductSort.values
                .map((s) => RadioListTile<ProductSort>(
                      value: s,
                      groupValue: _filter.sort,
                      activeColor: AppColor.primary,
                      title: Text(s.label,
                          style: const TextStyle(fontFamily: 'Estedad')),
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
    final prices = _all
        .map(CatalogService.finalPriceOf)
        .whereType<int>()
        .toList()
      ..sort();
    final int bound = prices.isEmpty ? 10000000 : prices.last;

    RangeValues range = RangeValues(
      (_filter.minPrice ?? 0).toDouble(),
      (_filter.maxPrice ?? bound).toDouble().clamp(0, bound.toDouble()),
    );
    bool onlyDiscounted = _filter.onlyDiscounted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                  const Text('فیلترها',
                      style: TextStyle(
                          fontFamily: 'Estedad',
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(
                    'محدوده قیمت: ${thousandSeparator(range.start.toInt())} تا ${thousandSeparator(range.end.toInt())} تومان',
                    style: const TextStyle(fontFamily: 'Estedad', fontSize: 12),
                  ),
                  RangeSlider(
                    values: range,
                    min: 0,
                    max: bound.toDouble(),
                    divisions: 20,
                    activeColor: AppColor.primary,
                    labels: RangeLabels(
                      thousandSeparator(range.start.toInt()),
                      thousandSeparator(range.end.toInt()),
                    ),
                    onChanged: (v) => setSheet(() => range = v),
                  ),
                  SwitchListTile(
                    value: onlyDiscounted,
                    activeColor: AppColor.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('فقط کالاهای تخفیف‌دار',
                        style: TextStyle(fontFamily: 'Estedad', fontSize: 14)),
                    onChanged: (v) => setSheet(() => onlyDiscounted = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _updateFilter(CatalogFilter(
                              query: _filter.query,
                              sort: _filter.sort,
                            ));
                          },
                          child: const Text('حذف فیلترها',
                              style: TextStyle(fontFamily: 'Estedad')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
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
                          child: const Text('اعمال فیلتر',
                              style: TextStyle(
                                  fontFamily: 'Estedad', color: Colors.white)),
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
