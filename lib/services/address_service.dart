// lib/services/address_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/address_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<String?> _requireToken(BuildContext context) async {
    final token = await _getToken();
    if (token != null && token.isNotEmpty) return token;

    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('نیاز به ورود دارید'),
          content: const Text('برای مدیریت آدرس‌ها باید وارد شوید.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamed(
                  '/login',
                  arguments: {'popOnSuccess': true},
                );
              },
              child: const Text('ورود'),
            ),
          ],
        ),
      ),
    );

    return null;
  }

  static String get _base => '${URLs.baseUrl}/v1/order/address';

  static Future<List<AddressModel>> list(BuildContext context) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await _requireToken(context);
      throw Exception('نیاز به ورود');
    }
    final res = await http.get(Uri.parse(_base + '/'), headers: {
      'Authorization': 'token $token',
      'Content-Type': 'application/json',
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data.map((e) => AddressModel.fromJson(e)).toList();
      } else if (data is Map && data['results'] is List) {
        return (data['results'] as List).map((e) => AddressModel.fromJson(e)).toList();
      }
      return [];
    }
    throw Exception('خطا در دریافت آدرس‌ها');
  }

  static Future<AddressModel> create(BuildContext context, AddressModel model) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await _requireToken(context);
      throw Exception('نیاز به ورود');
    }
    final res = await http.post(Uri.parse(_base + '/'),
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(model.toJson()));
    if (res.statusCode == 201 || res.statusCode == 200) {
      return AddressModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('ایجاد آدرس ناموفق بود');
  }

  static Future<AddressModel> update(BuildContext context, int id, AddressModel model) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await _requireToken(context);
      throw Exception('نیاز به ورود');
    }
    final res = await http.put(Uri.parse('$_base/$id/'),
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(model.toJson()));
    if (res.statusCode == 200) {
      return AddressModel.fromJson(jsonDecode(res.body));
    }
    throw Exception('ویرایش آدرس ناموفق بود');
  }

  static Future<void> remove(BuildContext context, int id) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await _requireToken(context);
      throw Exception('نیاز به ورود');
    }
    final res = await http.delete(Uri.parse('$_base/$id/'), headers: {
      'Authorization': 'token $token',
    });
    if (res.statusCode != 204) {
      throw Exception('حذف آدرس ناموفق بود');
    }
  }
}