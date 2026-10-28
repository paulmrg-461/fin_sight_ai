# 037 — App lock with biometrics

**Priority:** P1 (privacy) · **Effort:** M · **Depends on:** 004 (i18n), 035 (onboarding flag)

## Problem

FinSight AI keeps every amount, note, and receipt path in local Hive boxes.
Anyone holding an unlocked phone can open the app and read them. There is no
opt-in lock and no way to require the device credential before the ledger
renders.

## Scope

- Opt-in app lock persisted in the settings box (`biometric_lock_enabled`).
- Lock the app on cold start and whenever it goes to the background, then
  require a successful biometric / device-credential prompt to reveal the UI.
- Show the device state in Settings: available → switch, unavailable →
  explanation, no switch action.
- Localize all copy in English and Spanish.
- Keep the feature testable: platform authentication sits behind
  `BiometricService`, the preference behind `SecurityPreferences`.

## Out of scope

- Encrypting Hive boxes at rest (tracked separately).
- Locking individual screens or hiding amounts.
- Server-side session revocation.

## Design

- `BiometricService` (`core/services`) wraps `local_auth`.
  `LocalAuthBiometricService` maps `canCheckBiometrics || isDeviceSupported`
  to `isAvailable()` and calls `authenticate` with
  `biometricOnly: false` (device PIN/pattern allowed) and
  `persistAcrossBackgrounding: true`. Errors return `false`; the app never
  crashes because a vendor plugin threw.
- `SecurityPreferences` stores the flag in the existing settings box. Reads and
  writes are best effort: a storage fault leaves the app unlocked instead of
  bricking startup.
- `SecurityCubit` holds `loading`, `enabled`, `available`. `load()` reconciles
  the stored flag with the device capability so a restored backup on a device
  without biometrics cannot lock the user out. `setEnabled` refuses to enable
  when unavailable and persists the result.
- `AppLockGate` wraps the router child inside `MaterialApp.router`'s `builder`,
  after `OnboardingGate`, so onboarding is not covered by the lock screen.
  It listens to the cubit, locks on first load when enabled, re-locks on
  `AppLifecycleState.paused`, and shows a themed lock screen with an explicit
  **Unlock** button. `_authenticating` blocks duplicate prompts.
- Settings shows a `SwitchListTile.adaptive` inside a security card. While the
  cubit is loading or the device is unsupported the switch is disabled.

## Platform

- `MainActivity` extends `FlutterFragmentActivity` (required by `local_auth`).
- `AndroidManifest.xml` declares `USE_BIOMETRIC`.

## Tests

- `security_cubit_test.dart`: load with a stored flag, load without device
  support, enabling persists, enabling without support is refused, authenticate
  delegates.
- `app_lock_gate_test.dart`: locks until authentication succeeds, skips locking
  when the preference is off, skips when biometrics are unavailable.
- Settings tests provide a `SecurityCubit` with no device support.
- Integration: `locks the app until biometrics succeed` uses the fake
  biometric service and asserts the dashboard stays hidden until unlock.

## Verification

```bash
flutter analyze
flutter test --coverage
dart run tool/check_coverage.dart
flutter test -d linux integration_test/app_flow_test.dart
```

## Risks

- A device that reports support but fails every prompt would lock the app on
  each launch. The lock screen always offers a retry, and disabling the flag
  from Settings requires being inside the app, so the user can recover by
  authenticating once.
- `local_auth` gates only presentation. Data at rest is still plaintext; the
  encryption work item remains open.
