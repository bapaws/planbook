# Planbook - AI Agent Documentation

## Project Overview

**Planbook** is a cross-platform task management and note-taking Flutter application. It helps users manage tasks, plans, and notes in a unified interface with features like task prioritization (Eisenhower Matrix), recurring tasks, note-taking with daily focus/summary, and journaling capabilities.

- **App Name**: Planbook (计划本 in Chinese)
- **Version**: 2.6.1+104
- **Package Name**: `com.bapaws.planbook`
- **Primary Language**: Dart
- **Target Platforms**: iOS, Android
- **Architecture**: Clean Architecture with BLoC pattern

## Technology Stack

### Core Framework
- **Flutter**: ^3.8.1 (SDK)
- **Dart**: ^3.8.0

### State Management
- **flutter_bloc**: ^9.1.1 - BLoC pattern for state management
- **hydrated_bloc**: ^10.1.1 - Persistent BLoC state
- **bloc_concurrency**: ^0.3.0 - BLoC event concurrency

### Navigation
- **auto_route**: ^10.1.0+1 - Declarative routing with code generation

### Database & Storage
- **drift**: ^2.26.1 - SQLite ORM for Dart
- **sqlite3**: ^2.7.7 - SQLite bindings
- **supabase_flutter**: ^2.9.1 - Supabase backend integration
- **shared_preferences**: ^2.3.2 - Local key-value storage

### Dependency Injection & Service Location
- Repository pattern with `MultiRepositoryProvider` from flutter_bloc

### Key Dependencies
- **intl**: ^0.20.2 - Internationalization
- **jiffy**: ^6.3.1 - Date/time manipulation
- **equatable**: ^2.0.7 - Value equality
- **rxdart**: ^0.28.0 - Reactive programming

### UI Components
- **flutter_slidable**: ^4.0.3 - Slidable list items
- **flutter_staggered_grid_view**: ^0.7.0 - Grid layouts
- **table_calendar**: ^3.2.0 - Calendar widget
- **fl_chart**: ^1.1.1 - Charts
- **flutter_markdown**: ^0.7.7+1 - Markdown rendering
- **flutter_animate**: ^4.5.2 - Animations

### In-App Purchases
- **purchases_flutter**: 9.9.9 - RevenueCat for subscriptions
- **in_app_purchase**: ^3.2.3 - Native IAP
- **tobias**: ^5.3.2 - Alipay integration (China)

## Project Structure

### Monorepo Organization
The project uses a monorepo structure with local packages:

```
flutter_planbook/
├── lib/                          # Main application code
│   ├── app/                      # App-level configuration
│   │   ├── bloc/                 # App-wide BLoC (theme, auth)
│   │   ├── view/                 # App root widget
│   │   └── app_router.dart       # AutoRoute configuration
│   ├── core/                     # Core utilities and shared widgets
│   ├── root/                     # Root navigation tabs
│   │   ├── home/                 # Main tab container
│   │   ├── task/                 # Task tab
│   │   ├── discover/             # Discover/Journal tab
│   │   └── note/                 # Note tab
│   ├── task/                     # Task feature module
│   ├── note/                     # Note feature module
│   ├── tag/                      # Tag feature module
│   ├── settings/                 # Settings feature module
│   ├── sign/                     # Authentication module
│   ├── mine/                     # User profile module
│   ├── discover/                 # Journal/Discover feature module
│   └── l10n/                     # Localization
├── packages/                     # Local packages
│   ├── planbook_core/            # Core utilities, styles, extensions
│   ├── planbook_api/             # Data models and database entities
│   ├── planbook_repository/      # Repository layer
│   ├── database_planbook_api/    # Local database API implementation
│   ├── supabase_planbook_api/    # Supabase API implementation
│   └── home_widget/              # Home screen widget support
├── android/                      # Android platform code
├── ios/                          # iOS platform code
└── assets/                       # Static assets
    ├── images/
    ├── google_fonts/
    ├── audios/
    ├── tiles/
    └── files/
```

