import 'dart:io';

import 'package:database_planbook_api/task/recurrence_rule_calculator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 为任务的 [EventAlarm] 调度本地通知，在闹钟触发时提醒用户。
///
/// 单例，通过 [AlarmNotificationService.instance] 或 `AlarmNotificationService()`
/// 获取。插件采用延迟初始化：不在应用启动时初始化，仅在首次需要时（如用户点击
/// 「提醒」或首次调度/取消闹钟）再初始化，避免未登录或首次启动就触发权限或插件逻辑。
///
/// 使用时机：
/// - 创建任务后：在 [TasksRepository.create] 成功后调用 [scheduleForTask]
/// - 更新任务后：先 [cancelForTask]，再 [scheduleForTask]
/// - 删除任务后：调用 [cancelForTask]
/// - 从 Supabase 同步任务后：在 [TasksRepository.syncTasks] 中调用 [scheduleForTask]
class AlarmNotificationService implements TaskAlarmScheduler {
  AlarmNotificationService._();

  static final AlarmNotificationService instance = AlarmNotificationService._();

  static const _channelId = 'task_alarm';

  /// 渠道名称与描述，供应用层注入国际化文案；未设置时使用默认中文。
  String? _channelName;
  String? _channelDescription;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 每个任务最多支持的闹钟数量，用于取消时遍历 id
  static const int _maxAlarmsPerTask = 20;

  /// 重复任务最多预约的 occurrence 数量（避免通知过多）
  static const int _maxScheduledOccurrences = 50;

  /// 重复任务预约的时间范围（天）
  static const int _scheduleRangeDays = 60;

  /// 设置通知渠道的本地化名称与描述（应在进入主页等有 l10n 的时机调用）。
  void setChannelStrings({String? name, String? description}) {
    if (name != null) _channelName = name;
    if (description != null) _channelDescription = description;
  }

  String get _effectiveChannelName => _channelName ?? '任务提醒';
  String get _effectiveChannelDescription => _channelDescription ?? '任务开始前的提醒';

  /// 根据任务 id、occurrence 下标、闹钟下标生成稳定的通知 id（用于取消）
  /// 非重复任务固定使用 occurrenceIndex = 0。
  static int _notificationId(
    String taskId,
    int occurrenceIndex,
    int alarmIndex,
  ) {
    return Object.hash(taskId, occurrenceIndex, alarmIndex) & 0x7FFFFFFF;
  }

  /// 不请求通知权限；权限在 [requestPermissionIfNeeded] 中按需请求。
  Future<void> _initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    if (!Platform.isAndroid && !Platform.isIOS) {
      _initialized = true;
      return;
    }

    tz_data.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    // 不在 init 时请求权限，避免未登录或首次启动就弹窗；由 [requestPermissionIfNeeded] 按需请求
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    final androidChannel = AndroidNotificationChannel(
      _channelId,
      _effectiveChannelName,
      description: _effectiveChannelDescription,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    // 可选：根据 response.payload 跳转到任务详情
  }

  /// 按需请求通知权限。应在用户点击「提醒」按钮时调用。
  /// 首次调用会先延迟初始化插件，再请求权限。
  /// 返回 true 表示已授权，false 表示未授权，null 表示非移动端或未初始化。
  Future<bool?> requestPermissionIfNeeded() async {
    await _initialize();

    if (!_initialized || kIsWeb) return null;
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
    }
    if (Platform.isIOS) {
      return _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, sound: true, badge: true);
    }
    return null;
  }

  /// 为任务的所有闹钟调度本地通知。
  ///
  /// 非重复任务：按 [Task.startAt] 调度一次。
  /// 重复任务：为未来 [ _scheduleRangeDays] 天内、最多 [ _maxScheduledOccurrences]
  /// 个 occurrence 各调度一次提醒（每次重复都提醒）。
  /// 会先取消该任务已有的闹钟通知，再按当前 alarms 重新调度。
  /// 首次调用会先延迟初始化插件。
  @override
  Future<void> scheduleForTask(Task task) async {
    await _initialize();
    if (!_initialized || kIsWeb) return;

    final startAt = task.startAt ?? task.dueAt;
    if (startAt == null || task.alarms.isEmpty) return;

    await cancelForTask(task.id);

    final now = Jiffy.now();

    if (task.recurrenceRule != null) {
      await _scheduleRecurringTask(task, startAt, now);
    } else {
      await _scheduleSingleOccurrence(task, startAt, now, occurrenceIndex: 0);
    }
  }

  /// 为单个 occurrence 调度该任务的所有闹钟（供单次任务或重复任务的一个 occurrence 使用）
  Future<void> _scheduleSingleOccurrence(
    Task task,
    Jiffy occurrenceStartAt,
    Jiffy now, {
    required int occurrenceIndex,
  }) async {
    for (var i = 0; i < task.alarms.length; i++) {
      final alarm = task.alarms[i];
      final triggerAt = alarm.resolveTriggerTime(
        occurrenceStartAt,
        isAllDay: task.isAllDay,
      );
      if (triggerAt == null || !triggerAt.isAfter(now)) continue;

      final id = _notificationId(task.id, occurrenceIndex, i);
      await _scheduleOne(id, task.title, triggerAt);
    }
  }

  /// 重复任务：生成未来 occurrence 并为每个 occurrence 调度提醒
  Future<void> _scheduleRecurringTask(
    Task task,
    Jiffy seriesStartAt,
    Jiffy now,
  ) async {
    final rule = task.recurrenceRule!;
    final rangeStart = now.startOf(Unit.day);
    final rangeEnd = now.add(days: _scheduleRangeDays);

    final occurrenceDates = RecurrenceRuleCalculator.generateOccurrences(
      rule: rule,
      startDate: seriesStartAt,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    final toSchedule = occurrenceDates.take(_maxScheduledOccurrences).toList();

    for (var occIndex = 0; occIndex < toSchedule.length; occIndex++) {
      final occurrenceDay = toSchedule[occIndex];
      final occurrenceStartAt = task.isAllDay
          ? occurrenceDay.startOf(Unit.day)
          : occurrenceDay
                .startOf(Unit.day)
                .add(
                  hours: seriesStartAt.hour,
                  minutes: seriesStartAt.minute,
                  seconds: seriesStartAt.second,
                );
      await _scheduleSingleOccurrence(
        task,
        occurrenceStartAt,
        now,
        occurrenceIndex: occIndex,
      );
    }
  }

  Future<void> _scheduleOne(int id, String title, Jiffy triggerAt) async {
    final tzDate = tz.TZDateTime.from(triggerAt.dateTime, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _effectiveChannelName,
        channelDescription: _effectiveChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        null,
        tzDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on Exception catch (e) {
      debugPrint('AlarmNotificationService: schedule failed id=$id $e');
    }
  }

  /// 取消该任务已调度的所有闹钟通知（含重复任务的所有 occurrence）。若插件尚未初始化则无操作。
  @override
  Future<void> cancelForTask(String taskId) async {
    await _initialize();
    if (!_initialized || kIsWeb) return;

    for (var occIndex = 0; occIndex < _maxScheduledOccurrences; occIndex++) {
      for (var alarmIndex = 0; alarmIndex < _maxAlarmsPerTask; alarmIndex++) {
        final id = _notificationId(taskId, occIndex, alarmIndex);
        try {
          await _plugin.cancel(id);
        } on Object catch (_) {}
      }
    }
  }
}
