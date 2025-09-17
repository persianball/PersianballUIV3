part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {
  final BuildContext context;
  const LoadCart(this.context);

  @override
  List<Object?> get props => [context];
}

class UpdateQuantityLoadingEvent extends CartEvent {}

class AddToCart extends CartEvent {
  final BuildContext context;
  final int productId;
  final int quantity;

  const AddToCart(this.context, this.productId, this.quantity);

  @override
  List<Object?> get props => [context, productId, quantity];
}

class RemoveFromCart extends CartEvent {
  final BuildContext context;
  final int itemId;

  const RemoveFromCart(this.context, this.itemId);

  @override
  List<Object?> get props => [context, itemId];
}

class UpdateQuantity extends CartEvent {
  final BuildContext context;
  final int itemId;
  final int productId;
  final int quantity;

  const UpdateQuantity(this.context, this.itemId,this.productId, this.quantity);

  @override
  List<Object?> get props => [context, itemId, quantity];
}