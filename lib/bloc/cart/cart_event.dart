part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {}

class UpdateQuantityLoadingEvent extends CartEvent {}

class AddToCart extends CartEvent {
  final int productId;
  final int quantity;

  const AddToCart(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

class RemoveFromCart extends CartEvent {
  final int itemId;

  const RemoveFromCart(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class UpdateQuantity extends CartEvent {
  final int itemId;
  final int productId;
  final int quantity;

  const UpdateQuantity(this.itemId,this.productId, this.quantity);

  @override
  List<Object?> get props => [itemId, quantity];
}