# Plan 001: Remove secrets from release bundles and gate generated files

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving on. If a
> STOP condition occurs, stop and report — do not improvise. Update the status
> row for this plan in `plans/README.md` when done.
>
> **Drift check (run first)**:
> `git diff --stat 4e42297..HEAD -- pubspec.yaml lib/core/utils/app_env.dart lib/main.dart test/core/utils/app_env_test.dart .github/workflows/ci.yml README.md`
> If any in-scope file changed, compare the excerpts below with the live code;
> on a mismatch, STOP.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: security / dx
- **Planned at**: commit `4e42297`, 2026-10-23

## Why this matters

`pubspec.yaml` declares `.env` as a Flutter asset, so every local build copies
the developer's real credentials into the app bundle where they can be
extracted (`unzip app.apk assets/flutter_assets/.env`). The code's
`--dart-define` precedence hides the leak during development. Separately, CI
regenerates `lib/core/di/injection.config.dart` and `lib/l10n`, but never checks
that the committed files match, so a stale dependency graph can merge green and
fail at runtime on device.

After this plan: release builds contain no `.env`, configuration comes only from
`--dart-define` / `--dart-define-from-file`, and CI fails when generated files
are stale.

## Current state

- `pubspec.yaml:90-91`:
  ```yaml
  assets:
    - .env
  ```
- `lib/core/utils/app_env.dart:1` imports `package:flutter_dotenv/flutter_dotenv.dart`;
  `load()` calls `dotenv.load(fileName: fileName, isOptional: true)` and
  `_value()` falls back to `dotenv.maybeGet(key)`.
- `lib/main.dart:37` calls `await AppEnv.load();`.
- `test/core/utils/app_env_test.dart` asserts dotenv-map behavior.
- `test/core/di/injection_test.dart:93` imports `flutter_dotenv` and its
  `setUp` calls `dotenv.loadFromString(...)` to populate `AppEnv`; lines 143-144
  assert those values. Removing the dependency requires editing this file.
- `.github/workflows/ci.yml:20-21` and `:66-67` run `cp example.env .env`.
- README line ~65 tells developers to `cp example.env .env`.
- `ARCHITECTURE.md:171-175` documents the dotenv asset and fallback.
- No production code outside `app_env.dart` references dotenv; tests and docs do.

