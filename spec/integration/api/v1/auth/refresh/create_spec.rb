# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("POST /api/v1/sessions/refresh", type: :request) do
  path "/api/v1/sessions/refresh" do
    post "Refresh access token" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          refresh_token: { type: :string, description: "Valid refresh token from login" }
        },
        required: ["refresh_token"]
      }

      response "200", "ok" do
        let(:user) { create(:user) }
        let!(:refresh_token) { create(:refresh_token, user: user) }
        let(:body) { { refresh_token: refresh_token.token } }

        run_test! do |response|
          expect(response).to(have_http_status(:ok))
        end
      end

      response "401", "refresh token required" do
        let(:body) { {} }
        run_test!
      end

      response "401", "invalid refresh token" do
        let(:body) { { refresh_token: "invalid-token" } }
        run_test!
      end
    end
  end
end
