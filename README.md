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
- **Soft deletes:** Discard (ChallengeTemplate, ChallengeStepTemplate, Group, GroupStep, Membership, ProgressLog). Notification, Reaction, Follow, Category are not soft-deleted.
- **API docs:** RSwag (OpenAPI 3.0), UI at `/api-docs`
- **JSON:** Jbuilder · **Testing:** RSpec
- **Storage:** Google Cloud Storage (signed PUT URLs for direct uploads)

For coding standards and implementation patterns, see **CONTEXT.md**.

## Architecture at a Glance

- **Services:** Business logic in `app/services` (e.g. `Groups::Creator`, `Groups::StepCopier`, `Groups::Joiner`, `Groups::ActiveStackFetcher`, `Memberships::IntegrityCalculator`, `Feed::Fetcher`, `Stats::Calculator`, `ProgressLogs::Creator`, `Notifications::Creator`, `Storage::SignedUrlGenerator`). Controllers orchestrate and respond.
- **Authorization:** Pundit policies control who can see and act on ChallengeTemplates, ChallengeStepTemplates, Groups, and GroupSteps.
- **Soft deletes:** Records are discarded (not hard-deleted); scopes use `kept` / `discarded`. Notification is not discardable.
- **API:** Versioned under `api/v1`; standardized error JSON; Jbuilder per endpoint.

## Data Model

| Entity                | Role |
|-----------------------|------|
| **User**              | Devise-managed; unique `username`, `bio`, `timezone`. Has `refresh_tokens` (mobile), `devices` (push), `notifications`, `reactions`, and follow relationships (`following` / `followers`). |
| **ChallengeTemplate** | Blueprint (e.g. "90 Days of Growth"). `period_type` (weekly/monthly), `privacy_type` (public/private), `rules` (JSONB). API path: `/api/v1/challenges`. Can have many **categories** via join. |
| **ChallengeStepTemplate** | Habits within a template. `position` = order in stack (Week 1, 2, …). API path: `/api/v1/challenges/:id/challenge_steps`. |
| **Group**             | Live instance of a template; syncs members to same start date. `challenge_template_id`, `privacy_type`, `invite_code`, `rules` (JSONB), `integrity_score` (0–100). |
| **GroupStep**         | Instance of a habit for a group; copied from template when group is created. `position`, `requirements`, optional `original_step_id` (template). |
| **Membership**        | User ↔ Group with `role` (member/admin). Admins add/remove members. |
| **ProgressLog**       | Check-in per membership and **group step** (value, occurred_at, note, optional proof). Has many **reactions** (high_five, nudge). |
| **Reaction**          | User reaction on a ProgressLog. `kind`: `high_five` or `nudge`. One per (user, progress_log, kind). Creating a reaction creates a Notification for the log owner. |
| **Notification**      | In-app notification for a user. `recipient`, optional `actor`, `action` (e.g. high_five, nudge, follow, reminder), polymorphic `notifiable`, `read_at`, `data` (JSONB). |
| **Follow**            | User follows another user. Enables "Friends" feed scope. |
| **Category**          | Label for challenge filtering (e.g. Fitness, Mindfulness). Many-to-many with ChallengeTemplates via **ChallengeTemplateCategory**. |
| **RefreshToken**      | Long-lived token for mobile; used with POST `/api/v1/auth/refresh` to issue a new JWT. |
| **Device**            | Push notification token per user (platform: ios/android). |

## Domain Logic: Timing & Integrity

- **Weekly challenges:** Start on the nearest Monday 00:00:00 (user timezone for Active Stack).
- **Monthly challenges:** Start on the 1st of the month 00:00:00.
- **Active Stack:** `GET /api/v1/memberships/:id/active_stack?user_timezone=...` returns group steps where `position` ≤ current week of group, plus **completion status for today** (so the app can show "Check-in" vs "Completed" without an extra request).
- **Integrity (Crumbling Tower):** `GET /api/v1/memberships/:id/integrity` returns a live-calculated score 0–100 from a 14-day lookback; foundation (position 1) missing logs penalizes more than top layers. `GET /api/v1/groups/:id?include_members=1&user_timezone=...` returns members with `integrity_score` and `ghost_tower` (last 3 steps’ completed/missed status) for tower UI.

## API: Feed, Profile, Notifications, Follows, Categories

- **Feed:** `GET /api/v1/feed?scope=all|mine|friends&page=&per_page=` — Paginated progress logs from groups the user is in; `scope` = all members’ logs, current user’s logs only, or followed users’ logs. Response includes user, group_step, group, reaction stats, and `viewer_context` (reacted_by_me).
- **Profile:** `GET /api/v1/me` — Current user plus computed stats (total_blocks, current_streak, groups_count). `PATCH /api/v1/me` — Update first_name, last_name, avatar_url, bio, timezone.
- **Progress logs:** `POST /api/v1/progress_logs` — Create log (group_step_id, value, occurred_at, note, proof_url). `POST /api/v1/progress_logs/:id/react` — Toggle reaction (kind: high_five | nudge); returns reacted_by_me and reaction counts.
- **Notifications:** `GET /api/v1/notifications` — Paginated list. `POST /api/v1/notifications/:id/read` — Mark one read. `POST /api/v1/notifications/read_all` — Mark all read.
- **Follows:** `GET /api/v1/follows` — Users the current user follows. `POST /api/v1/follows` (followed_id) — Follow a user. `DELETE /api/v1/follows/:id` — Unfollow. `GET /api/v1/followers` — Users following the current user.
- **Categories:** `GET /api/v1/categories` — List categories for challenge filters. `GET /api/v1/challenges?category_id=` or `?category_slug=` — Filter challenges by category.

## Roadmap

| Phase | Status | Scope |
|-------|--------|--------|
| **1. Authentication & Swagger** | Done | Devise JWT, RSwag at `/api-docs`. |
| **2. Social & Group Infrastructure** | Done | ChallengeTemplates & ChallengeStepTemplates CRUD (API: challenges, challenge_steps). Groups CRUD, join/leave, invite codes. Memberships (index, admin add/remove). StepCopier on group create. Pundit policies. |
| **3. Stacking & Logging API** | Done | Active Stack with completion status (`GET /api/v1/memberships/:id/active_stack`). Integrity score (`GET /api/v1/memberships/:id/integrity`). ProgressLogs point to GroupStep. |
| **4. Mobile Bridge** | Done | Refresh tokens (POST `/api/v1/auth/refresh`, optional `refresh_token` on logout). GCS signed URLs (`GET /api/v1/uploads/signed_url`). Device registration for push (`POST /api/v1/devices`). |
| **5. Feed, Profile, Notifications** | Done | Feed (scopes: all, mine, friends). Profile GET/PATCH `/me` with stats. ProgressLog create and react (high_five, nudge). Notifications index, read, read_all. Follows and followers. Categories and challenge filter. Groups#show with optional members + integrity/ghost_tower. |
| **6. Competitive Features** | Future | Leaderboards, real-time activity feed (ActionCable). |

## CI / GitHub Actions

The workflow runs tests, Brakeman, and RuboCop on pull requests.

**One-time setup:** Add a repository secret so CI can sign/verify JWTs (credentials are not decrypted in CI).

1. **Settings → Secrets and variables → Actions**
2. **New repository secret** → Name: `TEST_SECRET_KEY_BASE`, Value: e.g. `openssl rand -hex 64`
3. Save. The workflow uses `secrets.TEST_SECRET_KEY_BASE` as `SECRET_KEY_BASE` in the test job only.

---

For implementation guidelines and AI instructions, see **CONTEXT.md**.
