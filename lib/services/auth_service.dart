// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:marketky/constant/urls.dart';
import 'package:shared_preferences/shared_preferences.dart';
class AuthService {


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
      return {
        'success': true,
        'data': jsonDecode(response.body),
      };
    } else {
      final body = jsonDecode(response.body);
      print(response.body);
      return {
        'success': false,
        'message': body['message'] ?? 'ورود ناموفق بود',
      };
    }

  }

  // ذخیره توکن‌ها
  static Future<void> saveTokens(String token, [String? refreshToken]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
  }

  // گرفتن توکن از حافظه
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // بررسی وضعیت ورود
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
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
          'message': data['message'] ?? 'ثبت‌نام ناموفق بود',
        };
      }

    } else {
      final body = jsonDecode(response.body);
      return {
        'success': false,
        'message': body['message'] ?? 'ثبت‌نام ناموفق بود',
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
        'message': body['message'] ?? 'ثبت‌نام ناموفق بود',
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
        final token = data['token'];
        final refresh = data['refresh'];
        if (token != null) {
          await saveTokens(token, refresh);
          return {'success': true, 'token': token, 'refresh': refresh};
        }else{
          return {
            'success': false,
            'message': data['message'] ?? 'ثبت‌نام ناموفق بود',
          };
        }
      } else {
        print(response.statusCode);
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'ثبت‌نام ناموفق بود',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'عدم دسترسی به سرور. اینترنت خود را بررسی کنید.',
      };
    }
  }
}