# Plan 006: Give categories a stable id and cascade renames

> **Executor instructions**: Follow step by step; update the status row. STOP if
> the migration cannot be made deterministic or if sync payload shape would
> change before plan 007.
>
> **Drift check**: `git diff --stat 4e42297..HEAD -- lib/features/categories lib/features/transactions lib/features/budgets lib/features/scheduled_payments lib/main.dart test/features`

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: MED
- **Depends on**: 003
- **Category**: tech-debt / bug
- **Planned at**: commit `4e42297`, 2026-10-23

## Why this matters

Transactions, budgets, and scheduled payments store the category **display
name**. Renaming a catalog entry therefore detaches budgets (spending no longer
matches) and schedules (they keep generating the retired name). Category
identity is the missing half of the catalog feature and a prerequisite for
syncing definitions safely.

After this plan, every record carries a `categoryId` plus a denormalized name
snapshot; renaming cascades by id across local records and enqueues updates.

## Current state

- `lib/features/categories/domain/entities/category_entity.dart` — `id`, `name`,
  `isArchived`, timestamps.
- `lib/features/categories/data/repositories/category_repository_impl.dart:130-164`
  — `renameCategory` updates only the catalog row.
- `lib/features/transactions/domain/entities/transaction_entity.dart:26-30` —
  `category` is a `String`.
- `lib/features/budgets/domain/entities/budget_entity.dart:17-19` — `category`
  String; `budget_repository_impl.dart:137` matches spending by name.
- `lib/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart:26-30`
  — `category` String; generated transactions copy it at
  `scheduled_payment_repository_impl.dart:286`.
- `lib/features/categories/presentation/widgets/category_dropdown.dart` —
  dropdown returns the selected **name**.

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Generate DI | `dart run build_runner build --delete-conflicting-outputs` | exit 0 |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test tool` | 0 changed |
| Analyze | `flutter analyze` | No issues |
| Unit | `flutter test --coverage` | all pass |
| Coverage | `dart run tool/check_coverage.dart` | passed |
| Integration | `flutter test -d linux integration_test/app_flow_test.dart` | all pass |

## Scope

**In scope**
- category/transaction/budget/scheduled-payment entities + models + repositories
- `lib/features/categories/domain/usecases/**` and repository
- new migration use case in `lib/features/categories/domain/usecases/`
- `lib/main.dart` (run migration before BLoCs)
- forms/dropdowns that select categories
- tests for the above
- `specs/SPEC-categories.md`, `specs/SPEC-scheduled-payments.md` (update the
  storage contract)

**Out of scope**
- Postgres schema and sync payloads (plan 007).
- Renaming categories on other devices.
- Changing category defaults.

## Steps

### Step 1: Add `categoryId`

Add `final String? categoryId;` to:
- `TransactionEntity` / `TransactionModel` (`categoryId` JSON key, parse
  nullable string, `copyWith`, `==`, `hashCode`);
- `BudgetEntity` / `BudgetModel`;
- `ScheduledPaymentEntity` / `ScheduledPaymentModel`.

Keep `category` as the display snapshot. Existing records deserialize with
`categoryId == null`; do not make it required.

**Verify**: model round-trip tests for each entity including null and set ids.

### Step 2: Resolve ids on write

Add a lookup helper, e.g.
`CategoryEntity? findByName(List<CategoryEntity>, String name)` in
`category_usecases.dart` (case-insensitive, trimmed).

Update the write paths:
- `AddTransactionUseCase` accepts `categoryId` in params (validated non-empty if
  provided; default null).
- `AddBudgetUseCase` accepts `categoryId`.
- `AddScheduledPaymentUseCase` accepts `categoryId`.
- Forms: after choosing a category name from `CategoryDropdown`, look up the
  active catalog entry from `CategoryBloc.state` and pass both id and name.
- If no catalog match exists, create the category via `AddCategoryUseCase`
  before saving (or reject with a validation error). Prefer create to preserve
  offline typing.

**Verify**: use-case tests assert id+name are persisted together.

### Step 3: Migrate existing records

Add `ResolveCategoryIdsUseCase` (category feature) that:
1. Reads all categories including archived; builds a case-insensitive name→id
   map.
2. For each transaction/budget/schedule with `categoryId == null` and a
   non-empty category name:
   - map to an existing id, or create a category with that name;
   - set `categoryId` and persist through the existing repository methods
     (which stamp `updatedAt` and enqueue transactions/budgets).
3. Uses a `settings` flag `category_ids_migration_v1`; runs once, sets the flag
   only after success.

Call it in `lib/main.dart` after the calendar migration and before due-payment
processing. If no catalog exists yet, trigger `LoadCategories`/seed first via
`GetCategoryCatalogUseCase` inside the migration.

**Verify**: temp-Hive test with legacy rows; second run writes nothing.

### Step 4: Cascade renames by id

Extend `CategoryRepository` with a method to fetch a category by id (or reuse
`getCategories(includeArchived: true)`).

In `RenameCategoryUseCase`:
1. Rename the catalog row.
2. Find all transactions/budgets/schedules whose `categoryId == id`.
3. Update their `category` snapshot to the new name (keep the same id),
   stamping `updatedAt`; use repository update methods or `addTransaction` /
   `addBudget` upserts. For schedules, save via the local data source through
   the repository.
4. Enqueue sync updates for transactions/budgets; schedules stay local until
   plan 007.
5. If no affected records, finish after the catalog rename.

If a failure occurs mid-cascade, return a `CacheFailure` that states the
catalog may be renamed but records may be partially updated. Do not silently
succeed.

**Verify**: repository test with one transaction, one budget, one schedule;
rename; assert all three now carry the new name and same id.

### Step 5: Update aggregation and tests

- Budget progress aggregation can keep matching by `category` snapshot (now
  cascaded); no change required if Step 4 is complete.
- Update `SPEC-categories.md` and `SPEC-scheduled-payments.md`: records store
  `categoryId` + name snapshot; renames cascade locally.
- Integration: create a transaction in a custom category, rename the category,
  assert the transaction list and budget show the new name.

## Test plan

- Entity/model round-trips for `categoryId`.
- Migration: legacy rows, idempotence, missing catalog.
- Rename cascade: transaction, budget, schedule; failure path.
- Widget: dropdown writes id+name.
- Integration flow above.

## Done criteria

- [ ] New writes persist both `categoryId` and `category`.
- [ ] Migration is idempotent and runs before BLoCs.
- [ ] Rename updates all records with the id and enqueues transaction/budget
      updates.
- [ ] No PostgREST payload field is added yet.
- [ ] Gates pass; `plans/README.md` updated.

## STOP conditions

- Two categories share a name case-insensitively (duplicate prevention was
  bypassed); report instead of guessing.
- The migration would enqueue an unbounded number of sync operations; report
  and propose batching.
- A record has a category name with no possible catalog match and creation
  fails.

## Maintenance notes

- Plan 007 will add `category_id` to Postgres and the sync mappers.
- Any new category-bearing entity must store id+snapshot and join the cascade.
- Reviewer: ensure historical transactions remain readable if the catalog row
  is later deleted.
