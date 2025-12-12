import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

part 'sign_home_state.dart';

class SignHomeCubit extends Cubit<SignHomeState> {
  SignHomeCubit() : super(const SignHomeState());

  void onInitialized() {
    FlutterNativeSplash.remove();
  }

  void signInWithPhone() {
    // 默认使用验证码登录
    emit(state.copyWith(status: SignHomeStatus.signInWithPhone));
  }

  void signInWithPassword() {
    emit(state.copyWith(status: SignHomeStatus.signInWithPassword));
  }

  void signInWithCode() {
    emit(state.copyWith(status: SignHomeStatus.signInWithPhone));
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
}
