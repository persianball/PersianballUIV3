// دکمه‌های «ورود به حساب» (صفحه‌ی دوره‌های من، auth_guard و…) با
// pushNamed<bool> صفحه‌ی ورود را باز می‌کنند و منتظر نتیجه می‌مانند.
// اگر روتِ /login بدون نوع ساخته شود، Navigator موقع push کست ناموفق
// انجام می‌دهد و دکمه بی‌صدا از کار می‌افتد. این تست همان را می‌گیرد.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/core/app_router.dart';

void main() {
  test('روت /login نتیجه‌ی bool برمی‌گرداند', () {
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: '/login', arguments: {'popOnSuccess': true}),
    );
    expect(route, isA<Route<bool?>>(),
        reason: 'pushNamed<bool> بدون این، TypeError می‌دهد');
  });
}
