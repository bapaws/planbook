// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i61;
import 'package:collection/collection.dart' as _i69;
import 'package:flutter/cupertino.dart' as _i63;
import 'package:flutter/material.dart' as _i64;
import 'package:flutter_planbook/app/activity/repository/app_activity_repository.dart'
    as _i62;
import 'package:flutter_planbook/app/activity/view/app_activity_alert_page.dart'
    as _i2;
import 'package:flutter_planbook/app/activity/view/app_activity_list_page.dart'
    as _i3;
import 'package:flutter_planbook/app/activity/view/app_activity_page.dart'
    as _i4;
import 'package:flutter_planbook/app/purchases/view/app_purchases_page.dart'
    as _i5;
import 'package:flutter_planbook/app/splash/view/splash_page.dart' as _i39;
import 'package:flutter_planbook/discover/cover/view/discover_journal_cover_page.dart'
    as _i7;
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart'
    as _i12;
import 'package:flutter_planbook/discover/export/view/journal_export_page.dart'
    as _i13;
import 'package:flutter_planbook/discover/focus/view/discover_focus_page.dart'
    as _i6;
import 'package:flutter_planbook/discover/journal/view/discover_journal_page.dart'
    as _i8;
import 'package:flutter_planbook/discover/play/view/discover_journal_play_page.dart'
    as _i9;
import 'package:flutter_planbook/discover/summary/view/discover_summary_page.dart'
    as _i10;
import 'package:flutter_planbook/mine/delete/view/mine_delete_page.dart'
    as _i14;
import 'package:flutter_planbook/mine/email/view/mine_email_page.dart' as _i15;
import 'package:flutter_planbook/mine/password/view/mine_password_page.dart'
    as _i16;
import 'package:flutter_planbook/mine/phone/view/mine_phone_page.dart' as _i17;
import 'package:flutter_planbook/mine/profile/view/mine_profile_page.dart'
    as _i18;
import 'package:flutter_planbook/note/gallery/view/note_gallery_page.dart'
    as _i19;
import 'package:flutter_planbook/note/list/view/note_list_page.dart' as _i20;
import 'package:flutter_planbook/note/new/view/note_new_fullscreen_page.dart'
    as _i21;
import 'package:flutter_planbook/note/new/view/note_new_page.dart' as _i22;
import 'package:flutter_planbook/note/tag/view/note_tag_page.dart' as _i24;
import 'package:flutter_planbook/note/timeline/view/note_task_page.dart'
    as _i25;
import 'package:flutter_planbook/note/timeline/view/note_timeline_page.dart'
    as _i26;
import 'package:flutter_planbook/note/timeline/view/note_written_page.dart'
    as _i27;
import 'package:flutter_planbook/note/type/view/note_new_type_page.dart'
    as _i23;
import 'package:flutter_planbook/root/discover/view/root_discover_page.dart'
    as _i28;
import 'package:flutter_planbook/root/home/view/root_home_page.dart' as _i29;
import 'package:flutter_planbook/root/note/view/root_note_page.dart' as _i30;
import 'package:flutter_planbook/root/task/view/root_task_page.dart' as _i31;
import 'package:flutter_planbook/settings/about/view/about_page.dart' as _i1;
import 'package:flutter_planbook/settings/background/view/settings_background_page.dart'
    as _i32;
import 'package:flutter_planbook/settings/color/view/settings_seed_color_page.dart'
    as _i36;
import 'package:flutter_planbook/settings/dark/view/settings_dark_mode_page.dart'
    as _i33;
import 'package:flutter_planbook/settings/feedback/view/feedback_page.dart'
    as _i11;
import 'package:flutter_planbook/settings/home/view/settings_home_page.dart'
    as _i34;
import 'package:flutter_planbook/settings/icon/view/settings_icon_page.dart'
    as _i35;
import 'package:flutter_planbook/settings/task/view/settings_task_page.dart'
    as _i37;
import 'package:flutter_planbook/sign/home/view/sign_home_page.dart' as _i38;
import 'package:flutter_planbook/tag/list/bloc/tag_list_bloc.dart' as _i68;
import 'package:flutter_planbook/tag/list/view/tag_list_page.dart' as _i40;
import 'package:flutter_planbook/tag/new/view/tag_new_page.dart' as _i41;
import 'package:flutter_planbook/tag/picker/view/tag_picker_page.dart' as _i42;
import 'package:flutter_planbook/task/alarm/view/task_alarm_page.dart' as _i43;
import 'package:flutter_planbook/task/child/view/task_new_child_page.dart'
    as _i51;
import 'package:flutter_planbook/task/detail/view/task_detail_page.dart'
    as _i45;
import 'package:flutter_planbook/task/done/view/task_done_page.dart' as _i46;
import 'package:flutter_planbook/task/duration/view/task_duration_page.dart'
    as _i47;
