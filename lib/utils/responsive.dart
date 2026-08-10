import 'package:flutter/widgets.dart';

class Responsive {
  static const double small = 600.0;
  static const double medium = 1024.0;
  static const double large = 1440.0;

  static double contentMaxWidth(double width, {double max = 1200.0}) {
    return width >= medium ? max : width;
  }

  static int crossAxisCount(double width, {int min = 2, int max = 6}) {
    if (width < small) return min;
    if (width < medium) return (min + 1).clamp(min, max);
    if (width < large) return (min + 2).clamp(min, max);
    return max;
  }

  static EdgeInsets pagePadding(double width) {
    return EdgeInsets.symmetric(
      horizontal: width < small ? 16 : (width < medium ? 24 : 32),
    );
  }
}