# Spec: money as integer minor units

## Objective

Remove binary floating-point from every monetary path so balances, budgets,
reports, and sync payloads are exact. Amounts are stored, aggregated, and
compared as integer minor units (cents for USD and COP).

## Current state

`TransactionEntity`, `DebtEntity`, `ReceivableEntity`, `BudgetEntity`,
`WalletEntity`, `WalletTransferEntity`, `ScheduledPaymentEntity`,
`SavingsGoalEntity`, `ReceiptEntity`, dashboard/report aggregates, CSV export,
widget snapshots, and the AI context all use `double`. ~320 amount reads and
~140 constructor sites exist in `lib/` plus matching tests.

Rounding already happens in a few places (`WalletCalculator`, chart sums), but
comparisons such as budget thresholds and debt payoff schedules still operate on
approximate values.

## Domain type

```dart
final class Money implements Comparable<Money> {
  const Money(this.minorUnits);

  final int minorUnits;

  static const Money zero = Money(0);

  factory Money.fromMajor(num major) => Money((major * 100).round());
  factory Money.parse(String input, {required AppCurrency currency});

  double get major => minorUnits / 100;
  String format(AppCurrency currency);
  String toDecimalString(); // "1234.56" for PostgREST

  Money operator +(Money other);
  Money operator -(Money other);
  Money operator *(int factor);
  Money negate();
  bool operator <(Money other);
  ...
}
```

Rules:

- Parsing accepts `1.234,56` (COP) and `1,234.56` (USD) plus plain `1234.56`,
  strips currency symbols/spaces, and rejects more than two decimals.
- `fromMajor` exists only for legacy migrations and test fixtures; new code
  takes input through `parse`.
- Division produces a `double` only for rates/percentages, never for an amount.

## Entity changes

Money fields become `Money`:

- Transaction: `amount`
- Debt: `totalAmount`, `remainingAmount`, `minimumPayment`
- Receivable: `totalAmount`, `remainingAmount`, `payments[].amount`
- Budget: `monthlyLimit`
- Wallet: `openingBalance`; WalletTransfer: `amount`
- Scheduled payment: `amount`
- Savings goal: `targetAmount`, `contributions[].amount`
- Receipt: `totalAmount`, `items[].price`
- Dashboard/report aggregates, `CommittedCashflow`, payoff plans, and widget
  snapshots.

`interestRate`, `quantity`, percentages, savings rate, and FX-less comparisons
stay `double`/`num`.

## Persistence and migration

Local (Hive JSON):

1. Add `amountMinor: int` alongside the existing `amount` in every mapper and
   read `amountMinor` when present. Writing emits both during the transition.
2. A one-shot `MoneyMigrationService` (like `CalendarMigrationService`) rewrites
   every box: `minor = (amount * 100).round()`, then removes the legacy key only
   after the whole box is rewritten.
3. Once all reads use `Money`, stop writing the legacy `amount` key.

Remote (Supabase):

1. Migration `0009_money_minor.sql` adds `*_minor bigint` columns, backfills
   with `round(amount * 100)`, and keeps the numeric columns until clients
   upgrade.
2. Payloads send decimal strings derived from minor units (`toDecimalString`)
   and `*_minor` integers. Reads prefer `*_minor` and fall back to numeric.
3. After all supported clients write minor units, drop the numeric columns in
   `0010_drop_money_numeric.sql`.

## UI

- Text fields parse with `Money.parse` at the domain boundary; invalid input
  returns `ValidationFailure('amount_invalid')`.
- `MoneyText` and `MoneyFormatter` format `Money`, not `double`.
- Charts convert to `double` only at the rendering boundary.
- CSV export writes `toDecimalString`; CSV import parses through `Money.parse`.

## Rollout phases

1. `Money` type, parsing/formatting, property tests (associativity, rounding,
   COP/USD separators).
2. Transactions + dashboard + CSV (largest read surface).
3. Budgets, debts, receivables.
4. Wallets, schedules, savings, receipts.
5. Sync dual-write, remote backfill, then remove legacy fields.
6. Grep gate: no monetary `double` remains in `lib/features`.

Each phase keeps `flutter analyze`, unit coverage ≥90%, and the 37 integration
flows green before the next starts.

## Acceptance criteria

- `0.10 + 0.20` sums to exactly `0.30` in dashboard, reports, and budgets.
- A budget of `100.00` and spending of `99.995` in legacy data round-trips to
  `100.00` and does not trigger an alert.
- Debt payoff schedules use exact cents and sum to the original principal.
- Local data written before the update is migrated without loss; a rolled-back
  build can still read the dual-written payloads.
- Sync round-trips preserve cents on both COP and USD.
- No new `double` amount fields are introduced; review checks the grep gate.

## Risks

- Touching every feature in one branch is unsafe. Phases 2–4 must be separate
  atomic commits with their own integration runs.
- COP has no commonly used subunit; minor units are still stored as cents for a
  uniform type. Display never shows them.
- PostgREST numeric handling must be tested against the live project before
  removing the numeric columns.
