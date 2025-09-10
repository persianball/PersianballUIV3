// bloc/cart/cart_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/models/CartModel.dart';
import '../../services/cart_service.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartInitial()) {
    on<LoadCart>((event, emit) async {
      emit(CartLoading());

      try {
        final cart = await CartService.fetchCart();

        emit(CartLoaded(cart));
      } catch (e) {

        emit(CartError(e.toString()));
      }
    });

    on<UpdateQuantityLoadingEvent>((event, emit) async{
      emit(CartUpdatingLoading());
    });

    on<AddToCart>((event, emit) async {

      emit(CartLoading());
      try {
        await CartService.addToCart(event.productId, event.quantity);
        emit(CartItemAdded('این کالا به سبد خرید اضافه شد')); // ← نمایش دیالوگ
        final cart = await CartService.fetchCart();
        emit(CartLoaded(cart));
      } catch (e) {
        emit(CartError('افزودن کالا ناموفق بود: ${e.toString()}'));
      }
    });

    on<RemoveFromCart>((event, emit) async {
      // Keep current UI; avoid global loading for minor cart updates
      try {
        await CartService.removeItem(event.itemId);
        final cart = await CartService.fetchCart();
        emit(CartLoaded(cart));
      } catch (e) {
        emit(CartError('حذف ناموفق'));
      }
    });

    on<UpdateQuantity>((event, emit) async {
      // Avoid emitting CartLoading to prevent full-screen refresh
      try {
        await CartService.updateQuantity(event.itemId, event.productId, event.quantity);
        final cart = await CartService.fetchCart();
        emit(CartLoaded(cart));
      } catch (e) {
        emit(CartError('به‌روزرسانی ناموفق'));
      }
    });
  }
}