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


class ProductDetail {
  final int id;
  final String? nameFarsi;
  final String? nameEnglish;
  final String? description;
  final String? image;
  final List<String> images;
  final int? price;
  final int? discountPercentage;
  final List<ProductVariant> variants;
  final String? video;
  final String? videoThumbnail;
  final Category category;
  final List<SimilarProduct> similarProducts;
  final double avgRate;
  final List<ProductComment> comments;
  final String? editor;
  final List<FaqItem>? faqs;

  ProductDetail({
    required this.id,
    this.nameFarsi,
    this.nameEnglish,
    this.description,
    this.image,
    required this.images,
    this.price,
    this.discountPercentage,
    required this.variants,
    this.video,
    this.videoThumbnail,
    required this.category,
    required this.similarProducts,
    required this.avgRate,
    required this.comments,
    this.editor,
    this.faqs
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id'],
      nameFarsi: json['name_farsi'],
      nameEnglish: json['name_english'],
      description: json['description'],
      image: json['image'],
      images: List<String>.from(json['images'] ?? []),
      price: json['price'],
      discountPercentage: json['discount_percentage'],
      variants: (json['variants'] as List).map((v) => ProductVariant.fromJson(v)).toList(),
      video: json['video'],
      videoThumbnail: json['video_thumbnail'],
      category: Category.fromJson(json['category']),
      similarProducts: (json['simillar_products'] as List).map((v) => SimilarProduct.fromJson(v)).toList(),
      avgRate: (json['avg_rate'] ?? 0.0).toDouble(),
      comments: (json['comments'] as List).map((v) => ProductComment.fromJson(v)).toList(),
      editor: json['editor'] ?? "",
      faqs: (json['faqs'] as List).map((v) => FaqItem.fromJson(v)).toList(),
    );
  }
}

class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
        question: json['question'],
        answer: json['answer'],
    );
  }
}

class ProductComment {
  final String text;
  final String adminResponse;
  final String createAt;

  ProductComment({required this.text,required this.adminResponse,required this.createAt});

  factory ProductComment.fromJson(Map<String, dynamic> json) {
    return ProductComment(
      text: json['text'],
      adminResponse: json['admin_response'],
      createAt: json['created_at']
    );
  }
}

class ProductVariant {
  final String? image;
  final String? color;
  final String? colorRgb;
  final String? productName;
  final int id;
  final bool isActive;
  final List<SizeVariant> sizeVariants;
  final String? icon;
  final String? video;
  final List<String> images;

  ProductVariant({
    this.image,
    this.color,
    this.colorRgb,
    this.productName,
    required this.id,
    required this.isActive,
    required this.sizeVariants,
    this.icon,
    this.video,
    required this.images,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      image: json['image'],
      color: json['color'],
      colorRgb: json['color_rgb'],
      productName: json['product_name'],
      id: json['id'],
      isActive: json['is_active'],
      sizeVariants: (json['size_variants'] as List).map((v) => SizeVariant.fromJson(v)).toList(),
      icon: json['icon'],
      video: json['video'],
      images: List<String>.from(json['images'] ?? []),
    );
  }
}

class SizeVariant {
  final String size;
  final int? discountPercentage;
  final int price;
  final int id;

  /// موجودی انبار این سایز (فیلد count در API)
  final int count;

  SizeVariant({
    required this.id,
    required this.size,
    required this.discountPercentage,
    required this.price,
    this.count = 0,
  });

  bool get inStock => count > 0;

  /// موجودی کم: برای ایجاد حس فوریت و شفافیت با کاربر
  bool get isLowStock => count > 0 && count <= 3;

  factory SizeVariant.fromJson(Map<String, dynamic> json) {
    return SizeVariant(
      id:json['id'],
      size: json['size'],
      discountPercentage: json['discount_percentage'],
      price: json['price'],
      count: json['count'] is int ? json['count'] : int.tryParse('${json['count']}') ?? 0,
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

class SimilarProduct {
  final int id;
  final String nameFarsi;
  final String nameEnglish;
  final List<String> images;
  final String image;
  final int? discountPercentage;
  final int? price;

  SimilarProduct({
    required this.id,
    required this.nameFarsi,
    required this.nameEnglish,
    required this.images,
    required this.image,
    this.discountPercentage,
    this.price,
  });

  factory SimilarProduct.fromJson(Map<String, dynamic> json) {
    return SimilarProduct(
      id: json['id'],
      nameFarsi: json['name_farsi'],
      nameEnglish: json['name_english'],
      images: List<String>.from(json['images'] ?? []),
      image: json['image'],
      discountPercentage: json['discount_percentage'],
      price: json['price'],
    );
  }
}

class ColorVariant {
  final String color;
  final String colorCode;
  final String? imageUrl;

  ColorVariant({required this.color, required this.colorCode, this.imageUrl});
}


