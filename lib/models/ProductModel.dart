// core/model/Product.dart
class Product {
  final int id;
  final String? image;
  final int? price;
  final int? discountPercentage;
  final Category category;
  final String nameFarsi;
  final String? nameEnglish;
  final String? description;
  final bool published;
  final String createdAt;
  final List<String> images;
  final List<int> similarProducts;

  Product({
    required this.id,
    this.image,
    this.price,
    this.discountPercentage,
    required this.category,
    required this.nameFarsi,
    this.nameEnglish,
    this.description,
    required this.published,
    required this.createdAt,
    required this.images,
    required this.similarProducts,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      image: json['image'],
      price: json['price'],
      discountPercentage: json['discount_percentage'],
      category: Category.fromJson(json['category']),
      nameFarsi: json['name_farsi'],
      nameEnglish: json['name_english'],
      description: json['description'],
      published: json['published'],
      createdAt: json['created_at'],
      images: List<String>.from(json['images'] ?? []),
      similarProducts: List<int>.from(json['simillar_products'] ?? []),
    );
  }
}

class Category {
  final String nameFarsi;
  final String? image;
  final int id;

  Category({required this.nameFarsi, this.image, required this.id});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      nameFarsi: json['name_farsi'],
      image: json['image'],
      id: json['id'],
    );
  }
}