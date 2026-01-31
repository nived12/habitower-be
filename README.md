# Habitower API

Habitower is a multiplayer habit-stacking platform designed for mobile-first engagement.

## Core Concept: The Stack

Unlike traditional habit trackers, Habitower focuses on building a "Tower" of habits.

- **Sequential growth:** A challenge starts with one habit in Week 1. In Week 2, a second is added; the user tracks both. By Week 4, they track 4 habits simultaneously.
- **Multiplayer:** Users join **Groups** to compete or cooperate, keeping each other accountable as the stack gets heavier.

## Key Features

- **Blueprint system:** Challenges are templates; Groups are the live instances people join.
- **Synchronized starts:** Weekly challenges start on Mondays, monthly on the 1st.
- **Social accountability:** Groups can be Public or Private (join private groups via invite code).
- **Proof of work:** Progress is tracked via ProgressLogs (value, occurred_at, optional photo proof).

## Technical Stack

- **Framework:** Rails 8.x (API-only)
- **Ruby:** 3.3.0 · **Database:** PostgreSQL
- **Auth:** Devise + devise-jwt (stateless, JTI revocation). Refresh tokens for mobile (POST `/api/v1/auth/refresh`).
- **Authorization:** Pundit (policies per resource)
- **Soft deletes:** Discard (ChallengeTemplate, ChallengeStepTemplate, Group, GroupStep, Membership, ProgressLog)
- **API docs:** RSwag (OpenAPI 3.0), UI at `/api-docs`
- **JSON:** Jbuilder · **Testing:** RSpec
- **Storage:** Google Cloud Storage (signed PUT URLs for direct uploads)

For coding standards and implementation patterns, see **CONTEXT.md**.

## Architecture at a Glance

- **Services:** Business logic in `app/services` (e.g. `Groups::Creator`, `Groups::StepCopier`, `Groups::Joiner`, `Groups::ActiveStackFetcher`, `Memberships::IntegrityCalculator`, `Storage::SignedUrlGenerator`). Controllers orchestrate and respond.
- **Authorization:** Pundit policies control who can see and act on ChallengeTemplates, ChallengeStepTemplates, Groups, and GroupSteps.
- **Soft deletes:** Records are discarded (not hard-deleted); scopes use `kept` / `discarded`.
- **API:** Versioned under `api/v1`; standardized error JSON; Jbuilder per endpoint.

## Data Model

| Entity                | Role |
|-----------------------|------|
| **User**              | Devise-managed; includes unique `username`. Has `refresh_tokens` (mobile) and `devices` (push). |
| **ChallengeTemplate** | Blueprint (e.g. "90 Days of Growth"). `period_type` (weekly/monthly), `privacy_type` (public/private), `rules` (JSONB). API path: `/api/v1/challenges`. |
| **ChallengeStepTemplate** | Habits within a template. `position` = order in stack (Week 1, 2, …). API path: `/api/v1/challenges/:id/challenge_steps`. |
| **Group**             | Live instance of a template; syncs members to same start date. `challenge_template_id`, `privacy_type`, `invite_code`, `rules` (JSONB), `integrity_score` (0–100). |
| **GroupStep**         | Instance of a habit for a group; copied from template when group is created. `position`, `requirements`, optional `original_step_id` (template). |
| **Membership**        | User ↔ Group with `role` (member/admin). Admins add/remove members. |
| **ProgressLog**       | Check-in per membership and **group step** (value, occurred_at, optional proof). |
| **RefreshToken**      | Long-lived token for mobile; used with POST `/api/v1/auth/refresh` to issue a new JWT. |
| **Device**            | Push notification token per user (platform: ios/android). |

## Domain Logic: Timing & Integrity

- **Weekly challenges:** Start on the nearest Monday 00:00:00 (user timezone for Active Stack).
- **Monthly challenges:** Start on the 1st of the month 00:00:00.
- **Active Stack:** `GET /api/v1/memberships/:id/active_stack?user_timezone=...` returns group steps where `position` ≤ current week of group, plus **completion status for today** (so the app can show "Check-in" vs "Completed" without an extra request).
- **Integrity (Crumbling Tower):** `GET /api/v1/memberships/:id/integrity` returns a live-calculated score 0–100 from a 14-day lookback; foundation (position 1) missing logs penalizes more than top layers.

## Roadmap

| Phase | Status | Scope |
|-------|--------|--------|
| **1. Authentication & Swagger** | Done | Devise JWT, RSwag at `/api-docs`. |
| **2. Social & Group Infrastructure** | Done | ChallengeTemplates & ChallengeStepTemplates CRUD (API: challenges, challenge_steps). Groups CRUD, join/leave, invite codes. Memberships (index, admin add/remove). StepCopier on group create. Pundit policies. |
| **3. Stacking & Logging API** | Done | Active Stack with completion status (`GET /api/v1/memberships/:id/active_stack`). Integrity score (`GET /api/v1/memberships/:id/integrity`). ProgressLogs point to GroupStep. |
| **4. Mobile Bridge** | Done | Refresh tokens (POST `/api/v1/auth/refresh`, optional `refresh_token` on logout). GCS signed URLs (`GET /api/v1/uploads/signed_url`). Device registration for push (`POST /api/v1/devices`). |
| **5. Competitive Features** | Future | Leaderboards, real-time activity feed (ActionCable). |

## CI / GitHub Actions

The workflow runs tests, Brakeman, and RuboCop on pull requests.

**One-time setup:** Add a repository secret so CI can sign/verify JWTs (credentials are not decrypted in CI).

1. **Settings → Secrets and variables → Actions**
2. **New repository secret** → Name: `TEST_SECRET_KEY_BASE`, Value: e.g. `openssl rand -hex 64`
3. Save. The workflow uses `secrets.TEST_SECRET_KEY_BASE` as `SECRET_KEY_BASE` in the test job only.

---

For implementation guidelines and AI instructions, see **CONTEXT.md**.
