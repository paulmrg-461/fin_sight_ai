# Spec: debts

## Objective

Track debts, record payments, visualize repayment progress, and project a payoff date using compounded monthly interest.

**Success criteria**

- Users can add debts with creditor, total, remaining balance, annual interest rate, minimum payment, and due date.
- Invalid terms (non-positive totals/payments, negative or > 100% rates, remaining outside the total) are rejected.
- Payments reduce the balance, are recorded in history, and mark the debt paid at zero.
- Overpayments clamp to the remaining balance; zero/negative payments are rejected.
- The payoff calculator returns a date when the payment covers interest, otherwise `null`.
- Every behavior is covered by unit, data, and BLoC tests.

## Entity

`DebtEntity extends Entity`

| Field | Type | Rules |
| --- | --- | --- |
| `id` | `String` | UUID v4 |
| `creditorName` | `String` | Trimmed, non-empty |
| `totalAmount` | `double` | Finite, `> 0` |
| `remainingAmount` | `double` | `[0, totalAmount]` |
| `interestRate` | `double` | Annual %, `0..100` |
| `minimumPayment` | `double` | Finite, `> 0` |
| `dueDate` | `DateTime` | Displayed and used for ordering |
| `status` | `DebtStatus` | `active` / `paid` |
| `paymentHistory` | `List<PaymentRecord>` | Appended on payment |

Derived: `paidAmount`, `progress` (`0..1`), `isPaid`.

## Repository

```dart
ResultFuture<DebtEntity> addDebt(DebtEntity debt);
ResultFuture<DebtEntity> updateDebt(DebtEntity debt);
ResultFuture<void> deleteDebt(String id);
ResultFuture<List<DebtEntity>> getDebts();
ResultFuture<DateTime?> calculatePayoffDate(DebtEntity debt, {double? monthlyPayment});
```

## Payoff algorithm

`DebtPayoffCalculator` applies monthly compounding:

```text
monthlyRate = annualInterestRate / 100 / 12
while balance > 0:
  interest = balance * monthlyRate
  if monthlyPayment <= interest: return null
  balance += interest - monthlyPayment
  months++
```

Zero balance returns the reference date; monthly payments are clamped conceptually by the use case.

## Use cases

- `AddDebtUseCase` — validates terms and generates an id.
- `GetDebtsUseCase` — returns debts ordered by due date.
- `MakePaymentUseCase` — validates payment, loads the debt, clamps, records history, updates status.
- `DeleteDebtUseCase` — rejects blank ids.
- `CalculatePayoffUseCase` — rejects non-positive override payments, delegates to the repository.

## Data

- `DebtModel extends DebtEntity` with JSON round-trip including payment history.
- `HiveDebtLocalDataSource` stores JSON maps keyed by id, ordered by due date.
- `DebtRepositoryImpl` maps storage exceptions to `CacheFailure`.

## Presentation

`DebtBloc` events: `LoadDebts`, `AddDebt`, `MakePayment`, `DeleteDebt`, `CalculatePayoff`.

States: `DebtInitial`, `DebtLoading`, `DebtLoaded` (optionally with `PayoffEstimate`), `DebtEmpty`, `DebtFailure`.

Screens/widgets: `DebtListScreen` (progress cards), `AddDebtScreen` (validated form), `DebtDetailScreen` (history, payment, payoff calculator, delete), `DebtCard`, `PaymentHistoryList`.

## Verification

```bash
flutter analyze
flutter test --coverage
```
