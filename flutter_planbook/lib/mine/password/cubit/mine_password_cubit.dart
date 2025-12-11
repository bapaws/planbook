import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'mine_password_state.dart';

class MinePasswordCubit extends Cubit<MinePasswordState> {
  MinePasswordCubit({
    required UsersRepository usersRepository,
    required AppLocalizations l10n,
  }) : _usersRepository = usersRepository,
       _l10n = l10n,
       super(const MinePasswordState());

  final UsersRepository _usersRepository;
  final AppLocalizations _l10n;

  void toggleObscureText() {
    emit(state.copyWith(obscureText: !state.obscureText));
  }

  void toggleComfirmObscureText() {
    emit(state.copyWith(comfirmObscureText: !state.comfirmObscureText));
  }

  void onUpdatePassword(String password) {
    emit(state.copyWith(password: password));
    _onUpdateIsValid();
  }

  void onUpdateComfirmPassword(String comfirmPassword) {
    emit(state.copyWith(comfirmPassword: comfirmPassword));
    _onUpdateIsValid();
  }

  void _onUpdateIsValid() {
    if (state.password != state.comfirmPassword) {
      emit(state.copyWith(isValid: false));
      return;
    }
    // 正则表达式：密码长度不小于6，且包含至少一个数字和一个字母
    final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$');
    if (!regex.hasMatch(state.password)) {
      emit(state.copyWith(isValid: false));
      return;
    }
    emit(state.copyWith(isValid: true));
  }

  Future<String?> onSubmited() async {
    emit(state.copyWith(status: PageStatus.loading));
    try {
      if (state.password != state.comfirmPassword) {
        emit(state.copyWith(status: PageStatus.failure));
        return _l10n.passwordNotMatch;
      }
      // 正则表达式：密码长度不小于6，且包含至少一个数字和一个字母
      final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$');
      if (!regex.hasMatch(state.password)) {
        emit(state.copyWith(status: PageStatus.failure));
        return _l10n.passwordInvalid;
      }
      await _usersRepository.updateUser(
        password: state.password,
      );
      emit(state.copyWith(status: PageStatus.success));
      return null;
    } on Exception catch (e) {
      emit(state.copyWith(status: PageStatus.failure));
      return e.toString();
    }
  }
}
