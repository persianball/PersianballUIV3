

import 'package:equatable/equatable.dart';
import 'package:marketky/core/model/ProductSize.dart';

import '../../models/ProductModel.dart';

abstract class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {}

class ProductDetailLoading extends ProductDetailState {}

class ProductDetailLoaded extends ProductDetailState {
  final ProductDetail product;

  const ProductDetailLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductDetailError extends ProductDetailState {
  final String message;

  const ProductDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductDetailChangedState extends ProductDetailState {
  final ProductVariant productVariant;
  final SizeVariant? productSize;


  const ProductDetailChangedState(this.productVariant,this.productSize);

  @override
  List<Object?> get props => [productVariant];
}

class ProductDetailSizeChanged extends ProductDetailState{
  final ProductVariant productVariant;
  final SizeVariant productSize;


  const ProductDetailSizeChanged(this.productVariant,this.productSize);

  @override
  List<Object?> get props => [productVariant,productSize];
}