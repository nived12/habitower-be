# frozen_string_literal: true

require "rails_helper"

RSpec.describe("GET /api/v1/challenges/:id", type: :request) do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  subject(:do_request) { get "/api/v1/challenges/#{challenge.id}", headers: auth_headers(user) }

  context "with a public challenge" do
    let(:challenge) { create(:challenge, creator: other_user) }

    before { do_request }

    it "returns 200 OK" do
      expect(response).to(have_http_status(:ok))
    end

    it "returns the challenge attributes" do
      expect(parsed_body["id"]).to(eq(challenge.id))
      expect(parsed_body["title"]).to(eq(challenge.title))
      expect(parsed_body["description"]).to(eq(challenge.description))
      expect(parsed_body["period_type"]).to(eq(challenge.period_type))
      expect(parsed_body["privacy_type"]).to(eq(challenge.privacy_type))
    end
  end

  context "with a private challenge" do
    let(:challenge) { create(:challenge, :private, creator: other_user) }

    context "when user is not the creator or member" do
      before { do_request }

      it "returns 403 Forbidden" do
        expect(response).to(have_http_status(:forbidden))
      end
    end

    context "when user is the creator" do
      let(:challenge) { create(:challenge, :private, creator: user) }

      before { do_request }

      it "returns 200 OK" do
        expect(response).to(have_http_status(:ok))
      end
    end

    context "when user is a member of a group using the challenge" do
      let(:group) { create(:group, challenge: challenge, creator: other_user) }
      let!(:membership) { create(:membership, group: group, user: user) }

      before { do_request }

      it "returns 200 OK" do
        expect(response).to(have_http_status(:ok))
      end
    end
  end

  context "when challenge does not exist" do
    subject(:do_request) { get "/api/v1/challenges/999999", headers: auth_headers(user) }

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    let(:challenge) { create(:challenge, creator: other_user) }

    subject(:do_request) { get "/api/v1/challenges/#{challenge.id}", headers: json_headers }

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
