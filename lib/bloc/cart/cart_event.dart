part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final CartModel item;

  const AddToCart(this.item);

  @override
  List<Object?> get props => [item];
}

class UpdateQuantity extends CartEvent {
  final int id;
  final int quantity;

  const UpdateQuantity(this.id, this.quantity);

  @override
  List<Object?> get props => [id, quantity];
}

class RemoveFromCart extends CartEvent {
  final int id;

  const RemoveFromCart(this.id);

  @override
  List<Object?> get props => [id];
}

class ClearCart extends CartEvent {}