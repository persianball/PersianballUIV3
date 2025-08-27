part of 'register_bloc.dart';

abstract class RegisterState extends Equatable {
  const RegisterState();

  @override
  List<Object?> get props => [];
}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final Map<String, dynamic> userData;

  const RegisterSuccess(this.userData);

  @override
  List<Object?> get props => [userData];
}

class RegisterFailure extends RegisterState {
  final String message;

  const RegisterFailure(this.message);

  @override
  List<Object?> get props => [message];
}