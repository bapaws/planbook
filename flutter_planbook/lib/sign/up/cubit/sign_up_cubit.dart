import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_repository/users/users_repository.dart';

part 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit({required UsersRepository usersRepository})
    : _usersRepository = usersRepository,
      super(SignUpInitial());

  final UsersRepository _usersRepository;

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    emit(SignUpLoading());

    try {
      // 验证密码确认
      if (password != confirmPassword) {
        emit(const SignUpFailure('密码不匹配'));
        return;
      }

      // 验证密码强度
      if (password.length < 6) {
        emit(const SignUpFailure('密码长度至少6位'));
        return;
      }

      await _usersRepository.signUp(
        name: email, // 使用邮箱作为用户名
        password: password,
        data: {
          'name': name,
        },
      );
      emit(SignUpSuccess());
    } on Exception catch (e) {
      emit(SignUpFailure(e.toString()));
    }
  }
}
