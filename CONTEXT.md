# CONTEXT.md: Habitower Backend

**Purpose:** Implementation guide — how to write and structure code. **README.md** describes what the project is and how to run it (setup, env vars, CI). API behaviour and endpoints are documented in Swagger at `/api-docs`.

## Tech Stack
Rails 8.x (API Mode), PostgreSQL, RSpec, Devise + JWT, Discard, Factory Bot. Jbuilder for JSON; RSwag for OpenAPI; Pundit for authorization. Optional: Google Cloud Storage (signed URLs) via credentials or `GCS_BUCKET`.

## Architecture
- **SOLID & Services:** Business logic in `app/services`; controllers handle routing/params.
- **ApplicationService:** Service objects inherit `ApplicationService` and use `.call(...)`; implement `#call` and return `success(payload)` or `failure(message)` (or `failure(ActiveModel::Errors)`). Callers get an `ApplicationService::Response` with `success?`/`failure?`, `payload`, and `errors` (ActiveModel::Errors). Use `render_service_errors(result.errors)` or `render_error(status_code, detail, http_status)` from `Api::V1::ErrorHandler` when handling failures in controllers.
- **Traceability (Discard):** Soft deletes via [Discard](https://github.com/jhawthorn/discard). Domain models (ChallengeTemplate, ChallengeStepTemplate, Group, GroupStep, Membership, ProgressLog) include `Discard::Model`; associations use `dependent: :destroy` and **`after_discard` callbacks** to cascade (e.g. `after_discard { challenge_step_templates.discard_all; groups.discard_all }`). Use `record.discard` (not `destroy`), `Model.kept` / `Model.discarded` for scoping. Notification, Reaction, Follow, Category do not use Discard.
- **Timing:** Weekly challenges start on the nearest Monday; monthly on the 1st.

## Domain Models (summary)
- **ChallengeTemplate:** `title`, `description`, `rules` (jsonb), `period_type` (enum), `privacy_type`, `creator_id`. Rules drive "fixed" vs "evolving". Has many categories through ChallengeTemplateCategory.
- **ChallengeStepTemplate:** `challenge_template_id`, `creator_id`, `title`, `position`, `requirements` (jsonb). Position = stacking order.
- **Group:** `challenge_template_id`, `start_date`, `privacy_type` (enum), `invite_code`, `rules` (jsonb). Syncs users to same start date.
- **GroupStep:** Instance of a habit for a group; `group_id`, `position`, `requirements`, optional `original_step_id` (ChallengeStepTemplate).
- **ProgressLog:** `membership_id`, `group_step_id`, `value`, `occurred_at`, `note`, `proof_url`. Progress per step per membership. Has many reactions (high_five, nudge).
- **Reaction:** `user_id`, `progress_log_id`, `kind` (enum: high_five, nudge). Unique per [user, progress_log, kind]. Creates a Notification for the log owner on create.
- **Notification:** `recipient_id`, optional `actor_id`, `action`, polymorphic `notifiable`, `read_at`, `data` (jsonb). No Discard.
- **Follow:** `follower_id`, `followed_id`. User cannot follow self.
- **Category:** `name`, `slug`. Many-to-many with ChallengeTemplates.

Evolving stacks: ChallengeTemplate is a timeline; users see GroupSteps where `position <= current_week_of_group`. ProgressLog links to a GroupStep.

### Schema annotations (models)
- Each model has a **Schema Information** comment block at the bottom: table name, columns (type, null, default), and indexes.
- **After running migrations**, annotations are updated automatically (custom task runs after `db:migrate` in development). You can also run `bundle exec rake schema:annotate` manually.

## JSON (Jbuilder)
- Use Jbuilder views for API JSON. Shared partials in `app/views/api/v1/` (e.g. `_auth_user.json.jbuilder`). Action views: `api/v1/resource/action.json.jbuilder`; controller sets `@resource` and renders partial. One-off errors: `render json: { ... }` in controller is fine.

## API Standards
- Controllers inherit `Api::V1::BaseController`; use `before_action :authenticate_user!`. Standard error JSON: `{ "errors": [{ "status": "422", "source": { "pointer": "/data/attributes/title" }, "detail": "..." }] }`. BaseController rescues `RecordNotFound` (404) and `RecordInvalid` (422).
- Use **`:unprocessable_content`** (not `:unprocessable_entity`) for 422 responses in `render(..., status: ...)` and in specs (e.g. `have_http_status(:unprocessable_content)`). Rack deprecates `:unprocessable_entity` in favor of `:unprocessable_content`.

## Testing

### Request specs (`spec/requests/`)
- **Purpose:** Endpoint behavior (status, body, headers). Plain RSpec; require `rails_helper` only.
- **Style:** `subject(:do_request) { post/get/delete ... }`, `context "with valid params"` etc., `let`/`let!` for setup. One logical assertion per example; descriptive present-tense names. Helpers in `spec/support/request_helpers.rb` (e.g. `json_headers`, `parsed_body`).

### Integration specs (`spec/integration/`)
- **Purpose:** OpenAPI/Swagger contract. RSwag DSL; require `swagger_helper`. Run `bundle exec rake rswag:specs:swaggerize` to regenerate `swagger/v1/swagger.yaml`. Docs at `/api-docs`.

### Model specs (`spec/models/`)
- **Purpose:** Validations, associations, enums, discard behavior.
- **Style:** Use **`let(:...)`** for all setup; use **Factory Bot** (`create(:user)`, `build(:challenge, creator: creator)`) to create or build records. No shoulda-matchers; write explicit examples with `expect(...).to be_valid`, `expect(...).to include(...)`, etc.
- **Factories:** Define in `spec/factories/` (e.g. `users.rb`, `challenges.rb`). Use `association :creator, factory: :user` for belongs_to. `rails_helper` includes `FactoryBot::Syntax::Methods` so `create`/`build` are available.

### Test DB & cleaning
- `database_cleaner-active_record`: strategy `:transaction` per example; use `:truncation` only when needed (tag and set in that context).

## Instructions for Cursor
1. Use RSpec for all tests. **Request specs** (`spec/requests/`) for behavior; **integration specs** (`spec/integration/`) for Swagger; **model specs** (`spec/models/`) for validations/associations/discard.
2. Use **Factory Bot** for test data; use **`let(:...)`** in specs (no raw variables). Factories in `spec/factories/`.
3. Follow the Service Object pattern for joining groups and logging progress.
4. Enums: strings in the model, not integers.
5. Update CONTEXT.md when adding or changing guidelines (only when required).
