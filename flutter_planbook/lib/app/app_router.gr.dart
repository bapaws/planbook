// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i30;
import 'package:collection/collection.dart' as _i35;
import 'package:flutter/cupertino.dart' as _i37;
import 'package:flutter/material.dart' as _i32;
import 'package:flutter_planbook/note/gallery/view/note_gallery_page.dart'
    as _i3;
import 'package:flutter_planbook/note/list/view/note_list_page.dart' as _i4;
import 'package:flutter_planbook/note/new/view/note_new_fullscreen_page.dart'
    as _i5;
import 'package:flutter_planbook/note/new/view/note_new_page.dart' as _i6;
import 'package:flutter_planbook/note/timeline/view/note_timeline_page.dart'
    as _i8;
import 'package:flutter_planbook/root/home/view/root_home_page.dart' as _i9;
import 'package:flutter_planbook/root/journal/view/root_journal_page.dart'
    as _i10;
import 'package:flutter_planbook/root/note/view/root_note_page.dart' as _i11;
import 'package:flutter_planbook/root/tag/view/note_tag_page.dart' as _i7;
import 'package:flutter_planbook/root/task/view/root_task_page.dart' as _i12;
import 'package:flutter_planbook/settings/about/view/about_page.dart' as _i1;
import 'package:flutter_planbook/settings/color/view/settings_seed_color_page.dart'
    as _i16;
import 'package:flutter_planbook/settings/dark/view/settings_dark_mode_page.dart'
    as _i13;
import 'package:flutter_planbook/settings/feedback/view/feedback_page.dart'
    as _i2;
import 'package:flutter_planbook/settings/home/view/settings_home_page.dart'
    as _i14;
import 'package:flutter_planbook/settings/icon/view/settings_icon_page.dart'
    as _i15;
import 'package:flutter_planbook/tag/list/bloc/tag_list_bloc.dart' as _i34;
import 'package:flutter_planbook/tag/list/view/tag_list_page.dart' as _i17;
import 'package:flutter_planbook/tag/new/view/tag_new_page.dart' as _i18;
import 'package:flutter_planbook/tag/picker/view/tag_picker_page.dart' as _i19;
import 'package:flutter_planbook/task/detail/view/task_detail_page.dart'
    as _i21;
import 'package:flutter_planbook/task/inbox/view/task_inbox_page.dart' as _i22;
import 'package:flutter_planbook/task/list/view/task_list_page.dart' as _i23;
import 'package:flutter_planbook/task/new/view/task_new_page.dart' as _i24;
import 'package:flutter_planbook/task/overdue/view/task_overdue_page.dart'
    as _i25;
import 'package:flutter_planbook/task/picker/view/task_date_picker_page.dart'
    as _i20;
import 'package:flutter_planbook/task/picker/view/task_picker_page.dart'
    as _i26;
import 'package:flutter_planbook/task/picker/view/task_priority_picker_page.dart'
    as _i27;
import 'package:flutter_planbook/task/tag/view/task_tag_page.dart' as _i28;
import 'package:flutter_planbook/task/today/view/task_today_page.dart' as _i29;
import 'package:planbook_api/database/task_priority.dart' as _i38;
import 'package:planbook_api/entity/tag_entity.dart' as _i33;
import 'package:planbook_api/planbook_api.dart' as _i36;
import 'package:planbook_repository/planbook_repository.dart' as _i31;

/// generated route for
/// [_i1.AboutPage]
class AboutRoute extends _i30.PageRouteInfo<void> {
  const AboutRoute({List<_i30.PageRouteInfo>? children})
    : super(AboutRoute.name, initialChildren: children);

  static const String name = 'AboutRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i1.AboutPage();
    },
  );
}

/// generated route for
/// [_i2.FeedbackPage]
class FeedbackRoute extends _i30.PageRouteInfo<void> {
  const FeedbackRoute({List<_i30.PageRouteInfo>? children})
    : super(FeedbackRoute.name, initialChildren: children);

  static const String name = 'FeedbackRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i2.FeedbackPage();
    },
  );
}

/// generated route for
/// [_i3.NoteGalleryPage]
class NoteGalleryRoute extends _i30.PageRouteInfo<void> {
  const NoteGalleryRoute({List<_i30.PageRouteInfo>? children})
    : super(NoteGalleryRoute.name, initialChildren: children);

  static const String name = 'NoteGalleryRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i3.NoteGalleryPage();
    },
  );
}

/// generated route for
/// [_i4.NoteListPage]
class NoteListRoute extends _i30.PageRouteInfo<void> {
  const NoteListRoute({List<_i30.PageRouteInfo>? children})
    : super(NoteListRoute.name, initialChildren: children);

