# Habitower API

Habitower is a multiplayer habit-stacking platform designed for mobile-first engagement.

## Core Concept: The Stack
Unlike traditional habit trackers, Habitower focuses on "Stacking." Users join a challenge that adds a new requirement every week. By week 4, the user is tracking 4 different habits simultaneously. 

## Key Features
- **Blueprint System:** `Challenges` act as templates. `Groups` are the live instances people join.
- **Synchronized Starts:** To maximize the "Multiplayer" feel, weekly challenges start on Mondays and monthly ones on the 1st of each month.
- **Social Accountability:** Groups can be Public or Private (via invite codes).
- **Proof of Work:** Progress is tracked via `ProgressLogs` which can include numeric values (reps/amount), notes, and photo proof.

## CI / GitHub Actions

The workflow runs tests, Brakeman, and RuboCop on pull requests. **One-time setup:** add a repository secret so CI can sign/verify JWTs in tests (credentials are not decrypted in CI).

1. In the repo: **Settings → Secrets and variables → Actions**.
2. **New repository secret** → Name: `TEST_SECRET_KEY_BASE`, Value: any long random string (e.g. run `openssl rand -hex 64` locally and paste the result).
3. Save. The workflow uses `secrets.TEST_SECRET_KEY_BASE` as `SECRET_KEY_BASE` in the test job only.

