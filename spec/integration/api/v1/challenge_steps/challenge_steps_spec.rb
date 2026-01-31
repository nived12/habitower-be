# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("Challenge Steps API", type: :request) do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }
  let(:challenge) { create(:challenge, creator: user) }
  let(:challenge_id) { challenge.id }

  path "/api/v1/challenges/{challenge_id}/challenge_steps" do
    parameter name: :challenge_id, in: :path, type: :integer, required: true, description: "Challenge ID"

    get "List challenge steps" do
      tags "Challenge Steps"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "success" do
        let!(:step) { create(:challenge_step, challenge_template: challenge, creator: user) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(be_an(Array))
          expect(data.first["id"]).to(eq(step.id))
        end
      end

      response "404", "challenge not found" do
        let(:challenge_id) { 999999 }
        run_test!
      end
    end

    post "Create a challenge step" do
      tags "Challenge Steps"
      security [bearer_auth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :challenge_step, in: :body, schema: {
        type: :object,
        properties: {
          challenge_step: {
            type: :object,
            properties: {
              title: { type: :string, example: "Morning Meditation" },
              position: { type: :integer, example: 1 },
              requirements: { type: :object, example: { duration_minutes: 10 } }
            },
            required: %w[title position]
          }
        },
        required: ["challenge_step"]
      }

      response "201", "created" do
        let(:challenge_step) { { challenge_step: { title: "Step 1", position: 1 } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["title"]).to(eq("Step 1"))
          expect(data["challenge_template_id"]).to(eq(challenge.id))
        end
      end

      response "403", "forbidden (not owner)" do
        let(:other_user) { create(:user) }
        let(:challenge) { create(:challenge, creator: other_user) }
        let(:challenge_step) { { challenge_step: { title: "Hacked", position: 1 } } }
        run_test!
      end

      response "422", "validation error" do
        let(:challenge_step) { { challenge_step: { title: "" } } }
        run_test!
      end
    end
  end

  path "/api/v1/challenges/{challenge_id}/challenge_steps/{id}" do
    parameter name: :challenge_id, in: :path, type: :integer, required: true, description: "Challenge ID"
    parameter name: :id, in: :path, type: :integer, required: true, description: "Challenge Step ID"

    get "Get a challenge step" do
      tags "Challenge Steps"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "success" do
        let(:step) { create(:challenge_step, challenge_template: challenge, creator: user) }
        let(:id) { step.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["id"]).to(eq(step.id))
        end
      end

      response "404", "not found" do
        let(:id) { 999999 }
        run_test!
      end
    end

    patch "Update a challenge step" do
      tags "Challenge Steps"
      security [bearer_auth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :challenge_step_params, in: :body, schema: {
        type: :object,
        properties: {
          challenge_step: {
            type: :object,
            properties: {
              title: { type: :string },
              position: { type: :integer },
              requirements: { type: :object }
            }
          }
        },
        required: ["challenge_step"]
      }

      response "200", "success" do
        let(:step) { create(:challenge_step, challenge_template: challenge, creator: user) }
        let(:id) { step.id }
        let(:challenge_step_params) { { challenge_step: { title: "Updated" } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["title"]).to(eq("Updated"))
        end
      end

      response "403", "forbidden (not owner)" do
        let(:other_user) { create(:user) }
        let(:challenge) { create(:challenge, creator: other_user) }
        let(:step) { create(:challenge_step, challenge_template: challenge, creator: other_user) }
        let(:id) { step.id }
        let(:challenge_step_params) { { challenge_step: { title: "Hacked" } } }
        run_test!
      end
    end

    delete "Delete a challenge step" do
      tags "Challenge Steps"
      security [bearer_auth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "204", "no content" do
        let(:step) { create(:challenge_step, challenge_template: challenge, creator: user) }
        let(:id) { step.id }
        run_test!
      end

      response "403", "forbidden (not owner)" do
        let(:other_user) { create(:user) }
        let(:challenge) { create(:challenge, creator: other_user) }
        let(:step) { create(:challenge_step, challenge_template: challenge, creator: other_user) }
        let(:id) { step.id }
        run_test!
      end
    end
  end
end
