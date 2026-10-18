import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/bloc/cart/cart_bloc.dart';
import 'package:persian_ball/models/CartModel.dart';
import 'package:persian_ball/utils/ThousandsFormatter.dart';
import 'package:persian_ball/views/screens/cart_page.dart';
import 'package:persian_ball/views/screens/order_summary_page.dart';

class _FakeCartBloc extends Bloc<CartEvent, CartState> implements CartBloc {
  _FakeCartBloc(AllCartFromBackend cart) : super(CartLoaded(cart)) {
    on<CartEvent>((e, emit) => emit(CartLoaded(cart)));
  }
}

AllCartFromBackend _fixture() => AllCartFromBackend.fromJson(
    jsonDecode(File('test/fixtures/cart_sample.json').readAsStringSync()));

Future<void> _pump(WidgetTester t, Size size) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(BlocProvider<CartBloc>(
    create: (_) => _FakeCartBloc(_fixture()),
    child: MaterialApp(home: CartPage()),
  ));
  await t.pump();
  await t.pump(const Duration(milliseconds: 600));
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Estedad');
    for (final f in ['Estedad-FD-ExtraLight', 'Estedad-FD-Regular', 'Estedad-FD-SemiBold', 'Estedad-FD-Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Estedad/$f.ttf'));
    }
    await loader.load();
  });

  testWidgets('موبایل: آیتم از فیلدهای API، بدونِ خطای اعشار، با سایز؛ شیت بدونِ سرریز', (t) async {
    await _pump(t, const Size(390, 844));
    // ۱۰٬۰۰۰ با ۹۰٪ تخفیف = ۱٬۰۰۰ (نسخه‌ی قبلی ۹۹۹ نشان می‌داد)
    expect(find.text('${thousandSeparator(1000)} تومان'), findsOneWidget);
    expect(find.text(thousandSeparator(10000)), findsOneWidget);
    expect(find.text('سایز 38'), findsOneWidget);
    expect(find.text('٪90'), findsOneWidget);
    expect(find.text('کفش تروپیک فیل'), findsOneWidget);

    await t.tap(find.byType(ElevatedButton).last);
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    // جمع‌ها عیناً از price ِ API
    expect(find.text('${thousandSeparator(10000)} تومان'), findsOneWidget);
    expect(find.text('${thousandSeparator(9000)} تومان'), findsOneWidget);
    expect(find.text('${thousandSeparator(1000)} تومان'), findsWidgets);
    expect(find.text('رایگان'), findsOneWidget);
  });

  testWidgets('دسکتاپ: همان مقادیر', (t) async {
    await _pump(t, const Size(1280, 800));
    expect(find.text('${thousandSeparator(1000)} تومان'), findsWidgets);
    expect(find.text('سایز 38'), findsOneWidget);
  });

  testWidgets('خلاصه‌ی سفارش: ردیف‌ها عیناً از price ِ API، بدونِ کد', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: OrderSummaryPage(cart: _fixture(), deliveryMethod: 'free'),
    ));
    await t.pump();
    expect(find.text('قیمت کل'), findsOneWidget);
    expect(find.text('تخفیف محصولات'), findsOneWidget);
    expect(find.text('${thousandSeparator(9000)}- تومان'), findsOneWidget);
    expect(find.text('${thousandSeparator(1000)} تومان'), findsWidgets);
    expect(find.text('رنگ مشکی، سایز 38'), findsOneWidget);
    expect(find.text('حذف کد'), findsNothing);
    expect(find.text('رفتن به درگاه پرداخت'), findsOneWidget);
  });
}
