import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:database_planbook_api/task/recurrence_rule_calculator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planbook_repository/planbook_repository.dart';
import 'package:planbook_repository/task/alarm_reservation_store.dart';
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
  Future<void>? _initializing;
  Future<AlarmReservationReconciler>? _reconciler;
  Future<List<Task>> Function()? _loadTasks;
  Future<Task?> Function(String)? _loadTask;
  String? Function()? _account;
  final _queue = AlarmRequestQueue(
    onError: (error, stack) {
      // 原调用多为 unawaited；保留失败意图，下次全量校正继续重试。
      debugPrint('AlarmNotificationService: $error\n$stack');
    },
  );

  /// 由 composition root 注入权威本地数据，不能用过期页面快照重建预约。
  void configure({
    required Future<List<Task>> Function() loadTasks,
    required Future<Task?> Function(String) loadTask,
    required String? Function() account,
  }) {
    _loadTasks = loadTasks;
    _loadTask = loadTask;
    _account = account;
  }

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// 设置通知渠道的本地化名称与描述（应在进入主页等有 l10n 的时机调用）。
  void setChannelStrings({String? name, String? description}) {
    if (name != null) _channelName = name;
    if (description != null) _channelDescription = description;
  }

  String get _effectiveChannelName => _channelName ?? '任务提醒';
  String get _effectiveChannelDescription => _channelDescription ?? '任务开始前的提醒';

  /// 不请求通知权限；权限在 [requestPermissionIfNeeded] 中按需请求。
  Future<void> _initialize() {
    if (_initialized) return Future.value();
    return _initializing ??= _initializeOnce().whenComplete(() {
      _initializing = null;
    });
  }

  Future<void> _initializeOnce() async {
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

  Future<AlarmReservationReconciler> _getReconciler() async {
    await _initialize();
    return _reconciler ??= _createReconciler().catchError((
      Object error,
      StackTrace stack,
    ) {
      _reconciler = null;
      Error.throwWithStackTrace(error, stack);
    });
  }

  Future<AlarmReservationReconciler> _createReconciler() async {
    final directory = await getApplicationSupportDirectory();
    return AlarmReservationReconciler(
      store: FileAlarmReservationStore(
        File('${directory.path}/task_alarm_reservations_v1.json'),
      ),
      pending: () async => {
        for (final item in await _plugin.pendingNotificationRequests())
          item.id: item.payload,
      },
      activeIds: _activeIds,
      cancel: _plugin.cancel,
      schedule: _scheduleOne,
    );
  }

  Future<Set<int>> _activeIds() async {
    try {
      return {
        for (final item in await _plugin.getActiveNotifications())
          if (item.id case final int id) id,
      };
    } on PlatformException catch (error) {
      // Android 5.x 无此系统查询能力，仍保留账本和 pending 列表的碰撞检测。
      if (Platform.isAndroid && error.code == 'unsupported_os_version') {
        return {};
      }
      rethrow;
    }
  }

  void _validate(String? account) {
    if (_account == null || _loadTasks == null || _loadTask == null) {
      throw StateError('提醒服务尚未注入本地数据源');
    }
    if (_account!() != account) throw StateError('提醒账号已变化，停止旧请求');
  }

  Future<void> _enqueue(String key, Future<void> Function() action) {
    return _queue.run(key, action);
  }

  /// 同批校正共用系统列表，实际修改后再核对；启动与前台恢复共用此队列。
  Future<void> reconcileAll() {
    if (!_supported) return Future.value();
    final account = _account?.call();
    return _enqueue('all', () => _performAll(account));
  }

  Future<void> _performAll(String? account, {String? excludedTaskId}) async {
    _validate(account);
    final reconciler = await _getReconciler();
    final tasks = await _loadTasks!();
    _validate(account);
    final plans = await _plans(
      tasks.where((t) => t.id != excludedTaskId).toList(),
    );
    await reconciler.reconcile(
      plans,
      full: true,
      scopes: {},
      validate: () => _validate(account),
    );
  }

  Future<List<AlarmPlan>> _plans(List<Task> tasks) => compute(
    buildAlarmPlans,
    (
      tasks: tasks.map((task) => task.toJson()).toList(),
      now: DateTime.now().millisecondsSinceEpoch,
      zone: tz.local.name,
    ),
    debugLabel: 'task-alarm-plans',
  );

  @override
  Future<void> scheduleForTask(Task task) {
    if (!_supported) return Future.value();
    final account = _account?.call();
    if (task.userId != account) return Future.value();
    return _requestTask(task.id, account, cancel: false);
  }

  @override
  Future<void> cancelForTask(String taskId) {
    if (!_supported) return Future.value();
    return _requestTask(taskId, _account?.call(), cancel: true);
  }

  Future<void> _requestTask(
    String taskId,
    String? account, {
    required bool cancel,
  }) => _enqueue(
    jsonEncode([account, taskId]),
    () async {
      _validate(account);
      final reconciler = await _getReconciler();
      if (await reconciler.needsMigration()) {
        await _performAll(account, excludedTaskId: cancel ? taskId : null);
      }
      _validate(account);
      final task = cancel ? null : await _loadTask!(taskId);
      final tasks =
          task != null && task.userId == account && task.deletedAt == null
          ? [task]
          : <Task>[];
      final plans = await _plans(tasks);
      await reconciler.reconcile(
        plans,
        full: false,
        scopes: {
          jsonEncode([account, taskId]),
        },
        validate: () => _validate(account),
      );
    },
  );

  Future<void> _scheduleOne(int id, AlarmPlan plan) async {
    final date = DateTime.fromMillisecondsSinceEpoch(plan.at, isUtc: true);
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
    // 失败必须回到协调器，不能把失败记录成预约成功。
    await _plugin.zonedSchedule(
      id,
      plan.title,
      null,
      tz.TZDateTime.from(date, tz.local),
      details,
      payload: plan.payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

typedef AlarmPlanInput = ({
  List<Map<String, dynamic>> tasks,
  int now,
  String zone,
});

/// 纯计算可在工作 isolate 执行；保留原 60 天、最多 50 个实例的预约范围。
List<AlarmPlan> buildAlarmPlans(AlarmPlanInput input) {
  final now = Jiffy.parseFromMillisecondsSinceEpoch(input.now);
  final plans = <AlarmPlan>[];
  for (final json in input.tasks) {
    final task = Task.fromJson(json);
    final start = task.startAt ?? task.dueAt;
    if (start == null || task.alarms.isEmpty || task.deletedAt != null) {
      continue;
    }
    final days = task.recurrenceRule == null
        ? [start]
        : RecurrenceRuleCalculator.generateOccurrences(
                rule: task.recurrenceRule!,
                startDate: start,
                rangeStart: now.startOf(Unit.day),
                rangeEnd: now.add(days: 60),
              )
              .take(50)
              .map(
                (day) => task.isAllDay
                    ? day.startOf(Unit.day)
                    : day
                          .startOf(Unit.day)
                          .add(
                            hours: start.hour,
                            minutes: start.minute,
                            seconds: start.second,
                          ),
              )
              .toList();
    for (final occurrence in days) {
      final duplicates = <String, int>{};
      for (final alarm in task.alarms) {
        final configuration = jsonEncode(alarm.toJson());
        final ordinal = duplicates.update(
          configuration,
          (n) => n + 1,
          ifAbsent: () => 0,
        );
        final at = alarm.resolveTriggerTime(
          occurrence,
          isAllDay: task.isAllDay,
        );
        if (at == null || !at.isAfter(now)) continue;
        final key = jsonEncode([
          task.userId,
          task.id,
          occurrence.dateTime.toUtc().toIso8601String(),
          configuration,
          ordinal,
        ]);
        final millis = at.dateTime.millisecondsSinceEpoch;
        plans.add(
          AlarmPlan(
            key: key,
            scope: jsonEncode([task.userId, task.id]),
            title: task.title,
            at: millis,
            payload: jsonEncode({
              'v': 1,
              'key': key,
              'at': millis,
              'title': task.title,
              'zone': input.zone,
            }),
          ),
        );
      }
    }
  }
  return plans;
}
