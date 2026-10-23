# Spec: money wallets and transfers

## Objective

Show how much money the user has, split between a bank account and cash, let them reconcile the actual balance, and move money from the account to cash.

## Entities

`WalletEntity extends Entity`: `id`, `name`, `type` (`bank`/`cash`), `openingBalance`, `currency`, `updatedAt`.

`WalletTransferEntity extends Entity`: `id`, `fromWalletId`, `toWalletId`, `amount`, `date`, `note`, `createdAt`.

`WalletBalance`: wallet plus the computed current balance.

## Calculation

`WalletCalculator.balances`:

- Start from each wallet's `openingBalance`.
- Add incomes / subtract expenses whose `walletId` matches.
- Transactions without a `walletId` belong to the default bank wallet.
- Subtract outgoing transfers and add incoming transfers.
- Round to 2 decimals.

## Defaults

On first load the repository creates two stable wallets:

- `wallet-bank` — “Cuenta principal” (`bank`).
- `wallet-cash` — “Efectivo” (`cash`).

## Repository

```dart
ResultFuture<List<WalletBalance>> getWalletBalances();
ResultFuture<WalletBalance> setWalletBalance({required String walletId, required double target});
ResultFuture<WalletTransferEntity> transfer({
  required String fromWalletId,
  required String toWalletId,
  required double amount,
  required DateTime date,
  String note = '',
});
```

- `setWalletBalance` reconciles by adjusting `openingBalance` by `target - current`.
- `transfer` validates the source balance and rejects insufficient funds.

## Data

- Hive boxes `wallets` and `wallet_transfers`.
- `WalletModel` / `WalletTransferModel` JSON mapping.
- `WalletRepositoryImpl` aggregates from `TransactionRepository`.

## Presentation

- `WalletBloc`: load, set balance, transfer.
- `WalletScreen`: total available, bank/cash cards, reconcile dialog, transfer dialog.
- Route `/money` + dashboard quick action.
- Transaction form selects the destination wallet; `walletId` is persisted and synced.

## Sync scope

Transaction `walletId` is included in the remote schema (`0004_wallet_ids.sql`).
Wallet definitions and transfers are local-only for now; default wallet ids are stable so synced transactions still map correctly.

## Tests

Calculator, entities/models, Hive data source, repository aggregation/reconciliation/insufficient funds, use cases, and BLoC transitions.
