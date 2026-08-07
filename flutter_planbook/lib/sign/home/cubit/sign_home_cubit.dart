import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/users/users_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'sign_home_state.dart';

class SignHomeCubit extends Cubit<SignHomeState> {
  SignHomeCubit({required UsersRepository usersRepository})
    : _usersRepository = usersRepository,
      super(const SignHomeState());

  final UsersRepository _usersRepository;

  Future<void> onInitialized() async {
    // 鸿蒙首版隐藏所有第三方登录（华为审核要求三方登录须搭配华为登录，
    // 首版未接入 Account Kit），跳过微信安装检测使主按钮回退为验证码/邮箱登录
    if (kIsOhos) return;
    final installed = await _usersRepository.isWeChatInstalled();
    emit(state.copyWith(isWeChatInstalled: installed));
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
    final authResponse = await _usersRepository.signInWithApple();
    if (authResponse != null) {
      emit(state.copyWith(authResponse: authResponse));
    }
  }

  Future<void> signInWithGoogle() async {
    final authResponse = await _usersRepository.signInWithGoogle();
    if (authResponse != null) {
      emit(state.copyWith(authResponse: authResponse));
    }
  }

  Future<void> signInWithWeChat() async {
    emit(state.copyWith(isWeChatLoading: true));
    try {
      final authResponse = await _usersRepository.signInWithWeChat();
      if (authResponse != null) {
        emit(
          state.copyWith(
            authResponse: authResponse,
            isWeChatLoading: false,
          ),
        );
      } else {
        emit(state.copyWith(isWeChatLoading: false));
      }
    } on Exception catch (e) {
      if (kDebugMode) print('signInWithWeChat 错误: $e');
      emit(state.copyWith(isWeChatLoading: false));
      rethrow;
    }
  }
}
