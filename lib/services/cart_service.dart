// services/CartService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/product_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketky/models/CartModel.dart';
import '../constant/urls.dart';
import '../models/ProductModel.dart';

class CartService {


  // دریافت سبد خرید
  static Future<Cart> fetchCart() async {
    final token = await _getToken();
    print(token);
    final response = await http.get(
      Uri.parse(URLs.baseUrl+"/v1/order/basket-items/"),
      headers: {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try{
      var cartFromBackend = CartFromBackend.fromJson(jsonDecode(response.body));
      List<CartItem> items = [];
      for (var res in cartFromBackend.results) {
        print(res);
        if (res.product != null) {
          ProductDetail product = await ProductService.fetchProductDetail(res.product ?? -1);
          print(product);

          items.add(
            CartItem(
              id: res.id,
              productId: res.product ?? -1,
              name: product.nameFarsi ?? "",
              image: product.image ?? "",
              price: product.price!,
              quantity: res.quantity,
              discountPrice: product.discountPercentage
            ),
          );
        } else {
          // فقط در صورتی که product null باشد، خطا پرتاب کنید — نه همیشه!
          throw Exception("نتیجه مطلوب نمی باشد.");
        }
      }
      //product

        return new Cart(items: items
          ,
        totalPrice: 0,itemCount: 0);
      }catch(e){

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
  static Future<void> addToCart(int productId, int quantity) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(URLs.baseUrl+"/v1/order/basket-items/"),
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

  // حذف آیتم
  static Future<void> removeItem(int itemId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('${URLs.baseUrl+"/v1/order/basket-items"}/$itemId/'),
      headers: {'Authorization': 'token $token'},
    );

    if (response.statusCode != 204) {
      throw Exception('حذف ناموفق');
    }
  }

  // به‌روزرسانی تعداد
  static Future<void> updateQuantity(int itemId,int productId, int quantity) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('${URLs.baseUrl+"/v1/order/basket-items"}/$itemId/'),
      headers: {
        'Authorization': 'token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'quantity': quantity,'product':productId}),
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