  static const String name = 'NoteListRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i4.NoteListPage();
    },
  );
}

/// generated route for
/// [_i5.NoteNewFullscreenPage]
class NoteNewFullscreenRoute
    extends _i30.PageRouteInfo<NoteNewFullscreenRouteArgs> {
  NoteNewFullscreenRoute({
    _i31.NoteEntity? initialNote,
    _i32.Key? key,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         NoteNewFullscreenRoute.name,
         args: NoteNewFullscreenRouteArgs(initialNote: initialNote, key: key),
         initialChildren: children,
       );

  static const String name = 'NoteNewFullscreenRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteNewFullscreenRouteArgs>(
        orElse: () => const NoteNewFullscreenRouteArgs(),
      );
      return _i5.NoteNewFullscreenPage(
        initialNote: args.initialNote,
        key: args.key,
      );
    },
  );
}

class NoteNewFullscreenRouteArgs {
  const NoteNewFullscreenRouteArgs({this.initialNote, this.key});

  final _i31.NoteEntity? initialNote;

  final _i32.Key? key;

  @override
  String toString() {
    return 'NoteNewFullscreenRouteArgs{initialNote: $initialNote, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteNewFullscreenRouteArgs) return false;
    return initialNote == other.initialNote && key == other.key;
  }

  @override
  int get hashCode => initialNote.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i6.NoteNewPage]
class NoteNewRoute extends _i30.PageRouteInfo<NoteNewRouteArgs> {
  NoteNewRoute({
    _i31.NoteEntity? initialNote,
    _i31.TaskEntity? initialTask,
    _i32.Key? key,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         NoteNewRoute.name,
         args: NoteNewRouteArgs(
           initialNote: initialNote,
           initialTask: initialTask,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'NoteNewRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteNewRouteArgs>(
        orElse: () => const NoteNewRouteArgs(),
      );
      return _i6.NoteNewPage(
        initialNote: args.initialNote,
        initialTask: args.initialTask,
        key: args.key,
      );
    },
  );
}

class NoteNewRouteArgs {
  const NoteNewRouteArgs({this.initialNote, this.initialTask, this.key});

  final _i31.NoteEntity? initialNote;

  final _i31.TaskEntity? initialTask;

  final _i32.Key? key;

  @override
  String toString() {
    return 'NoteNewRouteArgs{initialNote: $initialNote, initialTask: $initialTask, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteNewRouteArgs) return false;
    return initialNote == other.initialNote &&
        initialTask == other.initialTask &&
        key == other.key;
  }

  @override
  int get hashCode =>
      initialNote.hashCode ^ initialTask.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i7.NoteTagPage]
class NoteTagRoute extends _i30.PageRouteInfo<NoteTagRouteArgs> {
  NoteTagRoute({
    required _i33.TagEntity tag,
    _i32.Key? key,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         NoteTagRoute.name,
         args: NoteTagRouteArgs(tag: tag, key: key),
         initialChildren: children,
       );

  static const String name = 'NoteTagRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteTagRouteArgs>();
      return _i7.NoteTagPage(tag: args.tag, key: args.key);
    },
  );
}

class NoteTagRouteArgs {
  const NoteTagRouteArgs({required this.tag, this.key});

  final _i33.TagEntity tag;

  final _i32.Key? key;

  @override
  String toString() {
    return 'NoteTagRouteArgs{tag: $tag, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteTagRouteArgs) return false;
    return tag == other.tag && key == other.key;
  }

  @override
  int get hashCode => tag.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i8.NoteTimelinePage]
class NoteTimelineRoute extends _i30.PageRouteInfo<void> {
  const NoteTimelineRoute({List<_i30.PageRouteInfo>? children})
    : super(NoteTimelineRoute.name, initialChildren: children);

  static const String name = 'NoteTimelineRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i8.NoteTimelinePage();
    },
  );
}

/// generated route for
/// [_i9.RootHomePage]
class RootHomeRoute extends _i30.PageRouteInfo<void> {
  const RootHomeRoute({List<_i30.PageRouteInfo>? children})
    : super(RootHomeRoute.name, initialChildren: children);

  static const String name = 'RootHomeRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i9.RootHomePage();
    },
  );
}

/// generated route for
/// [_i10.RootJournalPage]
class RootJournalRoute extends _i30.PageRouteInfo<void> {
  const RootJournalRoute({List<_i30.PageRouteInfo>? children})
    : super(RootJournalRoute.name, initialChildren: children);

  static const String name = 'RootJournalRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i10.RootJournalPage();
    },
  );
}

