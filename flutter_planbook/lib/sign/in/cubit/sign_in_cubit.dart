import 'package:bloc/bloc.dart';
import 'package:email_validator/email_validator.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:planbook_repository/users/users_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit({required UsersRepository usersRepository})
    : _usersRepository = usersRepository,
      super(SignInInitial());

  final UsersRepository _usersRepository;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(SignInLoading());

    try {
      await _usersRepository.signInWithPassword(
        email: email,
        password: password,
      );
      emit(SignInSuccess());
    } on Exception catch (e) {
      emit(SignInFailure(e.toString()));
    }
  }

  Future<void> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    emit(SignInLoading());

    try {
      if (EmailValidator.validate(phone)) {
        await _usersRepository.signInWithPassword(
          email: phone,
          password: password,
        );
      } else {
        await _usersRepository.signInWithPassword(
          phone: phone,
          password: password,
        );
      }
      emit(SignInSuccess());
    } on Exception catch (e) {
      emit(SignInFailure(e.toString()));
    }
  }

  Future<void> sendCode({required String phone}) async {
    emit(CodeSending());

    try {
      if (EmailValidator.validate(phone)) {
        await _usersRepository.signInWithOtp(
          email: phone,
          shouldCreateUser: true,
        );
      } else {
        await _usersRepository.signInWithOtp(
          phone: phone,
          shouldCreateUser: true,
        );
      }
      emit(CodeSentSuccess());
    } on Exception catch (e) {
      print('e: $e');
      emit(CodeSentFailure(e.toString()));
    }
  }

  Future<void> signInWithCode({
    required String phone,
    required String code,
  }) async {
    emit(SignInLoading());

    try {
      if (EmailValidator.validate(phone)) {
        await _usersRepository.verifyOTP(
          type: OtpType.email,
          email: phone,
          token: code,
        );
      } else {
        await _usersRepository.verifyOTP(
          type: OtpType.sms,
          phone: phone,
          token: code,
        );
      }
      emit(SignInSuccess());
    } on AuthException catch (e) {
      try {
        if (EmailValidator.validate(phone)) {
          await _usersRepository.verifyOTP(
            type: OtpType.signup,
            email: phone,
            token: code,
          );
        } else {
          await _usersRepository.verifyOTP(
            type: OtpType.signup,
            phone: phone,
            token: code,
          );
        }
        emit(SignInSuccess());
      } on Exception catch (e) {
        if (kDebugMode) {
          print('e: $e');
        }
        emit(SignInFailure(e.toString()));
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('e: $e');
      }
      emit(SignInFailure(e.toString()));
    }
  }
}
