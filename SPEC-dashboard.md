# Spec: Dashboard analytics

## Objective

Aggregate transaction data into a financial summary, category breakdown, monthly comparison, and recent activity for a selected period.

## Entities

`DashboardSummaryEntity`: `totalIncome`, `totalExpenses`, `balance`, `savingsRate` (percent), `monthOverMonthChange` (percent).

`CategoryBreakdown`: `category`, `amount`, `percentage` of expenses.

`MonthlyComparisonEntity`: current/previous income and expenses, plus `expenseChangePercentage`.

## Repository

```dart
ResultFuture<DashboardSummaryEntity> getDashboardSummary({required DateTime start, required DateTime end});
ResultFuture<List<CategoryBreakdown>> getCategoryBreakdown({required DateTime start, required DateTime end});
ResultFuture<MonthlyComparisonEntity> getMonthlyComparison({required DateTime start, required DateTime end});
```

`DashboardRepositoryImpl` aggregates from `TransactionRepository` and derives the previous month from `start` (UTC/local preserved).

## Calculation rules

- Income and expenses are summed by transaction type.
- `balance = income - expenses`.
- `savingsRate = income > 0 ? (balance / income) * 100 : 0`.
- `monthOverMonthChange` compares current vs previous expenses: `100%` when the previous month is zero and current is positive, otherwise `(current - previous) / previous * 100`.
- Category percentages use total expenses; results are sorted by amount descending and rounded to 2 decimals.
- Empty periods produce zeroed summaries / empty breakdowns.

## Use cases

`GetDashboardSummaryUseCase`, `GetCategoryBreakdownUseCase`, `GetMonthlyComparisonUseCase` — reject `start > end` with `ValidationFailure(invalid_date_range)`.

## Presentation

`DashboardBloc` events: `LoadDashboard`, `RefreshData`, `ChangeDateRange`.

States: initial, loading, loaded (summary, breakdown, comparison, recent 5 transactions, range), empty, failure. Default range is the current month.

`DashboardPage`:
- Summary cards: income, expenses, balance, savings rate.
- `CategoryPieChart` with legend (fl_chart).
- `MonthlyComparisonChart` comparing current vs previous expenses.
- `RecentTransactionsList`.
- Pull-to-refresh, date-range picker, theme toggle, quick actions to every feature.
- Empty state with a CTA to add the first transaction.

## Verification

```bash
flutter analyze
flutter test --coverage
```
