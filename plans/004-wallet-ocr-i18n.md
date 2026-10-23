# Plan 004: Refresh wallet balances, fix OCR posting, and finish i18n

> **Executor instructions**: Follow step by step; run verifications; update the
> status row. STOP on drift or if a string change requires a data migration not
> covered here.
>
> **Drift check**: `git diff --stat 4e42297..HEAD -- lib/features/wallets lib/features/ocr lib/features/auth/presentation/screens lib/features/budgets/presentation lib/features/dashboard lib/l10n`

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: 003 (normalized dates)
- **Category**: bug / docs
- **Planned at**: commit `4e42297`, 2026-10-23

## Why this matters

Three user-visible correctness gaps:

1. Wallet balances are loaded once at startup and never refreshed. After an
   expense, sync pull, or scheduled auto-charge, Money shows stale balances and
   transfer validation uses stale funds.
2. Receipt scanning always posts an expense to the hard-coded category
   `Receipts`, which is not in the seeded catalog, and ignores a failed
   transaction while reporting `OcrSaved`. The receipt says success even when
   no expense exists.
3. Several hard-coded English strings remain, so Spanish UI is mixed and
   `ARCHITECTURE.md` claims otherwise.

## Current state

- `lib/main.dart:56` — only startup `LoadWallets`.
- `lib/features/wallets/presentation/bloc/wallet_bloc.dart:22` — reloads only on
  its own events.
- `lib/features/wallets/presentation/screens/wallet_screen.dart:62` — stateless
  `BlocBuilder`, no load on mount.
- `lib/features/ocr/presentation/bloc/ocr_bloc.dart:81-94` — `AddTransaction`
  result discarded; `category: 'Receipts'`; `OcrSaved` emitted unconditionally.
- `lib/features/categories/data/repositories/category_repository_impl.dart:24-82`
  — defaults contain no `Receipts` (EN has `Other`; ES has `Otros`).
- `lib/features/ocr/presentation/bloc/ocr_event.dart:32-39` — `SaveReceipt`
  carries `receipt` + `createTransaction` only.
- `lib/features/ocr/presentation/screens/receipt_preview_screen.dart:200` —
  dispatches `SaveReceipt`.
- Hard-coded copy: `login_screen.dart:66`, `budget_screen.dart:167` and `:316`,
  `dashboard_page.dart:82-83`.
- Default wallet names are persisted Spanish (`wallet_repository_impl.dart:189,200`).

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Generate l10n | `flutter gen-l10n` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test tool` | 0 changed |
| Analyze | `flutter analyze` | No issues |
| Unit | `flutter test --coverage` | all pass |
| Coverage | `dart run tool/check_coverage.dart` | passed |
| Integration | `flutter test -d linux integration_test/app_flow_test.dart` | all pass |

## Scope

**In scope**
- `lib/features/wallets/presentation/**`
- `lib/features/ocr/**` (bloc, event/state, preview, tests)
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/budgets/presentation/screens/budget_screen.dart`
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb` (generated files follow)
- `lib/features/wallets/presentation/widgets/wallet_display_name.dart` (new)
- tests under `test/features/wallets`, `test/features/ocr`, `test/app`

**Out of scope**
- Changing persisted wallet names (display mapping only).
- OCR engine/platform support.
- Notification work (plan 009).

## Steps

### Step 1: Refresh wallets on screen and resume

1. Convert `WalletScreen` to `StatefulWidget`; in `initState` dispatch
   `context.read<WalletBloc>().add(const LoadWallets())`.
2. Add `WidgetsBindingObserver`; on `AppLifecycleState.resumed`, dispatch
   `LoadWallets`.
3. Wrap the loaded body in a `RefreshIndicator` whose `onRefresh` dispatches
   `LoadWallets` and awaits one frame/`Future.delayed(300ms)` so the spinner
   completes.
4. Ensure the Money screen still renders loading/empty/error correctly.

**Verify**: widget/integration test opens Money after adding an expense and sees
the updated balance without restarting.

### Step 2: Make OCR posting explicit and safe

1. Add `String? category` to `SaveReceipt` (default null) and include it in
   `props`.
2. In `ReceiptPreviewScreen`, add `CategoryDropdown` above the save button
   (default to the first active category, preferably `Other`/`Otros` when
   present) and pass the selected name to `SaveReceipt`.
3. In `OcrBloc._onSave`, use `event.category ?? 'Other'`; inspect the
   `AddTransaction` result:
   - success → `OcrSaved(saved)`;
   - failure → new state `OcrTransactionFailure(saved, failure.message)`.
4. Add `OcrTransactionFailure` to the sealed state, show a `SnackBar`/banner
   ("Receipt saved, but the expense could not be recorded.") and keep the
   receipt in the list.
5. Add ARB keys `receiptSavedExpenseFailed` and `selectCategory` if needed.

**Verify**: bloc test where `addTransaction` returns `Left(ValidationFailure)`
emits `OcrTransactionFailure`, not `OcrSaved`.

### Step 3: Finish the hard-coded strings

Add ARB keys and replace:
- `login_screen.dart:66` → `l10n.createAccount` / `l10n.signIn`.
- `budget_screen.dart:167` → existing `l10n.overBudgetBy`.
- `budget_screen.dart:316` → existing `l10n.categoryRequired`.
- `dashboard_page.dart:82-83` → `l10n.switchToLight` / `l10n.switchToDark`.

Regenerate localizations.

**Verify**: `grep -rn "Over budget by\|Switch to light mode\|Create account'" lib/features` returns no matches (allow test fixtures).

### Step 4: Localize default wallet labels without migrating data

Create `walletDisplayName(BuildContext, WalletEntity)`:
- `wallet-bank` → `l10n.bankAccount`;
- `wallet-cash` → `l10n.cash`;
- otherwise → `wallet.name`.

Use it in `WalletScreen`, the transaction form wallet dropdown, and the
scheduled-payment form dropdown. Keep persisted names untouched for sync
compatibility. Add a widget test that switches locale to `es` and asserts the
default labels are Spanish.

## Test plan

- `test/features/wallets/presentation/wallet_screen_test.dart` (new): mount →
  `LoadWallets` dispatched; pull-to-refresh reloads.
- `test/features/ocr/presentation/bloc/ocr_bloc_test.dart`: add failure branch.
- `test/app/app_test.dart`: login AppBar uses `l10n` after locale switch.
- Integration: scan receipt with a selected category and assert the created
  transaction uses it; the existing OCR flow still passes.

## Done criteria

- [ ] `flutter analyze` exits 0; `flutter test --coverage` and coverage gate pass.
- [ ] Integration suite passes; OCR flow creates the selected category.
- [ ] `grep` checks in Steps 3 return clean.
- [ ] No persisted wallet names are rewritten.
- [ ] `plans/README.md` updated.

## STOP conditions

- `CategoryBloc` is not available in the receipt preview route.
- The OCR flow auto-creates transactions in a path not covered by `SaveReceipt`.
- A string replacement would change a persisted value rather than display text.

## Maintenance notes

- New OCR-created transactions must always receive an explicit catalog category.
- Any new default wallet id needs a localized display mapping.
- Reviewer: verify the wallet screen refresh does not create a load loop with
  `LoadWallets` events.