import 'package:flutter_planbook/task/inbox/view/task_inbox_page.dart' as _i48;
import 'package:flutter_planbook/task/list/view/task_list_page.dart' as _i49;
import 'package:flutter_planbook/task/month/view/task_month_page.dart' as _i50;
import 'package:flutter_planbook/task/new/view/task_new_page.dart' as _i52;
import 'package:flutter_planbook/task/overdue/view/task_overdue_page.dart'
    as _i54;
import 'package:flutter_planbook/task/picker/view/task_date_picker_page.dart'
    as _i44;
import 'package:flutter_planbook/task/picker/view/task_picker_page.dart'
    as _i55;
import 'package:flutter_planbook/task/picker/view/task_priority_picker_page.dart'
    as _i56;
import 'package:flutter_planbook/task/recurrence/view/task_recurrence_ends_page.dart'
    as _i53;
import 'package:flutter_planbook/task/recurrence/view/task_recurrence_page.dart'
    as _i57;
import 'package:flutter_planbook/task/tag/view/task_tag_page.dart' as _i58;
import 'package:flutter_planbook/task/today/view/task_today_page.dart' as _i59;
import 'package:flutter_planbook/task/week/view/task_week_page.dart' as _i60;
import 'package:jiffy/jiffy.dart' as _i67;
import 'package:planbook_api/database/recurrence_rule.dart' as _i72;
import 'package:planbook_api/database/task_priority.dart' as _i73;
import 'package:planbook_api/entity/tag_entity.dart' as _i70;
import 'package:planbook_api/entity/task_entity.dart' as _i71;
import 'package:planbook_api/planbook_api.dart' as _i66;
import 'package:planbook_repository/planbook_repository.dart' as _i65;

/// generated route for
/// [_i1.AboutPage]
class AboutRoute extends _i61.PageRouteInfo<void> {
  const AboutRoute({List<_i61.PageRouteInfo>? children})
    : super(AboutRoute.name, initialChildren: children);

  static const String name = 'AboutRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i1.AboutPage();
    },
  );
}

/// generated route for
/// [_i2.AppActivityAlertPage]
class AppActivityAlertRoute
    extends _i61.PageRouteInfo<AppActivityAlertRouteArgs> {
  AppActivityAlertRoute({
    required _i62.ActivityMessageEntity activity,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
  }) : super(
         AppActivityAlertRoute.name,
         args: AppActivityAlertRouteArgs(activity: activity, key: key),
         initialChildren: children,
       );

  static const String name = 'AppActivityAlertRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AppActivityAlertRouteArgs>();
      return _i2.AppActivityAlertPage(activity: args.activity, key: args.key);
    },
  );
}

class AppActivityAlertRouteArgs {
  const AppActivityAlertRouteArgs({required this.activity, this.key});

  final _i62.ActivityMessageEntity activity;

  final _i63.Key? key;

  @override
  String toString() {
    return 'AppActivityAlertRouteArgs{activity: $activity, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AppActivityAlertRouteArgs) return false;
    return activity == other.activity && key == other.key;
  }

  @override
  int get hashCode => activity.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i3.AppActivityListPage]
class AppActivityListRoute extends _i61.PageRouteInfo<void> {
  const AppActivityListRoute({List<_i61.PageRouteInfo>? children})
    : super(AppActivityListRoute.name, initialChildren: children);

  static const String name = 'AppActivityListRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i3.AppActivityListPage();
    },
  );
}

/// generated route for
/// [_i4.AppActivityPage]
class AppActivityRoute extends _i61.PageRouteInfo<AppActivityRouteArgs> {
  AppActivityRoute({
    required _i62.ActivityMessageEntity activity,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
  }) : super(
         AppActivityRoute.name,
         args: AppActivityRouteArgs(activity: activity, key: key),
         initialChildren: children,
       );

  static const String name = 'AppActivityRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AppActivityRouteArgs>();
      return _i4.AppActivityPage(activity: args.activity, key: args.key);
    },
  );
}

class AppActivityRouteArgs {
  const AppActivityRouteArgs({required this.activity, this.key});

  final _i62.ActivityMessageEntity activity;

  final _i63.Key? key;

  @override
  String toString() {
    return 'AppActivityRouteArgs{activity: $activity, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AppActivityRouteArgs) return false;
    return activity == other.activity && key == other.key;
  }

  @override
  int get hashCode => activity.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i5.AppPurchasesPage]
class AppPurchasesRoute extends _i61.PageRouteInfo<void> {
  const AppPurchasesRoute({List<_i61.PageRouteInfo>? children})
    : super(AppPurchasesRoute.name, initialChildren: children);

  static const String name = 'AppPurchasesRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i5.AppPurchasesPage();
    },
  );
}

/// generated route for
/// [_i6.DiscoverFocusPage]
class DiscoverFocusRoute extends _i61.PageRouteInfo<void> {
  const DiscoverFocusRoute({List<_i61.PageRouteInfo>? children})
    : super(DiscoverFocusRoute.name, initialChildren: children);

  static const String name = 'DiscoverFocusRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i6.DiscoverFocusPage();
    },
  );
}

