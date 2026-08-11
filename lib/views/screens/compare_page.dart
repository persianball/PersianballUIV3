// lib/views/screens/compare_page.dart
import 'package:flutter/material.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/services/catalog_service.dart';
import 'package:marketky/utils/ThousandsFormatter.dart';
import 'package:marketky/views/widgets/app_network_image.dart';

/// مقایسه چند محصول کنار هم.
///
/// داده کاملاً واقعی است و از همان /v2/product/product/ می‌آید؛ ویژگی‌های
/// مقایسه (قیمت، تخفیف، دسته‌بندی) از فیلدهای موجود ساخته می‌شوند.
/// پیشنهاد برای بک‌اند: افزودن آرایه `attributes` به محصول
/// (مثل جنس، وزن، کشور سازنده) تا جدول مقایسه غنی‌تر شود.
class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  List<Product> _all = [];
  final List<Product> _selected = [];
  bool _loading = true;
  String? _error;

  static const int _maxCompare = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await CatalogService.fetchAllProducts();
      if (!mounted) return;
      setState(() {
        _all = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'دریافت محصولات ناموفق بود';
        _loading = false;
      });
    }
  }

  void _toggle(Product p) {
    setState(() {
      if (_selected.any((e) => e.id == p.id)) {
        _selected.removeWhere((e) => e.id == p.id);
      } else if (_selected.length < _maxCompare) {
        _selected.add(p);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حداکثر ۳ کالا را می‌توانید مقایسه کنید',
                style: TextStyle(fontFamily: 'Estedad')),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: const Text('مقایسه محصولات',
              style: TextStyle(fontFamily: 'Estedad', fontSize: 16)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(_error!,
                        style: const TextStyle(fontFamily: 'Estedad')))
                : SafeArea(
                    child: Column(
                      children: [
                        _picker(),
                        const Divider(height: 1),
                        Expanded(child: _table()),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _picker() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        itemCount: _all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = _all[i];
          final selected = _selected.any((e) => e.id == p.id);
          return GestureDetector(
            onTap: () => _toggle(p),
            child: Container(
              width: 80,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColor.primary : AppColor.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  AppNetworkImage(
                    url: '${URLs.baseUrl}${p.image ?? ''}',
                    width: 48,
                    height: 40,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      p.nameFarsi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: 'Estedad', fontSize: 9, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _table() {
    if (_selected.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.compare_arrows,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('برای شروع، حداکثر ۳ کالا را از بالا انتخاب کنید',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Estedad', fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final rows = <String, String Function(Product)>{
      'دسته‌بندی': (p) => p.category.nameFarsi,
      'قیمت': (p) {
        final price = CatalogService.finalPriceOf(p);
        return price == null ? '—' : '${thousandSeparator(price)} تومان';
      },
      'قیمت پیش از تخفیف': (p) =>
          (p.discountPercentage ?? 0) > 0 && p.price != null
              ? '${thousandSeparator(p.price!)} تومان'
              : '—',
      'تخفیف': (p) => (p.discountPercentage ?? 0) > 0
          ? '٪${p.discountPercentage}'
          : 'ندارد',
      'تعداد تصاویر': (p) => '${p.images.length}',
      'وضعیت انتشار': (p) => p.published ? 'منتشرشده' : 'پیش‌نویس',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 90),
              ..._selected.map((p) => Expanded(
                    child: Column(
                      children: [
                        AppNetworkImage(
                          url: '${URLs.baseUrl}${p.image ?? ''}',
                          height: 70,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.nameFarsi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          ...rows.entries.map((entry) => Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(entry.key,
                          style: TextStyle(
                              fontFamily: 'Estedad',
                              fontSize: 11,
                              color: Colors.grey.shade600)),
                    ),
                    ..._selected.map((p) => Expanded(
                          child: Text(
                            entry.value(p),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        )),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 90),
              ..._selected.map((p) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamed('/product/${p.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('مشاهده',
                            style: TextStyle(
                                fontFamily: 'Estedad',
                                fontSize: 11,
                                color: Colors.white)),
                      ),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
