// bloc/login/login_bloc.dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import '../../services/push_notification_service.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<CheckAuthStatus>((event, emit) async {
      emit(LoginLoading());
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        final token = await AuthService.getToken();
        // دستگاه به حسابِ کاربر وصل می‌شود؛ ثبت دستگاه توکنِ ورود لازم
        // دارد، پس نمی‌تواند در شروعِ اپ و قبل از احراز هویت انجام شود.
        unawaited(PushNotificationService.onLogin());
        emit(LoginAuthenticated(token!));
      } else {
        emit(LoginUnauthenticated());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(LoginLoading());
      final result = await AuthService.login(event.username, event.password);
      if (result['success']) {
        unawaited(PushNotificationService.onLogin());
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
        unawaited(PushNotificationService.onLogin());
        emit(LoginAuthenticated(result['data']['token']));
      } else {
        emit(LoginUnauthenticated(result['message']));
      }
    });

    on<LogoutRequested>((event, emit) async {
      // پوشِ کاربرِ قبلی نباید به دستگاهی برود که دیگر دستِ او نیست
      await PushNotificationService.onLogout();
      await AuthService.logout();
      emit(LoginUnauthenticated('شما با موفقیت خارج شدید'));
    });
  }
}