Repo conventions: immutable `AppEnv` value object constructed from
`String.fromEnvironment`; tests use direct constructors rather than platform
state. Match `test/core/currency/app_currency_test.dart` for plain value tests.

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Dependencies | `flutter pub get` | exit 0 |
| Generate | `flutter gen-l10n` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test tool` | 0 changed |
| Analyze | `flutter analyze` | No issues found |
| Tests | `flutter test` | all pass |
| Integration | `flutter test -d linux integration_test/app_flow_test.dart` | all pass |

## Scope

**In scope**
- `pubspec.yaml`, `pubspec.lock`
- `lib/core/utils/app_env.dart`
- `lib/main.dart`
- `test/core/utils/app_env_test.dart`
- `test/core/di/injection_test.dart`
- `.github/workflows/ci.yml`
- `README.md`, `example.env` (comments only), `MEMORY.md` (credential warning)
- `ARCHITECTURE.md` (configuration section)

**Out of scope**
- `lib/core/services/*`, Supabase/Groq runtime behavior, real credentials.
- Any secret value. Never print or commit `.env`.

## Steps

### Step 1: Remove the asset and the runtime dotenv fallback

1. Delete the `assets: - .env` block from `pubspec.yaml` (leave `flutter:
   generate: true` and fonts untouched).
2. Remove `flutter_dotenv` from `dependencies` and run
   `flutter pub get` to update `pubspec.lock`.
3. In `app_env.dart`: delete the `flutter_dotenv` import, the `load()` method,
   and the `dotenv` fallback in `_value`. Keep `AppEnv.current()` reading only
   `String.fromEnvironment` constants and keep the constructor used by tests.
4. Delete `await AppEnv.load();` from `lib/main.dart`.
5. Update the `AppEnv` doc comment: production values come from
   `--dart-define` (or `--dart-define-from-file=.env` for local dev).

**Verify**: `grep -rn "dotenv\|assets:" lib pubspec.yaml` → only unrelated
matches (none for dotenv; no `.env` asset).

### Step 2: Update tests

Rewrite `test/core/utils/app_env_test.dart` to:
- construct `AppEnv(supabaseUrl: ..., supabaseAnonKey: ..., groqApiKey: ...)`
  and assert `hasSupabase` / `hasGroq` for populated and empty values;
- assert `AppEnv.current()` returns empty strings in the test environment.

Delete all `dotenv.loadFromString` / `dotenv.clean` usage.

In `test/core/di/injection_test.dart`:
- remove the `flutter_dotenv` import and the `dotenv.loadFromString(...)` call
  in `setUp`;
- replace lines 143-144 with assertions that the registered `AppEnv` is
  constructed and has empty values in the test environment (no defines):
  `expect(getIt<AppEnv>().supabaseUrl, isEmpty);`
  `expect(getIt<AppEnv>().hasGroq, isFalse);`
  Populated-value behavior is covered by the `AppEnv` value-object tests.

**Verify**: `flutter test test/core/utils/app_env_test.dart test/core/di/injection_test.dart` → all pass.

### Step 3: Update setup docs and CI

1. README: replace `cp example.env .env` guidance with
   `flutter run --dart-define-from-file=.env` (and the existing explicit
   `--dart-define` example for CI/release). State that `.env` is local-only and
   must never be an asset.
2. `example.env`: add a header comment with the same command.
3. `.github/workflows/ci.yml`: remove both `cp example.env .env` steps.
4. Update `ARCHITECTURE.md` §7: remove the dotenv asset/fallback description;
   state that configuration comes from `--dart-define` (or
   `--dart-define-from-file` locally) and that `.env` is never bundled.
5. After `Generate DI`, add a generation/verification block to the `quality`
   job:
   ```yaml
   - name: Generate localizations
     run: flutter gen-l10n
   - name: Verify generated files are committed
     run: git diff --exit-code -- lib/core/di/injection.config.dart lib/l10n
   ```
   (No `git add`; the step must fail when regeneration changes tracked files.)

**Verify**: `dart format` and `flutter analyze` clean.

### Step 4: Record the rotation warning

In `MEMORY.md`, under "Local environment", add: `.env` is no longer bundled;
any key that was present in a local build must be rotated (Groq key and
Supabase DB password). Do not write key values.

**Verify**: `grep -n "\.env" MEMORY.md README.md | head` → guidance present.

## Test plan

- Update `test/core/utils/app_env_test.dart` as described; treat it as the
  regression test for "no dotenv dependency".
- No new integration test is needed; the existing suite must stay green.
- Add one CI assertion (above) that fails on stale generated files.

## Done criteria

- [ ] `grep -rn "flutter_dotenv\|dotenv" lib test pubspec.yaml` returns nothing.
- [ ] `grep -n "assets:" -A3 pubspec.yaml` does not list `.env`.
- [ ] CI has the generated-files diff gate in the `quality` job.
- [ ] `flutter analyze` exits 0.
- [ ] `flutter test --coverage` passes and `dart run tool/check_coverage.dart` passes.
- [ ] `flutter test -d linux integration_test/app_flow_test.dart` passes.
- [ ] `grep -n "dotenv" ARCHITECTURE.md README.md` returns no stale guidance.
- [ ] `git status` shows no `.env` and no files outside scope.
- [ ] `plans/README.md` status row updated.

## STOP conditions

- `flutter_dotenv` is used outside `app_env.dart` (update the plan scope first).
- Removing the asset breaks a test or runtime loader in a way not covered here.
- You cannot complete the step without printing a secret value.

## Maintenance notes

- Any future config loader must use `--dart-define`; never re-add `.env` as an
  asset.
- When adding a new generated file set, extend the CI `git diff --exit-code`
  path list.
- If CI needs secrets for integration tests, inject them through the workflow
  environment as `--dart-define`, not an asset.