/// generated route for
/// [_i7.DiscoverJournalCoverPage]
class DiscoverJournalCoverRoute
    extends _i61.PageRouteInfo<DiscoverJournalCoverRouteArgs> {
  DiscoverJournalCoverRoute({
    required int year,
    String? currentCoverImage,
    _i64.Key? key,
    List<_i61.PageRouteInfo>? children,
  }) : super(
         DiscoverJournalCoverRoute.name,
         args: DiscoverJournalCoverRouteArgs(
           year: year,
           currentCoverImage: currentCoverImage,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'DiscoverJournalCoverRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DiscoverJournalCoverRouteArgs>();
      return _i7.DiscoverJournalCoverPage(
        year: args.year,
        currentCoverImage: args.currentCoverImage,
        key: args.key,
      );
    },
  );
}

class DiscoverJournalCoverRouteArgs {
  const DiscoverJournalCoverRouteArgs({
    required this.year,
    this.currentCoverImage,
    this.key,
  });

  final int year;

  final String? currentCoverImage;

  final _i64.Key? key;

  @override
  String toString() {
    return 'DiscoverJournalCoverRouteArgs{year: $year, currentCoverImage: $currentCoverImage, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DiscoverJournalCoverRouteArgs) return false;
    return year == other.year &&
        currentCoverImage == other.currentCoverImage &&
        key == other.key;
  }

  @override
  int get hashCode => year.hashCode ^ currentCoverImage.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i8.DiscoverJournalPage]
class DiscoverJournalRoute extends _i61.PageRouteInfo<void> {
  const DiscoverJournalRoute({List<_i61.PageRouteInfo>? children})
    : super(DiscoverJournalRoute.name, initialChildren: children);

  static const String name = 'DiscoverJournalRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i8.DiscoverJournalPage();
    },
  );
}

/// generated route for
/// [_i9.DiscoverJournalPlayPage]
class DiscoverJournalPlayRoute extends _i61.PageRouteInfo<void> {
  const DiscoverJournalPlayRoute({List<_i61.PageRouteInfo>? children})
    : super(DiscoverJournalPlayRoute.name, initialChildren: children);

  static const String name = 'DiscoverJournalPlayRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i9.DiscoverJournalPlayPage();
    },
  );
}

/// generated route for
/// [_i10.DiscoverSummaryPage]
class DiscoverSummaryRoute extends _i61.PageRouteInfo<void> {
  const DiscoverSummaryRoute({List<_i61.PageRouteInfo>? children})
    : super(DiscoverSummaryRoute.name, initialChildren: children);

  static const String name = 'DiscoverSummaryRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i10.DiscoverSummaryPage();
    },
  );
}

/// generated route for
/// [_i11.FeedbackPage]
class FeedbackRoute extends _i61.PageRouteInfo<void> {
  const FeedbackRoute({List<_i61.PageRouteInfo>? children})
    : super(FeedbackRoute.name, initialChildren: children);

  static const String name = 'FeedbackRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i11.FeedbackPage();
    },
  );
}

/// generated route for
/// [_i12.JournalDailyPage]
class JournalDailyRoute extends _i61.PageRouteInfo<JournalDailyRouteArgs> {
  JournalDailyRoute({
    required _i65.Jiffy date,
    _i64.Key? key,
    List<_i61.PageRouteInfo>? children,
  }) : super(
         JournalDailyRoute.name,
         args: JournalDailyRouteArgs(date: date, key: key),
         initialChildren: children,
       );

  static const String name = 'JournalDailyRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<JournalDailyRouteArgs>();
      return _i12.JournalDailyPage(date: args.date, key: args.key);
    },
  );
}

class JournalDailyRouteArgs {
  const JournalDailyRouteArgs({required this.date, this.key});

  final _i65.Jiffy date;

  final _i64.Key? key;

  @override
  String toString() {
    return 'JournalDailyRouteArgs{date: $date, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JournalDailyRouteArgs) return false;
    return date == other.date && key == other.key;
  }

  @override
  int get hashCode => date.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i13.JournalExportPage]
class JournalExportRoute extends _i61.PageRouteInfo<void> {
  const JournalExportRoute({List<_i61.PageRouteInfo>? children})
    : super(JournalExportRoute.name, initialChildren: children);

  static const String name = 'JournalExportRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i13.JournalExportPage();
    },
  );
}

/// generated route for
/// [_i14.MineDeletePage]
class MineDeleteRoute extends _i61.PageRouteInfo<void> {
  const MineDeleteRoute({List<_i61.PageRouteInfo>? children})
    : super(MineDeleteRoute.name, initialChildren: children);

  static const String name = 'MineDeleteRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i14.MineDeletePage();
    },
  );
}

/// generated route for
/// [_i15.MineEmailPage]
class MineEmailRoute extends _i61.PageRouteInfo<void> {
  const MineEmailRoute({List<_i61.PageRouteInfo>? children})
    : super(MineEmailRoute.name, initialChildren: children);

