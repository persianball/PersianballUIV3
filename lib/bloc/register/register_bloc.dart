// bloc/register/register_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc() : super(RegisterInitial()) {
    on<RegisterWithEmail>((event, emit) async {
      if (event.password != event.confirmPassword) {
        emit(RegisterFailure('رمز عبور و تکرار آن یکسان نیستند'));
        return;
      }

      emit(RegisterLoading());
      final result = await AuthService.register(
        email: event.email,
        username: event.username,
        password: event.password,
        inviteKey: event.inviteKey,
      );

      if (result['success']) {
        emit(RegisterSuccess(result['data']));
      } else {
        emit(RegisterFailure(result['message']));
      }
    });

    on<RegisterWithMobile>((event, emit) async {
      if (event.password != event.confirmPassword) {
        emit(RegisterFailure('رمز عبور و تکرار آن یکسان نیستند'));
        return;
      }

      emit(RegisterLoading());
      final result = await AuthService.register(
        mobileNumber: event.mobileNumber,
        username: event.username,
        password: event.password,
        inviteKey: event.inviteKey,
      );

      if (result['success']) {
        emit(RegisterSuccess(result['data']));
      } else {
        emit(RegisterFailure(result['message']));
      }
    });
  }
}