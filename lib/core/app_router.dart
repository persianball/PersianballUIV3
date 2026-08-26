// lib/core/app_router.dart
import 'package:flutter/material.dart';
import 'package:marketky/views/screens/welcome_page.dart';
import 'package:marketky/views/screens/page_switcher.dart';
import 'package:marketky/views/screens/login_page.dart';
import 'package:marketky/views/screens/product_detail.dart';
import 'package:marketky/views/screens/cart_page.dart';
import 'package:marketky/views/screens/splash_router.dart';
import 'package:marketky/views/screens/orders_page.dart';
import 'package:marketky/views/screens/addresses_page.dart';
import 'package:marketky/views/screens/notification_page.dart';
import 'package:marketky/views/screens/account_security_page.dart';
import 'package:marketky/views/screens/forgot_password_page.dart';
import 'package:marketky/views/screens/static_pages.dart';
import 'package:marketky/views/screens/compare_page.dart';
import 'package:marketky/views/screens/catalog_page.dart';
import 'package:marketky/views/screens/course_detail_page.dart';
import 'package:marketky/views/screens/my_course_detail_page.dart';
import 'package:marketky/models/course_models.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '/';

    if (name == '/') {
      return MaterialPageRoute(
        builder: (_) => const SplashRouter(),
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
      case '/welcome':
        return MaterialPageRoute(builder: (_) => WelcomePage(), settings: settings);
      case '/home':
        return MaterialPageRoute(builder: (_) => PageSwitcher(), settings: settings);
      case '/login':
        final args = settings.arguments;
        bool popOnSuccess = false;
        if (args is Map) {
          popOnSuccess = (args['popOnSuccess'] == true);
        }
        return MaterialPageRoute(
          builder: (_) => LoginPage(popOnSuccess: popOnSuccess),
          settings: settings,
        );
      case '/cart':
        return MaterialPageRoute(builder: (_) => CartPage(), settings: settings);
      case '/orders':
        return MaterialPageRoute(builder: (_) => const OrdersPage(), settings: settings);
      case '/compare':
        return MaterialPageRoute(builder: (_) => const ComparePage(), settings: settings);
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
        if (myCourse == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(body: Center(child: Text('اطلاعات دوره کاربر یافت نشد'))),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => MyCourseDetailPage(myCourse: myCourse!),
          settings: RouteSettings(name: name, arguments: args),
        );
      default:
        // Fallback to home
        return MaterialPageRoute(builder: (_) => PageSwitcher(), settings: settings);
    }
  }
}