// lib/services/catalog_service.dart
//
// سرویس کاتالوگ: جست‌وجو، دسته‌بندی، فیلتر و مرتب‌سازی.
//
// وضعیت بک‌اند:
//   GET /v2/product/product/  فقط صفحه‌بندی (count/next/previous/results) دارد و
//   پارامترهای search/category/ordering را نادیده می‌گیرد و endpoint دسته‌بندی
//   (/v2/product/category/) هم ۴۰۴ می‌دهد.
//
// پیشنهاد برای بک‌اند (وقتی آماده شد، فقط همین فایل عوض می‌شود):
//   GET /v2/product/product/?search=<q>&category=<id>&min_price=&max_price=
//       &only_discounted=true&ordering=-created_at|price|-price|-discount_percentage
//   GET /v2/product/category/            → [{id, name_farsi, name_english, image}]
//
// تا آن زمان: همه صفحات محصول از سرور گرفته و فیلتر/مرتب‌سازی سمت کلاینت انجام
// می‌شود و دسته‌بندی‌ها از روی خود محصولات استخراج می‌شوند.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/ProductModel.dart';

enum ProductSort {
  newest,
  priceAsc,
  priceDesc,
  discount,
}

extension ProductSortFa on ProductSort {
  String get label {
    switch (this) {
      case ProductSort.newest:
        return 'جدیدترین';
      case ProductSort.priceAsc:
        return 'ارزان‌ترین';
      case ProductSort.priceDesc:
        return 'گران‌ترین';
      case ProductSort.discount:
        return 'بیشترین تخفیف';
    }
  }

  /// پارامتری که بک‌اند باید پشتیبانی کند
  String get query {
    switch (this) {
      case ProductSort.newest:
        return '-created_at';
      case ProductSort.priceAsc:
        return 'price';
      case ProductSort.priceDesc:
        return '-price';
      case ProductSort.discount:
        return '-discount_percentage';
    }
  }
}

class CatalogFilter {
  final String query;
  final int? categoryId;
  final int? minPrice;
  final int? maxPrice;
  final bool onlyDiscounted;
  final ProductSort sort;

  const CatalogFilter({
    this.query = '',
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.onlyDiscounted = false,
    this.sort = ProductSort.newest,
  });

  CatalogFilter copyWith({
    String? query,
    int? categoryId,
    bool clearCategory = false,
    int? minPrice,
    int? maxPrice,
    bool clearPrice = false,
    bool? onlyDiscounted,
    ProductSort? sort,
  }) {
    return CatalogFilter(
      query: query ?? this.query,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      onlyDiscounted: onlyDiscounted ?? this.onlyDiscounted,
      sort: sort ?? this.sort,
    );
  }

  bool get hasActiveFilter =>
      categoryId != null ||
      minPrice != null ||
      maxPrice != null ||
      onlyDiscounted;
}

class CatalogService {
  /// همه محصولات را با دنبال کردن صفحه‌های بعدی می‌گیرد.
  /// [maxPages] محافظ برای کاتالوگ‌های خیلی بزرگ است.
  static Future<List<Product>> fetchAllProducts({int maxPages = 20}) async {
    final List<Product> all = [];
    Uri? uri = Uri.parse('${URLs.baseUrl}/v2/product/product/');
    int page = 0;

    while (uri != null && page < maxPages) {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('خطا در بارگذاری محصولات (${response.statusCode})');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>? ?? []);
      all.addAll(results.map((e) => Product.fromJson(e)));

      final next = data['next']?.toString();
      uri = (next == null || next.isEmpty) ? null : _resolveAgainstBase(next);
      page++;
    }
    return all;
  }

  /// آدرس صفحه بعد را با scheme/host/port همان baseUrl می‌سازد
  static Uri _resolveAgainstBase(String url) {
    final base = Uri.parse(URLs.baseUrl);
    final next = Uri.parse(url);
    return next.replace(
      scheme: base.scheme,
      host: base.host,
      port: base.port,
    );
  }

  /// دسته‌بندی‌ها از روی محصولات استخراج می‌شوند (تا وقتی endpoint اختصاصی نیست)
  static List<Category> categoriesFrom(List<Product> products) {
    final Map<int, Category> byId = {};
    for (final p in products) {
      byId[p.category.id] = p.category;
    }
    final list = byId.values.toList();
    list.sort((a, b) => a.nameFarsi.compareTo(b.nameFarsi));
    return list;
  }

  static int countInCategory(List<Product> products, int categoryId) =>
      products.where((p) => p.category.id == categoryId).length;

  /// قیمت نهایی محصول با احتساب تخفیف (قیمت null یعنی نامشخص)
  static int? finalPriceOf(Product p) {
    final price = p.price;
    if (price == null || price <= 0) return null;
    final percent = p.discountPercentage ?? 0;
    if (percent > 0 && percent < 100) {
      return (price * (1 - percent / 100)).toInt();
    }
    return price;
  }

  /// اعمال جست‌وجو، فیلتر و مرتب‌سازی سمت کلاینت
  static List<Product> apply(List<Product> products, CatalogFilter filter) {
    final q = filter.query.trim().toLowerCase();

    final result = products.where((p) {
      if (q.isNotEmpty) {
        final haystack = [
          p.nameFarsi,
          p.nameEnglish ?? '',
          p.description ?? '',
          p.category.nameFarsi,
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      if (filter.categoryId != null && p.category.id != filter.categoryId) {
        return false;
      }
      if (filter.onlyDiscounted && (p.discountPercentage ?? 0) <= 0) {
        return false;
      }
      final price = finalPriceOf(p);
      if (filter.minPrice != null && (price == null || price < filter.minPrice!)) {
        return false;
      }
      if (filter.maxPrice != null && (price == null || price > filter.maxPrice!)) {
        return false;
      }
      return true;
    }).toList();

    switch (filter.sort) {
      case ProductSort.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProductSort.priceAsc:
        result.sort((a, b) =>
            (finalPriceOf(a) ?? 1 << 40).compareTo(finalPriceOf(b) ?? 1 << 40));
        break;
      case ProductSort.priceDesc:
        result.sort((a, b) =>
            (finalPriceOf(b) ?? -1).compareTo(finalPriceOf(a) ?? -1));
        break;
      case ProductSort.discount:
        result.sort((a, b) =>
            (b.discountPercentage ?? 0).compareTo(a.discountPercentage ?? 0));
        break;
    }
    return result;
  }
}
