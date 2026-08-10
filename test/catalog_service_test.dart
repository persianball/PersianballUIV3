import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/services/catalog_service.dart';

Product _p({
  required int id,
  required String name,
  int? price,
  int? discount,
  int categoryId = 1,
  String categoryName = 'کفش',
  String createdAt = '2024-01-01',
}) {
  return Product(
    id: id,
    image: null,
    price: price,
    discountPercentage: discount,
    category: Category(id: categoryId, nameFarsi: categoryName),
    nameFarsi: name,
    nameEnglish: null,
    description: null,
    published: true,
    createdAt: createdAt,
    images: const [],
    similarProducts: const [],
  );
}

void main() {
  final products = [
    _p(id: 1, name: 'کفش تروپیک', price: 4200000, discount: 20, createdAt: '2024-03-01'),
    _p(id: 2, name: 'توپ فریستایل', price: 5000000, discount: 0, categoryId: 2, categoryName: 'توپ', createdAt: '2024-02-01'),
    _p(id: 3, name: 'تی شرت', price: null, categoryId: 3, categoryName: 'پوشاک', createdAt: '2024-05-01'),
    _p(id: 4, name: 'کفش فلو', price: 3000000, discount: 10, createdAt: '2024-01-15'),
  ];

  group('finalPriceOf', () {
    test('تخفیف را اعمال می‌کند', () {
      expect(CatalogService.finalPriceOf(products[0]), 3360000);
    });

    test('بدون تخفیف همان قیمت است', () {
      expect(CatalogService.finalPriceOf(products[1]), 5000000);
    });

    test('قیمت null نتیجه null می‌دهد', () {
      expect(CatalogService.finalPriceOf(products[2]), isNull);
    });
  });

  group('categoriesFrom', () {
    test('دسته‌بندی‌های یکتا استخراج می‌شوند', () {
      final cats = CatalogService.categoriesFrom(products);
      expect(cats.length, 3);
      expect(cats.map((c) => c.id).toSet(), {1, 2, 3});
    });

    test('تعداد کالای هر دسته درست است', () {
      expect(CatalogService.countInCategory(products, 1), 2);
      expect(CatalogService.countInCategory(products, 2), 1);
    });
  });

  group('apply', () {
    test('جست‌وجو روی نام فارسی', () {
      final r = CatalogService.apply(products, const CatalogFilter(query: 'تروپیک'));
      expect(r.single.id, 1);
    });

    test('جست‌وجو نام دسته‌بندی را هم پوشش می‌دهد', () {
      final r = CatalogService.apply(products, const CatalogFilter(query: 'کفش'));
      expect(r.map((p) => p.id).toSet(), {1, 4});
    });

    test('فیلتر دسته‌بندی', () {
      final r = CatalogService.apply(products, const CatalogFilter(categoryId: 2));
      expect(r.single.id, 2);
    });

    test('فقط تخفیف‌دار، کالای با تخفیف صفر را حذف می‌کند', () {
      final r = CatalogService.apply(
          products, const CatalogFilter(onlyDiscounted: true));
      expect(r.map((p) => p.id).toSet(), {1, 4});
    });

    test('فیلتر قیمت روی قیمت نهایی اعمال می‌شود', () {
      // قیمت نهایی کالای ۱ برابر ۳,۳۶۰,۰۰۰ است
      final r = CatalogService.apply(
          products, const CatalogFilter(minPrice: 3300000, maxPrice: 4000000));
      expect(r.map((p) => p.id).toSet(), {1});
    });

    test('کالای بدون قیمت با فیلتر قیمت حذف می‌شود', () {
      final r = CatalogService.apply(products, const CatalogFilter(maxPrice: 9999999));
      expect(r.map((p) => p.id).contains(3), isFalse);
    });

    test('مرتب‌سازی ارزان‌ترین', () {
      final r = CatalogService.apply(
          products, const CatalogFilter(sort: ProductSort.priceAsc));
      expect(r.first.id, 4); // 2,700,000
    });

    test('مرتب‌سازی بیشترین تخفیف', () {
      final r = CatalogService.apply(
          products, const CatalogFilter(sort: ProductSort.discount));
      expect(r.first.id, 1);
    });

    test('مرتب‌سازی جدیدترین', () {
      final r = CatalogService.apply(
          products, const CatalogFilter(sort: ProductSort.newest));
      expect(r.first.id, 3);
    });
  });
}
