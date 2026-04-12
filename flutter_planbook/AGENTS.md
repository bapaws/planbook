# Planbook - AI Agent Guide

> **Project Language**: The codebase uses Chinese for comments and documentation.
> **Last Updated**: 2026-04-11

## Project Overview

**Planbook** is a comprehensive task management and note-taking Flutter application. It's a "Plan, Task, Note, All in One" productivity app that helps users manage tasks, write notes, and track their daily/weekly/monthly focus and summaries.

- **Version**: 2.6.2+105
- **Flutter SDK**: ^3.8.1
- **Created with**: Very Good CLI

### Key Features
- Task management with Eisenhower Matrix priority (Important/Urgent quadrants)
- Note-taking with rich text and image support
- Hierarchical tags (parent/child relationships)
- Recurring tasks with customizable rules
- Daily/weekly/monthly focus and summary tracking
- In-app purchases (RevenueCat integration)
- Multi-language support (English, Simplified Chinese, Traditional Chinese)
- Customizable themes and app icons
- Android home screen widgets

## Technology Stack

### Core Framework
- **Flutter** ^3.8.1 - UI framework
- **Dart** ^3.8.0 - Programming language

### State Management
- **flutter_bloc** ^9.1.1 - BLoC pattern for state management
- **hydrated_bloc** ^10.1.1 - Persistent state management
- **bloc_concurrency** ^0.3.0 - Event transformation support

### Database & Storage
- **drift** ^2.26.1 - SQLite ORM
- **sqlite3** ^2.7.7 - SQLite bindings
- **supabase_flutter** ^2.9.1 - Backend as a Service
- **shared_preferences** ^2.3.2 - Local key-value storage

### Architecture Pattern
The project follows **Clean Architecture** with a layered package structure:

```
┌─────────────────────────────────────┐
│         flutter_planbook            │  <- UI Layer (Flutter App)
│    (329 Dart files in lib/)         │
├─────────────────────────────────────┤
│      planbook_repository            │  <- Repository Layer
│  (Business logic, data aggregation) │
├─────────────────────────────────────┤
│   database_planbook_api             │  <- Data Layer (Local DB)
│      supabase_planbook_api          │  <- Data Layer (Remote)
├─────────────────────────────────────┤
│         planbook_api                │  <- API Layer
│    (Entities, database schema)      │
├─────────────────────────────────────┤
│         planbook_core               │  <- Core Layer
│  (Common utilities, widgets)        │
└─────────────────────────────────────┘
```

## Project Structure

### Main App (`lib/`)

