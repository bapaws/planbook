import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'mine_profile_state.dart';

class MineProfileCubit extends Cubit<MineProfileState> {
  MineProfileCubit({
    required UsersRepository usersRepository,
    required AssetsRepository assetsRepository,
  }) : _usersRepository = usersRepository,
       _assetsRepository = assetsRepository,
       super(MineProfileState(user: usersRepository.user));

  final UsersRepository _usersRepository;
  final AssetsRepository _assetsRepository;

  Future<void> onFetched() async {}

  Future<void> onNameChanged(String name) async {
    await _usersRepository.updateUserProfile(username: name);
    emit(state.copyWith(user: _usersRepository.user));
  }

  Future<void> onAvatarChanged() async {
    try {
      // 设置加载状态
      emit(state.copyWith(isUpdatingAvatar: true));

      // 选择图片
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) {
        emit(state.copyWith(isUpdatingAvatar: false));
        return;
      }

      // 裁剪图片为正方形
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: '',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile == null) {
        emit(state.copyWith(isUpdatingAvatar: false));
        return;
      }

      // 上传头像
      final avatarUrl = await _assetsRepository.uploadImage(
        croppedFile.path,
        ResBucket.userAvatars,
      );

      // 更新用户头像
      await _usersRepository.updateUserProfile(avatar: avatarUrl);

      if (state.user?.avatar != null) {
        unawaited(
          _assetsRepository.removeImages([
            state.user!.avatar!,
          ], ResBucket.userAvatars),
        );
      }

      // 更新本地状态
      emit(
        state.copyWith(
          user: _usersRepository.user,
          isUpdatingAvatar: false,
        ),
      );
    } on Exception catch (_) {
      emit(state.copyWith(isUpdatingAvatar: false));
    }
  }

  Future<void> onBirthdayChanged(DateTime birthday) async {
    emit(state.copyWith(birthday: birthday));
  }

  Future<void> onBirthdaySubmitted() async {
    await _usersRepository.updateUserProfile(birthday: state.birthday);
    emit(state.copyWith(user: _usersRepository.user));
  }

  Future<void> onGenderChanged(UserGender gender) async {
    emit(state.copyWith(gender: gender));
  }

  Future<void> onGenderSubmitted() async {
    await _usersRepository.updateUserProfile(gender: state.gender);
    emit(state.copyWith(user: _usersRepository.user));
  }

  void onDeleteAccountConfirmationChanged(String value) {
    emit(state.copyWith(deleteAccountConfirmation: value));
  }

  void onLogout() {
    _usersRepository.logout();
  }

  void onDeleted() {
    _usersRepository.deleteUser();
  }
}
