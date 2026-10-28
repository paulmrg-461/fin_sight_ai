# Spec: canonical category ids

## Objective

Identify categories by `categoryId` everywhere instead of by display name, so
renames, archives, cross-device edits, and imports cannot split a category into
two or misattribute spending. The name becomes a resolved label, never a key.

## Current state

`CategoryEntity` has a stable `id` (plan 006), but transactions and budgets
store only `category` (the name). Renames cascade by matching the old name
across transactions, budgets, and schedules. Two categories with the same name,
a rename racing a sync pull, or an imported row with different casing breaks
that cascade. `categoryId` is the last known data-model gap in `MEMORY.md`.

## Data model

- `TransactionEntity`: add `categoryId` (`String?` during migration). Keep
  `category` as a read-only fallback snapshot for legacy/tombstoned rows.
- `BudgetEntity`: add `categoryId`; budget identity becomes
  `(categoryId ?? category, month)`.
- `ScheduledPaymentEntity`: add `categoryId` when its picker is wired.
- `CategoryEntity`: unchanged; `name` is unique per user (case-insensitive)
  while active.
- New writes require `categoryId`; `category` is filled from the catalog so
  exports, CSV, and AI prompts keep working without a join.

## Resolution

`CategoryResolver` (domain service, pure Dart over a `List<CategoryEntity>`):

- `idForName(String name)` — case-insensitive, trims, ignores archived/deleted.
- `nameForId(String id, {String? fallback})`.
- `resolveImport(String rawName)` — returns id + canonical name or null.
- `categoryKey(TransactionEntity tx)` => `tx.categoryId ?? tx.category`.

Presentation always renders `nameForId(categoryId) ?? category`, so a rename
updates dashboards, budgets, reports, search, and AI context immediately.

## Migration

1. `0011_category_ids.sql` (or next number): add `category_id text` to
   `transactions`, `budgets`, `scheduled_payments`; backfill by joining the
   owner's categories on lower(trim(name)); leave null when ambiguous.
2. Local `CategoryIdMigrationService` (one-shot, like the calendar migration)
   writes `categoryId` into transaction/budget/schedule JSON where a unique
   active category matches; unmatched rows keep a null id and the name.
3. CSV import resolves each row name through `CategoryResolver`; unmatched
   names are reported per row and may optionally auto-create a category.
4. `CategoryRepositoryImpl.rename` stops rewriting historical rows by name once
   every row has an id (kept as a fallback for null-id rows only).

## Queries and aggregates

- Dashboard breakdown, budget progress, reports, search, and alerts group by
  `categoryKey` and display `nameForId`.
- Budget matching uses `(categoryId, month)` when both sides have ids; falls
  back to the normalized name for legacy rows.
- Unknown ids (deleted category) render the stored name snapshot; they are never
  reassigned silently.

## Sync

- Payloads carry `categoryId`; PostgREST maps `category_id`.
- Pull merges keep the id and refresh `category` only when the id resolves
  locally; remote rows with an unknown id are stored as-is and reconciled when
  the category arrives (same pass, definitions pulled before the ledger).
- Category rename no longer needs to be pushed as hundreds of ledger updates.
- RLS and indexes follow the existing owner policies; add
  `(user_id, category_id)` indexes for transactions and budgets.

## UI

- Pickers submit ids. Displays resolve names.
- Archived categories stay selectable only for existing records; new entries
  cannot choose them.
- Archive/delete confirmations state what happens to history (name stays
  visible, category hidden from pickers).

## Acceptance criteria

- Rename a category with 100 transactions and 3 budgets: dashboard, budget
  progress, reports, search, and AI context show the new name without a ledger
  write storm.
- Import a CSV with `food`, `Food`, and `FOOD`: all rows land on the same
  category id.
- Two categories differing only by case cannot be created.
- A pull of a renamed remote category updates the UI after the definitions
  pass, and a pulled transaction with an unknown id does not crash.
- Legacy rows with null ids still render and remain editable; saving assigns
  the id.
- Coverage stays ≥90% for domain/data and the 37 integration flows stay green.

## Phases

1. `CategoryResolver` + tests; no behavior change.
2. Transaction writes/pickers/import; backfill; sync column.
3. Budget identity and progress; sync column.
4. Aggregations/reports/AI resolution.
5. Scheduled payments; remove name-cascade write storm.

## Risks

- Ambiguous duplicates block backfill; the migration must report them instead
  of guessing.
- A partially rolled-out client that still writes names must keep working until
  the sync column is enforced; keep the name fallback for at least one release.
- Category deletion must not orphan budgets; archive instead, and keep the id
  resolvable for history.
