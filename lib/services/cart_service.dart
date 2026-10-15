// services/CartService.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:persian_ball/models/CartModel.dart';
import '../constant/urls.dart';

class CartService {
  // دریافت سبد خرید
  static Future<AllCartFromBackend> fetchCart(BuildContext context) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('نیاز به ورود دارید'),
            content:
                const Text('برای مشاهده سبد خرید ابتدا وارد حساب کاربری شوید.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('انصراف')),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context)
                      .pushNamed('/login', arguments: {'popOnSuccess': true});
                },
                child: const Text('ورود'),
              ),
            ],
          ),
        ),
      );
      throw Exception('نیاز به ورود');
    }
    final response = await http.get(
      Uri.parse(URLs.baseUrl + "/v1/order/basket/"),
      headers: {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        var AllDataAboutCartFromBack =
            AllCartFromBackend.fromJson(jsonDecode(response.body));
        return AllDataAboutCartFromBack;
      } catch (e) {
        print("no product available + ${e.toString()}");
        throw Exception("محصول در سبد مشکلی دارد.");
      }

      //fetch product detail
    } else {
      print("status code : ${response.statusCode}");
      print("error: ${response.body}");
      throw Exception('خطا در بارگذاری سبد خرید');
    }
  }

  // افزودن محصول به سبد
  static Future<void> addToCart(
      BuildContext context, int productId, int quantity) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('نیاز به ورود دارید'),
            content:
                const Text('برای افزودن به سبد ابتدا وارد حساب کاربری شوید.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('انصراف')),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(ctx)
                      .pushNamed('/login', arguments: {'popOnSuccess': true});
                },
                child: const Text('ورود'),
              ),
            ],
          ),
        ),
      );
      throw Exception('نیاز به ورود');
    }
    final response = await http.post(
      Uri.parse(URLs.baseUrl + "/v1/order/basket-items/"),
      headers: {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'product': productId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('افزودن به سبد ناموفق بود');
    }
  }

  // افزودن دوره به سبد
  static Future<void> addCourseToCart(
      BuildContext context, int courseId, int quantity) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('نیاز به ورود دارید'),
            content: const Text(
                'برای افزودن دوره به سبد ابتدا وارد حساب کاربری شوید.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('انصراف')),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(ctx)
                      .pushNamed('/login', arguments: {'popOnSuccess': true});
                },
                child: const Text('ورود'),
              ),
            ],
          ),
        ),
      );
      throw Exception('نیاز به ورود');
    }
    final response = await http.post(
      Uri.parse(URLs.baseUrl + "/v1/order/basket-items/"),
      headers: {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'course': courseId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('افزودن دوره به سبد ناموفق بود');
    }
  }

  // حذف آیتم
  static Future<void> removeItem(BuildContext context, int itemId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('نیاز به ورود دارید'),
            content: const Text('برای حذف آیتم ابتدا وارد حساب کاربری شوید.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('انصراف')),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context)
                      .pushNamed('/login', arguments: {'popOnSuccess': true});
                },
                child: const Text('ورود'),
              ),
            ],
          ),
        ),
      );
      throw Exception('نیاز به ورود');
    }
    final response = await http.delete(
      Uri.parse('${URLs.baseUrl + "/v1/order/basket-items"}/$itemId/'),
      headers: {'Authorization': 'token $token'},
    );

    if (response.statusCode != 204) {
      throw Exception('حذف ناموفق');
    }
  }

  // به‌روزرسانی تعداد
  static Future<void> updateQuantity(BuildContext context, int itemId,
      int? productId, int? courseid, int quantity) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('نیاز به ورود دارید'),
            content: const Text('برای ویرایش سبد ابتدا وارد حساب کاربری شوید.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('انصراف')),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context)
                      .pushNamed('/login', arguments: {'popOnSuccess': true});
                },
                child: const Text('ورود'),
              ),
            ],
          ),
        ),
      );
      throw Exception('نیاز به ورود');
    }
    final response = await http.put(
      Uri.parse('${URLs.baseUrl + "/v1/order/basket-items"}/$itemId/'),
      headers: {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
          {'quantity': quantity, 'product': productId, 'course': courseid}),
    );

    if (response.statusCode != 200) {
      throw Exception('به‌روزرسانی ناموفق');
    }
  }

  // کمکی: گرفتن توکن
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
