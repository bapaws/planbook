// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i50;
import 'package:collection/collection.dart' as _i58;
import 'package:flutter/cupertino.dart' as _i55;
import 'package:flutter/material.dart' as _i52;
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
import 'package:flutter_planbook/note/tag/view/note_tag_page.dart' as _i17;
import 'package:flutter_planbook/note/timeline/view/note_timeline_page.dart'
    as _i18;
import 'package:flutter_planbook/note/type/view/note_new_type_page.dart'
    as _i16;
import 'package:flutter_planbook/root/home/view/root_home_page.dart' as _i19;
import 'package:flutter_planbook/root/journal/view/root_journal_page.dart'
    as _i20;
import 'package:flutter_planbook/root/note/view/root_note_page.dart' as _i21;
import 'package:flutter_planbook/root/task/view/root_task_page.dart' as _i22;
import 'package:flutter_planbook/settings/about/view/about_page.dart' as _i1;
import 'package:flutter_planbook/settings/background/view/settings_background_page.dart'
    as _i23;
import 'package:flutter_planbook/settings/color/view/settings_seed_color_page.dart'
    as _i27;
import 'package:flutter_planbook/settings/dark/view/settings_dark_mode_page.dart'
    as _i24;
import 'package:flutter_planbook/settings/feedback/view/feedback_page.dart'
    as _i3;
import 'package:flutter_planbook/settings/home/view/settings_home_page.dart'
    as _i25;
import 'package:flutter_planbook/settings/icon/view/settings_icon_page.dart'
    as _i26;
import 'package:flutter_planbook/settings/task/view/settings_task_page.dart'
    as _i28;
import 'package:flutter_planbook/sign/home/view/sign_home_page.dart' as _i29;
import 'package:flutter_planbook/tag/list/bloc/tag_list_bloc.dart' as _i57;
import 'package:flutter_planbook/tag/list/view/tag_list_page.dart' as _i30;
import 'package:flutter_planbook/tag/new/view/tag_new_page.dart' as _i31;
import 'package:flutter_planbook/tag/picker/view/tag_picker_page.dart' as _i32;
import 'package:flutter_planbook/task/child/view/task_new_child_page.dart'
    as _i40;
import 'package:flutter_planbook/task/detail/view/task_detail_page.dart'
    as _i34;
import 'package:flutter_planbook/task/done/view/task_done_page.dart' as _i35;
import 'package:flutter_planbook/task/duration/view/task_duration_page.dart'
    as _i36;
import 'package:flutter_planbook/task/inbox/view/task_inbox_page.dart' as _i37;
import 'package:flutter_planbook/task/list/view/task_list_page.dart' as _i38;
import 'package:flutter_planbook/task/month/view/task_month_page.dart' as _i39;
import 'package:flutter_planbook/task/new/view/task_new_page.dart' as _i41;
import 'package:flutter_planbook/task/new/view/task_new_recurrence_ends_page.dart'
    as _i42;
import 'package:flutter_planbook/task/overdue/view/task_overdue_page.dart'
    as _i43;
import 'package:flutter_planbook/task/picker/view/task_date_picker_page.dart'
    as _i33;
import 'package:flutter_planbook/task/picker/view/task_picker_page.dart'
    as _i44;
import 'package:flutter_planbook/task/picker/view/task_priority_picker_page.dart'
    as _i45;
import 'package:flutter_planbook/task/recurrence/view/task_recurrence_page.dart'
    as _i46;
import 'package:flutter_planbook/task/tag/view/task_tag_page.dart' as _i47;
import 'package:flutter_planbook/task/today/view/task_today_page.dart' as _i48;
import 'package:flutter_planbook/task/week/view/task_week_page.dart' as _i49;
import 'package:jiffy/jiffy.dart' as _i51;
import 'package:planbook_api/database/recurrence_rule.dart' as _i60;
import 'package:planbook_api/database/task_priority.dart' as _i61;
import 'package:planbook_api/entity/tag_entity.dart' as _i56;
import 'package:planbook_api/entity/task_entity.dart' as _i59;
import 'package:planbook_api/planbook_api.dart' as _i54;
import 'package:planbook_repository/planbook_repository.dart' as _i53;

/// generated route for
/// [_i1.AboutPage]
class AboutRoute extends _i50.PageRouteInfo<void> {
  const AboutRoute({List<_i50.PageRouteInfo>? children})
    : super(AboutRoute.name, initialChildren: children);

