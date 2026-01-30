# Project: Habitower (Backend API)
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

## JSON responses (Jbuilder)
- **Use Jbuilder views** for JSON responses instead of building hashes in controllers.
- **Shared partial:** Use `app/views/api/v1/auth/_auth_user.json.jbuilder` for the auth user shape; other shared shapes go in `app/views/api/v1/` (e.g. `_user.json.jbuilder` for a full user).
- **Action views:** Use `app/views/api/v1/auth/registrations/create.json.jbuilder` and `app/views/api/v1/auth/sessions/create.json.jbuilder` (and similarly `resource/action.json.jbuilder` for other endpoints). The view assigns `@user` (or the relevant resource) in the controller and calls `json.partial! "api/v1/auth/auth_user", user: @user` (or the appropriate partial).
- **Errors/simple messages:** Inline `render json: { ... }` in the controller is fine for one-off error or message responses.

## API Standards & Error Handling
- **Base Controller:** All API controllers must inherit from `Api::V1::BaseController`.
- **Authentication:** Use `before_action :authenticate_user!` in the BaseController.
- **Error Format:** Return a standardized JSON response for errors:
  `{ "errors": [{ "status": "422", "source": { "pointer": "/data/attributes/title" }, "detail": "can't be blank" }] }`
- **Standard Rescues:** The BaseController should rescue from `ActiveRecord::RecordNotFound` (404) and `ActiveRecord::RecordInvalid` (422) automatically.

## Testing / Specs

### Request specs (`spec/requests/`)
- **Purpose:** Test endpoint **behavior and expectations** (status codes, response body, headers).
- **Style:** Plain RSpec request specs with `describe` / `context` / `it`, `get` / `post` / `delete`, and `expect(response).to have_http_status(...)` etc.
- **Require:** `rails_helper` only (no `swagger_helper`).
- **Use for:** Asserting that each endpoint returns the correct status, JSON shape, error messages, and that side effects (e.g. user creation) happen as expected.

### Integration specs (`spec/integration/`)
- **Purpose:** Drive **OpenAPI/Swagger documentation** and validate that the API contract is satisfied.
- **Style:** RSwag DSL: `path`, `post` / `get` / `delete`, `parameter`, `response`, `run_test!`.
- **Require:** `swagger_helper`.
- **Use for:** Defining the documented API contract; these specs are the source of truth for `swagger/v1/swagger.yaml`.
- **Generate Swagger:** Run `bundle exec rake rswag:specs:swaggerize` to regenerate the Swagger file from `spec/integration/**/*_spec.rb` (and the other patterns rswag uses).

### Summary
| Folder           | Purpose                    | Require          | Example focus                          |
|-----------------|----------------------------|------------------|----------------------------------------|
| `spec/requests/`  | Endpoint behavior & expectations | `rails_helper`   | Status, body, headers, validation, side effects |
| `spec/integration/` | Swagger/OpenAPI contract   | `swagger_helper` | Paths, parameters, responses, run_test! |

### RSpec best practices (request and integration specs)
- **One file per endpoint action:** Put each action in its own spec file (e.g. `registrations/create_spec.rb`, `sessions/create_spec.rb`, `sessions/destroy_spec.rb`).
- **Subject for the request:** Use `subject(:do_request) { post/get/delete ... }` so the HTTP call is defined once; trigger it in a `before { do_request }` or in the example.
- **Context for scenarios:** Use `context "with valid params"`, `context "when email is blank"` etc. so each scenario has its own `let(:request_params)` (or equivalent) and optional `before`.
- **One logical assertion per example:** Prefer one behaviour per `it` (e.g. status in one example, body shape in another). Use `aggregate_failures` only when several expectations form a single logical assertion.
- **Descriptive example names:** Use present tense and behaviour: "returns 201 Created", "returns errors in the response body", "persists the user".
- **Shared helpers:** Use `spec/support/request_helpers.rb` for shared behaviour (e.g. `json_headers`, `parsed_body`). Include via `RSpec.configure { config.include RequestHelpers, type: :request }`.
- **Let over instance variables:** Use `let` and `let!` for setup; use `let!` when the object must exist before the example runs (e.g. existing user for login).
- **Side-effect examples:** For "persists the user" or similar, use `expect { ... }.to change(Model, :count).by(1)` in a dedicated example; avoid relying on a shared `before` that already performed the request.
- **Nested contexts and before order:** When a context needs setup before the request (e.g. "email already taken"), use a `before` in that context that does the setup then `do_request`, and do not rely on a parent `before { do_request }` that would run first.

### Test database only
- **Safeguard:** `spec/support/ensure_test_db.rb` aborts the test run if the app is connected to a development or production database. Only a database whose name includes `_test` (e.g. `habitower_be_test`) is allowed.
- **Rails env:** `spec/rails_helper.rb` sets `ENV["RAILS_ENV"] = "test"` so the test environment and test DB are always used when running specs. Do not set `DATABASE_URL` to a development or production DB when running tests.

### Database Cleaner
- **Gem:** `database_cleaner-active_record` is used to clean the database after each test.
- **Config:** `spec/support/database_cleaner.rb` turns off Rails transactional fixtures and uses Database Cleaner instead.
- **Strategy:** `:transaction` (rollback after each example); `:truncation` is used once before the suite. For specs that need truncation (e.g. multiple threads), tag with `:truncation` and set `DatabaseCleaner.strategy = :truncation` in a `before` for that context.

## API Documentation (Swagger/OpenAPI)
- **Tooling:** Use `rswag` (rswag-api, rswag-ui, and rswag-specs).
- **Workflow:** Documentation is generated from **integration specs** in `spec/integration/`. Add or edit specs there, then run `bundle exec rake rswag:specs:swaggerize` to update `swagger/v1/swagger.yaml`.
- **DSL:** In integration specs use the RSwag DSL (`path`, `get` / `post` / `delete`, `parameter`, `response`, `schema`, `run_test!`).
- **Security:** Define the JWT Bearer security scheme in `swagger_helper.rb`.
- **Output:** Documentation is served at `/api-docs`.

## Instructions for Cursor
1. Use RSpec for all tests. Put **endpoint behavior/expectations** in `spec/requests/` (plain request specs). Put **Swagger/OpenAPI contract** specs in `spec/integration/` (RSwag DSL).
2. Use FactoryBot and FFaker.
3. Follow the "Service Object" pattern for joining groups and logging progress.
4. You can update the CONTEXT.md file whenever a new guideline is added or modified. (NOT ALWAYS, JUST WHEN IT IS REQUIRED)
5. Enums should be strings and not integers, defined in the model
