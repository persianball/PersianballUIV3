import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_ball/core/app_router.dart';
import 'package:persian_ball/core/deep_link_resolver.dart';
import 'package:persian_ball/views/screens/my_course_loader_page.dart';
import 'package:persian_ball/views/screens/page_switcher.dart';

Widget _build(String name, [Object? args]) {
  final route = AppRouter.onGenerateRoute(RouteSettings(name: name, arguments: args))
      as MaterialPageRoute;
  return route.builder(_FakeContext());
}

class _FakeContext extends Fake implements BuildContext {}

void main() {
  test('/my-course/<id> بدونِ آبجکت → لودر با همان شناسه (رفرشِ وب)', () {
    final w = _build('/my-course/20');
    expect(w, isA<MyCourseLoaderPage>());
    expect((w as MyCourseLoaderPage).courseId, 20);
  });

  test('مسیرِ قدیمیِ بی‌شناسه دیگر صفحه‌ی خطا نیست؛ به خانه می‌رود', () {
    final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: '/user-course-detail')) as MaterialPageRoute;
    expect(route.settings.name, '/home');
    expect(route.builder(_FakeContext()), isA<PageSwitcher>());
  });

  test('لینکِ وب و اسکیمِ اپ برای /my-course/<id> معتبرند', () {
    expect(DeepLinkResolver.resolve(Uri.parse('persianball://my-course/20')),
        '/my-course/20');
    expect(
        DeepLinkResolver.resolve(
            Uri.parse('https://pball.ah8ad3.ir/my-course/20/')),
        '/my-course/20');
    expect(DeepLinkResolver.resolve(Uri.parse('persianball://my-course/x')),
        isNull);
  });
}
