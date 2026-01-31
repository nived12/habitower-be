# PROJECT.md: Habitower Backend

## 1. Project Overview
**Habitower** is a multiplayer habit-stacking platform designed for mobile-first engagement.

### The "Stacking" Mechanic
Unlike traditional habit trackers, Habitower focuses on building a "Tower" of habits.
- **Sequential Growth:** A challenge starts with one habit in Week 1.
- **The Stack:** In Week 2, a second habit is added. The user must now track both. By Week 4, the user is tracking 4 distinct habits simultaneously.
- **Multiplayer:** Users join "Groups" to compete or cooperate, keeping each other accountable as the stack gets heavier.

---

## 2. Technical Stack
- **Framework:** Rails 8.x (API-only mode).
- **Ruby Version:** 3.3.0.
- **Database:** PostgreSQL.
- **Authentication:** Devise + `devise-jwt` (Stateless, JTI revocation strategy).
- **API Documentation:** RSwag (OpenAPI 3.0).
- **JSON Serialization:** Jbuilder.
- **Testing:** RSpec (Request/Integration specs for API).

---

## 3. Architecture & Coding Standards

### SOLID & Service Objects
- **Skinny Controllers/Models:** Business logic must reside in `app/services`.
- **Service Pattern:** Use a single public `call` method.
- **Naming:** Services should be named as "Verb + Object" (e.g., `Groups::Joiner`, `Logs::Creator`).

### API Standards
- **Versioning:** All routes must be under the `api/v1` namespace.
- **Base Controller:** All controllers inherit from `Api::V1::BaseController`.
- **Error Handling:** Standardized JSON error format:
  `{ "errors": [{ "status": "422", "source": { "pointer": "/data/attributes/title" }, "detail": "can't be blank" }] }`
- **Jbuilder:** Every endpoint must have a corresponding `.json.jbuilder` template.

### Data Integrity
- **String Enums:** All enums must be stored as strings in the database for readability.
- **Constraints:** Strict `null: false` constraints and foreign keys in all migrations.

---

## 4. Data Model (The Blueprint)

### Core Entities
1. **User:** Managed by Devise.
2. **Challenge:** The template (e.g., "90 Days of Growth").
   - `period_type`: weekly or monthly.
   - `rules`: JSONB for flexible configuration (e.g., allow_backdating).
3. **ChallengeStep:** The specific habits within a challenge.
   - `position`: The order in the stack (Week 1, Week 2, etc.).
4. **Group:** The live instance of a challenge.
   - `start_date`: Synchronized (Mondays for weekly, 1st of month for monthly).
   - `privacy_type`: public or private.
   - `invite_code`: 6-digit unique code for private groups.
5. **Membership:** Join table for Users and Groups.
   - `role`: member or admin.
6. **ProgressLog:** The check-in record.
   - Links to both `Membership` and `ChallengeStep`.

---

## 5. Domain Logic: The Timing Engine
- **Weekly Challenges:** Always start on the nearest **Monday 00:00:00**.
- **Monthly Challenges:** Always start on the **1st day of the month 00:00:00**.
- **The Active Step:** The API calculates the current "Week" of the group based on the `start_date`. Users can only log progress for steps where `position` <= `current_week_of_group`.

---

## 6. Implementation Roadmap

### Phase 1: Authentication & Swagger (Done)
- Devise JWT integration.
- RSwag UI available at `/api-docs`.

### Phase 2: Social & Group Infrastructure (Current)
- Creating Challenges and ChallengeSteps.
- Group creation and `invite_code` generation.
- The `Groups::Joiner` service.

### Phase 3: The Stacking & Logging API
- Fetching the user's "Active Stack" (All steps requiring check-in today).
- `ProgressLog` creation with optional photo proof.

### Phase 4: Competitive Features
- Group leaderboards based on stack completion percentage.
- Real-time activity feed via ActionCable (Future).

---

## 7. AI Instructions (For Cursor/Claude)
1. **Context First:** Always read `PROJECT.md` and `CONTEXT.md` before generating code.
2. **TDD:** Write the RSwag integration spec *before* or *with* the controller logic.
3. **No Logic in Controllers:** If you are writing an `if/else` block with business logic in a controller, move it to a Service Object unless is a small logic.
4. **Formatting:** Use double quotes, trailing commas in hashes, and standard Ruby 3.3 syntax.
