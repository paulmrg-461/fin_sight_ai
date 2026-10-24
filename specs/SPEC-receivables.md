# Spec: receivables (“Me deben”)

## Objective

Track money the user has lent and is owed back: who owes it, how much, partial
payments, due dates, and the total still outstanding.

## Model

`ReceivableEntity`:

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | UUID v4 |
| `debtorName` | `String` | Required, trimmed, ≤ 120 chars |
| `totalAmount` | `double` | Amount lent, > 0, 2 decimals |
| `remainingAmount` | `double` | `0..totalAmount` |
| `dateLent` | `DateTime` | Calendar date, required |
| `dueDate` | `DateTime?` | Optional agreed payback date |
| `notes` | `String` | Optional, ≤ 500 chars |
| `status` | `ReceivableStatus` | `active` / `paid` |
| `paymentHistory` | `List<ReceivablePayment>` | Abonos received |
| `createdAt` / `updatedAt` | `DateTime` | Audit |

`ReceivablePayment`: `id`, `amount`, `paidAt`, optional `note`.

Derived values: `paidAmount`, `progress` in `[0,1]`, `isPaid`.

## Rules

- Adding validates debtor, amount, dates, notes.
- A payment must be > 0; it is clamped to the remaining amount. Full payment
  marks the receivable paid.
- Payments never create income transactions or touch wallets (consistent with
  the existing debts module); they only update the receivable.
- Deleting removes the receivable and its history (local-only).
- Receivables are **local-only** in this slice; sync is a documented follow-up.
- List order: active first, then by due date/date lent; paid entries after.

## Persistence

- Hive `receivables` box, JSON maps, `HiveReceivableLocalDataSource`.
- Repository maps `CacheException` to `CacheFailure`; no sync queue.

## Presentation

- `/receivables` screen:
  - gradient hero with **total outstanding** and active count;
  - cards with debtor avatar, remaining/total, progress bar, due date/status,
    “Abonar”, and delete;
  - empty/error states use the shared design-system widgets;
  - responsive `AppContent`.
- Add dialog/screen: debtor, amount, date lent, optional due date, notes.
- Detail screen: summary, info rows, payment history, add payment, delete.
- Payment dialog: amount + optional note, localized validation.
- Dashboard: a compact “Me deben” card with total/count linking to the module.
- Drawer “Más” group: “Me deben”.
- Dashboard quick action: “Me deben”.

## Localization

New keys include `receivablesTitle`, `owedToMe`, `owedToMeBody`,
`addReceivable`, `debtorName`, `amountLent`, `dateLent`, `dueDateOptional`,
`remainingAmount`, `received`, `addPayment`, `paymentHistory`, `noReceivables`,
`noReceivablesBody`, `peopleOweYou(count)`, `markPaid`, `receivablePaid`,
`deleteReceivable`, `debtorRequired`, `invalidLentAmount`, `paymentTooHigh`,
`noPaymentsReceived`, `receivableDetails`.

## Tests

- Entity/payment/progress/equality.
- Model legacy/JSON round-trip.
- Repository CRUD/payment/clamping/failure mapping with temp Hive.
- Use cases validation and payment behavior.
- BLoC states/actions.
- Widget flow and integration: add → pay partial → remaining/progress changes →
  dashboard total → restart persistence.
- Coverage ≥ 90% for domain/data.
