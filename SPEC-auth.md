# Spec: Supabase authentication

## Objective

Authenticate with Supabase Auth (email/password), persist the session securely, refresh expired tokens, and authorize PostgREST synchronization with the user's JWT.

## Session

`AuthSession`: `accessToken`, `refreshToken`, `userId`, `email`, `expiresAt`. `isExpired` compares against the clock.

## Repository

```dart
ResultFuture<AuthSession> signIn({required String email, required String password});
ResultFuture<AuthSession> signUp({required String email, required String password});
ResultFuture<AuthSession?> restoreSession();
ResultFuture<void> signOut();
String? get accessToken;
bool get isAuthenticated;
```

## Use cases

- `SignInUseCase` / `SignUpUseCase` validate email format and a minimum 6-character password.
- `RestoreSessionUseCase` restores from secure storage and refreshes expired tokens.
- `SignOutUseCase` clears the local session even when the network call fails.

## Data

- `SupabaseAuthDataSource` uses GoTrue REST:
  - `POST /auth/v1/token?grant_type=password`
  - `POST /auth/v1/signup`
  - `POST /auth/v1/token?grant_type=refresh_token`
  - `POST /auth/v1/logout`
- `AuthSessionModel` JSON mapping.
- `SecureSessionStorage` persists JSON in platform secure storage (`flutter_secure_storage`), with a `withStorage` test seam.
- Error codes: `auth_not_configured`, `auth_invalid_credentials`, `auth_signup_failed`, `auth_email_confirmation_required`, `auth_invalid_response`, `auth_timeout`, `auth_network_error`, `auth_http_<status>`.
- `AuthFailure` is the domain failure for auth operations.

## Presentation

- `AuthBloc`: restore, sign-in, sign-up, sign-out; states initial/loading/authenticated/unauthenticated/error.
- `LoginScreen`: email/password form, sign-in/sign-up toggle, inline errors, secure-password visibility toggle.
- `AccountButton` in the dashboard AppBar opens login or signs out.
- Successful login triggers `SyncNow`; startup restores the session and syncs when authenticated.

## Sync integration

- `SupabaseRestSyncDataSource` sends `Authorization: Bearer <accessToken>`; the anon key remains in `apikey`.
- Without a session, sync returns an offline report and the chip says “Sign in to sync”.
- RLS relies on `auth.uid()`; see `supabase/migrations/0001_init.sql`.

## RLS verification

- `supabase/tests/rls_test.sql` creates two JWT subjects and asserts isolation for select/update/delete.
- `supabase/verify_rls.sh` runs the script against a real `SUPABASE_DB_URL`.
- CI cannot run it without project credentials; run it as a protected deployment check.

## Verification

```bash
flutter analyze
flutter test --coverage
```
