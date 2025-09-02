
import 'package:equatable/equatable.dart';

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

// class ChangeProductColor extends ProductDetailEvent{
//   final int varientIndex;
//
// }