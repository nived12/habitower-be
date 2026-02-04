# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("POST /api/v1/users", type: :request) do
  path "/api/v1/users" do
    post "Create user (sign up)" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, example: "user@example.com" },
              password: { type: :string, example: "password123" },
              password_confirmation: { type: :string, example: "password123" },
              first_name: { type: :string, example: "Jane" },
              last_name: { type: :string, example: "Doe" },
              avatar_url: { type: :string, example: "https://example.com/avatar.png", nullable: true }
            },
            required: %w[email password password_confirmation]
          }
        },
        required: ["user"]
      }

      response "201", "created" do
        let(:user) do
          { user: { email: "newuser@example.com", password: "password123", password_confirmation: "password123" } }
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("id"))
          expect(data["email"]).to(eq("newuser@example.com"))
          expect(data).to(include("first_name", "last_name", "avatar_url"))
          expect(response.headers["Authorization"]).to(be_present)
        end
      end

      response "422", "unprocessable entity" do
        let(:user) { { user: { email: "", password: "short", password_confirmation: "mismatch" } } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("errors"))
        end
      end
    end
  end
end
