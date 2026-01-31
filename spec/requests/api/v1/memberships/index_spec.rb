# frozen_string_literal: true

require "rails_helper"

RSpec.describe("GET /api/v1/groups/:group_id/memberships", type: :request) do
  let(:user) { create(:user) }
  let(:admin) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: admin) }
  let(:group) { create(:group, challenge_template: challenge_template, creator: admin) }
  let!(:admin_membership) { create(:membership, group: group, user: admin, role: "admin") }
  let!(:member_membership) { create(:membership, group: group, user: user, role: "member") }

  subject(:do_request) do
    get "/api/v1/groups/#{group.id}/memberships", headers: auth_headers(user)
  end

  context "when authenticated" do
    before { do_request }

    it "returns 200 OK" do
      expect(response).to(have_http_status(:ok))
    end

    it "returns all memberships for the group" do
      expect(parsed_body.length).to(eq(2))
    end

    it "includes user information" do
      membership = parsed_body.find { |m| m["user_id"] == user.id }
      expect(membership["user"]["email"]).to(eq(user.email))
      expect(membership["user"]["username"]).to(eq(user.username))
    end
  end

  context "when not authenticated" do
    subject(:do_request) do
      get "/api/v1/groups/#{group.id}/memberships", headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end

  context "when group does not exist" do
    subject(:do_request) do
      get "/api/v1/groups/999999/memberships", headers: auth_headers(user)
    end

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end
end
