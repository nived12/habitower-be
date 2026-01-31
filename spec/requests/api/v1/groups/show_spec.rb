# frozen_string_literal: true

require "rails_helper"

RSpec.describe("GET /api/v1/groups/:id", type: :request) do
  let(:user) { create(:user) }
  let(:creator) { create(:user) }
  let(:challenge) { create(:challenge, creator: creator) }

  subject(:do_request) { get "/api/v1/groups/#{group.id}", headers: auth_headers(user) }

  context "with a public group" do
    let(:group) { create(:group, challenge: challenge, creator: creator) }

    before { do_request }

    it "returns 200 OK" do
      expect(response).to(have_http_status(:ok))
    end

    it "returns the group attributes" do
      expect(parsed_body["id"]).to(eq(group.id))
      expect(parsed_body["challenge_id"]).to(eq(challenge.id))
      expect(parsed_body["creator_id"]).to(eq(creator.id))
      expect(parsed_body["privacy_type"]).to(eq("public"))
      expect(parsed_body["start_date"]).to(be_present)
    end

    it "does not expose invite_code to non-members" do
      expect(parsed_body).not_to(have_key("invite_code"))
    end
  end

  context "with a private group" do
    let(:group) do
      create(:group, challenge: challenge, creator: creator, privacy_type: "private", invite_code: "ABC123")
    end

    context "when user is not a member" do
      before { do_request }

      it "returns 403 Forbidden" do
        expect(response).to(have_http_status(:forbidden))
      end
    end

    context "when user is the creator" do
      let(:user) { creator }
      let!(:membership) { create(:membership, group: group, user: creator, role: "admin") }

      before { do_request }

      it "returns 200 OK" do
        expect(response).to(have_http_status(:ok))
      end

      it "exposes invite_code to the creator" do
        expect(parsed_body["invite_code"]).to(eq("ABC123"))
      end
    end

    context "when user is a member" do
      let!(:membership) { create(:membership, group: group, user: user) }

      before { do_request }

      it "returns 200 OK" do
        expect(response).to(have_http_status(:ok))
      end

      it "exposes invite_code to members" do
        expect(parsed_body["invite_code"]).to(eq("ABC123"))
      end
    end
  end

  context "when group does not exist" do
    subject(:do_request) { get "/api/v1/groups/999999", headers: auth_headers(user) }

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    let(:group) { create(:group, challenge: challenge, creator: creator) }

    subject(:do_request) { get "/api/v1/groups/#{group.id}", headers: json_headers }

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
