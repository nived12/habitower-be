# Project: Habitower (Backend API)
**Purpose:** Mobile-first multiplayer habit stacking. Users join Groups (Public/Private) based on Challenge templates.

## Tech Stack
Rails 8.x (API Mode), PostgreSQL, RSpec, Devise + JWT, Discard, Factory Bot.

## Architecture
- **SOLID & Services:** Business logic in `app/services`; controllers handle routing/params.
- **Traceability (Discard):** Soft deletes via [Discard](https://github.com/jhawthorn/discard). Domain models (Challenge, Group, Membership, ChallengeStep, ProgressLog) include `Discard::Model`; associations use `dependent: :destroy` and **`after_discard` callbacks** to cascade (e.g. `after_discard { challenge_steps.discard_all; groups.discard_all }`). Use `record.discard` (not `destroy`), `Model.kept` / `Model.discarded` for scoping.
- **Timing:** Weekly challenges start on the nearest Monday; monthly on the 1st.

## Domain Models (summary)
- **Challenge:** `title`, `description`, `rules` (jsonb), `period_type` (enum), `creator_id`. Rules drive "fixed" vs "evolving".
- **ChallengeStep:** `challenge_id`, `creator_id`, `title`, `position`, `requirements` (jsonb). Position = stacking order.
- **Group:** `challenge_id`, `start_date`, `privacy_type` (enum), `invite_code`. Syncs users to same start date.
- **ProgressLog:** `membership_id`, `challenge_step_id`, `value`, `occurred_at`, `proof_url`. Progress per step per membership.

Evolving stacks: Challenge is a timeline; users see steps where `position <= current_week_of_group`. ProgressLog links to a specific ChallengeStep.

### Schema annotations (models)
- Each model has a **Schema Information** comment block at the bottom: table name, columns (type, null, default), and indexes.
- **After running migrations**, annotations are updated automatically (custom task runs after `db:migrate` in development). You can also run `bundle exec rake schema:annotate` manually.

## JSON (Jbuilder)
- Use Jbuilder views for API JSON. Shared partials in `app/views/api/v1/` (e.g. `_auth_user.json.jbuilder`). Action views: `api/v1/resource/action.json.jbuilder`; controller sets `@resource` and renders partial. One-off errors: `render json: { ... }` in controller is fine.

## API Standards
- Controllers inherit `Api::V1::BaseController`; use `before_action :authenticate_user!`. Standard error JSON: `{ "errors": [{ "status": "422", "source": { "pointer": "/data/attributes/title" }, "detail": "..." }] }`. BaseController rescues `RecordNotFound` (404) and `RecordInvalid` (422).

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
