import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_planbook/app/model/app_seed_colors.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:flutter_planbook/settings/icon/model/app_icons.dart';
import 'package:planbook_api/database/color_scheme_converter.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:uuid/uuid.dart';

part 'app_event.dart';
part 'app_state.dart';

const kAppGroupId = 'group.GM4766U38W.com.bapaws.planbook';
const kAppUrlScheme = 'planbook.bapaws';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required SettingsRepository settingsRepository,
    required TagsRepository tagsRepository,
    required TasksRepository tasksRepository,
    required UsersRepository usersRepository,
  }) : _settingsRepository = settingsRepository,
       _tagsRepository = tagsRepository,
       _tasksRepository = tasksRepository,
       _usersRepository = usersRepository,
       super(
         const AppState(
           darkMode: DarkMode.light,
           appIcons: AppIcons.green,
           seedColor: AppSeedColors.green,
         ),
       ) {
    on<AppInitialized>(_onInitialized);
    on<AppLaunched>(_onLaunched);
    on<AppUserRequested>(_onUserProfileRequested);
    on<AppDarkModeChanged>(_onDarkModeChanged);
    on<AppSeedColorChanged>(_onSeedColorChanged);
  }

  final SettingsRepository _settingsRepository;
  final TagsRepository _tagsRepository;
  final TasksRepository _tasksRepository;

  final UsersRepository _usersRepository;

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

    final appIconName = _settingsRepository.getAppIconName();
    emit(
      AppState(
        darkMode: darkMode,
        seedColor: seedColor,
        appIcons: appIconName == null
            ? AppIcons.green
            : AppIcons.fromName(appIconName),
      ),
    );
  }

  Future<void> _onLaunched(
    AppLaunched event,
    Emitter<AppState> emit,
  ) async {
    // Create default tags and sample tasks on first launch
    if (_usersRepository.isFirstLaunch) {
      final languageCode = event.l10n.localeName.split('_').first;
      final tagJsonString = await rootBundle.loadString(
        'assets/files/tags_$languageCode.json',
      );
      final tagJson = jsonDecode(tagJsonString) as List<dynamic>;

      const uuid = Uuid();
      for (final json in tagJson) {
        final tag = Tag.fromJson(json as Map<String, dynamic>);
        final color = tag.color?.toColor ?? material.Colors.yellow;

        await _tagsRepository.createTag(
          id: uuid.v4(),
          name: tag.name,
          lightColorScheme: ColorScheme.fromColorScheme(
            material.ColorScheme.fromSeed(
              seedColor: color,
            ),
          ),
          darkColorScheme: ColorScheme.fromColorScheme(
            material.ColorScheme.fromSeed(
              seedColor: color,
              brightness: material.Brightness.dark,
            ),
          ),
        );
      }

      final taskJsonString = await rootBundle.loadString(
        'assets/files/tasks_$languageCode.json',
      );
      final taskJson = jsonDecode(taskJsonString) as List<dynamic>;
      for (final json in taskJson) {
        final map = json as Map<String, dynamic>;
        final taskMap = map['task'] as Map<String, dynamic>;
        var task = Task.fromJson(taskMap).copyWith(id: uuid.v4());

        /// If dueAt is not null, set it to today
        if (taskMap['dueAt'] != null) {
          task = task.copyWith(dueAt: Value(Jiffy.now()));
        }
        final tagNames = List<String>.from(map['tags'] as List<dynamic>);
        final tags = await Future.wait(
          tagNames.map(_tagsRepository.getTagEntityByName),
        );
        await _tasksRepository.create(task: task, tags: tags.nonNulls.toList());
      }
    }

    final now = DateTime.now().toUtc();
    await _usersRepository.updateUserProfile(
      lastLaunchAppAt: now,
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
}