  static const String name = 'MineEmailRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i15.MineEmailPage();
    },
  );
}

/// generated route for
/// [_i16.MinePasswordPage]
class MinePasswordRoute extends _i61.PageRouteInfo<void> {
  const MinePasswordRoute({List<_i61.PageRouteInfo>? children})
    : super(MinePasswordRoute.name, initialChildren: children);

  static const String name = 'MinePasswordRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i16.MinePasswordPage();
    },
  );
}

/// generated route for
/// [_i17.MinePhonePage]
class MinePhoneRoute extends _i61.PageRouteInfo<void> {
  const MinePhoneRoute({List<_i61.PageRouteInfo>? children})
    : super(MinePhoneRoute.name, initialChildren: children);

  static const String name = 'MinePhoneRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i17.MinePhonePage();
    },
  );
}

/// generated route for
/// [_i18.MineProfilePage]
class MineProfileRoute extends _i61.PageRouteInfo<void> {
  const MineProfileRoute({List<_i61.PageRouteInfo>? children})
    : super(MineProfileRoute.name, initialChildren: children);

  static const String name = 'MineProfileRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i18.MineProfilePage();
    },
  );
}

/// generated route for
/// [_i19.NoteGalleryPage]
class NoteGalleryRoute extends _i61.PageRouteInfo<void> {
  const NoteGalleryRoute({List<_i61.PageRouteInfo>? children})
    : super(NoteGalleryRoute.name, initialChildren: children);

  static const String name = 'NoteGalleryRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i19.NoteGalleryPage();
    },
  );
}

/// generated route for
/// [_i20.NoteListPage]
class NoteListRoute extends _i61.PageRouteInfo<void> {
  const NoteListRoute({List<_i61.PageRouteInfo>? children})
    : super(NoteListRoute.name, initialChildren: children);

  static const String name = 'NoteListRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i20.NoteListPage();
    },
  );
}

/// generated route for
/// [_i21.NoteNewFullscreenPage]
class NoteNewFullscreenRoute
    extends _i61.PageRouteInfo<NoteNewFullscreenRouteArgs> {
  NoteNewFullscreenRoute({
    _i65.NoteEntity? initialNote,
    _i64.Key? key,
    List<_i61.PageRouteInfo>? children,
  }) : super(
         NoteNewFullscreenRoute.name,
         args: NoteNewFullscreenRouteArgs(initialNote: initialNote, key: key),
         initialChildren: children,
       );

  static const String name = 'NoteNewFullscreenRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteNewFullscreenRouteArgs>(
        orElse: () => const NoteNewFullscreenRouteArgs(),
      );
      return _i21.NoteNewFullscreenPage(
        initialNote: args.initialNote,
        key: args.key,
      );
    },
  );
}

class NoteNewFullscreenRouteArgs {
  const NoteNewFullscreenRouteArgs({this.initialNote, this.key});

  final _i65.NoteEntity? initialNote;

  final _i64.Key? key;

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
/// [_i22.NoteNewPage]
class NoteNewRoute extends _i61.PageRouteInfo<NoteNewRouteArgs> {
  NoteNewRoute({
    _i65.NoteEntity? initialNote,
    _i65.TaskEntity? initialTask,
    _i64.Key? key,
    List<_i61.PageRouteInfo>? children,
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

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteNewRouteArgs>(
        orElse: () => const NoteNewRouteArgs(),
      );
      return _i22.NoteNewPage(
        initialNote: args.initialNote,
        initialTask: args.initialTask,
        key: args.key,
      );
    },
  );
}

class NoteNewRouteArgs {
  const NoteNewRouteArgs({this.initialNote, this.initialTask, this.key});

  final _i65.NoteEntity? initialNote;

  final _i65.TaskEntity? initialTask;

  final _i64.Key? key;

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
/// [_i23.NoteNewTypePage]
class NoteNewTypeRoute extends _i61.PageRouteInfo<NoteNewTypeRouteArgs> {
  NoteNewTypeRoute({
    required _i66.NoteType type,
    required _i67.Jiffy focusAt,
    _i66.Note? initialNote,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
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

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteNewTypeRouteArgs>();
      return _i23.NoteNewTypePage(
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

  final _i66.NoteType type;

  final _i67.Jiffy focusAt;

  final _i66.Note? initialNote;

  final _i63.Key? key;

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
/// [_i24.NoteTagPage]
class NoteTagRoute extends _i61.PageRouteInfo<void> {
  const NoteTagRoute({List<_i61.PageRouteInfo>? children})
    : super(NoteTagRoute.name, initialChildren: children);

  static const String name = 'NoteTagRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i24.NoteTagPage();
    },
  );
}

/// generated route for
/// [_i25.NoteTaskPage]
class NoteTaskRoute extends _i61.PageRouteInfo<void> {
  const NoteTaskRoute({List<_i61.PageRouteInfo>? children})
    : super(NoteTaskRoute.name, initialChildren: children);

  static const String name = 'NoteTaskRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i25.NoteTaskPage();
    },
  );
}

/// generated route for
/// [_i26.NoteTimelinePage]
class NoteTimelineRoute extends _i61.PageRouteInfo<NoteTimelineRouteArgs> {
  NoteTimelineRoute({
    _i64.Key? key,
    _i65.NoteListMode mode = _i65.NoteListMode.all,
    List<_i61.PageRouteInfo>? children,
  }) : super(
         NoteTimelineRoute.name,
         args: NoteTimelineRouteArgs(key: key, mode: mode),
         initialChildren: children,
       );

