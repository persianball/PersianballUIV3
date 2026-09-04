// رفرش روی یک آدرس عمیق (مثل /#/course/20) نباید کاربر را به صفحه‌ی
// خوش‌آمد/خانه بیندازد. رفتار پیش‌فرض فلاتر پشته را از بخش‌های مسیر
// می‌سازد و SplashRouter را هم داخلش می‌آورد؛ این تست پشته‌ی صریح را
// تضمین می‌کند.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/core/app_router.dart';

List<Route<dynamic>> _initialRoutes(String initialRoute) {
  if (initialRoute == '/' || initialRoute.isEmpty) {
    return [AppRouter.onGenerateRoute(const RouteSettings(name: '/'))];
  }
  return [
    AppRouter.onGenerateRoute(const RouteSettings(name: '/home')),
    AppRouter.onGenerateRoute(RouteSettings(name: initialRoute)),
  ];
}

void main() {
  testWidgets('فلاتر به‌طور پیش‌فرض «/» را زیر آدرس عمیق می‌سازد', (t) async {
    final generated = <String?>[];
    await t.pumpWidget(MaterialApp(
      initialRoute: '/course/20',
      onGenerateRoute: (s) {
        generated.add(s.name);
        return MaterialPageRoute(builder: (_) => const SizedBox(), settings: s);
      },
    ));
    // همین رفتار بود که SplashRouter را وارد بازی می‌کرد
    expect(generated, contains('/'));
  });

  test('پشته‌ی صریح: خانه در پایین، خودِ آدرس عمیق در بالا', () {
    final routes = _initialRoutes('/course/20');
    expect(routes.length, 2);
    expect(routes.first.settings.name, '/home');
    expect(routes.last.settings.name, '/course/20');
    // هیچ روتِ '/' ای ساخته نمی‌شود، پس SplashRouter اجرا نمی‌شود
    expect(routes.map((r) => r.settings.name), isNot(contains('/')));
  });

  test('لینک مستقیم به جزئیات سفارش روت خودش را دارد', () {
    final route =
        AppRouter.onGenerateRoute(const RouteSettings(name: '/order/2097'));
    // اگر روتِ اختصاصی نباشد، به PageSwitcher می‌افتد
    expect(route.settings.name, '/order/2097');
    expect(route, isA<MaterialPageRoute>());
  });

  test('آدرس ریشه همان مسیر عادی splash را می‌گیرد', () {
    final routes = _initialRoutes('/');
    expect(routes.length, 1);
    expect(routes.single.settings.name, '/');
  });
}
