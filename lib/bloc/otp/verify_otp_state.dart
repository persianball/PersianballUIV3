// bloc/verify_otp/verify_otp_state.dart
part of 'verify_otp_bloc.dart';


abstract class VerifyOtpState extends Equatable {
  const VerifyOtpState();

  @override
  List<Object?> get props => [];
}

class VerifyOtpInitial extends VerifyOtpState {}

class VerifyOtpLoading extends VerifyOtpState {}

class VerifyOtpSuccess extends VerifyOtpState {
  final Map<String, dynamic> userData;

  const VerifyOtpSuccess(this.userData);

  @override
  List<Object?> get props => [userData];
}

class VerifyOtpFailure extends VerifyOtpState {
  final String message;

  const VerifyOtpFailure(this.message);

  @override
  List<Object?> get props => [message];
}