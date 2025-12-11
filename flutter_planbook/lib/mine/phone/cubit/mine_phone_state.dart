part of 'mine_phone_cubit.dart';

final class MinePhoneState extends Equatable {
  const MinePhoneState({
    this.status = PageStatus.initial,
    this.phone,
    this.code,
    this.canSendCode = false,
    this.isSent = false,
  });

  final PageStatus status;
  final String? phone;
  final String? code;
  final bool canSendCode;
  final bool isSent;

  @override
  List<Object?> get props => [
    status,
    phone,
    code,
    canSendCode,
    isSent,
  ];

  MinePhoneState copyWith({
    PageStatus? status,
    String? phone,
    String? code,
    bool? canSendCode,
    bool? isSent,
  }) {
    return MinePhoneState(
      status: status ?? this.status,
      phone: phone ?? this.phone,
      code: code ?? this.code,
      canSendCode: canSendCode ?? this.canSendCode,
      isSent: isSent ?? this.isSent,
    );
  }
}