### Package Architecture

#### planbook_core
Core utilities shared across packages:
- `AppStyles` - Theme and styling
- `AppHomeWidget` - Widget home screen integration
- `DarkMode` - Dark mode enums and utilities
- Extensions for DateTime, formatting, colors

#### planbook_api
Data layer definitions:
- **Entities**: `TaskEntity`, `NoteEntity`, `TagEntity`, `UserEntity`
- **Database**: Drift database definitions, converters
- **Settings**: App settings entities
- **Supabase**: Supabase client configuration (`AppSupabase`)

#### planbook_repository
Repository pattern implementation:
- `TasksRepository` - Task CRUD operations
- `NotesRepository` - Note CRUD operations
- `TagsRepository` - Tag management
- `UsersRepository` - User authentication and profile
- `SettingsRepository` - App settings persistence
- `AssetsRepository` - File/asset management
- `AlarmNotificationService` - Local notifications

#### database_planbook_api
Local SQLite implementation using Drift for offline-first data storage.

#### supabase_planbook_api
Remote API implementation using Supabase for cloud synchronization.

## Build System

### Entry Points
The app has three flavor-specific entry points:

1. **main.dart** - Standard build (`AppChannelType.main`)
2. **main_store.dart** - Store distribution (`AppChannelType.store`)
3. **main_cloud.dart** - Self-distribution via cloud (`AppChannelType.cloud`)

### Build Commands

```bash
# iOS App Store build
flutter build ipa --target lib/main.dart

# Google Play (App Bundle)
flutter build appbundle --target lib/main.dart --flavor store

# Chinese app stores (Xiaomi, VIVO, etc.) - APK
flutter build apk --flavor store --target lib/main_store.dart

# Self-distribution (Tencent Cloud)
flutter build apk --flavor cloud --target lib/main_cloud.dart
```

### Android Flavors
- **store**: For Google Play and Chinese app stores (REQUEST_INSTALL_PACKAGES removed)
- **cloud**: For self-distribution with auto-update capability

### iOS Configuration
- Bundle ID: Configured via Xcode
- App Group: `group.GM4766U38W.com.bapaws.planbook`
- URL Schemes: `planbook.bapaws`, Google OAuth
- Supported localizations: English, Chinese (Simplified), Chinese (Traditional)

## Code Generation

Several packages require code generation:

```bash
# Generate all code (Drift, AutoRoute, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for development
flutter pub run build_runner watch --delete-conflicting-outputs
```

Generated files:
- `lib/app/app_router.gr.dart` - AutoRoute generated routes
- `packages/planbook_api/lib/database/database.g.dart` - Drift generated code
- `lib/l10n/gen/` - Flutter localization generated files

## Localization

The app supports multiple languages:
- **English** (`lib/l10n/arb/app_en.arb`)
- **Chinese Simplified** (`lib/l10n/arb/app_zh.arb`)
- **Chinese Traditional** (`lib/l10n/arb/app_zh_TW.arb`)

Configuration in `l10n.yaml`:
```yaml
arb-dir: lib/l10n/arb
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/l10n/gen
```

## Development Conventions

### Code Style
- Uses **very_good_analysis**: ^9.0.0 for linting
- Configuration in `analysis_options.yaml`
- Excludes generated files from analysis

### BLoC Pattern Structure
Each feature follows the BLoC pattern:
```
feature_name/
├── bloc/
│   ├── feature_bloc.dart
│   ├── feature_event.dart
│   └── feature_state.dart
├── view/
│   ├── feature_page.dart
│   └── feature_widgets.dart
└── model/
    └── feature_models.dart
```

### Routing
Routes are defined in `lib/app/app_router.dart` using AutoRoute:
- Uses Cupertino-style transitions by default
- Modal bottom sheets for forms and pickers
- Route guards for authentication