```
lib/
├── app/                    # App-level configuration
│   ├── activity/           # User activity tracking
│   ├── app_router.dart     # AutoRoute configuration
│   ├── app_router.gr.dart  # Generated routes
│   ├── bloc/               # App-level BLoC (theme, user, etc.)
│   ├── launch/             # Splash/launch screen
│   ├── purchases/          # In-app purchase logic
│   └── view/               # Shared app views
├── core/                   # Core business logic
│   ├── apk_download_service.dart
│   ├── model/              # Extension models
│   ├── purchases/          # Purchase implementations
│   └── view/               # Shared widgets
├── discover/               # Discovery/Journal feature
│   ├── daily/              # Daily journal view
│   ├── focus/              # Focus mind map
│   ├── journal/            # Journal browser
│   ├── play/               # Journal playback
│   └── summary/            # Summary view
├── l10n/                   # Localization
│   ├── arb/                # ARB translation files
│   │   ├── app_en.arb      # English (template)
│   │   ├── app_zh.arb      # Chinese
│   │   ├── app_zh_Hans.arb # Simplified Chinese
│   │   └── app_zh_Hant.arb # Traditional Chinese
│   └── gen/                # Generated localization code
├── mine/                   # User profile settings
├── note/                   # Note feature
│   ├── gallery/            # Note gallery view
│   ├── list/               # Note list
│   ├── new/                # Create/edit note
│   ├── tag/                # Note tags
│   ├── timeline/           # Note timeline
│   └── type/               # Note types (focus/summary)
├── root/                   # Root navigation tabs
│   ├── discover/           # Discover tab
│   ├── home/               # Home container
│   ├── note/               # Note tab
│   └── task/               # Task tab
├── settings/               # App settings
│   ├── about/              # About page
│   ├── background/         # Background customization
│   ├── color/              # Theme color
│   ├── dark/               # Dark mode
│   ├── feedback/           # Feedback
│   ├── home/               # Settings home
│   ├── icon/               # App icon
│   └── task/               # Task settings
├── sign/                   # Authentication
│   ├── home/               # Sign-in home
│   ├── in/                 # Sign-in
│   ├── password/           # Password reset
│   ├── up/                 # Sign-up
│   └── welcome/            # Welcome page
├── tag/                    # Tag management
│   ├── list/               # Tag list
│   ├── new/                # Create tag
│   └── picker/             # Tag picker
└── task/                   # Task feature
    ├── alarm/              # Task alarms
    ├── child/              # Subtasks
    ├── detail/             # Task detail
    ├── done/               # Task completion
    ├── duration/           # Duration picker
    ├── inbox/              # Inbox view
    ├── list/               # Task list
    ├── month/              # Month view
    ├── new/                # Create/edit task
    ├── overdue/            # Overdue tasks
    ├── picker/             # Task pickers
    ├── priority/           # Priority view
    ├── recurrence/         # Recurrence rules
    ├── tag/                # Task tags
    ├── today/              # Today's tasks
    └── week/               # Week view
```

### Local Packages (`packages/`)

| Package | Files | Purpose |
|---------|-------|---------|
| `planbook_api` | ~20 | Entity definitions, database schema, Supabase config |
| `database_planbook_api` | ~10 | Drift/SQLite database operations |
| `supabase_planbook_api` | ~10 | Supabase remote API operations |
| `planbook_repository` | ~15 | Repository pattern, business logic |
| `planbook_core` | ~20 | Shared widgets, utilities, constants |
| `home_widget` | ~15 | Android home screen widget implementation |

## Database Schema

The app uses **Drift (SQLite)** for local storage with the following tables:

### Tasks Table
- Task management with hierarchical support (parent/child)
- Time tracking (startAt, endAt, dueAt)
- Recurring task support with recurrence rules
- Instance detachment (Apple Calendar-style)
- Priority levels (Eisenhower Matrix)
- Alarm/reminder support

### Notes Table
- Rich text notes with image support
- Task association (taskId foreign key)
- Note types: daily focus, daily summary, weekly focus, etc.
- Focus date tracking

### Tags Table
- Hierarchical tags (parent-child relationships)
- Color customization per tag
- Theme-aware color schemes

### TaskActivities Table
- Tracks task completions, timing sessions
- Activity types: completed, skipped, modified
- Duration tracking for focus sessions

### TaskOccurrences Table
- Pre-generated recurring task instances
- Optimized for date-range queries

## State Management (BLoC Pattern)

### 文件结构

每个 BLoC 遵循标准的三文件结构（使用 `part`/`part of` 组织）：

```
{feature}/
├── bloc/
│   ├── {feature}_bloc.dart   # 业务逻辑 (主文件)
│   ├── {feature}_event.dart  # 事件定义 (part 文件)
│   └── {feature}_state.dart  # 状态定义 (part 文件)
```

### 核心规范

#### 1. `emit.forEach` 的使用场景

**`emit.forEach` 专门用于监听 Repository 返回的 Stream**，实现数据的实时响应：

```dart
// ✅ 正确用法：监听 Repository 的数据流
await emit.forEach(
  _tasksRepository.getTaskEntities(mode: _mode, date: date),
  onData: (tasks) => state.copyWith(
    status: PageStatus.success,
    tasks: tasks,
  ),
);
```

