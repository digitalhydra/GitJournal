# GitJournal Agent Instructions

Flutter note-taking app with Git sync. Cross-platform (Android, iOS, Linux, macOS).

## Quick Commands

```bash
# Run (Android recommended - iOS setup is complex)
flutter run --flavor dev --debug

# Test
flutter test                    # or: ./scripts/test.sh

# Lint
flutter analyze                 # or: make lint

# Code generation (after changing models with @HiveType, etc.)
flutter packages pub run build_runner build --delete-conflicting-outputs

# Localization (auto-generated on .arb save via VS Code, or manual)
flutter gen-l10n
```

## Project Structure

```
lib/
  main.dart           # Entry point - uses Chain.capture for error handling
  app.dart            # JournalApp widget
  app_router.dart     # Navigation routing
  repository.dart     # Git repository abstraction
  core/               # Note, folder models, git operations
  editors/            # Markdown/raw note editors
  screens/            # UI screens
  settings/           # App configuration
  widgets/            # Shared UI components
  l10n/               # ARB translation files
  generated/          # Auto-generated (build_runner, protobuf)

packages/git_setup/   # Monorepo package (Melos)
```

## Architecture Notes

- **State Management**: BLoC pattern (`flutter_bloc`, `bloc` packages). `Bloc.observer` set in main.dart for debugging.
- **Git Integration**: Custom `dart_git` package + `go_git_dart` for native Git operations.
- **Storage**: Hive for local cache, files in Git repo for notes.
- **Notes**: Markdown + YAML frontmatter format.

## Code Generation

Must run after modifying:
- Files with `@HiveType` annotations → `build_runner build`
- Protobuf files (.proto) → `make protos`
- Localization (.arb) → `flutter gen-l10n`

## Development Workflow

1. **Always use `--flavor dev`**: Required for running/debugging
2. **VS Code setup**: Extension auto-runs `flutter gen-l10n` on .arb changes
3. **Environment**: `scripts/setup_env.dart` generates `lib/.env.dart`

## Testing

- Unit tests in `test/` mirror `lib/` structure
- Run single test: `flutter test test/path/to/test.dart`
- Test utilities: `test/lib.dart`

## Monorepo (Melos)

```bash
melos bootstrap     # Install deps across packages
melos run analyze   # Run analyze in all packages
```

## Linting Rules (Non-Default)

From `analysis_options.yaml`:
- `missing_required_param` and `missing_return` are **errors**, not warnings
- `use_key_in_widget_constructors: false`
- `use_build_context_synchronously: false`
- `no_leading_underscores_for_local_identifiers: false`

## License Compliance

- **Dual License**: Vishesh Handa's code = AGPL-3.0; Contributors = Apache-2.0
- **REUSE**: Run `reuse addheader --license 'AGPL-3.0-or-later' ...` on new files
- Generated files in `lib/generated/` are exempt from some lint rules

## Key Dependencies

- `dart_git`: Custom Git operations (external repo)
- `go_git_dart`: Native Git bindings
- `hive` + `hive_generator_plus`: Local storage
- `flutter_bloc`: State management
- `supabase_flutter`: Backend services
- `sentry_flutter`: Error reporting

## CI/CD Notes

- Linux builds use container `ghcr.io/gitjournal/flutter-android-sdk:latest`
- Requires `GITCRYPT_KEY` secret to decrypt `secrets/` for builds
- Test script: `./scripts/test.sh`

## Entry Points

- **App**: `lib/main.dart` → `JournalApp.main()`
- **Widgetbook**: `lib/main.widgetbook.dart` (component library)

## Gotchas

- `lib/experiments/` and `lib/account/init.dart` are excluded from analysis
- `flutter_displaymode` only runs on mobile (guarded by `Platform.isIOS || Platform.isAndroid`)
- Error handling: Uses `Chain.capture()` from `stack_trace` for async error tracking
