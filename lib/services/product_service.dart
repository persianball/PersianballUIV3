// core/services/ProductService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constant/urls.dart';
import '../models/ProductModel.dart';

class ProductService {
  static const String baseUrl = URLs.baseUrl; // تغییر بده

  static Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(baseUrl+"/v2/product/product"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'];
        return results.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('خطا در بارگذاری محصولات');
      }
    } catch (e) {
      throw Exception('عدم دسترسی به سرور');
    }
  }
}