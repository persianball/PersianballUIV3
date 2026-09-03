part of 'cart_bloc.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartUpdatingLoading extends CartState {}


class CartLoaded extends CartState {
  final AllCartFromBackend cart;

  const CartLoaded(this.cart);

  @override
  List<Object?> get props => [cart];
}

class CartItemChangedQuantity extends CartState {
  final AllCartFromBackend productInCart;

  const CartItemChangedQuantity(this.productInCart);

  @override
  List<Object?> get props => [productInCart];
}

class CartItemAdded extends CartState {
  final String message;

  const CartItemAdded(this.message);

  @override
  List<Object?> get props => [message];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

/// مهمان بودن، «خطا» نیست: صفحه‌ی سبد باید دعوت به ورود نشان دهد، ولی
/// صفحه‌های محصول/دوره که سبد را در پس‌زمینه بار می‌کنند نباید اسنک‌بار
/// قرمز بدهند. زیرکلاسِ CartError است تا هر `is CartError` موجود
/// دست‌نخورده کار کند.
class CartRequiresLogin extends CartError {
  const CartRequiresLogin() : super('نیاز به ورود دارید');
}

/// کالا واقعاً به سبد اضافه (یا حذف/ویرایش) شد، ولی خواندنِ دوباره‌ی سبد از
/// سرور شکست خورد.
///
/// این را از [CartError] جدا نگه می‌داریم چون پیام «افزودن ناموفق بود» در
/// این حالت دروغ است: عملیات انجام شده و فقط نمای سبد به‌روز نشده. صفحه‌ی
/// محصول هم نباید انیمیشن افزودن را نصفه قطع کند.
class CartRefreshFailed extends CartError {
  const CartRefreshFailed(super.message);
}
