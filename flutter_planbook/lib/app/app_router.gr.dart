// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i45;
import 'package:collection/collection.dart' as _i52;
import 'package:flutter/cupertino.dart' as _i50;
import 'package:flutter/material.dart' as _i47;
import 'package:flutter_planbook/app/purchases/view/app_purchases_page.dart'
    as _i2;
import 'package:flutter_planbook/journal/day/view/journal_day_page.dart' as _i4;
import 'package:flutter_planbook/journal/note/view/journal_note_page.dart'
    as _i5;
import 'package:flutter_planbook/journal/priority/view/journal_priority_page.dart'
    as _i6;
import 'package:flutter_planbook/mine/delete/view/mine_delete_page.dart' as _i7;
import 'package:flutter_planbook/mine/email/view/mine_email_page.dart' as _i8;
import 'package:flutter_planbook/mine/password/view/mine_password_page.dart'
    as _i9;
import 'package:flutter_planbook/mine/phone/view/mine_phone_page.dart' as _i10;
import 'package:flutter_planbook/mine/profile/view/mine_profile_page.dart'
    as _i11;
import 'package:flutter_planbook/note/gallery/view/note_gallery_page.dart'
    as _i12;
import 'package:flutter_planbook/note/list/view/note_list_page.dart' as _i13;
import 'package:flutter_planbook/note/new/view/note_new_fullscreen_page.dart'
    as _i14;
import 'package:flutter_planbook/note/new/view/note_new_page.dart' as _i15;
import 'package:flutter_planbook/note/tag/view/note_tag_page.dart' as _i16;
import 'package:flutter_planbook/note/timeline/view/note_timeline_page.dart'
    as _i17;
import 'package:flutter_planbook/root/home/view/root_home_page.dart' as _i18;
import 'package:flutter_planbook/root/journal/view/root_journal_page.dart'
    as _i19;
import 'package:flutter_planbook/root/note/view/root_note_page.dart' as _i20;
import 'package:flutter_planbook/root/task/view/root_task_page.dart' as _i21;
import 'package:flutter_planbook/settings/about/view/about_page.dart' as _i1;
import 'package:flutter_planbook/settings/background/view/settings_background_page.dart'
    as _i22;
import 'package:flutter_planbook/settings/color/view/settings_seed_color_page.dart'
    as _i26;
import 'package:flutter_planbook/settings/dark/view/settings_dark_mode_page.dart'
    as _i23;
import 'package:flutter_planbook/settings/feedback/view/feedback_page.dart'
    as _i3;
import 'package:flutter_planbook/settings/home/view/settings_home_page.dart'
    as _i24;
import 'package:flutter_planbook/settings/icon/view/settings_icon_page.dart'
    as _i25;
import 'package:flutter_planbook/settings/task/view/settings_task_page.dart'
    as _i27;
import 'package:flutter_planbook/sign/home/view/sign_home_page.dart' as _i28;
import 'package:flutter_planbook/tag/list/bloc/tag_list_bloc.dart' as _i51;
import 'package:flutter_planbook/tag/list/view/tag_list_page.dart' as _i29;
import 'package:flutter_planbook/tag/new/view/tag_new_page.dart' as _i30;
import 'package:flutter_planbook/tag/picker/view/tag_picker_page.dart' as _i31;
import 'package:flutter_planbook/task/detail/view/task_detail_page.dart'
    as _i33;
import 'package:flutter_planbook/task/duration/view/task_duration_page.dart'
    as _i34;
import 'package:flutter_planbook/task/inbox/view/task_inbox_page.dart' as _i35;
import 'package:flutter_planbook/task/list/view/task_list_page.dart' as _i36;
import 'package:flutter_planbook/task/new/view/task_new_page.dart' as _i37;
import 'package:flutter_planbook/task/overdue/view/task_overdue_page.dart'
    as _i39;
import 'package:flutter_planbook/task/picker/view/task_date_picker_page.dart'
    as _i32;
import 'package:flutter_planbook/task/picker/view/task_picker_page.dart'
    as _i40;
import 'package:flutter_planbook/task/picker/view/task_priority_picker_page.dart'
    as _i41;
import 'package:flutter_planbook/task/recurrence/view/task_recurrence_ends_page.dart'
    as _i38;
import 'package:flutter_planbook/task/recurrence/view/task_recurrence_page.dart'
    as _i42;
