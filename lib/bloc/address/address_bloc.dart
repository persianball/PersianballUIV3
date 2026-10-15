// lib/bloc/address/address_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persian_ball/services/address_service.dart';

import 'address_event.dart';
import 'address_state.dart';


class AddressBloc extends Bloc<AddressEvent, AddressState> {
  AddressBloc() : super(AddressInitial()) {
    on<LoadAddresses>(_onLoad);
    on<CreateAddress>(_onCreate);
    on<UpdateAddress>(_onUpdate);
    on<DeleteAddress>(_onDelete);
  }

  Future<void> _onLoad(LoadAddresses e, Emitter<AddressState> emit) async {
    emit(AddressLoading());
    try {
      final list = await AddressService.list(e.context);
      emit(AddressLoaded(list: list));
    } catch (err) {
      emit(AddressError(err.toString()));
    }
  }

  Future<void> _onCreate(CreateAddress e, Emitter<AddressState> emit) async {
    try {
      await AddressService.create(e.context, e.model);
      add(LoadAddresses(e.context));
    } catch (err) {
      emit(AddressError(err.toString()));
    }
  }

  Future<void> _onUpdate(UpdateAddress e, Emitter<AddressState> emit) async {
    try {
      await AddressService.update(e.context, e.id, e.model);
      add(LoadAddresses(e.context));
    } catch (err) {
      emit(AddressError(err.toString()));
    }
  }

  Future<void> _onDelete(DeleteAddress e, Emitter<AddressState> emit) async {
    try {
      await AddressService.remove(e.context, e.id);
      add(LoadAddresses(e.context));
    } catch (err) {
      emit(AddressError(err.toString()));
    }
  }
}