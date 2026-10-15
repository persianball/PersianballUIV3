// core/model/Cart.dart
import 'package:persian_ball/models/ProductModel.dart';
import 'package:persian_ball/utils/json_parse.dart';

class CartItem {
  final int id;
  final int productId;
  final String name;
  final String image;
  final int price;
  final int quantity;
  final int? discountPrice;

  /// فقط برای نمایش در شیتِ «افزودن به سبد»: سایز و رنگِ انتخاب‌شده
  final String? size;
  final String? colorName;
  final String? colorRgb;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    this.discountPrice,
    this.size,
    this.colorName,
    this.colorRgb,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: requireInt(json['id'], 'id'),
      productId: requireInt(json['product_id'], 'product_id'),
      name: json['name'],
      image: json['image'],
      price: asInt(json['price']) ?? 0,
      quantity: asInt(json['quantity']) ?? 1,
      discountPrice: asInt(json['discount_price'])
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
    };
  }
}

class Cart {
  final List<CartItem> items;
  final int totalPrice;
  final int itemCount;

  Cart({required this.items, required this.totalPrice, required this.itemCount});

  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List;
    final items = itemsJson.map((item) => CartItem.fromJson(item)).toList();
    return Cart(
      items: items,
      totalPrice: asInt(json['total_price']) ?? 0,
      itemCount: asInt(json['item_count']) ?? items.length,
    );
  }
}


class CartItemFromBackend{
  final ProductInCart? product;
  final int? classes;
  final CourseInCart? course;
  final int? support_coach;
  final int quantity;
  final int id;

  CartItemFromBackend({
    required this.id,required this.quantity,this.product,this.classes,this.support_coach,
    this.course
});


  factory CartItemFromBackend.fromJson(Map<String, dynamic> json) {

    return CartItemFromBackend(
        id: requireInt(json['id'], 'items[].id'),
        quantity: asInt(json['quantity']) ?? 1,
        product: json['product']==null? null:ProductInCart.fromJson(json['product']),
      course: json['course']==null?null:CourseInCart.fromJson(json['course']),
        classes: asInt(json['classes']),
        support_coach: asInt(json['support_coach']),

    );
  }
}

class TotalPriceFromBack{
  final int? price;
  final int? nat;
  final int? discountedPrice;
  final bool? isFreeShipping;
  final int? freeShippingThreshold;
  final int? postShippingPrice;
  final int? peykShippingPrice;
  final int? orderShippingPrice;

  TotalPriceFromBack({
    this.price,
    this.nat,
    this.discountedPrice,
    this.isFreeShipping,
    this.freeShippingThreshold,
    this.postShippingPrice,
    this.peykShippingPrice,
    this.orderShippingPrice
  });


  factory TotalPriceFromBack.fromJson(Map<String, dynamic> json) {

    return TotalPriceFromBack(
        price: asInt(json['price']),
        nat: asInt(json['nat']) ?? 0,
        discountedPrice: asInt(json['discounted_price']) ?? 0,
        isFreeShipping: json['is_free_shipping'],
        freeShippingThreshold: asInt(json['free_shipping_threshold']),
        postShippingPrice: asInt(json['post_shipping_price']),
        peykShippingPrice: asInt(json['peyk_shipping_price']),
        orderShippingPrice: asInt(json['order_shipping_price'])
    );
  }
}

class ProductInCart{
  final ProductVariant? productVariant;
  final String? size;
  final int? count;
  final int? disountPercentage;
  final bool? isActive;
  final int? price;
  final int id;

  ProductInCart({
    required this.productVariant,required this.size,required this.count,required this.disountPercentage,
    required this.isActive,required this.price,required this.id
  });
  factory ProductInCart.fromJson(Map<String, dynamic> json){
    return ProductInCart(
      id: requireInt(json['id'], 'product.id'),
      productVariant: json['product_variant'] == null
          ? null
          : ProductVariant.fromJson(json['product_variant']),
      size: json['size'],
      count: asInt(json['count']),
      disountPercentage: asInt(json['discount_percentage']),
      isActive: json['is_active'],
      price: asInt(json['price']),
    );
  }
}

class CourseInCart{
  final bool? isActive;
  final String? image;
  final int? price;
  final String? location;
  final int? coach;
  final String? courseName;
  ProductVariant? giftProduct;
  final int id;
  final bool? shipmentRequired;
  final int? discountPercentage;
  final int? capacity;
  

  CourseInCart({
    required this.isActive,required this.image,required this.price,required this.location,
    required this.coach,required this.courseName,required this.giftProduct,required this.id,
    required this.shipmentRequired,required this.discountPercentage,required this.capacity
  });
  factory CourseInCart.fromJson(Map<String, dynamic> json){
    return CourseInCart(
        isActive: json['is_active'],
        image: json['image'],
        price: asInt(json['price']),
        location: json['location'],
        coach: asInt(json['coach']),
        courseName: json['course_name'],
        giftProduct:json['gift_product'] != null ? ProductVariant.fromJson(json['gift_product']) : null,
        id:requireInt(json['id'], 'course.id'),
        shipmentRequired:json['shipment_required'],
        discountPercentage:asInt(json['discount_percentage']),
        capacity:asInt(json['capacity'])
    );
  }
}


class CartFromBackend{
  final int? user;
  final TotalPriceFromBack price;
  final List<CartItemFromBackend> items;


  CartFromBackend({this.user,required this.price,required this.items});

  factory CartFromBackend.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List;
    final items = itemsJson.map((item) => CartItemFromBackend.fromJson(item)).toList();
    return CartFromBackend(
        user: asInt(json['user']),
        price:TotalPriceFromBack.fromJson(json['price']) ,
        items: items
    );
  }



}



class AllCartFromBackend{
  final int count;
  final List<CartFromBackend> results;


  AllCartFromBackend({required this.count, required this.results});

  factory AllCartFromBackend.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['results'] as List;
    final items = itemsJson.map((item) => CartFromBackend.fromJson(item)).toList();
    return AllCartFromBackend(
      results: items,
      count: asInt(json['count']) ?? items.length
    );
  }
}

extension CartShipping on AllCartFromBackend {
  /// آیا این سفارش به آدرس پستی نیاز دارد؟
  ///
  /// دوره ارسال فیزیکی ندارد، پس سبدی که فقط دوره دارد نباید کاربر را به
  /// مرحله‌ی «انتخاب آدرس» بفرستد. دو استثنا: دوره‌ای که هدیه‌ی فیزیکی دارد
  /// (`gift_product`) و دوره‌ای که خودِ بک‌اند برایش `shipment_required`
  /// فرستاده — این‌ها باید جایی تحویل داده شوند.
  bool get requiresAddress {
    if (results.isEmpty) return false;
    return results.first.items.any((item) {
      if (item.product != null) return true;
      final course = item.course;
      if (course == null) return false;
      return course.giftProduct != null || course.shipmentRequired == true;
    });
  }
}
