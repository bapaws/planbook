part of 'mine_email_cubit.dart';

final class MineEmailState extends Equatable {
  const MineEmailState({
    this.status = PageStatus.initial,
    this.email,
    this.code,
    this.canSendCode = false,
    this.isSent = false,
  });

  final PageStatus status;
  final String? email;
  final String? code;
  final bool canSendCode;
  final bool isSent;

  @override
  List<Object?> get props => [
    status,
    email,
    code,
    canSendCode,
    isSent,
  ];

  MineEmailState copyWith({
    PageStatus? status,
    String? email,
    String? code,
    bool? canSendCode,
    bool? isSent,
  }) {
    return MineEmailState(
      status: status ?? this.status,
      email: email ?? this.email,
      code: code ?? this.code,
      canSendCode: canSendCode ?? this.canSendCode,
      isSent: isSent ?? this.isSent,
    );
  }
}
