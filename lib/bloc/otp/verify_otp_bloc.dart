// bloc/verify_otp/verify_otp_bloc.dart
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:marketky/services/auth_service.dart';

import '../../constant/urls.dart';

part 'verify_otp_event.dart';
part 'verify_otp_state.dart';

class VerifyOtpBloc extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  static const String apiUrl = '${URLs.baseUrl}/v1/user/code/verify/';

  VerifyOtpBloc() : super(VerifyOtpInitial()) {
    on<OtpSubmitted>((event, emit) async {
      emit(VerifyOtpLoading());

      try {

        final body = {
          'code': event.code,
        };

        if (event.email != null) {
          body['email'] = event.email!;
        } else if (event.mobileNumber != null) {
          body['mobile_number'] = event.mobileNumber!;
        }

        print(body);
        print(apiUrl);
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
        print(response.body);
        print(response.statusCode);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final token = data['extra']['access'];
          final refresh = data['extra']['refresh'];
          final isCoach = data['extra']['is_coach'];
          if (token != null) {
            await AuthService.saveTokens(token, refresh);
            emit(VerifyOtpSuccess(data));
          }else{
            final message = data['message'] ?? 'ثبت نام با مشکل مواجه شده است لطفا دوباره تلاش کنید.';
            emit(VerifyOtpFailure(message));
          }


        } else {
          final error = jsonDecode(response.body);
          final message = error['message'] ?? 'کد وارد شده نامعتبر است';
          emit(VerifyOtpFailure(message));
        }
      } catch (e) {
        emit(VerifyOtpFailure('عدم دسترسی به سرور. لطفاً اینترنت خود را بررسی کنید.'));
      }
    });
  }
}