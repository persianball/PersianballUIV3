import 'package:equatable/equatable.dart';

import '../../models/address_model.dart';
abstract class AddressEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAddresses extends AddressEvent {}

class CreateAddress extends AddressEvent {
  final AddressModel model;
  CreateAddress(this.model);
}

class UpdateAddress extends AddressEvent {
  final int id;
  final AddressModel model;
  UpdateAddress(this.id, this.model);
}

class DeleteAddress extends AddressEvent {
  final int id;
  DeleteAddress(this.id);
}