import 'package:flutter_planbook/task/tag/view/task_tag_page.dart' as _i43;
import 'package:flutter_planbook/task/today/view/task_today_page.dart' as _i44;
import 'package:jiffy/jiffy.dart' as _i46;
import 'package:planbook_api/database/recurrence_rule.dart' as _i54;
import 'package:planbook_api/database/task_priority.dart' as _i55;
import 'package:planbook_api/entity/tag_entity.dart' as _i49;
import 'package:planbook_api/planbook_api.dart' as _i53;
import 'package:planbook_repository/planbook_repository.dart' as _i48;

/// generated route for
/// [_i1.AboutPage]
class AboutRoute extends _i45.PageRouteInfo<void> {
  const AboutRoute({List<_i45.PageRouteInfo>? children})
    : super(AboutRoute.name, initialChildren: children);

  static const String name = 'AboutRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i1.AboutPage();
    },
  );
}

/// generated route for
/// [_i2.AppPurchasesPage]
class AppPurchasesRoute extends _i45.PageRouteInfo<void> {
  const AppPurchasesRoute({List<_i45.PageRouteInfo>? children})
    : super(AppPurchasesRoute.name, initialChildren: children);

  static const String name = 'AppPurchasesRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i2.AppPurchasesPage();
    },
  );
}

/// generated route for
/// [_i3.FeedbackPage]
class FeedbackRoute extends _i45.PageRouteInfo<void> {
  const FeedbackRoute({List<_i45.PageRouteInfo>? children})
    : super(FeedbackRoute.name, initialChildren: children);

  static const String name = 'FeedbackRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i3.FeedbackPage();
    },
  );
}

/// generated route for
/// [_i4.JournalDayPage]
class JournalDayRoute extends _i45.PageRouteInfo<JournalDayRouteArgs> {
  JournalDayRoute({
    required _i46.Jiffy date,
    required double scale,
    _i47.Key? key,
    List<_i45.PageRouteInfo>? children,
  }) : super(
         JournalDayRoute.name,
         args: JournalDayRouteArgs(date: date, scale: scale, key: key),
         initialChildren: children,
       );

  static const String name = 'JournalDayRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JournalDayRouteArgs>();
      return _i4.JournalDayPage(
        date: args.date,
        scale: args.scale,
        key: args.key,
      );
    },
  );
}

class JournalDayRouteArgs {
  const JournalDayRouteArgs({
    required this.date,
    required this.scale,
    this.key,
  });

  final _i46.Jiffy date;

  final double scale;

  final _i47.Key? key;

  @override
  String toString() {
    return 'JournalDayRouteArgs{date: $date, scale: $scale, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JournalDayRouteArgs) return false;
    return date == other.date && scale == other.scale && key == other.key;
  }

  @override
  int get hashCode => date.hashCode ^ scale.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i5.JournalNotePage]
class JournalNoteRoute extends _i45.PageRouteInfo<JournalNoteRouteArgs> {
  JournalNoteRoute({
    required _i46.Jiffy date,
    _i47.Key? key,
    List<_i45.PageRouteInfo>? children,
  }) : super(
         JournalNoteRoute.name,
         args: JournalNoteRouteArgs(date: date, key: key),
         initialChildren: children,
       );

  static const String name = 'JournalNoteRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JournalNoteRouteArgs>();
      return _i5.JournalNotePage(date: args.date, key: args.key);
    },
  );
}

class JournalNoteRouteArgs {
  const JournalNoteRouteArgs({required this.date, this.key});

  final _i46.Jiffy date;

  final _i47.Key? key;

  @override
  String toString() {
    return 'JournalNoteRouteArgs{date: $date, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JournalNoteRouteArgs) return false;
    return date == other.date && key == other.key;
  }

  @override
  int get hashCode => date.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i6.JournalPriorityPage]
class JournalPriorityRoute extends _i45.PageRouteInfo<void> {
  const JournalPriorityRoute({List<_i45.PageRouteInfo>? children})
    : super(JournalPriorityRoute.name, initialChildren: children);

  static const String name = 'JournalPriorityRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i6.JournalPriorityPage();
    },
  );
}

/// generated route for
/// [_i7.MineDeletePage]
class MineDeleteRoute extends _i45.PageRouteInfo<void> {
  const MineDeleteRoute({List<_i45.PageRouteInfo>? children})
    : super(MineDeleteRoute.name, initialChildren: children);

  static const String name = 'MineDeleteRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i7.MineDeletePage();
    },
  );
}

