# 040 — Encrypt Hive boxes at rest

**Priority:** P1 (privacy) · **Effort:** M · **Depends on:** 002 (account scope), 037 (app lock), 039 (startup boxes)

## Problem

The app lock hides the UI, but every amount, note, wallet, receipt path, and
sync queue entry is stored in plaintext Hive files. Rooted devices, adb backups,
and file managers can read them.

## Scope

- Generate a 32-byte AES key on first launch and keep it in platform secure
  storage (`flutter_secure_storage`).
- Open every ledger box with `HiveAesCipher`.
- Migrate existing plaintext boxes once, without losing records.
- Keep a tiny unencrypted `storage_meta` box that records whether encryption is
  active.
- Never fall back to plaintext after encryption is active: a wrong or missing
  key is a hard startup error, not a silent rewrite.
- Tests for key lifecycle, migration, wrong-key safety, and fresh boxes.

## Out of scope

- Encrypting the `storage_meta` marker (it holds one boolean).
- Rotating keys or changing the cipher.
- Encrypting the receipt image files on disk and the Supabase payloads (TLS
  already covers transport; at-rest encryption in Postgres is a project setting).

## Design

- `HiveEncryption` reads `hive_encryption_key`; a missing, malformed, or
  non-32-byte value is replaced with `Hive.generateSecureKey()` encoded as
  base64. Any storage exception returns `null`, which degrades to the previous
  plaintext behavior instead of blocking launch.
- `EncryptedBoxOpener.open(name, cipher, allowLegacyMigration)`:
  - opens with the cipher when available;
  - on failure, only if `allowLegacyMigration`, opens the plaintext box, copies
    its entries, deletes the file, and reopens encrypted;
  - otherwise rethrows, so a wrong key can never feed ciphertext to the
    plaintext reader.
- `StorageModule` opens `storage_meta` first. The `encrypted` flag decides
  whether legacy migration is allowed. If the flag is set and the key is
  unavailable, startup throws a clear `StateError`. On the first successful
  encrypted launch the flag is written.
- All boxes share one cipher; Hive handles encryption transparently for every
  existing data source.

## Risks

- Losing the secure-storage key (factory reset edge cases, backup restore
  without keystore data) makes the boxes unreadable. The app fails loudly
  instead of silently discarding records; the user must clear app data, after
  which Supabase repopulates synced entities.
- The first launch after the update rewrites every box; this is a one-time cost
  proportional to ledger size.
- Desktop Linux without a keyring falls back to plaintext, matching the old
  behavior.

## Verification

```bash
flutter analyze
flutter test --coverage
dart run tool/check_coverage.dart
flutter test -d linux integration_test/app_flow_test.dart
flutter build apk --debug --dart-define-from-file=.env
```

## Manual check

1. Install over an existing build with transactions.
2. Confirm the ledger still renders and the app does not re-seed data.
3. Inspect `app_flutter/*.hive` with `strings`: no merchant names or notes.
4. Kill the app, relaunch, and confirm the same data loads from the encrypted
   boxes.
