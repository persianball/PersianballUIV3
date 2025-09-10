// lib/bloc/address/address_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:marketky/models/address_model.dart';
import 'package:marketky/services/address_service.dart';

part 'address_event.dart';
part 'address_state.dart';

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
      final list = await AddressService.list();
      emit(AddressLoaded(list: list));
    } catch (err) {
      emit(AddressError(err.toString()));
    }
  }

  Future<void> _onCreate(CreateAddress e, Emitter<AddressState> emit) async {
    try {
      await AddressService.create(e.model);
      add(LoadAddresses());
    } catch (err) {
      emit(AddressError(err.toString()));
    }
  }

  Future<void> _onUpdate(UpdateAddress e, Emitter<AddressState> emit) async {
    try {
      await AddressService.update(e.id, e.model);
      add(LoadAddresses());
    } catch (err) {
      emit(AddressError(err.toString()));
    }
  }

  Future<void> _onDelete(DeleteAddress e, Emitter<AddressState> emit) async {
    try {
      await AddressService.remove(e.id);
      add(LoadAddresses());
    } catch (err) {
      emit(AddressError(err.toString()));
    }
  }
}