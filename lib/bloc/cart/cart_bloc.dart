// bloc/cart/cart_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/CartModel.dart';
part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartInitial()) {
    on<AddToCart>((event, emit) {
      final state = this.state;
      if (state is CartLoaded) {
        final items = List<CartModel>.from(state.items);
        final index = items.indexWhere((item) => item.id == event.item.id);
        if (index >= 0) {
          items[index] = items[index].copyWith(quantity: items[index].quantity + event.item.quantity);
        } else {
          items.add(event.item);
        }
        emit(CartLoaded(items));
      } else {
        emit(CartLoaded([event.item]));
      }
    });

    on<UpdateQuantity>((event, emit) {
      if (state is CartLoaded) {
        final items = List<CartModel>.from((state as CartLoaded).items);
        final index = items.indexWhere((item) => item.id == event.id);
        if (index >= 0 && event.quantity > 0) {
          items[index] = items[index].copyWith(quantity: event.quantity);
          emit(CartLoaded(items));
        } else if (event.quantity <= 0) {
          items.removeAt(index);
          emit(CartLoaded(items));
        }
      }
    });

    on<RemoveFromCart>((event, emit) {
      if (state is CartLoaded) {
        final items = (state as CartLoaded).items.where((item) => item.id != event.id).toList();
        emit(CartLoaded(items));
      }
    });

    on<ClearCart>((event, emit) {
      emit(CartLoaded([]));
    });
  }
}