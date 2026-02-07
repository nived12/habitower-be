# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("POST /api/v1/sessions", type: :request) do
  path "/api/v1/sessions" do
    post "Create session (login)" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, example: "user@example.com" },
              password: { type: :string, example: "password123" }
            },
            required: %w[email password]
          }
        },
        required: ["user"]
      }

      response "200", "ok" do
        let(:credentials) { { user: { email: login_user.email, password: "password123" } } }
        let(:login_user) do
          User.create!(email: "login@example.com", password: "password123", password_confirmation: "password123")
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["email"]).to(eq("login@example.com"))
          expect(data).to(include("first_name", "last_name", "avatar_url"))
          expect(response.headers["Authorization"]).to(be_present)
        end
      end

      response "401", "unauthorized" do
        let(:credentials) { { user: { email: "wrong@example.com", password: "wrongpassword" } } }
        run_test! do |response|
          expect(response.body).to(be_present)
        end
      end
    end
  end
end
