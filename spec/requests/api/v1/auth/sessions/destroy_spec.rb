# frozen_string_literal: true

require "rails_helper"

RSpec.describe("DELETE /api/v1/auth/logout", type: :request) do
  let!(:user) do
    User.create!(email: "logout@example.com", password: "password123", password_confirmation: "password123")
  end

  def auth_headers
    post(
      "/api/v1/auth/login",
      params: { user: { email: user.email, password: "password123" } }.to_json,
      headers: json_headers
    )
    { "Authorization" => response.headers["Authorization"], "Accept" => "application/json" }
  end

  subject(:do_request) do
    delete "/api/v1/auth/logout", headers: request_headers
  end

  context "with a valid JWT" do
    let(:request_headers) { auth_headers }

    before { do_request }

    it "returns 200 OK" do
      expect(response).to(have_http_status(:ok))
    end

    it "returns a success message" do
      expect(parsed_body).to(have_key("message"))
      expect(parsed_body["message"]).to(be_present)
    end
  end

  context "without a token" do
    let(:request_headers) { json_headers }

    before { do_request }

    it "returns 200 OK (no session to sign out)" do
      expect(response).to(have_http_status(:ok))
    end
  end
end