  static const String name = 'NoteTimelineRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NoteTimelineRouteArgs>(
        orElse: () => const NoteTimelineRouteArgs(),
      );
      return _i26.NoteTimelinePage(key: args.key, mode: args.mode);
    },
  );
}

class NoteTimelineRouteArgs {
  const NoteTimelineRouteArgs({this.key, this.mode = _i65.NoteListMode.all});

  final _i64.Key? key;

  final _i65.NoteListMode mode;

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
/// [_i27.NoteWrittenPage]
class NoteWrittenRoute extends _i61.PageRouteInfo<void> {
  const NoteWrittenRoute({List<_i61.PageRouteInfo>? children})
    : super(NoteWrittenRoute.name, initialChildren: children);

  static const String name = 'NoteWrittenRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i27.NoteWrittenPage();
    },
  );
}

/// generated route for
/// [_i28.RootDiscoverPage]
class RootDiscoverRoute extends _i61.PageRouteInfo<void> {
  const RootDiscoverRoute({List<_i61.PageRouteInfo>? children})
    : super(RootDiscoverRoute.name, initialChildren: children);

  static const String name = 'RootDiscoverRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i28.RootDiscoverPage();
    },
  );
}

/// generated route for
/// [_i29.RootHomePage]
class RootHomeRoute extends _i61.PageRouteInfo<void> {
  const RootHomeRoute({List<_i61.PageRouteInfo>? children})
    : super(RootHomeRoute.name, initialChildren: children);

  static const String name = 'RootHomeRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i29.RootHomePage();
    },
  );
}

/// generated route for
/// [_i30.RootNotePage]
class RootNoteRoute extends _i61.PageRouteInfo<void> {
  const RootNoteRoute({List<_i61.PageRouteInfo>? children})
    : super(RootNoteRoute.name, initialChildren: children);

  static const String name = 'RootNoteRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i30.RootNotePage();
    },
  );
}

/// generated route for
/// [_i31.RootTaskPage]
class RootTaskRoute extends _i61.PageRouteInfo<void> {
  const RootTaskRoute({List<_i61.PageRouteInfo>? children})
    : super(RootTaskRoute.name, initialChildren: children);

  static const String name = 'RootTaskRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i31.RootTaskPage();
    },
  );
}

/// generated route for
/// [_i32.SettingsBackgroundPage]
class SettingsBackgroundRoute extends _i61.PageRouteInfo<void> {
  const SettingsBackgroundRoute({List<_i61.PageRouteInfo>? children})
    : super(SettingsBackgroundRoute.name, initialChildren: children);

  static const String name = 'SettingsBackgroundRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i32.SettingsBackgroundPage();
    },
  );
}

/// generated route for
/// [_i33.SettingsDarkModePage]
class SettingsDarkModeRoute extends _i61.PageRouteInfo<void> {
  const SettingsDarkModeRoute({List<_i61.PageRouteInfo>? children})
    : super(SettingsDarkModeRoute.name, initialChildren: children);

  static const String name = 'SettingsDarkModeRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i33.SettingsDarkModePage();
    },
  );
}

/// generated route for
/// [_i34.SettingsHomePage]
class SettingsHomeRoute extends _i61.PageRouteInfo<void> {
  const SettingsHomeRoute({List<_i61.PageRouteInfo>? children})
    : super(SettingsHomeRoute.name, initialChildren: children);

  static const String name = 'SettingsHomeRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i34.SettingsHomePage();
    },
  );
}

/// generated route for
/// [_i35.SettingsIconPage]
class SettingsIconRoute extends _i61.PageRouteInfo<void> {
  const SettingsIconRoute({List<_i61.PageRouteInfo>? children})
    : super(SettingsIconRoute.name, initialChildren: children);

  static const String name = 'SettingsIconRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i35.SettingsIconPage();
    },
  );
}

/// generated route for
/// [_i36.SettingsSeedColorPage]
class SettingsSeedColorRoute extends _i61.PageRouteInfo<void> {
  const SettingsSeedColorRoute({List<_i61.PageRouteInfo>? children})
    : super(SettingsSeedColorRoute.name, initialChildren: children);

  static const String name = 'SettingsSeedColorRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i36.SettingsSeedColorPage();
    },
  );
}

/// generated route for
/// [_i37.SettingsTaskPage]
class SettingsTaskRoute extends _i61.PageRouteInfo<void> {
  const SettingsTaskRoute({List<_i61.PageRouteInfo>? children})
    : super(SettingsTaskRoute.name, initialChildren: children);

