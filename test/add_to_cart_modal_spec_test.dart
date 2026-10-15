import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/models/CartModel.dart';
import 'package:persian_ball/views/widgets/modals/add_to_cart_modal.dart';

CartItem _item({String? size, String? color}) => CartItem(
      id: 29,
      productId: 9,
      name: 'کفش تروپیک فیل',
      image: '',
      price: 4200000,
      quantity: 1,
      discountPrice: 20,
      size: size,
      colorName: color,
      colorRgb: 'FFFAFA',
    );

Future<void> _pump(WidgetTester t, CartItem item) async {
  t.view.physicalSize = const Size(430, 1000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    home: Scaffold(body: AddToCartModal(cartItem: item)),
  ));
  await t.pump();
}

void main() {
  testWidgets('سایز و رنگِ انتخاب‌شده در شیت دیده می‌شود', (t) async {
    await _pump(t, _item(size: '41', color: 'سفید'));
    expect(find.text('41'), findsOneWidget);
    expect(find.text('سفید'), findsOneWidget);
    expect(find.text('سایز: '), findsOneWidget);
    expect(find.text('رنگ: '), findsOneWidget);
  });

  testWidgets('محصولِ بی‌سایز: فقط تعداد', (t) async {
    await _pump(t, _item());
    expect(find.text('سایز: '), findsNothing);
    expect(find.text('رنگ: '), findsNothing);
    expect(find.text('تعداد: '), findsOneWidget);
  });
}
