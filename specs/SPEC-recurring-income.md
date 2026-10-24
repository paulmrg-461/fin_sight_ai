# Spec: recurring income (salary)

## Objective

Let the user define a fixed monthly (or yearly) income — typically salary — so
the app knows the expected amount and payday, records the income automatically
when due, and shows the expected monthly income.

## Model change

`ScheduledPaymentEntity` gains a `type`:

| Field | Values | Default |
| --- | --- | --- |
| `type` | `TransactionType.expense` / `TransactionType.income` | `expense` |

Existing persisted schedules without `type` deserialize as **expense** (no
migration required). All other fields (`name`, `amount`, `category`,
`frequency`, `nextDueDate`, `dayOfMonth`, `walletId`, `notes`, `isActive`)
are unchanged.

## Behavior

- Due processing creates a transaction with the schedule's `type`. Income
  schedules create `TransactionType.income`; expenses keep the current behavior.
- The deterministic UUID v5 per `(schedule, dueDate)` and the same-day pay guard
  apply to both types.
- “Pay now” records the schedule's type immediately and advances the date.
- Paused income schedules never auto-record.
- The scheduled screen shows an **Expected monthly income** card when at least
  one active income schedule exists:
  - monthly schedules count their full amount;
  - yearly schedules count `amount / 12`;
  - total is rounded to 2 decimals;
  - the card shows the next income date.
- Dashboard/budgets/wallets only see the income when the transaction is
  generated, matching the existing “no forward projection” decision.
- Generated income transactions sync through the normal transaction pipeline.

## UI

- Add form: segmented Expense / Income above the amount.
- Category selection: default to `Salary`/`Salario` for income when present,
  otherwise the first active category.
- Card: income entries show a leading `+` and the primary/green amount color;
  expense entries keep the current appearance. A small “Income” chip/label
  distinguishes them.
- Screen header card: `Expected monthly income`, amount, and next date.
- Drawer/bottom label stays “Scheduled” / “Programados”.

## Localization

New keys: `incomeSchedule`, `expectedMonthlyIncome`, `nextIncome`,
`incomeType`. Reuse `income`, `expense`, `scheduledPayments`.

## Tests

- Domain: `isIncome`, copyWith/equality.
- Model: missing `type` reads as expense; income round-trips.
- Repository: due processing and pay-now create income transactions with the
  right type; deterministic ids remain stable.
- Calculator: monthly + yearly/12, ignores paused, next date.
- BLoC/widget: form can save income; card/summary render.
- Integration: create a salary due today → income appears in Transactions and
  dashboard income total; the existing expense flow still passes.
