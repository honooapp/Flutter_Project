# AGENTS GUIDE

Essentials for developing and maintaining **honoo** with the current architecture, toolchain, and workflows.

---

## 1. Project Snapshot

| Item            | Details                                                                |
|-----------------|-------------------------------------------------------------------------|
| Framework       | Flutter 3.10.0 (stable) + Dart 3.0.0                                    |
| Targets         | Web (primary), Android/iOS/Desktop supported via Flutter scaffolding    |
| Backend         | Supabase (PostgreSQL + Auth + Storage)                                  |
| Design Language | Typography via Google Fonts (Lora), extensive SVG assets               |
| Git Branches    | `main` (source), `gh-pages` (built site), feature branches as needed    |

---

## 2. Domain Concepts

### Honoo
* Short multimedia “cards” (text ≤ 144 chars, centered typography, square image).
* Managed via `HonooBuilder`, persisted to Supabase table `honoo`.
* `HonooController` caches the user’s scrigno (chest) locally.

### Hinoo
* Long-form narrative (up to 21 lines) + background image.
* Currently single page, but legacy multi-page logic still present — leave branching intact.
* Builder flow (`lib/UI/hinoo_builder.dart` + `Pages/new_hinoo_page.dart`) enforces:
  - Background image uploaded and confirmed.
  - Text length / line constraints.
  - Optional duplication to moon (`HinooService.duplicateToMoon`).

Keep both models aligned with Supabase JSON structure (`pages` array on `hinoo` table). Do not change schema lightly; migrations live in `supabase/`.

---

## 3. Repository Layout Highlights

```
lib/
  Controller/        // Business logic & caches (Honoo, Hinoo, device helpers, Nim mini-game)
  Entities/          // Data models mirroring Supabase rows
  Pages/             // Flutter screens (login, chest, moon, hinoo builder, etc.)
  UI/                // Reusable widgets (Honoo/Hinoo builders, viewers)
  Widgets/           // Shared components (dialogs, scaffolds, custom inputs)
  Utility/           // Styling, layout helpers, text formatters
  env/               // Environment loader (web vs io)
integration_test/    // Live Supabase end-to-end check (optional, gated)
test/                // Unit / widget tests + Supabase REST smoke tests
.github/workflows/   // Supabase QA + Pages deploy pipelines
live.env             // Local helper values for live integration tests (keep private)
```

---

## 4. Environment & Config

* **Web runtime**: Only `SUPABASE_URL` and `SUPABASE_ANON_KEY` are read via `env/env.dart`. Use `--dart-define` or CI secrets.
* **Local dev**:
  ```bash
  ~/Applications/flutter/bin/flutter run -d chrome \
    --dart-define=SUPABASE_URL=https://<staging>.supabase.co \
    --dart-define=SUPABASE_ANON_KEY=<anon>
  ```
* **Integration tests** (optional): Populate `live.env` or pass HONOO\_\* defines. Includes staging user email/password — **never commit real credentials**.
* **Supabase CLI** (optional): `supabase start` provides a local stack; apply migrations from `supabase/`.

---

## 5. Supabase Practices

* Only use the **anon key** in Flutter code (already public). Anything requiring elevated privileges belongs in server-side tooling.
* Respect Row Level Security (RLS). Builders assume:
  - Authenticated user can insert/update their own honoo/hinoo rows.
  - Anonymous actions are limited (moon/public fetch).
* `HinooService` and `HonooService` centralise network calls — extend them instead of scattering `Supabase.instance.client` usage.
* Storage uploads:
  - Hinoo backgrounds via `HinooStorageUploader.uploadBackground`.
  - Ensure user is authenticated before invoking; builder already blocks unauthenticated tries with toasts.

---

## 6. Builder Flows & Validation

### Hinoo (single screen)
1. `CambiaSfondoOverlay` → pick image, upload to storage.
2. Confirm (`_confirmBgAndLock`) once upload completes (spinner hides).
3. Pick text color.
4. Write text (`ScriviHinooOverlay`), enforced by `CenteringMultilineField`.
5. Save → `HinooController.saveToChest` after validation:
   - At least one page (today: exactly one).
   - ≤ 9 pages (legacy guard).
   - Each page has background + non-empty text.

### Honoo
* Similar flow but constrained to short text; see `HonooBuilder`.
* Upload uses `HonooImageUploader` (PNG target size for square cards).

When editing flows, maintain existing guards and toasts; they prevent silent failures when Supabase is unreachable or user is logged out.

---

## 7. Testing Strategy

| Suite                               | Command / trigger                             | Notes                                              |
|------------------------------------|-----------------------------------------------|----------------------------------------------------|
| Static analysis                    | `flutter analyze`                             | Must be clean; pipeline fails on warnings.         |
| Unit / widget tests                | `flutter test`                                | Some tests mock Supabase via `mocktail`.           |
| Supabase REST smoke (staging)      | `tool/run_supabase_readonly_staging.sh`       | Requires staging secrets. Runs in CI.              |
| Supabase CRUD (manual)             | `tool/run_supabase_crud_staging.sh`           | Enable `ENABLE_WRITE_TESTS=1` consciously.         |
| Live integration (optional E2E)    | `flutter test integration_test/...` + defines | Only when HONOO\_\* vars are supplied.             |

