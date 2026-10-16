// lib/core/app_router.dart
import 'package:flutter/material.dart';
import 'package:persian_ball/views/screens/page_switcher.dart';
import 'package:persian_ball/views/screens/login_page.dart';
import 'package:persian_ball/views/screens/product_detail.dart';
import 'package:persian_ball/views/screens/cart_page.dart';
import 'package:persian_ball/views/screens/orders_page.dart';
import 'package:persian_ball/views/screens/order_detail_page.dart';
import 'package:persian_ball/views/screens/addresses_page.dart';
import 'package:persian_ball/views/screens/notification_page.dart';
import 'package:persian_ball/views/screens/account_security_page.dart';
import 'package:persian_ball/views/screens/forgot_password_page.dart';
import 'package:persian_ball/views/screens/static_pages.dart';
import 'package:persian_ball/views/screens/catalog_page.dart';
import 'package:persian_ball/views/screens/course_detail_page.dart';
import 'package:persian_ball/views/screens/my_course_detail_page.dart';
import 'package:persian_ball/views/screens/my_course_loader_page.dart';
import 'package:persian_ball/models/course_models.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '/';

    if (name == '/') {
      return MaterialPageRoute(
        builder: (_) => PageSwitcher(),
        settings: settings,
      );
    }

    // Dynamic: /product/{id}
    final productMatch = RegExp(r'^/product/(\d+)$').firstMatch(name);
    if (productMatch != null) {
      final id = int.parse(productMatch.group(1)!);
      return MaterialPageRoute(
        builder: (_) => ProductDetailPage(productId: id),
        settings: settings,
      );
    }

    // Dynamic: /order/{id} — لینک مستقیم به جزئیات سفارش. بدون این،
    // صفحه‌ی جزئیات فقط با push از لیست باز می‌شد.
    final orderMatch = RegExp(r'^/order/(\d+)$').firstMatch(name);
    if (orderMatch != null) {
      final id = int.parse(orderMatch.group(1)!);
      return MaterialPageRoute(
        builder: (_) => OrderDetailPage(orderId: id),
        settings: settings,
      );
    }

    // Dynamic: /my-course/{id} — دوره‌ی خریداری‌شده با آدرسِ قابلِ کپی.
    // از فهرست با خودِ آبجکت می‌آید (سریع)؛ با رفرش/لینک فقط شناسه هست و
    // لودر بعد از اطمینان از ورود، دوره را از فهرستِ کاربر پیدا می‌کند.
    final myCourseMatch = RegExp(r'^/my-course/(\d+)$').firstMatch(name);
    if (myCourseMatch != null) {
      final id = int.parse(myCourseMatch.group(1)!);
      final args = settings.arguments;
      if (args is MyCourse && args.courseId == id) {
        return MaterialPageRoute(
          builder: (_) => MyCourseDetailPage(myCourse: args),
          settings: settings,
        );
      }
      return MaterialPageRoute(
        builder: (_) => MyCourseLoaderPage(courseId: id),
        settings: settings,
      );
    }

    // Dynamic: /course/{id}
    final courseMatch = RegExp(r'^/course/(\d+)$').firstMatch(name);
    if (courseMatch != null) {
      final id = int.parse(courseMatch.group(1)!);
      return MaterialPageRoute(
        builder: (_) => CourseDetailPage(id: id),
        settings: settings,
      );
    }

    switch (name) {
      case '/home':
        return MaterialPageRoute(builder: (_) => PageSwitcher(), settings: settings);
      case '/login':
        final args = settings.arguments;
        bool popOnSuccess = false;
        if (args is Map) {
          popOnSuccess = (args['popOnSuccess'] == true);
        }
        // نوعِ صریح <bool> لازم است: صفحه‌ی ورود با pop(true) نتیجه برمی‌گرداند
        // و فراخوان‌ها با pushNamed<bool> صدایش می‌زنند. بدون این، Navigator
        // موقعِ push یک MaterialPageRoute<dynamic> را به Route<bool?> کست
        // می‌کند و TypeError می‌دهد؛ یعنی دکمه‌ی «ورود به حساب» بی‌صدا از کار
        // می‌افتاد.
        return MaterialPageRoute<bool>(
          builder: (_) => LoginPage(popOnSuccess: popOnSuccess),
          settings: settings,
        );
      case '/cart':
        return MaterialPageRoute(builder: (_) => CartPage(), settings: settings);
      case '/orders':
        return MaterialPageRoute(builder: (_) => const OrdersPage(), settings: settings);
      case '/catalog':
        return MaterialPageRoute(builder: (_) => const CatalogPage(), settings: settings);
      case '/account-security':
        return MaterialPageRoute(builder: (_) => const AccountSecurityPage(), settings: settings);
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage(), settings: settings);
      case '/terms':
        return MaterialPageRoute(
            builder: (_) => const StaticContentPage(content: StaticContent.terms),
            settings: settings);
      case '/privacy':
        return MaterialPageRoute(
            builder: (_) => const StaticContentPage(content: StaticContent.privacy),
            settings: settings);
      case '/about':
        return MaterialPageRoute(
            builder: (_) => const StaticContentPage(content: StaticContent.about),
            settings: settings);
      case '/support':
        return MaterialPageRoute(builder: (_) => const SupportPage(), settings: settings);
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationPage(), settings: settings);
      case '/addresses':
        return MaterialPageRoute(builder: (_) => const AddressesPage(), settings: settings);
      case '/user-course-detail':
        final args = settings.arguments;
        MyCourse? myCourse;
        if (args is MyCourse) {
          myCourse = args;
        } else if (args is Map) {
          final c = args['course'] ?? args['myCourse'] ?? args['data'];
          if (c is MyCourse) myCourse = c;
        }
        // مسیرِ قدیمی بدونِ شناسه: با رفرشِ وب چیزی برای بازسازی نداشت.
        // اگر آبجکت همراه باشد همان صفحه با آدرسِ شناسه‌دار باز می‌شود تا
        // آدرسِ نوارِ مرورگر قابلِ کپی باشد؛ وگرنه کاربر به دوره‌هایش برمی‌گردد.
        if (myCourse == null) {
          return MaterialPageRoute(
            builder: (_) => PageSwitcher(),
            settings: const RouteSettings(name: '/home'),
          );
        }
        return MaterialPageRoute(
          builder: (_) => MyCourseDetailPage(myCourse: myCourse!),
          settings: RouteSettings(
              name: '/my-course/${myCourse.courseId}', arguments: myCourse),
        );
      default:
        // Fallback to home
        return MaterialPageRoute(builder: (_) => PageSwitcher(), settings: settings);
    }
  }
}