# Plan 008: Add transaction/budget editing, confirmation, and undo

> **Executor instructions**: Follow step by step; update the status row. STOP if
> the form refactor requires touching scheduled-payment editing (out of scope).
>
> **Drift check**: `git diff --stat 4e42297..HEAD -- lib/features/transactions lib/features/budgets test/features/transactions test/features/budgets integration_test/app_flow_test.dart`

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 003
- **Category**: direction
- **Planned at**: commit `4e42297`, 2026-10-23

## Why this matters

Transactions and budgets are create/delete only. A typo in an amount forces a
delete plus a new record: a new id, lost receipt linkage, two sync operations,
and a broken audit trail. Delete is a single tap with no confirmation or undo.
Debts already support updates, so the asymmetry is visible in the domain model.

After this plan, users can correct transactions and budgets in place (same id,
one sync update) and cannot delete by accident.

## Current state

- `lib/features/transactions/domain/repositories/transaction_repository.dart:5-19`
  — add/get/delete/byRange only.
- `lib/features/transactions/domain/usecases/add_transaction_usecase.dart` —
  create only.
- `lib/features/transactions/presentation/bloc/transaction_bloc.dart:24-55` —
  events Load/Add/Delete/Filter.
- `lib/features/transactions/presentation/widgets/transaction_form.dart` —
  create-only form; controllers in `initState`.
- `lib/features/transactions/presentation/widgets/transaction_list.dart:154` —
  delete `IconButton` with no confirmation.
- `lib/features/budgets/domain/repositories/budget_repository.dart` — add/delete/
  progress/categories only.
- `lib/features/budgets/presentation/screens/budget_screen.dart:65` — delete
  action; no edit.
- `lib/features/debts/data/repositories/debt_repository_impl.dart` — existing
  update pattern to copy (`updateDebt`, stamps `updatedAt`, enqueues).

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test tool` | 0 changed |
| Analyze | `flutter analyze` | No issues |
| Unit | `flutter test --coverage` | all pass |
| Coverage | `dart run tool/check_coverage.dart` | passed |
| Integration | `flutter test -d linux integration_test/app_flow_test.dart` | all pass |

## Scope

**In scope**
- `lib/features/transactions/{domain,data,presentation}/**`
- `lib/features/budgets/{domain,data,presentation}/**`
- tests under those features
- `integration_test/app_flow_test.dart` (edit + delete confirmation flow)
- ARB copy for edit/undo/confirm dialogs

**Out of scope**
- Scheduled-payment editing (separate follow-up).
- Debt editing (already works).
- Changing sync conflict policy.

## Steps

### Step 1: Transaction update path

1. Add `updateTransaction(TransactionEntity)` to `TransactionRepository` and
   `TransactionRepositoryImpl`. It must:
   - find the existing model by id (return `ValidationFailure('transaction_not_found')`
     if absent);
   - preserve `receiptImagePath`/`walletId` unless explicitly changed;
   - stamp `updatedAt = clock.now()`, `isSynced = false`;
   - save and enqueue `SyncOperation.upsert`.
   Copy the enqueue helper from the existing add method.
2. Add `UpdateTransactionParams` + `UpdateTransactionUseCase` with the same
   validation as add (amount > 0, category required, description ≤ 500, date
   normalized via plan 003's `calendarDate`). Include `id`,
   `receiptImagePath`, `walletId`.
3. Add `UpdateTransaction` event and handler to `TransactionBloc`; reload after
   success.

**Verify**: use-case and repository tests (found/not-found, updatedAt,
queue entry).

### Step 2: Prefill the form for edit

1. Add `final TransactionEntity? initial;` to `TransactionForm`.
2. In `initState`, prefill controllers and `_type/_date/_category/_walletId`
   from `initial`; default category fallback must not overwrite an existing
   name missing from the catalog.
3. Rename the submit button/title in edit mode (`l10n.editTransaction`,
   `l10n.saveChanges`).
4. On submit: dispatch `UpdateTransaction` when `initial != null`, else
   `AddTransaction`.
5. Add an edit icon to each transaction row that opens the same bottom sheet
   with `initial: transaction`.

**Verify**: widget/integration test edits an amount and sees the same row id
updated (no duplicate).

### Step 3: Confirm deletes and offer undo

1. Replace the direct delete dispatch in `TransactionList` with an
   `AlertDialog` (`l10n.deleteTransactionQuestion`, body, cancel/delete).
2. After a confirmed delete, show a `SnackBar` with `l10n.undo`. On undo,
   dispatch `AddTransaction` with the deleted entity's id and fields (the
   repository upsert clears the tombstone). Keep it best-effort and reload.
3. Apply the same confirmation pattern to budget deletion.

**Verify**: integration test cancels a delete (row remains), confirms another,
then taps undo (row returns).

### Step 4: Budget editing

1. Add `updateBudget(BudgetEntity)` to `BudgetRepository`/impl, preserving id,
   stamping `updatedAt`, enqueueing an upsert.
2. Add `UpdateBudgetParams` + `UpdateBudgetUseCase` (same validation as add).
3. Add `UpdateBudget` event/handler to `BudgetBloc`.
4. Make budget cards tappable to open the existing `_AddBudgetDialog` prefilled
   (`initialCategory`, `initialLimit`); submit dispatches update in edit mode.
5. Add `l10n.editBudget` and reuse save/cancel keys.

**Verify**: repository/bloc tests; widget/integration edit changes the limit in
place.

### Step 5: Guard against duplicate creates

When the editor opens in edit mode, the wallet dropdown must not reset the
wallet id, and the date must be normalized only once. Add a test that saving
twice produces one id and one queue operation (the second update replaces the
first).

## Test plan

- Repository: update found/not-found, preserves id, stamps updatedAt, enqueues.
- Use case: validation matrix mirrors add.
- Bloc: update event reloads; failure emits `TransactionFailure`.
- Widget/integration: edit amount, cancel delete, confirm delete, undo delete,
  edit budget limit.

## Done criteria

- [ ] Transactions and budgets can be edited without changing id.
- [ ] Deletes require confirmation; transaction delete offers undo.
- [ ] No duplicate record is created by an edit.
- [ ] `flutter analyze`, unit coverage, coverage gate, Linux integration pass.
- [ ] `plans/README.md` updated.

## STOP conditions

- `TransactionEntity.copyWith` cannot represent clearing `receiptImagePath` or
  `walletId`; report before changing copy semantics.
- Undo cannot restore a soft-deleted row without violating the sync tombstone
  contract.
- The form is also used by a screen that must remain create-only.

## Maintenance notes

- Scheduled-payment editing should reuse the same "prefilled form + update use
  case" pattern.
- Reviewer: verify edit updates do not lose the original `createdAt`/receipt
  linkage.
