# frozen_string_literal: true

require "rails_helper"

RSpec.describe("DELETE /api/v1/groups/:id/leave", type: :request) do
  let(:user) { create(:user) }
  let(:creator) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: creator) }
  let(:group) { create(:group, challenge_template: challenge_template, creator: creator) }

  subject(:do_request) do
    delete "/api/v1/groups/#{group.id}/leave", headers: auth_headers(user)
  end

  context "when user is a member" do
    let!(:membership) { create(:membership, group: group, user: user) }

    it "returns 204 No Content" do
      do_request
      expect(response).to(have_http_status(:no_content))
    end

    it "soft deletes the membership" do
      expect { do_request }.to(change { membership.reload.discarded? }.from(false).to(true))
    end
  end

  context "when user is the creator" do
    let(:user) { creator }
    let!(:membership) { create(:membership, group: group, user: creator, role: "admin") }

    before { do_request }

    it "returns 403 Forbidden (creators cannot leave)" do
      expect(response).to(have_http_status(:forbidden))
    end

    it "does not discard the membership" do
      expect(membership.reload.discarded?).to(be(false))
    end
  end

  context "when user is not a member" do
    before { do_request }

    it "returns 403 Forbidden" do
      expect(response).to(have_http_status(:forbidden))
    end
  end

  context "when group does not exist" do
    subject(:do_request) do
      delete "/api/v1/groups/999999/leave", headers: auth_headers(user)
    end

    before { do_request }

    it "returns 404 Not Found" do
      expect(response).to(have_http_status(:not_found))
    end
  end

  context "when not authenticated" do
    subject(:do_request) do
      delete "/api/v1/groups/#{group.id}/leave", headers: json_headers
    end

    before { do_request }

    it "returns 401 Unauthorized" do
      expect(response).to(have_http_status(:unauthorized))
    end
  end
end
