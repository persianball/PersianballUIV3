// bloc/login/login_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<CheckAuthStatus>((event, emit) async {
      emit(LoginLoading());
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        final token = await AuthService.getToken();
        emit(LoginAuthenticated(token!));
      } else {
        emit(LoginUnauthenticated());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(LoginLoading());
      final result = await AuthService.login(event.username, event.password);
      if (result['success']) {
        emit(LoginAuthenticated(result['data']['token']));
      } else {
        emit(LoginUnauthenticated(result['message']));
      }
    });

    on<RegisterRequested>((event, emit) async {
      emit(LoginLoading());
      final result = await AuthService.register(
        email: event.email,
        mobileNumber: event.mobileNumber,
        username: event.username,
        password: event.password,
      );
      if (result['success']) {
        emit(LoginAuthenticated(result['data']['token']));
      } else {
        emit(LoginUnauthenticated(result['message']));
      }
    });

    on<LogoutRequested>((event, emit) async {
      await AuthService.logout();
      emit(LoginUnauthenticated('شما با موفقیت خارج شدید'));
    });
  }
}