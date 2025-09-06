// core/model/Cart.dart
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
  final int? product;
  final int? classes;
  final int? course;
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
        product: json['product'],
        classes: json['classes'],
        support_coach: json['support_coach'],
        course: json['course']
    );
  }
}
class CartFromBackend{
  final int count;
  final List<CartItemFromBackend> results;


  CartFromBackend({required this.count, required this.results});

  factory CartFromBackend.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['results'] as List;
    final items = itemsJson.map((item) => CartItemFromBackend.fromJson(item)).toList();
    return CartFromBackend(
      results: items,
      count: json['count']
    );
  }
}