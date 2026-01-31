# frozen_string_literal: true

require "rails_helper"

RSpec.describe("GET /api/v1/groups", type: :request) do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:challenge) { create(:challenge, creator: other_user) }

  subject(:do_request) { get "/api/v1/groups", headers: auth_headers(user) }

  context "when authenticated" do
    let!(:public_group) { create(:group, challenge: challenge, creator: other_user) }
    let!(:private_group) { create(:group, challenge: challenge, creator: other_user, privacy_type: "private") }
    let!(:own_private_group) { create(:group, challenge: challenge, creator: user, privacy_type: "private") }

    before { do_request }

    it "returns 200 OK" do
      expect(response).to(have_http_status(:ok))
    end

    it "returns public groups" do
      expect(parsed_body.map { |g| g["id"] }).to(include(public_group.id))
    end

    it "returns user's own private groups" do
      expect(parsed_body.map { |g| g["id"] }).to(include(own_private_group.id))
    end

    it "excludes other users' private groups" do
      expect(parsed_body.map { |g| g["id"] }).not_to(include(private_group.id))
    end
  end

  context "when user is member of a private group" do
    let!(:private_group) { create(:group, challenge: challenge, creator: other_user, privacy_type: "private") }
    let!(:membership) { create(:membership, group: private_group, user: user) }

    before { do_request }

    it "includes the private group" do
      expect(parsed_body.map { |g| g["id"] }).to(include(private_group.id))
    end
  end

  context "when not authenticated" do
    subject(:do_request) { get "/api/v1/groups", headers: json_headers }

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
