# frozen_string_literal: true

require "rails_helper"

RSpec.describe("GET /api/v1/feed", type: :request) do
  let(:user) { create(:user) }
  let(:creator) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: creator) }
  let(:group) { create(:group, challenge_template: challenge_template, creator: creator) }
  let(:membership) { create(:membership, user: user, group: group) }
  let(:group_step) { create(:group_step, group: group, creator: creator, position: 1) }

  subject(:do_request) do
    get "/api/v1/feed", params: { scope: scope }, headers: auth_headers(user)
  end

  context "with scope all" do
    let(:scope) { "all" }

    context "when user has no group memberships" do
      let(:membership) { nil }

      before { do_request }

      it "returns 200 OK" do
        expect(response).to(have_http_status(:ok))
      end

      it "returns empty feed" do
        expect(parsed_body["feed"]).to(eq([]))
      end

      it "returns meta with total 0" do
        expect(parsed_body["meta"]["total"]).to(eq(0))
      end
    end

    context "when user is a member and there are progress logs" do
      let!(:progress_log) do
        create(:progress_log, membership: membership, group_step: group_step, occurred_at: 1.hour.ago)
      end

      before { do_request }

      it "returns 200 OK" do
        expect(response).to(have_http_status(:ok))
      end

      it "returns feed with the progress log" do
        expect(parsed_body["feed"].size).to(eq(1))
        expect(parsed_body["feed"].first["id"]).to(eq(progress_log.id))
        expect(parsed_body["feed"].first["user"]["id"]).to(eq(user.id))
        expect(parsed_body["feed"].first["stats"]).to(have_key("reactions_count"))
        expect(parsed_body["feed"].first["viewer_context"]).to(have_key("reacted_by_me"))
      end
    end
  end

  context "with scope mine" do
    let(:scope) { "mine" }
    let!(:progress_log) { create(:progress_log, membership: membership, group_step: group_step) }

    before { do_request }

    it "returns 200 OK" do
      expect(response).to(have_http_status(:ok))
    end

    it "returns only current user progress logs" do
      expect(parsed_body["feed"].size).to(eq(1))
      expect(parsed_body["feed"].first["user"]["id"]).to(eq(user.id))
    end
  end

  context "with invalid scope" do
    let(:scope) { "invalid" }

    before { do_request }

    it "returns 422 Unprocessable Content" do
      expect(response).to(have_http_status(:unprocessable_content))
    end
  end

  context "when not authenticated" do
    let(:scope) { "all" }

    subject(:do_request) { get "/api/v1/feed", params: { scope: scope }, headers: json_headers }

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
