# Habitower API

Habitower is a multiplayer habit-stacking platform designed for mobile-first engagement.

## What It Is

Unlike traditional habit trackers, Habitower focuses on building a **"Tower"** of habits: you add one habit in Week 1, then stack more over time (Week 2, Week 3, …). Users join **Groups** to do challenges together, with the same start date and shared accountability. Progress is logged per habit (with optional proof); groups can be public or private (invite codes).

The API supports a social feed (all updates, your activity, or friends), profile and stats, reactions (e.g. high-fives and nudges), in-app notifications, and categories for filtering challenges. Full endpoint reference is in the interactive docs at **`/api-docs`** (Swagger).

## Key Features

- **Blueprint system** — Challenges are templates; groups are the live instances people join.
- **Synchronized starts** — Weekly challenges start on Mondays; monthly on the 1st.
- **Social accountability** — Public or private groups; join private ones via invite code.
- **Progress and proof** — Log progress per habit, with optional photo proof.
- **Feed and profile** — Activity feed (all / mine / friends), profile with stats (e.g. streak, total blocks).
- **Reactions and notifications** — React to others’ progress; get notified on reactions, follows, and reminders.
- **Categories** — Filter and discover challenges by category (e.g. Fitness, Mindfulness).

For implementation details, architecture, and coding standards, see **CONTEXT.md**.

## Running the Project

- **Ruby:** See `.ruby-version`.
- **Database:** PostgreSQL. Configure via `config/database.yml` or `DATABASE_URL`.
- **Setup:** `bin/setup` (installs deps, prepares DB, clears logs/tmp). For a fresh DB: `bin/rails db:create db:migrate`.
- **Server:** `bin/dev` or `bin/rails server`. API is JSON under `/api/v1`; interactive docs at **`/api-docs`** (Swagger).

## Configuration and Environment

- **Secret key:** Rails expects `SECRET_KEY_BASE` (or use `rails credentials`). Required for sessions and JWT.
- **Uploads (optional):** For signed upload URLs, set either Rails credentials `gcs.bucket` or the env var **`GCS_BUCKET`**. If neither is set, the uploads endpoint will return an error.
- **Database:** Use `config/database.yml` in development/test, or set **`DATABASE_URL`** (e.g. in production or CI).
- **CI (GitHub Actions):** The workflow runs tests and static checks. To run tests in CI, add a repository secret **`TEST_SECRET_KEY_BASE`** (used as `SECRET_KEY_BASE` in the test job only; no need to commit a value).

No other env vars are required for basic run; optional ones (e.g. `WEB_CONCURRENCY`, `PIDFILE`) are documented in the relevant config files.

## CI / GitHub Actions

The workflow runs on pull requests: tests, Brakeman, and RuboCop. Add the **`TEST_SECRET_KEY_BASE`** secret in **Settings → Secrets and variables → Actions** so the test job can sign/verify JWTs.
