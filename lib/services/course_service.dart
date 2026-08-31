// lib/services/course_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/course_models.dart';
import 'package:marketky/models/course_detail_model.dart';
import 'package:flutter/widgets.dart';
import 'package:marketky/services/auth_service.dart';

/// نکته‌ی مهم: سرور پاسخ‌ها را با `Content-Type: application/json` و
/// **بدون charset** برمی‌گرداند. در این حالت پکیجِ http مقدار `res.body` را
/// با latin-1 دیکد می‌کند و همه‌ی متن‌های فارسی (عنوان و توضیح دوره) خراب
/// می‌شوند؛ برای همین همه‌جا از `utf8.decode(res.bodyBytes)` استفاده می‌شود.
class CourseService {
  /// دسته‌ی «دوره» در بک‌اند. بدون این فیلتر، آیتم‌هایی مثل کلاس حضوری و
  /// پشتیبانی هم داخل لیست دوره‌ها می‌آیند.
  static const int courseCategory = 1;

  static Future<CoursesResponse> fetchCourses({String? nextPageUrl}) async {
    // لینکِ صفحه‌ی بعدی خودش پارامتر category را همراه دارد.
    final uri = nextPageUrl != null && nextPageUrl.isNotEmpty
        ? Uri.parse(nextPageUrl)
        : Uri.parse(
            '${URLs.baseUrl}v2/product/course/?category=$courseCategory');

    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return CoursesResponse.fromJson(data);
    }
    throw Exception('خطا در دریافت لیست دوره‌ها (${res.statusCode})');
  }

  static Future<CourseDetailResponse> fetchCourseDetail({required int id}) async {
    final uri = Uri.parse('${URLs.baseUrl}v2/product/course/$id/');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return CourseDetailResponse.fromJson(data);
    }
    throw Exception('خطا در دریافت جزییات دوره (${res.statusCode})');
  }

  static Future<MyCoursesResponse> fetchUserCourses(BuildContext context) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('توکن ورود یافت نشد');
    final uri = Uri.parse('${URLs.baseUrl}v1/course/user-course/');
    final res = await http.get(uri, headers: {
      'Authorization': 'token $token',
      'Accept': 'application/json',
    });
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return MyCoursesResponse.fromJson(data);
    }
    throw Exception('خطا در دریافت لیست دوره‌های کاربر (${res.statusCode})');
  }
}