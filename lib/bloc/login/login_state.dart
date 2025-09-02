// bloc/login/login_state.dart
part of 'login_bloc.dart';


abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginAuthenticated extends LoginState {
  final String token;

  const LoginAuthenticated(this.token);

  @override
  List<Object?> get props => [token];
}

class LoginUnauthenticated extends LoginState {
  final String? message;

  const LoginUnauthenticated([this.message]);

  @override
  List<Object?> get props => [message];
}

class LoginError extends LoginState {
  final String message;

  const LoginError(this.message);

  @override
  List<Object?> get props => [message];
}