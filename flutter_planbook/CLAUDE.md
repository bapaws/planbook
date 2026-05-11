# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

`AGENTS.md` is the long-form companion to this file — it contains the full BLoC patterns, schema details, security notes, and platform-specific workarounds. Read it whenever a section here points there.

## Build & Run

The app has three entry points wired to Android flavors. Always pass both `--target` and `--flavor` together:

```bash
flutter build ipa --target lib/main.dart                                  # iOS App Store
flutter build appbundle --target lib/main.dart --flavor store             # Google Play
flutter build apk --flavor store --target lib/main_store.dart             # 国内市场 (Xiaomi/VIVO)
flutter build apk --flavor cloud --target lib/main_cloud.dart             # 自分发 (Tencent Cloud)
```

`AppChannel.instance.type` is set in each `main_*.dart` and gates channel-specific behavior — don't bypass it.

## Code Generation

Three independent generators. Run only the ones whose inputs you touched:

```bash
# AutoRoute (after editing lib/app/app_router.dart)
dart run build_runner build --delete-conflicting-outputs

# Localization (after editing lib/l10n/arb/*.arb)
flutter gen-l10n

# Drift schema (after editing tables in packages/planbook_api)
cd packages/planbook_api && dart run build_runner build --delete-conflicting-outputs
```

Generated files (`*.g.dart`, `lib/l10n/gen/*`, `app_router.gr.dart`) are excluded from analysis — never edit them by hand.

## Architecture

Layered, with local path packages under `packages/`. Higher layers depend on lower; never invert.

```
flutter_planbook (lib/)         UI + BLoCs + routes
  └── planbook_repository       business logic; aggregates local + remote
        ├── database_planbook_api    Drift/SQLite (local)
        └── supabase_planbook_api    Supabase (remote)
              └── planbook_api       entities, schema, AppSupabase config
  └── planbook_core             shared widgets, constants (kAppGroupId, etc.)
  └── planbook_widget           Android home-screen widget bridge
```

`lib/bootstrap.dart` is the composition root: it constructs every repository, wires `TaskActionService` (the single source of truth for task complete/delete/auto-note/reminder side effects), registers them via `MultiRepositoryProvider`, and only then mounts `App`. New repositories must be added here, not lazily in widgets.

Feature folders under `lib/` (`task/`, `note/`, `tag/`, `discover/`, `settings/`, `sign/`, `mine/`, `widget/`) each contain their own `bloc/`, `view/`, and sub-features. `lib/root/` is the bottom-tab shell.

## BLoC conventions (load-bearing — see AGENTS.md §State Management for full rules)

- **Streams from repositories → `emit.forEach`.** One-shot reads/writes → plain `emit`. Mixing them inside one handler leaks subscriptions.
- **Pick a transformer for every `on<>` registration.** `restartable()` for queries/search, `sequential()` for ordered mutations, `droppable()` for submit buttons. Don't rely on the default.
- **State is `Equatable` + `final` fields + `copyWith`.** Nullable fields in `copyWith` use `ValueGetter<T?>?` so callers can distinguish "leave alone" from "set to null".
- **External streams** (e.g., `ApkDownloadService.progressStream`) are subscribed manually in the bloc and re-emitted as events; cancel the subscription in `close()`.

## Conventions

- **Comments are Chinese.** Match the surrounding style; don't translate existing comments to English.
- **User-facing strings live in `lib/l10n/arb/app_en.arb`** (template) plus `app_zh*.arb` translations. Access via `context.l10n.<key>`.
- **Lints:** `very_good_analysis` with `no_default_cases` and `public_member_api_docs` disabled. The `lib/l10n/gen/*` tree is excluded.
- **Naming:** files snake_case, classes PascalCase, constants k-prefixed (e.g., `kAppGroupId`).

## Platform gotchas

- **iPadOS 26.1+ pointer bug** — `FilteringFlutterBinding` in `lib/main.dart` drops `PointerEvent`s at `(0,0)` to keep Drawers/Dialogs/BottomSheets from auto-closing. The detection is iPad-only and version-gated; don't apply it elsewhere.
- **iOS App Group**: `group.GM4766U38W.com.bapaws.planbook`. The SQLite DB and RevenueCat user defaults both live there so the home-screen widget can read them.
- **Database migration**: `_migrationDatabasePath` in `bootstrap.dart` clears Supabase sync timestamps when no `planbook.sqlite` exists, forcing a re-pull after the old `habits.sqlite` rename. Don't remove without understanding the migration story.

## Tests

Test deps (`bloc_test`, `mocktail`) are configured but the project currently has **no `test/` directory**. If you add tests, place them at the project root in `test/` and follow `*_test.dart`.
