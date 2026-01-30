# frozen_string_literal: true

require "rails_helper"

RSpec.describe("POST /api/v1/auth/login", type: :request) do
  let!(:user) do
    User.create!(email: "login@example.com", password: "password123", password_confirmation: "password123")
  end

  subject(:do_request) do
    post "/api/v1/auth/login", params: request_params.to_json, headers: json_headers
  end

  context "with valid credentials" do
    let(:request_params) { { user: { email: user.email, password: "password123" } } }

    before { do_request }

    it "returns 200 OK" do
      expect(response).to(have_http_status(:ok))
    end

    it "returns the user with id, email, first_name, last_name, avatar_url, and created_at" do
      expect(parsed_body["id"]).to(eq(user.id))
      expect(parsed_body["email"]).to(eq("login@example.com"))
      expect(parsed_body).to(include("first_name", "last_name", "avatar_url", "created_at"))
    end

    it "returns a JWT in the Authorization header" do
      expect(response.headers["Authorization"]).to(be_present.and(start_with("Bearer ")))
    end
  end

  context "with invalid credentials" do
    before { do_request }

    context "when email does not exist" do
      let(:request_params) { { user: { email: "nonexistent@example.com", password: "password123" } } }

      it "returns 401 Unauthorized" do
        expect(response).to(have_http_status(:unauthorized))
      end
    end

    context "when password is wrong" do
      let(:request_params) { { user: { email: user.email, password: "wrongpassword" } } }

      it "returns 401 Unauthorized" do
        expect(response).to(have_http_status(:unauthorized))
      end

      it "returns an error message in the body" do
        expect(parsed_body).to(have_key("error"))
      end
    end
  end
end
