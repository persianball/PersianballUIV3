
import 'package:equatable/equatable.dart';
import 'package:persian_ball/models/ProductModel.dart';

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
  final SizeVariant? productSize;


  const ChangeProductColorEvent(this.prdouctVar,this.productSize);

  @override
  List<Object?> get props => [prdouctVar];

}

class ChangeProductSizeEvent extends ProductDetailEvent{
  final ProductVariant productVariant;
  final SizeVariant productSize;

  const ChangeProductSizeEvent(this.productVariant,this.productSize);

  @override
  List<Object?> get props => [productVariant,productSize];

}