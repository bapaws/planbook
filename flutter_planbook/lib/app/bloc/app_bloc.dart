import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_planbook/app/model/app_seed_colors.dart';
import 'package:flutter_planbook/core/apk_download_service.dart';
import 'package:flutter_planbook/core/model/app_channel.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_event.dart';
part 'app_state.dart';

const kAppGroupId = 'group.GM4766U38W.com.bapaws.planbook';
const kAppUrlScheme = 'planbook.bapaws';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required SettingsRepository settingsRepository,
    required TagsRepository tagsRepository,
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
    required UsersRepository usersRepository,
    required SharedPreferences sp,
  }) : _settingsRepository = settingsRepository,
       _tagsRepository = tagsRepository,
       _tasksRepository = tasksRepository,
       _notesRepository = notesRepository,
       _usersRepository = usersRepository,
       _sp = sp,
       super(
         const AppState(
           darkMode: DarkMode.light,
           seedColor: AppSeedColors.green,
         ),
       ) {
    on<AppInitialized>(_onInitialized);
    on<AppLaunched>(_onLaunched);
    on<AppUserRequested>(_onUserProfileRequested);
    on<AppDarkModeChanged>(_onDarkModeChanged);
    on<AppSeedColorChanged>(_onSeedColorChanged);
    on<AppBackgroundRequested>(_onBackgroundRequested);
    on<AppApkVersionRequested>(_onApkVersionRequested);
    on<AppApkDownloadRequested>(_onApkDownloadRequested);
    on<AppApkDownloadProgressUpdated>(_onApkDownloadProgressUpdated);
  }

  final SettingsRepository _settingsRepository;
  final TagsRepository _tagsRepository;
  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;

  final UsersRepository _usersRepository;
  final SharedPreferences _sp;

  StreamSubscription<double>? _apkProgressSub;
  AppLocalizations? _apkL10n;

  @override
  Future<void> close() async {
    unawaited(_apkProgressSub?.cancel());
    await super.close();
  }

  Future<void> _onInitialized(
    AppInitialized event,
    Emitter<AppState> emit,
  ) async {
    final darkMode = _settingsRepository.getDarkMode();
    final seedColorHex = _settingsRepository.getSeedColorHex();
    final seedColor = seedColorHex == null
        ? AppSeedColors.green
        : AppSeedColors.fromHex(seedColorHex);

    final lightColorScheme = await _settingsRepository.getLightColorScheme();
    if (lightColorScheme == null) {
      final colorScheme = material.ColorScheme.fromSeed(
        seedColor: seedColor.color,
      );
      await _settingsRepository.saveLightColorScheme(colorScheme.toJson());
    }
    final darkColorScheme = await _settingsRepository.getDarkColorScheme();
    if (darkColorScheme == null) {
      final colorScheme = material.ColorScheme.fromSeed(
        seedColor: seedColor.color,
        brightness: material.Brightness.dark,
      );
      await _settingsRepository.saveDarkColorScheme(colorScheme.toJson());
    }

    /// Request background asset
    add(const AppBackgroundRequested());

    emit(
      AppState(
        darkMode: darkMode,
        seedColor: seedColor,
      ),
    );
  }

  /// 应用启动进入主页时触发
  Future<void> _onLaunched(
    AppLaunched event,
    Emitter<AppState> emit,
  ) async {
    // Create default tags and sample tasks on first launch
    if (_usersRepository.isFirstLaunch) {
      final languageCode = event.l10n.localeName.split('_').first;
      await _tagsRepository.createDefaultTags(languageCode: languageCode);
      await _tasksRepository.createDefaultTasks(languageCode: languageCode);
      // await _notesRepository.createDefaultNotes(languageCode: languageCode);
    } else if (kDebugMode) {
      const languageCode = 'zh';
      // await _tagsRepository.createDefaultTags(languageCode: languageCode);
      // await _tasksRepository.createDefaultTasks(languageCode: languageCode);
      // await _notesRepository.createDefaultNotes(languageCode: languageCode);
    }

    unawaited(
      _usersRepository.updateUserProfile(
        lastLaunchAppAt: DateTime.now(),
      ),
    );
  }

  Future<void> _onUserProfileRequested(
    AppUserRequested event,
    Emitter<AppState> emit,
  ) async {
    await emit.forEach(
      _usersRepository.onUserEntityChange,
      onData: (user) {
        // if (user != null && user.id != state.user?.id) {
        //   unawaited(_syncRepository.sync());
        // }
        return state.copyWith(user: user);
      },
    );
  }

  void _onDarkModeChanged(
    AppDarkModeChanged event,
    Emitter<AppState> emit,
  ) {
    _settingsRepository.saveDarkMode(event.darkMode);
    emit(
      state.copyWith(
        darkMode: () => event.darkMode,
      ),
    );
  }

  Future<void> _onSeedColorChanged(
    AppSeedColorChanged event,
    Emitter<AppState> emit,
  ) async {
    await _settingsRepository.saveSeedColorHex(event.seedColor.hex);

    emit(
      state.copyWith(
        seedColor: event.seedColor,
      ),
    );

    final lightColorScheme = material.ColorScheme.fromSeed(
      seedColor: event.seedColor.color,
    );
    await _settingsRepository.saveLightColorScheme(lightColorScheme.toJson());
    final darkColorScheme = material.ColorScheme.fromSeed(
      seedColor: event.seedColor.color,
      brightness: material.Brightness.dark,
    );
    await _settingsRepository.saveDarkColorScheme(darkColorScheme.toJson());
  }

  Future<void> _onBackgroundRequested(
    AppBackgroundRequested event,
    Emitter<AppState> emit,
  ) async {
    await emit.forEach(
      _settingsRepository.onBackgroundAssetChange,
      onData: (background) => state.copyWith(background: background),
    );
  }

  Future<void> _onApkVersionRequested(
    AppApkVersionRequested event,
    Emitter<AppState> emit,
  ) async {
    if (!AppChannel.isCloud) return;
    if (kDebugMode) {
      emit(state.copyWith(apkVersion: '2.5.1', apkHasNewVersion: true));
      return;
    }
    final version = await ApkDownloadService.fetchVersion(_sp);
    if (version == null) return;
    final hasNew = await ApkDownloadService.hasNewVersion(version);
    emit(state.copyWith(apkVersion: version, apkHasNewVersion: hasNew));
  }

  Future<void> _onApkDownloadRequested(
    AppApkDownloadRequested event,
    Emitter<AppState> emit,
  ) async {
    if (!AppChannel.isCloud) return;
    _apkL10n = event.l10n;

    final version = state.apkVersion;
    if (version == null || version.isEmpty) {
      emit(
        state.copyWith(
          apkDownloadStatus: AppApkDownloadStatus.installError,
          apkDownloadErrorMessage: event.l10n.apkDownloadNoVersion,
        ),
      );
      return;
    }
    final hasNew = await ApkDownloadService.hasNewVersion(version);
    if (!hasNew) {
      emit(
        state.copyWith(
          apkDownloadStatus: AppApkDownloadStatus.installError,
          apkDownloadErrorMessage: event.l10n.apkDownloadNotNewer,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        apkDownloadStatus: AppApkDownloadStatus.downloading,
        apkDownloadProgress: 0,
        clearApkDownloadError: true,
      ),
    );

    final enqueued = await ApkDownloadService.downloadApk(version, _sp);
    if (!enqueued) {
      emit(
        state.copyWith(
          apkDownloadStatus: AppApkDownloadStatus.installError,
          apkDownloadErrorMessage: event.l10n.apkDownloadFailed,
        ),
      );
      return;
    }

    unawaited(_apkProgressSub?.cancel());
    _apkProgressSub = ApkDownloadService.progressStream.listen((p) {
      add(AppApkDownloadProgressUpdated(p));
    });
  }

  void _onApkDownloadProgressUpdated(
    AppApkDownloadProgressUpdated event,
    Emitter<AppState> emit,
  ) {
    if (!AppChannel.isCloud) return;
    if (state.apkDownloadStatus != AppApkDownloadStatus.downloading) return;
    final l10n = _apkL10n;

    if (event.progress < 0) {
      emit(
        state.copyWith(
          apkDownloadStatus: AppApkDownloadStatus.installError,
          apkDownloadErrorMessage: l10n?.apkDownloadFailed ?? 'Download failed',
        ),
      );
      _apkProgressSub?.cancel();
      _apkProgressSub = null;
      return;
    }
    emit(state.copyWith(apkDownloadProgress: event.progress));
    if (event.progress >= 1) {
      emit(
        state.copyWith(
          apkDownloadStatus: AppApkDownloadStatus.installSuccess,
          apkDownloadProgress: 1,
        ),
      );
      _apkProgressSub?.cancel();
      _apkProgressSub = null;
    }
  }
}
