part of 'address_bloc.dart';

abstract class AddressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddressInitial extends AddressState {}

class AddressLoading extends AddressState {}

class AddressLoaded extends AddressState {
  final List<AddressModel> list;
  AddressLoaded({required this.list});

  @override
  List<Object?> get props => [list];
}

class AddressError extends AddressState {
  final String message;
  AddressError(this.message);

  @override
  List<Object?> get props => [message];
}