### Naming Conventions
- **Pages**: `*Page` (e.g., `TaskListPage`)
- **Routes**: `*Route` (AutoRoute generates these)
- **BLoCs**: `*Bloc` with `*Event` and `*State`
- **Cubits**: `*Cubit` with `*State` (for simpler state)
- **Repositories**: `*Repository`

## Testing

Currently, the project has minimal test coverage. Tests should be added in:
- `test/` directory for main app
- `packages/*/test/` for package tests

Recommended testing packages are already included:
- **flutter_test** - Flutter testing framework
- **bloc_test** - BLoC testing utilities
- **mocktail** - Mocking library

## CI/CD

GitHub Actions workflow (`.github/workflows/main.yaml`):
- **Semantic PR Check**: Validates PR titles
- **Build**: Uses Very Good Workflows for Flutter
- **Spell Check**: Documentation spell checking

## Key Features

### Task Management
- Task creation with title, description, dates
- Priority levels (Eisenhower Matrix: Important/Urgent quadrants)
- Recurring tasks with customizable rules
- Subtasks support
- Drag-and-drop reordering
- Multiple views: Today, Week, Month, Inbox, Overdue

### Note Taking
- Rich text notes with markdown support
- Daily focus and summary notes
- Note tagging
- Image attachments
- Gallery view with calendar

### Journal/Discover
- Daily/Weekly/Monthly/Yearly focus and summary
- Mind map visualization
- Auto-play journal review
- Statistics and analytics

### User Features
- Authentication (Email, Phone, Apple Sign-In, Google Sign-In)
- User profile management
- Pro/Premium subscription via RevenueCat
- Data synchronization via Supabase

## Important Implementation Notes

### iPadOS 26 Workaround
The app includes a workaround for an iPadOS 26.1+ bug where Drawer/Dialog/BottomSheet closes immediately after opening. The `FilteringFlutterBinding` class filters out PointerEvents at position (0, 0).

### Channel Configuration
Different builds use different channel configurations:
- Main channel: Standard build
- Store channel: For app stores (no auto-update)
- Cloud channel: For self-distribution with auto-update

### Platform-Specific Code
- Android: Method channel for APK download/installation
- iOS: Method channel for widget communication

## Security Considerations

1. **API Keys**: RevenueCat and Supabase keys are embedded in the code
2. **App Group**: Uses iOS App Groups for widget data sharing
3. **Keychain**: User credentials stored in secure storage
4. **Local Database**: SQLite with encryption not currently implemented

## Dependencies to Note

- **flutter_native_splash**: ^2.4.6 - Splash screen (currently disabled for Android 12+)
- **flutter_launcher_icons**: ^0.14.4 - App icon generation
- **audioplayers**: ^6.5.1 - Sound effects for task completion
- **image_picker**: ^1.1.2 - Photo selection
- **image_cropper**: ^11.0.0 - Image cropping
- **share_plus**: ^12.0.1 - Content sharing
- **in_app_review**: ^2.0.10 - App store review prompts

## Development Tips

1. **Hot Reload**: Use `flutter run` with specific target for flavor testing
2. **Database Migrations**: Drift handles schema migrations; check `database.dart`
3. **State Persistence**: HydratedBloc automatically persists BLoC states
4. **Localization**: Add new strings to ARB files, then run `flutter gen-l10n`
5. **Code Generation**: Run `build_runner` after modifying routes or database schemas

## Resources

- **Help Center**: https://malachite-aster-f7a.notion.site/1a018752b1d28086a748cc007acfd7ba
- **Privacy Policy**: https://uxsyr9xrl46.feishu.cn/wiki/IBcdwbHN1iJx8EkvSEEcUZqlnKg
- **Terms of Use**: https://uxsyr9xrl46.feishu.cn/wiki/Vk5fwN4A6i2kyzksv98c4IFjnCb
