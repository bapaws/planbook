part of 'mine_delete_cubit.dart';

final class MineDeleteState extends Equatable {
  const MineDeleteState({
    this.confirmText = '',
    this.status = PageStatus.initial,
  });

  final PageStatus status;
  final String confirmText;

  @override
  List<Object> get props => [confirmText, status];

  MineDeleteState copyWith({
    String? confirmText,
    PageStatus? status,
  }) {
    return MineDeleteState(
      confirmText: confirmText ?? this.confirmText,
      status: status ?? this.status,
    );
  }
}