Golden tests rely on `test/test_config.dart` (fixes DPI). If fonts cause 400s, pre-cache via `google_fonts` recommendations.

---

## 8. Deployment

* **GitHub Pages** is the hosting surface.
  - New workflow: `.github/workflows/deploy-gh-pages.yml`.
  - Triggers: push tags `v*` or manual dispatch.
  - Steps: checkout → Flutter 3.10.0 → `flutter build web --release` → add `CNAME` (`honoo.it`) → deploy via `peaceiris/actions-gh-pages`.
  - Secrets needed: `PROD_SUPABASE_URL`, `PROD_SUPABASE_ANON_KEY`.
* For manual builds, `build/web` mirrors what peanut produced previously. Keep the base href at `/` because `gh-pages` has a `CNAME`.
* Ensure DNS for `honoo.it` points the apex to GitHub Pages IPs.

---

## 9. CI Workflows

* **Supabase Tests (`supabase-tests.yml`)**
  - `push` to `main` and every PR.
  - Jobs: analysis + staging read-only suite, optional CRUD (manual).
* **Deploy to Pages (`deploy-gh-pages.yml`)**
  - `push` tags `v*`, or manual.
  - Produces `gh-pages` build.

Keep workflows in sync with Flutter version upgrades — both install Flutter 3.10.0 via `subosito/flutter-action`.

---

## 10. Coding Notes & Conventions

* File naming is now snake_case (Linux build requires it).
* Many widgets use Google Fonts; include fonts in assets if offline tests fail.
* `CenteringMultilineField` handles text layout; touch carefully (builder UX depends on it).
* Avoid `Platform.environment` directly in lib/ — use `env/env.dart`.
* `supabase_provider.dart` exposes `SupabaseProvider.client`; override in tests via `SupabaseProvider.overrideForTests`.
* Nim mini-game (`Controller/nim_controller.dart`, `nim_game.dart`, `Pages/nim_page.dart`) is a self-contained feature; leave unchanged unless required.

---

## 11. Security & Secrets

* Public repo: remove or encrypt `live.env` if it ever contains real credentials. Prefer CI secrets for deployment/login tests.
* Supabase anon key is public, but RLS must prevent unauthorized access.
* Never commit service role keys or password lists.

---

## 12. Quick Start Checklist (New Work Session)

1. `git pull` latest `main`.
2. Confirm Flutter 3.10.0 is active (`flutter --version`).
3. `flutter pub get`.
4. Run `flutter analyze`.
5. Launch web app with correct `--dart-define` values.
6. Implement feature / fix, keeping builders’ validation intact.
7. Add / update tests where applicable.
8. `flutter test` and (if relevant) run Supabase smoke suite.
9. Commit with clear message; open PR targeting `main`.
10. Tag release (`git tag vYYYY-MM-DD && git push --tags`) when ready; Pages deploy workflow will publish.

---

## 13. Useful Commands

```bash
# Static analysis
flutter analyze

# Run tests
flutter test

# Supabase read-only suite (staging)
SUPABASE_URL=... SUPABASE_ANON_KEY=... \
TEST_IMAGE_URL=... ./tool/run_supabase_readonly_staging.sh

# Web build with defines
flutter build web --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...

# Manual deploy trigger (if needed)
git tag v2025-10-14            # use date-based tags
git push --tags
# If the tag already exists, append suffixes: v2025-10-14.1, .2, ...
```

---

### Keep this document updated when:
* Flutter or Supabase SDK versions change.
* Deployment strategy is revised (e.g., switch hosting).
* Builders or validation rules are extended (e.g., re-enable multi-page hinoo).
* New CI/CD steps or secrets are introduced.
* You uncover fundamentals that a future session should remember (workflow quirks, release steps, high-impact fixes). Skip short-lived, feature-specific trivia.

## 14. Hinoo Typography Calibration (2025-10-16)

* **Fixed Typography**: Lora font, size 18pt, line height ~1.375 (24.75pt). No dynamic scaling.
* **Line length limits (dual condition)**: User is blocked from typing more when EITHER condition is met:
  1. **Character count**: Line exceeds 36 characters
  2. **Physical width**: Line width exceeds available screen space (matters on narrow screens)
* **No automatic wrapping**: Text never wraps automatically. User must manually press Enter for new lines.
* **Padding**: Horizontal padding 32px per side (from 360px baseline), vertical padding as needed.
* **Line limit**: Maximum 20 lines. The user can't write anymore text after 20 lines.
* **Export**: PNG renders at 1080×1920 with same fixed typography.

Typography behavior:
- **Wide screens (≥360px)**: Up to 36 characters per line.
- **Narrow screens**: Fewer characters fit before hitting physical width limit (font stays 18pt).
- **Input blocking**: User cannot type when either character count (36) OR physical width is reached.
- **Manual line breaks**: User must press Enter to start a new line.

If typography needs adjustment, check:
1. Font size: 18pt (from image analysis)
2. Line height: 1.375 (~1.35-1.4 range from image analysis)
3. Character limit: 36 chars (`HinooTypography.maxCharsPerLine`)
4. Dual-condition logic in `ScriviHinooOverlay._lineWidthAndCountFormatter`

This guide should give any Codex agent enough context to operate effectively without rediscovering the project architecture from scratch. Happy building! 🚀
