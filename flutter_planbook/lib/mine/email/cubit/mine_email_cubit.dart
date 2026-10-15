import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'mine_email_state.dart';

class MineEmailCubit extends Cubit<MineEmailState> {
  MineEmailCubit({
    required UsersRepository usersRepository,
    required AppLocalizations l10n,
  }) : _usersRepository = usersRepository,
       _l10n = l10n,
       super(const MineEmailState());

  final UsersRepository _usersRepository;
  final AppLocalizations _l10n;

  void setEmail(String email) {
    emit(state.copyWith(email: email));
  }

  void setCode(String code) {
    emit(state.copyWith(code: code));
  }

  Future<bool> sendCode(String email) async {
    if (email.trim() == _usersRepository.user?.email) {
      Fluttertoast.showToast(
        msg: _l10n.emailSameAsCurrent,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return false;
    }

    emit(state.copyWith(status: PageStatus.loading, isSent: false));
    try {
      await _usersRepository.updateUser(email: email);
      emit(state.copyWith(status: PageStatus.initial, isSent: true));
      Fluttertoast.showToast(
        msg: _l10n.codeSentSuccess,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return true;
    } on Exception catch (error) {
      emit(state.copyWith(status: PageStatus.initial, isSent: false));
      Fluttertoast.showToast(
        msg: error.toString(),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
      );
      return false;
    }
  }

  Future<void> verifyCode(String email, String code) async {
    emit(state.copyWith(status: PageStatus.loading, isSent: false));
    try {
      await _usersRepository.verifyOTP(
        type: OtpType.emailChange,
        email: email,
        token: code,
      );
      emit(state.copyWith(status: PageStatus.success));
    } on Exception catch (error) {
      emit(state.copyWith(status: PageStatus.initial));
      Fluttertoast.showToast(
        msg: error.toString(),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
      );
    }
  }
}
