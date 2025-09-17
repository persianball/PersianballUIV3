// lib/services/course_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:marketky/constant/urls.dart';
import 'package:marketky/models/course_models.dart';
import 'package:marketky/models/course_detail_model.dart';

class CourseService {
  static Future<CoursesResponse> fetchCourses({String? nextPageUrl}) async {
    final uri = nextPageUrl != null && nextPageUrl.isNotEmpty
        ? Uri.parse(nextPageUrl)
        : Uri.parse('${URLs.baseUrl}/v2/product/course/');

    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return CoursesResponse.fromJson(data);
    }
    throw Exception('خطا در دریافت لیست دوره‌ها (${res.statusCode})');
  }

  static Future<CourseDetailResponse> fetchCourseDetail({required int id}) async {
    final uri = Uri.parse('${URLs.baseUrl}/v2/product/course/$id');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return CourseDetailResponse.fromJson(data);
    }
    throw Exception('خطا در دریافت جزییات دوره (${res.statusCode})');
  }
}