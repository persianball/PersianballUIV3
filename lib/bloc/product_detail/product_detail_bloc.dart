// bloc/product_detail/product_detail_bloc.dart
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:marketky/bloc/product_detail/product_detail_event.dart';
import 'package:marketky/bloc/product_detail/product_detail_state.dart';
import '../../models/ProductModel.dart';
import '../../constant/urls.dart';


class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc() : super(ProductDetailInitial()) {
    on<FetchProductDetail>((event, emit) async {
      emit(ProductDetailLoading());
      try {

        final response = await http.get(
          Uri.parse('${URLs.baseUrl}/v2/product/product/${event.productId}/'),
        );
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final product = ProductDetail.fromJson(json);
          emit(ProductDetailLoaded(product));
        } else {
          emit(ProductDetailError('محصول یافت نشد'));
        }
      } catch (e,s) {
        print(e);
        print(s);
        emit(ProductDetailError('خطا در ارتباط با سرور'));
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