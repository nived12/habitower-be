# frozen_string_literal: true

require "rails_helper"

RSpec.describe("GET /api/v1/challenges/:challenge_id/challenge_steps", type: :request) do
  let(:user) { create(:user) }
  let(:creator) { create(:user) }
  let(:challenge) { create(:challenge, creator: creator) }

  subject(:do_request) do
    get "/api/v1/challenges/#{challenge.id}/challenge_steps", headers: auth_headers(user)
  end

  context "when challenge is public" do
    let!(:step1) { create(:challenge_step, challenge_template: challenge, position: 1, creator: creator) }
    let!(:step2) { create(:challenge_step, challenge_template: challenge, position: 2, creator: creator) }

    before { do_request }

    it "returns 200 OK" do
      expect(response).to(have_http_status(:ok))
    end

    it "returns all challenge steps ordered by position" do
      expect(parsed_body.length).to(eq(2))
      expect(parsed_body.first["id"]).to(eq(step1.id))
      expect(parsed_body.second["id"]).to(eq(step2.id))
    end
  end

  context "when challenge is private" do
    let(:challenge) { create(:challenge, :private, creator: creator) }
    let!(:step) { create(:challenge_step, challenge_template: challenge, creator: creator) }

    context "when user is not authorized" do
      before { do_request }

      it "returns 403 Forbidden" do
        expect(response).to(have_http_status(:forbidden))
      end
    end

    context "when user is the challenge creator" do
      let(:user) { creator }

      before { do_request }

      it "returns 200 OK" do
        expect(response).to(have_http_status(:ok))
      end
    end

    context "when user is a member of a group using the challenge" do
      let(:group) { create(:group, challenge_template: challenge, creator: creator) }
      let!(:membership) { create(:membership, group: group, user: user) }

      before { do_request }

      it "returns 200 OK" do
        expect(response).to(have_http_status(:ok))
      end
    end
  end

  context "when challenge does not exist" do
    subject(:do_request) do
      get "/api/v1/challenges/999999/challenge_steps", headers: auth_headers(user)
    end

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    subject(:do_request) do
      get "/api/v1/challenges/#{challenge.id}/challenge_steps", headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