  static const String name = 'AboutRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i1.AboutPage();
    },
  );
}

/// generated route for
/// [_i2.AppPurchasesPage]
class AppPurchasesRoute extends _i50.PageRouteInfo<void> {
  const AppPurchasesRoute({List<_i50.PageRouteInfo>? children})
    : super(AppPurchasesRoute.name, initialChildren: children);

  static const String name = 'AppPurchasesRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i2.AppPurchasesPage();
    },
  );
}

/// generated route for
/// [_i3.FeedbackPage]
class FeedbackRoute extends _i50.PageRouteInfo<void> {
  const FeedbackRoute({List<_i50.PageRouteInfo>? children})
    : super(FeedbackRoute.name, initialChildren: children);

  static const String name = 'FeedbackRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i3.FeedbackPage();
    },
  );
}

/// generated route for
/// [_i4.JournalDayPage]
class JournalDayRoute extends _i50.PageRouteInfo<JournalDayRouteArgs> {
  JournalDayRoute({
    required _i51.Jiffy date,
    _i52.Key? key,
    List<_i50.PageRouteInfo>? children,
  }) : super(
         JournalDayRoute.name,
         args: JournalDayRouteArgs(date: date, key: key),
         initialChildren: children,
       );

  static const String name = 'JournalDayRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JournalDayRouteArgs>();
      return _i4.JournalDayPage(date: args.date, key: args.key);
    },
  );
}

class JournalDayRouteArgs {
  const JournalDayRouteArgs({required this.date, this.key});

  final _i51.Jiffy date;

  final _i52.Key? key;

  @override
  String toString() {
    return 'JournalDayRouteArgs{date: $date, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JournalDayRouteArgs) return false;
    return date == other.date && key == other.key;
  }

  @override
  int get hashCode => date.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i5.JournalNotePage]
class JournalNoteRoute extends _i50.PageRouteInfo<JournalNoteRouteArgs> {
  JournalNoteRoute({
    required _i51.Jiffy date,
    _i52.Key? key,
    List<_i50.PageRouteInfo>? children,
  }) : super(
         JournalNoteRoute.name,
         args: JournalNoteRouteArgs(date: date, key: key),
         initialChildren: children,
       );

  static const String name = 'JournalNoteRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JournalNoteRouteArgs>();
      return _i5.JournalNotePage(date: args.date, key: args.key);
    },
  );
}

class JournalNoteRouteArgs {
  const JournalNoteRouteArgs({required this.date, this.key});

  final _i51.Jiffy date;

  final _i52.Key? key;

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
class JournalPriorityRoute extends _i50.PageRouteInfo<void> {
  const JournalPriorityRoute({List<_i50.PageRouteInfo>? children})
    : super(JournalPriorityRoute.name, initialChildren: children);

  static const String name = 'JournalPriorityRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i6.JournalPriorityPage();
    },
  );
}

/// generated route for
/// [_i7.MineDeletePage]
class MineDeleteRoute extends _i50.PageRouteInfo<void> {
  const MineDeleteRoute({List<_i50.PageRouteInfo>? children})
    : super(MineDeleteRoute.name, initialChildren: children);

  static const String name = 'MineDeleteRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i7.MineDeletePage();
    },
  );
}

/// generated route for
/// [_i8.MineEmailPage]
class MineEmailRoute extends _i50.PageRouteInfo<void> {
  const MineEmailRoute({List<_i50.PageRouteInfo>? children})
    : super(MineEmailRoute.name, initialChildren: children);

  static const String name = 'MineEmailRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i8.MineEmailPage();
    },
  );
}

/// generated route for
/// [_i9.MinePasswordPage]
class MinePasswordRoute extends _i50.PageRouteInfo<void> {
  const MinePasswordRoute({List<_i50.PageRouteInfo>? children})
    : super(MinePasswordRoute.name, initialChildren: children);

  static const String name = 'MinePasswordRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i9.MinePasswordPage();
    },
  );
}

/// generated route for
/// [_i10.MinePhonePage]
class MinePhoneRoute extends _i50.PageRouteInfo<void> {
  const MinePhoneRoute({List<_i50.PageRouteInfo>? children})
    : super(MinePhoneRoute.name, initialChildren: children);