/// generated route for
/// [_i8.MineEmailPage]
class MineEmailRoute extends _i45.PageRouteInfo<void> {
  const MineEmailRoute({List<_i45.PageRouteInfo>? children})
    : super(MineEmailRoute.name, initialChildren: children);

  static const String name = 'MineEmailRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i8.MineEmailPage();
    },
  );
}

/// generated route for
/// [_i9.MinePasswordPage]
class MinePasswordRoute extends _i45.PageRouteInfo<void> {
  const MinePasswordRoute({List<_i45.PageRouteInfo>? children})
    : super(MinePasswordRoute.name, initialChildren: children);

  static const String name = 'MinePasswordRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i9.MinePasswordPage();
    },
  );
}

/// generated route for
/// [_i10.MinePhonePage]
class MinePhoneRoute extends _i45.PageRouteInfo<void> {
  const MinePhoneRoute({List<_i45.PageRouteInfo>? children})
    : super(MinePhoneRoute.name, initialChildren: children);

  static const String name = 'MinePhoneRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i10.MinePhonePage();
    },
  );
}

/// generated route for
/// [_i11.MineProfilePage]
class MineProfileRoute extends _i45.PageRouteInfo<void> {
  const MineProfileRoute({List<_i45.PageRouteInfo>? children})
    : super(MineProfileRoute.name, initialChildren: children);

  static const String name = 'MineProfileRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i11.MineProfilePage();
    },
  );
}

/// generated route for
/// [_i12.NoteGalleryPage]
class NoteGalleryRoute extends _i45.PageRouteInfo<void> {
  const NoteGalleryRoute({List<_i45.PageRouteInfo>? children})
    : super(NoteGalleryRoute.name, initialChildren: children);

  static const String name = 'NoteGalleryRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i12.NoteGalleryPage();
    },
  );
}

/// generated route for
/// [_i13.NoteListPage]
class NoteListRoute extends _i45.PageRouteInfo<void> {
  const NoteListRoute({List<_i45.PageRouteInfo>? children})
    : super(NoteListRoute.name, initialChildren: children);

  static const String name = 'NoteListRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i13.NoteListPage();
    },
  );
}

/// generated route for
/// [_i14.NoteNewFullscreenPage]
class NoteNewFullscreenRoute
    extends _i45.PageRouteInfo<NoteNewFullscreenRouteArgs> {
  NoteNewFullscreenRoute({
    _i48.NoteEntity? initialNote,
    _i47.Key? key,
    List<_i45.PageRouteInfo>? children,
  }) : super(
         NoteNewFullscreenRoute.name,
         args: NoteNewFullscreenRouteArgs(initialNote: initialNote, key: key),
         initialChildren: children,
       );

  static const String name = 'NoteNewFullscreenRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteNewFullscreenRouteArgs>(
        orElse: () => const NoteNewFullscreenRouteArgs(),
      );
      return _i14.NoteNewFullscreenPage(
        initialNote: args.initialNote,
        key: args.key,
      );
    },
  );
}

class NoteNewFullscreenRouteArgs {
  const NoteNewFullscreenRouteArgs({this.initialNote, this.key});

  final _i48.NoteEntity? initialNote;

  final _i47.Key? key;

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
/// [_i15.NoteNewPage]
class NoteNewRoute extends _i45.PageRouteInfo<NoteNewRouteArgs> {
  NoteNewRoute({
    _i48.NoteEntity? initialNote,
    _i48.TaskEntity? initialTask,
    _i47.Key? key,
    List<_i45.PageRouteInfo>? children,
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

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteNewRouteArgs>(
        orElse: () => const NoteNewRouteArgs(),
      );
      return _i15.NoteNewPage(
        initialNote: args.initialNote,
        initialTask: args.initialTask,
        key: args.key,
      );
    },
  );
}

class NoteNewRouteArgs {
  const NoteNewRouteArgs({this.initialNote, this.initialTask, this.key});

  final _i48.NoteEntity? initialNote;

  final _i48.TaskEntity? initialTask;

  final _i47.Key? key;

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
/// [_i16.NoteTagPage]
class NoteTagRoute extends _i45.PageRouteInfo<NoteTagRouteArgs> {
  NoteTagRoute({
    required _i49.TagEntity tag,
    _i47.Key? key,
    List<_i45.PageRouteInfo>? children,
  }) : super(
         NoteTagRoute.name,
         args: NoteTagRouteArgs(tag: tag, key: key),
         initialChildren: children,
       );

