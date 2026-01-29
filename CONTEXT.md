# Project: Kinetic (Backend API)
**Purpose:** Mobile-first multiplayer habit stacking. Users join Groups (Public/Private) based on Challenge templates.

## Tech Stack
- Rails 8.x (API Mode), PostgreSQL, RSpec, Devise + JWT.

## Architecture Guidelines
- **SOLID & Services:** Business logic belongs in `app/services`. Controllers only handle routing/params.
- **Synchronized Timing:** - Weekly challenges start on the nearest Monday.
    - Monthly challenges start on the 1st of the month.
## Domain Models & Business Logic
1. **Challenge:** - Attributes: `title`, `description`, `rules` (jsonb), `period_type` (enum), `creator_id`.
   - Logic: The `rules` field determines if the challenge is "fixed" or "evolving".
2. **ChallengeStep:** - Attributes: `challenge_id`, `creator_id`, `title`, `position` (integer), `requirements` (jsonb).
   - Logic: Steps can be added at any time. `position` determines the stacking order.
3. **Group:** - Attributes: `challenge_id`, `start_date`, `privacy_type` (enum), `invite_code`.
   - Logic: Groups sync users to the same `start_date` (Mondays/1st of Month).
4. **ProgressLog:**
   - Attributes: `membership_id`, `challenge_step_id`, `value`, `occurred_at`, `proof_url`.
   - Logic: Users log progress against specific steps within their membership.

## Feature Specifics: Evolving Stacks
- A Challenge is NOT static. It is a timeline.
- Users see all ChallengeSteps where `position` <= `current_week_of_group`.
- A ProgressLog must link to a specific ChallengeStep to ensure the "Stack" is tracked accurately.

## API Standards & Error Handling
- **Base Controller:** All API controllers must inherit from `Api::V1::BaseController`.
- **Authentication:** Use `before_action :authenticate_user!` in the BaseController.
- **Error Format:** Return a standardized JSON response for errors:
  `{ "errors": [{ "status": "422", "source": { "pointer": "/data/attributes/title" }, "detail": "can't be blank" }] }`
- **Standard Rescues:** The BaseController should rescue from `ActiveRecord::RecordNotFound` (404) and `ActiveRecord::RecordInvalid` (422) automatically.

## API Documentation (Swagger/OpenAPI)
- **Tooling:** Use `rswag` (rswag-api, rswag-ui, and rswag-specs).
- **Workflow:** Documentation must be generated from integration specs located in `spec/requests` or `spec/integration`.
- **DSL:** Use RSwag DSL (`path`, `get`, `post`, `response`, `schema`, `run_test!`).
- **Security:** Define the JWT Bearer security scheme in `swagger_helper.rb`.
- **Output:** Documentation must be accessible at `/api-docs`.

## Instructions for Cursor
1. Use RSpec for all tests (Request specs for APIs).
2. Use FactoryBot and FFaker.
3. Follow the "Service Object" pattern for joining groups and logging progress.
4. You can update the CONTEXT.md file whenever a new guideline is added or modified. (NOT ALWAYS, JUST WHEN IT IS REQUIRED)
5. Enums should be strings and not integers, defined in the model