  static const String name = 'MinePhoneRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i10.MinePhonePage();
    },
  );
}

/// generated route for
/// [_i11.MineProfilePage]
class MineProfileRoute extends _i50.PageRouteInfo<void> {
  const MineProfileRoute({List<_i50.PageRouteInfo>? children})
    : super(MineProfileRoute.name, initialChildren: children);

  static const String name = 'MineProfileRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i11.MineProfilePage();
    },
  );
}

/// generated route for
/// [_i12.NoteGalleryPage]
class NoteGalleryRoute extends _i50.PageRouteInfo<void> {
  const NoteGalleryRoute({List<_i50.PageRouteInfo>? children})
    : super(NoteGalleryRoute.name, initialChildren: children);

  static const String name = 'NoteGalleryRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i12.NoteGalleryPage();
    },
  );
}

/// generated route for
/// [_i13.NoteListPage]
class NoteListRoute extends _i50.PageRouteInfo<void> {
  const NoteListRoute({List<_i50.PageRouteInfo>? children})
    : super(NoteListRoute.name, initialChildren: children);

  static const String name = 'NoteListRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i13.NoteListPage();
    },
  );
}

/// generated route for
/// [_i14.NoteNewFullscreenPage]
class NoteNewFullscreenRoute
    extends _i50.PageRouteInfo<NoteNewFullscreenRouteArgs> {
  NoteNewFullscreenRoute({
    _i53.NoteEntity? initialNote,
    _i52.Key? key,
    List<_i50.PageRouteInfo>? children,
  }) : super(
         NoteNewFullscreenRoute.name,
         args: NoteNewFullscreenRouteArgs(initialNote: initialNote, key: key),
         initialChildren: children,
       );

  static const String name = 'NoteNewFullscreenRoute';

  static _i50.PageInfo page = _i50.PageInfo(
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

  final _i53.NoteEntity? initialNote;

  final _i52.Key? key;

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
class NoteNewRoute extends _i50.PageRouteInfo<NoteNewRouteArgs> {
  NoteNewRoute({
    _i53.NoteEntity? initialNote,
    _i53.TaskEntity? initialTask,
    _i52.Key? key,
    List<_i50.PageRouteInfo>? children,
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

  static _i50.PageInfo page = _i50.PageInfo(
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

  final _i53.NoteEntity? initialNote;

  final _i53.TaskEntity? initialTask;

  final _i52.Key? key;

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
/// [_i16.NoteNewTypePage]
class NoteNewTypeRoute extends _i50.PageRouteInfo<NoteNewTypeRouteArgs> {
  NoteNewTypeRoute({
    required _i54.NoteType type,
    required _i51.Jiffy focusAt,
    _i54.Note? initialNote,
    _i55.Key? key,
    List<_i50.PageRouteInfo>? children,
  }) : super(
         NoteNewTypeRoute.name,
         args: NoteNewTypeRouteArgs(
           type: type,
           focusAt: focusAt,
           initialNote: initialNote,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'NoteNewTypeRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteNewTypeRouteArgs>();
      return _i16.NoteNewTypePage(
        type: args.type,
        focusAt: args.focusAt,
        initialNote: args.initialNote,
        key: args.key,
      );
    },
  );
}

class NoteNewTypeRouteArgs {
  const NoteNewTypeRouteArgs({
    required this.type,
    required this.focusAt,
    this.initialNote,
    this.key,
  });

  final _i54.NoteType type;

  final _i51.Jiffy focusAt;

  final _i54.Note? initialNote;

  final _i55.Key? key;

  @override
  String toString() {
    return 'NoteNewTypeRouteArgs{type: $type, focusAt: $focusAt, initialNote: $initialNote, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteNewTypeRouteArgs) return false;
    return type == other.type &&
        focusAt == other.focusAt &&
        initialNote == other.initialNote &&
        key == other.key;
  }

  @override
  int get hashCode =>
      type.hashCode ^ focusAt.hashCode ^ initialNote.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i17.NoteTagPage]
class NoteTagRoute extends _i50.PageRouteInfo<NoteTagRouteArgs> {
  NoteTagRoute({
    required _i56.TagEntity tag,
    _i52.Key? key,
    List<_i50.PageRouteInfo>? children,
  }) : super(
         NoteTagRoute.name,
         args: NoteTagRouteArgs(tag: tag, key: key),
         initialChildren: children,
       );

  static const String name = 'NoteTagRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteTagRouteArgs>();
      return _i17.NoteTagPage(tag: args.tag, key: args.key);
    },
  );
}

class NoteTagRouteArgs {
  const NoteTagRouteArgs({required this.tag, this.key});

  final _i56.TagEntity tag;

  final _i52.Key? key;

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
/// [_i18.NoteTimelinePage]
class NoteTimelineRoute extends _i50.PageRouteInfo<NoteTimelineRouteArgs> {
  NoteTimelineRoute({
    _i52.Key? key,
    _i53.NoteListMode mode = _i53.NoteListMode.all,
    List<_i50.PageRouteInfo>? children,
  }) : super(
         NoteTimelineRoute.name,
         args: NoteTimelineRouteArgs(key: key, mode: mode),
         initialChildren: children,
       );

  static const String name = 'NoteTimelineRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteTimelineRouteArgs>(
        orElse: () => const NoteTimelineRouteArgs(),
      );
      return _i18.NoteTimelinePage(key: args.key, mode: args.mode);
    },
  );
}

class NoteTimelineRouteArgs {
  const NoteTimelineRouteArgs({this.key, this.mode = _i53.NoteListMode.all});

  final _i52.Key? key;

  final _i53.NoteListMode mode;

  @override
  String toString() {
    return 'NoteTimelineRouteArgs{key: $key, mode: $mode}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NoteTimelineRouteArgs) return false;
    return key == other.key && mode == other.mode;
  }

  @override
  int get hashCode => key.hashCode ^ mode.hashCode;
}

/// generated route for
/// [_i19.RootHomePage]
class RootHomeRoute extends _i50.PageRouteInfo<void> {
  const RootHomeRoute({List<_i50.PageRouteInfo>? children})
    : super(RootHomeRoute.name, initialChildren: children);

  static const String name = 'RootHomeRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i19.RootHomePage();
    },
  );
}

