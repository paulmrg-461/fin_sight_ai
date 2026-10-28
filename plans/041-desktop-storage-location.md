# 041 — Desktop storage location

**Priority:** P2 · **Effort:** S · **Depends on:** 040 (encrypted boxes)

## Problem

`getApplicationDocumentsDirectory()` on Linux returns the user's
`~/Documents` folder, so running the desktop build leaves `transactions.hive`,
`settings.hive`, `storage_meta.hive`, and `.lock` files next to the user's real
documents. It also makes two app instances contend on the same files.

## Scope

- Resolve the application support directory on Linux, macOS, and Windows.
- Keep mobile behavior unchanged (the documents directory is already
  app-private there).
- On the first desktop launch after the change, copy legacy `*.hive` files from
  the documents directory into the support directory.
- Never delete or overwrite originals; never copy lock files.
- Fall back to the documents directory if the support path cannot be resolved.

## Out of scope

- Moving receipt images (they live under the documents directory via
  `ReceiptImageStore`).
- Deleting the legacy copies; the user can remove them after verifying.
- Web storage.

## Design

`HiveStorageLocation` (core service):

- `isDesktop` defaults to `defaultTargetPlatform` being Linux, macOS, or
  Windows; overridable for tests.
- `resolve()` returns support on desktop, documents elsewhere.
- Migration runs only when the support directory has no `*.hive` files. It
  copies every `*.hive` file (including `storage_meta.hive`, which carries the
  encryption flag) and ignores `*.lock` and unrelated files.
- A copy failure deletes the partially copied files and leaves the app on the
  support path; the next launch retries, and the originals are intact.
- Directory providers and the desktop flag are injectable, so tests use temp
  directories.

`StorageModule` calls `HiveStorageLocation().resolve()` before
`Hive.initFlutter`.

## Verification

```bash
flutter analyze
flutter test --coverage
dart run tool/check_coverage.dart
flutter run -d linux --dart-define-from-file=.env
```

Manual check: after launch, `~/.local/share/pro.devpaul.fin_sight_ai/` contains
the same `.hive` files as `~/Documents`, the ledger still loads (the copied
`storage_meta` keeps the encryption flag), and `~/Documents` is untouched.

## Risks

- Copies are byte-identical, so encrypted boxes stay readable with the same
  secure-storage key.
- Running the old build and the new build at the same time would split writes
  across two directories. Close the old instance before upgrading.
- If the support path later changes (application id rename), the migration
  triggers again from documents, which may be stale. Keep the originals until
  the desktop release is validated.
