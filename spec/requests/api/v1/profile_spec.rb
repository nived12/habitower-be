# frozen_string_literal: true

require "rails_helper"

RSpec.describe("GET /api/v1/me", type: :request) do
  let(:user) { create(:user, first_name: "Jane", last_name: "Doe", username: "jane") }

  subject(:do_request) { get "/api/v1/me", headers: auth_headers(user) }

  before { do_request }

  it "returns 200 OK" do
    expect(response).to(have_http_status(:ok))
  end

  it "returns current user and stats" do
    expect(parsed_body["user"]["id"]).to(eq(user.id))
    expect(parsed_body["user"]["username"]).to(eq("jane"))
    expect(parsed_body["user"]["first_name"]).to(eq("Jane"))
    expect(parsed_body["user"]["last_name"]).to(eq("Doe"))
    expect(parsed_body["stats"]).to(have_key("total_blocks"))
    expect(parsed_body["stats"]).to(have_key("current_streak"))
    expect(parsed_body["stats"]).to(have_key("groups_count"))
  end
end

RSpec.describe("PATCH /api/v1/me", type: :request) do
  let(:user) { create(:user) }

  subject(:do_request) do
    patch "/api/v1/me",
      params: { first_name: "Updated", bio: "Hello", timezone: "America/New_York" }.to_json,
      headers: auth_headers(user)
  end

  context "with valid params" do
    before { do_request }

    it "returns 200 OK" do
      expect(response).to(have_http_status(:ok))
    end

    it "updates the user" do
      expect(parsed_body["user"]["first_name"]).to(eq("Updated"))
      expect(parsed_body["user"]["bio"]).to(eq("Hello"))
      expect(parsed_body["user"]["timezone"]).to(eq("America/New_York"))
    end
  end
end