/// generated route for
/// [_i20.RootJournalPage]
class RootJournalRoute extends _i50.PageRouteInfo<void> {
  const RootJournalRoute({List<_i50.PageRouteInfo>? children})
    : super(RootJournalRoute.name, initialChildren: children);

  static const String name = 'RootJournalRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i20.RootJournalPage();
    },
  );
}

/// generated route for
/// [_i21.RootNotePage]
class RootNoteRoute extends _i50.PageRouteInfo<void> {
  const RootNoteRoute({List<_i50.PageRouteInfo>? children})
    : super(RootNoteRoute.name, initialChildren: children);

  static const String name = 'RootNoteRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i21.RootNotePage();
    },
  );
}

/// generated route for
/// [_i22.RootTaskPage]
class RootTaskRoute extends _i50.PageRouteInfo<void> {
  const RootTaskRoute({List<_i50.PageRouteInfo>? children})
    : super(RootTaskRoute.name, initialChildren: children);

  static const String name = 'RootTaskRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i22.RootTaskPage();
    },
  );
}

/// generated route for
/// [_i23.SettingsBackgroundPage]
class SettingsBackgroundRoute extends _i50.PageRouteInfo<void> {
  const SettingsBackgroundRoute({List<_i50.PageRouteInfo>? children})
    : super(SettingsBackgroundRoute.name, initialChildren: children);

  static const String name = 'SettingsBackgroundRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i23.SettingsBackgroundPage();
    },
  );
}

/// generated route for
/// [_i24.SettingsDarkModePage]
class SettingsDarkModeRoute extends _i50.PageRouteInfo<void> {
  const SettingsDarkModeRoute({List<_i50.PageRouteInfo>? children})
    : super(SettingsDarkModeRoute.name, initialChildren: children);

  static const String name = 'SettingsDarkModeRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i24.SettingsDarkModePage();
    },
  );
}

/// generated route for
/// [_i25.SettingsHomePage]
class SettingsHomeRoute extends _i50.PageRouteInfo<void> {
  const SettingsHomeRoute({List<_i50.PageRouteInfo>? children})
    : super(SettingsHomeRoute.name, initialChildren: children);

  static const String name = 'SettingsHomeRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i25.SettingsHomePage();
    },
  );
}

/// generated route for
/// [_i26.SettingsIconPage]
class SettingsIconRoute extends _i50.PageRouteInfo<void> {
  const SettingsIconRoute({List<_i50.PageRouteInfo>? children})
    : super(SettingsIconRoute.name, initialChildren: children);

