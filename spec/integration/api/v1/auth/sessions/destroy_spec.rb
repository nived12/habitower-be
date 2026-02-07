# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("DELETE /api/v1/sessions", type: :request) do
  path "/api/v1/sessions" do
    delete "Logout" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      security [bearer_auth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "ok" do
        let(:login_user) do
          User.create!(email: "logout@example.com", password: "password123", password_confirmation: "password123")
        end
        let(:Authorization) do
          post "/api/v1/sessions", params: { user: { email: login_user.email, password: "password123" } }.to_json,
            headers: { "Content-Type" => "application/json" }
          response.headers["Authorization"]
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("message"))
        end
      end
    end
  end
end
