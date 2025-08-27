// bloc/verify_otp/verify_otp_event.dart
part of 'verify_otp_bloc.dart';

abstract class VerifyOtpEvent extends Equatable {
  const VerifyOtpEvent();

  @override
  List<Object?> get props => [];
}

class OtpSubmitted extends VerifyOtpEvent {
  final String code;
  final String? email;
  final String? mobileNumber;

  const OtpSubmitted({
    required this.code,
    this.email,
    this.mobileNumber,
  });

  @override
  List<Object?> get props => [code, email, mobileNumber];
}