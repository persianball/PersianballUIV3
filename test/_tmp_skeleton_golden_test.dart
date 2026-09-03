import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketky/views/widgets/shimmer.dart';
import 'package:marketky/bloc/cart/cart_bloc.dart';
import 'package:marketky/bloc/product_detail/product_detail_bloc.dart';
import 'package:marketky/views/screens/course_detail_page.dart';
import 'package:marketky/views/screens/product_detail.dart';

Widget _wrap(Widget child) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ProductDetailBloc()),
        BlocProvider(create: (_) => ProductDetailVariantBloc()),
        BlocProvider(create: (_) => CartBloc()),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('product mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(const ProductDetailPage(productId: 1)));
    expect(find.byType(Shimmer), findsOneWidget);
    await expectLater(find.byType(ProductDetailPage),
        matchesGoldenFile('shots/product_mobile.png'));
  });

  testWidgets('product desktop', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(const ProductDetailPage(productId: 1)));
    expect(find.byType(Shimmer), findsOneWidget);
    await expectLater(find.byType(ProductDetailPage),
        matchesGoldenFile('shots/product_desktop.png'));
  });

  testWidgets('course mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(const CourseDetailPage(id: 1)));
    expect(find.byType(Shimmer), findsOneWidget);
    await expectLater(find.byType(CourseDetailPage),
        matchesGoldenFile('shots/course_mobile.png'));
  });

  testWidgets('course desktop', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(const CourseDetailPage(id: 1)));
    expect(find.byType(Shimmer), findsOneWidget);
    await expectLater(find.byType(CourseDetailPage),
        matchesGoldenFile('shots/course_desktop.png'));
  });
}
