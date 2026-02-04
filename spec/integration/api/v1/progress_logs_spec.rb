# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("Progress Logs API", type: :request) do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
  let(:creator) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: creator) }
  let(:group) { create(:group, challenge_template: challenge_template, creator: creator) }
  let!(:membership) { create(:membership, user: user, group: group) }
  let(:group_step) { create(:group_step, group: group, creator: creator, position: 1) }

  path "/api/v1/progress_logs" do
    post "Create a progress log" do
      tags "Progress Logs"
      security [bearer_auth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          group_step_id: { type: :integer },
          value: { type: :number },
          occurred_at: { type: :string, format: "date-time" },
          note: { type: :string },
          proof_url: { type: :string }
        },
        required: %w[group_step_id value]
      }

      response "201", "created" do
        let(:body) { { group_step_id: group_step.id, value: 1, occurred_at: Time.current.iso8601 } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("id"))
          expect(data["group_step_id"]).to(eq(group_step.id))
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        let(:body) { { group_step_id: group_step.id, value: 1 } }
        run_test!
      end
    end
  end

  path "/api/v1/progress_logs/{id}/react" do
    parameter name: :id, in: :path, type: :integer, required: true, description: "Progress log ID"
    let(:progress_log) { create(:progress_log, membership: membership, group_step: group_step) }
    let(:id) { progress_log.id }

    post "Toggle reaction on a progress log" do
      tags "Progress Logs"
      security [bearer_auth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          kind: { type: :string, enum: %w[high_five nudge], example: "high_five" }
        }
      }

      response "200", "success" do
        let(:body) { { kind: "high_five" } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("reacted_by_me"))
          expect(data).to(have_key("reactions_count"))
        end
      end
    end
  end
end
