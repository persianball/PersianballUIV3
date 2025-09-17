// utils/auth_guard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marketky/bloc/login/login_bloc.dart';
import 'package:marketky/views/screens/login_page.dart';

/// Ensures user is authenticated before performing [action].
/// - If authenticated: runs [action] immediately.
/// - If not: pushes LoginPage(popOnSuccess: true), then runs [action] if login succeeds.
Future<void> ensureAuthenticated(BuildContext context, Future<void> Function() action) async {
  final loginState = context.read<LoginBloc>().state;
  bool isAuthed = loginState is LoginAuthenticated;

  if (isAuthed) {
    await action();
    return;
  }

  final result = await Navigator.of(context).pushNamed<bool>(
    '/login',
    arguments: {'popOnSuccess': true},
  );

  if (result == true) {
    await action();
  }
}