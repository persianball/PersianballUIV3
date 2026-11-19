// bloc/product_detail/product_detail_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persian_ball/bloc/product_detail/product_detail_event.dart';
import 'package:persian_ball/bloc/product_detail/product_detail_state.dart';
import '../../services/product_service.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc() : super(ProductDetailInitial()) {
    on<FetchProductDetail>((event, emit) async {
      // محصولی که تازه دیده شده فوراً نشان داده می‌شود، بدونِ اسکلتِ بارگذاری.
      final cached = event.refresh
          ? null
          : ProductService.cachedProductDetail(event.productId);
      if (cached != null) {
        emit(ProductDetailLoaded(cached));
        return;
      }
      emit(ProductDetailLoading());

      try {
        final product = await ProductService.fetchProductDetail(
            event.productId,
            refresh: event.refresh);
        emit(ProductDetailLoaded(product));
      } catch (e) {
        emit(ProductDetailError(e.toString()));
      }


    });

  }
}

class ProductDetailVariantBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailVariantBloc() : super(ProductDetailInitial()) {


    on<ChangeProductColorEvent>((event, emit) async {
      print("ChangeProductColorEvent");
      emit(ProductDetailChangedState(event.prdouctVar,event.productSize));
      // رنگی که سایز ندارد (مثلاً جاتوپی) فقط تغییرِ رنگ است
      final size = event.productSize;
      if (size != null) {
        emit(ProductDetailSizeChanged(event.prdouctVar, size));
      }

    });


    on<ChangeProductSizeEvent>((event, emit) async {
      print("ChangeProductSizeEvent");
      emit(ProductDetailSizeChanged(event.productVariant,event.productSize));
    });
  }
}