**必须使用 `emit.forEach` 的场景：**
| 场景 | Repository 方法示例 |
|------|-------------------|
| 监听任务列表变化 | `getTaskEntities()`, `getAllTodayTaskEntities()` |
| 监听笔记列表变化 | `getNoteEntitiesByDate()`, `getNoteEntitiesByTaskId()` |
| 监听标签列表变化 | `getTopLevelTags()`, `getAllTags()` |
| 监听用户状态变化 | `onUserEntityChange`, `onAuthStateChange` |
| 监听设置变化 | `onBackgroundAssetChange`, `onTaskPriorityStyleChange` |
| 监听单条数据变化 | `getNoteByFocusAt()` |

#### 2. 不使用 `emit.forEach` 的场景

**一次性操作**使用普通的 `emit`：

```dart
// ✅ 一次性查询
final task = await _tasksRepository.getTaskEntityById(_taskId);
emit(state.copyWith(status: PageStatus.success, task: task));

// ✅ 删除/更新操作
await _tasksRepository.deleteTaskById(taskId);
emit(state.copyWith(status: PageStatus.success));

// ✅ 设置更新
await _settingsRepository.saveDarkMode(event.darkMode);
emit(state.copyWith(darkMode: () => event.darkMode));
```

#### 3. State 设计规范

State 必须继承 `Equatable`，使用 `final` 字段，并提供 `copyWith` 方法：

```dart
final class TaskTodayState extends Equatable {
  const TaskTodayState({
    required this.date,
    this.calendarFormat = CalendarFormat.week,
    this.taskCounts = const {},
  });

  final Jiffy date;
  final CalendarFormat calendarFormat;
  final Map<int, int> taskCounts;

  @override
  List<Object?> get props => [date, calendarFormat, taskCounts];

  TaskTodayState copyWith({
    Jiffy? date,
    CalendarFormat? calendarFormat,
    Map<int, int>? taskCounts,
    ValueGetter<Note?>? focusNote,  // 可为 null 的字段使用 ValueGetter
  }) {
    return TaskTodayState(
      date: date ?? this.date,
      calendarFormat: calendarFormat ?? this.calendarFormat,
      taskCounts: taskCounts ?? this.taskCounts,
      focusNote: focusNote != null ? focusNote() : this.focusNote,
    );
  }
}
```

#### 4. 并发控制（Event Transformer）

使用 `bloc_concurrency` 进行事件流控制：

```dart
TaskListBloc(...) : super(const TaskListState()) {
  on<TaskListRequested>(_onRequested, transformer: restartable());
  on<TaskListNoteCreated>(_onNoteCreated, transformer: sequential());
}
```

| Transformer | 用途 | 适用场景 |
|------------|------|---------|
| `restartable()` | 新事件到来时取消之前正在进行的事件 | 数据请求、搜索 |
| `sequential()` | 按顺序执行事件 | 依赖操作、创建笔记 |
| `droppable()` | 忽略新事件，如果前一个还在执行 | 防重复提交 |

#### 5. 事件处理 Handler 模板

```dart
Future<void> _onEventName(
  EventType event,
  Emitter<StateType> emit,
) async {
  // 1. 加载状态（可选）
  emit(state.copyWith(status: PageStatus.loading));
  
  // 2. 监听流数据（持续更新）
  await emit.forEach(
    repository.getStreamData(),
    onData: (data) => state.copyWith(
      status: PageStatus.success,
      data: data,
    ),
  );
  
  // 3. 或者执行一次性操作
  final result = await repository.fetchData();
  emit(state.copyWith(status: PageStatus.success, data: result));
}
```

#### 6. 特殊模式：手动管理 StreamSubscription

当需要在 BLoC 外部监听流并在内部触发事件时，手动管理订阅：

