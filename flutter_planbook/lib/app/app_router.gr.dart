// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i24;
import 'package:collection/collection.dart' as _i28;
import 'package:flutter/cupertino.dart' as _i30;
import 'package:flutter/material.dart' as _i26;
import 'package:flutter_planbook/note/gallery/view/note_gallery_page.dart'
    as _i3;
import 'package:flutter_planbook/note/list/view/note_list_page.dart' as _i4;
import 'package:flutter_planbook/note/new/view/note_new_fullscreen_page.dart'
    as _i5;
import 'package:flutter_planbook/note/new/view/note_new_page.dart' as _i6;
import 'package:flutter_planbook/note/timeline/view/note_timeline_page.dart'
    as _i7;
import 'package:flutter_planbook/root/home/view/root_home_page.dart' as _i8;
import 'package:flutter_planbook/root/note/view/root_note_page.dart' as _i9;
import 'package:flutter_planbook/root/task/view/root_task_page.dart' as _i10;
import 'package:flutter_planbook/settings/about/view/about_page.dart' as _i1;
import 'package:flutter_planbook/settings/color/view/settings_seed_color_page.dart'
    as _i14;
import 'package:flutter_planbook/settings/dark/view/settings_dark_mode_page.dart'
    as _i11;
import 'package:flutter_planbook/settings/feedback/view/feedback_page.dart'
    as _i2;
import 'package:flutter_planbook/settings/home/view/settings_home_page.dart'
    as _i12;
import 'package:flutter_planbook/settings/icon/view/settings_icon_page.dart'
    as _i13;
import 'package:flutter_planbook/tag/list/bloc/tag_list_bloc.dart' as _i27;
import 'package:flutter_planbook/tag/list/view/tag_list_page.dart' as _i15;
import 'package:flutter_planbook/tag/new/view/tag_new_page.dart' as _i16;
import 'package:flutter_planbook/tag/picker/view/tag_picker_page.dart' as _i17;
import 'package:flutter_planbook/task/inbox/view/task_inbox_page.dart' as _i18;
import 'package:flutter_planbook/task/list/view/task_list_page.dart' as _i19;
import 'package:flutter_planbook/task/new/view/task_new_page.dart' as _i20;
import 'package:flutter_planbook/task/picker/view/task_picker_page.dart'
    as _i21;
import 'package:flutter_planbook/task/tag/view/task_tag_page.dart' as _i22;
import 'package:flutter_planbook/task/today/view/task_today_page.dart' as _i23;
import 'package:planbook_api/entity/tag_entity.dart' as _i31;
import 'package:planbook_api/planbook_api.dart' as _i29;
import 'package:planbook_repository/planbook_repository.dart' as _i25;

/// generated route for
/// [_i1.AboutPage]
class AboutRoute extends _i24.PageRouteInfo<void> {
  const AboutRoute({List<_i24.PageRouteInfo>? children})
    : super(AboutRoute.name, initialChildren: children);

  static const String name = 'AboutRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i1.AboutPage();
    },
  );
}

/// generated route for
/// [_i2.FeedbackPage]
class FeedbackRoute extends _i24.PageRouteInfo<void> {
  const FeedbackRoute({List<_i24.PageRouteInfo>? children})
    : super(FeedbackRoute.name, initialChildren: children);

  static const String name = 'FeedbackRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i2.FeedbackPage();
    },
  );
}

/// generated route for
/// [_i3.NoteGalleryPage]
class NoteGalleryRoute extends _i24.PageRouteInfo<void> {
  const NoteGalleryRoute({List<_i24.PageRouteInfo>? children})
    : super(NoteGalleryRoute.name, initialChildren: children);

  static const String name = 'NoteGalleryRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i3.NoteGalleryPage();
    },
  );
}

/// generated route for
/// [_i4.NoteListPage]
class NoteListRoute extends _i24.PageRouteInfo<void> {
  const NoteListRoute({List<_i24.PageRouteInfo>? children})
    : super(NoteListRoute.name, initialChildren: children);

  static const String name = 'NoteListRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i4.NoteListPage();
    },
  );
}

