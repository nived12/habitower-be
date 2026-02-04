# frozen_string_literal: true

require "rails_helper"

RSpec.describe("POST /api/v1/follows", type: :request) do
  let(:user) { create(:user) }
  let(:followed) { create(:user) }

  subject(:do_request) do
    post "/api/v1/follows",
      params: { followed_id: followed.id },
      headers: auth_headers(user),
      as: :json
  end

  context "with valid followed_id" do
    before { do_request }

    it "returns 201 Created" do
      expect(response).to(have_http_status(:created))
    end

    it "returns the follow with followed user" do
      expect(parsed_body["follow"]["followed_id"]).to(eq(followed.id))
      expect(parsed_body["follow"]["followed"]["username"]).to(eq(followed.username))
    end

    it "creates a follow record" do
      expect(user.followed_users).to(include(followed))
    end
  end

  context "when following self" do
    subject(:do_request) do
      post "/api/v1/follows",
        params: { followed_id: user.id },
        headers: auth_headers(user),
        as: :json
    end

    before { do_request }

    it "returns 422 Unprocessable Content" do
      expect(response).to(have_http_status(:unprocessable_content))
    end
  end
end

RSpec.describe("DELETE /api/v1/follows/:id", type: :request) do
  let(:user) { create(:user) }
  let(:followed) { create(:user) }
  let!(:follow) { create(:follow, follower: user, followed: followed) }

  subject(:do_request) do
    delete "/api/v1/follows/#{follow.id}", headers: auth_headers(user)
  end

  before { do_request }

  it "returns 204 No Content" do
    expect(response).to(have_http_status(:no_content))
  end

  it "removes the follow" do
    expect(user.followed_users.reload).not_to(include(followed))
  end
end

RSpec.describe("GET /api/v1/follows", type: :request) do
  let(:user) { create(:user) }
  let(:followed) { create(:user) }
  let!(:follow) { create(:follow, follower: user, followed: followed) }

  subject(:do_request) { get "/api/v1/follows", headers: auth_headers(user) }

  before { do_request }

  it "returns 200 OK" do
    expect(response).to(have_http_status(:ok))
  end

  it "returns list of followed users" do
    expect(parsed_body["following"].size).to(eq(1))
    expect(parsed_body["following"].first["id"]).to(eq(followed.id))
  end
end

RSpec.describe("GET /api/v1/followers", type: :request) do
  let(:user) { create(:user) }
  let(:follower) { create(:user) }
  let!(:follow) { create(:follow, follower: follower, followed: user) }

  subject(:do_request) { get "/api/v1/followers", headers: auth_headers(user) }

  before { do_request }

  it "returns 200 OK" do
    expect(response).to(have_http_status(:ok))
  end

  it "returns list of followers" do
    expect(parsed_body["followers"].size).to(eq(1))
    expect(parsed_body["followers"].first["id"]).to(eq(follower.id))
  end
end
