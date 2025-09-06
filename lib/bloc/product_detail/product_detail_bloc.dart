// bloc/product_detail/product_detail_bloc.dart
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:marketky/bloc/product_detail/product_detail_event.dart';
import 'package:marketky/bloc/product_detail/product_detail_state.dart';
import '../../models/ProductModel.dart';
import '../../constant/urls.dart';
import '../../services/product_service.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc() : super(ProductDetailInitial()) {
    on<FetchProductDetail>((event, emit) async {
      emit(ProductDetailLoading());

      try {
        final product = await ProductService.fetchProductDetail(event.productId);
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
    });


    on<ChangeProductSizeEvent>((event, emit) async {
      print("ChangeProductSizeEvent");
      emit(ProductDetailSizeChanged(event.productVariant,event.productSize));
    });
  }
}