```dart
class AppBloc extends Bloc<AppEvent, AppState> {
  StreamSubscription<double>? _apkProgressSub;
  
  @override
  Future<void> close() async {
    unawaited(_apkProgressSub?.cancel());
    await super.close();
  }
  
  void _onDownloadRequested(...) {
    _apkProgressSub = ApkDownloadService.progressStream.listen((p) {
      add(AppApkDownloadProgressUpdated(p));  // 通过事件触发状态更新
    });
  }
}
```

### Key BLoCs

- `AppBloc` - Global app state (theme, user, background)
- `AppPurchasesBloc` - In-app purchase state
- `TaskTodayBloc`, `TaskWeekBloc`, `TaskMonthBloc` - Task views
- `NoteListBloc`, `NoteTimelineBloc` - Note views
- `TagListBloc`, `TagPickerBloc` - Tag management

## Navigation

Uses **AutoRoute** for declarative routing:
- Route definitions in `lib/app/app_router.dart`
- Generated code in `lib/app/app_router.gr.dart`
- Authentication guard redirects unauthenticated users to sign-in
- Modal bottom sheets for task/note creation

## Localization

- Template: `lib/l10n/arb/app_en.arb` (English)
- Translations: Chinese (Simplified/Traditional)
- Code generation: `flutter gen-l10n`
- Output: `lib/l10n/gen/`
- Extension for BuildContext: `context.l10n`

## Build Configuration

### Multiple Entry Points

The app has different entry points for different distribution channels:

| Entry Point | Channel | Purpose |
|-------------|---------|---------|
| `lib/main.dart` | main | Development/General release |
| `lib/main_store.dart` | store | Google Play Store (international) |
| `lib/main_cloud.dart` | cloud | Self-distribution (China market) |

### Flavors

Android flavors configured in build.gradle:
- `main` - Default flavor
- `store` - Google Play Store
- `cloud` - Self-distribution (Tencent Cloud Storage)

### Build Commands

```bash
# iOS App Store
flutter build ipa --target lib/main.dart

# Google Play Store (AAB)
flutter build appbundle --target lib/main.dart --flavor store

# China app stores (Xiaomi, VIVO) - APK
flutter build apk --flavor store --target lib/main_store.dart

# Self-distribution - APK
flutter build apk --flavor cloud --target lib/main_cloud.dart
```

## Code Style Guidelines

### Analysis Configuration
- Base: `package:very_good_analysis/analysis_options.yaml`
- Custom exclusions: `lib/l10n/gen/*`
- Disabled rule: `no_default_cases` (set to ignore)
- Disabled rule: `public_member_api_docs`

### Naming Conventions
- **Files**: snake_case (e.g., `task_detail_bloc.dart`)
- **Classes**: PascalCase (e.g., `TaskDetailBloc`)
- **Variables**: camelCase (e.g., `taskRepository`)
- **Constants**: k-prefixed camelCase (e.g., `kAppGroupId`)

### Comments
- Use Chinese for all code comments
- Document complex business logic
- Link to relevant GitHub issues for workarounds

## Testing

### Test Dependencies
- **bloc_test** ^10.0.0 - BLoC testing utilities
- **mocktail** ^1.0.4 - Mocking library

### No Test Files Currently
The project currently has no test files. When adding tests:
- Place in `test/` directory at project root
- Follow `*_test.dart` naming convention
- Use `very_good_analysis` for linting tests

## Key Dependencies

### UI/UX
- **auto_route** ^10.1.0+1 - Navigation
- **flutter_slidable** ^4.0.3 - Swipe actions
- **flutter_staggered_grid_view** ^0.7.0 - Grid layouts
- **flutter_animate** ^4.5.2 - Animations
- **animate_do** ^4.2.0 - Animation presets
- **table_calendar** ^3.2.0 - Calendar widget
- **fl_chart** ^1.1.1 - Charts
- **flex_color_picker** ^3.7.2 - Color picker

