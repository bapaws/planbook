part of 'mine_password_cubit.dart';

class MinePasswordState extends Equatable {
  const MinePasswordState({
    this.status = PageStatus.initial,
    this.obscureText = true,
    this.comfirmObscureText = true,
    this.password = '',
    this.comfirmPassword = '',
    this.isValid = false,
  });

  final PageStatus status;

  final String password;
  final String comfirmPassword;

  final bool obscureText;
  final bool comfirmObscureText;

  final bool isValid;

  @override
  List<Object> get props => [
    status,
    obscureText,
    comfirmObscureText,
    password,
    comfirmPassword,
    isValid,
  ];

  MinePasswordState copyWith({
    PageStatus? status,
    bool? obscureText,
    bool? comfirmObscureText,
    String? password,
    String? comfirmPassword,
    bool? isValid,
  }) {
    return MinePasswordState(
      status: status ?? this.status,
      obscureText: obscureText ?? this.obscureText,
      comfirmObscureText: comfirmObscureText ?? this.comfirmObscureText,
      password: password ?? this.password,
      comfirmPassword: comfirmPassword ?? this.comfirmPassword,
      isValid: isValid ?? this.isValid,
    );
  }
}
