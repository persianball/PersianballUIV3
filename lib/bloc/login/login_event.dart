// bloc/login/login_event.dart
part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends LoginEvent {
  final String username;
  final String password;

  const LoginRequested(this.username, this.password);

  @override
  List<Object?> get props => [username, password];
}

class RegisterRequested extends LoginEvent {
  final String email;
  final String mobileNumber;
  final String username;
  final String password;

  const RegisterRequested({
    required this.email,
    required this.mobileNumber,
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [email, mobileNumber, username, password];
}

class LogoutRequested extends LoginEvent {}

class CheckAuthStatus extends LoginEvent {}