  static const String name = 'NoteTagRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteTagRouteArgs>();
      return _i16.NoteTagPage(tag: args.tag, key: args.key);
    },
  );
}

class NoteTagRouteArgs {
  const NoteTagRouteArgs({required this.tag, this.key});

  final _i49.TagEntity tag;

  final _i47.Key? key;

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
/// [_i17.NoteTimelinePage]
class NoteTimelineRoute extends _i45.PageRouteInfo<void> {
  const NoteTimelineRoute({List<_i45.PageRouteInfo>? children})
    : super(NoteTimelineRoute.name, initialChildren: children);

  static const String name = 'NoteTimelineRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i17.NoteTimelinePage();
    },
  );
}

/// generated route for
/// [_i18.RootHomePage]
class RootHomeRoute extends _i45.PageRouteInfo<void> {
  const RootHomeRoute({List<_i45.PageRouteInfo>? children})
    : super(RootHomeRoute.name, initialChildren: children);

  static const String name = 'RootHomeRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i18.RootHomePage();
    },
  );
}

/// generated route for
/// [_i19.RootJournalPage]
class RootJournalRoute extends _i45.PageRouteInfo<void> {
  const RootJournalRoute({List<_i45.PageRouteInfo>? children})
    : super(RootJournalRoute.name, initialChildren: children);

  static const String name = 'RootJournalRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i19.RootJournalPage();
    },
  );
}

/// generated route for
/// [_i20.RootNotePage]
class RootNoteRoute extends _i45.PageRouteInfo<void> {
  const RootNoteRoute({List<_i45.PageRouteInfo>? children})
    : super(RootNoteRoute.name, initialChildren: children);

  static const String name = 'RootNoteRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i20.RootNotePage();
    },
  );
}

/// generated route for
/// [_i21.RootTaskPage]
class RootTaskRoute extends _i45.PageRouteInfo<RootTaskRouteArgs> {
  RootTaskRoute({_i50.Key? key, List<_i45.PageRouteInfo>? children})
    : super(
        RootTaskRoute.name,
        args: RootTaskRouteArgs(key: key),
        initialChildren: children,
      );

  static const String name = 'RootTaskRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RootTaskRouteArgs>(
        orElse: () => const RootTaskRouteArgs(),
      );
      return _i21.RootTaskPage(key: args.key);
    },
  );
}

class RootTaskRouteArgs {
  const RootTaskRouteArgs({this.key});

  final _i50.Key? key;

  @override
  String toString() {
    return 'RootTaskRouteArgs{key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RootTaskRouteArgs) return false;
    return key == other.key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// generated route for
/// [_i22.SettingsBackgroundPage]
class SettingsBackgroundRoute extends _i45.PageRouteInfo<void> {
  const SettingsBackgroundRoute({List<_i45.PageRouteInfo>? children})
    : super(SettingsBackgroundRoute.name, initialChildren: children);

  static const String name = 'SettingsBackgroundRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i22.SettingsBackgroundPage();
    },
  );
}

/// generated route for
/// [_i23.SettingsDarkModePage]
class SettingsDarkModeRoute extends _i45.PageRouteInfo<void> {
  const SettingsDarkModeRoute({List<_i45.PageRouteInfo>? children})
    : super(SettingsDarkModeRoute.name, initialChildren: children);

  static const String name = 'SettingsDarkModeRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i23.SettingsDarkModePage();
    },
  );
}

/// generated route for
/// [_i24.SettingsHomePage]
class SettingsHomeRoute extends _i45.PageRouteInfo<void> {
  const SettingsHomeRoute({List<_i45.PageRouteInfo>? children})
    : super(SettingsHomeRoute.name, initialChildren: children);

  static const String name = 'SettingsHomeRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i24.SettingsHomePage();
    },
  );
}

/// generated route for
/// [_i25.SettingsIconPage]
class SettingsIconRoute extends _i45.PageRouteInfo<void> {
  const SettingsIconRoute({List<_i45.PageRouteInfo>? children})
    : super(SettingsIconRoute.name, initialChildren: children);

  static const String name = 'SettingsIconRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i25.SettingsIconPage();
    },
  );
}

/// generated route for
/// [_i26.SettingsSeedColorPage]
class SettingsSeedColorRoute extends _i45.PageRouteInfo<void> {
  const SettingsSeedColorRoute({List<_i45.PageRouteInfo>? children})
    : super(SettingsSeedColorRoute.name, initialChildren: children);

