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

  void sendCode(String email) {
    if (email.trim() == _usersRepository.user?.email) {
      emit(state.copyWith(status: PageStatus.failure));
      Fluttertoast.showToast(
        msg: _l10n.emailSameAsCurrent,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    emit(state.copyWith(status: PageStatus.loading, isSent: true));
    _usersRepository.updateUser(email: email);
  }

  void verifyCode(String email, String code) {
    emit(state.copyWith(status: PageStatus.loading, isSent: false));
    _usersRepository.verifyOTP(
      type: OtpType.emailChange,
      email: email,
      captchaToken: code,
    );
  }
}
