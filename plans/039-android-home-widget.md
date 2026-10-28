# 039 — Android home-screen widget

**Priority:** P2 · **Effort:** M · **Depends on:** 010 (single dashboard read), 021 (summary)

## Problem

Users must open FinSight AI to see their month. A home-screen widget with the
current balance and spend makes the ledger glanceable without unlocking the
whole app experience.

## Scope

- A resizable Android AppWidget showing the balance, monthly spend, and
  currency for the current dashboard period.
- Tapping the widget opens the app.
- The app publishes a snapshot after every successful dashboard load; failures
  are silent and never affect the ledger.
- English labels; values come pre-formatted in the active COP/USD format.

## Out of scope

- iOS/macOS/Windows widgets.
- Per-widget configuration, charts, or category breakdowns.
- Background refresh while the app is closed (the widget re-renders the last
  snapshot every 30 minutes).

## Design

- `lib/core/services/widget_data_bridge.dart` defines `WidgetDataBridge` and a
  `DashboardWidgetSnapshot`. `AndroidWidgetDataBridge` reads the persisted
  currency and sends pre-formatted strings over
  `devpaul.fin_sight_ai/widget`, swallowing missing-plugin and vendor errors.
- `DashboardBloc` takes an optional `WidgetDataBridge`. After emitting
  `DashboardLoaded` it publishes the summary balance and expenses; a bridge
  failure is caught so the dashboard state is unaffected. Tests construct the
  bloc without a bridge, so existing suites are untouched.
- `MainActivity` handles the channel, writes to the `fin_sight_widget`
  SharedPreferences file (`WidgetStore`), and broadcasts an update.
- `FinanceWidgetProvider` (RemoteViews) reads the snapshot, localizes the
  "Spent" label through `strings.xml`, and opens `MainActivity` on tap.
- Resources: `finance_widget.xml` layout, `widget_background.xml` gradient,
  `finance_widget_info.xml` (4×2 cells, resizable, 30-minute refresh), and the
  manifest receiver with `APPWIDGET_UPDATE`.

## Tests

- `widget_data_bridge_test.dart`: COP/USD formatting, channel payload, and
  graceful no-channel behavior.
- `dashboard_bloc_test.dart`: publishes balance/expenses after a load and keeps
  the loaded state when the bridge throws.
- `flutter build apk --debug` compiles the Kotlin provider and resources.

## Verification

```bash
flutter analyze
flutter test --coverage
dart run tool/check_coverage.dart
flutter test -d linux integration_test/app_flow_test.dart
flutter build apk --debug --dart-define-from-file=.env
```

## Manual check

Install the APK, long-press the home screen, add **FinSight AI · This month**,
open the app once, and confirm the widget shows the same balance and spend as
the dashboard. Tapping it must return to the app.

## Risks

- Widget text is pre-formatted in Dart, so currency switches only reach the
  widget after the next dashboard load.
- The snapshot lives in plain SharedPreferences. It contains only month totals,
  not notes or merchant data.
