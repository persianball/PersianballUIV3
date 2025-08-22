// bloc/login/login_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginSubmitted>((event, emit) async {
      emit(LoginLoading());

      try {
        final result = await AuthService.login(event.username, event.password);

        if (result['success']) {
          emit(LoginSuccess(result['data']));
        } else {
          emit(LoginFailure(result['message']));
        }
      } catch (e) {
        emit(LoginFailure('خطا در ارتباط با سرور'));
      }
    });
  }
}