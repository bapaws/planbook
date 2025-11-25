// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> startAt =
      GeneratedColumn<DateTime>(
        'start_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TasksTable.$converterstartAtn);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> endAt =
      GeneratedColumn<DateTime>(
        'end_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TasksTable.$converterendAtn);
  static const VerificationMeta _isAllDayMeta = const VerificationMeta(
    'isAllDay',
  );
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
    'is_all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> dueAt =
      GeneratedColumn<DateTime>(
        'due_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TasksTable.$converterdueAtn);
  @override
  late final GeneratedColumnWithTypeConverter<RecurrenceRule?, String>
  recurrenceRule = GeneratedColumn<String>(
    'recurrence_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<RecurrenceRule?>($TasksTable.$converterrecurrenceRule);
  static const VerificationMeta _detachedFromTaskIdMeta =
      const VerificationMeta('detachedFromTaskId');
  @override
  late final GeneratedColumn<String> detachedFromTaskId =
      GeneratedColumn<String>(
        'detached_from_task_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tasks (id) ON DELETE SET NULL',
        ),
      );
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime>
  detachedRecurrenceAt = GeneratedColumn<DateTime>(
    'detached_recurrence_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  ).withConverter<Jiffy?>($TasksTable.$converterdetachedRecurrenceAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DetachedReason?, String>
  detachedReason = GeneratedColumn<String>(
    'detached_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DetachedReason?>($TasksTable.$converterdetachedReasonn);
  @override
  late final GeneratedColumnWithTypeConverter<List<EventAlarm>, String> alarms =
      GeneratedColumn<String>(
        'alarms',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<List<EventAlarm>>($TasksTable.$converteralarms);
  @override
  late final GeneratedColumnWithTypeConverter<TaskPriority?, String> priority =
      GeneratedColumn<String>(
        'priority',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<TaskPriority?>($TasksTable.$converterpriorityn);
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeZoneMeta = const VerificationMeta(
    'timeZone',
  );
  @override
  late final GeneratedColumn<String> timeZone = GeneratedColumn<String>(
    'time_zone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      ).withConverter<Jiffy>($TasksTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TasksTable.$converterupdatedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> deletedAt =
      GeneratedColumn<DateTime>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TasksTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    parentId,
    order,
    startAt,
    endAt,
    isAllDay,
    dueAt,
    recurrenceRule,
    detachedFromTaskId,
    detachedRecurrenceAt,
    detachedReason,
    alarms,
    priority,
    location,
    notes,
    timeZone,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    if (data.containsKey('is_all_day')) {
      context.handle(
        _isAllDayMeta,
        isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta),
      );
    }
    if (data.containsKey('detached_from_task_id')) {
      context.handle(
        _detachedFromTaskIdMeta,
        detachedFromTaskId.isAcceptableOrUnknown(
          data['detached_from_task_id']!,
          _detachedFromTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('time_zone')) {
      context.handle(
        _timeZoneMeta,
        timeZone.isAcceptableOrUnknown(data['time_zone']!, _timeZoneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      startAt: $TasksTable.$converterstartAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}start_at'],
        ),
      ),
      endAt: $TasksTable.$converterendAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}end_at'],
        ),
      ),
      isAllDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_all_day'],
      )!,
      dueAt: $TasksTable.$converterdueAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}due_at'],
        ),
      ),
      recurrenceRule: $TasksTable.$converterrecurrenceRule.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}recurrence_rule'],
        ),
      ),
      detachedFromTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detached_from_task_id'],
      ),
      detachedRecurrenceAt: $TasksTable.$converterdetachedRecurrenceAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}detached_recurrence_at'],
        ),
      ),
      detachedReason: $TasksTable.$converterdetachedReasonn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}detached_reason'],
        ),
      ),
      alarms: $TasksTable.$converteralarms.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}alarms'],
        ),
      ),
      priority: $TasksTable.$converterpriorityn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}priority'],
        ),
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      timeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone'],
      ),
      createdAt: $TasksTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $TasksTable.$converterupdatedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        ),
      ),
      deletedAt: $TasksTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterstartAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterstartAtn =
      JsonTypeConverter2.asNullable($converterstartAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterendAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterendAtn =
      JsonTypeConverter2.asNullable($converterendAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterdueAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterdueAtn =
      JsonTypeConverter2.asNullable($converterdueAt);
  static JsonTypeConverter2<RecurrenceRule?, String?, Map<String, dynamic>?>
  $converterrecurrenceRule = const RecurrenceRuleConverter();
  static JsonTypeConverter2<Jiffy, DateTime, DateTime>
  $converterdetachedRecurrenceAt = const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?>
  $converterdetachedRecurrenceAtn = JsonTypeConverter2.asNullable(
    $converterdetachedRecurrenceAt,
  );
  static JsonTypeConverter2<DetachedReason, String, String>
  $converterdetachedReason = const EnumNameConverter<DetachedReason>(
    DetachedReason.values,
  );
  static JsonTypeConverter2<DetachedReason?, String?, String?>
  $converterdetachedReasonn = JsonTypeConverter2.asNullable(
    $converterdetachedReason,
  );
  static JsonTypeConverter2<List<EventAlarm>, String?, List<dynamic>?>
  $converteralarms = const EventAlarmListConverter();
  static JsonTypeConverter2<TaskPriority, String, String> $converterpriority =
      const EnumNameConverter<TaskPriority>(TaskPriority.values);
  static JsonTypeConverter2<TaskPriority?, String?, String?>
  $converterpriorityn = JsonTypeConverter2.asNullable($converterpriority);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $convertercreatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterupdatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterupdatedAtn =
      JsonTypeConverter2.asNullable($converterupdatedAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterdeletedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterdeletedAtn =
      JsonTypeConverter2.asNullable($converterdeletedAt);
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String? userId;
  final String title;
  final String? parentId;
  final int order;
  final Jiffy? startAt;
  final Jiffy? endAt;
  final bool isAllDay;
  final Jiffy? dueAt;
  final RecurrenceRule? recurrenceRule;
  final String? detachedFromTaskId;
  final Jiffy? detachedRecurrenceAt;
  final DetachedReason? detachedReason;
  final List<EventAlarm> alarms;
  final TaskPriority? priority;
  final String? location;
  final String? notes;
  final String? timeZone;
  final Jiffy createdAt;
  final Jiffy? updatedAt;
  final Jiffy? deletedAt;
  const Task({
    required this.id,
    this.userId,
    required this.title,
    this.parentId,
    required this.order,
    this.startAt,
    this.endAt,
    required this.isAllDay,
    this.dueAt,
    this.recurrenceRule,
    this.detachedFromTaskId,
    this.detachedRecurrenceAt,
    this.detachedReason,
    required this.alarms,
    this.priority,
    this.location,
    this.notes,
    this.timeZone,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['order'] = Variable<int>(order);
    if (!nullToAbsent || startAt != null) {
      map['start_at'] = Variable<DateTime>(
        $TasksTable.$converterstartAtn.toSql(startAt),
      );
    }
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<DateTime>(
        $TasksTable.$converterendAtn.toSql(endAt),
      );
    }
    map['is_all_day'] = Variable<bool>(isAllDay);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(
        $TasksTable.$converterdueAtn.toSql(dueAt),
      );
    }
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(
        $TasksTable.$converterrecurrenceRule.toSql(recurrenceRule),
      );
    }
    if (!nullToAbsent || detachedFromTaskId != null) {
      map['detached_from_task_id'] = Variable<String>(detachedFromTaskId);
    }
    if (!nullToAbsent || detachedRecurrenceAt != null) {
      map['detached_recurrence_at'] = Variable<DateTime>(
        $TasksTable.$converterdetachedRecurrenceAtn.toSql(detachedRecurrenceAt),
      );
    }
    if (!nullToAbsent || detachedReason != null) {
      map['detached_reason'] = Variable<String>(
        $TasksTable.$converterdetachedReasonn.toSql(detachedReason),
      );
    }
    {
      map['alarms'] = Variable<String>(
        $TasksTable.$converteralarms.toSql(alarms),
      );
    }
    if (!nullToAbsent || priority != null) {
      map['priority'] = Variable<String>(
        $TasksTable.$converterpriorityn.toSql(priority),
      );
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || timeZone != null) {
      map['time_zone'] = Variable<String>(timeZone);
    }
    {
      map['created_at'] = Variable<DateTime>(
        $TasksTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(
        $TasksTable.$converterupdatedAtn.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(
        $TasksTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      title: Value(title),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      order: Value(order),
      startAt: startAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startAt),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      isAllDay: Value(isAllDay),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
      detachedFromTaskId: detachedFromTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(detachedFromTaskId),
      detachedRecurrenceAt: detachedRecurrenceAt == null && nullToAbsent
          ? const Value.absent()
          : Value(detachedRecurrenceAt),
      detachedReason: detachedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(detachedReason),
      alarms: Value(alarms),
      priority: priority == null && nullToAbsent
          ? const Value.absent()
          : Value(priority),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      timeZone: timeZone == null && nullToAbsent
          ? const Value.absent()
          : Value(timeZone),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['user_id']),
      title: serializer.fromJson<String>(json['title']),
      parentId: serializer.fromJson<String?>(json['parent_id']),
      order: serializer.fromJson<int>(json['order']),
      startAt: $TasksTable.$converterstartAtn.fromJson(
        serializer.fromJson<DateTime?>(json['start_at']),
      ),
      endAt: $TasksTable.$converterendAtn.fromJson(
        serializer.fromJson<DateTime?>(json['end_at']),
      ),
      isAllDay: serializer.fromJson<bool>(json['is_all_day']),
      dueAt: $TasksTable.$converterdueAtn.fromJson(
        serializer.fromJson<DateTime?>(json['due_at']),
      ),
      recurrenceRule: $TasksTable.$converterrecurrenceRule.fromJson(
        serializer.fromJson<Map<String, dynamic>?>(json['recurrence_rule']),
      ),
      detachedFromTaskId: serializer.fromJson<String?>(
        json['detached_from_task_id'],
      ),
      detachedRecurrenceAt: $TasksTable.$converterdetachedRecurrenceAtn
          .fromJson(
            serializer.fromJson<DateTime?>(json['detached_recurrence_at']),
          ),
      detachedReason: $TasksTable.$converterdetachedReasonn.fromJson(
        serializer.fromJson<String?>(json['detached_reason']),
      ),
      alarms: $TasksTable.$converteralarms.fromJson(
        serializer.fromJson<List<dynamic>?>(json['alarms']),
      ),
      priority: $TasksTable.$converterpriorityn.fromJson(
        serializer.fromJson<String?>(json['priority']),
      ),
      location: serializer.fromJson<String?>(json['location']),
      notes: serializer.fromJson<String?>(json['notes']),
      timeZone: serializer.fromJson<String?>(json['time_zone']),
      createdAt: $TasksTable.$convertercreatedAt.fromJson(
        serializer.fromJson<DateTime>(json['created_at']),
      ),
      updatedAt: $TasksTable.$converterupdatedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['updated_at']),
      ),
      deletedAt: $TasksTable.$converterdeletedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['deleted_at']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String?>(userId),
      'title': serializer.toJson<String>(title),
      'parent_id': serializer.toJson<String?>(parentId),
      'order': serializer.toJson<int>(order),
      'start_at': serializer.toJson<DateTime?>(
        $TasksTable.$converterstartAtn.toJson(startAt),
      ),
      'end_at': serializer.toJson<DateTime?>(
        $TasksTable.$converterendAtn.toJson(endAt),
      ),
      'is_all_day': serializer.toJson<bool>(isAllDay),
      'due_at': serializer.toJson<DateTime?>(
        $TasksTable.$converterdueAtn.toJson(dueAt),
      ),
      'recurrence_rule': serializer.toJson<Map<String, dynamic>?>(
        $TasksTable.$converterrecurrenceRule.toJson(recurrenceRule),
      ),
      'detached_from_task_id': serializer.toJson<String?>(detachedFromTaskId),
      'detached_recurrence_at': serializer.toJson<DateTime?>(
        $TasksTable.$converterdetachedRecurrenceAtn.toJson(
          detachedRecurrenceAt,
        ),
      ),
      'detached_reason': serializer.toJson<String?>(
        $TasksTable.$converterdetachedReasonn.toJson(detachedReason),
      ),
      'alarms': serializer.toJson<List<dynamic>?>(
        $TasksTable.$converteralarms.toJson(alarms),
      ),
      'priority': serializer.toJson<String?>(
        $TasksTable.$converterpriorityn.toJson(priority),
      ),
      'location': serializer.toJson<String?>(location),
      'notes': serializer.toJson<String?>(notes),
      'time_zone': serializer.toJson<String?>(timeZone),
      'created_at': serializer.toJson<DateTime>(
        $TasksTable.$convertercreatedAt.toJson(createdAt),
      ),
      'updated_at': serializer.toJson<DateTime?>(
        $TasksTable.$converterupdatedAtn.toJson(updatedAt),
      ),
      'deleted_at': serializer.toJson<DateTime?>(
        $TasksTable.$converterdeletedAtn.toJson(deletedAt),
      ),
    };
  }

  Task copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    String? title,
    Value<String?> parentId = const Value.absent(),
    int? order,
    Value<Jiffy?> startAt = const Value.absent(),
    Value<Jiffy?> endAt = const Value.absent(),
    bool? isAllDay,
    Value<Jiffy?> dueAt = const Value.absent(),
    Value<RecurrenceRule?> recurrenceRule = const Value.absent(),
    Value<String?> detachedFromTaskId = const Value.absent(),
    Value<Jiffy?> detachedRecurrenceAt = const Value.absent(),
    Value<DetachedReason?> detachedReason = const Value.absent(),
    List<EventAlarm>? alarms,
    Value<TaskPriority?> priority = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> timeZone = const Value.absent(),
    Jiffy? createdAt,
    Value<Jiffy?> updatedAt = const Value.absent(),
    Value<Jiffy?> deletedAt = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    title: title ?? this.title,
    parentId: parentId.present ? parentId.value : this.parentId,
    order: order ?? this.order,
    startAt: startAt.present ? startAt.value : this.startAt,
    endAt: endAt.present ? endAt.value : this.endAt,
    isAllDay: isAllDay ?? this.isAllDay,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    recurrenceRule: recurrenceRule.present
        ? recurrenceRule.value
        : this.recurrenceRule,
    detachedFromTaskId: detachedFromTaskId.present
        ? detachedFromTaskId.value
        : this.detachedFromTaskId,
    detachedRecurrenceAt: detachedRecurrenceAt.present
        ? detachedRecurrenceAt.value
        : this.detachedRecurrenceAt,
    detachedReason: detachedReason.present
        ? detachedReason.value
        : this.detachedReason,
    alarms: alarms ?? this.alarms,
    priority: priority.present ? priority.value : this.priority,
    location: location.present ? location.value : this.location,
    notes: notes.present ? notes.value : this.notes,
    timeZone: timeZone.present ? timeZone.value : this.timeZone,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      order: data.order.present ? data.order.value : this.order,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
      detachedFromTaskId: data.detachedFromTaskId.present
          ? data.detachedFromTaskId.value
          : this.detachedFromTaskId,
      detachedRecurrenceAt: data.detachedRecurrenceAt.present
          ? data.detachedRecurrenceAt.value
          : this.detachedRecurrenceAt,
      detachedReason: data.detachedReason.present
          ? data.detachedReason.value
          : this.detachedReason,
      alarms: data.alarms.present ? data.alarms.value : this.alarms,
      priority: data.priority.present ? data.priority.value : this.priority,
      location: data.location.present ? data.location.value : this.location,
      notes: data.notes.present ? data.notes.value : this.notes,
      timeZone: data.timeZone.present ? data.timeZone.value : this.timeZone,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('parentId: $parentId, ')
          ..write('order: $order, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('dueAt: $dueAt, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('detachedFromTaskId: $detachedFromTaskId, ')
          ..write('detachedRecurrenceAt: $detachedRecurrenceAt, ')
          ..write('detachedReason: $detachedReason, ')
          ..write('alarms: $alarms, ')
          ..write('priority: $priority, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('timeZone: $timeZone, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    title,
    parentId,
    order,
    startAt,
    endAt,
    isAllDay,
    dueAt,
    recurrenceRule,
    detachedFromTaskId,
    detachedRecurrenceAt,
    detachedReason,
    alarms,
    priority,
    location,
    notes,
    timeZone,
    createdAt,
    updatedAt,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.parentId == this.parentId &&
          other.order == this.order &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.isAllDay == this.isAllDay &&
          other.dueAt == this.dueAt &&
          other.recurrenceRule == this.recurrenceRule &&
          other.detachedFromTaskId == this.detachedFromTaskId &&
          other.detachedRecurrenceAt == this.detachedRecurrenceAt &&
          other.detachedReason == this.detachedReason &&
          other.alarms == this.alarms &&
          other.priority == this.priority &&
          other.location == this.location &&
          other.notes == this.notes &&
          other.timeZone == this.timeZone &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> title;
  final Value<String?> parentId;
  final Value<int> order;
  final Value<Jiffy?> startAt;
  final Value<Jiffy?> endAt;
  final Value<bool> isAllDay;
  final Value<Jiffy?> dueAt;
  final Value<RecurrenceRule?> recurrenceRule;
  final Value<String?> detachedFromTaskId;
  final Value<Jiffy?> detachedRecurrenceAt;
  final Value<DetachedReason?> detachedReason;
  final Value<List<EventAlarm>> alarms;
  final Value<TaskPriority?> priority;
  final Value<String?> location;
  final Value<String?> notes;
  final Value<String?> timeZone;
  final Value<Jiffy> createdAt;
  final Value<Jiffy?> updatedAt;
  final Value<Jiffy?> deletedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.parentId = const Value.absent(),
    this.order = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.detachedFromTaskId = const Value.absent(),
    this.detachedRecurrenceAt = const Value.absent(),
    this.detachedReason = const Value.absent(),
    this.alarms = const Value.absent(),
    this.priority = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    required String title,
    this.parentId = const Value.absent(),
    this.order = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.detachedFromTaskId = const Value.absent(),
    this.detachedRecurrenceAt = const Value.absent(),
    this.detachedReason = const Value.absent(),
    this.alarms = const Value.absent(),
    this.priority = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? parentId,
    Expression<int>? order,
    Expression<DateTime>? startAt,
    Expression<DateTime>? endAt,
    Expression<bool>? isAllDay,
    Expression<DateTime>? dueAt,
    Expression<String>? recurrenceRule,
    Expression<String>? detachedFromTaskId,
    Expression<DateTime>? detachedRecurrenceAt,
    Expression<String>? detachedReason,
    Expression<String>? alarms,
    Expression<String>? priority,
    Expression<String>? location,
    Expression<String>? notes,
    Expression<String>? timeZone,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (parentId != null) 'parent_id': parentId,
      if (order != null) 'order': order,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (dueAt != null) 'due_at': dueAt,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (detachedFromTaskId != null)
        'detached_from_task_id': detachedFromTaskId,
      if (detachedRecurrenceAt != null)
        'detached_recurrence_at': detachedRecurrenceAt,
      if (detachedReason != null) 'detached_reason': detachedReason,
      if (alarms != null) 'alarms': alarms,
      if (priority != null) 'priority': priority,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      if (timeZone != null) 'time_zone': timeZone,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String>? title,
    Value<String?>? parentId,
    Value<int>? order,
    Value<Jiffy?>? startAt,
    Value<Jiffy?>? endAt,
    Value<bool>? isAllDay,
    Value<Jiffy?>? dueAt,
    Value<RecurrenceRule?>? recurrenceRule,
    Value<String?>? detachedFromTaskId,
    Value<Jiffy?>? detachedRecurrenceAt,
    Value<DetachedReason?>? detachedReason,
    Value<List<EventAlarm>>? alarms,
    Value<TaskPriority?>? priority,
    Value<String?>? location,
    Value<String?>? notes,
    Value<String?>? timeZone,
    Value<Jiffy>? createdAt,
    Value<Jiffy?>? updatedAt,
    Value<Jiffy?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      parentId: parentId ?? this.parentId,
      order: order ?? this.order,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isAllDay: isAllDay ?? this.isAllDay,
      dueAt: dueAt ?? this.dueAt,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      detachedFromTaskId: detachedFromTaskId ?? this.detachedFromTaskId,
      detachedRecurrenceAt: detachedRecurrenceAt ?? this.detachedRecurrenceAt,
      detachedReason: detachedReason ?? this.detachedReason,
      alarms: alarms ?? this.alarms,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      timeZone: timeZone ?? this.timeZone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(
        $TasksTable.$converterstartAtn.toSql(startAt.value),
      );
    }
    if (endAt.present) {
      map['end_at'] = Variable<DateTime>(
        $TasksTable.$converterendAtn.toSql(endAt.value),
      );
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(
        $TasksTable.$converterdueAtn.toSql(dueAt.value),
      );
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(
        $TasksTable.$converterrecurrenceRule.toSql(recurrenceRule.value),
      );
    }
    if (detachedFromTaskId.present) {
      map['detached_from_task_id'] = Variable<String>(detachedFromTaskId.value);
    }
    if (detachedRecurrenceAt.present) {
      map['detached_recurrence_at'] = Variable<DateTime>(
        $TasksTable.$converterdetachedRecurrenceAtn.toSql(
          detachedRecurrenceAt.value,
        ),
      );
    }
    if (detachedReason.present) {
      map['detached_reason'] = Variable<String>(
        $TasksTable.$converterdetachedReasonn.toSql(detachedReason.value),
      );
    }
    if (alarms.present) {
      map['alarms'] = Variable<String>(
        $TasksTable.$converteralarms.toSql(alarms.value),
      );
    }
    if (priority.present) {
      map['priority'] = Variable<String>(
        $TasksTable.$converterpriorityn.toSql(priority.value),
      );
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (timeZone.present) {
      map['time_zone'] = Variable<String>(timeZone.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $TasksTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $TasksTable.$converterupdatedAtn.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(
        $TasksTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('parentId: $parentId, ')
          ..write('order: $order, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('dueAt: $dueAt, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('detachedFromTaskId: $detachedFromTaskId, ')
          ..write('detachedRecurrenceAt: $detachedRecurrenceAt, ')
          ..write('detachedReason: $detachedReason, ')
          ..write('alarms: $alarms, ')
          ..write('priority: $priority, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('timeZone: $timeZone, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> images =
      GeneratedColumn<String>(
        'images',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<List<String>>($NotesTable.$converterimages);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      ).withConverter<Jiffy>($NotesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($NotesTable.$converterupdatedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> deletedAt =
      GeneratedColumn<DateTime>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($NotesTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    content,
    images,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      images: $NotesTable.$converterimages.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}images'],
        ),
      ),
      createdAt: $NotesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $NotesTable.$converterupdatedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        ),
      ),
      deletedAt: $NotesTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<List<String>, String?, List<dynamic>?>
  $converterimages = const ListConverter<String>();
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $convertercreatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterupdatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterupdatedAtn =
      JsonTypeConverter2.asNullable($converterupdatedAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterdeletedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterdeletedAtn =
      JsonTypeConverter2.asNullable($converterdeletedAt);
}

class Note extends DataClass implements Insertable<Note> {
  final String id;
  final String? userId;
  final String title;
  final String? content;
  final List<String> images;
  final Jiffy createdAt;
  final Jiffy? updatedAt;
  final Jiffy? deletedAt;
  const Note({
    required this.id,
    this.userId,
    required this.title,
    this.content,
    required this.images,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    {
      map['images'] = Variable<String>(
        $NotesTable.$converterimages.toSql(images),
      );
    }
    {
      map['created_at'] = Variable<DateTime>(
        $NotesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(
        $NotesTable.$converterupdatedAtn.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(
        $NotesTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      title: Value(title),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      images: Value(images),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['user_id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String?>(json['content']),
      images: $NotesTable.$converterimages.fromJson(
        serializer.fromJson<List<dynamic>?>(json['images']),
      ),
      createdAt: $NotesTable.$convertercreatedAt.fromJson(
        serializer.fromJson<DateTime>(json['created_at']),
      ),
      updatedAt: $NotesTable.$converterupdatedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['updated_at']),
      ),
      deletedAt: $NotesTable.$converterdeletedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['deleted_at']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String?>(userId),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String?>(content),
      'images': serializer.toJson<List<dynamic>?>(
        $NotesTable.$converterimages.toJson(images),
      ),
      'created_at': serializer.toJson<DateTime>(
        $NotesTable.$convertercreatedAt.toJson(createdAt),
      ),
      'updated_at': serializer.toJson<DateTime?>(
        $NotesTable.$converterupdatedAtn.toJson(updatedAt),
      ),
      'deleted_at': serializer.toJson<DateTime?>(
        $NotesTable.$converterdeletedAtn.toJson(deletedAt),
      ),
    };
  }

  Note copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    String? title,
    Value<String?> content = const Value.absent(),
    List<String>? images,
    Jiffy? createdAt,
    Value<Jiffy?> updatedAt = const Value.absent(),
    Value<Jiffy?> deletedAt = const Value.absent(),
  }) => Note(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    title: title ?? this.title,
    content: content.present ? content.value : this.content,
    images: images ?? this.images,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      images: data.images.present ? data.images.value : this.images,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('images: $images, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    content,
    images,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.content == this.content &&
          other.images == this.images &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> title;
  final Value<String?> content;
  final Value<List<String>> images;
  final Value<Jiffy> createdAt;
  final Value<Jiffy?> updatedAt;
  final Value<Jiffy?> deletedAt;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.images = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    required String title,
    this.content = const Value.absent(),
    this.images = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? images,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (images != null) 'images': images,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String>? title,
    Value<String?>? content,
    Value<List<String>>? images,
    Value<Jiffy>? createdAt,
    Value<Jiffy?>? updatedAt,
    Value<Jiffy?>? deletedAt,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (images.present) {
      map['images'] = Variable<String>(
        $NotesTable.$converterimages.toSql(images.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $NotesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $NotesTable.$converterupdatedAtn.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(
        $NotesTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('images: $images, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ColorScheme?, String>
  darkColorScheme = GeneratedColumn<String>(
    'dark_color_scheme',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ColorScheme?>($TagsTable.$converterdarkColorScheme);
  @override
  late final GeneratedColumnWithTypeConverter<ColorScheme?, String>
  lightColorScheme = GeneratedColumn<String>(
    'light_color_scheme',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ColorScheme?>($TagsTable.$converterlightColorScheme);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      ).withConverter<Jiffy>($TagsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TagsTable.$converterupdatedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> deletedAt =
      GeneratedColumn<DateTime>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TagsTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    color,
    order,
    parentId,
    level,
    darkColorScheme,
    lightColorScheme,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      darkColorScheme: $TagsTable.$converterdarkColorScheme.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}dark_color_scheme'],
        ),
      ),
      lightColorScheme: $TagsTable.$converterlightColorScheme.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}light_color_scheme'],
        ),
      ),
      createdAt: $TagsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $TagsTable.$converterupdatedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        ),
      ),
      deletedAt: $TagsTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ColorScheme?, String?, String?>
  $converterdarkColorScheme = const ColorSchemeConverter();
  static JsonTypeConverter2<ColorScheme?, String?, String?>
  $converterlightColorScheme = const ColorSchemeConverter();
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $convertercreatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterupdatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterupdatedAtn =
      JsonTypeConverter2.asNullable($converterupdatedAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterdeletedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterdeletedAtn =
      JsonTypeConverter2.asNullable($converterdeletedAt);
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String? userId;
  final String name;
  final String? color;
  final int order;
  final String? parentId;
  final int level;
  final ColorScheme? darkColorScheme;
  final ColorScheme? lightColorScheme;
  final Jiffy createdAt;
  final Jiffy? updatedAt;
  final Jiffy? deletedAt;
  const Tag({
    required this.id,
    this.userId,
    required this.name,
    this.color,
    required this.order,
    this.parentId,
    required this.level,
    this.darkColorScheme,
    this.lightColorScheme,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['order'] = Variable<int>(order);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['level'] = Variable<int>(level);
    if (!nullToAbsent || darkColorScheme != null) {
      map['dark_color_scheme'] = Variable<String>(
        $TagsTable.$converterdarkColorScheme.toSql(darkColorScheme),
      );
    }
    if (!nullToAbsent || lightColorScheme != null) {
      map['light_color_scheme'] = Variable<String>(
        $TagsTable.$converterlightColorScheme.toSql(lightColorScheme),
      );
    }
    {
      map['created_at'] = Variable<DateTime>(
        $TagsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(
        $TagsTable.$converterupdatedAtn.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(
        $TagsTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      order: Value(order),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      level: Value(level),
      darkColorScheme: darkColorScheme == null && nullToAbsent
          ? const Value.absent()
          : Value(darkColorScheme),
      lightColorScheme: lightColorScheme == null && nullToAbsent
          ? const Value.absent()
          : Value(lightColorScheme),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['user_id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      order: serializer.fromJson<int>(json['order']),
      parentId: serializer.fromJson<String?>(json['parent_id']),
      level: serializer.fromJson<int>(json['level']),
      darkColorScheme: $TagsTable.$converterdarkColorScheme.fromJson(
        serializer.fromJson<String?>(json['dark_color_scheme']),
      ),
      lightColorScheme: $TagsTable.$converterlightColorScheme.fromJson(
        serializer.fromJson<String?>(json['light_color_scheme']),
      ),
      createdAt: $TagsTable.$convertercreatedAt.fromJson(
        serializer.fromJson<DateTime>(json['created_at']),
      ),
      updatedAt: $TagsTable.$converterupdatedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['updated_at']),
      ),
      deletedAt: $TagsTable.$converterdeletedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['deleted_at']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String?>(userId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'order': serializer.toJson<int>(order),
      'parent_id': serializer.toJson<String?>(parentId),
      'level': serializer.toJson<int>(level),
      'dark_color_scheme': serializer.toJson<String?>(
        $TagsTable.$converterdarkColorScheme.toJson(darkColorScheme),
      ),
      'light_color_scheme': serializer.toJson<String?>(
        $TagsTable.$converterlightColorScheme.toJson(lightColorScheme),
      ),
      'created_at': serializer.toJson<DateTime>(
        $TagsTable.$convertercreatedAt.toJson(createdAt),
      ),
      'updated_at': serializer.toJson<DateTime?>(
        $TagsTable.$converterupdatedAtn.toJson(updatedAt),
      ),
      'deleted_at': serializer.toJson<DateTime?>(
        $TagsTable.$converterdeletedAtn.toJson(deletedAt),
      ),
    };
  }

  Tag copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    String? name,
    Value<String?> color = const Value.absent(),
    int? order,
    Value<String?> parentId = const Value.absent(),
    int? level,
    Value<ColorScheme?> darkColorScheme = const Value.absent(),
    Value<ColorScheme?> lightColorScheme = const Value.absent(),
    Jiffy? createdAt,
    Value<Jiffy?> updatedAt = const Value.absent(),
    Value<Jiffy?> deletedAt = const Value.absent(),
  }) => Tag(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    order: order ?? this.order,
    parentId: parentId.present ? parentId.value : this.parentId,
    level: level ?? this.level,
    darkColorScheme: darkColorScheme.present
        ? darkColorScheme.value
        : this.darkColorScheme,
    lightColorScheme: lightColorScheme.present
        ? lightColorScheme.value
        : this.lightColorScheme,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      order: data.order.present ? data.order.value : this.order,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      level: data.level.present ? data.level.value : this.level,
      darkColorScheme: data.darkColorScheme.present
          ? data.darkColorScheme.value
          : this.darkColorScheme,
      lightColorScheme: data.lightColorScheme.present
          ? data.lightColorScheme.value
          : this.lightColorScheme,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('order: $order, ')
          ..write('parentId: $parentId, ')
          ..write('level: $level, ')
          ..write('darkColorScheme: $darkColorScheme, ')
          ..write('lightColorScheme: $lightColorScheme, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    color,
    order,
    parentId,
    level,
    darkColorScheme,
    lightColorScheme,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.color == this.color &&
          other.order == this.order &&
          other.parentId == this.parentId &&
          other.level == this.level &&
          other.darkColorScheme == this.darkColorScheme &&
          other.lightColorScheme == this.lightColorScheme &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String> name;
  final Value<String?> color;
  final Value<int> order;
  final Value<String?> parentId;
  final Value<int> level;
  final Value<ColorScheme?> darkColorScheme;
  final Value<ColorScheme?> lightColorScheme;
  final Value<Jiffy> createdAt;
  final Value<Jiffy?> updatedAt;
  final Value<Jiffy?> deletedAt;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.order = const Value.absent(),
    this.parentId = const Value.absent(),
    this.level = const Value.absent(),
    this.darkColorScheme = const Value.absent(),
    this.lightColorScheme = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.order = const Value.absent(),
    this.parentId = const Value.absent(),
    this.level = const Value.absent(),
    this.darkColorScheme = const Value.absent(),
    this.lightColorScheme = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? color,
    Expression<int>? order,
    Expression<String>? parentId,
    Expression<int>? level,
    Expression<String>? darkColorScheme,
    Expression<String>? lightColorScheme,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (order != null) 'order': order,
      if (parentId != null) 'parent_id': parentId,
      if (level != null) 'level': level,
      if (darkColorScheme != null) 'dark_color_scheme': darkColorScheme,
      if (lightColorScheme != null) 'light_color_scheme': lightColorScheme,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String>? name,
    Value<String?>? color,
    Value<int>? order,
    Value<String?>? parentId,
    Value<int>? level,
    Value<ColorScheme?>? darkColorScheme,
    Value<ColorScheme?>? lightColorScheme,
    Value<Jiffy>? createdAt,
    Value<Jiffy?>? updatedAt,
    Value<Jiffy?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      order: order ?? this.order,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      darkColorScheme: darkColorScheme ?? this.darkColorScheme,
      lightColorScheme: lightColorScheme ?? this.lightColorScheme,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (darkColorScheme.present) {
      map['dark_color_scheme'] = Variable<String>(
        $TagsTable.$converterdarkColorScheme.toSql(darkColorScheme.value),
      );
    }
    if (lightColorScheme.present) {
      map['light_color_scheme'] = Variable<String>(
        $TagsTable.$converterlightColorScheme.toSql(lightColorScheme.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $TagsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $TagsTable.$converterupdatedAtn.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(
        $TagsTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('order: $order, ')
          ..write('parentId: $parentId, ')
          ..write('level: $level, ')
          ..write('darkColorScheme: $darkColorScheme, ')
          ..write('lightColorScheme: $lightColorScheme, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteTagsTable extends NoteTags with TableInfo<$NoteTagsTable, NoteTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _isParentMeta = const VerificationMeta(
    'isParent',
  );
  @override
  late final GeneratedColumn<bool> isParent = GeneratedColumn<bool>(
    'is_parent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_parent" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      ).withConverter<Jiffy>($NoteTagsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($NoteTagsTable.$converterupdatedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> deletedAt =
      GeneratedColumn<DateTime>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($NoteTagsTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    noteId,
    tagId,
    isParent,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('is_parent')) {
      context.handle(
        _isParentMeta,
        isParent.isAcceptableOrUnknown(data['is_parent']!, _isParentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteTag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
      isParent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_parent'],
      )!,
      createdAt: $NoteTagsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $NoteTagsTable.$converterupdatedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        ),
      ),
      deletedAt: $NoteTagsTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $NoteTagsTable createAlias(String alias) {
    return $NoteTagsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $convertercreatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterupdatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterupdatedAtn =
      JsonTypeConverter2.asNullable($converterupdatedAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterdeletedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterdeletedAtn =
      JsonTypeConverter2.asNullable($converterdeletedAt);
}

class NoteTag extends DataClass implements Insertable<NoteTag> {
  final String id;
  final String noteId;
  final String tagId;
  final bool isParent;
  final Jiffy createdAt;
  final Jiffy? updatedAt;
  final Jiffy? deletedAt;
  const NoteTag({
    required this.id,
    required this.noteId,
    required this.tagId,
    required this.isParent,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['tag_id'] = Variable<String>(tagId);
    map['is_parent'] = Variable<bool>(isParent);
    {
      map['created_at'] = Variable<DateTime>(
        $NoteTagsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(
        $NoteTagsTable.$converterupdatedAtn.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(
        $NoteTagsTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  NoteTagsCompanion toCompanion(bool nullToAbsent) {
    return NoteTagsCompanion(
      id: Value(id),
      noteId: Value(noteId),
      tagId: Value(tagId),
      isParent: Value(isParent),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory NoteTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteTag(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<String>(json['note_id']),
      tagId: serializer.fromJson<String>(json['tag_id']),
      isParent: serializer.fromJson<bool>(json['is_parent']),
      createdAt: $NoteTagsTable.$convertercreatedAt.fromJson(
        serializer.fromJson<DateTime>(json['created_at']),
      ),
      updatedAt: $NoteTagsTable.$converterupdatedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['updated_at']),
      ),
      deletedAt: $NoteTagsTable.$converterdeletedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['deleted_at']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'note_id': serializer.toJson<String>(noteId),
      'tag_id': serializer.toJson<String>(tagId),
      'is_parent': serializer.toJson<bool>(isParent),
      'created_at': serializer.toJson<DateTime>(
        $NoteTagsTable.$convertercreatedAt.toJson(createdAt),
      ),
      'updated_at': serializer.toJson<DateTime?>(
        $NoteTagsTable.$converterupdatedAtn.toJson(updatedAt),
      ),
      'deleted_at': serializer.toJson<DateTime?>(
        $NoteTagsTable.$converterdeletedAtn.toJson(deletedAt),
      ),
    };
  }

  NoteTag copyWith({
    String? id,
    String? noteId,
    String? tagId,
    bool? isParent,
    Jiffy? createdAt,
    Value<Jiffy?> updatedAt = const Value.absent(),
    Value<Jiffy?> deletedAt = const Value.absent(),
  }) => NoteTag(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    tagId: tagId ?? this.tagId,
    isParent: isParent ?? this.isParent,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  NoteTag copyWithCompanion(NoteTagsCompanion data) {
    return NoteTag(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      isParent: data.isParent.present ? data.isParent.value : this.isParent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteTag(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('tagId: $tagId, ')
          ..write('isParent: $isParent, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, noteId, tagId, isParent, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteTag &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.tagId == this.tagId &&
          other.isParent == this.isParent &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class NoteTagsCompanion extends UpdateCompanion<NoteTag> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<String> tagId;
  final Value<bool> isParent;
  final Value<Jiffy> createdAt;
  final Value<Jiffy?> updatedAt;
  final Value<Jiffy?> deletedAt;
  final Value<int> rowid;
  const NoteTagsCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.isParent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteTagsCompanion.insert({
    this.id = const Value.absent(),
    required String noteId,
    required String tagId,
    this.isParent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : noteId = Value(noteId),
       tagId = Value(tagId);
  static Insertable<NoteTag> custom({
    Expression<String>? id,
    Expression<String>? noteId,
    Expression<String>? tagId,
    Expression<bool>? isParent,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (tagId != null) 'tag_id': tagId,
      if (isParent != null) 'is_parent': isParent,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteTagsCompanion copyWith({
    Value<String>? id,
    Value<String>? noteId,
    Value<String>? tagId,
    Value<bool>? isParent,
    Value<Jiffy>? createdAt,
    Value<Jiffy?>? updatedAt,
    Value<Jiffy?>? deletedAt,
    Value<int>? rowid,
  }) {
    return NoteTagsCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      tagId: tagId ?? this.tagId,
      isParent: isParent ?? this.isParent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (isParent.present) {
      map['is_parent'] = Variable<bool>(isParent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $NoteTagsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $NoteTagsTable.$converterupdatedAtn.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(
        $NoteTagsTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteTagsCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('tagId: $tagId, ')
          ..write('isParent: $isParent, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskTagsTable extends TaskTags with TableInfo<$TaskTagsTable, TaskTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _isParentMeta = const VerificationMeta(
    'isParent',
  );
  @override
  late final GeneratedColumn<bool> isParent = GeneratedColumn<bool>(
    'is_parent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_parent" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      ).withConverter<Jiffy>($TaskTagsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TaskTagsTable.$converterupdatedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> deletedAt =
      GeneratedColumn<DateTime>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TaskTagsTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    tagId,
    isParent,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('is_parent')) {
      context.handle(
        _isParentMeta,
        isParent.isAcceptableOrUnknown(data['is_parent']!, _isParentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
      isParent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_parent'],
      )!,
      createdAt: $TaskTagsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $TaskTagsTable.$converterupdatedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        ),
      ),
      deletedAt: $TaskTagsTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $TaskTagsTable createAlias(String alias) {
    return $TaskTagsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $convertercreatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterupdatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterupdatedAtn =
      JsonTypeConverter2.asNullable($converterupdatedAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterdeletedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterdeletedAtn =
      JsonTypeConverter2.asNullable($converterdeletedAt);
}

class TaskTag extends DataClass implements Insertable<TaskTag> {
  final String id;
  final String taskId;
  final String tagId;
  final bool isParent;
  final Jiffy createdAt;
  final Jiffy? updatedAt;
  final Jiffy? deletedAt;
  const TaskTag({
    required this.id,
    required this.taskId,
    required this.tagId,
    required this.isParent,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['tag_id'] = Variable<String>(tagId);
    map['is_parent'] = Variable<bool>(isParent);
    {
      map['created_at'] = Variable<DateTime>(
        $TaskTagsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(
        $TaskTagsTable.$converterupdatedAtn.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(
        $TaskTagsTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  TaskTagsCompanion toCompanion(bool nullToAbsent) {
    return TaskTagsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      tagId: Value(tagId),
      isParent: Value(isParent),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TaskTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTag(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['task_id']),
      tagId: serializer.fromJson<String>(json['tag_id']),
      isParent: serializer.fromJson<bool>(json['is_parent']),
      createdAt: $TaskTagsTable.$convertercreatedAt.fromJson(
        serializer.fromJson<DateTime>(json['created_at']),
      ),
      updatedAt: $TaskTagsTable.$converterupdatedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['updated_at']),
      ),
      deletedAt: $TaskTagsTable.$converterdeletedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['deleted_at']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'task_id': serializer.toJson<String>(taskId),
      'tag_id': serializer.toJson<String>(tagId),
      'is_parent': serializer.toJson<bool>(isParent),
      'created_at': serializer.toJson<DateTime>(
        $TaskTagsTable.$convertercreatedAt.toJson(createdAt),
      ),
      'updated_at': serializer.toJson<DateTime?>(
        $TaskTagsTable.$converterupdatedAtn.toJson(updatedAt),
      ),
      'deleted_at': serializer.toJson<DateTime?>(
        $TaskTagsTable.$converterdeletedAtn.toJson(deletedAt),
      ),
    };
  }

  TaskTag copyWith({
    String? id,
    String? taskId,
    String? tagId,
    bool? isParent,
    Jiffy? createdAt,
    Value<Jiffy?> updatedAt = const Value.absent(),
    Value<Jiffy?> deletedAt = const Value.absent(),
  }) => TaskTag(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    tagId: tagId ?? this.tagId,
    isParent: isParent ?? this.isParent,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TaskTag copyWithCompanion(TaskTagsCompanion data) {
    return TaskTag(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      isParent: data.isParent.present ? data.isParent.value : this.isParent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTag(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('tagId: $tagId, ')
          ..write('isParent: $isParent, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, tagId, isParent, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTag &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.tagId == this.tagId &&
          other.isParent == this.isParent &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TaskTagsCompanion extends UpdateCompanion<TaskTag> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> tagId;
  final Value<bool> isParent;
  final Value<Jiffy> createdAt;
  final Value<Jiffy?> updatedAt;
  final Value<Jiffy?> deletedAt;
  final Value<int> rowid;
  const TaskTagsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.isParent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskTagsCompanion.insert({
    this.id = const Value.absent(),
    required String taskId,
    required String tagId,
    this.isParent = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       tagId = Value(tagId);
  static Insertable<TaskTag> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? tagId,
    Expression<bool>? isParent,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (tagId != null) 'tag_id': tagId,
      if (isParent != null) 'is_parent': isParent,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskTagsCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? tagId,
    Value<bool>? isParent,
    Value<Jiffy>? createdAt,
    Value<Jiffy?>? updatedAt,
    Value<Jiffy?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TaskTagsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      tagId: tagId ?? this.tagId,
      isParent: isParent ?? this.isParent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (isParent.present) {
      map['is_parent'] = Variable<bool>(isParent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $TaskTagsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $TaskTagsTable.$converterupdatedAtn.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(
        $TaskTagsTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTagsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('tagId: $tagId, ')
          ..write('isParent: $isParent, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskActivitiesTable extends TaskActivities
    with TableInfo<$TaskActivitiesTable, TaskActivity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notes (id) ON DELETE SET NULL',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> completedAt =
      GeneratedColumn<DateTime>(
        'completed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      ).withConverter<Jiffy?>($TaskActivitiesTable.$convertercompletedAtn);
  static const VerificationMeta _activityTypeMeta = const VerificationMeta(
    'activityType',
  );
  @override
  late final GeneratedColumn<String> activityType = GeneratedColumn<String>(
    'activity_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> occurrenceAt =
      GeneratedColumn<DateTime>(
        'occurrence_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TaskActivitiesTable.$converteroccurrenceAtn);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> startAt =
      GeneratedColumn<DateTime>(
        'start_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TaskActivitiesTable.$converterstartAtn);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> endAt =
      GeneratedColumn<DateTime>(
        'end_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TaskActivitiesTable.$converterendAtn);
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      ).withConverter<Jiffy>($TaskActivitiesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TaskActivitiesTable.$converterupdatedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> deletedAt =
      GeneratedColumn<DateTime>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TaskActivitiesTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    taskId,
    noteId,
    completedAt,
    activityType,
    occurrenceAt,
    startAt,
    endAt,
    duration,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskActivity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    }
    if (data.containsKey('activity_type')) {
      context.handle(
        _activityTypeMeta,
        activityType.isAcceptableOrUnknown(
          data['activity_type']!,
          _activityTypeMeta,
        ),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskActivity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskActivity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      ),
      completedAt: $TaskActivitiesTable.$convertercompletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}completed_at'],
        ),
      ),
      activityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_type'],
      ),
      occurrenceAt: $TaskActivitiesTable.$converteroccurrenceAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}occurrence_at'],
        ),
      ),
      startAt: $TaskActivitiesTable.$converterstartAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}start_at'],
        ),
      ),
      endAt: $TaskActivitiesTable.$converterendAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}end_at'],
        ),
      ),
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      ),
      createdAt: $TaskActivitiesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $TaskActivitiesTable.$converterupdatedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        ),
      ),
      deletedAt: $TaskActivitiesTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $TaskActivitiesTable createAlias(String alias) {
    return $TaskActivitiesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $convertercompletedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?>
  $convertercompletedAtn = JsonTypeConverter2.asNullable($convertercompletedAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converteroccurrenceAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?>
  $converteroccurrenceAtn = JsonTypeConverter2.asNullable(
    $converteroccurrenceAt,
  );
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterstartAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterstartAtn =
      JsonTypeConverter2.asNullable($converterstartAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterendAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterendAtn =
      JsonTypeConverter2.asNullable($converterendAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $convertercreatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterupdatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterupdatedAtn =
      JsonTypeConverter2.asNullable($converterupdatedAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterdeletedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterdeletedAtn =
      JsonTypeConverter2.asNullable($converterdeletedAt);
}

class TaskActivity extends DataClass implements Insertable<TaskActivity> {
  final String id;
  final String? userId;
  final String? taskId;
  final String? noteId;
  final Jiffy? completedAt;
  final String? activityType;
  final Jiffy? occurrenceAt;
  final Jiffy? startAt;
  final Jiffy? endAt;
  final int? duration;
  final Jiffy createdAt;
  final Jiffy? updatedAt;
  final Jiffy? deletedAt;
  const TaskActivity({
    required this.id,
    this.userId,
    this.taskId,
    this.noteId,
    this.completedAt,
    this.activityType,
    this.occurrenceAt,
    this.startAt,
    this.endAt,
    this.duration,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    if (!nullToAbsent || noteId != null) {
      map['note_id'] = Variable<String>(noteId);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$convertercompletedAtn.toSql(completedAt),
      );
    }
    if (!nullToAbsent || activityType != null) {
      map['activity_type'] = Variable<String>(activityType);
    }
    if (!nullToAbsent || occurrenceAt != null) {
      map['occurrence_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$converteroccurrenceAtn.toSql(occurrenceAt),
      );
    }
    if (!nullToAbsent || startAt != null) {
      map['start_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$converterstartAtn.toSql(startAt),
      );
    }
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$converterendAtn.toSql(endAt),
      );
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    {
      map['created_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$converterupdatedAtn.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  TaskActivitiesCompanion toCompanion(bool nullToAbsent) {
    return TaskActivitiesCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      noteId: noteId == null && nullToAbsent
          ? const Value.absent()
          : Value(noteId),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      activityType: activityType == null && nullToAbsent
          ? const Value.absent()
          : Value(activityType),
      occurrenceAt: occurrenceAt == null && nullToAbsent
          ? const Value.absent()
          : Value(occurrenceAt),
      startAt: startAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startAt),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TaskActivity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskActivity(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['user_id']),
      taskId: serializer.fromJson<String?>(json['task_id']),
      noteId: serializer.fromJson<String?>(json['note_id']),
      completedAt: $TaskActivitiesTable.$convertercompletedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['completed_at']),
      ),
      activityType: serializer.fromJson<String?>(json['activity_type']),
      occurrenceAt: $TaskActivitiesTable.$converteroccurrenceAtn.fromJson(
        serializer.fromJson<DateTime?>(json['occurrence_at']),
      ),
      startAt: $TaskActivitiesTable.$converterstartAtn.fromJson(
        serializer.fromJson<DateTime?>(json['start_at']),
      ),
      endAt: $TaskActivitiesTable.$converterendAtn.fromJson(
        serializer.fromJson<DateTime?>(json['end_at']),
      ),
      duration: serializer.fromJson<int?>(json['duration']),
      createdAt: $TaskActivitiesTable.$convertercreatedAt.fromJson(
        serializer.fromJson<DateTime>(json['created_at']),
      ),
      updatedAt: $TaskActivitiesTable.$converterupdatedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['updated_at']),
      ),
      deletedAt: $TaskActivitiesTable.$converterdeletedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['deleted_at']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'user_id': serializer.toJson<String?>(userId),
      'task_id': serializer.toJson<String?>(taskId),
      'note_id': serializer.toJson<String?>(noteId),
      'completed_at': serializer.toJson<DateTime?>(
        $TaskActivitiesTable.$convertercompletedAtn.toJson(completedAt),
      ),
      'activity_type': serializer.toJson<String?>(activityType),
      'occurrence_at': serializer.toJson<DateTime?>(
        $TaskActivitiesTable.$converteroccurrenceAtn.toJson(occurrenceAt),
      ),
      'start_at': serializer.toJson<DateTime?>(
        $TaskActivitiesTable.$converterstartAtn.toJson(startAt),
      ),
      'end_at': serializer.toJson<DateTime?>(
        $TaskActivitiesTable.$converterendAtn.toJson(endAt),
      ),
      'duration': serializer.toJson<int?>(duration),
      'created_at': serializer.toJson<DateTime>(
        $TaskActivitiesTable.$convertercreatedAt.toJson(createdAt),
      ),
      'updated_at': serializer.toJson<DateTime?>(
        $TaskActivitiesTable.$converterupdatedAtn.toJson(updatedAt),
      ),
      'deleted_at': serializer.toJson<DateTime?>(
        $TaskActivitiesTable.$converterdeletedAtn.toJson(deletedAt),
      ),
    };
  }

  TaskActivity copyWith({
    String? id,
    Value<String?> userId = const Value.absent(),
    Value<String?> taskId = const Value.absent(),
    Value<String?> noteId = const Value.absent(),
    Value<Jiffy?> completedAt = const Value.absent(),
    Value<String?> activityType = const Value.absent(),
    Value<Jiffy?> occurrenceAt = const Value.absent(),
    Value<Jiffy?> startAt = const Value.absent(),
    Value<Jiffy?> endAt = const Value.absent(),
    Value<int?> duration = const Value.absent(),
    Jiffy? createdAt,
    Value<Jiffy?> updatedAt = const Value.absent(),
    Value<Jiffy?> deletedAt = const Value.absent(),
  }) => TaskActivity(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    taskId: taskId.present ? taskId.value : this.taskId,
    noteId: noteId.present ? noteId.value : this.noteId,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    activityType: activityType.present ? activityType.value : this.activityType,
    occurrenceAt: occurrenceAt.present ? occurrenceAt.value : this.occurrenceAt,
    startAt: startAt.present ? startAt.value : this.startAt,
    endAt: endAt.present ? endAt.value : this.endAt,
    duration: duration.present ? duration.value : this.duration,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TaskActivity copyWithCompanion(TaskActivitiesCompanion data) {
    return TaskActivity(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      activityType: data.activityType.present
          ? data.activityType.value
          : this.activityType,
      occurrenceAt: data.occurrenceAt.present
          ? data.occurrenceAt.value
          : this.occurrenceAt,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      duration: data.duration.present ? data.duration.value : this.duration,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskActivity(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('taskId: $taskId, ')
          ..write('noteId: $noteId, ')
          ..write('completedAt: $completedAt, ')
          ..write('activityType: $activityType, ')
          ..write('occurrenceAt: $occurrenceAt, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('duration: $duration, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    taskId,
    noteId,
    completedAt,
    activityType,
    occurrenceAt,
    startAt,
    endAt,
    duration,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskActivity &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.taskId == this.taskId &&
          other.noteId == this.noteId &&
          other.completedAt == this.completedAt &&
          other.activityType == this.activityType &&
          other.occurrenceAt == this.occurrenceAt &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.duration == this.duration &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TaskActivitiesCompanion extends UpdateCompanion<TaskActivity> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String?> taskId;
  final Value<String?> noteId;
  final Value<Jiffy?> completedAt;
  final Value<String?> activityType;
  final Value<Jiffy?> occurrenceAt;
  final Value<Jiffy?> startAt;
  final Value<Jiffy?> endAt;
  final Value<int?> duration;
  final Value<Jiffy> createdAt;
  final Value<Jiffy?> updatedAt;
  final Value<Jiffy?> deletedAt;
  final Value<int> rowid;
  const TaskActivitiesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.noteId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.activityType = const Value.absent(),
    this.occurrenceAt = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.duration = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskActivitiesCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.noteId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.activityType = const Value.absent(),
    this.occurrenceAt = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.duration = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<TaskActivity> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? taskId,
    Expression<String>? noteId,
    Expression<DateTime>? completedAt,
    Expression<String>? activityType,
    Expression<DateTime>? occurrenceAt,
    Expression<DateTime>? startAt,
    Expression<DateTime>? endAt,
    Expression<int>? duration,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (taskId != null) 'task_id': taskId,
      if (noteId != null) 'note_id': noteId,
      if (completedAt != null) 'completed_at': completedAt,
      if (activityType != null) 'activity_type': activityType,
      if (occurrenceAt != null) 'occurrence_at': occurrenceAt,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (duration != null) 'duration': duration,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskActivitiesCompanion copyWith({
    Value<String>? id,
    Value<String?>? userId,
    Value<String?>? taskId,
    Value<String?>? noteId,
    Value<Jiffy?>? completedAt,
    Value<String?>? activityType,
    Value<Jiffy?>? occurrenceAt,
    Value<Jiffy?>? startAt,
    Value<Jiffy?>? endAt,
    Value<int?>? duration,
    Value<Jiffy>? createdAt,
    Value<Jiffy?>? updatedAt,
    Value<Jiffy?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TaskActivitiesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      noteId: noteId ?? this.noteId,
      completedAt: completedAt ?? this.completedAt,
      activityType: activityType ?? this.activityType,
      occurrenceAt: occurrenceAt ?? this.occurrenceAt,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$convertercompletedAtn.toSql(completedAt.value),
      );
    }
    if (activityType.present) {
      map['activity_type'] = Variable<String>(activityType.value);
    }
    if (occurrenceAt.present) {
      map['occurrence_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$converteroccurrenceAtn.toSql(occurrenceAt.value),
      );
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$converterstartAtn.toSql(startAt.value),
      );
    }
    if (endAt.present) {
      map['end_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$converterendAtn.toSql(endAt.value),
      );
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$converterupdatedAtn.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(
        $TaskActivitiesTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('taskId: $taskId, ')
          ..write('noteId: $noteId, ')
          ..write('completedAt: $completedAt, ')
          ..write('activityType: $activityType, ')
          ..write('occurrenceAt: $occurrenceAt, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('duration: $duration, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskOccurrencesTable extends TaskOccurrences
    with TableInfo<$TaskOccurrencesTable, TaskOccurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskOccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy, DateTime> occurrenceAt =
      GeneratedColumn<DateTime>(
        'occurrence_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<Jiffy>($TaskOccurrencesTable.$converteroccurrenceAt);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> startAt =
      GeneratedColumn<DateTime>(
        'start_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TaskOccurrencesTable.$converterstartAtn);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> endAt =
      GeneratedColumn<DateTime>(
        'end_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TaskOccurrencesTable.$converterendAtn);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> dueAt =
      GeneratedColumn<DateTime>(
        'due_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TaskOccurrencesTable.$converterdueAtn);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      ).withConverter<Jiffy>($TaskOccurrencesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TaskOccurrencesTable.$converterupdatedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<Jiffy?, DateTime> deletedAt =
      GeneratedColumn<DateTime>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      ).withConverter<Jiffy?>($TaskOccurrencesTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    occurrenceAt,
    startAt,
    endAt,
    dueAt,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskOccurrence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {taskId, occurrenceAt},
  ];
  @override
  TaskOccurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskOccurrence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      occurrenceAt: $TaskOccurrencesTable.$converteroccurrenceAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}occurrence_at'],
        )!,
      ),
      startAt: $TaskOccurrencesTable.$converterstartAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}start_at'],
        ),
      ),
      endAt: $TaskOccurrencesTable.$converterendAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}end_at'],
        ),
      ),
      dueAt: $TaskOccurrencesTable.$converterdueAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}due_at'],
        ),
      ),
      createdAt: $TaskOccurrencesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $TaskOccurrencesTable.$converterupdatedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        ),
      ),
      deletedAt: $TaskOccurrencesTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $TaskOccurrencesTable createAlias(String alias) {
    return $TaskOccurrencesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converteroccurrenceAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterstartAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterstartAtn =
      JsonTypeConverter2.asNullable($converterstartAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterendAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterendAtn =
      JsonTypeConverter2.asNullable($converterendAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterdueAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterdueAtn =
      JsonTypeConverter2.asNullable($converterdueAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $convertercreatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterupdatedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterupdatedAtn =
      JsonTypeConverter2.asNullable($converterupdatedAt);
  static JsonTypeConverter2<Jiffy, DateTime, DateTime> $converterdeletedAt =
      const JiffyConverter();
  static JsonTypeConverter2<Jiffy?, DateTime?, DateTime?> $converterdeletedAtn =
      JsonTypeConverter2.asNullable($converterdeletedAt);
}

class TaskOccurrence extends DataClass implements Insertable<TaskOccurrence> {
  final String id;
  final String? taskId;
  final Jiffy occurrenceAt;
  final Jiffy? startAt;
  final Jiffy? endAt;
  final Jiffy? dueAt;
  final Jiffy createdAt;
  final Jiffy? updatedAt;
  final Jiffy? deletedAt;
  const TaskOccurrence({
    required this.id,
    this.taskId,
    required this.occurrenceAt,
    this.startAt,
    this.endAt,
    this.dueAt,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    {
      map['occurrence_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$converteroccurrenceAt.toSql(occurrenceAt),
      );
    }
    if (!nullToAbsent || startAt != null) {
      map['start_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$converterstartAtn.toSql(startAt),
      );
    }
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$converterendAtn.toSql(endAt),
      );
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$converterdueAtn.toSql(dueAt),
      );
    }
    {
      map['created_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$converterupdatedAtn.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  TaskOccurrencesCompanion toCompanion(bool nullToAbsent) {
    return TaskOccurrencesCompanion(
      id: Value(id),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      occurrenceAt: Value(occurrenceAt),
      startAt: startAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startAt),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TaskOccurrence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskOccurrence(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String?>(json['task_id']),
      occurrenceAt: $TaskOccurrencesTable.$converteroccurrenceAt.fromJson(
        serializer.fromJson<DateTime>(json['occurrence_at']),
      ),
      startAt: $TaskOccurrencesTable.$converterstartAtn.fromJson(
        serializer.fromJson<DateTime?>(json['start_at']),
      ),
      endAt: $TaskOccurrencesTable.$converterendAtn.fromJson(
        serializer.fromJson<DateTime?>(json['end_at']),
      ),
      dueAt: $TaskOccurrencesTable.$converterdueAtn.fromJson(
        serializer.fromJson<DateTime?>(json['due_at']),
      ),
      createdAt: $TaskOccurrencesTable.$convertercreatedAt.fromJson(
        serializer.fromJson<DateTime>(json['created_at']),
      ),
      updatedAt: $TaskOccurrencesTable.$converterupdatedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['updated_at']),
      ),
      deletedAt: $TaskOccurrencesTable.$converterdeletedAtn.fromJson(
        serializer.fromJson<DateTime?>(json['deleted_at']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'task_id': serializer.toJson<String?>(taskId),
      'occurrence_at': serializer.toJson<DateTime>(
        $TaskOccurrencesTable.$converteroccurrenceAt.toJson(occurrenceAt),
      ),
      'start_at': serializer.toJson<DateTime?>(
        $TaskOccurrencesTable.$converterstartAtn.toJson(startAt),
      ),
      'end_at': serializer.toJson<DateTime?>(
        $TaskOccurrencesTable.$converterendAtn.toJson(endAt),
      ),
      'due_at': serializer.toJson<DateTime?>(
        $TaskOccurrencesTable.$converterdueAtn.toJson(dueAt),
      ),
      'created_at': serializer.toJson<DateTime>(
        $TaskOccurrencesTable.$convertercreatedAt.toJson(createdAt),
      ),
      'updated_at': serializer.toJson<DateTime?>(
        $TaskOccurrencesTable.$converterupdatedAtn.toJson(updatedAt),
      ),
      'deleted_at': serializer.toJson<DateTime?>(
        $TaskOccurrencesTable.$converterdeletedAtn.toJson(deletedAt),
      ),
    };
  }

  TaskOccurrence copyWith({
    String? id,
    Value<String?> taskId = const Value.absent(),
    Jiffy? occurrenceAt,
    Value<Jiffy?> startAt = const Value.absent(),
    Value<Jiffy?> endAt = const Value.absent(),
    Value<Jiffy?> dueAt = const Value.absent(),
    Jiffy? createdAt,
    Value<Jiffy?> updatedAt = const Value.absent(),
    Value<Jiffy?> deletedAt = const Value.absent(),
  }) => TaskOccurrence(
    id: id ?? this.id,
    taskId: taskId.present ? taskId.value : this.taskId,
    occurrenceAt: occurrenceAt ?? this.occurrenceAt,
    startAt: startAt.present ? startAt.value : this.startAt,
    endAt: endAt.present ? endAt.value : this.endAt,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TaskOccurrence copyWithCompanion(TaskOccurrencesCompanion data) {
    return TaskOccurrence(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      occurrenceAt: data.occurrenceAt.present
          ? data.occurrenceAt.value
          : this.occurrenceAt,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskOccurrence(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('occurrenceAt: $occurrenceAt, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('dueAt: $dueAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    occurrenceAt,
    startAt,
    endAt,
    dueAt,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskOccurrence &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.occurrenceAt == this.occurrenceAt &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.dueAt == this.dueAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TaskOccurrencesCompanion extends UpdateCompanion<TaskOccurrence> {
  final Value<String> id;
  final Value<String?> taskId;
  final Value<Jiffy> occurrenceAt;
  final Value<Jiffy?> startAt;
  final Value<Jiffy?> endAt;
  final Value<Jiffy?> dueAt;
  final Value<Jiffy> createdAt;
  final Value<Jiffy?> updatedAt;
  final Value<Jiffy?> deletedAt;
  final Value<int> rowid;
  const TaskOccurrencesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.occurrenceAt = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskOccurrencesCompanion.insert({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    required Jiffy occurrenceAt,
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : occurrenceAt = Value(occurrenceAt);
  static Insertable<TaskOccurrence> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<DateTime>? occurrenceAt,
    Expression<DateTime>? startAt,
    Expression<DateTime>? endAt,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (occurrenceAt != null) 'occurrence_at': occurrenceAt,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (dueAt != null) 'due_at': dueAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskOccurrencesCompanion copyWith({
    Value<String>? id,
    Value<String?>? taskId,
    Value<Jiffy>? occurrenceAt,
    Value<Jiffy?>? startAt,
    Value<Jiffy?>? endAt,
    Value<Jiffy?>? dueAt,
    Value<Jiffy>? createdAt,
    Value<Jiffy?>? updatedAt,
    Value<Jiffy?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TaskOccurrencesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      occurrenceAt: occurrenceAt ?? this.occurrenceAt,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      dueAt: dueAt ?? this.dueAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (occurrenceAt.present) {
      map['occurrence_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$converteroccurrenceAt.toSql(occurrenceAt.value),
      );
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$converterstartAtn.toSql(startAt.value),
      );
    }
    if (endAt.present) {
      map['end_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$converterendAtn.toSql(endAt.value),
      );
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$converterdueAtn.toSql(dueAt.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$converterupdatedAtn.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(
        $TaskOccurrencesTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskOccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('occurrenceAt: $occurrenceAt, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('dueAt: $dueAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $NoteTagsTable noteTags = $NoteTagsTable(this);
  late final $TaskTagsTable taskTags = $TaskTagsTable(this);
  late final $TaskActivitiesTable taskActivities = $TaskActivitiesTable(this);
  late final $TaskOccurrencesTable taskOccurrences = $TaskOccurrencesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    notes,
    tags,
    noteTags,
    taskTags,
    taskActivities,
    taskOccurrences,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('note_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('note_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_activities', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_activities', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_occurrences', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String?> userId,
      required String title,
      Value<String?> parentId,
      Value<int> order,
      Value<Jiffy?> startAt,
      Value<Jiffy?> endAt,
      Value<bool> isAllDay,
      Value<Jiffy?> dueAt,
      Value<RecurrenceRule?> recurrenceRule,
      Value<String?> detachedFromTaskId,
      Value<Jiffy?> detachedRecurrenceAt,
      Value<DetachedReason?> detachedReason,
      Value<List<EventAlarm>> alarms,
      Value<TaskPriority?> priority,
      Value<String?> location,
      Value<String?> notes,
      Value<String?> timeZone,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String> title,
      Value<String?> parentId,
      Value<int> order,
      Value<Jiffy?> startAt,
      Value<Jiffy?> endAt,
      Value<bool> isAllDay,
      Value<Jiffy?> dueAt,
      Value<RecurrenceRule?> recurrenceRule,
      Value<String?> detachedFromTaskId,
      Value<Jiffy?> detachedRecurrenceAt,
      Value<DetachedReason?> detachedReason,
      Value<List<EventAlarm>> alarms,
      Value<TaskPriority?> priority,
      Value<String?> location,
      Value<String?> notes,
      Value<String?> timeZone,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _parentIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.tasks.parentId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TasksTable _detachedFromTaskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias(
        $_aliasNameGenerator(db.tasks.detachedFromTaskId, db.tasks.id),
      );

  $$TasksTableProcessedTableManager? get detachedFromTaskId {
    final $_column = $_itemColumn<String>('detached_from_task_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_detachedFromTaskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TaskTagsTable, List<TaskTag>> _taskTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.taskTags,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.taskTags.taskId),
  );

  $$TaskTagsTableProcessedTableManager get taskTagsRefs {
    final manager = $$TaskTagsTableTableManager(
      $_db,
      $_db.taskTags,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskActivitiesTable, List<TaskActivity>>
  _taskActivitiesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskActivities,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.taskActivities.taskId),
  );

  $$TaskActivitiesTableProcessedTableManager get taskActivitiesRefs {
    final manager = $$TaskActivitiesTableTableManager(
      $_db,
      $_db.taskActivities,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskActivitiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskOccurrencesTable, List<TaskOccurrence>>
  _taskOccurrencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskOccurrences,
    aliasName: $_aliasNameGenerator(db.tasks.id, db.taskOccurrences.taskId),
  );

  $$TaskOccurrencesTableProcessedTableManager get taskOccurrencesRefs {
    final manager = $$TaskOccurrencesTableTableManager(
      $_db,
      $_db.taskOccurrences,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskOccurrencesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get startAt =>
      $composableBuilder(
        column: $table.startAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get endAt =>
      $composableBuilder(
        column: $table.endAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get dueAt =>
      $composableBuilder(
        column: $table.dueAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<RecurrenceRule?, RecurrenceRule, String>
  get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime>
  get detachedRecurrenceAt => $composableBuilder(
    column: $table.detachedRecurrenceAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DetachedReason?, DetachedReason, String>
  get detachedReason => $composableBuilder(
    column: $table.detachedReason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<EventAlarm>, List<EventAlarm>, String>
  get alarms => $composableBuilder(
    column: $table.alarms,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskPriority?, TaskPriority, String>
  get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Jiffy, Jiffy, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$TasksTableFilterComposer get parentId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableFilterComposer get detachedFromTaskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.detachedFromTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> taskTagsRefs(
    Expression<bool> Function($$TaskTagsTableFilterComposer f) f,
  ) {
    final $$TaskTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTagsTableFilterComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskActivitiesRefs(
    Expression<bool> Function($$TaskActivitiesTableFilterComposer f) f,
  ) {
    final $$TaskActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskActivities,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.taskActivities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskOccurrencesRefs(
    Expression<bool> Function($$TaskOccurrencesTableFilterComposer f) f,
  ) {
    final $$TaskOccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskOccurrences,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskOccurrencesTableFilterComposer(
            $db: $db,
            $table: $db.taskOccurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detachedRecurrenceAt => $composableBuilder(
    column: $table.detachedRecurrenceAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detachedReason => $composableBuilder(
    column: $table.detachedReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alarms => $composableBuilder(
    column: $table.alarms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get parentId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableOrderingComposer get detachedFromTaskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.detachedFromTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<bool> get isAllDay =>
      $composableBuilder(column: $table.isAllDay, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RecurrenceRule?, String>
  get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get detachedRecurrenceAt =>
      $composableBuilder(
        column: $table.detachedRecurrenceAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DetachedReason?, String>
  get detachedReason => $composableBuilder(
    column: $table.detachedReason,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<EventAlarm>, String> get alarms =>
      $composableBuilder(column: $table.alarms, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskPriority?, String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get timeZone =>
      $composableBuilder(column: $table.timeZone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get parentId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableAnnotationComposer get detachedFromTaskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.detachedFromTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> taskTagsRefs<T extends Object>(
    Expression<T> Function($$TaskTagsTableAnnotationComposer a) f,
  ) {
    final $$TaskTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskActivitiesRefs<T extends Object>(
    Expression<T> Function($$TaskActivitiesTableAnnotationComposer a) f,
  ) {
    final $$TaskActivitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskActivities,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskActivitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskActivities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskOccurrencesRefs<T extends Object>(
    Expression<T> Function($$TaskOccurrencesTableAnnotationComposer a) f,
  ) {
    final $$TaskOccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskOccurrences,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskOccurrencesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskOccurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({
            bool parentId,
            bool detachedFromTaskId,
            bool taskTagsRefs,
            bool taskActivitiesRefs,
            bool taskOccurrencesRefs,
          })
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<Jiffy?> startAt = const Value.absent(),
                Value<Jiffy?> endAt = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<Jiffy?> dueAt = const Value.absent(),
                Value<RecurrenceRule?> recurrenceRule = const Value.absent(),
                Value<String?> detachedFromTaskId = const Value.absent(),
                Value<Jiffy?> detachedRecurrenceAt = const Value.absent(),
                Value<DetachedReason?> detachedReason = const Value.absent(),
                Value<List<EventAlarm>> alarms = const Value.absent(),
                Value<TaskPriority?> priority = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> timeZone = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                userId: userId,
                title: title,
                parentId: parentId,
                order: order,
                startAt: startAt,
                endAt: endAt,
                isAllDay: isAllDay,
                dueAt: dueAt,
                recurrenceRule: recurrenceRule,
                detachedFromTaskId: detachedFromTaskId,
                detachedRecurrenceAt: detachedRecurrenceAt,
                detachedReason: detachedReason,
                alarms: alarms,
                priority: priority,
                location: location,
                notes: notes,
                timeZone: timeZone,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                required String title,
                Value<String?> parentId = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<Jiffy?> startAt = const Value.absent(),
                Value<Jiffy?> endAt = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<Jiffy?> dueAt = const Value.absent(),
                Value<RecurrenceRule?> recurrenceRule = const Value.absent(),
                Value<String?> detachedFromTaskId = const Value.absent(),
                Value<Jiffy?> detachedRecurrenceAt = const Value.absent(),
                Value<DetachedReason?> detachedReason = const Value.absent(),
                Value<List<EventAlarm>> alarms = const Value.absent(),
                Value<TaskPriority?> priority = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> timeZone = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                parentId: parentId,
                order: order,
                startAt: startAt,
                endAt: endAt,
                isAllDay: isAllDay,
                dueAt: dueAt,
                recurrenceRule: recurrenceRule,
                detachedFromTaskId: detachedFromTaskId,
                detachedRecurrenceAt: detachedRecurrenceAt,
                detachedReason: detachedReason,
                alarms: alarms,
                priority: priority,
                location: location,
                notes: notes,
                timeZone: timeZone,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TasksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                parentId = false,
                detachedFromTaskId = false,
                taskTagsRefs = false,
                taskActivitiesRefs = false,
                taskOccurrencesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskTagsRefs) db.taskTags,
                    if (taskActivitiesRefs) db.taskActivities,
                    if (taskOccurrencesRefs) db.taskOccurrences,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentId,
                                    referencedTable: $$TasksTableReferences
                                        ._parentIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._parentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (detachedFromTaskId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.detachedFromTaskId,
                                    referencedTable: $$TasksTableReferences
                                        ._detachedFromTaskIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._detachedFromTaskIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskTagsRefs)
                        await $_getPrefetchedData<Task, $TasksTable, TaskTag>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskActivitiesRefs)
                        await $_getPrefetchedData<
                          Task,
                          $TasksTable,
                          TaskActivity
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskActivitiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskActivitiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskOccurrencesRefs)
                        await $_getPrefetchedData<
                          Task,
                          $TasksTable,
                          TaskOccurrence
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._taskOccurrencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).taskOccurrencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({
        bool parentId,
        bool detachedFromTaskId,
        bool taskTagsRefs,
        bool taskActivitiesRefs,
        bool taskOccurrencesRefs,
      })
    >;
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      Value<String> id,
      Value<String?> userId,
      required String title,
      Value<String?> content,
      Value<List<String>> images,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String> title,
      Value<String?> content,
      Value<List<String>> images,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });

final class $$NotesTableReferences
    extends BaseReferences<_$AppDatabase, $NotesTable, Note> {
  $$NotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NoteTagsTable, List<NoteTag>> _noteTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.noteTags,
    aliasName: $_aliasNameGenerator(db.notes.id, db.noteTags.noteId),
  );

  $$NoteTagsTableProcessedTableManager get noteTagsRefs {
    final manager = $$NoteTagsTableTableManager(
      $_db,
      $_db.noteTags,
    ).filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_noteTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskActivitiesTable, List<TaskActivity>>
  _taskActivitiesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.taskActivities,
    aliasName: $_aliasNameGenerator(db.notes.id, db.taskActivities.noteId),
  );

  $$TaskActivitiesTableProcessedTableManager get taskActivitiesRefs {
    final manager = $$TaskActivitiesTableTableManager(
      $_db,
      $_db.taskActivities,
    ).filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskActivitiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Jiffy, Jiffy, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> noteTagsRefs(
    Expression<bool> Function($$NoteTagsTableFilterComposer f) f,
  ) {
    final $$NoteTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteTags,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteTagsTableFilterComposer(
            $db: $db,
            $table: $db.noteTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskActivitiesRefs(
    Expression<bool> Function($$TaskActivitiesTableFilterComposer f) f,
  ) {
    final $$TaskActivitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskActivities,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskActivitiesTableFilterComposer(
            $db: $db,
            $table: $db.taskActivities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get images =>
      $composableBuilder(column: $table.images, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> noteTagsRefs<T extends Object>(
    Expression<T> Function($$NoteTagsTableAnnotationComposer a) f,
  ) {
    final $$NoteTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteTags,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.noteTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskActivitiesRefs<T extends Object>(
    Expression<T> Function($$TaskActivitiesTableAnnotationComposer a) f,
  ) {
    final $$TaskActivitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskActivities,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskActivitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskActivities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, $$NotesTableReferences),
          Note,
          PrefetchHooks Function({bool noteTagsRefs, bool taskActivitiesRefs})
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<List<String>> images = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                userId: userId,
                title: title,
                content: content,
                images: images,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                required String title,
                Value<String?> content = const Value.absent(),
                Value<List<String>> images = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                content: content,
                images: images,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$NotesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({noteTagsRefs = false, taskActivitiesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (noteTagsRefs) db.noteTags,
                    if (taskActivitiesRefs) db.taskActivities,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (noteTagsRefs)
                        await $_getPrefetchedData<Note, $NotesTable, NoteTag>(
                          currentTable: table,
                          referencedTable: $$NotesTableReferences
                              ._noteTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotesTableReferences(
                                db,
                                table,
                                p0,
                              ).noteTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.noteId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskActivitiesRefs)
                        await $_getPrefetchedData<
                          Note,
                          $NotesTable,
                          TaskActivity
                        >(
                          currentTable: table,
                          referencedTable: $$NotesTableReferences
                              ._taskActivitiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotesTableReferences(
                                db,
                                table,
                                p0,
                              ).taskActivitiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.noteId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, $$NotesTableReferences),
      Note,
      PrefetchHooks Function({bool noteTagsRefs, bool taskActivitiesRefs})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String?> userId,
      required String name,
      Value<String?> color,
      Value<int> order,
      Value<String?> parentId,
      Value<int> level,
      Value<ColorScheme?> darkColorScheme,
      Value<ColorScheme?> lightColorScheme,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String> name,
      Value<String?> color,
      Value<int> order,
      Value<String?> parentId,
      Value<int> level,
      Value<ColorScheme?> darkColorScheme,
      Value<ColorScheme?> lightColorScheme,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TagsTable _parentIdTable(_$AppDatabase db) =>
      db.tags.createAlias($_aliasNameGenerator(db.tags.parentId, db.tags.id));

  $$TagsTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$NoteTagsTable, List<NoteTag>> _noteTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.noteTags,
    aliasName: $_aliasNameGenerator(db.tags.id, db.noteTags.tagId),
  );

  $$NoteTagsTableProcessedTableManager get noteTagsRefs {
    final manager = $$NoteTagsTableTableManager(
      $_db,
      $_db.noteTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_noteTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskTagsTable, List<TaskTag>> _taskTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.taskTags,
    aliasName: $_aliasNameGenerator(db.tags.id, db.taskTags.tagId),
  );

  $$TaskTagsTableProcessedTableManager get taskTagsRefs {
    final manager = $$TaskTagsTableTableManager(
      $_db,
      $_db.taskTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ColorScheme?, ColorScheme, String>
  get darkColorScheme => $composableBuilder(
    column: $table.darkColorScheme,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ColorScheme?, ColorScheme, String>
  get lightColorScheme => $composableBuilder(
    column: $table.lightColorScheme,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Jiffy, Jiffy, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$TagsTableFilterComposer get parentId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> noteTagsRefs(
    Expression<bool> Function($$NoteTagsTableFilterComposer f) f,
  ) {
    final $$NoteTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteTagsTableFilterComposer(
            $db: $db,
            $table: $db.noteTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskTagsRefs(
    Expression<bool> Function($$TaskTagsTableFilterComposer f) f,
  ) {
    final $$TaskTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTagsTableFilterComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get darkColorScheme => $composableBuilder(
    column: $table.darkColorScheme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lightColorScheme => $composableBuilder(
    column: $table.lightColorScheme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TagsTableOrderingComposer get parentId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ColorScheme?, String> get darkColorScheme =>
      $composableBuilder(
        column: $table.darkColorScheme,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<ColorScheme?, String> get lightColorScheme =>
      $composableBuilder(
        column: $table.lightColorScheme,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Jiffy, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$TagsTableAnnotationComposer get parentId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> noteTagsRefs<T extends Object>(
    Expression<T> Function($$NoteTagsTableAnnotationComposer a) f,
  ) {
    final $$NoteTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.noteTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskTagsRefs<T extends Object>(
    Expression<T> Function($$TaskTagsTableAnnotationComposer a) f,
  ) {
    final $$TaskTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({
            bool parentId,
            bool noteTagsRefs,
            bool taskTagsRefs,
          })
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<ColorScheme?> darkColorScheme = const Value.absent(),
                Value<ColorScheme?> lightColorScheme = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                userId: userId,
                name: name,
                color: color,
                order: order,
                parentId: parentId,
                level: level,
                darkColorScheme: darkColorScheme,
                lightColorScheme: lightColorScheme,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                required String name,
                Value<String?> color = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<ColorScheme?> darkColorScheme = const Value.absent(),
                Value<ColorScheme?> lightColorScheme = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                color: color,
                order: order,
                parentId: parentId,
                level: level,
                darkColorScheme: darkColorScheme,
                lightColorScheme: lightColorScheme,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({parentId = false, noteTagsRefs = false, taskTagsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (noteTagsRefs) db.noteTags,
                    if (taskTagsRefs) db.taskTags,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentId,
                                    referencedTable: $$TagsTableReferences
                                        ._parentIdTable(db),
                                    referencedColumn: $$TagsTableReferences
                                        ._parentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (noteTagsRefs)
                        await $_getPrefetchedData<Tag, $TagsTable, NoteTag>(
                          currentTable: table,
                          referencedTable: $$TagsTableReferences
                              ._noteTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TagsTableReferences(db, table, p0).noteTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tagId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskTagsRefs)
                        await $_getPrefetchedData<Tag, $TagsTable, TaskTag>(
                          currentTable: table,
                          referencedTable: $$TagsTableReferences
                              ._taskTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TagsTableReferences(db, table, p0).taskTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tagId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({
        bool parentId,
        bool noteTagsRefs,
        bool taskTagsRefs,
      })
    >;
typedef $$NoteTagsTableCreateCompanionBuilder =
    NoteTagsCompanion Function({
      Value<String> id,
      required String noteId,
      required String tagId,
      Value<bool> isParent,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });
typedef $$NoteTagsTableUpdateCompanionBuilder =
    NoteTagsCompanion Function({
      Value<String> id,
      Value<String> noteId,
      Value<String> tagId,
      Value<bool> isParent,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });

final class $$NoteTagsTableReferences
    extends BaseReferences<_$AppDatabase, $NoteTagsTable, NoteTag> {
  $$NoteTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NotesTable _noteIdTable(_$AppDatabase db) => db.notes.createAlias(
    $_aliasNameGenerator(db.noteTags.noteId, db.notes.id),
  );

  $$NotesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias($_aliasNameGenerator(db.noteTags.tagId, db.tags.id));

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NoteTagsTableFilterComposer
    extends Composer<_$AppDatabase, $NoteTagsTable> {
  $$NoteTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isParent => $composableBuilder(
    column: $table.isParent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Jiffy, Jiffy, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$NotesTableFilterComposer get noteId {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $NoteTagsTable> {
  $$NoteTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isParent => $composableBuilder(
    column: $table.isParent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotesTableOrderingComposer get noteId {
    final $$NotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableOrderingComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NoteTagsTable> {
  $$NoteTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isParent =>
      $composableBuilder(column: $table.isParent, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$NotesTableAnnotationComposer get noteId {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NoteTagsTable,
          NoteTag,
          $$NoteTagsTableFilterComposer,
          $$NoteTagsTableOrderingComposer,
          $$NoteTagsTableAnnotationComposer,
          $$NoteTagsTableCreateCompanionBuilder,
          $$NoteTagsTableUpdateCompanionBuilder,
          (NoteTag, $$NoteTagsTableReferences),
          NoteTag,
          PrefetchHooks Function({bool noteId, bool tagId})
        > {
  $$NoteTagsTableTableManager(_$AppDatabase db, $NoteTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> noteId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<bool> isParent = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteTagsCompanion(
                id: id,
                noteId: noteId,
                tagId: tagId,
                isParent: isParent,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String noteId,
                required String tagId,
                Value<bool> isParent = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteTagsCompanion.insert(
                id: id,
                noteId: noteId,
                tagId: tagId,
                isParent: isParent,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NoteTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({noteId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (noteId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.noteId,
                                referencedTable: $$NoteTagsTableReferences
                                    ._noteIdTable(db),
                                referencedColumn: $$NoteTagsTableReferences
                                    ._noteIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$NoteTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$NoteTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NoteTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NoteTagsTable,
      NoteTag,
      $$NoteTagsTableFilterComposer,
      $$NoteTagsTableOrderingComposer,
      $$NoteTagsTableAnnotationComposer,
      $$NoteTagsTableCreateCompanionBuilder,
      $$NoteTagsTableUpdateCompanionBuilder,
      (NoteTag, $$NoteTagsTableReferences),
      NoteTag,
      PrefetchHooks Function({bool noteId, bool tagId})
    >;
typedef $$TaskTagsTableCreateCompanionBuilder =
    TaskTagsCompanion Function({
      Value<String> id,
      required String taskId,
      required String tagId,
      Value<bool> isParent,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });
typedef $$TaskTagsTableUpdateCompanionBuilder =
    TaskTagsCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> tagId,
      Value<bool> isParent,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });

final class $$TaskTagsTableReferences
    extends BaseReferences<_$AppDatabase, $TaskTagsTable, TaskTag> {
  $$TaskTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.taskTags.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias($_aliasNameGenerator(db.taskTags.tagId, db.tags.id));

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskTagsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskTagsTable> {
  $$TaskTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isParent => $composableBuilder(
    column: $table.isParent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Jiffy, Jiffy, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskTagsTable> {
  $$TaskTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isParent => $composableBuilder(
    column: $table.isParent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskTagsTable> {
  $$TaskTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isParent =>
      $composableBuilder(column: $table.isParent, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskTagsTable,
          TaskTag,
          $$TaskTagsTableFilterComposer,
          $$TaskTagsTableOrderingComposer,
          $$TaskTagsTableAnnotationComposer,
          $$TaskTagsTableCreateCompanionBuilder,
          $$TaskTagsTableUpdateCompanionBuilder,
          (TaskTag, $$TaskTagsTableReferences),
          TaskTag,
          PrefetchHooks Function({bool taskId, bool tagId})
        > {
  $$TaskTagsTableTableManager(_$AppDatabase db, $TaskTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<bool> isParent = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTagsCompanion(
                id: id,
                taskId: taskId,
                tagId: tagId,
                isParent: isParent,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String taskId,
                required String tagId,
                Value<bool> isParent = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTagsCompanion.insert(
                id: id,
                taskId: taskId,
                tagId: tagId,
                isParent: isParent,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$TaskTagsTableReferences
                                    ._taskIdTable(db),
                                referencedColumn: $$TaskTagsTableReferences
                                    ._taskIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$TaskTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$TaskTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskTagsTable,
      TaskTag,
      $$TaskTagsTableFilterComposer,
      $$TaskTagsTableOrderingComposer,
      $$TaskTagsTableAnnotationComposer,
      $$TaskTagsTableCreateCompanionBuilder,
      $$TaskTagsTableUpdateCompanionBuilder,
      (TaskTag, $$TaskTagsTableReferences),
      TaskTag,
      PrefetchHooks Function({bool taskId, bool tagId})
    >;
typedef $$TaskActivitiesTableCreateCompanionBuilder =
    TaskActivitiesCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String?> taskId,
      Value<String?> noteId,
      Value<Jiffy?> completedAt,
      Value<String?> activityType,
      Value<Jiffy?> occurrenceAt,
      Value<Jiffy?> startAt,
      Value<Jiffy?> endAt,
      Value<int?> duration,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });
typedef $$TaskActivitiesTableUpdateCompanionBuilder =
    TaskActivitiesCompanion Function({
      Value<String> id,
      Value<String?> userId,
      Value<String?> taskId,
      Value<String?> noteId,
      Value<Jiffy?> completedAt,
      Value<String?> activityType,
      Value<Jiffy?> occurrenceAt,
      Value<Jiffy?> startAt,
      Value<Jiffy?> endAt,
      Value<int?> duration,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });

final class $$TaskActivitiesTableReferences
    extends BaseReferences<_$AppDatabase, $TaskActivitiesTable, TaskActivity> {
  $$TaskActivitiesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.taskActivities.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager? get taskId {
    final $_column = $_itemColumn<String>('task_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NotesTable _noteIdTable(_$AppDatabase db) => db.notes.createAlias(
    $_aliasNameGenerator(db.taskActivities.noteId, db.notes.id),
  );

  $$NotesTableProcessedTableManager? get noteId {
    final $_column = $_itemColumn<String>('note_id');
    if ($_column == null) return null;
    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskActivitiesTable> {
  $$TaskActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get occurrenceAt =>
      $composableBuilder(
        column: $table.occurrenceAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get startAt =>
      $composableBuilder(
        column: $table.startAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get endAt =>
      $composableBuilder(
        column: $table.endAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Jiffy, Jiffy, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotesTableFilterComposer get noteId {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskActivitiesTable> {
  $$TaskActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurrenceAt => $composableBuilder(
    column: $table.occurrenceAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotesTableOrderingComposer get noteId {
    final $$NotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableOrderingComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskActivitiesTable> {
  $$TaskActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get activityType => $composableBuilder(
    column: $table.activityType,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get occurrenceAt =>
      $composableBuilder(
        column: $table.occurrenceAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotesTableAnnotationComposer get noteId {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskActivitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskActivitiesTable,
          TaskActivity,
          $$TaskActivitiesTableFilterComposer,
          $$TaskActivitiesTableOrderingComposer,
          $$TaskActivitiesTableAnnotationComposer,
          $$TaskActivitiesTableCreateCompanionBuilder,
          $$TaskActivitiesTableUpdateCompanionBuilder,
          (TaskActivity, $$TaskActivitiesTableReferences),
          TaskActivity,
          PrefetchHooks Function({bool taskId, bool noteId})
        > {
  $$TaskActivitiesTableTableManager(
    _$AppDatabase db,
    $TaskActivitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
                Value<Jiffy?> completedAt = const Value.absent(),
                Value<String?> activityType = const Value.absent(),
                Value<Jiffy?> occurrenceAt = const Value.absent(),
                Value<Jiffy?> startAt = const Value.absent(),
                Value<Jiffy?> endAt = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskActivitiesCompanion(
                id: id,
                userId: userId,
                taskId: taskId,
                noteId: noteId,
                completedAt: completedAt,
                activityType: activityType,
                occurrenceAt: occurrenceAt,
                startAt: startAt,
                endAt: endAt,
                duration: duration,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> noteId = const Value.absent(),
                Value<Jiffy?> completedAt = const Value.absent(),
                Value<String?> activityType = const Value.absent(),
                Value<Jiffy?> occurrenceAt = const Value.absent(),
                Value<Jiffy?> startAt = const Value.absent(),
                Value<Jiffy?> endAt = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskActivitiesCompanion.insert(
                id: id,
                userId: userId,
                taskId: taskId,
                noteId: noteId,
                completedAt: completedAt,
                activityType: activityType,
                occurrenceAt: occurrenceAt,
                startAt: startAt,
                endAt: endAt,
                duration: duration,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskActivitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false, noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$TaskActivitiesTableReferences
                                    ._taskIdTable(db),
                                referencedColumn:
                                    $$TaskActivitiesTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (noteId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.noteId,
                                referencedTable: $$TaskActivitiesTableReferences
                                    ._noteIdTable(db),
                                referencedColumn:
                                    $$TaskActivitiesTableReferences
                                        ._noteIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskActivitiesTable,
      TaskActivity,
      $$TaskActivitiesTableFilterComposer,
      $$TaskActivitiesTableOrderingComposer,
      $$TaskActivitiesTableAnnotationComposer,
      $$TaskActivitiesTableCreateCompanionBuilder,
      $$TaskActivitiesTableUpdateCompanionBuilder,
      (TaskActivity, $$TaskActivitiesTableReferences),
      TaskActivity,
      PrefetchHooks Function({bool taskId, bool noteId})
    >;
typedef $$TaskOccurrencesTableCreateCompanionBuilder =
    TaskOccurrencesCompanion Function({
      Value<String> id,
      Value<String?> taskId,
      required Jiffy occurrenceAt,
      Value<Jiffy?> startAt,
      Value<Jiffy?> endAt,
      Value<Jiffy?> dueAt,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });
typedef $$TaskOccurrencesTableUpdateCompanionBuilder =
    TaskOccurrencesCompanion Function({
      Value<String> id,
      Value<String?> taskId,
      Value<Jiffy> occurrenceAt,
      Value<Jiffy?> startAt,
      Value<Jiffy?> endAt,
      Value<Jiffy?> dueAt,
      Value<Jiffy> createdAt,
      Value<Jiffy?> updatedAt,
      Value<Jiffy?> deletedAt,
      Value<int> rowid,
    });

final class $$TaskOccurrencesTableReferences
    extends
        BaseReferences<_$AppDatabase, $TaskOccurrencesTable, TaskOccurrence> {
  $$TaskOccurrencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias(
    $_aliasNameGenerator(db.taskOccurrences.taskId, db.tasks.id),
  );

  $$TasksTableProcessedTableManager? get taskId {
    final $_column = $_itemColumn<String>('task_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskOccurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskOccurrencesTable> {
  $$TaskOccurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Jiffy, Jiffy, DateTime> get occurrenceAt =>
      $composableBuilder(
        column: $table.occurrenceAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get startAt =>
      $composableBuilder(
        column: $table.startAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get endAt =>
      $composableBuilder(
        column: $table.endAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get dueAt =>
      $composableBuilder(
        column: $table.dueAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy, Jiffy, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Jiffy?, Jiffy, DateTime> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskOccurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskOccurrencesTable> {
  $$TaskOccurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurrenceAt => $composableBuilder(
    column: $table.occurrenceAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskOccurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskOccurrencesTable> {
  $$TaskOccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy, DateTime> get occurrenceAt =>
      $composableBuilder(
        column: $table.occurrenceAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Jiffy?, DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskOccurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskOccurrencesTable,
          TaskOccurrence,
          $$TaskOccurrencesTableFilterComposer,
          $$TaskOccurrencesTableOrderingComposer,
          $$TaskOccurrencesTableAnnotationComposer,
          $$TaskOccurrencesTableCreateCompanionBuilder,
          $$TaskOccurrencesTableUpdateCompanionBuilder,
          (TaskOccurrence, $$TaskOccurrencesTableReferences),
          TaskOccurrence,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskOccurrencesTableTableManager(
    _$AppDatabase db,
    $TaskOccurrencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskOccurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskOccurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskOccurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<Jiffy> occurrenceAt = const Value.absent(),
                Value<Jiffy?> startAt = const Value.absent(),
                Value<Jiffy?> endAt = const Value.absent(),
                Value<Jiffy?> dueAt = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskOccurrencesCompanion(
                id: id,
                taskId: taskId,
                occurrenceAt: occurrenceAt,
                startAt: startAt,
                endAt: endAt,
                dueAt: dueAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                required Jiffy occurrenceAt,
                Value<Jiffy?> startAt = const Value.absent(),
                Value<Jiffy?> endAt = const Value.absent(),
                Value<Jiffy?> dueAt = const Value.absent(),
                Value<Jiffy> createdAt = const Value.absent(),
                Value<Jiffy?> updatedAt = const Value.absent(),
                Value<Jiffy?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskOccurrencesCompanion.insert(
                id: id,
                taskId: taskId,
                occurrenceAt: occurrenceAt,
                startAt: startAt,
                endAt: endAt,
                dueAt: dueAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskOccurrencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$TaskOccurrencesTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$TaskOccurrencesTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskOccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskOccurrencesTable,
      TaskOccurrence,
      $$TaskOccurrencesTableFilterComposer,
      $$TaskOccurrencesTableOrderingComposer,
      $$TaskOccurrencesTableAnnotationComposer,
      $$TaskOccurrencesTableCreateCompanionBuilder,
      $$TaskOccurrencesTableUpdateCompanionBuilder,
      (TaskOccurrence, $$TaskOccurrencesTableReferences),
      TaskOccurrence,
      PrefetchHooks Function({bool taskId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$NoteTagsTableTableManager get noteTags =>
      $$NoteTagsTableTableManager(_db, _db.noteTags);
  $$TaskTagsTableTableManager get taskTags =>
      $$TaskTagsTableTableManager(_db, _db.taskTags);
  $$TaskActivitiesTableTableManager get taskActivities =>
      $$TaskActivitiesTableTableManager(_db, _db.taskActivities);
  $$TaskOccurrencesTableTableManager get taskOccurrences =>
      $$TaskOccurrencesTableTableManager(_db, _db.taskOccurrences);
}
