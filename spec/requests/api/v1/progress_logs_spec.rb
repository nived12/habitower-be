# frozen_string_literal: true

require "rails_helper"

RSpec.describe("POST /api/v1/progress_logs", type: :request) do
  let(:user) { create(:user) }
  let(:creator) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: creator) }
  let(:group) { create(:group, challenge_template: challenge_template, creator: creator) }
  let!(:membership) { create(:membership, user: user, group: group) }
  let(:group_step) { create(:group_step, group: group, creator: creator, position: 1) }

  subject(:do_request) do
    post "/api/v1/progress_logs",
      params: {
        group_step_id: group_step.id,
        value: 1,
        occurred_at: Time.current.iso8601,
        note: "Done"
      },
      headers: auth_headers(user),
      as: :json
  end

  context "with valid params" do
    before { do_request }

    it "returns 201 Created" do
      expect(response).to(have_http_status(:created))
    end

    it "returns the created progress log" do
      expect(parsed_body["id"]).to(be_present)
      expect(parsed_body["value"]).to(be_present)
      expect(parsed_body["group_step_id"]).to(eq(group_step.id))
      expect(parsed_body["membership_id"]).to(eq(membership.id))
    end
  end

  context "when user is not a member of the group" do
    let(:other_group) { create(:group, challenge_template: challenge_template, creator: creator) }
    let(:other_group_step) { create(:group_step, group: other_group, creator: creator, position: 1) }

    subject(:do_request) do
      post "/api/v1/progress_logs",
        params: { group_step_id: other_group_step.id, value: 1, occurred_at: Time.current.iso8601 },
        headers: auth_headers(user),
        as: :json
    end

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    subject(:do_request) do
      post "/api/v1/progress_logs",
        params: { group_step_id: group_step.id, value: 1 },
        headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end

RSpec.describe("POST /api/v1/progress_logs/:progress_log_id/reactions", type: :request) do
  let(:user) { create(:user) }
  let(:creator) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: creator) }
  let(:group) { create(:group, challenge_template: challenge_template, creator: creator) }
  let(:membership) { create(:membership, user: creator, group: group) }
  let(:group_step) { create(:group_step, group: group, creator: creator, position: 1) }
  let(:progress_log) { create(:progress_log, membership: membership, group_step: group_step) }
  let!(:viewer_membership) { create(:membership, user: user, group: group) }

  subject(:do_request) do
    post "/api/v1/progress_logs/#{progress_log.id}/reactions",
      params: { kind: "high_five" },
      headers: auth_headers(user),
      as: :json
  end

  context "when toggling reaction" do
    it "returns 200 OK" do
      do_request
      expect(response).to(have_http_status(:ok))
    end

    it "creates reaction on first call" do
      expect { do_request }.to(change(Reaction, :count).by(1))
      expect(parsed_body["reacted_by_me"]).to(include("high_five"))
      expect(parsed_body["reactions_count"]).to(eq(1))
    end

    context "when reaction already exists" do
      let!(:existing_reaction) { create(:reaction, user: user, progress_log: progress_log, kind: "high_five") }

      it "removes reaction on toggle" do
        do_request
        expect(parsed_body["reacted_by_me"]).to(eq([]))
        expect(parsed_body["reactions_count"]).to(eq(0))
      end
    end
  end

  context "when user is not in the same group" do
    let(:other_user) { create(:user) }

    subject(:do_request) do
      post "/api/v1/progress_logs/#{progress_log.id}/reactions",
        params: { kind: "high_five" },
        headers: auth_headers(other_user),
        as: :json
    end

    before { do_request }

    it "returns 403 Forbidden" do
      expect(response).to(have_http_status(:forbidden))
    end
  end
end