  static const String name = 'SettingsIconRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i26.SettingsIconPage();
    },
  );
}

/// generated route for
/// [_i27.SettingsSeedColorPage]
class SettingsSeedColorRoute extends _i50.PageRouteInfo<void> {
  const SettingsSeedColorRoute({List<_i50.PageRouteInfo>? children})
    : super(SettingsSeedColorRoute.name, initialChildren: children);

  static const String name = 'SettingsSeedColorRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i27.SettingsSeedColorPage();
    },
  );
}

/// generated route for
/// [_i28.SettingsTaskPage]
class SettingsTaskRoute extends _i50.PageRouteInfo<void> {
  const SettingsTaskRoute({List<_i50.PageRouteInfo>? children})
    : super(SettingsTaskRoute.name, initialChildren: children);

  static const String name = 'SettingsTaskRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i28.SettingsTaskPage();
    },
  );
}

/// generated route for
/// [_i29.SignHomePage]
class SignHomeRoute extends _i50.PageRouteInfo<void> {
  const SignHomeRoute({List<_i50.PageRouteInfo>? children})
    : super(SignHomeRoute.name, initialChildren: children);

  static const String name = 'SignHomeRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i29.SignHomePage();
    },
  );
}

/// generated route for
/// [_i30.TagListPage]
class TagListRoute extends _i50.PageRouteInfo<TagListRouteArgs> {
  TagListRoute({
    required _i57.TagListMode mode,
    required List<_i53.TagEntity> selectedTags,
    _i52.Key? key,
    List<_i50.PageRouteInfo>? children,
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

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagListRouteArgs>();
      return _i30.TagListPage(
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

  final _i57.TagListMode mode;

  final List<_i53.TagEntity> selectedTags;

  final _i52.Key? key;

  @override
  String toString() {
    return 'TagListRouteArgs{mode: $mode, selectedTags: $selectedTags, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagListRouteArgs) return false;
    return mode == other.mode &&
        const _i58.ListEquality<_i53.TagEntity>().equals(
          selectedTags,
          other.selectedTags,
        ) &&
        key == other.key;
  }

  @override
  int get hashCode =>
      mode.hashCode ^
      const _i58.ListEquality<_i53.TagEntity>().hash(selectedTags) ^
      key.hashCode;
}

/// generated route for
/// [_i31.TagNewPage]
class TagNewRoute extends _i50.PageRouteInfo<TagNewRouteArgs> {
  TagNewRoute({
    _i54.TagEntity? initialTag,
    _i55.Key? key,
    List<_i50.PageRouteInfo>? children,
  }) : super(
         TagNewRoute.name,
         args: TagNewRouteArgs(initialTag: initialTag, key: key),
         initialChildren: children,
       );

  static const String name = 'TagNewRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagNewRouteArgs>(
        orElse: () => const TagNewRouteArgs(),
      );
      return _i31.TagNewPage(initialTag: args.initialTag, key: args.key);
    },
  );
}

class TagNewRouteArgs {
  const TagNewRouteArgs({this.initialTag, this.key});

  final _i54.TagEntity? initialTag;