/// generated route for
/// [_i11.RootNotePage]
class RootNoteRoute extends _i30.PageRouteInfo<void> {
  const RootNoteRoute({List<_i30.PageRouteInfo>? children})
    : super(RootNoteRoute.name, initialChildren: children);

  static const String name = 'RootNoteRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i11.RootNotePage();
    },
  );
}

/// generated route for
/// [_i12.RootTaskPage]
class RootTaskRoute extends _i30.PageRouteInfo<void> {
  const RootTaskRoute({List<_i30.PageRouteInfo>? children})
    : super(RootTaskRoute.name, initialChildren: children);

  static const String name = 'RootTaskRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i12.RootTaskPage();
    },
  );
}

/// generated route for
/// [_i13.SettingsDarkModePage]
class SettingsDarkModeRoute extends _i30.PageRouteInfo<void> {
  const SettingsDarkModeRoute({List<_i30.PageRouteInfo>? children})
    : super(SettingsDarkModeRoute.name, initialChildren: children);

  static const String name = 'SettingsDarkModeRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i13.SettingsDarkModePage();
    },
  );
}

/// generated route for
/// [_i14.SettingsHomePage]
class SettingsHomeRoute extends _i30.PageRouteInfo<void> {
  const SettingsHomeRoute({List<_i30.PageRouteInfo>? children})
    : super(SettingsHomeRoute.name, initialChildren: children);

  static const String name = 'SettingsHomeRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i14.SettingsHomePage();
    },
  );
}

/// generated route for
/// [_i15.SettingsIconPage]
class SettingsIconRoute extends _i30.PageRouteInfo<void> {
  const SettingsIconRoute({List<_i30.PageRouteInfo>? children})
    : super(SettingsIconRoute.name, initialChildren: children);

  static const String name = 'SettingsIconRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i15.SettingsIconPage();
    },
  );
}

/// generated route for
/// [_i16.SettingsSeedColorPage]
class SettingsSeedColorRoute extends _i30.PageRouteInfo<void> {
  const SettingsSeedColorRoute({List<_i30.PageRouteInfo>? children})
    : super(SettingsSeedColorRoute.name, initialChildren: children);

  static const String name = 'SettingsSeedColorRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i16.SettingsSeedColorPage();
    },
  );
}

/// generated route for
/// [_i17.TagListPage]
class TagListRoute extends _i30.PageRouteInfo<TagListRouteArgs> {
  TagListRoute({
    required _i34.TagListMode mode,
    required List<_i31.TagEntity> selectedTags,
    _i32.Key? key,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         TagListRoute.name,
         args: TagListRouteArgs(
           mode: mode,
           selectedTags: selectedTags,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TagListRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagListRouteArgs>();
      return _i17.TagListPage(
        mode: args.mode,
        selectedTags: args.selectedTags,
        key: args.key,
      );
    },
  );
}

class TagListRouteArgs {
  const TagListRouteArgs({
    required this.mode,
    required this.selectedTags,
    this.key,
  });

  final _i34.TagListMode mode;

  final List<_i31.TagEntity> selectedTags;

  final _i32.Key? key;

  @override
  String toString() {
    return 'TagListRouteArgs{mode: $mode, selectedTags: $selectedTags, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagListRouteArgs) return false;
    return mode == other.mode &&
        const _i35.ListEquality<_i31.TagEntity>().equals(
          selectedTags,
          other.selectedTags,
        ) &&
        key == other.key;
  }

  @override
  int get hashCode =>
      mode.hashCode ^
      const _i35.ListEquality<_i31.TagEntity>().hash(selectedTags) ^
      key.hashCode;
}

/// generated route for
/// [_i18.TagNewPage]
class TagNewRoute extends _i30.PageRouteInfo<TagNewRouteArgs> {
  TagNewRoute({
    _i36.TagEntity? initialTag,
    _i37.Key? key,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         TagNewRoute.name,
         args: TagNewRouteArgs(initialTag: initialTag, key: key),
         initialChildren: children,
       );

  static const String name = 'TagNewRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagNewRouteArgs>(
        orElse: () => const TagNewRouteArgs(),
      );
      return _i18.TagNewPage(initialTag: args.initialTag, key: args.key);
    },
  );
}

class TagNewRouteArgs {
  const TagNewRouteArgs({this.initialTag, this.key});

  final _i36.TagEntity? initialTag;

  final _i37.Key? key;

  @override
  String toString() {
    return 'TagNewRouteArgs{initialTag: $initialTag, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagNewRouteArgs) return false;
    return initialTag == other.initialTag && key == other.key;
  }

