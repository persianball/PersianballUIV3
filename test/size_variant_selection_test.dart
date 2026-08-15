import 'package:flutter_test/flutter_test.dart';
import 'package:marketky/models/ProductModel.dart';

SizeVariant _s(String size, int count) =>
    SizeVariant(id: size.hashCode, size: size, discountPercentage: 0, price: 1000, count: count);

void main() {
  test('اگر سایز اول ناموجود باشد، اولین سایز موجود انتخاب می‌شود', () {
    final sizes = [_s('39', 0), _s('40', 0), _s('41', 5)];
    expect(firstAvailableSizeVariant(sizes)!.size, '41');
  });

  test('اگر سایز اول موجود باشد، همان انتخاب می‌شود', () {
    final sizes = [_s('39', 2), _s('40', 7)];
    expect(firstAvailableSizeVariant(sizes)!.size, '39');
  });

  test('اگر هیچ سایزی موجود نباشد، سایز اول برگردانده می‌شود', () {
    final sizes = [_s('39', 0), _s('40', 0)];
    expect(firstAvailableSizeVariant(sizes)!.size, '39');
  });

  test('لیست خالی نتیجه null می‌دهد', () {
    expect(firstAvailableSizeVariant([]), isNull);
  });

  test('inStock و isLowStock درست محاسبه می‌شوند', () {
    expect(_s('42', 0).inStock, isFalse);
    expect(_s('42', 2).isLowStock, isTrue);
    expect(_s('42', 9).isLowStock, isFalse);
  });
}
