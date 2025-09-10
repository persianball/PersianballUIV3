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