/// generated route for
/// [_i5.NoteNewFullscreenPage]
class NoteNewFullscreenRoute
    extends _i24.PageRouteInfo<NoteNewFullscreenRouteArgs> {
  NoteNewFullscreenRoute({
    _i25.NoteEntity? initialNote,
    _i26.Key? key,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         NoteNewFullscreenRoute.name,
         args: NoteNewFullscreenRouteArgs(initialNote: initialNote, key: key),
         initialChildren: children,
       );

  static const String name = 'NoteNewFullscreenRoute';

  static _i24.PageInfo page = _i24.PageInfo(
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

  final _i25.NoteEntity? initialNote;

  final _i26.Key? key;

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
class NoteNewRoute extends _i24.PageRouteInfo<NoteNewRouteArgs> {
  NoteNewRoute({
    _i25.NoteEntity? initialNote,
    _i26.Key? key,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         NoteNewRoute.name,
         args: NoteNewRouteArgs(initialNote: initialNote, key: key),
         initialChildren: children,
       );

  static const String name = 'NoteNewRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteNewRouteArgs>(
        orElse: () => const NoteNewRouteArgs(),
      );
      return _i6.NoteNewPage(initialNote: args.initialNote, key: args.key);
    },
  );
}

class NoteNewRouteArgs {
  const NoteNewRouteArgs({this.initialNote, this.key});

  final _i25.NoteEntity? initialNote;

  final _i26.Key? key;

  @override
  String toString() {
    return 'NoteNewRouteArgs{initialNote: $initialNote, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteNewRouteArgs) return false;
    return initialNote == other.initialNote && key == other.key;
  }

  @override
  int get hashCode => initialNote.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i7.NoteTimelinePage]
class NoteTimelineRoute extends _i24.PageRouteInfo<void> {
  const NoteTimelineRoute({List<_i24.PageRouteInfo>? children})
    : super(NoteTimelineRoute.name, initialChildren: children);

  static const String name = 'NoteTimelineRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i7.NoteTimelinePage();
    },
  );
}

/// generated route for
/// [_i8.RootHomePage]
class RootHomeRoute extends _i24.PageRouteInfo<void> {
  const RootHomeRoute({List<_i24.PageRouteInfo>? children})
    : super(RootHomeRoute.name, initialChildren: children);

  static const String name = 'RootHomeRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i8.RootHomePage();
    },
  );
}

/// generated route for
/// [_i9.RootNotePage]
class RootNoteRoute extends _i24.PageRouteInfo<void> {
  const RootNoteRoute({List<_i24.PageRouteInfo>? children})
    : super(RootNoteRoute.name, initialChildren: children);

  static const String name = 'RootNoteRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i9.RootNotePage();
    },
  );
}

/// generated route for
/// [_i10.RootTaskPage]
class RootTaskRoute extends _i24.PageRouteInfo<void> {
  const RootTaskRoute({List<_i24.PageRouteInfo>? children})
    : super(RootTaskRoute.name, initialChildren: children);

  static const String name = 'RootTaskRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i10.RootTaskPage();
    },
  );
}

/// generated route for
/// [_i11.SettingsDarkModePage]
class SettingsDarkModeRoute extends _i24.PageRouteInfo<void> {
  const SettingsDarkModeRoute({List<_i24.PageRouteInfo>? children})
    : super(SettingsDarkModeRoute.name, initialChildren: children);

  static const String name = 'SettingsDarkModeRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i11.SettingsDarkModePage();
    },
  );
}

/// generated route for
/// [_i12.SettingsHomePage]
class SettingsHomeRoute extends _i24.PageRouteInfo<void> {
  const SettingsHomeRoute({List<_i24.PageRouteInfo>? children})
    : super(SettingsHomeRoute.name, initialChildren: children);

  static const String name = 'SettingsHomeRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i12.SettingsHomePage();
    },
  );
}

/// generated route for
/// [_i13.SettingsIconPage]
class SettingsIconRoute extends _i24.PageRouteInfo<void> {
  const SettingsIconRoute({List<_i24.PageRouteInfo>? children})
    : super(SettingsIconRoute.name, initialChildren: children);

  static const String name = 'SettingsIconRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i13.SettingsIconPage();
    },
  );
}

/// generated route for
/// [_i14.SettingsSeedColorPage]
class SettingsSeedColorRoute extends _i24.PageRouteInfo<void> {
  const SettingsSeedColorRoute({List<_i24.PageRouteInfo>? children})
    : super(SettingsSeedColorRoute.name, initialChildren: children);

  static const String name = 'SettingsSeedColorRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i14.SettingsSeedColorPage();
    },
  );
}

/// generated route for
/// [_i15.TagListPage]
class TagListRoute extends _i24.PageRouteInfo<TagListRouteArgs> {
  TagListRoute({
    required _i27.TagListMode mode,
    required List<_i25.TagEntity> selectedTags,
    _i26.Key? key,
    List<_i24.PageRouteInfo>? children,
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

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagListRouteArgs>();
      return _i15.TagListPage(
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

  final _i27.TagListMode mode;

  final List<_i25.TagEntity> selectedTags;

  final _i26.Key? key;

  @override
  String toString() {
    return 'TagListRouteArgs{mode: $mode, selectedTags: $selectedTags, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagListRouteArgs) return false;
    return mode == other.mode &&
        const _i28.ListEquality<_i25.TagEntity>().equals(
          selectedTags,
          other.selectedTags,
        ) &&
        key == other.key;
  }

  @override
  int get hashCode =>
      mode.hashCode ^
      const _i28.ListEquality<_i25.TagEntity>().hash(selectedTags) ^
      key.hashCode;
}

/// generated route for
/// [_i16.TagNewPage]
class TagNewRoute extends _i24.PageRouteInfo<TagNewRouteArgs> {
  TagNewRoute({
    _i29.TagEntity? initialTag,
    _i30.Key? key,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         TagNewRoute.name,
         args: TagNewRouteArgs(initialTag: initialTag, key: key),
         initialChildren: children,
       );

  static const String name = 'TagNewRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagNewRouteArgs>(
        orElse: () => const TagNewRouteArgs(),
      );
      return _i16.TagNewPage(initialTag: args.initialTag, key: args.key);
    },
  );
}

class TagNewRouteArgs {
  const TagNewRouteArgs({this.initialTag, this.key});

