import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/constant/app_color.dart';
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/views/widgets/item_card.dart';

Product _product({int? price, int? discount}) => Product(
      id: 1,
      image: null,
      price: price,
      discountPercentage: discount,
      category: Category(id: 1, nameFarsi: 'کفش'),
      nameFarsi: 'محصول تست',
      nameEnglish: null,
      description: null,
      published: true,
      createdAt: '2024-01-01',
      images: const [],
      similarProducts: const [],
    );

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Directionality(
      textDirection: TextDirection.rtl,
      child: child,
    )));

void main() {
  testWidgets('پیش‌فرض: بدون دکمه افزودن به سبد (رفتار قدیمی حفظ می‌شود)',
      (tester) async {
    await tester.pumpWidget(_host(ItemCard(product: _product(price: 1000))));
    expect(find.text('افزودن به سبد'), findsNothing);
  });

  testWidgets('showAddToCartButton=true دکمه را نشان می‌دهد', (tester) async {
    await tester.pumpWidget(_host(ItemCard(
      product: _product(price: 1000),
      dark: true,
      showAddToCartButton: true,
    )));
    expect(find.text('افزودن به سبد'), findsOneWidget);
  });

  testWidgets('کارت سفید با گوشه‌ی اسکوئرکل و سایه‌ی برجسته است',
      (tester) async {
    await tester.pumpWidget(_host(ItemCard(product: _product(price: 1000))));
    final container = tester.widget<Container>(find
        .descendant(of: find.byType(ItemCard), matching: find.byType(Container))
        .first);
    final decoration = container.decoration as ShapeDecoration;
    expect(decoration.color, AppColor.card);
    // گوشه‌ها باید انحنای پیوسته (اسکوئرکل) داشته باشند، نه کمان دایره‌ای
    expect(decoration.shape, isA<ContinuousRectangleBorder>());
    expect(decoration.shadows, isNotEmpty);
  });

  testWidgets('بدون قیمت واقعی، متن "مشاهده قیمت" نشان داده می‌شود',
      (tester) async {
    await tester.pumpWidget(_host(ItemCard(product: _product(price: null))));
    expect(find.text('مشاهده قیمت'), findsOneWidget);
  });
}
