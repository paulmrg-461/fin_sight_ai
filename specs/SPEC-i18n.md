# Spec: internationalization (English / Spanish)

## Objective

Ship the app in **English** and **Spanish**, with a persisted language preference and a default that follows the device locale.

## Supported locales

| Locale | Name | ARB |
| --- | --- | --- |
| `en` | English | `lib/l10n/app_en.arb` |
| `es` | Español | `lib/l10n/app_es.arb` |

Fallback is the system locale. Unsupported device locales resolve to English.

## Configuration

- `l10n.yaml` points at `lib/l10n` and generates `AppLocalizations`.
- `flutter: generate: true` in `pubspec.yaml`; `flutter_localizations` provides the Material/Cupertino delegates.
- `lib/core/l10n/l10n.dart` exports the generated API, defines `context.l10n`, and composes `appLocalizationsDelegates` from `AppLocalizations.delegate` plus `GlobalMaterialLocalizations.delegates` (the `material_ui`/`cupertino_ui` implementations required by Flutter 3.50+).
- Generated localization files are excluded from analyzer warnings.

## Persistence

- `LocaleRepository` backed by the Hive `settings` box under the `locale` key.
- Values: `system` (default), `en`, `es`. Invalid stored values fall back to the system locale.
- `GetLocaleUseCase` returns the stored locale; read errors fall back to the system locale.
- `SetLocaleUseCase` persists the choice and maps write errors to `CacheFailure(code: locale_write_failed)`.

## Presentation

- `LocaleBloc`: `LoadLocale` and `ChangeLocale`; states `LocaleInitial`, `LocaleLoaded`, `LocaleFailure`.
- `FinSightApp` rebuilds `MaterialApp.router` with the selected `locale`, `appLocalizationsDelegates`, and `AppLocalizations.supportedLocales`.
- `SettingsScreen` (`/settings`) shows a System / English / Español segmented control below the currency section and describes that System follows the device.
- All user-facing text in dashboard, transactions, wallets, debts, budgets, OCR, AI coach, auth, sync indicators, and settings comes from `AppLocalizations`.

## Localized content boundaries

- Currency labels are localized (e.g. `COP — Peso colombiano`), but amounts are never converted.
- Domain `Failure` messages and AI-generated insight text remain in English; screens render their own localized copy for known failures.
- Dates use the locale-independent `DD/MM/YYYY` formatter.

## Tests

- Repository: defaults, persistence, reset to System, invalid values.
- Use cases and `LocaleBloc`: load, change, read/write failures, value equality.
- Widget: settings selector switches language and renders failures.
- Integration: switching English → Español → English updates the visible UI.
- Coverage gate must remain ≥ 90% for core and domain/data layers.
