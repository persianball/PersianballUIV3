// core/model/Cart.dart
import 'package:marketky/models/ProductModel.dart';
import 'package:marketky/models/course_detail_model.dart';

class CartItem {
  final int id;
  final int productId;
  final String name;
  final String image;
  final int price;
  final int quantity;
  final int? discountPrice;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    this.discountPrice
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['product_id'],
      name: json['name'],
      image: json['image'],
      price: json['price'],
      quantity: json['quantity'],
      discountPrice: json['discount_price']
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
      totalPrice: json['total_price'],
      itemCount: json['item_count'],
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
        id: json['id'],
        quantity: json['quantity'],
        product: json['product']==null? null:ProductInCart.fromJson(json['product']),
      course: json['course']==null?null:CourseInCart.fromJson(json['course']),
        classes: json['classes'],
        support_coach: json['support_coach'],

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
        price: json['price'],
        nat: json['nat']!=null ? json['nat'].toInt() : 0,
        discountedPrice: json['discounted_price']!=null?json['discounted_price'].toInt(): 0,
        isFreeShipping: json['is_free_shipping'],
        freeShippingThreshold: json['free_shipping_threshold'],
        postShippingPrice: json['post_shipping_price'],
        peykShippingPrice: json['peyk_shipping_price'],
        orderShippingPrice: json['order_shipping_price']
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
    return ProductInCart(id:json['id'],productVariant:ProductVariant.fromJson(json['product_variant']),size:json['size'],count:json['count'],disountPercentage:json['discount_percentage'],isActive:json['is_active'],price:json['price']);
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
        price: json['price'],
        location: json['location'],
        coach: json['coach'],
        courseName: json['course_name'],
        giftProduct:json['gift_product'] != null ? ProductVariant.fromJson(json['gift_product']) : null,
        id:json['id'],
        shipmentRequired:json['shipment_required'],
        discountPercentage:json['discount_percentage'],
        capacity:json['capacity']
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
        user: json['user'],
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
      count: json['count']
    );
  }
}