  static const String name = 'SettingsSeedColorRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i26.SettingsSeedColorPage();
    },
  );
}

/// generated route for
/// [_i27.SettingsTaskPage]
class SettingsTaskRoute extends _i45.PageRouteInfo<void> {
  const SettingsTaskRoute({List<_i45.PageRouteInfo>? children})
    : super(SettingsTaskRoute.name, initialChildren: children);

  static const String name = 'SettingsTaskRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i27.SettingsTaskPage();
    },
  );
}

/// generated route for
/// [_i28.SignHomePage]
class SignHomeRoute extends _i45.PageRouteInfo<void> {
  const SignHomeRoute({List<_i45.PageRouteInfo>? children})
    : super(SignHomeRoute.name, initialChildren: children);

  static const String name = 'SignHomeRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i28.SignHomePage();
    },
  );
}

/// generated route for
/// [_i29.TagListPage]
class TagListRoute extends _i45.PageRouteInfo<TagListRouteArgs> {
  TagListRoute({
    required _i51.TagListMode mode,
    required List<_i48.TagEntity> selectedTags,
    _i47.Key? key,
    List<_i45.PageRouteInfo>? children,
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

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagListRouteArgs>();
      return _i29.TagListPage(
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

  final _i51.TagListMode mode;

  final List<_i48.TagEntity> selectedTags;

  final _i47.Key? key;

  @override
  String toString() {
    return 'TagListRouteArgs{mode: $mode, selectedTags: $selectedTags, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagListRouteArgs) return false;
    return mode == other.mode &&
        const _i52.ListEquality<_i48.TagEntity>().equals(
          selectedTags,
          other.selectedTags,
        ) &&
        key == other.key;
  }

  @override
  int get hashCode =>
      mode.hashCode ^
      const _i52.ListEquality<_i48.TagEntity>().hash(selectedTags) ^
      key.hashCode;
}

/// generated route for
/// [_i30.TagNewPage]
class TagNewRoute extends _i45.PageRouteInfo<TagNewRouteArgs> {
  TagNewRoute({
    _i53.TagEntity? initialTag,
    _i50.Key? key,
    List<_i45.PageRouteInfo>? children,
  }) : super(
         TagNewRoute.name,
         args: TagNewRouteArgs(initialTag: initialTag, key: key),
         initialChildren: children,
       );

  static const String name = 'TagNewRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagNewRouteArgs>(
        orElse: () => const TagNewRouteArgs(),
      );
      return _i30.TagNewPage(initialTag: args.initialTag, key: args.key);
    },
  );
}

class TagNewRouteArgs {
  const TagNewRouteArgs({this.initialTag, this.key});

  final _i53.TagEntity? initialTag;

