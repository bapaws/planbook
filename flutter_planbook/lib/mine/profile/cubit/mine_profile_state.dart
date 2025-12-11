part of 'mine_profile_cubit.dart';

final class MineProfileState extends Equatable {
  MineProfileState({
    this.user,
    this.isUpdatingAvatar = false,
    this.deleteAccountConfirmation,
    DateTime? birthday,
    UserGender? gender,
  }) : birthday = birthday ?? user?.birthday ?? DateTime(2010),
       gender = gender ?? user?.gender ?? UserGender.unknown;

  final UserEntity? user;
  final bool isUpdatingAvatar;

  final DateTime? birthday;
  final UserGender? gender;

  final String? deleteAccountConfirmation;

  MineProfileState copyWith({
    UserEntity? user,
    bool? isUpdatingAvatar,
    DateTime? birthday,
    UserGender? gender,
    String? deleteAccountConfirmation,
  }) {
    return MineProfileState(
      user: user ?? this.user,
      isUpdatingAvatar: isUpdatingAvatar ?? this.isUpdatingAvatar,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      deleteAccountConfirmation:
          deleteAccountConfirmation ?? this.deleteAccountConfirmation,
    );
  }

  @override
  List<Object?> get props => [
    user,
    isUpdatingAvatar,
    birthday,
    deleteAccountConfirmation,
    gender,
  ];
}
