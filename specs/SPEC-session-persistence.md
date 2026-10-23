# Spec: session persistence and renewal

## Objective

Keep the user signed in across restarts for **at least two months**, including
offline launches, and stop treating transient network failures as a logout.

## Server requirement

Supabase GoTrue owns refresh-token lifetime. The app cannot extend it. The
project must configure:

- **Authentication → Sessions → Refresh token expiry**: 60 days or longer.
- Access token (JWT) expiry may stay at the default 1 hour.

This setting is documented in `README.md` and `supabase/README.md`; changing it
requires dashboard/management access and is not a client code change.

## Client behavior

`AuthRepository.restoreSession()`:

- no stored session → `Right(null)`.
- stored access token still valid → return it.
- access token expired → refresh:
  - success → persist the rotated session, update the local-data owner, return it.
  - **transient** failure (`auth_timeout`, `auth_network_error`,
    `auth_not_configured`, `auth_http_429`, `auth_http_5xx`) → keep the stored
    session and return it, so the app opens offline in a signed-in state.
  - **permanent** rejection (`auth_http_400`, `auth_http_401`,
    `auth_invalid_response`) → clear only the stored token/session; keep the
    local ledger and owner so a later login can reclaim it.

Session renewal:

- A session observer refreshes on `AppLifecycleState.resumed` when the current
  state is authenticated.
- While authenticated, a timer fires five minutes before `expiresAt` and
  triggers a refresh; it is rescheduled if the refresh rotates the session.
- The timer is cancelled on unauthenticated/error states and on dispose.

Sign-out remains explicit, confirmed, and erases local data per plan 002.

## Tests

- Repository: transient refresh failure keeps the session and does not clear
  storage; 400/401 clears storage; successful refresh rotates tokens.
- Observer: resume dispatches `RestoreAuthSession` only when authenticated;
  timer schedules/cancels on state changes.
- Integration: a stored expired session + transient refresh failure still
  renders the authenticated shell, and a later refresh succeeds.
