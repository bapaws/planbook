import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/l10n/gen/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'mine_phone_state.dart';

class MinePhoneCubit extends Cubit<MinePhoneState> {
  MinePhoneCubit({
    required UsersRepository usersRepository,
    required AppLocalizations l10n,
  }) : _usersRepository = usersRepository,
       _l10n = l10n,
       super(const MinePhoneState());

  final UsersRepository _usersRepository;
  final AppLocalizations _l10n;

  void setPhone(String phone) {
    emit(state.copyWith(phone: phone));
  }

  void setCode(String code) {
    emit(state.copyWith(code: code));
  }

  Future<bool> sendCode(String phone) async {
    if (phone.trim() == _usersRepository.user?.phone) {
      Fluttertoast.showToast(
        msg: _l10n.phoneNumberSameAsCurrent,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return false;
    }

    emit(state.copyWith(status: PageStatus.loading, isSent: false));
    try {
      await _usersRepository.updateUser(phone: phone);
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

  Future<void> verifyCode(String phone, String code) async {
    emit(state.copyWith(status: PageStatus.loading, isSent: false));
    try {
      await _usersRepository.verifyOTP(
        type: OtpType.phoneChange,
        phone: phone,
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
