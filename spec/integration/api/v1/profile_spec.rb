# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("Profile API", type: :request) do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }

  path "/api/v1/me" do
    get "Get current user profile and stats" do
      tags "Profile"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "success" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("user"))
          expect(data).to(have_key("stats"))
          expect(data["user"]["id"]).to(eq(user.id))
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end

    patch "Update current user profile" do
      tags "Profile"
      security [bearer_auth: []]
      consumes "application/json"
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          first_name: { type: :string },
          last_name: { type: :string },
          avatar_url: { type: :string },
          bio: { type: :string },
          timezone: { type: :string }
        }
      }

      response "200", "success" do
        let(:body) { { first_name: "Updated" } }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        let(:body) { {} }
        run_test!
      end
    end
  end
end
