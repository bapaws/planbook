import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planbook_repository/users/users_repository.dart';

part 'sign_password_state.dart';

class SignPasswordCubit extends Cubit<SignPasswordState> {
  SignPasswordCubit({required UsersRepository usersRepository})
    : _usersRepository = usersRepository,
      super(SignPasswordInitial());

  final UsersRepository _usersRepository;

  Future<void> resetPassword({required String email}) async {
    emit(SignPasswordLoading());

    try {
      await _usersRepository.resetPasswordForEmail(email);
      emit(SignPasswordSuccess());
    } on Exception catch (e) {
      emit(SignPasswordFailure(e.toString()));
    }
  }
}
