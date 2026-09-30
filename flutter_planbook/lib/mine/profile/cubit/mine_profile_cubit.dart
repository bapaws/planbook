import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as image;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planbook_core/data/page_status.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'mine_profile_state.dart';

class MineProfileCubit extends Cubit<MineProfileState> {
  factory MineProfileCubit({
    required UsersRepository usersRepository,
    required AssetsRepository assetsRepository,
  }) => MineProfileCubit._(usersRepository, assetsRepository);

  MineProfileCubit._(this._usersRepository, this._assetsRepository)
    : super(MineProfileState(user: _usersRepository.user));

  final UsersRepository _usersRepository;
  final AssetsRepository _assetsRepository;

  static const _avatarDimension = 512;
  static const _avatarQuality = 88;

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
      );

      if (image == null) {
        emit(state.copyWith(isUpdatingAvatar: false));
        return;
      }

      // 裁剪图片为正方形
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        maxWidth: _avatarDimension,
        maxHeight: _avatarDimension,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 100,
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

      // 裁剪插件只保证最大尺寸；统一缩放为固定尺寸，确保各端头像清晰且体积可控。
      final avatarFile = await _normalizeAvatar(croppedFile.path);

      // 上传头像
      final avatarUrl = await _assetsRepository.uploadImage(
        avatarFile.path,
        ResBucket.userAvatars,
      );

      // 更新用户头像
      await _usersRepository.updateUserProfile(avatar: avatarUrl);

      final previousAvatar = state.user?.avatar;
      if (previousAvatar != null &&
          previousAvatar.contains(AssetsRepository.host)) {
        unawaited(
          _assetsRepository.removeImages([
            previousAvatar,
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

  Future<File> _normalizeAvatar(String path) async {
    final file = File(path);
    final decoded = image.decodeImage(await file.readAsBytes());
    if (decoded == null) {
      throw const FormatException('Invalid avatar image');
    }

    final resized = image.copyResize(
      decoded,
      width: _avatarDimension,
      height: _avatarDimension,
      interpolation: image.Interpolation.cubic,
    );
    await file.writeAsBytes(
      image.encodeJpg(resized, quality: _avatarQuality),
      flush: true,
    );
    return file;
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

  Future<void> onLogout() async {
    emit(state.copyWith(status: PageStatus.loading));
    await _usersRepository.logout();
    emit(state.copyWith(status: PageStatus.dispose));
  }

  Future<void> linkWeChat() async {
    emit(state.copyWith(status: PageStatus.loading));
    try {
      await _usersRepository.linkWeChat();
      emit(
        state.copyWith(
          user: _usersRepository.user,
          status: PageStatus.success,
        ),
      );
    } on Exception catch (e) {
      emit(state.copyWith(status: PageStatus.failure));
      final message = _resolveLinkErrorMessage(e);
      if (message != null) {
        unawaited(
          Fluttertoast.showToast(
            msg: message,
            gravity: ToastGravity.CENTER,
          ),
        );
      }
    }
  }

  String? _resolveLinkErrorMessage(Exception e) {
    final message = e.toString();
    if (message.contains('409') || message.contains('该微信已绑定其他账号')) {
      return '该微信已绑定其他账号';
    }
    if (message.contains('WeChat is not installed')) {
      return '未安装微信';
    }
    if (message.contains('cancelled')) {
      return null;
    }
    return '微信绑定失败';
  }

  void onDeleted() {
    _usersRepository.deleteUser();
  }
}
