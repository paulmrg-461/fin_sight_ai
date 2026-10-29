# 047 — Developer profile and legal attribution

**Priority:** P2 · **Effort:** S/M · **Status:** DONE

## Goal

Give the product a human face and a clear ownership trail, inspired by the
`loans_devpaul` developer screen but rebuilt in the FinSight design language:
brand gradient, icon sections, brand social icons, and localized copy.

## Page

Route `/developer` (`developerName`), reachable from:

- Drawer → **About the developer**
- Settings → **About the developer** card with the DevPaul logo
- Login → legal footer button
- Drawer copyright caption

Contents:

- Gradient hero: DevPaul logo, name, role, and app version (`package_info_plus`
  with a safe fallback).
- **About me** card with a short, privacy-first bio.
- **Find me online**: GitHub, LinkedIn, Facebook, X, Instagram (brand SVGs) and
  devpaul.pro (Material globe), plus a tonal website button.
- Legal footer: `© {year} DevPaul. All rights reserved.`.

## Links and safety

- `LinkLauncher` isolates `url_launcher` and validates `http`/`https` only.
- Failures and platform refusals surface a localized snackbar.
- Social rows meet the 48 dp touch target and expose a tooltip/semantic label.

## Attribution placement

- Developer page footer (year + rights).
- Settings footer (short legal line).
- Drawer bottom caption, tappable to the profile.
- Login screen footer button.

## Assets and dependencies

- `assets/branding/devpaul_logo.jpeg` and `assets/social/*.svg` (copied from the
  user's existing brand assets).
- New dependencies: `url_launcher`, `package_info_plus`, `flutter_svg`.

## Tests

- `link_launcher_test.dart`: schemes, refusals, platform errors.
- `developer_info_screen_test.dart`: profile, version, six links, website CTA,
  failure snackbar. Uses an injected fake launcher and version loader.
- Integration: open the profile from the drawer and assert the identity and
  legal notice.
- Drawer golden regenerated with the new entry and copyright caption.

## Verification

`flutter analyze`, **1154** unit/widget tests, coverage gate, **39** integration
flows, debug APK build.
