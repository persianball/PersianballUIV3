// services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marketky/constant/urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
class AuthService {

  /// خطاهای Django REST Framework معمولاً به شکل {"message": "..."} نیستند؛
  /// به شکل {"field_name": ["پیام خطا"]} یا {"non_field_errors": [...]} یا
  /// {"detail": "..."} برمی‌گردند. این متد همه‌ی این حالت‌ها را پوشش می‌دهد
  /// تا خطای واقعی بک‌اند به کاربر نمایش داده شود، نه یک پیام عمومی.
  static String _extractErrorMessage(dynamic decoded, String fallback) {
    if (decoded is String) return decoded;
    if (decoded is! Map) return fallback;
    if (decoded['message'] is String) return decoded['message'];
    if (decoded['detail'] is String) return decoded['detail'];

    final messages = <String>[];
    decoded.forEach((key, value) {
      if (value is List) {
        messages.addAll(value.map((e) => e.toString()));
      } else if (value is String) {
        messages.add(value);
      }
    });
    if (messages.isNotEmpty) return messages.join('\n');
    return fallback;
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${URLs.baseUrl}/v1/user/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    print(jsonEncode({
      'username': username,
      'password': password,
    }));


    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      if(token!=null){
        saveTokens(token);
      }else{
        print("Token is null ?????");
      }
      return {
        'success': true,
        'data': jsonDecode(response.body),
      };
    } else {
      final body = jsonDecode(response.body);
      print(response.body);
      return {
        'success': false,
        'message': _extractErrorMessage(body, 'ورود ناموفق بود'),
      };
    }

  }

  // ذخیره توکن‌ها
  static Future<void> saveTokens(String token, [String? refreshToken,bool? isCoach]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
    if(isCoach !=null){
      await prefs.setBool("is_coach", isCoach);
    }
  }

  // گرفتن توکن از حافظه
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Returns token if exists; otherwise shows a login dialog using provided context,
  // navigates to login, and returns null.
  static Future<String?> requireToken(BuildContext context) async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) return token;

    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('نیاز به ورود دارید'),
          content: const Text('برای ادامه، لطفاً ابتدا وارد حساب کاربری خود شوید.'),
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

  // بررسی وضعیت ورود
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    // توکن خالی هم یعنی وارد نشده
    return token != null && token.isNotEmpty;
  }

  // حذف توکن (Logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  // ثبت‌نام با ایمیل
  static Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${URLs.baseUrl}/v1/user/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      if (token != null) {
        await saveTokens(token);
        return {'success': true, 'token': token,'data': jsonDecode(response.body)};
      }else{
        return {
          'success': false,
          'message': _extractErrorMessage(data, 'ثبت‌نام ناموفق بود'),
        };
      }

    } else {
      final body = jsonDecode(response.body);
      return {
        'success': false,
        'message': _extractErrorMessage(body, 'ثبت‌نام ناموفق بود'),
      };
    }
  }

  // ثبت‌نام با شماره موبایل
  static Future<Map<String, dynamic>> registerWithMobile({
    required String mobileNumber,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${URLs.baseUrl}/v1/user/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile_number': mobileNumber,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return {
        'success': true,
        'data': jsonDecode(response.body),
      };
    } else {

      final body = jsonDecode(response.body);
      return {
        'success': false,
        'message': _extractErrorMessage(body, 'ثبت‌نام ناموفق بود'),
      };
    }
  }
  static Future<Map<String, dynamic>> register({
    String? email,
    String? mobileNumber,
    required String username,
    required String password,
    String? inviteKey,
  }) async {
    final body = {
      if (email != null) 'email': email,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
      'username': username,
      'password': password,
      if (inviteKey != null && inviteKey.isNotEmpty) 'invite_key': inviteKey,
    };
    print("${URLs.baseUrl}/v1/user/register/");
    try {
      final response = await http.post(
        Uri.parse("${URLs.baseUrl}/v1/user/register/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      print(body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // final token = data['token'];
        // final refresh = data['refresh'];
        // if (token != null) {
        //   await saveTokens(token, refresh);
        //   return {'success': true, 'token': token, 'refresh': refresh};
        // }else{
          return {
            'success': true,
            'message': data['message'] ?? 'ثبت‌نام ناموفق بود',
            'data':data
          };
        // }
      } else {
        print(response.statusCode);
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': _extractErrorMessage(error, 'ثبت‌نام ناموفق بود'),
        };
      }
    } catch (e) {
      print('Register error: $e');
      return {
        'success': false,
        'message': 'عدم دسترسی به سرور. اینترنت خود را بررسی کنید.',
      };
    }
  }
}