  final _i50.Key? key;

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
/// [_i31.TagPickerPage]
class TagPickerRoute extends _i45.PageRouteInfo<TagPickerRouteArgs> {
  TagPickerRoute({
    required List<_i49.TagEntity> selectedTags,
    required _i50.ValueChanged<List<_i49.TagEntity>> onSelected,
    _i50.Key? key,
    List<_i45.PageRouteInfo>? children,
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

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagPickerRouteArgs>();
      return _i31.TagPickerPage(
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

  final List<_i49.TagEntity> selectedTags;

  final _i50.ValueChanged<List<_i49.TagEntity>> onSelected;

  final _i50.Key? key;

  @override
  String toString() {
    return 'TagPickerRouteArgs{selectedTags: $selectedTags, onSelected: $onSelected, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagPickerRouteArgs) return false;
    return const _i52.ListEquality<_i49.TagEntity>().equals(
          selectedTags,
          other.selectedTags,
        ) &&
        onSelected == other.onSelected &&
        key == other.key;
  }

  @override
  int get hashCode =>
      const _i52.ListEquality<_i49.TagEntity>().hash(selectedTags) ^
      onSelected.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i32.TaskDatePickerPage]
class TaskDatePickerRoute extends _i45.PageRouteInfo<TaskDatePickerRouteArgs> {
  TaskDatePickerRoute({
    required _i48.Jiffy date,
    _i50.ValueChanged<_i48.Jiffy?>? onDateChanged,
    _i50.Key? key,
    List<_i45.PageRouteInfo>? children,
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

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDatePickerRouteArgs>();
      return _i32.TaskDatePickerPage(
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

  final _i48.Jiffy date;

  final _i50.ValueChanged<_i48.Jiffy?>? onDateChanged;

  final _i50.Key? key;

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
/// [_i33.TaskDetailPage]
class TaskDetailRoute extends _i45.PageRouteInfo<TaskDetailRouteArgs> {
  TaskDetailRoute({
    required String taskId,
    _i50.Key? key,
    List<_i45.PageRouteInfo>? children,
  }) : super(
         TaskDetailRoute.name,
         args: TaskDetailRouteArgs(taskId: taskId, key: key),
         initialChildren: children,
       );

  static const String name = 'TaskDetailRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDetailRouteArgs>();
      return _i33.TaskDetailPage(taskId: args.taskId, key: args.key);
    },
  );
}

class TaskDetailRouteArgs {
  const TaskDetailRouteArgs({required this.taskId, this.key});

  final String taskId;

  final _i50.Key? key;

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
/// [_i34.TaskDurationPage]
class TaskDurationRoute extends _i45.PageRouteInfo<TaskDurationRouteArgs> {
  TaskDurationRoute({
    required _i46.Jiffy? startAt,
    required _i46.Jiffy? endAt,
    required bool isAllDay,
    required _i50.ValueChanged<bool> onIsAllDayChanged,
    required _i50.ValueChanged<_i46.Jiffy?> onStartAtChanged,
    required _i50.ValueChanged<_i46.Jiffy?> onEndAtChanged,
    _i50.Key? key,
    List<_i45.PageRouteInfo>? children,
  }) : super(
         TaskDurationRoute.name,
         args: TaskDurationRouteArgs(
           startAt: startAt,
           endAt: endAt,
           isAllDay: isAllDay,
           onIsAllDayChanged: onIsAllDayChanged,
           onStartAtChanged: onStartAtChanged,
           onEndAtChanged: onEndAtChanged,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TaskDurationRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDurationRouteArgs>();
      return _i34.TaskDurationPage(
        startAt: args.startAt,
        endAt: args.endAt,
        isAllDay: args.isAllDay,
        onIsAllDayChanged: args.onIsAllDayChanged,
        onStartAtChanged: args.onStartAtChanged,
        onEndAtChanged: args.onEndAtChanged,
        key: args.key,
      );
    },
  );
}

class TaskDurationRouteArgs {
  const TaskDurationRouteArgs({
    required this.startAt,
    required this.endAt,
    required this.isAllDay,
    required this.onIsAllDayChanged,
    required this.onStartAtChanged,
    required this.onEndAtChanged,
    this.key,
  });

  final _i46.Jiffy? startAt;

  final _i46.Jiffy? endAt;

  final bool isAllDay;

  final _i50.ValueChanged<bool> onIsAllDayChanged;

  final _i50.ValueChanged<_i46.Jiffy?> onStartAtChanged;

  final _i50.ValueChanged<_i46.Jiffy?> onEndAtChanged;

  final _i50.Key? key;

  @override
  String toString() {
    return 'TaskDurationRouteArgs{startAt: $startAt, endAt: $endAt, isAllDay: $isAllDay, onIsAllDayChanged: $onIsAllDayChanged, onStartAtChanged: $onStartAtChanged, onEndAtChanged: $onEndAtChanged, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskDurationRouteArgs) return false;
    return startAt == other.startAt &&
        endAt == other.endAt &&
        isAllDay == other.isAllDay &&
        onIsAllDayChanged == other.onIsAllDayChanged &&
        onStartAtChanged == other.onStartAtChanged &&
        onEndAtChanged == other.onEndAtChanged &&
        key == other.key;
  }

  @override
  int get hashCode =>
      startAt.hashCode ^
      endAt.hashCode ^
      isAllDay.hashCode ^
      onIsAllDayChanged.hashCode ^
      onStartAtChanged.hashCode ^
      onEndAtChanged.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i35.TaskInboxPage]
class TaskInboxRoute extends _i45.PageRouteInfo<void> {
  const TaskInboxRoute({List<_i45.PageRouteInfo>? children})
    : super(TaskInboxRoute.name, initialChildren: children);

  static const String name = 'TaskInboxRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i35.TaskInboxPage();
    },
  );
}

/// generated route for
/// [_i36.TaskListPage]
class TaskListRoute extends _i45.PageRouteInfo<void> {
  const TaskListRoute({List<_i45.PageRouteInfo>? children})
    : super(TaskListRoute.name, initialChildren: children);

  static const String name = 'TaskListRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i36.TaskListPage();
    },
  );
}

/// generated route for
/// [_i37.TaskNewPage]
class TaskNewRoute extends _i45.PageRouteInfo<TaskNewRouteArgs> {
  TaskNewRoute({
    _i48.TaskEntity? initialTask,
    _i48.Jiffy? dueAt,
    _i47.Key? key,
    List<_i45.PageRouteInfo>? children,
  }) : super(
         TaskNewRoute.name,
         args: TaskNewRouteArgs(
           initialTask: initialTask,
           dueAt: dueAt,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TaskNewRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskNewRouteArgs>(
        orElse: () => const TaskNewRouteArgs(),
      );
      return _i37.TaskNewPage(
        initialTask: args.initialTask,
        dueAt: args.dueAt,
        key: args.key,
      );
    },
  );
}

class TaskNewRouteArgs {
  const TaskNewRouteArgs({this.initialTask, this.dueAt, this.key});

  final _i48.TaskEntity? initialTask;

  final _i48.Jiffy? dueAt;

  final _i47.Key? key;

  @override
  String toString() {
    return 'TaskNewRouteArgs{initialTask: $initialTask, dueAt: $dueAt, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskNewRouteArgs) return false;
    return initialTask == other.initialTask &&
        dueAt == other.dueAt &&
        key == other.key;
  }

  @override
  int get hashCode => initialTask.hashCode ^ dueAt.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i38.TaskNewRecurrenceEndAtPage]
class TaskNewRecurrenceEndAtRoute
    extends _i45.PageRouteInfo<TaskNewRecurrenceEndAtRouteArgs> {
  TaskNewRecurrenceEndAtRoute({
    required _i46.Jiffy? minimumDateTime,
    required _i54.RecurrenceEnd? initialRecurrenceEnd,
    required _i50.ValueChanged<_i54.RecurrenceEnd?> onRecurrenceEndChanged,
    _i50.Key? key,
    List<_i45.PageRouteInfo>? children,
  }) : super(
         TaskNewRecurrenceEndAtRoute.name,
         args: TaskNewRecurrenceEndAtRouteArgs(
           minimumDateTime: minimumDateTime,
           initialRecurrenceEnd: initialRecurrenceEnd,
           onRecurrenceEndChanged: onRecurrenceEndChanged,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TaskNewRecurrenceEndAtRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskNewRecurrenceEndAtRouteArgs>();
      return _i38.TaskNewRecurrenceEndAtPage(
        minimumDateTime: args.minimumDateTime,
        initialRecurrenceEnd: args.initialRecurrenceEnd,
        onRecurrenceEndChanged: args.onRecurrenceEndChanged,
        key: args.key,
      );
    },
  );
}

class TaskNewRecurrenceEndAtRouteArgs {
  const TaskNewRecurrenceEndAtRouteArgs({
    required this.minimumDateTime,
    required this.initialRecurrenceEnd,
    required this.onRecurrenceEndChanged,
    this.key,
  });

  final _i46.Jiffy? minimumDateTime;

  final _i54.RecurrenceEnd? initialRecurrenceEnd;

  final _i50.ValueChanged<_i54.RecurrenceEnd?> onRecurrenceEndChanged;

  final _i50.Key? key;

  @override
  String toString() {
    return 'TaskNewRecurrenceEndAtRouteArgs{minimumDateTime: $minimumDateTime, initialRecurrenceEnd: $initialRecurrenceEnd, onRecurrenceEndChanged: $onRecurrenceEndChanged, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskNewRecurrenceEndAtRouteArgs) return false;
    return minimumDateTime == other.minimumDateTime &&
        initialRecurrenceEnd == other.initialRecurrenceEnd &&
        onRecurrenceEndChanged == other.onRecurrenceEndChanged &&
        key == other.key;
  }

  @override
  int get hashCode =>
      minimumDateTime.hashCode ^
      initialRecurrenceEnd.hashCode ^
      onRecurrenceEndChanged.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i39.TaskOverduePage]
class TaskOverdueRoute extends _i45.PageRouteInfo<void> {
  const TaskOverdueRoute({List<_i45.PageRouteInfo>? children})
    : super(TaskOverdueRoute.name, initialChildren: children);

  static const String name = 'TaskOverdueRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i39.TaskOverduePage();
    },
  );
}

/// generated route for
/// [_i40.TaskPickerPage]
class TaskPickerRoute extends _i45.PageRouteInfo<void> {
  const TaskPickerRoute({List<_i45.PageRouteInfo>? children})
    : super(TaskPickerRoute.name, initialChildren: children);

