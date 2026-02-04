# frozen_string_literal: true

require "rails_helper"

RSpec.describe("POST /api/v1/users", type: :request) do
  let(:valid_params) do
    { user: { email: "user@example.com", password: "password123", password_confirmation: "password123" } }
  end

  subject(:do_request) do
    post "/api/v1/users", params: request_params.to_json, headers: json_headers
  end

  context "with valid params" do
    let(:request_params) { valid_params }

    before { do_request }

    it "returns 201 Created" do
      expect(response).to(have_http_status(:created))
    end

    it "returns the created user with id, email, first_name, last_name, avatar_url, and created_at" do
      expect(parsed_body).to(include("id", "email", "first_name", "last_name", "avatar_url", "created_at"))
      expect(parsed_body["email"]).to(eq("user@example.com"))
    end

    it "returns a JWT in the Authorization header" do
      expect(response.headers["Authorization"]).to(be_present.and(start_with("Bearer ")))
    end

    it "persists the user" do
      expect {
        post(
          "/api/v1/users",
          params: { user: { email: "new@example.com", password: "password123",
password_confirmation: "password123" } }.to_json,
          headers: json_headers
        )
      }.to(change(User, :count).by(1))
    end
  end

  context "with invalid params" do
    context "when email is blank" do
      let(:request_params) do
        { user: { email: "", password: "password123", password_confirmation: "password123" } }
      end

      before { do_request }

      it "returns 422" do
        expect(response).to(have_http_status(422))
      end

      it "returns errors in the response body" do
        expect(parsed_body).to(have_key("errors"))
        expect(parsed_body["errors"]).to(be_an(Array))
      end
    end

    context "when password is too short" do
      let(:request_params) do
        { user: { email: "u@example.com", password: "short", password_confirmation: "short" } }
      end

      before { do_request }

      it "returns 422 Unprocessable Entity" do
        expect(response).to(have_http_status(422))
      end

      it "returns errors in the response body" do
        expect(parsed_body).to(have_key("errors"))
      end
    end

    context "when password confirmation does not match" do
      let(:request_params) do
        { user: { email: "u@example.com", password: "password123", password_confirmation: "other" } }
      end

      before { do_request }

      it "returns 422 Unprocessable Entity" do
        expect(response).to(have_http_status(422))
      end

      it "returns errors in the response body" do
        expect(parsed_body).to(have_key("errors"))
      end
    end

    context "when email is already taken" do
      let(:request_params) do
        { user: { email: "taken@example.com", password: "password123", password_confirmation: "password123" } }
      end

      before do
        User.create!(email: "taken@example.com", password: "password123", password_confirmation: "password123")
        do_request
      end

      it "returns 422 Unprocessable Entity" do
        expect(response).to(have_http_status(422))
      end

      it "returns errors in the response body" do
        expect(parsed_body).to(have_key("errors"))
      end
    end
  end
end