  static const String name = 'SettingsTaskRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i37.SettingsTaskPage();
    },
  );
}

/// generated route for
/// [_i38.SignHomePage]
class SignHomeRoute extends _i61.PageRouteInfo<void> {
  const SignHomeRoute({List<_i61.PageRouteInfo>? children})
    : super(SignHomeRoute.name, initialChildren: children);

  static const String name = 'SignHomeRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i38.SignHomePage();
    },
  );
}

/// generated route for
/// [_i39.SplashPage]
class SplashRoute extends _i61.PageRouteInfo<void> {
  const SplashRoute({List<_i61.PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i39.SplashPage();
    },
  );
}

/// generated route for
/// [_i40.TagListPage]
class TagListRoute extends _i61.PageRouteInfo<TagListRouteArgs> {
  TagListRoute({
    required _i68.TagListMode mode,
    required List<_i65.TagEntity> selectedTags,
    _i64.Key? key,
    List<_i61.PageRouteInfo>? children,
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

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagListRouteArgs>();
      return _i40.TagListPage(
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

  final _i68.TagListMode mode;

  final List<_i65.TagEntity> selectedTags;

  final _i64.Key? key;

  @override
  String toString() {
    return 'TagListRouteArgs{mode: $mode, selectedTags: $selectedTags, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagListRouteArgs) return false;
    return mode == other.mode &&
        const _i69.ListEquality<_i65.TagEntity>().equals(
          selectedTags,
          other.selectedTags,
        ) &&
        key == other.key;
  }

  @override
  int get hashCode =>
      mode.hashCode ^
      const _i69.ListEquality<_i65.TagEntity>().hash(selectedTags) ^
      key.hashCode;
}

/// generated route for
/// [_i41.TagNewPage]
class TagNewRoute extends _i61.PageRouteInfo<TagNewRouteArgs> {
  TagNewRoute({
    _i66.TagEntity? initialTag,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
  }) : super(
         TagNewRoute.name,
         args: TagNewRouteArgs(initialTag: initialTag, key: key),
         initialChildren: children,
       );

  static const String name = 'TagNewRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagNewRouteArgs>(
        orElse: () => const TagNewRouteArgs(),
      );
      return _i41.TagNewPage(initialTag: args.initialTag, key: args.key);
    },
  );
}

class TagNewRouteArgs {
  const TagNewRouteArgs({this.initialTag, this.key});

  final _i66.TagEntity? initialTag;

