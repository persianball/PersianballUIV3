// core/services/ProductService.dart
import 'package:persian_ball/core/timed_cache.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constant/urls.dart';
import '../models/ProductModel.dart';

class ProductService {
  static const String baseUrl = URLs.baseUrl; // تغییر بده

  static Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(baseUrl+"/v2/product/product/"));

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

  static final TimedCache<int, ProductDetail> _detailCache = TimedCache();

  static ProductDetail? cachedProductDetail(int productId) =>
      _detailCache.peek(productId);

  static Future<ProductDetail> fetchProductDetail(int productId,
          {bool refresh = false}) =>
      _detailCache.get(productId, () => _loadProductDetail(productId),
          refresh: refresh);

  static Future<ProductDetail> _loadProductDetail(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('${URLs.baseUrl}/v2/product/product/${productId}/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return  ProductDetail.fromJson(data);
      } else {
        throw Exception('خطا در بارگذاری محصولات');
      }
    } catch (e) {
      throw Exception('عدم دسترسی به سرور');
    }
  }
}
