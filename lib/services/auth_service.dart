// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:marketky/constant/urls.dart';
class AuthService {


  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${URLs.baseUrl}/v1/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': jsonDecode(response.body),
      };
    } else {
      final body = jsonDecode(response.body);
      return {
        'success': false,
        'message': body['message'] ?? 'ورود ناموفق بود',
      };
    }
  }
}