  @override
  int get hashCode => initialTag.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i19.TagPickerPage]
class TagPickerRoute extends _i30.PageRouteInfo<TagPickerRouteArgs> {
  TagPickerRoute({
    required List<_i33.TagEntity> selectedTags,
    required _i37.ValueChanged<List<_i33.TagEntity>> onSelected,
    _i37.Key? key,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         TagPickerRoute.name,
         args: TagPickerRouteArgs(
           selectedTags: selectedTags,
           onSelected: onSelected,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TagPickerRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagPickerRouteArgs>();
      return _i19.TagPickerPage(
        selectedTags: args.selectedTags,
        onSelected: args.onSelected,
        key: args.key,
      );
    },
  );
}

class TagPickerRouteArgs {
  const TagPickerRouteArgs({
    required this.selectedTags,
    required this.onSelected,
    this.key,
  });

  final List<_i33.TagEntity> selectedTags;

  final _i37.ValueChanged<List<_i33.TagEntity>> onSelected;

  final _i37.Key? key;

  @override
  String toString() {
    return 'TagPickerRouteArgs{selectedTags: $selectedTags, onSelected: $onSelected, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagPickerRouteArgs) return false;
    return const _i35.ListEquality<_i33.TagEntity>().equals(
          selectedTags,
          other.selectedTags,
        ) &&
        onSelected == other.onSelected &&
        key == other.key;
  }

  @override
  int get hashCode =>
      const _i35.ListEquality<_i33.TagEntity>().hash(selectedTags) ^
      onSelected.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i20.TaskDatePickerPage]
class TaskDatePickerRoute extends _i30.PageRouteInfo<TaskDatePickerRouteArgs> {
  TaskDatePickerRoute({
    required _i31.Jiffy date,
    _i37.ValueChanged<_i31.Jiffy?>? onDateChanged,
    _i37.Key? key,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         TaskDatePickerRoute.name,
         args: TaskDatePickerRouteArgs(
           date: date,
           onDateChanged: onDateChanged,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TaskDatePickerRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDatePickerRouteArgs>();
      return _i20.TaskDatePickerPage(
        date: args.date,
        onDateChanged: args.onDateChanged,
        key: args.key,
      );
    },
  );
}

class TaskDatePickerRouteArgs {
  const TaskDatePickerRouteArgs({
    required this.date,
    this.onDateChanged,
    this.key,
  });

  final _i31.Jiffy date;

  final _i37.ValueChanged<_i31.Jiffy?>? onDateChanged;

  final _i37.Key? key;

  @override
  String toString() {
    return 'TaskDatePickerRouteArgs{date: $date, onDateChanged: $onDateChanged, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskDatePickerRouteArgs) return false;
    return date == other.date &&
        onDateChanged == other.onDateChanged &&
        key == other.key;
  }

  @override
  int get hashCode => date.hashCode ^ onDateChanged.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i21.TaskDetailPage]
class TaskDetailRoute extends _i30.PageRouteInfo<TaskDetailRouteArgs> {
  TaskDetailRoute({
    required String taskId,
    _i37.Key? key,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         TaskDetailRoute.name,
         args: TaskDetailRouteArgs(taskId: taskId, key: key),
         initialChildren: children,
       );

  static const String name = 'TaskDetailRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDetailRouteArgs>();
      return _i21.TaskDetailPage(taskId: args.taskId, key: args.key);
    },
  );
}

class TaskDetailRouteArgs {
  const TaskDetailRouteArgs({required this.taskId, this.key});

  final String taskId;

  final _i37.Key? key;

  @override
  String toString() {
    return 'TaskDetailRouteArgs{taskId: $taskId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskDetailRouteArgs) return false;
    return taskId == other.taskId && key == other.key;
  }

  @override
  int get hashCode => taskId.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i22.TaskInboxPage]
class TaskInboxRoute extends _i30.PageRouteInfo<void> {
  const TaskInboxRoute({List<_i30.PageRouteInfo>? children})
    : super(TaskInboxRoute.name, initialChildren: children);

  static const String name = 'TaskInboxRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i22.TaskInboxPage();
    },
  );
}

/// generated route for
/// [_i23.TaskListPage]
class TaskListRoute extends _i30.PageRouteInfo<void> {
  const TaskListRoute({List<_i30.PageRouteInfo>? children})
    : super(TaskListRoute.name, initialChildren: children);

  static const String name = 'TaskListRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i23.TaskListPage();
    },
  );
}

