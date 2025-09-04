import 'package:flutter/cupertino.dart';
import 'package:marketky/models/ProductModel.dart';

class ColorWay {
  String name;
  Color color;
  String? imageUrl;

  ColorWay({required this.name, required this.color, String? imageUrl});

  factory ColorWay.fromJson(Map<String, dynamic> json) {
    return ColorWay(name: json['name'], color: json['color']);
  }
}



class ColorVariant {
  final String color;       // نام رنگ فارسی مثل "مشکی"
  final String colorCode;   // کد رنگ مثل "#000000"
  final String? imageUrl;   // آدرس تصویر مرتبط با این رنگ

  ColorVariant({required this.color, required this.colorCode, this.imageUrl});
}