  final _i55.Key? key;

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
/// [_i32.TagPickerPage]
class TagPickerRoute extends _i50.PageRouteInfo<TagPickerRouteArgs> {
  TagPickerRoute({
    required List<_i56.TagEntity> selectedTags,
    required _i55.ValueChanged<List<_i56.TagEntity>> onSelected,
    _i55.Key? key,
    List<_i50.PageRouteInfo>? children,
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

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagPickerRouteArgs>();
      return _i32.TagPickerPage(
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

  final List<_i56.TagEntity> selectedTags;

  final _i55.ValueChanged<List<_i56.TagEntity>> onSelected;

  final _i55.Key? key;

  @override
  String toString() {
    return 'TagPickerRouteArgs{selectedTags: $selectedTags, onSelected: $onSelected, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagPickerRouteArgs) return false;
    return const _i58.ListEquality<_i56.TagEntity>().equals(
          selectedTags,
          other.selectedTags,
        ) &&
        onSelected == other.onSelected &&
        key == other.key;
  }

  @override
  int get hashCode =>
      const _i58.ListEquality<_i56.TagEntity>().hash(selectedTags) ^
      onSelected.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i33.TaskDatePickerPage]
class TaskDatePickerRoute extends _i50.PageRouteInfo<TaskDatePickerRouteArgs> {
  TaskDatePickerRoute({
    required _i53.Jiffy date,
    _i55.ValueChanged<_i53.Jiffy?>? onDateChanged,
    _i55.Key? key,
    List<_i50.PageRouteInfo>? children,
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

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDatePickerRouteArgs>();
      return _i33.TaskDatePickerPage(
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

  final _i53.Jiffy date;

  final _i55.ValueChanged<_i53.Jiffy?>? onDateChanged;

  final _i55.Key? key;

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
/// [_i34.TaskDetailPage]
class TaskDetailRoute extends _i50.PageRouteInfo<TaskDetailRouteArgs> {
  TaskDetailRoute({
    required String taskId,
    _i53.Jiffy? occurrenceAt,
    _i55.Key? key,
    List<_i50.PageRouteInfo>? children,
  }) : super(
         TaskDetailRoute.name,
         args: TaskDetailRouteArgs(
           taskId: taskId,
           occurrenceAt: occurrenceAt,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TaskDetailRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDetailRouteArgs>();
      return _i34.TaskDetailPage(
        taskId: args.taskId,
        occurrenceAt: args.occurrenceAt,
        key: args.key,
      );
    },
  );
}

class TaskDetailRouteArgs {
  const TaskDetailRouteArgs({
    required this.taskId,
    this.occurrenceAt,
    this.key,
  });

  final String taskId;

  final _i53.Jiffy? occurrenceAt;

  final _i55.Key? key;

  @override
  String toString() {
    return 'TaskDetailRouteArgs{taskId: $taskId, occurrenceAt: $occurrenceAt, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskDetailRouteArgs) return false;
    return taskId == other.taskId &&
        occurrenceAt == other.occurrenceAt &&
        key == other.key;
  }

  @override
  int get hashCode => taskId.hashCode ^ occurrenceAt.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i35.TaskDonePage]
class TaskDoneRoute extends _i50.PageRouteInfo<TaskDoneRouteArgs> {
  TaskDoneRoute({
    required _i59.TaskEntity task,
    _i55.Key? key,
    List<_i50.PageRouteInfo>? children,
  }) : super(
         TaskDoneRoute.name,
         args: TaskDoneRouteArgs(task: task, key: key),
         initialChildren: children,
       );

  static const String name = 'TaskDoneRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDoneRouteArgs>();
      return _i35.TaskDonePage(task: args.task, key: args.key);
    },
  );
}

class TaskDoneRouteArgs {
  const TaskDoneRouteArgs({required this.task, this.key});

  final _i59.TaskEntity task;

  final _i55.Key? key;

  @override
  String toString() {
    return 'TaskDoneRouteArgs{task: $task, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskDoneRouteArgs) return false;
    return task == other.task && key == other.key;
  }

  @override
  int get hashCode => task.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i36.TaskDurationPage]
class TaskDurationRoute extends _i50.PageRouteInfo<TaskDurationRouteArgs> {
  TaskDurationRoute({
    _i51.Jiffy? startAt,
    _i51.Jiffy? endAt,
    bool isAllDay = true,
    _i55.Key? key,
    List<_i50.PageRouteInfo>? children,
  }) : super(
         TaskDurationRoute.name,
         args: TaskDurationRouteArgs(
           startAt: startAt,
           endAt: endAt,
           isAllDay: isAllDay,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TaskDurationRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDurationRouteArgs>(
        orElse: () => const TaskDurationRouteArgs(),
      );
      return _i36.TaskDurationPage(
        startAt: args.startAt,
        endAt: args.endAt,
        isAllDay: args.isAllDay,
        key: args.key,
      );
    },
  );
}

class TaskDurationRouteArgs {
  const TaskDurationRouteArgs({
    this.startAt,
    this.endAt,
    this.isAllDay = true,
    this.key,
  });

  final _i51.Jiffy? startAt;

  final _i51.Jiffy? endAt;

  final bool isAllDay;

  final _i55.Key? key;

  @override
  String toString() {
    return 'TaskDurationRouteArgs{startAt: $startAt, endAt: $endAt, isAllDay: $isAllDay, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskDurationRouteArgs) return false;
    return startAt == other.startAt &&
        endAt == other.endAt &&
        isAllDay == other.isAllDay &&
        key == other.key;
  }

  @override
  int get hashCode =>
      startAt.hashCode ^ endAt.hashCode ^ isAllDay.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i37.TaskInboxPage]
class TaskInboxRoute extends _i50.PageRouteInfo<void> {
  const TaskInboxRoute({List<_i50.PageRouteInfo>? children})
    : super(TaskInboxRoute.name, initialChildren: children);

  static const String name = 'TaskInboxRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i37.TaskInboxPage();
    },
  );
}

/// generated route for
/// [_i38.TaskListPage]
class TaskListRoute extends _i50.PageRouteInfo<void> {
  const TaskListRoute({List<_i50.PageRouteInfo>? children})
    : super(TaskListRoute.name, initialChildren: children);

  static const String name = 'TaskListRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i38.TaskListPage();
    },
  );
}

/// generated route for
/// [_i39.TaskMonthPage]
class TaskMonthRoute extends _i50.PageRouteInfo<void> {
  const TaskMonthRoute({List<_i50.PageRouteInfo>? children})
    : super(TaskMonthRoute.name, initialChildren: children);

