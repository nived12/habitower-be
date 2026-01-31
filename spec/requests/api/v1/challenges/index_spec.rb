# frozen_string_literal: true

require "rails_helper"

RSpec.describe("GET /api/v1/challenges", type: :request) do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  subject(:do_request) { get "/api/v1/challenges", headers: auth_headers(user) }

  context "when authenticated" do
    let!(:public_challenge) { create(:challenge, creator: other_user) }
    let!(:private_challenge) { create(:challenge, :private, creator: other_user) }
    let!(:own_private_challenge) { create(:challenge, :private, creator: user) }

    before { do_request }

    it "returns 200 OK" do
      expect(response).to(have_http_status(:ok))
    end

    it "returns public challenges" do
      expect(parsed_body.map { |c| c["id"] }).to(include(public_challenge.id))
    end

    it "returns user's own private challenges" do
      expect(parsed_body.map { |c| c["id"] }).to(include(own_private_challenge.id))
    end

    it "excludes other users' private challenges" do
      expect(parsed_body.map { |c| c["id"] }).not_to(include(private_challenge.id))
    end
  end

  context "when user is member of a group with a private challenge" do
    let!(:private_challenge) { create(:challenge, :private, creator: other_user) }
    let(:group) { create(:group, challenge: private_challenge, creator: other_user) }
    let!(:membership) { create(:membership, group: group, user: user) }

    before { do_request }

    it "includes the private challenge" do
      expect(parsed_body.map { |c| c["id"] }).to(include(private_challenge.id))
    end
  end

  context "when not authenticated" do
    subject(:do_request) { get "/api/v1/challenges", headers: json_headers }

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
