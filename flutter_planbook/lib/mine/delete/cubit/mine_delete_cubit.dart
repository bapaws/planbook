import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'mine_delete_state.dart';

class MineDeleteCubit extends Cubit<MineDeleteState> {
  MineDeleteCubit({
    required UsersRepository usersRepository,
    required AppLocalizations l10n,
  }) : _usersRepository = usersRepository,
       _l10n = l10n,
       super(const MineDeleteState());

  final UsersRepository _usersRepository;
  final AppLocalizations _l10n;

  void onConfirmTextChanged(String value) {
    emit(state.copyWith(confirmText: value));
  }

  Future<void> onDeleted() async {
    if (state.confirmText != _l10n.deleteAccount) {
      emit(state.copyWith(status: PageStatus.failure));
      return;
    }

    emit(state.copyWith(status: PageStatus.loading));

    await _usersRepository.deleteUser();
    emit(state.copyWith(status: PageStatus.success));
  }
}
