part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

class RegisterWithEmail extends RegisterEvent {
  final String email;
  final String username;
  final String password;
  final String confirmPassword;
  final String? inviteKey;

  const RegisterWithEmail({
    required this.email,
    required this.username,
    required this.password,
    required this.confirmPassword,
    this.inviteKey,
  });

  @override
  List<Object?> get props => [email, username, password, confirmPassword, inviteKey];
}

class RegisterWithMobile extends RegisterEvent {
  final String mobileNumber;
  final String username;
  final String password;
  final String confirmPassword;
  final String? inviteKey;

  const RegisterWithMobile({
    required this.mobileNumber,
    required this.username,
    required this.password,
    required this.confirmPassword,
    this.inviteKey,
  });

  @override
  List<Object?> get props => [mobileNumber, username, password, confirmPassword, inviteKey];
}