/// generated route for
/// [_i24.TaskNewPage]
class TaskNewRoute extends _i30.PageRouteInfo<TaskNewRouteArgs> {
  TaskNewRoute({
    _i31.TaskEntity? initialTask,
    _i32.Key? key,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         TaskNewRoute.name,
         args: TaskNewRouteArgs(initialTask: initialTask, key: key),
         initialChildren: children,
       );

  static const String name = 'TaskNewRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskNewRouteArgs>(
        orElse: () => const TaskNewRouteArgs(),
      );
      return _i24.TaskNewPage(initialTask: args.initialTask, key: args.key);
    },
  );
}

class TaskNewRouteArgs {
  const TaskNewRouteArgs({this.initialTask, this.key});

  final _i31.TaskEntity? initialTask;

  final _i32.Key? key;

  @override
  String toString() {
    return 'TaskNewRouteArgs{initialTask: $initialTask, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskNewRouteArgs) return false;
    return initialTask == other.initialTask && key == other.key;
  }

  @override
  int get hashCode => initialTask.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i25.TaskOverduePage]
class TaskOverdueRoute extends _i30.PageRouteInfo<void> {
  const TaskOverdueRoute({List<_i30.PageRouteInfo>? children})
    : super(TaskOverdueRoute.name, initialChildren: children);

  static const String name = 'TaskOverdueRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i25.TaskOverduePage();
    },
  );
}

/// generated route for
/// [_i26.TaskPickerPage]
class TaskPickerRoute extends _i30.PageRouteInfo<void> {
  const TaskPickerRoute({List<_i30.PageRouteInfo>? children})
    : super(TaskPickerRoute.name, initialChildren: children);

  static const String name = 'TaskPickerRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i26.TaskPickerPage();
    },
  );
}

/// generated route for
/// [_i27.TaskPriorityPickerPage]
class TaskPriorityPickerRoute
    extends _i30.PageRouteInfo<TaskPriorityPickerRouteArgs> {
  TaskPriorityPickerRoute({
    required _i38.TaskPriority selectedPriority,
    _i37.ValueChanged<_i38.TaskPriority>? onSelected,
    _i37.Key? key,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         TaskPriorityPickerRoute.name,
         args: TaskPriorityPickerRouteArgs(
           selectedPriority: selectedPriority,
           onSelected: onSelected,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TaskPriorityPickerRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskPriorityPickerRouteArgs>();
      return _i27.TaskPriorityPickerPage(
        selectedPriority: args.selectedPriority,
        onSelected: args.onSelected,
        key: args.key,
      );
    },
  );
}

class TaskPriorityPickerRouteArgs {
  const TaskPriorityPickerRouteArgs({
    required this.selectedPriority,
    this.onSelected,
    this.key,
  });

  final _i38.TaskPriority selectedPriority;

  final _i37.ValueChanged<_i38.TaskPriority>? onSelected;

  final _i37.Key? key;

  @override
  String toString() {
    return 'TaskPriorityPickerRouteArgs{selectedPriority: $selectedPriority, onSelected: $onSelected, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskPriorityPickerRouteArgs) return false;
    return selectedPriority == other.selectedPriority &&
        onSelected == other.onSelected &&
        key == other.key;
  }

  @override
  int get hashCode =>
      selectedPriority.hashCode ^ onSelected.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i28.TaskTagPage]
class TaskTagRoute extends _i30.PageRouteInfo<TaskTagRouteArgs> {
  TaskTagRoute({
    required _i36.TagEntity tag,
    _i32.Key? key,
    List<_i30.PageRouteInfo>? children,
  }) : super(
         TaskTagRoute.name,
         args: TaskTagRouteArgs(tag: tag, key: key),
         initialChildren: children,
       );

  static const String name = 'TaskTagRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskTagRouteArgs>();
      return _i28.TaskTagPage(tag: args.tag, key: args.key);
    },
  );
}

class TaskTagRouteArgs {
  const TaskTagRouteArgs({required this.tag, this.key});

  final _i36.TagEntity tag;

  final _i32.Key? key;

  @override
  String toString() {
    return 'TaskTagRouteArgs{tag: $tag, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskTagRouteArgs) return false;
    return tag == other.tag && key == other.key;
  }

  @override
  int get hashCode => tag.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i29.TaskTodayPage]
class TaskTodayRoute extends _i30.PageRouteInfo<void> {
  const TaskTodayRoute({List<_i30.PageRouteInfo>? children})
    : super(TaskTodayRoute.name, initialChildren: children);

  static const String name = 'TaskTodayRoute';

  static _i30.PageInfo page = _i30.PageInfo(
    name,
    builder: (data) {
      return const _i29.TaskTodayPage();
    },
  );
}
