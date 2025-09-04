
import 'package:equatable/equatable.dart';
import 'package:marketky/models/ProductModel.dart';

abstract class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object?> get props => [];
}

class FetchProductDetail extends ProductDetailEvent {
  final int productId;

  const FetchProductDetail(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ChangeProductColorEvent extends ProductDetailEvent{
  final ProductVariant prdouctVar;


  const ChangeProductColorEvent(this.prdouctVar);

  @override
  List<Object?> get props => [prdouctVar];

}