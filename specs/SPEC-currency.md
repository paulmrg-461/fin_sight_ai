# Spec: currency configuration

## Objective

Use **COP (Colombian peso)** by default and let the user switch the app to **USD**, persistently and app-wide.

## Currency model

`AppCurrency { cop, usd }`:

| Currency | Code | Locale | Label |
| --- | --- | --- | --- |
| COP | `COP` | `es_CO` | COP — Peso colombiano |
| USD | `USD` | `en_US` | USD — US Dollar |

`MoneyFormatter` uses `intl.NumberFormat.currency` with 2 decimals and supports signed values.

**No exchange-rate conversion is applied.** Switching currency changes labels/formatting only; the stored numeric amounts are unchanged.

## Persistence

- `CurrencyRepository` backed by the Hive `settings` box.
- Missing/invalid values fall back to COP.
- `GetCurrencyUseCase` / `SetCurrencyUseCase`.

## Presentation

- `CurrencyBloc`: load and change currency.
- `MoneyText` renders all monetary amounts with the active currency.
- `SettingsScreen` (`/settings`) exposes a COP/USD segmented control and explains that no conversion happens.
- Dashboard settings icon opens the screen.

## Applied surfaces

Transactions, dashboard summary/recent activity, budgets, debts, OCR/receipt previews, and the Money screen use `MoneyText`.

## Tests

Formatter output for both locales, persistence/defaults, use cases, BLoC, `MoneyText`, and the settings screen.
