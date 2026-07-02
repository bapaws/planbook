import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_planbook/app/activity/model/app_activity_notice.dart';
import 'package:flutter_planbook/app/activity/notice/app_activity_notice_resolver.dart';
import 'package:flutter_planbook/app/activity/notice/app_activity_redeem_status_loader.dart';
import 'package:flutter_planbook/app/activity/repository/app_activity_repository.dart';
import 'package:planbook_repository/planbook_repository.dart';

part 'app_activity_event.dart';
part 'app_activity_state.dart';

class AppActivityBloc extends Bloc<AppActivityEvent, AppActivityState> {
  AppActivityBloc({
    required AppActivityRepository appActivityRepository,
    required SettingsRepository settingsRepository,
  }) : _appActivityRepository = appActivityRepository,
       _settingsRepository = settingsRepository,
       super(const AppActivityState()) {
    on<AppActivityRequested>(_onRequested);
    on<AppActivityFetched>(_onFetched, transformer: restartable());
    on<AppActivityLocaleChanged>(_onLocaleChanged, transformer: restartable());
    on<AppActivityNoticesRefreshed>(
      _onNoticesRefreshed,
      transformer: restartable(),
    );
    on<AppActivityNotShowAgain>(_onNotShowAgain);
    on<AppActivityWillShow>(_onWillShow);
    _syncLocale();
  }

  final AppActivityRepository _appActivityRepository;
  final SettingsRepository _settingsRepository;

  AppActivityRedeemSnapshot _redeemSnapshot = const AppActivityRedeemSnapshot();
  bool _listeningToActivityStream = false;

  void _syncLocale() {
    _appActivityRepository.updateLocale(_settingsRepository.getLocale());
  }

  List<AppActivityNotice> _resolveNotices(
    List<ActivityMessageEntity> activities,
  ) {
    return AppActivityNoticeResolver.resolve(
      activities: activities,
      redeemSnapshot: _redeemSnapshot,
    );
  }

  Future<void> _loadRedeemAndResolve(
    Emitter<AppActivityState> emit, {
    required List<ActivityMessageEntity> activities,
    bool? isReleasedVersion,
  }) async {
    _redeemSnapshot = await AppActivityRedeemStatusLoader.load(
      _appActivityRepository,
    );
    emit(
      state.copyWith(
        activities: activities,
        isReleasedVersion: isReleasedVersion,
        notices: _resolveNotices(activities),
      ),
    );
  }

  Future<void> _onRequested(
    AppActivityRequested event,
    Emitter<AppActivityState> emit,
  ) async {
    final isReleasedVersion = await _appActivityRepository.appStoreRepository
        .isReleaseVersion();
    emit(state.copyWith(isReleasedVersion: isReleasedVersion));

    await emit.forEach(
      _appActivityRepository.onActivityChange,
      onData: (activities) => state.copyWith(
        activities: activities,
        notices: _resolveNotices(activities),
      ),
    );
  }

  Future<void> _onFetched(
    AppActivityFetched event,
    Emitter<AppActivityState> emit,
  ) async {
    final activities = await _appActivityRepository.fetch(isNew: event.isNew);
    final isReleasedVersion = await _appActivityRepository.appStoreRepository
        .isReleaseVersion();
    await _loadRedeemAndResolve(
      emit,
      activities: activities,
      isReleasedVersion: isReleasedVersion,
    );

    if (!_listeningToActivityStream) {
      _listeningToActivityStream = true;
      add(const AppActivityRequested());
    }
  }

  Future<void> _onLocaleChanged(
    AppActivityLocaleChanged event,
    Emitter<AppActivityState> emit,
  ) async {
    _appActivityRepository.updateLocale(event.locale);
    final activities = await _appActivityRepository.fetch();
    await _loadRedeemAndResolve(emit, activities: activities);
  }

  Future<void> _onNoticesRefreshed(
    AppActivityNoticesRefreshed event,
    Emitter<AppActivityState> emit,
  ) async {
    _redeemSnapshot = await AppActivityRedeemStatusLoader.load(
      _appActivityRepository,
    );
    emit(
      state.copyWith(
        notices: _resolveNotices(state.activities),
      ),
    );
  }

  Future<void> _onNotShowAgain(
    AppActivityNotShowAgain event,
    Emitter<AppActivityState> emit,
  ) async {
    _appActivityRepository.notShowAgain(event.message);
    final activities = state.activities
        .where((activity) => activity.id != event.message.id)
        .toList();
    emit(
      state.copyWith(
        activities: activities,
        notices: _resolveNotices(activities),
      ),
    );
  }

  Future<void> _onWillShow(
    AppActivityWillShow event,
    Emitter<AppActivityState> emit,
  ) async {
    _appActivityRepository.willShow(event.message, event.date);
    final activities = state.activities
        .where((activity) => activity.id != event.message.id)
        .toList();
    emit(
      state.copyWith(
        activities: activities,
        notices: _resolveNotices(activities),
      ),
    );
  }
}