### Media & Files
- **image_picker** ^1.1.2 - Camera/gallery
- **image_cropper** ^11.0.0 - Image cropping
- **audioplayers** ^6.5.1 - Audio playback
- **cached_network_image** ^3.4.1 - Image caching
- **photo_view** ^0.15.0 - Image viewer
- **background_downloader** ^9.5.3 - File downloads

### Platform Integration
- **in_app_purchase** ^3.2.3 - IAP (Google/Apple)
- **purchases_flutter** 9.9.9 - RevenueCat
- **in_app_review** ^2.0.10 - App store reviews
- **app_settings** ^7.0.0 - Open system settings
- **flutter_dynamic_icon_plus** ^1.3.1 - Dynamic app icons
- **share_plus** ^12.0.1 - Content sharing
- **url_launcher** ^6.3.2 - Open URLs

### Backend & Sync
- **supabase_flutter** ^2.9.1 - Backend
- **google_sign_in** ^7.2.0 - Google auth
- **sign_in_with_apple** ^7.0.1 - Apple auth
- **http** ^1.6.0 - HTTP requests

### Date/Time
- **jiffy** ^6.3.1 - Date manipulation
- **intl** ^0.20.2 - Internationalization
- **calendar_date_picker2** ^2.0.1 - Date picker
- **flutter_timezone** ^4.0.0 - Timezone support

## Security Considerations

1. **API Keys**: RevenueCat API keys are embedded in source code
   - Android: `goog_jlxqPffDOplzoFISIizzxwRdFFk`
   - iOS: `appl_aNYCwAWkYYxFFPdqMBTWIXzIzko`
   - Proxy URL: `https://api.rc-backup.com/`

2. **Supabase**: Credentials managed via `AppSupabase` class

3. **Database**: SQLite with WAL mode, stored in app documents
   - iOS: Uses App Group container (`group.GM4766U38W.com.bapaws.planbook`)
   - Android: Standard app documents directory

4. **URL Scheme**: `planbook.bapaws` (for deep linking)

## Platform-Specific Notes

### iOS
- Bundle ID: Configured for App Store distribution
- App Group: `group.GM4766U38W.com.bapaws.planbook`
- URL Schemes: `planbook`, `planbook.bapaws`
- Google Sign-In: Configured with OAuth client ID
- Orientation: Portrait only (iPhone), all orientations (iPad)

### Android
- Package: Follows flavor-specific configuration
- Min SDK: 21
- Permissions: Camera, microphone, storage (for older Android)
- Edge-to-edge display enabled

### Known Issues & Workarounds

1. **iPadOS 26 Bug**: Drawer/Dialog/BottomSheet closes immediately after opening
   - Workaround: `FilteringFlutterBinding` class in `main.dart`
   - Filters out pointer events at position (0, 0)

2. **Native Splash**: Disabled for Android 12+ due to branding size requirements
   - Commented out in `pubspec.yaml`

## Development Workflow

### Code Generation
```bash
# Generate routes (after modifying app_router.dart)
flutter pub run build_runner build --delete-conflicting-outputs

# Generate localization
flutter gen-l10n

# Generate Drift database code (in planbook_api package)
cd packages/planbook_api && flutter pub run build_runner build
```

### Adding a New Feature
1. Create feature directory under appropriate category (task/, note/, etc.)
2. Create BLoC files: `{feature}_bloc.dart`, `{feature}_event.dart`, `{feature}_state.dart`
3. Create view files: `{feature}_page.dart`, `{feature}_view.dart`
4. Add route to `lib/app/app_router.dart`
5. Run code generation
6. Add translations to ARB files if needed

### Adding a New Package
1. Add dependency to `pubspec.yaml`
2. If it's a local package in `packages/`, update the path dependency
3. Run `flutter pub get`
4. Export in appropriate `lib/{package}.dart` file

## Contributing Guidelines

1. Follow the existing code structure and naming conventions
2. Use Chinese for comments
3. Update ARB files when adding user-facing strings
4. Test on both iOS and Android when possible
5. Follow Very Good Analysis lint rules
