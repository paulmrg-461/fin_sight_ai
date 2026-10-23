# Spec: integration tests

## Objective

Verify the complete FinSight AI user journey with the real widget graph, real Hive persistence, and deterministic fakes for external services.

## Harness

`integration_test/support/harness.dart` builds the production dependency graph manually:

- Real Hive boxes (`transactions`, `debts`, `receipts`) in a temp directory.
- Real repositories, use cases, blocs, router, and theme controller.
- `FakeOcrDataSource`, `FakeGroqDatasource`, `FakeReceiptImagePicker`, and a fake auth repository (no real Supabase project).

External networks and platform plugins are never invoked. ML Kit, Groq, and image picking are replaced at their interfaces.

## Scenarios

1. Empty dashboard with quick actions.
2. Add income through the form; dashboard summary updates on return.
3. Scan a receipt with the fake picker/OCR; save it; an expense transaction is created automatically and the dashboard updates.
4. Add a debt through the form; the card appears with repayment progress.
5. Request AI insights; the mocked suggestion renders.
6. Add a budget and verify category spending progress.
7. Sign in and out through the dashboard account button.
8. Filter transactions by date range; only matching records remain.
9. Manage bank/cash balances: reconcile the bank balance, transfer to cash, and switch COP → USD.
10. Restart persistence: close boxes/blocs, reopen the same Hive directory, rebuild the app, and verify transactions, debts, receipts, wallets, and currency survive.
11. Performance smoke benchmarks for launch/dashboard and transactions render.

## Commands

```bash
flutter test -d linux integration_test/app_flow_test.dart
```

The benchmark output is printed as:

```text
BENCHMARK app_launch_and_dashboard=<ms>ms
BENCHMARK transactions_render=<ms>ms
```

Thresholds: launch/dashboard `< 5000ms`, transactions render `< 3000ms`.

## Fakes

- OCR text: `ACME MARKET`, two items, `TOTAL $25.50`.
- Groq response: `{"type":"suggestion","content":"Automate 10% of your income."}`.
- Image picker: stable `/tmp/fake-receipt.jpg`.
- Auth: any valid email + 6-character password signs in with a synthetic session.
- Currency: starts at COP; the Money test switches to USD through Settings.

## Verification

```bash
flutter analyze
flutter test --coverage
flutter test -d linux integration_test/app_flow_test.dart
```
