// core/model/Cart.dart
class CartModel {
  final int id;
  final String name;
  final String image;
  final int price;
  final int quantity;

  CartModel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  // برای افزودن یا به‌روزرسانی
  CartModel copyWith({int? quantity}) {
    return CartModel(
      id: id,
      name: name,
      image: image,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }
}