  static const String name = 'TaskMonthRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i39.TaskMonthPage();
    },
  );
}

/// generated route for
/// [_i40.TaskNewChildPage]
class TaskNewChildRoute extends _i50.PageRouteInfo<TaskNewChildRouteArgs> {
  TaskNewChildRoute({
    required List<_i54.TaskEntity> subTasks,
    _i55.Key? key,
    List<_i50.PageRouteInfo>? children,
  }) : super(
         TaskNewChildRoute.name,
         args: TaskNewChildRouteArgs(subTasks: subTasks, key: key),
         initialChildren: children,
       );

  static const String name = 'TaskNewChildRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskNewChildRouteArgs>();
      return _i40.TaskNewChildPage(subTasks: args.subTasks, key: args.key);
    },
  );
}

class TaskNewChildRouteArgs {
  const TaskNewChildRouteArgs({required this.subTasks, this.key});

  final List<_i54.TaskEntity> subTasks;

  final _i55.Key? key;

  @override
  String toString() {
    return 'TaskNewChildRouteArgs{subTasks: $subTasks, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskNewChildRouteArgs) return false;
    return const _i58.ListEquality<_i54.TaskEntity>().equals(
          subTasks,
          other.subTasks,
        ) &&
        key == other.key;
  }

  @override
  int get hashCode =>
      const _i58.ListEquality<_i54.TaskEntity>().hash(subTasks) ^ key.hashCode;
}

/// generated route for
/// [_i41.TaskNewPage]
class TaskNewRoute extends _i50.PageRouteInfo<TaskNewRouteArgs> {
  TaskNewRoute({
    _i53.TaskEntity? initialTask,
    _i53.Jiffy? dueAt,
    _i55.Key? key,
    List<_i50.PageRouteInfo>? children,
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

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskNewRouteArgs>(
        orElse: () => const TaskNewRouteArgs(),
      );
      return _i41.TaskNewPage(
        initialTask: args.initialTask,
        dueAt: args.dueAt,
        key: args.key,
      );
    },
  );
}

class TaskNewRouteArgs {
  const TaskNewRouteArgs({this.initialTask, this.dueAt, this.key});

  final _i53.TaskEntity? initialTask;

  final _i53.Jiffy? dueAt;

