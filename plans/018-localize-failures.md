# Plan 018: Localize failure messages

> **Executor instructions**: Keep the domain Flutter-free and English; translate
> only at the presentation boundary. Preserve unknown messages as-is.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 004
- **Category**: i18n
- **Planned at**: commit 7e4e609, 2026-10-26
- **Status**: DONE

## Why this matters

The UI translated labels but showed English validation and storage errors even
in Spanish. That broke the otherwise complete EN/ES experience.

## What shipped

- `FailureText` extension on `BuildContext` maps the stable domain messages to
  ARB strings in the active locale.
- Exact mappings cover validation, auth, sync, AI, wallet, debt, receivable,
  schedule, budget, and receipt failures.
- Prefix mappings cover the shared infrastructure families
  (`Unable to read/save/delete/update/calculate/record/rename/process/scan/
  transfer`, `Could not …`).
- Unknown messages fall back to the original English text, so new domain errors
  never disappear.
- All failure-rendering screens (transactions, debts, receivables, budgets,
  wallets, schedules, categories, dashboard, OCR, AI coach, sync, login) use the
  helper.

## Tests

- Widget tests for exact translations, prefix families, and unknown-message
  fallback in both locales.
- Existing integration suite covers the English rendering paths.

## Follow-ups

- Replace message matching with failure codes if states start carrying
  `Failure`; AI-generated insight text still comes from the model in English.

## Done criteria

- [x] Spanish shows translated errors for mapped failures.
- [x] Unknown failures fall back safely.
- [x] Analyze, unit coverage, coverage gate, and Linux integration pass.
