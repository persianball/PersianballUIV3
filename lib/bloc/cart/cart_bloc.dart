// bloc/cart/cart_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/models/CartModel.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartInitial()) {
    on<LoadCart>((event, emit) async {
      emit(CartLoading());

      // Auth is checked here, before ever calling CartService.fetchCart,
      // so the silent initial load never opens the "please log in" dialog.
      // Awaiting a dialog from inside a Bloc handler is fragile (the
      // Future can be left pending if the barrier is dismissed via a path
      // that doesn't resolve it), which previously froze the cart on a
      // permanent blank CartLoading screen for guests.
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        emit(CartError('نیاز به ورود دارید'));
        return;
      }

      try {
        final cart = await CartService.fetchCart(event.context);
        emit(CartLoaded(cart));
      } catch (e) {
        emit(CartError(e.toString()));
      }
    });

    on<UpdateQuantityLoadingEvent>((event, emit) async {
      emit(CartUpdatingLoading());
    });

    on<AddToCart>((event, emit) async {
      emit(CartLoading());
      try {
        await CartService.addToCart(
            event.context, event.productId, event.quantity);
        emit(CartItemAdded('این کالا به سبد خرید اضافه شد')); // ← نمایش دیالوگ
        final cart = await CartService.fetchCart(event.context);
        emit(CartLoaded(cart));
      } catch (e) {
        emit(CartError('افزودن کالا ناموفق بود: ${e.toString()}'));
      }
    });

    on<RemoveFromCart>((event, emit) async {
      // Keep current UI; avoid global loading for minor cart updates
      try {
        await CartService.removeItem(event.context, event.itemId);
        final cart = await CartService.fetchCart(event.context);
        emit(CartLoaded(cart));
      } catch (e) {
        emit(CartError('حذف ناموفق'));
      }
    });

    on<UpdateQuantity>((event, emit) async {
      // Avoid emitting CartLoading to prevent full-screen refresh
      try {
        await CartService.updateQuantity(event.context, event.itemId,
            event.productId, event.courseId, event.quantity);
        final cart = await CartService.fetchCart(event.context);
        emit(CartLoaded(cart));
      } catch (e) {
        emit(CartError('به‌روزرسانی ناموفق'));
      }
    });

    on<AddCourseToCart>((event, emit) async {
      emit(CartLoading());
      try {
        await CartService.addCourseToCart(
            event.context, event.courseId, event.quantity);
        emit(CartItemAdded('این دوره به سبد خرید اضافه شد'));
        final cart = await CartService.fetchCart(event.context);
        emit(CartLoaded(cart));
      } catch (e) {
        emit(CartError('افزودن دوره ناموفق بود: ${e.toString()}'));
      }
    });
  }
}