  static const String name = 'TaskPickerRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i40.TaskPickerPage();
    },
  );
}

/// generated route for
/// [_i41.TaskPriorityPickerPage]
class TaskPriorityPickerRoute
    extends _i45.PageRouteInfo<TaskPriorityPickerRouteArgs> {
  TaskPriorityPickerRoute({
    required _i55.TaskPriority selectedPriority,
    _i50.ValueChanged<_i55.TaskPriority>? onSelected,
    _i50.Key? key,
    List<_i45.PageRouteInfo>? children,
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

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskPriorityPickerRouteArgs>();
      return _i41.TaskPriorityPickerPage(
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

  final _i55.TaskPriority selectedPriority;

  final _i50.ValueChanged<_i55.TaskPriority>? onSelected;

  final _i50.Key? key;

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
/// [_i42.TaskRecurrencePage]
class TaskRecurrenceRoute extends _i45.PageRouteInfo<TaskRecurrenceRouteArgs> {
  TaskRecurrenceRoute({
    required _i50.ValueChanged<_i54.RecurrenceRule?> onRecurrenceRuleChanged,
    _i46.Jiffy? taskDate,
    _i54.RecurrenceRule? initialRecurrenceRule,
    _i50.Key? key,
    List<_i45.PageRouteInfo>? children,
  }) : super(
         TaskRecurrenceRoute.name,
         args: TaskRecurrenceRouteArgs(
           onRecurrenceRuleChanged: onRecurrenceRuleChanged,
           taskDate: taskDate,
           initialRecurrenceRule: initialRecurrenceRule,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TaskRecurrenceRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskRecurrenceRouteArgs>();
      return _i42.TaskRecurrencePage(
        onRecurrenceRuleChanged: args.onRecurrenceRuleChanged,
        taskDate: args.taskDate,
        initialRecurrenceRule: args.initialRecurrenceRule,
        key: args.key,
      );
    },
  );
}

class TaskRecurrenceRouteArgs {
  const TaskRecurrenceRouteArgs({
    required this.onRecurrenceRuleChanged,
    this.taskDate,
    this.initialRecurrenceRule,
    this.key,
  });

  final _i50.ValueChanged<_i54.RecurrenceRule?> onRecurrenceRuleChanged;

  final _i46.Jiffy? taskDate;

  final _i54.RecurrenceRule? initialRecurrenceRule;

  final _i50.Key? key;

  @override
  String toString() {
    return 'TaskRecurrenceRouteArgs{onRecurrenceRuleChanged: $onRecurrenceRuleChanged, taskDate: $taskDate, initialRecurrenceRule: $initialRecurrenceRule, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskRecurrenceRouteArgs) return false;
    return onRecurrenceRuleChanged == other.onRecurrenceRuleChanged &&
        taskDate == other.taskDate &&
        initialRecurrenceRule == other.initialRecurrenceRule &&
        key == other.key;
  }

  @override
  int get hashCode =>
      onRecurrenceRuleChanged.hashCode ^
      taskDate.hashCode ^
      initialRecurrenceRule.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i43.TaskTagPage]
class TaskTagRoute extends _i45.PageRouteInfo<TaskTagRouteArgs> {
  TaskTagRoute({
    required _i53.TagEntity tag,
    _i47.Key? key,
    List<_i45.PageRouteInfo>? children,
  }) : super(
         TaskTagRoute.name,
         args: TaskTagRouteArgs(tag: tag, key: key),
         initialChildren: children,
       );

  static const String name = 'TaskTagRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskTagRouteArgs>();
      return _i43.TaskTagPage(tag: args.tag, key: args.key);
    },
  );
}

class TaskTagRouteArgs {
  const TaskTagRouteArgs({required this.tag, this.key});

  final _i53.TagEntity tag;

  final _i47.Key? key;

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
/// [_i44.TaskTodayPage]
class TaskTodayRoute extends _i45.PageRouteInfo<void> {
  const TaskTodayRoute({List<_i45.PageRouteInfo>? children})
    : super(TaskTodayRoute.name, initialChildren: children);

  static const String name = 'TaskTodayRoute';

  static _i45.PageInfo page = _i45.PageInfo(
    name,
    builder: (data) {
      return const _i44.TaskTodayPage();
    },
  );
}