  final _i63.Key? key;

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
/// [_i42.TagPickerPage]
class TagPickerRoute extends _i61.PageRouteInfo<TagPickerRouteArgs> {
  TagPickerRoute({
    required List<_i70.TagEntity> selectedTags,
    required _i63.ValueChanged<List<_i70.TagEntity>> onSelected,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
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

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TagPickerRouteArgs>();
      return _i42.TagPickerPage(
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

  final List<_i70.TagEntity> selectedTags;

  final _i63.ValueChanged<List<_i70.TagEntity>> onSelected;

  final _i63.Key? key;

  @override
  String toString() {
    return 'TagPickerRouteArgs{selectedTags: $selectedTags, onSelected: $onSelected, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagPickerRouteArgs) return false;
    return const _i69.ListEquality<_i70.TagEntity>().equals(
          selectedTags,
          other.selectedTags,
        ) &&
        onSelected == other.onSelected &&
        key == other.key;
  }

  @override
  int get hashCode =>
      const _i69.ListEquality<_i70.TagEntity>().hash(selectedTags) ^
      onSelected.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i43.TaskAlarmPage]
class TaskAlarmRoute extends _i61.PageRouteInfo<TaskAlarmRouteArgs> {
  TaskAlarmRoute({
    required _i65.Jiffy taskStartAt,
    List<_i65.EventAlarm>? initialAlarms,
    bool isAllDay = false,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
  }) : super(
         TaskAlarmRoute.name,
         args: TaskAlarmRouteArgs(
           taskStartAt: taskStartAt,
           initialAlarms: initialAlarms,
           isAllDay: isAllDay,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'TaskAlarmRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskAlarmRouteArgs>();
      return _i43.TaskAlarmPage(
        taskStartAt: args.taskStartAt,
        initialAlarms: args.initialAlarms,
        isAllDay: args.isAllDay,
        key: args.key,
      );
    },
  );
}

class TaskAlarmRouteArgs {
  const TaskAlarmRouteArgs({
    required this.taskStartAt,
    this.initialAlarms,
    this.isAllDay = false,
    this.key,
  });

  final _i65.Jiffy taskStartAt;

  final List<_i65.EventAlarm>? initialAlarms;

  final bool isAllDay;

  final _i63.Key? key;

  @override
  String toString() {
    return 'TaskAlarmRouteArgs{taskStartAt: $taskStartAt, initialAlarms: $initialAlarms, isAllDay: $isAllDay, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskAlarmRouteArgs) return false;
    return taskStartAt == other.taskStartAt &&
        const _i69.ListEquality<_i65.EventAlarm>().equals(
          initialAlarms,
          other.initialAlarms,
        ) &&
        isAllDay == other.isAllDay &&
        key == other.key;
  }

  @override
  int get hashCode =>
      taskStartAt.hashCode ^
      const _i69.ListEquality<_i65.EventAlarm>().hash(initialAlarms) ^
      isAllDay.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i44.TaskDatePickerPage]
class TaskDatePickerRoute extends _i61.PageRouteInfo<TaskDatePickerRouteArgs> {
  TaskDatePickerRoute({
    required _i65.Jiffy date,
    _i63.ValueChanged<_i65.Jiffy?>? onDateChanged,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
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

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDatePickerRouteArgs>();
      return _i44.TaskDatePickerPage(
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

  final _i65.Jiffy date;

  final _i63.ValueChanged<_i65.Jiffy?>? onDateChanged;

  final _i63.Key? key;

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
/// [_i45.TaskDetailPage]
class TaskDetailRoute extends _i61.PageRouteInfo<TaskDetailRouteArgs> {
  TaskDetailRoute({
    required String taskId,
    _i65.Jiffy? occurrenceAt,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
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

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDetailRouteArgs>();
      return _i45.TaskDetailPage(
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

  final _i65.Jiffy? occurrenceAt;

  final _i63.Key? key;

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
/// [_i46.TaskDonePage]
class TaskDoneRoute extends _i61.PageRouteInfo<TaskDoneRouteArgs> {
  TaskDoneRoute({
    required _i71.TaskEntity task,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
  }) : super(
         TaskDoneRoute.name,
         args: TaskDoneRouteArgs(task: task, key: key),
         initialChildren: children,
       );

  static const String name = 'TaskDoneRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDoneRouteArgs>();
      return _i46.TaskDonePage(task: args.task, key: args.key);
    },
  );
}

class TaskDoneRouteArgs {
  const TaskDoneRouteArgs({required this.task, this.key});

  final _i71.TaskEntity task;

  final _i63.Key? key;

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
/// [_i47.TaskDurationPage]
class TaskDurationRoute extends _i61.PageRouteInfo<TaskDurationRouteArgs> {
  TaskDurationRoute({
    _i67.Jiffy? startAt,
    _i67.Jiffy? endAt,
    bool isAllDay = true,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
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

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDurationRouteArgs>(
        orElse: () => const TaskDurationRouteArgs(),
      );
      return _i47.TaskDurationPage(
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

  final _i67.Jiffy? startAt;

  final _i67.Jiffy? endAt;

  final bool isAllDay;

  final _i63.Key? key;

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
/// [_i48.TaskInboxPage]
class TaskInboxRoute extends _i61.PageRouteInfo<void> {
  const TaskInboxRoute({List<_i61.PageRouteInfo>? children})
    : super(TaskInboxRoute.name, initialChildren: children);

  static const String name = 'TaskInboxRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i48.TaskInboxPage();
    },
  );
}

/// generated route for
/// [_i49.TaskListPage]
class TaskListRoute extends _i61.PageRouteInfo<void> {
  const TaskListRoute({List<_i61.PageRouteInfo>? children})
    : super(TaskListRoute.name, initialChildren: children);

  static const String name = 'TaskListRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i49.TaskListPage();
    },
  );
}

/// generated route for
/// [_i50.TaskMonthPage]
class TaskMonthRoute extends _i61.PageRouteInfo<void> {
  const TaskMonthRoute({List<_i61.PageRouteInfo>? children})
    : super(TaskMonthRoute.name, initialChildren: children);

  static const String name = 'TaskMonthRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i50.TaskMonthPage();
    },
  );
}

/// generated route for
/// [_i51.TaskNewChildPage]
class TaskNewChildRoute extends _i61.PageRouteInfo<TaskNewChildRouteArgs> {
  TaskNewChildRoute({
    required List<_i66.TaskEntity> subTasks,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
  }) : super(
         TaskNewChildRoute.name,
         args: TaskNewChildRouteArgs(subTasks: subTasks, key: key),
         initialChildren: children,
       );

  static const String name = 'TaskNewChildRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskNewChildRouteArgs>();
      return _i51.TaskNewChildPage(subTasks: args.subTasks, key: args.key);
    },
  );
}

class TaskNewChildRouteArgs {
  const TaskNewChildRouteArgs({required this.subTasks, this.key});

  final List<_i66.TaskEntity> subTasks;

  final _i63.Key? key;

  @override
  String toString() {
    return 'TaskNewChildRouteArgs{subTasks: $subTasks, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskNewChildRouteArgs) return false;
    return const _i69.ListEquality<_i66.TaskEntity>().equals(
          subTasks,
          other.subTasks,
        ) &&
        key == other.key;
  }

  @override
  int get hashCode =>
      const _i69.ListEquality<_i66.TaskEntity>().hash(subTasks) ^ key.hashCode;
}

/// generated route for
/// [_i52.TaskNewPage]
class TaskNewRoute extends _i61.PageRouteInfo<TaskNewRouteArgs> {
  TaskNewRoute({
    _i65.TaskEntity? initialTask,
    _i65.Jiffy? dueAt,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
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

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskNewRouteArgs>(
        orElse: () => const TaskNewRouteArgs(),
      );
      return _i52.TaskNewPage(
        initialTask: args.initialTask,
        dueAt: args.dueAt,
        key: args.key,
      );
    },
  );
}

class TaskNewRouteArgs {
  const TaskNewRouteArgs({this.initialTask, this.dueAt, this.key});

  final _i65.TaskEntity? initialTask;

  final _i65.Jiffy? dueAt;

  final _i63.Key? key;

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
/// [_i53.TaskNewRecurrenceEndAtPage]
class TaskNewRecurrenceEndAtRoute
    extends _i61.PageRouteInfo<TaskNewRecurrenceEndAtRouteArgs> {
  TaskNewRecurrenceEndAtRoute({
    required _i67.Jiffy? minimumDateTime,
    required _i72.RecurrenceEnd? initialRecurrenceEnd,
    required _i63.ValueChanged<_i72.RecurrenceEnd?> onRecurrenceEndChanged,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
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

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskNewRecurrenceEndAtRouteArgs>();
      return _i53.TaskNewRecurrenceEndAtPage(
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

  final _i67.Jiffy? minimumDateTime;

  final _i72.RecurrenceEnd? initialRecurrenceEnd;

  final _i63.ValueChanged<_i72.RecurrenceEnd?> onRecurrenceEndChanged;

  final _i63.Key? key;

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
/// [_i54.TaskOverduePage]
class TaskOverdueRoute extends _i61.PageRouteInfo<void> {
  const TaskOverdueRoute({List<_i61.PageRouteInfo>? children})
    : super(TaskOverdueRoute.name, initialChildren: children);

  static const String name = 'TaskOverdueRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i54.TaskOverduePage();
    },
  );
}

/// generated route for
/// [_i55.TaskPickerPage]
class TaskPickerRoute extends _i61.PageRouteInfo<void> {
  const TaskPickerRoute({List<_i61.PageRouteInfo>? children})
    : super(TaskPickerRoute.name, initialChildren: children);

  static const String name = 'TaskPickerRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i55.TaskPickerPage();
    },
  );
}

/// generated route for
/// [_i56.TaskPriorityPickerPage]
class TaskPriorityPickerRoute
    extends _i61.PageRouteInfo<TaskPriorityPickerRouteArgs> {
  TaskPriorityPickerRoute({
    required _i73.TaskPriority selectedPriority,
    _i63.ValueChanged<_i73.TaskPriority>? onSelected,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
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

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskPriorityPickerRouteArgs>();
      return _i56.TaskPriorityPickerPage(
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

  final _i73.TaskPriority selectedPriority;

  final _i63.ValueChanged<_i73.TaskPriority>? onSelected;

  final _i63.Key? key;

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
/// [_i57.TaskRecurrencePage]
class TaskRecurrenceRoute extends _i61.PageRouteInfo<TaskRecurrenceRouteArgs> {
  TaskRecurrenceRoute({
    _i67.Jiffy? taskDate,
    _i72.RecurrenceRule? initialRecurrenceRule,
    _i63.Key? key,
    List<_i61.PageRouteInfo>? children,
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

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskRecurrenceRouteArgs>(
        orElse: () => const TaskRecurrenceRouteArgs(),
      );
      return _i57.TaskRecurrencePage(
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

  final _i67.Jiffy? taskDate;

  final _i72.RecurrenceRule? initialRecurrenceRule;

  final _i63.Key? key;

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
/// [_i58.TaskTagPage]
class TaskTagRoute extends _i61.PageRouteInfo<void> {
  const TaskTagRoute({List<_i61.PageRouteInfo>? children})
    : super(TaskTagRoute.name, initialChildren: children);

  static const String name = 'TaskTagRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i58.TaskTagPage();
    },
  );
}

/// generated route for
/// [_i59.TaskTodayPage]
class TaskTodayRoute extends _i61.PageRouteInfo<void> {
  const TaskTodayRoute({List<_i61.PageRouteInfo>? children})
    : super(TaskTodayRoute.name, initialChildren: children);

  static const String name = 'TaskTodayRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i59.TaskTodayPage();
    },
  );
}

/// generated route for
/// [_i60.TaskWeekPage]
class TaskWeekRoute extends _i61.PageRouteInfo<void> {
  const TaskWeekRoute({List<_i61.PageRouteInfo>? children})
    : super(TaskWeekRoute.name, initialChildren: children);

  static const String name = 'TaskWeekRoute';

  static _i61.PageInfo page = _i61.PageInfo(
    name,
    builder: (data) {
      return const _i60.TaskWeekPage();
    },
  );
}