  final _i55.Key? key;

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
/// [_i42.TaskNewRecurrenceEndAtPage]
class TaskNewRecurrenceEndAtRoute
    extends _i50.PageRouteInfo<TaskNewRecurrenceEndAtRouteArgs> {
  TaskNewRecurrenceEndAtRoute({
    required _i51.Jiffy? minimumDateTime,
    required _i60.RecurrenceEnd? initialRecurrenceEnd,
    required _i55.ValueChanged<_i60.RecurrenceEnd?> onRecurrenceEndChanged,
    _i55.Key? key,
    List<_i50.PageRouteInfo>? children,
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

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskNewRecurrenceEndAtRouteArgs>();
      return _i42.TaskNewRecurrenceEndAtPage(
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

  final _i51.Jiffy? minimumDateTime;

  final _i60.RecurrenceEnd? initialRecurrenceEnd;

  final _i55.ValueChanged<_i60.RecurrenceEnd?> onRecurrenceEndChanged;

  final _i55.Key? key;

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
/// [_i43.TaskOverduePage]
class TaskOverdueRoute extends _i50.PageRouteInfo<void> {
  const TaskOverdueRoute({List<_i50.PageRouteInfo>? children})
    : super(TaskOverdueRoute.name, initialChildren: children);

  static const String name = 'TaskOverdueRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i43.TaskOverduePage();
    },
  );
}

/// generated route for
/// [_i44.TaskPickerPage]
class TaskPickerRoute extends _i50.PageRouteInfo<void> {
  const TaskPickerRoute({List<_i50.PageRouteInfo>? children})
    : super(TaskPickerRoute.name, initialChildren: children);

  static const String name = 'TaskPickerRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i44.TaskPickerPage();
    },
  );
}

/// generated route for
/// [_i45.TaskPriorityPickerPage]
class TaskPriorityPickerRoute
    extends _i50.PageRouteInfo<TaskPriorityPickerRouteArgs> {
  TaskPriorityPickerRoute({
    required _i61.TaskPriority selectedPriority,
    _i55.ValueChanged<_i61.TaskPriority>? onSelected,
    _i55.Key? key,
    List<_i50.PageRouteInfo>? children,
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

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskPriorityPickerRouteArgs>();
      return _i45.TaskPriorityPickerPage(
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

  final _i61.TaskPriority selectedPriority;

  final _i55.ValueChanged<_i61.TaskPriority>? onSelected;

  final _i55.Key? key;

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
/// [_i46.TaskRecurrencePage]
class TaskRecurrenceRoute extends _i50.PageRouteInfo<TaskRecurrenceRouteArgs> {
  TaskRecurrenceRoute({
    _i51.Jiffy? taskDate,
    _i60.RecurrenceRule? initialRecurrenceRule,
    _i55.Key? key,
    List<_i50.PageRouteInfo>? children,
  }) : super(
         TaskRecurrenceRoute.name,
         args: TaskRecurrenceRouteArgs(
           taskDate: taskDate,
           initialRecurrenceRule: initialRecurrenceRule,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TaskRecurrenceRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskRecurrenceRouteArgs>(
        orElse: () => const TaskRecurrenceRouteArgs(),
      );
      return _i46.TaskRecurrencePage(
        taskDate: args.taskDate,
        initialRecurrenceRule: args.initialRecurrenceRule,
        key: args.key,
      );
    },
  );
}

class TaskRecurrenceRouteArgs {
  const TaskRecurrenceRouteArgs({
    this.taskDate,
    this.initialRecurrenceRule,
    this.key,
  });

  final _i51.Jiffy? taskDate;

  final _i60.RecurrenceRule? initialRecurrenceRule;

  final _i55.Key? key;

  @override
  String toString() {
    return 'TaskRecurrenceRouteArgs{taskDate: $taskDate, initialRecurrenceRule: $initialRecurrenceRule, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskRecurrenceRouteArgs) return false;
    return taskDate == other.taskDate &&
        initialRecurrenceRule == other.initialRecurrenceRule &&
        key == other.key;
  }

  @override
  int get hashCode =>
      taskDate.hashCode ^ initialRecurrenceRule.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i47.TaskTagPage]
class TaskTagRoute extends _i50.PageRouteInfo<void> {
  const TaskTagRoute({List<_i50.PageRouteInfo>? children})
    : super(TaskTagRoute.name, initialChildren: children);

  static const String name = 'TaskTagRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i47.TaskTagPage();
    },
  );
}

/// generated route for
/// [_i48.TaskTodayPage]
class TaskTodayRoute extends _i50.PageRouteInfo<void> {
  const TaskTodayRoute({List<_i50.PageRouteInfo>? children})
    : super(TaskTodayRoute.name, initialChildren: children);

  static const String name = 'TaskTodayRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i48.TaskTodayPage();
    },
  );
}

/// generated route for
/// [_i49.TaskWeekPage]
class TaskWeekRoute extends _i50.PageRouteInfo<void> {
  const TaskWeekRoute({List<_i50.PageRouteInfo>? children})
    : super(TaskWeekRoute.name, initialChildren: children);

  static const String name = 'TaskWeekRoute';

  static _i50.PageInfo page = _i50.PageInfo(
    name,
    builder: (data) {
      return const _i49.TaskWeekPage();
    },
  );
}