  final _i29.TagEntity? initialTag;

  final _i30.Key? key;

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
/// [_i17.TagPickerPage]
class TagPickerRoute extends _i24.PageRouteInfo<TagPickerRouteArgs> {
  TagPickerRoute({
    required List<_i31.TagEntity> selectedTags,
    required _i30.ValueChanged<List<_i31.TagEntity>> onSelected,
    _i30.Key? key,
    List<_i24.PageRouteInfo>? children,
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

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagPickerRouteArgs>();
      return _i17.TagPickerPage(
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

  final List<_i31.TagEntity> selectedTags;

  final _i30.ValueChanged<List<_i31.TagEntity>> onSelected;

  final _i30.Key? key;

  @override
  String toString() {
    return 'TagPickerRouteArgs{selectedTags: $selectedTags, onSelected: $onSelected, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagPickerRouteArgs) return false;
    return const _i28.ListEquality<_i31.TagEntity>().equals(
          selectedTags,
          other.selectedTags,
        ) &&
        onSelected == other.onSelected &&
        key == other.key;
  }

  @override
  int get hashCode =>
      const _i28.ListEquality<_i31.TagEntity>().hash(selectedTags) ^
      onSelected.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i18.TaskInboxPage]
class TaskInboxRoute extends _i24.PageRouteInfo<void> {
  const TaskInboxRoute({List<_i24.PageRouteInfo>? children})
    : super(TaskInboxRoute.name, initialChildren: children);

  static const String name = 'TaskInboxRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i18.TaskInboxPage();
    },
  );
}

/// generated route for
/// [_i19.TaskListPage]
class TaskListRoute extends _i24.PageRouteInfo<void> {
  const TaskListRoute({List<_i24.PageRouteInfo>? children})
    : super(TaskListRoute.name, initialChildren: children);

  static const String name = 'TaskListRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i19.TaskListPage();
    },
  );
}

/// generated route for
/// [_i20.TaskNewPage]
class TaskNewRoute extends _i24.PageRouteInfo<TaskNewRouteArgs> {
  TaskNewRoute({
    _i25.TaskEntity? initialTask,
    _i26.Key? key,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         TaskNewRoute.name,
         args: TaskNewRouteArgs(initialTask: initialTask, key: key),
         initialChildren: children,
       );

  static const String name = 'TaskNewRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskNewRouteArgs>(
        orElse: () => const TaskNewRouteArgs(),
      );
      return _i20.TaskNewPage(initialTask: args.initialTask, key: args.key);
    },
  );
}

class TaskNewRouteArgs {
  const TaskNewRouteArgs({this.initialTask, this.key});

  final _i25.TaskEntity? initialTask;

  final _i26.Key? key;

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
/// [_i21.TaskPickerPage]
class TaskPickerRoute extends _i24.PageRouteInfo<void> {
  const TaskPickerRoute({List<_i24.PageRouteInfo>? children})
    : super(TaskPickerRoute.name, initialChildren: children);

  static const String name = 'TaskPickerRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i21.TaskPickerPage();
    },
  );
}

/// generated route for
/// [_i22.TaskTagPage]
class TaskTagRoute extends _i24.PageRouteInfo<TaskTagRouteArgs> {
  TaskTagRoute({
    required _i29.TagEntity tag,
    _i26.Key? key,
    List<_i24.PageRouteInfo>? children,
  }) : super(
         TaskTagRoute.name,
         args: TaskTagRouteArgs(tag: tag, key: key),
         initialChildren: children,
       );

  static const String name = 'TaskTagRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskTagRouteArgs>();
      return _i22.TaskTagPage(tag: args.tag, key: args.key);
    },
  );
}

class TaskTagRouteArgs {
  const TaskTagRouteArgs({required this.tag, this.key});

  final _i29.TagEntity tag;

  final _i26.Key? key;

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
/// [_i23.TaskTodayPage]
class TaskTodayRoute extends _i24.PageRouteInfo<void> {
  const TaskTodayRoute({List<_i24.PageRouteInfo>? children})
    : super(TaskTodayRoute.name, initialChildren: children);

  static const String name = 'TaskTodayRoute';

  static _i24.PageInfo page = _i24.PageInfo(
    name,
    builder: (data) {
      return const _i23.TaskTodayPage();
    },
  );
}
