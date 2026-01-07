import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:planbook_api/supabase/app_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'sign_home_state.dart';

class SignHomeCubit extends Cubit<SignHomeState> {
  SignHomeCubit() : super(const SignHomeState());

  void onInitialized() {
    FlutterNativeSplash.remove();
  }

  void backToWelcome() {
    emit(state.copyWith(status: SignHomeStatus.welcome));
  }

  void signInWithCode() {
    emit(state.copyWith(status: SignHomeStatus.signInWithCode));
  }

  void signInWithPhone() {
    emit(state.copyWith(status: SignHomeStatus.signInWithPhone));
  }

  void signInWithPassword() {
    emit(state.copyWith(status: SignHomeStatus.signInWithPassword));
  }

  void signInWithEmail() {
    emit(state.copyWith(status: SignHomeStatus.signInWithEmail));
  }

  void signUp() {
    emit(state.copyWith(status: SignHomeStatus.signUp));
  }

  void forgotPassword() {
    emit(state.copyWith(status: SignHomeStatus.forgotPassword));
  }

  void setIsAgreedToTerms({required bool isAgreed}) {
    emit(state.copyWith(isAgreedToTerms: isAgreed));
  }

  Future<void> signInWithApple() async {
    final authResponse = await AppSupabase.instance.signInWithApple();
    if (authResponse != null) {
      emit(state.copyWith(authResponse: authResponse));
    }
  }

  Future<void> signInWithGoogle() async {
    final authResponse = await AppSupabase.instance.signInWithGoogle();
    if (authResponse != null) {
      emit(state.copyWith(authResponse: authResponse));
    }
  }
}
