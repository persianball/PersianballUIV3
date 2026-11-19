// سقفِ تعداد بر اساسِ موجودیِ انبار: در شیتِ «افزودن به سبد» و در محاسبه‌ی
// باقی‌مانده با حسابِ آنچه از قبل در سبد است.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/bloc/cart/cart_bloc.dart';
import 'package:persian_ball/models/CartModel.dart';
import 'package:persian_ball/utils/stock_limit.dart';
import 'package:persian_ball/views/widgets/modals/add_to_cart_modal.dart';

CartState _cartWith(List<(int sizeId, int qty)> lines) => CartLoaded(
      AllCartFromBackend.fromJson({
        'count': 1,
        'results': [
          {
            'user': 1,
            'price': <String, dynamic>{},
            'items': [
              for (int i = 0; i < lines.length; i++)
                {
                  'id': 100 + i,
                  'quantity': lines[i].$2,
                  'product': {
                    'id': lines[i].$1,
                    'size': '42',
                    'count': 5,
                    'price': 1000,
                  },
                },
            ],
          },
        ],
      }),
    );

void main() {
  test('تعدادِ همان سایز در سبد جمع زده می‌شود', () {
    final state = _cartWith([(7, 2), (9, 1), (7, 1)]);
    expect(quantityInCart(state, 7), 3);
    expect(quantityInCart(state, 9), 1);
    expect(quantityInCart(state, 8), 0);
    expect(quantityInCart(CartInitial(), 7), 0);
  });

  test('باقی‌مانده = موجودی منهای سبد، هیچ‌وقت منفی نمی‌شود', () {
    expect(remainingStock(stock: 5, inCart: 0), 5);
    expect(remainingStock(stock: 5, inCart: 3), 2);
    expect(remainingStock(stock: 5, inCart: 5), 0);
    expect(remainingStock(stock: 5, inCart: 9), 0);
    expect(remainingStock(stock: null, inCart: 3), isNull);
  });

  Future<void> pumpSheet(WidgetTester tester, {int? max}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BlocProvider(
      create: (_) => CartBloc(),
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: AddToCartModal(
                maxQuantity: max,
                cartItem: CartItem(
                  id: 7,
                  productId: 1,
                  name: 'کفش',
                  image: '',
                  price: 1000,
                  quantity: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Finder qty(int n) => find.text('$n');

  testWidgets('دکمه‌ی + بعد از رسیدن به موجودی از کار می‌افتد', (tester) async {
    await pumpSheet(tester, max: 2);
    final plus = find.byIcon(Icons.add_rounded);
    expect(find.byKey(const ValueKey('stock-limit-hint')), findsNothing);

    await tester.tap(plus);
    await tester.pump();
    expect(qty(2), findsWidgets);
    expect(find.byKey(const ValueKey('stock-limit-hint')), findsOneWidget);

    await tester.tap(plus, warnIfMissed: false);
    await tester.pump();
    expect(qty(3), findsNothing);
  });

  testWidgets('بدونِ سقف، تعداد آزادانه بالا می‌رود', (tester) async {
    await pumpSheet(tester);
    final plus = find.byIcon(Icons.add_rounded);
    for (int i = 0; i < 4; i++) {
      await tester.tap(plus);
      await tester.pump();
    }
    expect(qty(5), findsWidgets);
    expect(find.byKey(const ValueKey('stock-limit-hint')), findsNothing);
  });
}
