// lib/utils/stock_limit.dart
//
// سقفِ تعداد بر اساسِ موجودیِ انبار. موجودی به ازای هر «سایز» است (فیلدِ
// count)، و شناسه‌ی همان سایز چیزی است که به سبد فرستاده می‌شود.
import 'package:persian_ball/bloc/cart/cart_bloc.dart';

/// از این سایز الان چند عدد در سبد است (صفر اگر سبد هنوز خوانده نشده).
int quantityInCart(CartState state, int sizeVariantId) {
  if (state is! CartLoaded) return 0;
  int total = 0;
  for (final basket in state.cart.results) {
    for (final item in basket.items) {
      if (item.product?.id == sizeVariantId) total += item.quantity;
    }
  }
  return total;
}

/// چند عددِ دیگر می‌شود اضافه کرد. null یعنی موجودی معلوم نیست و سقفی
/// اعمال نمی‌شود (تصمیم با سرور).
int? remainingStock({required int? stock, required int inCart}) {
  if (stock == null) return null;
  final left = stock - inCart;
  return left < 0 ? 0 : left;
}
