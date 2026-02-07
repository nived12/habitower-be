# frozen_string_literal: true

require "rails_helper"

RSpec.describe("GET /api/v1/categories", type: :request) do
  let(:user) { create(:user) }
  let!(:category) { create(:category, name: "Fitness", slug: "fitness") }

  subject(:do_request) { get "/api/v1/categories", headers: auth_headers(user) }

  before { do_request }

  it "returns 200 OK" do
    expect(response).to(have_http_status(:ok))
  end

  it "returns categories list" do
    expect(parsed_body["categories"]).to(be_an(Array))
    expect(parsed_body["categories"].first["name"]).to(eq("Fitness"))
    expect(parsed_body["categories"].first["slug"]).to(eq("fitness"))
  end
end
