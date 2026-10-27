# Plan 028: Isolate sync failures and show diagnostics

> **Executor instructions**: One failing entity must never block the rest of the
> pull. Surface the failing entities without exposing tokens or payloads.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 005, 027
- **Category**: reliability
- **Planned at**: commit 452eb3a, 2026-10-27
- **Status**: DONE

## Why this matters

A missing `savings_goals` table produced a 404 that aborted the whole pull, so
the app looked “offline” even though auth and network were fine. The cloud icon
also hid the reason.

## What shipped

- Per-entity pull isolation: fetch/merge/parse failures are captured as
  `SyncEntityFailure` and the remaining entities still sync.
- `SyncReport.failures` carries entity, code, and message for both push and pull;
  partial passes now return a report instead of a generic failure.
- The sync chip detects entity failures, opens a dialog listing them with a
  friendly entity name and code, and offers Retry.
- Missing schema (`supabase_http_404`), rejected session (`401/403`), and
  transport errors have distinct messages.
- Debug builds log `SYNC failed: <code>` and transport exception details.
- Release builds declare `android.permission.INTERNET` in the main manifest.
- Troubleshooting guide added to `supabase/README.md`.

## Tests

- Partial pull: missing category table still pulls transactions.
- Invalid row and local merge failure are isolated with the right codes.
- Push failures are recorded in the report.
- Entity failure equality/report equality.

## Done criteria

- [x] One bad entity no longer blocks the pass.
- [x] The UI explains which entity failed and why.
- [x] Analyze, coverage gate, and Linux integration pass.
