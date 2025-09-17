import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../models/address_model.dart';
abstract class AddressEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAddresses extends AddressEvent {
  final BuildContext context;
  LoadAddresses(this.context);
}

class CreateAddress extends AddressEvent {
  final BuildContext context;
  final AddressModel model;
  CreateAddress(this.context, this.model);
}

class UpdateAddress extends AddressEvent {
  final BuildContext context;
  final int id;
  final AddressModel model;
  UpdateAddress(this.context, this.id, this.model);
}

class DeleteAddress extends AddressEvent {
  final BuildContext context;
  final int id;
  DeleteAddress(this.context, this.id);
}