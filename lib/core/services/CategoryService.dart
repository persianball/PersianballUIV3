import 'package:persian_ball/core/model/Category.dart';

class CategoryService {
  static List<Category> categoryData = categoryRawData.map((data) => Category.fromJson(data)).toList();
}

var categoryRawData = [
  {
    'featured': false,
    'icon_url': 'assets/icons/free_style_clothes.svg',
    'name': 'فری استایل',
  },
  {
    'featured': false,
    'icon_url': 'assets/icons/clothes.svg',
    'name': 'لباس',
  },
  {
    'featured': false,
    'icon_url': 'assets/icons/ball_bag.svg',
    'name': 'کیف توپ',
  },

];
